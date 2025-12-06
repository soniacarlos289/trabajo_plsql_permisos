# Sistema de Procesamiento por Lotes con Iteraciones

## 📋 Descripción General

Sistema completo para gestión de procesamiento por lotes (batch processing) con soporte para duplicación de rutas, marcado de iteraciones y mejor usabilidad. Este sistema permite procesar grandes volúmenes de datos de forma controlada, iterativa y con capacidad de reintento.

## 🎯 Características Principales

### 1. Procesamiento por Lotes
- ✅ Procesamiento controlado en lotes de tamaño configurable
- ✅ Soporte para múltiples tipos de proceso (Permisos, Ausencias, Fichajes, Nóminas, Cursos)
- ✅ Control de iteraciones con límite máximo configurable
- ✅ Procesamiento transaccional con commit por lote

### 2. Duplicación de Rutas
- ✅ Capacidad de duplicar lotes completos
- ✅ Preservación de configuración del lote origen
- ✅ Reinicio automático de contadores y estados
- ✅ Trazabilidad del lote origen

### 3. Marcado de Iteraciones
- ✅ Registro de la iteración en la que se procesa cada registro
- ✅ Log detallado de cada iteración
- ✅ Métricas de tiempo y rendimiento por iteración
- ✅ Historial completo de procesamiento

### 4. Mejor Usabilidad
- ✅ API simple con operaciones CRUD
- ✅ Respuestas en formato JSON
- ✅ Estados claros y descriptivos
- ✅ Manejo robusto de errores
- ✅ Vista consolidada de estado

## 🏗️ Arquitectura del Sistema

### Componentes

```
┌─────────────────────────────────────────────────────┐
│           APLICACIÓN CLIENTE                         │
└───────────────────┬─────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────┐
│     GESTIONA_RUTA_LOTES (Función de Gestión)        │
│  • CREAR    • DUPLICAR   • CONSULTAR   • CANCELAR   │
└───────────────────┬─────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────┐
│   PROCESA_LOTES_ITERACIONES (Procedimiento Core)    │
│  • Control de Iteraciones                            │
│  • Procesamiento por Lotes                           │
│  • Manejo de Errores                                 │
│  • Actualización de Estados                          │
└───────────────────┬─────────────────────────────────┘
                    │
    ┌───────────────┼───────────────┐
    │               │               │
    ▼               ▼               ▼
┌─────────┐  ┌─────────────┐  ┌──────────┐
│ LOTES_  │  │  LOTES_     │  │ LOTES_   │
│ CONTROL │  │ PROCESAM.   │  │ LOG_ITER │
└─────────┘  └─────────────┘  └──────────┘
```

### Tablas

1. **LOTES_CONTROL**: Control principal de lotes
2. **LOTES_PROCESAMIENTO**: Detalle de registros a procesar
3. **LOTES_LOG_ITERACIONES**: Log de cada iteración

### Objetos PL/SQL

1. **PROCESA_LOTES_ITERACIONES**: Procedimiento principal de procesamiento
2. **GESTIONA_RUTA_LOTES**: Función para gestión de lotes
3. **V_LOTES_ESTADO**: Vista consolidada de estados

## 📖 Guía de Uso

### 1. Crear un Nuevo Lote

```sql
-- Crear lote de permisos
DECLARE
  v_resultado VARCHAR2(4000);
BEGIN
  v_resultado := GESTIONA_RUTA_LOTES(
    p_accion       => 'CREAR',
    p_tipo_proceso => 'PERMISOS',
    p_descripcion  => 'Procesamiento de permisos de diciembre 2025',
    p_id_usuario   => 'USUARIO_APP',
    p_prioridad    => 5
  );
  
  DBMS_OUTPUT.PUT_LINE(v_resultado);
  -- Salida: {"resultado": "OK", "id_lote": 1, "tipo_proceso": "PERMISOS", ...}
END;
/
```

### 2. Agregar Registros al Lote

```sql
-- Insertar registros en el lote
INSERT INTO LOTES_PROCESAMIENTO (
  id_registro, id_lote, tipo_registro, estado, prioridad, datos_registro
)
SELECT 
  SEQ_LOTES_PROCESAMIENTO.NEXTVAL,
  1, -- ID del lote
  'PERMISO_VACACIONES',
  'PENDIENTE',
  5,
  '{"id_funcionario": ' || id_funcionario || ', "fecha_inicio": "' || 
  TO_CHAR(fecha_inicio, 'DD/MM/YYYY') || '", "dias": ' || dias || '}'
FROM tabla_permisos_pendientes
WHERE estado = 'POR_PROCESAR';

COMMIT;
```

### 3. Procesar el Lote

