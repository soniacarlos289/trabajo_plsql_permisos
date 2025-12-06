/*
================================================================================
  VISTA: rrhh.permisos_en_dia
================================================================================
  PROPÓSITO:
    Combina los permisos y ausencias activos en una sola vista para identificar
    los días en que un funcionario tiene algún tipo de permiso o ausencia
    registrado y aprobado.

  CAMPOS RETORNADOS:
    - id_funcionario: Identificador del funcionario
    - fecha_inicio: Fecha de inicio del permiso/ausencia
    - fecha_fin: Fecha de fin del permiso/ausencia

  FUENTES DE DATOS:
    - rrhh.permiso: Permisos registrados (vacaciones, asuntos propios, etc.)
    - rrhh.ausencia: Ausencias registradas (bajas médicas, etc.)

  FILTROS APLICADOS:
    - id_estado = '80': Solo registros en estado aprobado/activo

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    Se mantiene UNION en lugar de UNION ALL por diseño
    =========================================================================
    En este caso, UNION es correcto porque:
    - Puede haber permisos y ausencias para el mismo funcionario en las mismas fechas
    - Se desea evitar duplicados en el resultado
    - Si se requirieran todos los registros duplicados, usar UNION ALL

    ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_permiso_estado ON permiso(id_estado, id_funcionario);
    - CREATE INDEX idx_ausencia_estado ON ausencia(id_estado, id_funcionario);

  DEPENDENCIAS:
    - Tabla: rrhh.permiso
    - Tabla: rrhh.ausencia

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Añadida documentación
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.permisos_en_dia AS
-- Permisos aprobados
SELECT 
    id_funcionario,
    fecha_inicio,
    fecha_fin 
FROM 
    rrhh.permiso
WHERE 
    id_estado = '80'                    -- Estado aprobado/activo
UNION
-- Ausencias aprobadas
SELECT 
    id_funcionario,
    fecha_inicio,
    fecha_fin 
FROM 
    rrhh.ausencia 
WHERE 
    id_estado = '80';                   -- Estado aprobado/activo

