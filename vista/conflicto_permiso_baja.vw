/*
================================================================================
  VISTA: rrhh.conflicto_permiso_baja
================================================================================
  PROPÓSITO:
    Identifica conflictos entre permisos solicitados y períodos de baja ILT
    (Incapacidad Laboral Transitoria). Detecta cuando un funcionario tiene
    un permiso que se solapa con una baja médica activa.

  CAMPOS RETORNADOS:
    - id_funcionario: Identificador del funcionario
    - fecha_inicio_per: Fecha de inicio del permiso
    - fecha_fin_per: Fecha de fin del permiso
    - id_tipo_permiso: Tipo de permiso solicitado
    - fecha_inicio_baj: Fecha de inicio de la baja
    - fecha_fin_baj: Fecha de fin de la baja
    - id_tipo_baja: Tipo de baja médica

  JOINS UTILIZADOS:
    - permiso (pe): Permisos registrados
    - bajas_ilt (b): Vista de bajas por incapacidad laboral

  CONDICIONES DE CONFLICTO:
    El permiso está completamente contenido dentro del período de baja:
    - pe.fecha_inicio BETWEEN b.fecha_inicio AND b.fecha_fin
    - pe.fecha_fin BETWEEN b.fecha_inicio AND b.fecha_fin

  FILTROS APLICADOS:
    - Mismo año (pe.id_ano = b.id_ano)
    - Mismo funcionario (pe.id_funcionario = b.id_funcionario)
    - Año > 2014 (datos desde 2015)
    - No anulado (ANULADO IS NULL OR ANULADO = 'NO')

  NOTAS DE OPTIMIZACIÓN:
    - WITH READ ONLY previene modificaciones
    - Los filtros de fecha en el JOIN son eficientes con índices
    - RECOMENDACIÓN: Índice compuesto en permiso(id_funcionario, id_ano, fecha_inicio, fecha_fin)
    - RECOMENDACIÓN: La vista bajas_ilt debe tener índices adecuados

  CASOS DE USO:
    - Validación antes de aprobar permisos
    - Auditoría de permisos durante bajas médicas
    - Detección de inconsistencias administrativas

  DEPENDENCIAS:
    - Tabla: permiso
    - Vista: bajas_ilt

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación añadida
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.conflicto_permiso_baja AS
SELECT 
    pe.id_funcionario,
    pe.fecha_inicio AS fecha_inicio_per,       -- Fechas del permiso
    pe.fecha_fin AS fecha_fin_per,
    id_tipo_permiso,
    b.fecha_inicio AS fecha_inicio_baj,        -- Fechas de la baja
    b.fecha_fin AS fecha_fin_baj,
    id_tipo_baja
FROM 
    permiso pe
    INNER JOIN bajas_ilt b 
        ON pe.id_funcionario = b.id_funcionario
        AND pe.id_ano = b.id_ano
        -- El permiso está contenido dentro de la baja
        AND pe.fecha_inicio BETWEEN b.fecha_inicio AND b.fecha_fin
        AND pe.fecha_fin BETWEEN b.fecha_inicio AND b.fecha_fin
WHERE 
    pe.id_ano > 2014                           -- Datos desde 2015
    AND (anulado IS NULL OR anulado = 'NO')    -- Solo permisos activos
WITH READ ONLY;

