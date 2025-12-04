--------------------------------------------------------------------------------
-- PROCEDURE: PERMISO_DENEGADO
--------------------------------------------------------------------------------
-- Propósito: Revertir cambios en bolsas al denegar/anular un permiso
-- Autor: RRHH / Optimizado por Carlos (04/12/2025)
-- Versión: 2.0.0
--
-- Descripción:
--   Revierte los movimientos en bolsas de días/horas cuando un permiso es:
--   - Denegado por RRHH (estado 32)
--   - Anulado por RRHH (estado 40)
--   - Anulado por Usuario (estado 41)
--
--   Tipos de bolsa afectados:
--   - Bolsa de días (permisos únicos: vacaciones, asuntos propios, etc.)
--   - Bolsa de horas extras (compensatorios 15000)
--   - Bolsa de conciliación (permiso 40000)
--   - Bolsa movimiento (bajas por enfermedad 11100/11300)
--
-- Parámetros:
--   V_ID_PERMISO   - ID del permiso a denegar/anular (IN)
--   todo_ok_Basico - 0=OK, 1=Error (OUT)
--   msgBasico      - Mensaje resultado (OUT)
--
-- Historial:
--   04/12/2025 - Carlos - Optimización v2.0
--   18/11/2014 - CHM - Eliminada validación días máximos
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE RRHH."PERMISO_DENEGADO" (
       V_ID_PERMISO IN NUMBER,
       todo_ok_Basico OUT INTEGER,
       msgBasico OUT VARCHAR2
) IS

  --------------------------------------------------------------------------------
  -- CONSTANTES
  --------------------------------------------------------------------------------
  C_OK CONSTANT INTEGER := 0;
  C_ERROR CONSTANT INTEGER := 1;
  
  -- Tipos de permiso especiales
  C_PERMISO_VACACIONES CONSTANT VARCHAR2(5) := '01000';
  C_PERMISO_BAJA_ENFERMEDAD CONSTANT VARCHAR2(5) := '11100';
  C_PERMISO_BAJA_SIN_DESCUENTO CONSTANT VARCHAR2(5) := '11300';
  C_PERMISO_COMPENSATORIO CONSTANT VARCHAR2(5) := '15000';
  C_PERMISO_CONCILIACION CONSTANT VARCHAR2(5) := '40000';
  
  -- Límites
  C_MAX_HORAS_COMPENSATORIO CONSTANT NUMBER := 1450;
  C_MAX_DIAS_VACACIONES_ESPECIAL CONSTANT NUMBER := 31;
  C_UMBRAL_VACACIONES_NATURALES CONSTANT NUMBER := 29;
  C_DIAS_VACACIONES_LABORABLES CONSTANT NUMBER := 22;
  C_FLAG_SI CONSTANT VARCHAR2(2) := 'SI';
  C_FLAG_NO CONSTANT VARCHAR2(2) := 'NO';
  
  --------------------------------------------------------------------------------
  -- VARIABLES LOCALES (OPTIMIZADAS)
  --------------------------------------------------------------------------------
  
  -- Control
  i_no_hay_permisos NUMBER(1);
  
  -- Datos del permiso
  i_id_funcionario VARCHAR2(6);
  i_num_dias NUMBER;
  i_id_unico VARCHAR2(2);
  i_num_dias_total NUMBER;
  i_num_dias_restan NUMBER;
  v_id_tipo_permiso VARCHAR2(6);
  i_id_ano NUMBER(4);
  i_id_tipo_dias VARCHAR2(2);
  i_total_horas NUMBER;
  d_fecha_inicio DATE;
  I_DESCUENTO_BAJAS VARCHAR2(2);
  I_DESCUENTO_DIAS NUMBER;

