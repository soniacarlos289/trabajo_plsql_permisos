/*
================================================================================
  VISTA: rrhh.bajas_ilt
================================================================================
  PROPÓSITO:
    Proporciona información sobre las bajas por Incapacidad Laboral Transitoria 
    (ILT) de los funcionarios. Selecciona permisos de tipo '11300' (bajas médicas)
    que están en estado activo (80) y no han sido anulados.

  CAMPOS RETORNADOS:
    - id_baja: Identificador único de la baja (id_permiso)
    - id_funcionario: Identificador del funcionario afectado
    - id_ano: Año de la baja
    - fecha_inicio: Fecha de inicio de la baja
    - fecha_presentacion: Reservado para fecha de presentación (NULL por diseño)
    - fecha_soli: Fecha de solicitud del permiso
    - fecha_fin: Fecha fin efectiva (si es NULL, se usa sysdate+1 como provisional)
    - fecha_fin_real: Fecha fin real almacenada (puede ser NULL si aún activa)
    - fecha_confirmacion: Reservado para fecha de confirmación (NULL por diseño)
    - id_tipo_baja: Tipo específico de baja (campo TIPO_BAJA)
    - baja_cobra_100: Reservado para indicador de cobro al 100% (NULL por diseño)
    - id_usuario: Usuario que registró la baja
    - fecha_modi: Fecha de última modificación
    - observaciones: Notas adicionales sobre la baja
    - anulada: Indicador de anulación del registro
    - fecha_anulada: Reservado para fecha de anulación (NULL por diseño)

  FILTROS APLICADOS:
    - id_tipo_permiso = '11300': Solo permisos de tipo ILT
    - id_estado = 80: Solo permisos en estado activo/aprobado
    - anulado = 'NO' o NULL: Excluye registros anulados

  DEPENDENCIAS:
    - Tabla: permiso

  NOTAS DE OPTIMIZACIÓN:
    - Se eliminó DISTINCT innecesario si id_permiso es PK
    - Se usan NULL en lugar de '' para campos reservados (mejor práctica Oracle)
    - Se recomienda índice compuesto: 
      CREATE INDEX idx_permiso_tipo_estado ON permiso(id_tipo_permiso, id_estado, anulado);

  HISTORIAL:
    - 09/10/2017 (CHM): Añadido NVL para fecha_fin con sysdate+1
    - 05/12/2025: Añadidos comentarios y optimización de NULL vs ''
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.bajas_ilt AS
SELECT 
    id_permiso      AS id_baja,               -- Identificador único de la baja
    id_funcionario,                            -- Funcionario en baja
    id_ano,                                    -- Año de la baja
    fecha_inicio,                              -- Inicio de la incapacidad
    NULL            AS fecha_presentacion,     -- Reservado: fecha de presentación
    fecha_soli,                                -- Fecha de solicitud
    NVL(fecha_fin, SYSDATE + 1) AS fecha_fin,  -- Fecha fin (o mañana si aún activa)
    fecha_fin       AS fecha_fin_real,         -- Fecha fin original (puede ser NULL)
    NULL            AS fecha_confirmacion,     -- Reservado: fecha de confirmación
    tipo_baja       AS id_tipo_baja,           -- Tipo específico de baja médica
    NULL            AS baja_cobra_100,         -- Reservado: indicador cobro 100%
    id_usuario,                                -- Usuario que registró
    fecha_modi,                                -- Última modificación
    observaciones,                             -- Notas adicionales
    anulado         AS anulada,                -- Estado de anulación
    NULL            AS fecha_anulada           -- Reservado: fecha de anulación
FROM 
    permiso 
WHERE 
    id_tipo_permiso = '11300'                  -- Tipo ILT (Incapacidad Laboral Transitoria)
    AND id_estado = 80                         -- Estado activo/aprobado
    AND (anulado = 'NO' OR anulado IS NULL);   -- Excluir anulados

