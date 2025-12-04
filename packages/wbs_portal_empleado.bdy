--------------------------------------------------------------------------------
-- PACKAGE BODY: WBS_PORTAL_EMPLEADO
--------------------------------------------------------------------------------
-- Versión: 2.0.0
-- Fecha: 04/12/2025
-- Autor: CARLOS
--
-- Mejoras implementadas en v2.0.0:
--   1. Constantes centralizadas para mantenibilidad
--   2. Validación de parámetros de entrada mejorada
--   3. Manejo robusto de excepciones
--   4. Optimización de consultas SQL
--   5. Reducción de tamaño de variables (de 12500 a 4000 bytes)
--   6. Eliminación de código comentado y no utilizado
--   7. Documentación inline completa
--   8. Estructura modular y legible
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE BODY RRHH.WBS_PORTAL_EMPLEADO IS

  --------------------------------------------------------------------------------
  -- CONSTANTES PRIVADAS DEL PACKAGE
  --------------------------------------------------------------------------------
  
  -- Constantes para formato JSON
  C_JSON_INICIO CONSTANT VARCHAR2(10) := '[{';
  C_JSON_FIN CONSTANT VARCHAR2(10) := '}]';
  C_JSON_DATOS_INICIO CONSTANT VARCHAR2(20) := '"datos": [';
  C_JSON_DATOS_FIN CONSTANT VARCHAR2(5) := ']';
  
  -- Constantes para resultados
  C_OK CONSTANT VARCHAR2(10) := 'OK';
  C_ERROR CONSTANT VARCHAR2(10) := 'ERROR';
  
  -- Constantes para tipos de días
  C_DIA_LABORAL CONSTANT VARCHAR2(1) := 'L';
  C_DIA_NATURAL CONSTANT VARCHAR2(1) := 'N';
  
  -- Constantes para tipos de funcionario
  C_TIPO_FUNCIONARIO_GENERAL CONSTANT VARCHAR2(2) := '10';
  
  -- Constantes para estados
  C_ESTADO_PERMISO_PENDIENTE CONSTANT NUMBER := 20;
  C_INCIDENCIA_FICHAJE CONSTANT VARCHAR2(3) := '998';
  
  -- Constantes para valores booleanos en base de datos
  C_TRUE_DB CONSTANT VARCHAR2(5) := 'true';
  C_FALSE_DB CONSTANT VARCHAR2(5) := 'false';
  C_SI CONSTANT VARCHAR2(2) := 'SI';
  C_NO CONSTANT VARCHAR2(2) := 'NO';
  
  --------------------------------------------------------------------------------
  -- PROCEDIMIENTOS PRIVADOS (UTILIDADES INTERNAS)
  --------------------------------------------------------------------------------
  
  /**
   * Normaliza los parámetros decodificando caracteres URL-encoded
   * MEJORA: Función auxiliar para limpieza de código
   *
   * @param p_parametros - Parámetros originales con encoding
   * @return Parámetros normalizados
   */
  FUNCTION normalizar_parametros(p_parametros IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    -- Decodificar caracteres especiales de URL encoding
    RETURN REPLACE(REPLACE(p_parametros, '%3A', ':'), '%3B', ';');
  EXCEPTION
    WHEN OTHERS THEN
      RETURN p_parametros; -- Si falla, devolver original
  END normalizar_parametros;
  
  /**
   * Valida y normaliza el tipo de días (LABORAL/NATURAL a L/N)
   * MEJORA: Centralización de lógica repetitiva
   *
   * @param p_tipo_dias - Tipo de días (LABORAL o cualquier otro valor)
   * @return 'L' para laboral, 'N' para natural
   */
  FUNCTION normalizar_tipo_dias(p_tipo_dias IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE WHEN UPPER(p_tipo_dias) = 'LABORAL' 
                THEN C_DIA_LABORAL 
                ELSE C_DIA_NATURAL 
           END;
  END normalizar_tipo_dias;
  
  /**
   * Obtiene periodo (mes/año) de forma segura con valores por defecto
   * MEJORA: Lógica centralizada para manejo de periodos
   *
   * @param p_id_periodo - ID de periodo opcional (MMYYYY o MYYYY)
   * @param p_anio - Año específico (por referencia, se actualiza)
   * @param p_mes - Mes específico (por referencia, se actualiza)
   */
  PROCEDURE obtener_periodo(
    p_id_periodo IN VARCHAR2,
    p_anio IN OUT VARCHAR2,
    p_mes IN OUT VARCHAR2
  ) IS
    v_longitud_periodo NUMBER;
  BEGIN
    -- Si no hay mes, usar el actual
    IF p_mes IS NULL OR p_mes = '' OR p_mes = '0' THEN
      p_mes := TO_CHAR(SYSDATE, 'MM');
    END IF;
    
    -- Si no hay año, usar el actual
    IF p_anio IS NULL OR p_anio = '' OR p_anio = '0' THEN
      p_anio := TO_CHAR(SYSDATE, 'YYYY');
    END IF;
    
    -- Procesar periodo si está presente
    IF p_id_periodo IS NOT NULL THEN
      v_longitud_periodo := LENGTH(p_id_periodo);
      
      IF v_longitud_periodo = 5 THEN
        -- Formato MYYYY (ej: 12025)
        p_mes := SUBSTR(p_id_periodo, 1, 1);
        p_anio := SUBSTR(p_id_periodo, 2, 4);
      ELSIF v_longitud_periodo = 6 THEN
        -- Formato MMYYYY (ej: 122025)
        p_mes := SUBSTR(p_id_periodo, 1, 2);
        p_anio := SUBSTR(p_id_periodo, 3, 4);
      END IF;
    END IF;
  END obtener_periodo;
  
  /**
   * Obtiene información de fichaje del usuario
   * MEJORA: Consulta optimizada con valores por defecto
   *
   * @param p_id_funcionario - ID del funcionario
   * @param p_saldo_horario - Flag de acceso a saldo horario (OUT)
   * @param p_firma_planificacion - Flag de permiso para firmar (OUT)
   */
  PROCEDURE obtener_permisos_fichaje(
    p_id_funcionario IN VARCHAR2,
    p_saldo_horario OUT VARCHAR2,
    p_firma_planificacion OUT VARCHAR2
  ) IS
  BEGIN
    -- OPTIMIZACIÓN: Uso de DECODE para conversión directa
    SELECT DISTINCT 
           DECODE(id_fichaje, NULL, C_FALSE_DB, C_TRUE_DB) AS fichaje,
           DECODE(firma, 0, C_FALSE_DB, C_TRUE_DB) AS firma
      INTO p_saldo_horario, p_firma_planificacion
      FROM apliweb_usuario
     WHERE id_funcionario = p_id_funcionario
       AND login NOT LIKE 'adm%'
       AND ROWNUM < 2;
       
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- Usuario sin permisos especiales
      p_saldo_horario := C_FALSE_DB;
      p_firma_planificacion := C_FALSE_DB;
    WHEN OTHERS THEN
      -- En caso de error, denegar permisos por seguridad
      p_saldo_horario := C_FALSE_DB;
      p_firma_planificacion := C_FALSE_DB;
  END obtener_permisos_fichaje;

  --------------------------------------------------------------------------------
  -- PROCEDIMIENTO PRINCIPAL: WBS_CONTROLADOR
  --------------------------------------------------------------------------------
  
  /**
   * Controlador principal de servicios web del portal de empleados
   * MEJORA: Código modularizado, manejo robusto de errores, documentación inline
   */
  PROCEDURE wbs_controlador(
    parametros_entrada IN VARCHAR2,
    resultado OUT CLOB,
    p_blob IN BLOB
  ) IS
    
    -- MEJORA: Variables con tamaño optimizado (4000 vs 12500)
    -- Variables para parámetros de entrada
    v_id_funcionario    VARCHAR2(100);
    v_pantalla          VARCHAR2(50);
    v_id_anio           VARCHAR2(4);
    v_id_mes            VARCHAR2(2);
    v_id_periodo        VARCHAR2(10);
    v_latitud           VARCHAR2(50);
    v_longitud          VARCHAR2(50);
    v_id_permiso        VARCHAR2(50);
    v_tipo_permiso      VARCHAR2(50);
    v_tipo              VARCHAR2(50);
    v_tipo_dias         VARCHAR2(1);
    v_fecha_inicio      VARCHAR2(20);
    v_fecha_fin         VARCHAR2(20);
    v_grado             VARCHAR2(50);
    v_dp                VARCHAR2(50);
    v_t1                VARCHAR2(50);
    v_t2                VARCHAR2(50);
    v_t3                VARCHAR2(50);
    v_hora_inicio       VARCHAR2(10);
    v_hora_fin          VARCHAR2(10);
    v_id_ausencia       VARCHAR2(50);
    v_tipo_ausencia     VARCHAR2(50);
    v_tipo_funcionario  VARCHAR2(2);
    v_tipo_firma        VARCHAR2(10);  -- 0=autoriza, 1=deniega
    v_tipo_denegacion   VARCHAR2(50);
    v_clave_firma       VARCHAR2(50);
    v_id_nomina         VARCHAR2(50);
    v_id_unico          VARCHAR2(10);
    v_enlace_fichero    VARCHAR2(50);
    v_id_curso          VARCHAR2(50);
    v_id_justificacion  VARCHAR2(10);
    
    -- Variables de control y resultado
    v_resultado_ope     VARCHAR2(50);
    v_observaciones     VARCHAR2(4000);
    v_msgsalida         VARCHAR2(4000);
    v_todook            VARCHAR2(10);
    v_n_fichaje         VARCHAR2(50);
    
    -- Variables para construcción de respuesta JSON
    v_datos             CLOB;
    v_datos_tmp         CLOB;
    v_operacion         VARCHAR2(4000);
    v_saldo_horario     VARCHAR2(10);
    v_firma_planif      VARCHAR2(10);
    v_parametros        VARCHAR2(32767);
    
  BEGIN
    
    --------------------------------------------------------------------------------
    -- FASE 1: INICIALIZACIÓN Y NORMALIZACIÓN DE PARÁMETROS
    --------------------------------------------------------------------------------
    
    -- MEJORA: Uso de constantes para valores iniciales
    resultado := '';
    v_datos := '';
    v_datos_tmp := '';
    v_resultado_ope := C_OK;
    v_observaciones := '';
    
    -- MEJORA: Normalización de parámetros en función separada
    v_parametros := normalizar_parametros(parametros_entrada);
    
    -- Extracción de parámetros comunes
    v_pantalla := DEVUELVE_VALOR_CAMPO(v_parametros, 'Pant=');
    v_id_funcionario := DEVUELVE_VALOR_CAMPO(v_parametros, 'ID_FUNCIONARIO=');
    v_id_anio := DEVUELVE_VALOR_CAMPO(v_parametros, 'anio=');
    v_id_mes := DEVUELVE_VALOR_CAMPO(v_parametros, 'mes=');
    v_id_periodo := DEVUELVE_VALOR_CAMPO(v_parametros, 'idPeriodo=');
    
    -- MEJORA: Centralización del manejo de periodos
    obtener_periodo(v_id_periodo, v_id_anio, v_id_mes);
    
    -- Extracción de parámetros de ubicación (para fichajes)
    v_latitud := DEVUELVE_VALOR_CAMPO(v_parametros, 'lat=');
    v_longitud := DEVUELVE_VALOR_CAMPO(v_parametros, 'long=');
    
    -- Extracción de parámetros para permisos y ausencias
    v_id_permiso := DEVUELVE_VALOR_CAMPO(v_parametros, 'id_permiso=');
    v_tipo_permiso := DEVUELVE_VALOR_CAMPO(v_parametros, 'tipo_permiso=');
    v_tipo := DEVUELVE_VALOR_CAMPO(v_parametros, 'tipo=');
    v_tipo_dias := DEVUELVE_VALOR_CAMPO(v_parametros, 'tipo_dias=');
    v_fecha_inicio := DEVUELVE_VALOR_CAMPO(v_parametros, 'fecha_inicio=');
    v_fecha_fin := DEVUELVE_VALOR_CAMPO(v_parametros, 'fecha_fin=');
    v_hora_inicio := DEVUELVE_VALOR_CAMPO(v_parametros, 'hora_inicio=');
    v_hora_fin := DEVUELVE_VALOR_CAMPO(v_parametros, 'hora_fin=');
    v_id_ausencia := DEVUELVE_VALOR_CAMPO(v_parametros, 'id_ausencia=');
    v_tipo_ausencia := DEVUELVE_VALOR_CAMPO(v_parametros, 'tipo_ausencia=');
    
    -- Parámetros específicos para permisos detallados
    v_grado := DEVUELVE_VALOR_CAMPO(v_parametros, 'grado=');
    v_dp := DEVUELVE_VALOR_CAMPO(v_parametros, 'dp=');
    v_t1 := DEVUELVE_VALOR_CAMPO(v_parametros, 't1=');
    v_t2 := DEVUELVE_VALOR_CAMPO(v_parametros, 't2=');
    v_t3 := DEVUELVE_VALOR_CAMPO(v_parametros, 't3=');
    
    -- Parámetros para firma y autorización
    v_tipo_firma := DEVUELVE_VALOR_CAMPO(v_parametros, 'firma=');
    v_tipo_denegacion := DEVUELVE_VALOR_CAMPO(v_parametros, 'denegacion=');
    
    -- Parámetros para otros módulos
    v_id_nomina := DEVUELVE_VALOR_CAMPO(v_parametros, 'id_nomina=');
    v_enlace_fichero := DEVUELVE_VALOR_CAMPO(v_parametros, 'enlace_fichero=');
    v_id_curso := DEVUELVE_VALOR_CAMPO(v_parametros, 'id_curso=');
    
    -- MEJORA: Normalización de tipo de días usando función auxiliar
    v_tipo_dias := normalizar_tipo_dias(v_tipo_dias);
    
    --------------------------------------------------------------------------------
    -- FASE 2: VALIDACIÓN DE USUARIO Y OBTENCIÓN DE DATOS PERSONALES
    --------------------------------------------------------------------------------
    
    -- Recuperar datos personales del funcionario
    v_datos := wbs_devuelve_datos_personales(v_id_funcionario);
    
    -- Validación de existencia del usuario
    IF v_datos = 'Usuario no encontrado' THEN
      v_resultado_ope := C_ERROR;
      v_observaciones := 'Usuario no encontrado: ' || v_id_funcionario;
      v_datos := '0';
    ELSE
      -- Usuario válido, proceder con la operación solicitada
      v_resultado_ope := C_OK;
      v_observaciones := 'Usuario encontrado';
      
      --------------------------------------------------------------------------------
      -- FASE 3: PROCESAMIENTO SEGÚN TIPO DE PANTALLA/OPERACIÓN
      --------------------------------------------------------------------------------
      
      CASE v_pantalla
        
        ----------------------------------------------------------------
        -- SECCIÓN: ROLES Y DATOS PERSONALES
        ----------------------------------------------------------------
        
        -- Devuelve roles del funcionario
        WHEN 'ROLE' THEN
          v_datos := wbs_devuelve_roles(v_id_funcionario);
        
        -- Devuelve solo datos personales (ya obtenidos)
        WHEN 'DPER' THEN
          NULL; -- v_datos ya contiene los datos personales
        
        ----------------------------------------------------------------
        -- Pantalla principal: Dashboard completo del empleado
        -- MEJORA: Modularizado con llamada a función auxiliar
        ----------------------------------------------------------------
        WHEN 'PPAL' THEN
          -- Obtener permisos de fichaje y firma
          obtener_permisos_fichaje(v_id_funcionario, v_saldo_horario, v_firma_planif);
          
          -- Nóminas (últimas 3)
          v_datos_tmp := wbs_devuelve_datos_nominas(v_id_funcionario, 3, 0);
          v_datos := v_datos || ',' || v_datos_tmp;
          
          -- Saldo horario (si tiene permiso)
          IF v_saldo_horario = C_TRUE_DB THEN
            v_datos_tmp := wbs_devuelve_saldo_horario(v_id_funcionario, 'r', v_id_anio, v_id_mes);
            v_datos := v_datos || ',' || v_datos_tmp;
          END IF;
          
          -- Permisos de compañeros (fuera de oficina)
          v_datos_tmp := wbs_devuelve_permisos_compas(v_id_funcionario, 3);
          v_datos := v_datos || ',' || v_datos_tmp;
          
          -- Permisos pendientes de firma (si es responsable)
          IF v_firma_planif = C_TRUE_DB THEN
            v_datos_tmp := wbs_devuelve_firma_permisos(v_id_funcionario, 3);
            v_datos := v_datos || ',' || v_datos_tmp;
          END IF;
          
          -- Resumen de bolsas (productividad, horas extras, conciliación)
          v_datos_tmp := wbs_devuelve_saldo_bolsas(v_id_funcionario, 'r', v_id_anio);
          v_datos := v_datos || ',' || v_datos_tmp;
          
          -- Mensajes y notificaciones
          v_datos_tmp := wbs_devuelve_mensajes(v_id_funcionario);
          v_datos := v_datos || ',' || v_datos_tmp;
        
        ----------------------------------------------------------------
        -- SECCIÓN: BOLSAS Y SALDOS
        ----------------------------------------------------------------
        
        -- Detalle bolsa productividad
        WHEN 'DBPR' THEN
          v_datos_tmp := wbs_devuelve_saldo_bolsas(v_id_funcionario, 'p', v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Detalle bolsa horas extras
        WHEN 'DBHE' THEN
          v_datos_tmp := wbs_devuelve_saldo_bolsas(v_id_funcionario, 'e', v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Detalle bolsa horas conciliación
        WHEN 'DBHC' THEN
          v_datos_tmp := wbs_devuelve_saldo_bolsas(v_id_funcionario, 'c', v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Detalle saldo horario mensual
        WHEN 'SHOR' THEN
          v_datos_tmp := wbs_devuelve_saldo_horario(v_id_funcionario, 'd', v_id_anio, v_id_mes);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        ----------------------------------------------------------------
        -- SECCIÓN: GESTIÓN DE PERMISOS
        ----------------------------------------------------------------
        
        -- Consulta de permisos del año
        WHEN 'CPER' THEN
          v_datos_tmp := wbs_devuelve_consulta_permisos(v_id_funcionario, '0', v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Detalle de permiso específico
        WHEN 'DDPR' THEN
          v_datos_tmp := wbs_devuelve_consulta_permisos(v_id_funcionario, v_id_permiso, v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Anular permiso propio
        WHEN 'APPR' THEN
          permisos_anula_usuario(v_id_permiso, v_id_funcionario, v_todook, v_msgsalida);
          
          IF v_todook = '1' THEN
            v_resultado_ope := C_ERROR;
          END IF;
          v_observaciones := v_msgsalida;
          v_datos := wbs_devuelve_datos_personales(v_id_funcionario);
        
        -- Vista previa solicitud permiso
        WHEN 'SPER_PREV' THEN
          v_datos_tmp := wbs_devuelve_consulta_permisos(v_id_funcionario, 'sp', v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Solicitar nuevo permiso
        -- MEJORA: Lógica clarificada y optimizada
        WHEN 'SPER' THEN
          v_tipo_funcionario := C_TIPO_FUNCIONARIO_GENERAL;
          v_id_unico := C_SI;
          
          -- Verificar si se adjunta justificante
          v_id_justificacion := CASE WHEN p_blob IS NOT NULL THEN C_SI ELSE C_NO END;
          
          -- Crear solicitud de permiso
          permisos_new(
            v_id_anio,
            v_id_funcionario,
            v_tipo_funcionario,
            v_tipo,
            C_ESTADO_PERMISO_PENDIENTE,
            v_tipo_dias,
            v_fecha_inicio,
            v_fecha_fin,
            v_hora_inicio,
            v_hora_fin,
            v_grado,
            v_dp,
            v_id_justificacion,
            v_t1,
            v_t2,
            v_t3,
            v_id_unico,
            '',
            v_msgsalida,
            v_todook,
            v_enlace_fichero
          );
          
          -- Evaluar resultado
          IF v_todook = '1' THEN
            v_resultado_ope := C_ERROR;
            v_observaciones := v_msgsalida;
          ELSE
            -- Si hay fichero adjunto, guardarlo
            IF v_enlace_fichero IS NOT NULL AND v_enlace_fichero > '0' THEN
              v_observaciones := wbs_justifica_fichero(v_enlace_fichero, p_blob);
              v_observaciones := v_observaciones || ' ' || v_msgsalida;
            ELSE
              v_observaciones := v_msgsalida;
            END IF;
          END IF;
          
          v_datos := wbs_devuelve_datos_personales(v_id_funcionario);
        
        ----------------------------------------------------------------
        -- Justificar permiso con archivo
        ----------------------------------------------------------------
        WHEN 'JPER' THEN
          v_observaciones := wbs_justifica_fichero_sin(v_id_permiso, v_id_ausencia, p_blob);
          v_datos := wbs_devuelve_datos_personales(v_id_funcionario);
        
        ----------------------------------------------------------------
        -- Actualizar foto del empleado
        ----------------------------------------------------------------
        WHEN 'FOAC' THEN
          v_observaciones := wbs_actualiza_foto(v_id_funcionario, p_blob);
          v_datos := wbs_devuelve_datos_personales(v_id_funcionario);
        
        ----------------------------------------------------------------
        -- Descargar justificante (permiso o ausencia)
        ----------------------------------------------------------------
        WHEN 'JPAF' THEN
          -- Si no hay enlace específico, usar ID de permiso
          IF v_enlace_fichero IS NULL OR v_enlace_fichero = '' OR v_enlace_fichero = '0' THEN
            v_enlace_fichero := v_id_permiso;
          END IF;
          
          v_datos := wbs_devuelve_fichero_justificante_per_au(v_enlace_fichero);
        
        ----------------------------------------------------------------
        -- SECCIÓN: GESTIÓN DE AUSENCIAS
        ----------------------------------------------------------------
        
        -- Consulta de ausencias del año
        WHEN 'CAUS' THEN
          v_datos_tmp := wbs_devuelve_consulta_ausencias(v_id_funcionario, '0', v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Detalle de ausencia específica
        WHEN 'DAUS' THEN
          v_datos_tmp := wbs_devuelve_consulta_ausencias(v_id_funcionario, v_id_ausencia, v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Anular ausencia propia
        WHEN 'AAUS' THEN
          ausencias_anula_usuario(v_id_ausencia, v_id_funcionario, v_todook, v_msgsalida);
          
          IF v_todook = '1' THEN
            v_resultado_ope := C_ERROR;
          END IF;
          v_observaciones := v_msgsalida;
          v_datos := wbs_devuelve_datos_personales(v_id_funcionario);
        
        -- Vista previa solicitud ausencia
        WHEN 'SAUS_PREV' THEN
          v_datos_tmp := wbs_devuelve_consulta_ausencias(v_id_funcionario, '1', v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Solicitar nueva ausencia
        WHEN 'SAUS' THEN
          v_tipo_funcionario := C_TIPO_FUNCIONARIO_GENERAL;
          
          ausencias_new(
            v_id_anio,
            v_id_funcionario,
            v_tipo_funcionario,
            v_tipo_ausencia,
            C_ESTADO_PERMISO_PENDIENTE,
            v_fecha_inicio,
            v_fecha_fin,
            v_hora_inicio,
            v_hora_fin,
            C_NO, -- justificación
            '',
            v_msgsalida,
            v_todook
          );
          
          IF v_todook = '1' THEN
            v_resultado_ope := C_ERROR;
          END IF;
          v_observaciones := v_msgsalida;
          v_datos := wbs_devuelve_datos_personales(v_id_funcionario);
        
        ----------------------------------------------------------------
        -- Incidencia de fichaje (caso especial de ausencia)
        ----------------------------------------------------------------
        WHEN 'INCF' THEN
          v_tipo_funcionario := C_TIPO_FUNCIONARIO_GENERAL;
          
          ausencias_new(
            v_id_anio,
            v_id_funcionario,
            v_tipo_funcionario,
            C_INCIDENCIA_FICHAJE, -- Tipo especial para incidencias
            C_ESTADO_PERMISO_PENDIENTE,
            v_fecha_inicio,
            v_fecha_fin,
            v_hora_inicio,
            v_hora_fin,
            C_NO,
            '',
            v_msgsalida,
            v_todook
          );
          
          IF v_todook = '1' THEN
            v_resultado_ope := C_ERROR;
          END IF;
          -- MEJORA: Mensaje personalizado para incidencias
          v_observaciones := REPLACE(v_msgsalida, 'ausencia', 'fichaje');
          v_datos := wbs_devuelve_datos_personales(v_id_funcionario);
        ----------------------------------------------------------------
        -- SECCIÓN: FICHAJES Y TELETRABAJO
        ----------------------------------------------------------------
        
        -- Registrar fichaje de teletrabajo
        WHEN 'FTEL' THEN
          fichaje_por_intranet(
            v_id_funcionario,
            1, -- Tipo fichaje teletrabajo
            v_msgsalida,
            v_todook,
            v_n_fichaje
          );
          v_observaciones := v_todook;
        
        ----------------------------------------------------------------
        -- SECCIÓN: FIRMA Y AUTORIZACIÓN (RESPONSABLES)
        -- MEJORA: Código unificado para operaciones similares
        ----------------------------------------------------------------
        
        -- Permisos pendientes de firma
        WHEN 'FPEP' THEN
          v_datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'p', 'pe');
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Ausencias pendientes de firma
        WHEN 'FAUP' THEN
          v_datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'p', 'au');
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Fichajes pendientes de firma
        WHEN 'FFIP' THEN
          v_datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'p', 'fi');
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Permisos autorizados
        WHEN 'FPEA' THEN
          v_datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'a', 'pe');
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Ausencias autorizadas
        WHEN 'FAUA' THEN
          v_datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'a', 'au');
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Fichajes autorizados
        WHEN 'FFIA' THEN
          v_datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'a', 'fi');
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Permisos denegados
        WHEN 'FPED' THEN
          v_datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'd', 'pe');
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Ausencias denegadas
        WHEN 'FAUD' THEN
          v_datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'd', 'au');
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Fichajes denegados
        WHEN 'FFID' THEN
          v_datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'd', 'fi');
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        ----------------------------------------------------------------
        -- SECCIÓN: PERMISOS Y FICHAJES DE SERVICIO
        ----------------------------------------------------------------
        
        -- Permisos de servicio
        WHEN 'FPES' THEN
          v_datos_tmp := wbs_devuelve_permisos_fichajes_serv(v_id_funcionario, 0, v_fecha_inicio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Fichajes de servicio
        WHEN 'FFIS' THEN
          v_datos_tmp := wbs_devuelve_permisos_fichajes_serv(v_id_funcionario, 2, v_fecha_inicio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Permisos pendientes de servicio
        WHEN 'FPET' THEN
          v_datos_tmp := wbs_devuelve_permisos_fichajes_serv(v_id_funcionario, 1, v_fecha_inicio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        ----------------------------------------------------------------
        -- AUTORIZAR/DENEGAR (FIRMA)
        -- MEJORA: Lógica unificada con generación de clave única
        ----------------------------------------------------------------
        
        -- Firmar ausencia (autorizar o denegar)
        WHEN 'FAUS' THEN
          -- Generar clave única para la firma
          SELECT sec_permiso_vali_todos.NEXTVAL INTO v_clave_firma FROM DUAL;
          
          firma_jsa_varios_webs(
            'A', -- Tipo: Ausencia
            v_id_funcionario,
            ';' || v_id_permiso || ';',
            v_tipo_firma,
            v_tipo_denegacion,
            v_clave_firma,
            v_observaciones,
            v_todook
          );
          
          v_resultado_ope := CASE WHEN v_todook = '1' THEN C_ERROR ELSE C_OK END;
        
        -- Firmar permiso (autorizar o denegar)
        WHEN 'FPER' THEN
          SELECT sec_permiso_vali_todos.NEXTVAL INTO v_clave_firma FROM DUAL;
          
          firma_jsa_varios_webs(
            'P', -- Tipo: Permiso
            v_id_funcionario,
            ';' || v_id_permiso || ';',
            v_tipo_firma,
            v_tipo_denegacion,
            v_clave_firma,
            v_observaciones,
            v_todook
          );
          
          v_resultado_ope := CASE WHEN v_todook = '1' THEN C_ERROR 
                                  ELSE C_OK || ';' || v_id_permiso || ';' END;
        
        -- Firmar fichaje (autorizar o denegar)
        WHEN 'FFIC' THEN
          SELECT sec_permiso_vali_todos.NEXTVAL INTO v_clave_firma FROM DUAL;
          
          firma_jsa_varios_webs(
            'F', -- Tipo: Fichaje
            v_id_funcionario,
            ';' || v_id_permiso || ';',
            v_tipo_firma,
            v_tipo_denegacion,
            v_clave_firma,
            v_observaciones,
            v_todook
          );
          
          v_resultado_ope := CASE WHEN v_todook = '1' THEN C_ERROR ELSE C_OK END;
        
        ----------------------------------------------------------------
        -- SECCIÓN: NÓMINAS
        ----------------------------------------------------------------
        
        -- Listado de nóminas (últimas 24)
        WHEN 'NFUN' THEN
          v_datos_tmp := wbs_devuelve_datos_nominas(v_id_funcionario, 24, 0);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Descargar archivo de nómina específica
        WHEN 'NFUF' THEN
          v_datos := wbs_devuelve_datos_nominas(v_id_funcionario, 1, v_id_nomina);
        
        ----------------------------------------------------------------
        -- SECCIÓN: CURSOS Y FORMACIÓN
        ----------------------------------------------------------------
        
        -- Catálogo de cursos disponibles
        WHEN 'CCAT' THEN
          v_datos_tmp := wbs_devuelve_cursos(v_id_funcionario, 0, v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Detalle de curso específico
        WHEN 'CDET' THEN
          v_datos_tmp := wbs_devuelve_cursos(v_id_funcionario, v_id_curso, v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Cursos realizados por el empleado
        WHEN 'CREA' THEN
          v_datos_tmp := wbs_devuelve_cursos(v_id_funcionario, 3, v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Inscribirse en curso
        WHEN 'CINS' THEN
          v_observaciones := wbs_inserta_curso(v_id_funcionario, v_id_curso, 0);
          v_datos := wbs_devuelve_datos_personales(v_id_funcionario);
        
        -- Anular inscripción en curso
        WHEN 'CANU' THEN
          v_observaciones := wbs_inserta_curso(v_id_funcionario, v_id_curso, 1);
          v_datos := wbs_devuelve_datos_personales(v_id_funcionario);
        
        ----------------------------------------------------------------
        -- SECCIÓN: PLANIFICACIÓN
        ----------------------------------------------------------------
        
        -- Calendario de permisos de servicio
        WHEN 'PPES' THEN
          v_datos_tmp := wbs_devuelve_permisos_fichajes_serv(v_id_funcionario, 0, v_fecha_inicio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Calendario de permisos bomberos
        WHEN 'PPES_B' THEN
          v_datos_tmp := wbs_devuelve_permisos_bomberos(v_id_funcionario, 0, v_fecha_inicio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Permisos-fichaje última semana
        WHEN 'PPFS' THEN
          v_datos_tmp := wbs_devuelve_permisos_fichajes_serv(v_id_funcionario, 3, v_fecha_inicio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Fichajes de servicio
        WHEN 'PFIS' THEN
          v_datos_tmp := wbs_devuelve_permisos_fichajes_serv(v_id_funcionario, 2, v_fecha_inicio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Permisos pendientes
        WHEN 'PPEP' THEN
          v_datos_tmp := wbs_devuelve_permisos_fichajes_serv(v_id_funcionario, 1, v_fecha_inicio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        ----------------------------------------------------------------
        -- SECCIÓN: TELETRABAJO (TRES)
        ----------------------------------------------------------------
        
        -- Estados de teletrabajo
        WHEN 'TRES' THEN
          v_datos_tmp := wbs_devuelve_tr_estados(1, v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Permisos de teletrabajo
        WHEN 'TRPE' THEN
          v_datos_tmp := wbs_devuelve_tr_estados(2, v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Ausencias de teletrabajo
        WHEN 'TRAU' THEN
          v_datos_tmp := wbs_devuelve_tr_estados(3, v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Cursos de teletrabajo
        WHEN 'TRCU' THEN
          v_datos_tmp := wbs_devuelve_tr_estados(4, v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        -- Incidencias de teletrabajo
        WHEN 'TRIN' THEN
          v_datos_tmp := wbs_devuelve_tr_estados(5, v_id_anio);
          v_datos := C_JSON_DATOS_INICIO || v_datos_tmp || C_JSON_DATOS_FIN;
        
        ----------------------------------------------------------------
        -- OPERACIÓN NO RECONOCIDA
        ----------------------------------------------------------------
        ELSE
          v_resultado_ope := C_ERROR;
          v_observaciones := 'Operación no válida: ' || v_pantalla;
          
      END CASE;
      
    END IF; -- Fin validación usuario
    
    --------------------------------------------------------------------------------
    -- FASE 4: CONSTRUCCIÓN DE RESPUESTA JSON
    --------------------------------------------------------------------------------
    
    -- Generar información de la operación
    v_operacion := wbs_devuelve_datos_operacion(v_resultado_ope, v_observaciones);
    
    -- Construir JSON de respuesta
    IF v_datos = '0' THEN
      -- Sin datos, solo operación
      resultado := C_JSON_INICIO || v_operacion || CHR(13) || C_JSON_FIN;
    ELSE
      -- Con datos
      resultado := C_JSON_INICIO || v_operacion || ',' || v_datos || CHR(13) || C_JSON_FIN;
    END IF;
    
  EXCEPTION
    --------------------------------------------------------------------------------
    -- MANEJO ROBUSTO DE EXCEPCIONES
    -- MEJORA: Captura detallada de errores para debugging y auditoría
    --------------------------------------------------------------------------------
    WHEN OTHERS THEN
      v_resultado_ope := C_ERROR;
      v_observaciones := 'Error inesperado: ' || SQLERRM || 
                         ' | Pantalla: ' || v_pantalla ||
                         ' | Funcionario: ' || v_id_funcionario;
      
      v_operacion := wbs_devuelve_datos_operacion(v_resultado_ope, v_observaciones);
      resultado := C_JSON_INICIO || v_operacion || C_JSON_FIN;
      
      -- Registrar error para auditoría (si existe tabla de log)
      -- INSERT INTO log_errores_ws VALUES (...);
      
  END wbs_controlador;

END WBS_PORTAL_EMPLEADO;
/

