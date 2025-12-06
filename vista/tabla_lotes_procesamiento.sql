-- =====================================================
-- Script de creación de tablas para procesamiento por lotes
-- Sistema de gestión de rutas duplicadas con iteraciones
-- Autor: Sistema Automático
-- Fecha: 06/12/2025
-- =====================================================

-- Tabla de control de lotes
CREATE TABLE RRHH.LOTES_CONTROL (
  id_lote                NUMBER PRIMARY KEY,
  tipo_proceso           VARCHAR2(50) NOT NULL,
  descripcion            VARCHAR2(500),
  estado                 VARCHAR2(50) NOT NULL,
  prioridad              NUMBER DEFAULT 5,
  fecha_creacion         TIMESTAMP DEFAULT SYSTIMESTAMP,
  fecha_inicio_proceso   TIMESTAMP,
  fecha_fin_proceso      TIMESTAMP,
  id_usuario_creacion    VARCHAR2(50),
  id_usuario_proceso     VARCHAR2(50),
  registros_total        NUMBER DEFAULT 0,
  registros_procesados   NUMBER DEFAULT 0,
  registros_error        NUMBER DEFAULT 0,
  registros_ok           NUMBER DEFAULT 0,
  iteracion_actual       NUMBER DEFAULT 0,
  total_iteraciones      NUMBER DEFAULT 0,
  tiempo_proceso         NUMBER,  -- en segundos
  mensaje_error          VARCHAR2(4000),
  id_lote_origen         NUMBER,  -- Para lotes duplicados
  ultima_actualizacion   TIMESTAMP,
  CONSTRAINT chk_lotes_estado CHECK (estado IN (
    'CREADO', 'EN_PROCESO', 'COMPLETADO', 'COMPLETADO_CON_ERRORES', 
    'ERROR', 'CANCELADO', 'MAX_ITERACIONES'
  )),
  CONSTRAINT chk_lotes_tipo CHECK (tipo_proceso IN (
    'PERMISOS', 'AUSENCIAS', 'FICHAJES', 'NOMINAS', 'CURSOS'
  ))
);

COMMENT ON TABLE RRHH.LOTES_CONTROL IS 'Tabla de control para procesamiento por lotes con iteraciones';
COMMENT ON COLUMN RRHH.LOTES_CONTROL.id_lote IS 'Identificador único del lote';
COMMENT ON COLUMN RRHH.LOTES_CONTROL.tipo_proceso IS 'Tipo de proceso: PERMISOS, AUSENCIAS, FICHAJES, NOMINAS, CURSOS';
COMMENT ON COLUMN RRHH.LOTES_CONTROL.estado IS 'Estado actual del lote';
COMMENT ON COLUMN RRHH.LOTES_CONTROL.prioridad IS 'Prioridad del lote (1=Alta, 5=Normal, 10=Baja)';
COMMENT ON COLUMN RRHH.LOTES_CONTROL.iteracion_actual IS 'Número de iteración actual en ejecución';
COMMENT ON COLUMN RRHH.LOTES_CONTROL.total_iteraciones IS 'Total de iteraciones completadas';
COMMENT ON COLUMN RRHH.LOTES_CONTROL.id_lote_origen IS 'ID del lote origen si es una duplicación';

-- Tabla de detalle de procesamiento
CREATE TABLE RRHH.LOTES_PROCESAMIENTO (
  id_registro            NUMBER PRIMARY KEY,
  id_lote                NUMBER NOT NULL,
  tipo_registro          VARCHAR2(50),
  estado                 VARCHAR2(50) NOT NULL,
  prioridad              NUMBER DEFAULT 5,
  datos_registro         CLOB,
  fecha_creacion         TIMESTAMP DEFAULT SYSTIMESTAMP,
  fecha_inicio_proceso   TIMESTAMP,
  fecha_fin_proceso      TIMESTAMP,
  iteracion_actual       NUMBER DEFAULT 0,
  resultado              VARCHAR2(50),
  mensaje_resultado      VARCHAR2(4000),
  reintentos             NUMBER DEFAULT 0,
  CONSTRAINT fk_lotes_procesamiento FOREIGN KEY (id_lote) 
    REFERENCES RRHH.LOTES_CONTROL(id_lote),
  CONSTRAINT chk_lotes_proc_estado CHECK (estado IN (
    'PENDIENTE', 'PROCESANDO', 'COMPLETADO', 'ERROR', 'REINTENTO', 'CANCELADO'
  ))
);

