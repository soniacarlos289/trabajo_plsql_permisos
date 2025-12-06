/*
================================================================================
  VISTA: rrhh.area
================================================================================
  PROPÓSITO:
    Proporciona una vista de las áreas de la organización basándose en la tabla
    de unidades. Filtra únicamente las unidades cuyo identificador tiene 
    exactamente 5 caracteres, lo cual representa el nivel de área dentro de
    la jerarquía organizacional.

  CAMPOS RETORNADOS:
    - id_area: Identificador único del área (id_unidad de 5 caracteres)
    - desc_area: Descripción textual del área

  DEPENDENCIAS:
    - Tabla: unidad (id_unidad, desc_unidad)

  NOTAS DE OPTIMIZACIÓN:
    - La consulta es simple y eficiente
    - Se recomienda crear un índice funcional sobre LENGTH(id_unidad) si hay
      muchos registros en la tabla unidad:
      CREATE INDEX idx_unidad_length ON unidad (LENGTH(id_unidad));

  AUTOR: Sistema RRHH
  ÚLTIMA MODIFICACIÓN: 05/12/2025 - Añadidos comentarios descriptivos
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.area AS
SELECT 
    id_unidad   AS id_area,    -- Identificador del área (filtrado por longitud 5)
    desc_unidad AS desc_area   -- Descripción del área
FROM 
    unidad 
WHERE 
    LENGTH(id_unidad) = 5;     -- Filtra solo unidades de nivel área (5 caracteres)

