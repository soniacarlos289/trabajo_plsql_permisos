--------------------------------------------------------------------------------
-- PROCEDURE: INSERTA_PERMISO_RRHH_NEW
--------------------------------------------------------------------------------
-- Propósito: Insertar permiso concedido directamente por RRHH (versión mejorada)
-- Autor: RRHH / Optimizado por Carlos (04/12/2025)
-- Versión: 2.0.0
--
-- Descripción:
--   Versión mejorada de INSERTA_PERMISO_RRHH con soporte para:
--   - Turnos de bomberos (T1, T2, T3)
--   - Descuento a bolsa por baja (bajas 11300)
--   - Tipo de baja (campo adicional para clasificación)
--   - Validación de usuario (usar 101235 si es NULL)
--
--   Inserta un nuevo permiso con estado CONCEDIDO (80) directamente.
--   El permiso ya está aprobado por JS, JA y RRHH desde el inicio.
--
-- Parámetros adicionales vs versión legacy:
--   V_t1, V_t2, V_t3          - Turnos bomberos (IN)
--   V_DESCUENTO_BAJAS         - Descontar de bolsa SI/NO (IN)
--   V_DESCUENTO_DIAS          - Días a descontar (IN)
--
-- Historial:
--   04/12/2025 - Carlos - Optimización v2.0
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE RRHH."INSERTA_PERMISO_RRHH_NEW" (
        V_ID_USUARIO IN OUT VARCHAR2,
        V_ID_ANO IN NUMBER,
        V_ID_FUNCIONARIO IN NUMBER,
        V_ID_TIPO_FUNCIONARIO IN NUMBER,
        V_ID_TIPO_PERMISO IN VARCHAR2,
        V_ID_TIPO_DIAS IN OUT VARCHAR2,
        V_FECHA_INICIO IN DATE,
        V_FECHA_FIN IN DATE,
        V_HORA_INICIO IN VARCHAR2,
        V_HORA_FIN IN VARCHAR2,
        V_UNICO IN VARCHAR2,
        V_DPROVINCIA IN VARCHAR2,
        V_ID_GRADO IN VARCHAR2,
        V_JUSTIFICACION IN VARCHAR2,
        V_NUM_DIAS IN NUMBER,
        v_total_horas IN NUMBER,
        V_t1 IN VARCHAR2,
        V_t2 IN VARCHAR2,
        V_t3 IN VARCHAR2,
        todo_ok_Basico OUT INTEGER,
        msgBasico OUT VARCHAR2,
        V_OBSERVACIONES IN VARCHAR2,
        V_DESCUENTO_BAJAS IN VARCHAR2,
        V_DESCUENTO_DIAS IN VARCHAR2
) IS

  --------------------------------------------------------------------------------
  -- CONSTANTES
  --------------------------------------------------------------------------------
  C_OK CONSTANT INTEGER := 0;
  C_ERROR CONSTANT INTEGER := 1;
  C_ESTADO_CONCEDIDO CONSTANT NUMBER := 80;
  C_FLAG_NO CONSTANT VARCHAR2(2) := 'NO';
  C_PERMISO_BAJA_SIN_DESCUENTO CONSTANT VARCHAR2(5) := '11300';
  C_USUARIO_DEFAULT CONSTANT VARCHAR2(6) := '101235';
  
  --------------------------------------------------------------------------------
  -- VARIABLES LOCALES (OPTIMIZADAS)
  --------------------------------------------------------------------------------
  
  -- Secuencias
  i_secuencia_operacion NUMBER;
  i_secuencia_permiso NUMBER;
  
  -- Fechas y firma
  i_Estado_permiso NUMBER;
  i_fecha_js DATE;
  i_fecha_ja DATE;
  i_fecha_rrhh DATE;
  i_firmado_js VARCHAR2(6);
  i_firmado_ja VARCHAR2(6);
  I_firmado_rrhh VARCHAR2(6);
  i_tipo_baja VARCHAR2(6);
  
  -- Auxiliares
  i_fecha VARCHAR2(10);
  i_hora VARCHAR2(10);
  i_id_ano VARCHAR2(4);

