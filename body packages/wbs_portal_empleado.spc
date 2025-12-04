--------------------------------------------------------------------------------
-- PACKAGE: WBS_PORTAL_EMPLEADO (ESPECIFICACIÓN)
--------------------------------------------------------------------------------
-- Propósito: Controlador de servicios web para el portal de empleados
-- Autor: CARLOS
-- Fecha Creación: 31/07/2024
-- Última Modificación: 04/12/2025
--
-- Descripción:
--   Este package proporciona servicios web REST para el portal de empleados,
--   permitiendo la gestión de permisos, ausencias, fichajes, nóminas, cursos,
--   firmados y consultas de saldo horario.
--
-- Dependencias:
--   - Funciones: DEVUELVE_VALOR_CAMPO, wbs_devuelve_* (múltiples funciones)
--   - Procedimientos: permisos_new, ausencias_new, firma_jsa_varios_webs
--   - Tablas: apliweb_usuario, personal, permisos, ausencias, fichajes
--
-- Historial de Cambios:
--   04/12/2025 - CARLOS - Optimización y documentación completa
--   31/07/2024 - CARLOS - Creación inicial
--------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE RRHH.WBS_PORTAL_EMPLEADO AS

  --------------------------------------------------------------------------------
  -- CONSTANTES GLOBALES
  --------------------------------------------------------------------------------
  -- Versión del package para control de cambios
  C_VERSION CONSTANT VARCHAR2(10) := '2.0.0';
  
  -- Códigos de resultado estándar
  C_RESULTADO_OK CONSTANT VARCHAR2(10) := 'OK';
  C_RESULTADO_ERROR CONSTANT VARCHAR2(10) := 'ERROR';
  
  --------------------------------------------------------------------------------
  -- PROCEDIMIENTOS PÚBLICOS
  --------------------------------------------------------------------------------
  
  /**
   * Procedimiento principal del controlador de servicios web
   *
   * @param parametros_entrada - Cadena con parámetros en formato key=value separados por ;
   *                             Parámetros comunes:
   *                             - Pant: Código de pantalla/operación (PPAL, ROLE, SPER, CPER, etc.)
   *                             - ID_FUNCIONARIO: Identificador único del empleado
   *                             - anio: Año de consulta (formato YYYY)
   *                             - mes: Mes de consulta (formato MM)
   *                             - idPeriodo: Periodo alternativo (formato MMYYYY o MYYYY)
   *
   * @param resultado          - CLOB de salida con respuesta en formato JSON
   *                             Estructura: [{"resultado":"OK|ERROR","observaciones":"mensaje",...}]
   *
   * @param p_blob             - BLOB opcional para archivos (justificantes, fotos, nóminas)
   *                             Utilizado en operaciones: SPER, JPER, FOAC, NFUF
   *
   * Operaciones soportadas (parámetro Pant):
   * 
   * GESTIÓN DE DATOS PERSONALES Y ROLES:
   *   - ROLE: Devuelve roles del funcionario
   *   - DPER: Devuelve datos personales
   *   - PPAL: Pantalla principal (datos personales + nóminas + saldo + permisos)
   *
   * CONSULTAS DE SALDO Y BOLSAS:
   *   - SHOR: Saldo horario detallado por periodo
   *   - DBPR: Detalle bolsa de productividad
   *   - DBHE: Detalle bolsa de horas extras
   *   - DBHC: Detalle bolsa de horas de conciliación
   *
   * GESTIÓN DE PERMISOS:
   *   - CPER: Consulta de permisos del año
   *   - DDPR: Detalle de un permiso específico
   *   - SPER_PREV: Vista previa de solicitud de permiso
   *   - SPER: Solicitar nuevo permiso (con justificante opcional)
   *   - APPR: Anular permiso propio
   *   - JPER: Justificar permiso con archivo
   *
   * GESTIÓN DE AUSENCIAS:
   *   - CAUS: Consulta de ausencias del año
   *   - DAUS: Detalle de una ausencia específica
   *   - SAUS_PREV: Vista previa de solicitud de ausencia
   *   - SAUS: Solicitar nueva ausencia
   *   - AAUS: Anular ausencia propia
   *   - INCF: Incidencia de fichaje
   *
   * FICHAJES Y TELETRABAJO:
   *   - FTEL: Registrar fichaje de teletrabajo
   *
   * FIRMA Y AUTORIZACIÓN (para responsables):
   *   - FPEP: Permisos pendientes de firma
   *   - FAUP: Ausencias pendientes de firma
   *   - FFIP: Fichajes pendientes de firma
   *   - FPEA: Permisos autorizados
   *   - FAUA: Ausencias autorizadas
   *   - FFIA: Fichajes autorizados
   *   - FPED: Permisos denegados
   *   - FAUD: Ausencias denegadas
   *   - FFID: Fichajes denegados
   *   - FPER: Firmar permiso (autorizar/denegar)
   *   - FAUS: Firmar ausencia (autorizar/denegar)
   *   - FFIC: Firmar fichaje (autorizar/denegar)
   *
   * PLANIFICACIÓN Y SERVICIOS:
   *   - FPES: Permisos de servicio para firma
   *   - FFIS: Fichajes de servicio
   *   - FPET: Permisos pendientes de servicio
   *   - PPES: Calendario de permisos de servicio
   *   - PPES_B: Calendario de permisos bomberos
   *   - PPFS: Permisos-fichaje última semana
   *   - PFIS: Fichajes de servicio
   *   - PPEP: Permisos pendientes
   *
   * NÓMINAS:
   *   - NFUN: Listado de nóminas (últimas 24)
   *   - NFUF: Descargar archivo de nómina específica
   *
   * CURSOS Y FORMACIÓN:
   *   - CCAT: Catálogo de cursos disponibles
   *   - CDET: Detalle de un curso específico
   *   - CREA: Cursos realizados por el empleado
   *   - CINS: Inscribirse en un curso
   *   - CANU: Anular inscripción en curso
   *
   * TELETRABAJO (TRES):
   *   - TRES: Estados de teletrabajo
   *   - TRPE: Permisos de teletrabajo
   *   - TRAU: Ausencias de teletrabajo
   *   - TRCU: Cursos de teletrabajo
   *   - TRIN: Incidencias de teletrabajo
   *
   * GESTIÓN DE ARCHIVOS:
   *   - FOAC: Actualizar foto del empleado
   *   - JPAF: Descargar justificante (permiso/ausencia)
   *
   * @throws NO_DATA_FOUND - Cuando el funcionario no existe
   * @throws OTHERS - Errores generales procesados y devueltos en JSON
   *
   * @example
   *   DECLARE
   *     v_resultado CLOB;
   *   BEGIN
   *     WBS_PORTAL_EMPLEADO.wbs_controlador(
   *       parametros_entrada => 'Pant=PPAL;ID_FUNCIONARIO=12345;anio=2025;mes=12',
   *       resultado => v_resultado,
   *       p_blob => NULL
   *     );
   *     DBMS_OUTPUT.PUT_LINE(v_resultado);
   *   END;
   */
  PROCEDURE wbs_controlador(
    parametros_entrada IN VARCHAR2,
    resultado OUT CLOB,
    p_blob IN BLOB
  );

END WBS_PORTAL_EMPLEADO;
/