COMMENT ON TABLE RRHH.LOTES_PROCESAMIENTO IS 'Detalle de registros individuales en cada lote';
COMMENT ON COLUMN RRHH.LOTES_PROCESAMIENTO.id_registro IS 'Identificador único del registro';
COMMENT ON COLUMN RRHH.LOTES_PROCESAMIENTO.id_lote IS 'Referencia al lote de control';
COMMENT ON COLUMN RRHH.LOTES_PROCESAMIENTO.datos_registro IS 'Datos del registro en formato JSON o XML';
COMMENT ON COLUMN RRHH.LOTES_PROCESAMIENTO.iteracion_actual IS 'En qué iteración se procesó este registro';
COMMENT ON COLUMN RRHH.LOTES_PROCESAMIENTO.reintentos IS 'Número de veces que se ha reintentado procesar';

-- Tabla de log de iteraciones
CREATE TABLE RRHH.LOTES_LOG_ITERACIONES (
  id_log                 NUMBER PRIMARY KEY,
  id_lote                NUMBER NOT NULL,
  iteracion_numero       NUMBER NOT NULL,
  fecha_inicio           TIMESTAMP DEFAULT SYSTIMESTAMP,
  fecha_fin              TIMESTAMP,
  registros_procesados   NUMBER DEFAULT 0,
  registros_exitosos     NUMBER DEFAULT 0,
  registros_error        NUMBER DEFAULT 0,
  tiempo_ejecucion       NUMBER,  -- en segundos
  mensaje                VARCHAR2(4000),
  CONSTRAINT fk_lotes_log FOREIGN KEY (id_lote) 
    REFERENCES RRHH.LOTES_CONTROL(id_lote)
);

COMMENT ON TABLE RRHH.LOTES_LOG_ITERACIONES IS 'Log detallado de cada iteración de procesamiento';
COMMENT ON COLUMN RRHH.LOTES_LOG_ITERACIONES.iteracion_numero IS 'Número de la iteración';
COMMENT ON COLUMN RRHH.LOTES_LOG_ITERACIONES.tiempo_ejecucion IS 'Tiempo de ejecución de la iteración en segundos';

-- Índices para mejorar el rendimiento
CREATE INDEX idx_lotes_control_estado ON RRHH.LOTES_CONTROL(estado, fecha_creacion);
CREATE INDEX idx_lotes_control_tipo ON RRHH.LOTES_CONTROL(tipo_proceso, estado);
CREATE INDEX idx_lotes_proc_lote ON RRHH.LOTES_PROCESAMIENTO(id_lote, estado);
CREATE INDEX idx_lotes_proc_estado ON RRHH.LOTES_PROCESAMIENTO(estado, prioridad);
CREATE INDEX idx_lotes_log_lote ON RRHH.LOTES_LOG_ITERACIONES(id_lote, iteracion_numero);

-- Secuencias para IDs autoincrementales
CREATE SEQUENCE RRHH.SEQ_LOTES_CONTROL
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

CREATE SEQUENCE RRHH.SEQ_LOTES_PROCESAMIENTO
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

CREATE SEQUENCE RRHH.SEQ_LOTES_LOG
  START WITH 1
  INCREMENT BY 1
  NOCACHE
  NOCYCLE;

COMMENT ON SEQUENCE RRHH.SEQ_LOTES_CONTROL IS 'Secuencia para generar IDs de lotes de control';
COMMENT ON SEQUENCE RRHH.SEQ_LOTES_PROCESAMIENTO IS 'Secuencia para generar IDs de registros de procesamiento';
COMMENT ON SEQUENCE RRHH.SEQ_LOTES_LOG IS 'Secuencia para generar IDs de log de iteraciones';

