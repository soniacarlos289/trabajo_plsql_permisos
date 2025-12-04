--------------------------------------------------------------------------------
-- PROCEDURE: INSERTA_PERMISO_RRHH
--------------------------------------------------------------------------------
-- Propósito: Insertar permiso concedido directamente por RRHH (versión legacy)
-- Autor: RRHH / Optimizado por Carlos (04/12/2025)
-- Versión: 2.0.0
--
-- Descripción:
--   Inserta un nuevo permiso con estado CONCEDIDO (80) directamente.
--   El permiso ya está aprobado por JS, JA y RRHH desde el inicio.
--   Usado para altas manuales de permisos retroactivos o especiales.
--
-- Nota: Versión legacy. Para nuevas implementaciones usar INSERTA_PERMISO_RRHH_NEW
--       que soporta turnos de bomberos y descuentos de bolsa.
--
-- Parámetros:
--   V_ID_USUARIO          - Usuario RRHH que inserta (IN)
--   V_ID_ANO              - Año del permiso (IN)
--   V_ID_FUNCIONARIO      - ID funcionario (IN)
--   V_ID_TIPO_FUNCIONARIO - Tipo funcionario (IN)
--   V_ID_TIPO_PERMISO     - Código tipo permiso (IN)
--   V_ID_TIPO_DIAS        - Tipo días L/N/H (IN OUT)
--   V_FECHA_INICIO        - Fecha inicio (IN)
--   V_FECHA_FIN           - Fecha fin (IN)
--   V_HORA_INICIO         - Hora inicio (IN)
--   V_HORA_FIN            - Hora fin (IN)
--   V_UNICO               - Permiso único SI/NO (IN)
--   V_DPROVINCIA          - Provincia (IN)
--   V_ID_GRADO            - Grado funcionario (IN)
--   V_JUSTIFICACION       - Justificación requerida (IN)
--   V_NUM_DIAS            - Número de días (IN)
--   v_total_horas         - Total horas (compensatorios) (IN)
--   todo_ok_Basico        - 0=OK, 1=Error (OUT)
--   msgBasico             - Mensaje resultado (OUT)
--   V_OBSERVACIONES       - Observaciones (IN)
--
-- Historial:
--   04/12/2025 - Carlos - Optimización v2.0
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE RRHH."INSERTA_PERMISO_RRHH" (
        V_ID_USUARIO IN VARCHAR2,
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
        todo_ok_Basico OUT INTEGER,
        msgBasico OUT VARCHAR2,
        V_OBSERVACIONES IN VARCHAR2
) IS

  --------------------------------------------------------------------------------
  -- CONSTANTES
  --------------------------------------------------------------------------------
  C_OK CONSTANT INTEGER := 0;
  C_ERROR CONSTANT INTEGER := 1;
  C_ESTADO_CONCEDIDO CONSTANT NUMBER := 80;
  C_FLAG_NO CONSTANT VARCHAR2(2) := 'NO';
  
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
  
  -- Auxiliares
  i_fecha VARCHAR2(10);
  i_hora VARCHAR2(10);
  i_id_ano VARCHAR2(4);

BEGIN
  
  --------------------------------------------------------------------------------
  -- FASE 1: INICIALIZACIÓN
  --------------------------------------------------------------------------------
  
  todo_ok_basico := C_OK;
  msgBasico := '';
  i_Estado_permiso := C_ESTADO_CONCEDIDO;
  i_fecha_rrhh := SYSDATE;
  
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
  
  -- Establecer firmantes (mismo usuario RRHH para todos los niveles)
  i_firmado_js := V_ID_USUARIO;
  I_fecha_js := SYSDATE;
  i_firmado_ja := V_ID_USUARIO;
  I_fecha_ja := SYSDATE;
  I_firmado_rrhh := V_ID_USUARIO;
  I_fecha_rrhh := SYSDATE;
  
  --------------------------------------------------------------------------------
  -- FASE 3: INSERTAR PERMISO CON ESTADO CONCEDIDO (80)
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
    OBSERVACIONES
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
    V_ID_USUARIO,
    TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/YY'), 'DD/MM/YY'),
    V_OBSERVACIONES
  );
  
  --------------------------------------------------------------------------------
  -- FASE 4: FINALIZACIÓN EXITOSA
  --------------------------------------------------------------------------------
  
  msgBasico := 'Permiso insertado correctamente con ID: ' || i_secuencia_permiso;
  
EXCEPTION
  WHEN OTHERS THEN
    -- Manejo robusto de excepciones
    todo_ok_basico := C_ERROR;
    msgBasico := 'Error al insertar permiso: ' || SQLERRM;
    ROLLBACK;

END INSERTA_PERMISO_RRHH;
/

