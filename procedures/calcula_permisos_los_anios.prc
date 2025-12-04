--------------------------------------------------------------------------------
-- PROCEDURE: CALCULA_PERMISOS_LOS_ANIOS
--------------------------------------------------------------------------------
-- Propósito: Calcular y asignar permisos anuales a funcionarios
-- Autor: RRHH / Optimizado por Carlos (04/12/2025)
-- Versión: 2.0.0
--
-- Descripción:
--   Calcula automáticamente los permisos que corresponden a cada funcionario
--   para un año específico basándose en:
--   - Antigüedad del funcionario
--   - Tipo de funcionario (bomberos, policías, administrativos)
--   - Tipo de contratación (funcionario, laboral)
--   - Días proporcionales si es alta/baja durante el año
--   - Trienios acumulados
--
--   Funcionalidades principales:
--   - Cálculo de vacaciones (01000) con días adicionales por antigüedad
--   - Asuntos propios (02000) según colectivo
--   - Días adicionales por antigüedad (01015)
--   - Asuntos propios por trienios (02015)
--   - Permisos compensatorios (03010-03060) arrastre año anterior
--   - Ajuste proporcional para altas/bajas en el año
--   - Casos especiales para funcionarios históricos (IDs específicos)
--
-- Reglas de cálculo:
--   Vacaciones base: 30 días laborables (bomberos/policías: naturales)
--   Antigüedad > 15 años: +1 a +4 días extra según tramo
--   Factor proporcional: días desde ingreso / 365
--   Bomberos (tipo 23) y Policías (tipo 21): días naturales
--
-- Parámetros:
--   V_ID_FUNCIONARIO - ID funcionario (0=todos) (IN)
--   V_ID_ANO         - Año cálculo (0=actual) (IN)
--
-- Historial:
--   04/12/2025 - Carlos - Optimización v2.0
--   [Múltiples fechas] - CHM - Casos especiales funcionarios históricos
--   [Original] - RRHH - Creación inicial
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE RRHH.CALCULA_PERMISOS_LOS_ANIOS (
  V_ID_FUNCIONARIO IN NUMBER,
  V_ID_ANO         IN VARCHAR
) IS

  --------------------------------------------------------------------------------
  -- CONSTANTES
  --------------------------------------------------------------------------------
  C_DIAS_VACACIONES_BASE CONSTANT NUMBER := 30;
  C_DIAS_MAX_FACTOR CONSTANT NUMBER := 365;
  C_ANTIGUEDAD_MAXIMA CONSTANT NUMBER := 55;
  C_ANTIGUEDAD_COMPLETA CONSTANT NUMBER := 5;
  
  -- Tipos de funcionario
  C_TIPO_ADMINISTRATIVO CONSTANT NUMBER := 10;
  C_TIPO_POLICIA CONSTANT NUMBER := 21;
  C_TIPO_BOMBERO CONSTANT NUMBER := 23;
  
  -- Tipos de permiso principales
  C_PERMISO_VACACIONES CONSTANT VARCHAR2(5) := '01000';
  C_PERMISO_ASUNTOS_PROPIOS CONSTANT VARCHAR2(5) := '02000';
  C_PERMISO_DIAS_ANTIGUEDAD CONSTANT VARCHAR2(5) := '01015';
  C_PERMISO_TRIENIOS CONSTANT VARCHAR2(5) := '02015';
  
  -- IDs funcionarios históricos con reglas especiales
  TYPE t_ids_especiales IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
  v_ids_1991 t_ids_especiales; -- Fecha antigüedad 01/02/1991
  v_ids_1985 t_ids_especiales; -- Fecha antigüedad 01/02/1985
  
  --------------------------------------------------------------------------------
  -- VARIABLES LOCALES
  --------------------------------------------------------------------------------
  i INTEGER;
  i_id_funcionario VARCHAR2(6);
  i_id_ano NUMBER(4);
  i_compensatorios NUMBER;
  i_asuntos_propios_bomberos NUMBER;
  i_asuntos_propios NUMBER;
  i_num_dias_extras NUMBER;
  i_fecha_ingreso DATE;
  i_antiguedad NUMBER;
  i_dias_factor NUMBER;
  i_contratacion NUMBER;
  i_tipo_funcionario2 NUMBER;
  id_tipo_funcionario_p NUMBER;
  i_id_tipo_permiso VARCHAR2(5);
  i_num_dias NUMBER;
  i_unico VARCHAR2(2);
  i_tipo_dias VARCHAR2(1);
  i_inserta NUMBER;
  
  --------------------------------------------------------------------------------
  -- CURSORES
  --------------------------------------------------------------------------------
  
  -- Cursor para obtener funcionarios activos en el año
  CURSOR c1 (i_ano NUMBER, i_funcionario NUMBER) IS
    SELECT DISTINCT 
           id_funcionario,
           fecha_ingreso,
           NVL(TO_CHAR(fecha_baja, 'yyyy'), '0') - TO_CHAR(fecha_antiguedad, 'yyyy') AS Antiguedad,
           NVL(FECHA_FIN_CONTRATO, TO_DATE('31/12/' || i_ano, 'DD/MM/YYYY')) - fecha_ingreso AS dias_factor,
           contratacion,
           tipo_funcionario2
    FROM personal_new pe
    WHERE (fecha_baja IS NULL 
           OR (fecha_baja > TO_DATE('31/12/' || i_ano, 'DD/MM/YYYY')
               AND fecha_baja <= TO_DATE('31/12/2090', 'DD/MM/YYYY')))
      AND (fecha_fin_contrato > TO_DATE('01/12/' || i_ano, 'DD/MM/YYYY') 
           OR fecha_fin_contrato IS NULL)
      AND ('0' = i_funcionario OR pe.id_funcionario = i_funcionario)
    ORDER BY id_funcionario;
  
  -- Cursor para tipos de permiso del año
  CURSOR c2 (i_ano NUMBER) IS
    SELECT LPAD(ID_TIPO_PERMISO, 5, '0'),
           NUM_DIAS,
           UNICO,
           tipo_dias,
           id_tipo_funcionario
    FROM tr_tipo_permiso
    WHERE id_ano = v_id_ano
      AND id_tipo_permiso NOT IN ('01501', '01502', '01503', '01504', '03060', '03070', '03080')
    ORDER BY id_tipo_permiso;

