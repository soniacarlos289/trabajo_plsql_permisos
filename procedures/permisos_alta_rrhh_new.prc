--------------------------------------------------------------------------------
-- PROCEDURE: PERMISOS_ALTA_RRHH_NEW
--------------------------------------------------------------------------------
-- Propósito: Alta de permisos realizada directamente por RRHH
-- Autor: RRHH / Optimizado por Carlos (04/12/2025)
-- Versión: 2.0.0
--
-- Descripción:
--   Permite a RRHH dar de alta permisos directamente con estado concedido (80).
--   Realiza todas las validaciones necesarias, actualiza bolsas de días,
--   integra con sistema de fichaje biométrico y envía notificaciones.
--
-- Tipos de permiso soportados:
--   01000 - Vacaciones
--   02000 - Asuntos propios
--   11100 - Baja por enfermedad (con descuento obligatorio a bolsa)
--   11300 - Baja por enfermedad sin descuento
--   15000 - Compensatorio por horas
--   030XX - Permisos retribuidos varios
--
-- Parámetros IN:
--   V_ID_ANO              - Año del permiso
--   V_ID_FUNCIONARIO      - ID del funcionario
--   V_ID_TIPO_PERMISO     - Código del tipo de permiso
--   V_ID_ESTADO_PERMISO   - Estado del permiso
--   V_ID_TIPO_DIAS        - Tipo de días (laborables, naturales, horas)
--   V_FECHA_INICIO        - Fecha inicio
--   V_HORA_INICIO         - Hora inicio (para compensatorios)
--   V_HORA_FIN            - Hora fin (para compensatorios)
--   V_ID_GRADO            - Grado del funcionario
--   V_DPROVINCIA          - Provincia (para permisos especiales)
--   V_JUSTIFICACION       - Justificación requerida (SI/NO)
--   v_T1/v_T2/v_T3        - Turnos (para bomberos)
--   V_TIPO_BAJA           - Tipo de baja (para bajas por enfermedad)
--   V_ID_USUARIO          - Usuario que realiza el alta
--   V_OBSERVACIONES       - Observaciones adicionales
--   V_DESCUENTO_BAJAS     - Descontar de bolsa (SI/NO)
--   V_DESCUENTO_DIAS      - Número de días a descontar (máx 3)
--   V_IP                  - Control de validación de reglas ('1'=validar)
--
-- Parámetros IN OUT:
--   V_ID_TIPO_FUNCIONARIO - Tipo de funcionario
--   V_FECHA_FIN           - Fecha fin (calculada)
--   V_UNICO2              - Si es permiso único
--
-- Parámetros OUT:
--   msgsalida             - Mensaje resultado
--   todook                - '0'=OK, '1'=Error
--
-- Historial:
--   04/12/2025 - Carlos - Optimización v2.0
--   13/02/2019 - CHM - Regeneración de saldo finger
--   07/04/2017 - CHM - Añadido descuento para tipo 11300
--   25/01/2017 - CHM - Control de turnos
--   01/03/2013 - CHM - Descuento por baja enfermedad
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE RRHH.PERMISOS_ALTA_RRHH_NEW (
          V_ID_ANO IN NUMBER,
          V_ID_FUNCIONARIO IN NUMBER,
          V_ID_TIPO_FUNCIONARIO IN OUT VARCHAR2,
          V_ID_TIPO_PERMISO IN VARCHAR2,
          V_ID_ESTADO_PERMISO IN VARCHAR2,
          V_ID_TIPO_DIAS IN VARCHAR2,
          V_FECHA_INICIO IN DATE,
          V_FECHA_FIN IN OUT DATE,
          V_HORA_INICIO IN VARCHAR2,
          V_HORA_FIN IN VARCHAR2,
          V_ID_GRADO IN VARCHAR2,
          V_DPROVINCIA IN VARCHAR2,
          V_JUSTIFICACION IN VARCHAR2,
          v_T1 IN VARCHAR2,
          v_T2 IN VARCHAR2,
          v_t3 IN VARCHAR2,
          V_UNICO2 OUT VARCHAR2,
          V_TIPO_BAJA IN VARCHAR2,
          msgsalida OUT VARCHAR2,
          todook OUT VARCHAR2,
          V_ID_USUARIO IN VARCHAR2,
          V_OBSERVACIONES IN VARCHAR2,
          V_DESCUENTO_BAJAS IN VARCHAR2,
          V_DESCUENTO_DIAS IN VARCHAR2,
          V_IP IN VARCHAR2
) IS
  
  --------------------------------------------------------------------------------
  -- CONSTANTES
  --------------------------------------------------------------------------------
  C_OK CONSTANT VARCHAR2(1) := '0';
  C_ERROR CONSTANT VARCHAR2(1) := '1';
  
  -- Tipos de permiso
  C_PERMISO_VACACIONES CONSTANT VARCHAR2(5) := '01000';
  C_PERMISO_ASUNTOS_PROPIOS CONSTANT VARCHAR2(5) := '02000';
  C_PERMISO_BAJA_ENFERMEDAD CONSTANT VARCHAR2(5) := '11100';
  C_PERMISO_BAJA_SIN_DESCUENTO CONSTANT VARCHAR2(5) := '11300';
  C_PERMISO_COMPENSATORIO CONSTANT VARCHAR2(5) := '15000';
  
  -- Tipos de funcionario
  C_TIPO_FUNC_BOMBERO CONSTANT NUMBER := 23;
  
  -- Estado de permiso concedido
  C_ESTADO_CONCEDIDO CONSTANT NUMBER := 80;
  
  -- Límites y validaciones
  C_MAX_DESCUENTO_DIAS CONSTANT NUMBER := 3;
  C_VALIDAR_REGLAS CONSTANT VARCHAR2(1) := '1';
  C_FLAG_SI CONSTANT VARCHAR2(2) := 'SI';
  C_FLAG_NO CONSTANT VARCHAR2(2) := 'NO';
  C_CODINCI_EXCLUIR CONSTANT NUMBER := 999;
  
  --------------------------------------------------------------------------------
  -- VARIABLES LOCALES (OPTIMIZADAS)
  --------------------------------------------------------------------------------
  
  -- Control de flujo
  i_ficha NUMBER(1);
  i_todo_ok_B NUMBER(1);
  i_no_hay_permisos NUMBER(1);
  i_reglas NUMBER(1);
  i_dias_descuenta NUMBER;
  
  -- Datos del permiso
  v_num_dias NUMBER;
  v_num_dias_tiene_per NUMBER;
  v_id_tipo_dias_per VARCHAR2(1);
  v_id_tipo_dias_ent VARCHAR2(10);
  v_unico VARCHAR2(5);
  v_provincias VARCHAR2(5);
  
  -- Fichaje biométrico
  v_codpers VARCHAR2(5);
  i_codpers VARCHAR2(5);
  i_id_funcionario NUMBER(6);
  
  -- Compensatorios
  v_total_horas NUMBER;
  v_total_horas_mete VARCHAR2(5);
  
  -- Turnos (bomberos)
  i_t1 NUMBER(1) := 0;
  V_GUARDIAS VARCHAR2(2000);
  
  -- Usuario y mensajes
  V_ID_USUARIO2 VARCHAR2(50);
  msgBasico VARCHAR2(500);
  