```sql
-- Procesar lote con configuración personalizada
DECLARE
  v_resultado           VARCHAR2(50);
  v_mensaje             VARCHAR2(4000);
  v_registros_proc      NUMBER;
  v_registros_error     NUMBER;
BEGIN
  PROCESA_LOTES_ITERACIONES(
    p_tipo_proceso         => 'PERMISOS',
    p_id_lote              => 1,
    p_tamaño_lote          => 100,      -- 100 registros por iteración
    p_max_iteraciones      => 1000,     -- Máximo 1000 iteraciones
    p_modo_ejecucion       => 'NORMAL', -- NORMAL, DEBUG, VALIDACION
    p_id_usuario           => 'USUARIO_APP',
    p_resultado            => v_resultado,
    p_mensaje_salida       => v_mensaje,
    p_registros_procesados => v_registros_proc,
    p_registros_error      => v_registros_error
  );
  
  DBMS_OUTPUT.PUT_LINE('Resultado: ' || v_resultado);
  DBMS_OUTPUT.PUT_LINE('Mensaje: ' || v_mensaje);
  DBMS_OUTPUT.PUT_LINE('Procesados: ' || v_registros_proc);
  DBMS_OUTPUT.PUT_LINE('Errores: ' || v_registros_error);
END;
/
```

### 4. Duplicar un Lote

```sql
-- Duplicar lote existente (útil para reprocesar)
DECLARE
  v_resultado VARCHAR2(4000);
BEGIN
  v_resultado := GESTIONA_RUTA_LOTES(
    p_accion         => 'DUPLICAR',
    p_id_lote_origen => 1,
    p_id_usuario     => 'USUARIO_APP',
    p_prioridad      => 3  -- Mayor prioridad
  );
  
  DBMS_OUTPUT.PUT_LINE(v_resultado);
  -- Salida: {"resultado": "OK", "id_lote_nuevo": 2, "id_lote_origen": 1, ...}
END;
/
```

### 5. Consultar Estado de un Lote

```sql
-- Consultar estado completo
DECLARE
  v_resultado VARCHAR2(4000);
BEGIN
  v_resultado := GESTIONA_RUTA_LOTES(
    p_accion         => 'CONSULTAR',
    p_id_lote_origen => 1,
    p_id_usuario     => 'USUARIO_APP'
  );
  
  DBMS_OUTPUT.PUT_LINE(v_resultado);
END;
/

-- Consultar mediante vista
SELECT * FROM V_LOTES_ESTADO WHERE id_lote = 1;
```

### 6. Cancelar un Lote

```sql
-- Cancelar procesamiento de un lote
DECLARE
  v_resultado VARCHAR2(4000);
BEGIN
  v_resultado := GESTIONA_RUTA_LOTES(
    p_accion         => 'CANCELAR',
    p_id_lote_origen => 1,
    p_id_usuario     => 'USUARIO_APP'
  );
  
  DBMS_OUTPUT.PUT_LINE(v_resultado);
END;
/
```

## 📊 Monitoreo y Reporting

### Consultar Estado de Todos los Lotes

```sql
SELECT 
  id_lote,
  tipo_proceso,
  estado_lote,
  porcentaje_completado,
  registros_total,
  completados,
  errores,
  pendientes,
  total_iteraciones,
  tiempo_proceso
FROM V_LOTES_ESTADO
ORDER BY fecha_creacion DESC;
```

### Consultar Registros con Error

```sql
SELECT 
  lp.id_registro,
  lp.id_lote,
  lc.tipo_proceso,
  lp.estado,
  lp.mensaje_resultado,
  lp.reintentos,
  lp.iteracion_actual,
  lp.fecha_fin_proceso
FROM LOTES_PROCESAMIENTO lp
JOIN LOTES_CONTROL lc ON lp.id_lote = lc.id_lote
WHERE lp.estado = 'ERROR'
  AND lc.id_lote = 1
ORDER BY lp.fecha_fin_proceso DESC;
```

### Consultar Log de Iteraciones

```sql
SELECT 
  iteracion_numero,
  registros_procesados,
  registros_exitosos,
  registros_error,
  tiempo_ejecucion,
  mensaje
FROM LOTES_LOG_ITERACIONES
WHERE id_lote = 1
ORDER BY iteracion_numero;
```

## ⚙️ Configuración y Ajustes

### Parámetros de Procesamiento

| Parámetro | Descripción | Valor Por Defecto | Recomendación |
|-----------|-------------|-------------------|---------------|
| `p_tamaño_lote` | Registros por iteración | 100 | 50-200 según complejidad |
| `p_max_iteraciones` | Límite de iteraciones | 1000 | Ajustar según volumen |
| `p_modo_ejecucion` | Modo de ejecución | NORMAL | DEBUG para troubleshooting |
| `p_prioridad` | Prioridad del lote | 5 | 1=Alta, 5=Normal, 10=Baja |

### Modos de Ejecución

- **NORMAL**: Procesamiento estándar sin output adicional
- **DEBUG**: Incluye mensajes de depuración (DBMS_OUTPUT)
- **VALIDACION**: Modo de validación sin commits permanentes