BEGIN
  
  --------------------------------------------------------------------------------
  -- FASE 1: INICIALIZACIÓN
  --------------------------------------------------------------------------------
  
  DBMS_OUTPUT.PUT_LINE('Empieza el PL/SQL');
  
  -- Determinar año de cálculo
  IF V_ID_ANO = '0' THEN
    i_id_ano := TO_CHAR(SYSDATE, 'YYYY');
  ELSE
    i_id_ano := TO_NUMBER(V_ID_ANO);
  END IF;
  
  -- Inicializar IDs funcionarios especiales (antigüedad 01/02/1991)
  v_ids_1991(1) := 10002;
  v_ids_1991(2) := 10003;
  v_ids_1991(3) := 10024;
  v_ids_1991(4) := 10011;
  v_ids_1991(5) := 10013;
  v_ids_1991(6) := 10016;
  v_ids_1991(7) := 10020;
  v_ids_1991(8) := 10029;
  v_ids_1991(9) := 10021;
  v_ids_1991(10) := 10023;
  v_ids_1991(11) := 10028;
  v_ids_1991(12) := 10030;
  
  -- Inicializar IDs antigüedad 01/02/1985
  v_ids_1985(1) := 14003;
  v_ids_1985(2) := 14004;
  
  --------------------------------------------------------------------------------
  -- FASE 2: RECORRER FUNCIONARIOS Y CALCULAR PERMISOS
  --------------------------------------------------------------------------------
  
  OPEN C1(i_id_ano, V_ID_FUNCIONARIO);
  LOOP
    
    FETCH C1 INTO i_id_funcionario,
                  i_fecha_ingreso,
                  i_antiguedad,
                  i_dias_factor,
                  i_contratacion,
                  i_tipo_funcionario2;
    EXIT WHEN C1%NOTFOUND;
    
    -- Calcular factor proporcional (días trabajados / 365)
    i_dias_factor := i_dias_factor / C_DIAS_MAX_FACTOR;
    
    -- Ajustes de antigüedad
    IF i_antiguedad > C_ANTIGUEDAD_MAXIMA THEN
      i_antiguedad := 0;
    END IF;
    
    IF i_antiguedad > C_ANTIGUEDAD_COMPLETA THEN
      i_dias_factor := 1;
    END IF;
    
    IF i_dias_factor > 1 THEN
      i_dias_factor := 1;
    END IF;
    
    --------------------------------------------------------------------------------
    -- FASE 3: PROCESAR CADA TIPO DE PERMISO
    --------------------------------------------------------------------------------
    
    OPEN C2(i_id_ano);
    LOOP
      
      FETCH C2 INTO i_id_tipo_permiso,
                    i_num_dias,
                    i_unico,
                    i_tipo_dias,
                    id_tipo_funcionario_p;
      EXIT WHEN C2%NOTFOUND;
      
      i_inserta := 1; -- Por defecto no insertar
      
      -- VACACIONES Y ASUNTOS PROPIOS (proporcionales)
      IF i_id_tipo_permiso = C_PERMISO_VACACIONES OR i_id_tipo_permiso = C_PERMISO_ASUNTOS_PROPIOS THEN
        
        IF i_id_tipo_permiso = C_PERMISO_VACACIONES AND i_dias_factor <> 1 THEN
          i_num_dias := C_DIAS_VACACIONES_BASE;
        END IF;
        
        i_num_dias := ROUND(i_num_dias * i_dias_factor, 0);
        i_inserta := 1;
        
        -- Bomberos y policías: días naturales
        IF i_TIPO_FUNCIONARIO2 = C_TIPO_POLICIA OR i_TIPO_FUNCIONARIO2 = C_TIPO_BOMBERO THEN
          i_tipo_dias := 'N';
        END IF;
        
      -- PERMISOS COMPENSATORIOS (arrastre año anterior)
      ELSIF i_id_tipo_permiso IN ('03010', '03020', '03030', '03040', '03050', '03060') THEN
        
        BEGIN
          SELECT COUNT(*)
          INTO i_inserta
          FROM permiso_funcionario
          WHERE id_funcionario = i_id_funcionario
            AND ID_TIPO_PERMISO IN ('03010', '03020', '03030', '03040', '03050', '03060')
            AND id_ano = v_id_ano - 1;
            
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_inserta := 0;
          WHEN OTHERS THEN
            i_inserta := 0;
        END;
        
        -- Administrativos siempre
        IF i_TIPO_FUNCIONARIO2 = C_TIPO_ADMINISTRATIVO THEN
          i_inserta := 1;
        END IF;
        
        IF i_inserta > 0 THEN
          i_inserta := 1;
        END IF;
        
      END IF;
      
      --------------------------------------------------------------------------------
      -- FASE 4: DÍAS ADICIONALES POR ANTIGÜEDAD (01015)
      --------------------------------------------------------------------------------
      
      IF i_id_tipo_permiso = C_PERMISO_DIAS_ANTIGUEDAD THEN
        
        BEGIN
          i_inserta := 1;
          
          -- Calcular días adicionales según años de antigüedad (16-70 años)
          SELECT DISTINCT
            DECODE(i_id_ano - TO_NUMBER(SUBSTR(TO_CHAR(fecha_antiguedad, 'DD/MM/YYYY'), 7, 4)),
              16, 1, 17, 1, 18, 1, 19, 1, 20, 1,  -- 16-20 años: 1 día
              21, 2, 22, 2, 23, 2, 24, 2, 25, 2,  -- 21-25 años: 2 días
              26, 3, 27, 3, 28, 3, 29, 3, 30, 3,  -- 26-30 años: 3 días
              31, 4, 32, 4, 33, 4, 34, 4, 35, 4,  -- 31-70 años: 4 días
              36, 4, 37, 4, 38, 4, 39, 4, 40, 4,
              41, 4, 42, 4, 43, 4, 44, 4, 45, 4,
              46, 4, 47, 4, 48, 4, 49, 4, 50, 4,
              51, 4, 52, 4, 53, 4, 54, 4, 55, 4,
              56, 4, 57, 4, 58, 4, 59, 4, 60, 4,
              61, 4, 62, 4, 63, 4, 64, 4, 65, 4,
              66, 4, 67, 4, 68, 4, 69, 4, 70, 4,
              0) -- Por defecto 0
          INTO i_num_dias
          FROM personal_new
          WHERE i_id_ano - TO_NUMBER(SUBSTR(TO_CHAR(fecha_antiguedad, 'DD/MM/YYYY'), 7, 4)) > 15
            AND id_funcionario = i_id_funcionario;
            
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_inserta := 0;
          WHEN OTHERS THEN
            i_inserta := 0;
        END;
        
        -- Casos especiales: IDs con antigüedad 01/02/1991 → 2 días
        FOR i IN 1..v_ids_1991.COUNT LOOP
          IF i_id_funcionario = v_ids_1991(i) THEN
            i_num_dias := 2;
            i_inserta := 1;
            EXIT;
          END IF;
        END LOOP;
        
        -- Caso especial: ID 203353 → 3 días (trienios especiales)
        IF i_id_funcionario = 203353 THEN
          i_num_dias := 3;
          i_inserta := 1;
        END IF;
        
        -- Casos especiales: IDs con antigüedad 01/02/1985 → 4 días
        FOR i IN 1..v_ids_1985.COUNT LOOP
          IF i_id_funcionario = v_ids_1985(i) THEN
            i_num_dias := 4;
            i_inserta := 1;
            EXIT;
          END IF;
        END LOOP;
        
      END IF; -- FIN PERMISO 01015
      
      --------------------------------------------------------------------------------
      -- FASE 5: ASUNTOS PROPIOS POR TRIENIOS (02015)
      --------------------------------------------------------------------------------
      
      IF i_id_tipo_permiso = C_PERMISO_AP_TRIENIOS THEN
        
        i_inserta := 1;
        
        BEGIN
          -- Cálculo de trienios deshabilitado (lógica comentada en original)
          -- Se mantiene valor por defecto de 0
          SELECT DISTINCT 0
          INTO i_num_dias
          FROM dual;
          
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_inserta := 0;
          WHEN OTHERS THEN
            i_inserta := 0;
        END;
        
        -- Casos especiales con trienios: IDs con antigüedad 01/02/1991 → 3 días
        FOR i IN 1..v_ids_1991.COUNT LOOP
          IF i_id_funcionario = v_ids_1991(i) THEN
            i_num_dias := 3;
            i_inserta := 1;
            EXIT;
          END IF;
        END LOOP;
        
        -- Caso especial: ID 203353 → 3 días (trienios especiales)
        IF i_id_funcionario = 203353 THEN
          i_num_dias := 3;
          i_inserta := 1;
        END IF;
        
        -- Casos especiales: IDs con antigüedad 01/02/1985 → 2 días trienios
        FOR i IN 1..v_ids_1985.COUNT LOOP
          IF i_id_funcionario = v_ids_1985(i) THEN
            i_num_dias := 2;
            i_inserta := 1;
            EXIT;
          END IF;
        END LOOP;
        
      END IF; -- FIN PERMISO 02015
      
      -- Excluir permisos bomberos (02030, 02031) para no bomberos
      IF (i_id_tipo_permiso = '02030' OR i_id_tipo_permiso = '02031') 
         AND i_TIPO_FUNCIONARIO2 <> C_TIPO_BOMBERO THEN
        i_inserta := 0;
      END IF;
      
      --------------------------------------------------------------------------------
      -- FASE 6: INSERTAR EN PERMISO_FUNCIONARIO
      --------------------------------------------------------------------------------
      
      IF i_inserta = 1 THEN
        BEGIN
          INSERT INTO permiso_funcionario (
            id_funcionario,
            id_tipo_permiso,
            id_ano,
            num_dias,
            completo,
            unico,
            id_tipo_dias
          ) VALUES (
            i_id_funcionario,
            i_id_tipo_permiso,
            v_id_ano,
            i_num_dias,
            'SI',
            i_unico,
            i_tipo_dias
          );
          
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            NULL; -- Registro ya existe, ignorar
        END;
      END IF;
      
    END LOOP; -- Fin cursor C2 (tipos de permiso)
    CLOSE C2;
    
  END LOOP; -- Fin cursor C1 (funcionarios)
  CLOSE C1;
  
  COMMIT;
  
  DBMS_OUTPUT.PUT_LINE('Finalizado calcula_permisos_los_anios exitosamente');
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error en calcula_permisos_los_anios: ' || SQLERRM);
    ROLLBACK;
    RAISE;
    
END calcula_permisos_los_anios;
/