BEGIN
  
  --------------------------------------------------------------------------------
  -- FASE 1: INICIALIZACIÓN
  --------------------------------------------------------------------------------
  
  todook := C_ERROR;
  msgsalida := '';
  V_GUARDIAS := '';
  V_ID_USUARIO2 := V_ID_USUARIO;
  v_id_tipo_dias_ent := V_ID_TIPO_DIAS;
  i_no_hay_permisos := 1;
  
  --------------------------------------------------------------------------------
  -- FASE 2: CONFIGURACIÓN DE VALIDACIÓN DE REGLAS
  -- Si V_IP = '1' se activan todas las validaciones de negocio
  --------------------------------------------------------------------------------
  
  i_reglas := 0;
  IF V_IP IS NOT NULL AND V_IP = C_VALIDAR_REGLAS THEN
    i_reglas := 1;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 3: VALIDAR USUARIO
  -- El usuario de RRHH es obligatorio
  --------------------------------------------------------------------------------
  
  IF V_ID_USUARIO IS NULL OR V_ID_USUARIO = '' THEN
    msgsalida := 'Error, vuelva a entrar en la intranet';
    ROLLBACK;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 4: VERIFICAR SI EL PERMISO ES ÚNICO
  -- Permisos únicos: solo se puede tener uno activo de ese tipo
  --------------------------------------------------------------------------------
  
  -- Compensatorios siempre son únicos
  IF V_ID_TIPO_PERMISO = C_PERMISO_COMPENSATORIO THEN
    V_UNICO := C_FLAG_SI;
  END IF;
  
  -- Si no viene informado, consultar en tabla de tipos
  IF V_UNICO IS NULL THEN
    BEGIN
      SELECT unico
        INTO V_unico
        FROM TR_TIPO_permiso
       WHERE id_tipo_permiso = V_ID_TIPO_PERMISO 
         AND id_ano = V_ID_ANO;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_no_hay_permisos := 0;
    END;
    
    IF i_no_hay_permisos = 0 THEN
      msgsalida := 'Tipo de permiso no encontrado en TR_TIPO_PERMISO.';
      ROLLBACK;
      RETURN;
    END IF;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 5: CALCULAR NÚMERO DE TURNOS (BOMBEROS)
  -- Actualización: 25/01/2017 - CHM
  --------------------------------------------------------------------------------
  
  IF V_T1 = '1' THEN
    i_t1 := i_t1 + 1;
  END IF;
  
  IF V_T2 = '1' THEN
    i_t1 := i_t1 + 1;
  END IF;
  
  IF V_T3 = '1' THEN
    i_t1 := i_t1 + 1;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 6: CHEQUEO BÁSICO DEL PERMISO
  -- Valida fechas, solapamientos, disponibilidad de días, etc.
  --------------------------------------------------------------------------------
  
  Chequeo_Basico_NEW(
    V_ID_ANO,
    V_ID_FUNCIONARIO,
    V_ID_TIPO_FUNCIONARIO,
    V_ID_TIPO_PERMISO,
    v_id_tipo_dias_ent,
    V_FECHA_INICIO,
    V_FECHA_FIN,
    V_HORA_INICIO,
    V_HORA_FIN,
    V_UNICO,
    V_DPROVINCIA,
    V_ID_GRADO,
    i_t1,
    v_num_dias,
    v_id_tipo_dias_per,
    v_num_dias_tiene_per,
    i_todo_ok_B,
    msgBasico,
    i_reglas,
    1  -- No comprobar límite 3 días (añadido 06/04/2010)
  );
  
  IF i_todo_ok_B = 1 THEN
    msgsalida := msgbasico;
    ROLLBACK;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 7: CHEQUEO ESPECÍFICO DE VACACIONES (NO BOMBEROS)
  --------------------------------------------------------------------------------
  
  IF (V_ID_TIPO_PERMISO = C_PERMISO_VACACIONES OR
      V_ID_TIPO_PERMISO = C_PERMISO_ASUNTOS_PROPIOS OR
      V_ID_TIPO_PERMISO IN ('02081', '02082', '02162', '02241', '02242', '02015') OR
      SUBSTR(V_ID_TIPO_PERMISO, 1, 3) = '030' OR
      V_ID_TIPO_PERMISO = C_PERMISO_COMPENSATORIO) 
     AND V_ID_TIPO_FUNCIONARIO <> C_TIPO_FUNC_BOMBERO THEN
    
    chequeo_vacaciones_new(
      v_id_ano,
      v_id_funcionario,
      v_id_tipo_funcionario,
      v_id_tipo_permiso,
      v_id_tipo_dias_ent,
      v_fecha_inicio,
      v_fecha_fin,
      v_num_dias,
      i_todo_ok_B,
      msgbasico,
      i_reglas
    );
    
    IF i_todo_ok_B = 1 THEN
      msgsalida := msgbasico;
      ROLLBACK;
      RETURN;
    END IF;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 8: CHEQUEO ESPECÍFICO DE VACACIONES (BOMBEROS)
  --------------------------------------------------------------------------------
  
  IF V_ID_TIPO_PERMISO = C_PERMISO_VACACIONES 
     AND V_ID_TIPO_FUNCIONARIO = C_TIPO_FUNC_BOMBERO THEN
    
    Chequeo_VACACIONES_BOMBEROS(
      v_id_ano,
      v_id_funcionario,
      v_id_tipo_funcionario,
      v_id_tipo_permiso,
      v_id_tipo_dias_ent,
      v_fecha_inicio,
      v_fecha_fin,
      v_num_dias,
      V_GUARDIAS,
      i_todo_ok_B,
      msgbasico,
      1  -- Comprobar reglas
    );
    
    IF i_todo_ok_B = 1 THEN
      msgsalida := msgbasico;
      ROLLBACK;
      RETURN;
    END IF;
  END IF;
  
  -- Agregar observaciones de guardias para bomberos
  V_GUARDIAS := V_GUARDIAS || ' ' || V_OBSERVACIONES;
  
  --------------------------------------------------------------------------------
  -- FASE 9: CHEQUEO DE COMPENSATORIO POR HORAS
  --------------------------------------------------------------------------------
  
  IF V_ID_TIPO_PERMISO = C_PERMISO_COMPENSATORIO THEN
    chequeo_compensatorio(
      v_id_ano,
      v_id_funcionario,
      v_fecha_inicio,
      v_fecha_fin,
      v_hora_inicio,
      v_hora_fin,
      v_total_horas,
      i_todo_ok_B,
      msgbasico
    );
    
    IF i_todo_ok_B = 1 THEN
      msgsalida := msgbasico;
      ROLLBACK;
      RETURN;
    END IF;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 10: ACTUALIZAR PERMISOS ÚNICOS
  -- Si es permiso único y ya existe uno activo, se actualiza
  --------------------------------------------------------------------------------
  
  IF V_UNICO = C_FLAG_SI AND V_ID_TIPO_PERMISO <> C_PERMISO_COMPENSATORIO THEN
    ACTUALIZAR_UNICO_NEW(
      V_ID_ANO,
      V_ID_FUNCIONARIO,
      V_ID_TIPO_FUNCIONARIO,
      V_ID_TIPO_PERMISO,
      v_id_tipo_dias_ent,
      V_ID_TIPO_DIAS_PER,
      V_FECHA_INICIO,
      V_FECHA_FIN,
      V_NUM_DIAS,
      v_num_dias_tiene_per,
      i_todo_ok_B,
      msgbasico,
      i_reglas,
      0
    );
    
    IF i_todo_ok_B = 1 THEN
      msgsalida := msgbasico;
      ROLLBACK;
      RETURN;
    END IF;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 11: DESCUENTO POR BAJA POR ENFERMEDAD
  -- Actualización: 01/03/2013 - CHM
  -- Actualización: 07/04/2017 - CHM - Añadido tipo 11300
  --------------------------------------------------------------------------------
  
  IF V_ID_TIPO_PERMISO = C_PERMISO_BAJA_ENFERMEDAD OR
     (V_ID_TIPO_PERMISO = C_PERMISO_BAJA_SIN_DESCUENTO AND V_DESCUENTO_BAJAS = C_FLAG_SI) THEN
    
    -- Validar número de días a descontar
    IF V_DESCUENTO_BAJAS = C_FLAG_SI AND V_DESCUENTO_DIAS IS NULL THEN
      msgsalida := 'Descuento a bolsa número de días tiene que ser mayor que 0.';
      ROLLBACK;
      RETURN;
    END IF;
    
    IF V_DESCUENTO_DIAS > C_MAX_DESCUENTO_DIAS AND V_DESCUENTO_DIAS IS NOT NULL THEN
      msgsalida := 'Descuento a bolsa son solo máximo 3 días.';
      ROLLBACK;
      RETURN;
    END IF;
    
    -- Determinar días a descontar
    IF V_ID_TIPO_PERMISO = C_PERMISO_BAJA_ENFERMEDAD THEN
      i_dias_descuenta := v_num_dias;
    ELSE
      i_dias_descuenta := NVL(V_DESCUENTO_DIAS, 0);
    END IF;
    
    -- Regenerar saldo finger (actualización: 13/02/2019 - CHM)
    finger_regenera_saldo(
      v_id_funcionario,
      devuelve_periodo(TO_CHAR(V_FECHA_INICIO, 'dd/mm/yyyy')),
      0
    );
    
    -- Descontar días de la bolsa
    MOV_BOLSA_DESCUENTO_ENFERME(
      V_ID_ANO,
      V_ID_FUNCIONARIO,
      V_ID_TIPO_FUNCIONARIO,
      V_FECHA_INICIO,
      i_dias_descuenta,
      i_todo_ok_B,
      msgbasico
    );
    
    IF i_todo_ok_B = 1 THEN
      msgsalida := msgbasico;
      ROLLBACK;
      RETURN;
    END IF;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 12: PREPARAR DATOS PARA INSERCIÓN
  -- Para bajas tipo 11300, usar V_TIPO_BAJA como provincia
  --------------------------------------------------------------------------------
  
  IF V_ID_TIPO_PERMISO = C_PERMISO_BAJA_SIN_DESCUENTO THEN
    v_provincias := V_TIPO_BAJA;
  ELSE
    v_provincias := v_dprovincia;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 13: INSERTAR PERMISO Y ENVIAR CORREO
  --------------------------------------------------------------------------------
  
  inserta_permiso_rrhh_new(
    V_id_USUARIO2,
    v_id_ano,
    v_id_funcionario,
    v_id_tipo_funcionario,
    v_id_tipo_permiso,
    v_id_tipo_dias_ent,
    v_fecha_inicio,
    v_fecha_fin,
    v_hora_inicio,
    v_hora_fin,
    v_unico,
    v_provincias,
    v_id_GRADO,
    v_justificacion,
    v_num_dias,
    v_total_horas,
    v_T1,
    v_T2,
    v_t3,
    i_todo_ok_B,
    msgbasico,
    V_GUARDIAS,
    V_DESCUENTO_BAJAS,
    V_DESCUENTO_DIAS
  );
  
  IF i_todo_ok_B = 1 THEN
    msgsalida := msgbasico;
    ROLLBACK;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 14: ACTUALIZAR SISTEMA DE FICHAJE BIOMÉTRICO
  -- Verificar si el funcionario tiene fichaje activo
  --------------------------------------------------------------------------------
  
  i_ficha := 1;
  BEGIN
    SELECT DISTINCT codigo
      INTO i_codpers
      FROM personal_new p,
           persona pr,
           apliweb_usuario u
     WHERE p.id_funcionario = V_ID_FUNCIONARIO
       AND LPAD(p.id_funcionario, 6, '0') = LPAD(u.id_funcionario, 6, '0')
       AND u.id_fichaje IS NOT NULL
       AND u.id_fichaje = pr.codigo
       AND ROWNUM < 2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_ficha := 0;
  END;
  
  v_codpers := i_codpers;
  
  --------------------------------------------------------------------------------
  -- FASE 15: ACTUALIZAR FINGER SEGÚN TIPO DE PERMISO
  -- Actualización: 14/02/2018 - CHM
  --------------------------------------------------------------------------------
  
  -- Para permisos generales con fichaje
  IF I_FICHA = 1 AND V_ID_TIPO_PERMISO <> C_PERMISO_COMPENSATORIO 
     AND V_JUSTIFICACION <> C_FLAG_NO THEN
    
    actualiza_finger(
      v_id_ano,
      v_id_funcionario,
      v_id_tipo_permiso,
      v_fecha_inicio,
      v_fecha_fin,
      V_codpers,
      C_ESTADO_CONCEDIDO,  -- Estado 80 (Concedido)
      i_todo_ok_B,
      msgbasico
    );
    
    IF i_todo_ok_B = 1 THEN
      msgsalida := msgbasico;
      ROLLBACK;
      RETURN;
    END IF;
    
  -- Para compensatorios con fichaje
  ELSIF I_FICHA = 1 AND V_ID_TIPO_PERMISO = C_PERMISO_COMPENSATORIO THEN
    
    -- Formatear horas (HH:MM)
    v_total_horas_mete := LPAD(TRUNC(V_total_horas / 60), 2, '0') || ':' || 
                          LPAD(MOD(V_total_horas, 60), 2, '0');
    
    -- Insertar fichaje en transacciones y persfich
    mete_fichaje_finger_new(
      V_id_ano,
      V_id_funcionario,
      V_fecha_inicio,
      v_hora_inicio,
      V_hora_fin,
      V_codpers,
      v_total_horas_mete,
      C_PERMISO_COMPENSATORIO,
      i_todo_ok_B,
      msgbasico
    );
    
    IF i_todo_ok_B = 1 THEN
      msgsalida := msgbasico;
      ROLLBACK;
      RETURN;
    END IF;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 16: FINALIZACIÓN EXITOSA
  --------------------------------------------------------------------------------
  
  COMMIT;
  msgsalida := 'La solicitud ha sido incorporada en el programa de RRHH.';
  todook := C_OK;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Manejo robusto de excepciones no controladas
    todook := C_ERROR;
    msgsalida := 'Error inesperado al dar de alta permiso: ' || SQLERRM ||
                 ' | Funcionario: ' || V_ID_FUNCIONARIO ||
                 ' | Tipo Permiso: ' || V_ID_TIPO_PERMISO;
    ROLLBACK;
    
END PERMISOS_ALTA_RRHH_NEW;
/