-- Vista para consulta rápida de estado de lotes
CREATE OR REPLACE VIEW RRHH.V_LOTES_ESTADO AS
SELECT 
  lc.id_lote,
  lc.tipo_proceso,
  lc.descripcion,
  lc.estado as estado_lote,
  lc.prioridad,
  lc.fecha_creacion,
  lc.fecha_inicio_proceso,
  lc.fecha_fin_proceso,
  lc.id_usuario_creacion,
  lc.registros_total,
  lc.registros_procesados,
  lc.registros_error,
  lc.registros_ok,
  lc.iteracion_actual,
  lc.total_iteraciones,
  lc.tiempo_proceso,
  ROUND((lc.registros_procesados / NULLIF(lc.registros_total, 0)) * 100, 2) as porcentaje_completado,
  COUNT(DISTINCT lp.id_registro) as total_registros_detalle,
  SUM(CASE WHEN lp.estado = 'PENDIENTE' THEN 1 ELSE 0 END) as pendientes,
  SUM(CASE WHEN lp.estado = 'PROCESANDO' THEN 1 ELSE 0 END) as procesando,
  SUM(CASE WHEN lp.estado = 'COMPLETADO' THEN 1 ELSE 0 END) as completados,
  SUM(CASE WHEN lp.estado = 'ERROR' THEN 1 ELSE 0 END) as errores,
  SUM(CASE WHEN lp.estado = 'REINTENTO' THEN 1 ELSE 0 END) as reintentos,
  SUM(CASE WHEN lp.estado = 'CANCELADO' THEN 1 ELSE 0 END) as cancelados
FROM RRHH.LOTES_CONTROL lc
LEFT JOIN RRHH.LOTES_PROCESAMIENTO lp ON lc.id_lote = lp.id_lote
GROUP BY 
  lc.id_lote, lc.tipo_proceso, lc.descripcion, lc.estado, lc.prioridad,
  lc.fecha_creacion, lc.fecha_inicio_proceso, lc.fecha_fin_proceso,
  lc.id_usuario_creacion, lc.registros_total, lc.registros_procesados,
  lc.registros_error, lc.registros_ok, lc.iteracion_actual, 
  lc.total_iteraciones, lc.tiempo_proceso;

COMMENT ON VIEW RRHH.V_LOTES_ESTADO IS 'Vista consolidada del estado de todos los lotes';

-- Grants necesarios (ajustar según usuarios/roles de la aplicación)
-- GRANT SELECT, INSERT, UPDATE, DELETE ON RRHH.LOTES_CONTROL TO <usuario_app>;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON RRHH.LOTES_PROCESAMIENTO TO <usuario_app>;
-- GRANT SELECT, INSERT ON RRHH.LOTES_LOG_ITERACIONES TO <usuario_app>;
-- GRANT SELECT ON RRHH.V_LOTES_ESTADO TO <usuario_app>;
-- GRANT SELECT ON RRHH.SEQ_LOTES_CONTROL TO <usuario_app>;
-- GRANT SELECT ON RRHH.SEQ_LOTES_PROCESAMIENTO TO <usuario_app>;
-- GRANT SELECT ON RRHH.SEQ_LOTES_LOG TO <usuario_app>;

COMMIT;

-- Script de validación
SELECT 'Tabla LOTES_CONTROL creada' as resultado FROM DUAL WHERE EXISTS (
  SELECT 1 FROM USER_TABLES WHERE TABLE_NAME = 'LOTES_CONTROL'
);

SELECT 'Tabla LOTES_PROCESAMIENTO creada' as resultado FROM DUAL WHERE EXISTS (
  SELECT 1 FROM USER_TABLES WHERE TABLE_NAME = 'LOTES_PROCESAMIENTO'
);

SELECT 'Tabla LOTES_LOG_ITERACIONES creada' as resultado FROM DUAL WHERE EXISTS (
  SELECT 1 FROM USER_TABLES WHERE TABLE_NAME = 'LOTES_LOG_ITERACIONES'
);

SELECT 'Vista V_LOTES_ESTADO creada' as resultado FROM DUAL WHERE EXISTS (
  SELECT 1 FROM USER_VIEWS WHERE VIEW_NAME = 'V_LOTES_ESTADO'
);