## 🔧 Mantenimiento

### Limpiar Lotes Antiguos

```sql
-- Eliminar lotes completados de hace más de 30 días
DELETE FROM LOTES_PROCESAMIENTO 
WHERE id_lote IN (
  SELECT id_lote 
  FROM LOTES_CONTROL 
  WHERE estado IN ('COMPLETADO', 'CANCELADO')
    AND fecha_fin_proceso < SYSDATE - 30
);

DELETE FROM LOTES_LOG_ITERACIONES 
WHERE id_lote IN (
  SELECT id_lote 
  FROM LOTES_CONTROL 
  WHERE estado IN ('COMPLETADO', 'CANCELADO')
    AND fecha_fin_proceso < SYSDATE - 30
);

DELETE FROM LOTES_CONTROL 
WHERE estado IN ('COMPLETADO', 'CANCELADO')
  AND fecha_fin_proceso < SYSDATE - 30;

COMMIT;
```

### Reintentar Registros con Error

```sql
-- Marcar registros con error para reintento
UPDATE LOTES_PROCESAMIENTO
SET estado = 'REINTENTO',
    mensaje_resultado = NULL
WHERE id_lote = 1
  AND estado = 'ERROR'
  AND reintentos < 3;

COMMIT;

-- Reprocesar el lote
-- (ejecutar PROCESA_LOTES_ITERACIONES nuevamente)
```

## 🚀 Casos de Uso

### Caso 1: Procesamiento Masivo de Permisos

```sql
-- 1. Crear lote
v_resultado := GESTIONA_RUTA_LOTES('CREAR', NULL, 'PERMISOS', 
  'Permisos masivos diciembre', 'ADMIN', 5);

-- 2. Cargar registros (desde tabla temporal o importación)
INSERT INTO LOTES_PROCESAMIENTO (...)
SELECT ... FROM tabla_importacion;

-- 3. Procesar
PROCESA_LOTES_ITERACIONES(...);
```

### Caso 2: Reprocesar Lote con Errores

```sql
-- 1. Duplicar lote original
v_resultado := GESTIONA_RUTA_LOTES('DUPLICAR', 1, NULL, NULL, 'ADMIN', 3);

-- 2. Extraer id_lote_nuevo del JSON
-- 3. Ajustar registros si es necesario
-- 4. Procesar lote duplicado
PROCESA_LOTES_ITERACIONES(...);
```

### Caso 3: Procesamiento Programado

```sql
-- Crear job para procesamiento nocturno
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'JOB_PROCESA_LOTES_NOCHE',
    job_type        => 'PLSQL_BLOCK',
    job_action      => 'BEGIN 
      FOR lote IN (SELECT id_lote FROM LOTES_CONTROL WHERE estado = ''CREADO'') LOOP
        PROCESA_LOTES_ITERACIONES(''PERMISOS'', lote.id_lote, 100, 1000, 
          ''NORMAL'', ''SISTEMA'', :resultado, :mensaje, :proc, :error);
      END LOOP;
    END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=0',
    enabled         => TRUE
  );
END;
/
```

## ⚠️ Consideraciones

### Rendimiento
- Ajustar `p_tamaño_lote` según la complejidad de cada registro
- Lotes muy grandes pueden causar locks prolongados
- Usar prioridades para controlar orden de procesamiento

### Transaccionalidad
- Cada iteración hace commit independiente
- Fallos en un registro no afectan a otros del mismo lote
- Los errores se registran para análisis posterior

### Escalabilidad
- El sistema soporta múltiples lotes en paralelo
- Usar FOR UPDATE SKIP LOCKED para evitar contención
- Monitorear uso de tablespace de UNDO y TEMP

## 📚 Referencias

### Archivos Relacionados
- `procedures/procesa_lotes_iteraciones.prc` - Procedimiento principal
- `functiones/gestiona_ruta_lotes.fnc` - Función de gestión
- `vista/tabla_lotes_procesamiento.sql` - DDL de tablas

### Procedimientos Existentes Compatibles
- `permisos_new.prc`
- `ausencias_new.prc`
- `mete_fichaje_finger_new.prc`
- (Cualquier procedimiento que pueda llamarse por cada registro)

## 🎯 Roadmap Futuro

- [ ] Integración con sistema de notificaciones
- [ ] Dashboard web para monitoreo en tiempo real
- [ ] API REST para gestión remota
- [ ] Procesamiento paralelo multi-thread
- [ ] Reintentos automáticos con backoff exponencial
- [ ] Métricas de rendimiento avanzadas

## 📞 Soporte

Para preguntas o problemas:
- Consultar log de iteraciones para troubleshooting
- Verificar estado en vista V_LOTES_ESTADO
- Revisar mensajes de error en LOTES_PROCESAMIENTO

---

**Versión**: 1.0.0  
**Fecha**: 06/12/2025  
**Autor**: Sistema Automático