BEGIN
  
  --------------------------------------------------------------------------------
  -- FASE 1: INICIALIZACIÓN Y VALIDACIÓN DE USUARIO
  --------------------------------------------------------------------------------
  
  todo_ok_basico := C_OK;
  msgBasico := '';
  i_Estado_permiso := C_ESTADO_CONCEDIDO;
  i_fecha_rrhh := SYSDATE;
  
  -- Validar usuario (usar default si es NULL/vacío)
  IF UPPER(V_ID_USUARIO) = 'NULL' OR V_ID_USUARIO IS NULL OR 
     V_ID_USUARIO = 'null' OR V_ID_USUARIO = '' THEN
    V_ID_USUARIO := C_USUARIO_DEFAULT;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 2: GENERAR SECUENCIAS
  --------------------------------------------------------------------------------
  
  SELECT sec_operacion.NEXTVAL,
         sec_permiso.NEXTVAL,
         TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
         TO_CHAR(SYSDATE, 'HH:MI'),
         TO_CHAR(SYSDATE, 'YYYY')
    INTO i_secuencia_operacion,
         i_secuencia_permiso,
         i_fecha,
         i_hora,
         i_id_ano
    FROM DUAL;
  
  -- Establecer firmantes
  i_firmado_js := NVL(V_ID_USUARIO, 0);
  I_fecha_js := SYSDATE;
  i_firmado_ja := NVL(V_ID_USUARIO, 0);
  I_fecha_ja := SYSDATE;
  I_firmado_rrhh := NVL(V_ID_USUARIO, 0);
  I_fecha_rrhh := SYSDATE;
  
  --------------------------------------------------------------------------------
  -- FASE 3: PREPARAR TIPO DE BAJA
  -- Para bajas 11300, el campo DPROVINCIA contiene el tipo de baja
  --------------------------------------------------------------------------------
  
  IF V_ID_TIPO_PERMISO = C_PERMISO_BAJA_SIN_DESCUENTO THEN
    i_tipo_baja := V_DPROVINCIA;
  ELSE
    i_tipo_baja := '';
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 4: INSERTAR PERMISO CON CAMPOS EXTENDIDOS
  -- Incluye turnos, tipo baja y descuentos
  --------------------------------------------------------------------------------
  
  INSERT INTO permiso (
    id_permiso,
    id_ano,
    id_funcionario,
    id_tipo_permiso,
    id_estado,
    firmado_js,
    fecha_js,
    firmado_ja,
    fecha_ja,
    firmado_rrhh,
    fecha_rrhh,
    fecha_inicio,
    fecha_fin,
    num_dias,
    hora_inicio,
    hora_fin,
    total_horas,
    id_tipo_dias,
    dprovincia,
    ID_GRADO,
    ANULADO,
    justificacion,
    id_usuario,
    fecha_modi,
    OBSERVACIONES,
    tu1_14_22,
    tu2_22_06,
    tu3_04_14,
    TIPO_BAJA,
    descuento_bajas,
    descuento_dias
  )
  VALUES (
    i_secuencia_permiso,
    V_id_ANO,
    V_ID_FUNCIONARIO,
    V_ID_TIPO_PERMISO,
    i_estado_permiso,
    i_firmado_js,
    i_fecha_js,
    i_firmado_ja,
    i_fecha_ja,
    i_firmado_rrhh,
    i_fecha_rrhh,
    TO_DATE(TO_CHAR(V_FECHA_INICIO, 'DD/MM/YY'), 'DD/MM/YY'),
    TO_DATE(TO_CHAR(V_FECHA_FIN, 'DD/MM/YY'), 'DD/MM/YY'),
    V_NUM_DIAS,
    V_HORA_INICIO,
    V_HORA_FIN,
    v_total_horas,
    V_ID_TIPO_DIAS,
    V_DPROVINCIA,
    V_ID_GRADO,
    C_FLAG_NO,
    V_JUSTIFICACION,
    NVL(V_ID_USUARIO, 0),
    TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YY'), 'DD/MM/YY'),
    V_OBSERVACIONES,
    TO_NUMBER(v_t1),
    TO_NUMBER(v_t2),
    TO_NUMBER(v_t3),
    i_tipo_baja,
    V_DESCUENTO_BAJAS,
    V_DESCUENTO_DIAS
  );
  
  --------------------------------------------------------------------------------
  -- FASE 5: FINALIZACIÓN EXITOSA
  --------------------------------------------------------------------------------
  
  msgBasico := 'Permiso insertado correctamente con ID: ' || i_secuencia_permiso;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Manejo robusto de excepciones
    todo_ok_basico := C_ERROR;
    msgBasico := 'Error al insertar permiso: ' || SQLERRM;
    ROLLBACK;

END INSERTA_PERMISO_RRHH_NEW;
/