BEGIN
  
  --------------------------------------------------------------------------------
  -- FASE 1: INICIALIZACIÓN
  --------------------------------------------------------------------------------
  
  todo_ok_basico := C_OK;
  msgBasico := '';
  i_no_hay_permisos := 0;

  
  --------------------------------------------------------------------------------
  -- FASE 2: OBTENER DATOS DEL PERMISO
  --------------------------------------------------------------------------------
  
  BEGIN
    SELECT p.id_funcionario,
           p.num_dias,
           unico,
           tr.num_dias,
           p.id_tipo_permiso,
           p.id_ano,
           total_horas,
           p.fecha_inicio,
           DESCUENTO_BAJAS,
           DESCUENTO_DIAS
      INTO i_id_funcionario,
           i_num_dias,
           i_id_unico,
           i_num_dias_total,
           v_id_tipo_permiso,
           i_id_ano,
           i_total_horas,
           d_fecha_inicio,
           I_DESCUENTO_BAJAS,
           I_DESCUENTO_DIAS
      FROM permiso p
      JOIN tr_tipo_permiso tr 
        ON p.id_ano = tr.id_ano 
       AND p.id_tipo_permiso = tr.id_tipo_permiso
     WHERE id_permiso = v_id_permiso 
       AND (anulado = C_FLAG_NO OR ANULADO IS NULL)
       AND ROWNUM < 2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_no_hay_permisos := -1;
  END;
  
  IF i_no_hay_permisos = -1 THEN
    todo_ok_basico := C_ERROR;
    msgBasico := 'Operación no realizada. Permiso no existe.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 3: ELIMINAR MOVIMIENTOS DE BOLSA (BAJAS POR ENFERMEDAD)
  -- Revierte el descuento aplicado a la bolsa cuando se concedió la baja
  --------------------------------------------------------------------------------
  
  IF V_ID_TIPO_PERMISO = C_PERMISO_BAJA_ENFERMEDAD OR 
     (I_DESCUENTO_BAJAS = C_FLAG_SI AND V_ID_TIPO_PERMISO = C_PERMISO_BAJA_SIN_DESCUENTO) THEN
    
    UPDATE bolsa_movimiento
       SET ANULADO = 1
     WHERE id_funcionario = i_id_funcionario
       AND fecha_movimiento = d_fecha_inicio;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 4: REVERTIR BOLSA DE DÍAS (PERMISOS ÚNICOS)
  -- Devolver los días utilizados a la bolsa del funcionario
  --------------------------------------------------------------------------------
  
  IF I_ID_UNICO = C_FLAG_SI AND V_ID_TIPO_PERMISO <> C_PERMISO_COMPENSATORIO THEN
    
    -- Obtener días restantes en la bolsa
    i_no_hay_permisos := 0;
    
    BEGIN
      SELECT pe.num_dias,
             id_tipo_dias
        INTO i_num_dias_restan,
             i_id_tipo_dias
        FROM permiso_funcionario pe
       WHERE id_ano = i_id_ano
         AND id_funcionario = i_id_funcionario
         AND id_tipo_permiso = v_id_tipo_permiso;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_no_hay_permisos := -1;
    END;
    
    IF i_no_hay_permisos = -1 THEN
      todo_ok_basico := C_ERROR;
      msgBasico := 'Operación no realizada. No existen días para ese permiso.';
      RETURN;
    END IF;
    
    -- Lógica especial para VACACIONES (01000)
    IF V_ID_TIPO_PERMISO = C_PERMISO_VACACIONES THEN
      
      -- Caso 1: Restaurar a 31 días naturales (umbral > 29)
      IF (i_num_dias_restan + i_num_dias) > C_UMBRAL_VACACIONES_NATURALES AND 
         i_num_dias_total = C_MAX_DIAS_VACACIONES_ESPECIAL THEN
        
        UPDATE permiso_funcionario
           SET num_dias = C_MAX_DIAS_VACACIONES_ESPECIAL,
               id_tipo_dias = 'N'
         WHERE id_funcionario = i_id_funcionario
           AND id_tipo_permiso = C_PERMISO_VACACIONES
           AND id_ano = i_id_ano
           AND ROWNUM < 2;
        
        IF SQL%ROWCOUNT = 0 THEN
          todo_ok_basico := C_ERROR;
          msgBasico := 'Operación no realizada. Póngase en contacto con RRHH. Error Update Firma.';
          RETURN;
        END IF;
        
      -- Caso 2: Conversión de 22 laborables a 31 naturales
      ELSIF (i_num_dias_restan + i_num_dias) = C_DIAS_VACACIONES_LABORABLES AND 
            i_num_dias_total = C_MAX_DIAS_VACACIONES_ESPECIAL AND 
            i_id_tipo_dias = 'L' THEN
        
        UPDATE permiso_funcionario
           SET num_dias = C_MAX_DIAS_VACACIONES_ESPECIAL,
               id_tipo_dias = 'N'
         WHERE id_funcionario = i_id_funcionario
           AND id_tipo_permiso = C_PERMISO_VACACIONES
           AND id_ano = i_id_ano
           AND ROWNUM < 2;
        
        IF SQL%ROWCOUNT = 0 THEN
          todo_ok_basico := C_ERROR;
          msgBasico := 'Operación no realizada. Póngase en contacto con RRHH. Error Update Firma.';
          RETURN;
        END IF;
        
      -- Caso 3: Suma simple de días
      ELSE
        UPDATE permiso_funcionario
           SET num_dias = num_dias + i_num_dias
         WHERE id_funcionario = i_id_funcionario
           AND id_tipo_permiso = V_ID_TIPO_PERMISO
           AND id_ano = i_id_ano
           AND ROWNUM < 2;
        
        IF SQL%ROWCOUNT = 0 THEN
          todo_ok_basico := C_ERROR;
          msgBasico := 'Operación no realizada. Póngase en contacto con RRHH. Error Update Firma.';
          RETURN;
        END IF;
      END IF;
      
    -- Para otros permisos únicos: suma simple
    ELSE
      UPDATE permiso_funcionario
         SET num_dias = num_dias + i_num_dias
       WHERE id_funcionario = i_id_funcionario
         AND id_tipo_permiso = V_ID_TIPO_PERMISO
         AND id_ano = i_id_ano
         AND ROWNUM < 2;
      
      IF SQL%ROWCOUNT = 0 THEN
        todo_ok_basico := C_ERROR;
        msgBasico := 'Operación no realizada. Póngase en contacto con RRHH. Error Update Firma.';
        RETURN;
      END IF;
    END IF;
    
  --------------------------------------------------------------------------------
  -- FASE 5: REVERTIR BOLSA DE HORAS (COMPENSATORIOS)
  --------------------------------------------------------------------------------
  
  ELSIF V_ID_TIPO_PERMISO = C_PERMISO_COMPENSATORIO AND 
        i_total_horas > 0 AND 
        i_total_horas < C_MAX_HORAS_COMPENSATORIO THEN
    
    UPDATE horas_extras_ausencias
       SET utilizadas = utilizadas - i_total_horas
     WHERE id_funcionario = i_ID_funcionario
       AND ROWNUM < 3;
    
    IF SQL%ROWCOUNT = 0 THEN
      todo_ok_basico := C_ERROR;
      msgBasico := 'Operación no realizada. Póngase en contacto con RRHH. Error Update Horas Extras Ausencia.';
      RETURN;
    END IF;
    
  --------------------------------------------------------------------------------
  -- FASE 6: REVERTIR BOLSA DE CONCILIACIÓN (PERMISO 40000)
  --------------------------------------------------------------------------------
  
  ELSIF V_ID_TIPO_PERMISO = C_PERMISO_CONCILIACION AND 
        i_total_horas > 0 AND 
        i_total_horas < C_MAX_HORAS_COMPENSATORIO THEN
    
    UPDATE bolsa_concilia
       SET utilizadas = utilizadas - i_total_horas
     WHERE id_funcionario = i_ID_funcionario
       AND ROWNUM < 3
       AND id_ano = i_id_ano;
    
    IF SQL%ROWCOUNT = 0 THEN
      todo_ok_basico := C_ERROR;
      msgBasico := 'Operación no realizada. Póngase en contacto con RRHH. Error Update Horas BOLSA_CONCILIA.';
      RETURN;
    END IF;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 7: FINALIZACIÓN EXITOSA
  --------------------------------------------------------------------------------
  
  todo_ok_basico := C_OK;
  msgBasico := 'TODO bien';
  
EXCEPTION
  WHEN OTHERS THEN
    -- Manejo robusto de excepciones no controladas
    todo_ok_basico := C_ERROR;
    msgBasico := 'Error inesperado al denegar permiso: ' || SQLERRM ||
                 ' | Permiso: ' || V_ID_PERMISO;
    ROLLBACK;

END PERMISO_DENEGADO;
/

