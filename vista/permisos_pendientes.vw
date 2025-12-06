/*
================================================================================
  VISTA: rrhh.permisos_pendientes
================================================================================
  PROPÓSITO:
    Proporciona un resumen de los permisos pendientes de cada funcionario por año,
    desglosados por categoría: vacaciones, asuntos propios, compensatorios y otros.

  CAMPOS RETORNADOS:
    - id_funcionario: Identificador del funcionario
    - id_ano: Año de los permisos
    - vacaciones: Total de días de vacaciones pendientes (tipo 010xx)
    - asuntos_propios: Total de días de asuntos propios (tipo 020xx)
    - compensatorios: Total de días compensatorios (tipo 030xx)
    - otros: Total de días de otros tipos de permisos
    - total: Suma total de todos los días pendientes

  FUENTE DE DATOS:
    - permiso_funcionario: Tabla de permisos asignados por funcionario

  FILTROS APLICADOS:
    - id_ano > 2024: Solo años desde 2025
    - num_dias > 0: Solo registros con días asignados
    - unico = 'SI': Solo permisos marcados como únicos

  CLASIFICACIÓN DE PERMISOS:
    Los permisos se clasifican por los primeros 3 caracteres del tipo:
    - '010': Vacaciones (010xx)
    - '020': Asuntos propios (020xx)
    - '030': Compensatorios (030xx)
    - Otros: Cualquier otro tipo de permiso

  NOTAS DE OPTIMIZACIÓN:
    - La vista usa CASE WHEN que es estándar SQL y eficiente
    - La agregación por GROUP BY es apropiada para este tipo de resumen
    - RECOMENDACIÓN: Índice en permiso_funcionario(id_ano, unico, num_dias)

  DEPENDENCIAS:
    - Tabla: permiso_funcionario

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Añadida documentación
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.permisos_pendientes AS
SELECT
    id_funcionario,
    id_ano,
    -- Suma de días por categoría usando CASE WHEN
    SUM(CASE WHEN SUBSTR(id_tipo_permiso, 1, 3) = '010' THEN num_dias ELSE 0 END) AS vacaciones,
    SUM(CASE WHEN SUBSTR(id_tipo_permiso, 1, 3) = '020' THEN num_dias ELSE 0 END) AS asuntos_propios,
    SUM(CASE WHEN SUBSTR(id_tipo_permiso, 1, 3) = '030' THEN num_dias ELSE 0 END) AS compensatorios,
    SUM(CASE WHEN SUBSTR(id_tipo_permiso, 1, 3) NOT IN ('010', '020', '030') THEN num_dias ELSE 0 END) AS otros,
    SUM(num_dias) AS total
FROM 
    permiso_funcionario p 
WHERE 
    id_ano > 2024                -- Años desde 2025
    AND p.num_dias > 0           -- Solo registros con días
    AND p.unico = 'SI'           -- Solo permisos únicos
GROUP BY 
    id_funcionario, 
    id_ano;

