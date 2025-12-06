/*
================================================================================
  VISTA: rrhh.calendario_fichaje
================================================================================
  PROPÓSITO:
    Genera datos de calendario para fichajes, combinando un registro por defecto
    (funcionario 0) con los datos de permisos de los funcionarios. Proporciona
    información de columnas de calendario y rangos de fechas.

  CAMPOS RETORNADOS:
    - id_funcionario: Identificador del funcionario (0 para registro por defecto)
    - id_tipo_permiso: Tipo de permiso ('0' para registro por defecto)
    - id_tipo_estado: Estado del tipo de permiso
    - desc_columna: Descripción HTML de la columna del calendario
    - fecha_inicio: Fecha de inicio del rango
    - fecha_fin: Fecha de fin del rango

  FUENTES DE DATOS:
    1. Registro por defecto (DUAL): Crea un registro base con:
       - id_funcionario = 0
       - Rango de fechas amplio (01/01/1900 - 01/01/2100)
       - Celda blanca por defecto
    2. Permisos activos: Combina TR_TIPO_COLUMNA_CALENDARIO con permiso

  JOINS UTILIZADOS:
    - tr_tipo_columna_calendario (t): Configuración de columnas por tipo de permiso
    - permiso (p): Permisos de funcionarios

  FILTROS APLICADOS:
    - p.id_ano > 2019: Solo permisos desde 2020 en adelante

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    Se mantiene UNION por diseño (registro ficticio + datos reales)
    =========================================================================
    El primer SELECT genera un registro base necesario para el funcionamiento
    del calendario cuando no hay permisos.

    ALTERNATIVA: Podría usarse UNION ALL si se garantiza que el registro
    de DUAL nunca se duplicará con datos reales (id_funcionario = 0).

    ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_permiso_tipo_estado ON permiso(id_tipo_permiso, id_estado);
    - CREATE INDEX idx_permiso_ano ON permiso(id_ano);

  DEPENDENCIAS:
    - Tabla: tr_tipo_columna_calendario
    - Tabla: permiso

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación añadida
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.calendario_fichaje AS
(
    -- Registro por defecto para funcionario 0 (base del calendario)
    SELECT 
        0 AS id_funcionario, 
        '0' AS id_tipo_permiso,
        0 AS id_tipo_estado,
        '<td bgcolor=FFFFFF>' AS desc_columna,          -- Celda blanca por defecto
        TO_DATE('01/01/1900', 'DD/mm/yyyy') AS fecha_inicio,
        TO_DATE('01/01/2100', 'DD/mm/yyyy') AS fecha_fin
    FROM dual
    
    UNION
    
    -- Datos de permisos con configuración de columnas
    SELECT 
        id_funcionario,
        t.id_tipo_permiso,
        t.id_tipo_estado,
        SUBSTR(desc_tipo_columna, 1, 19) AS desc_columna,  -- Trunca descripción
        fecha_inicio,
        fecha_fin
    FROM 
        rrhh.tr_tipo_columna_calendario t
        INNER JOIN permiso p 
            ON p.id_tipo_permiso = t.id_tipo_permiso
            AND p.id_estado = t.id_tipo_estado
    WHERE 
        id_ano > 2019                                       -- Datos desde 2020
);

