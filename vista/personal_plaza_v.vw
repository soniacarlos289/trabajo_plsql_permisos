/*
================================================================================
  VISTA: rrhh.personal_plaza_v
================================================================================
  PROPÓSITO:
    Proporciona información consolidada de plazas y personal, incluyendo
    estadísticas de ocupación (ocupadas, libres, total) junto con los datos
    del funcionario asignado a cada plaza y su clasificación profesional.

  CAMPOS RETORNADOS:
    - grupo: Código del grupo profesional
    - id_plaza: Identificador de la plaza
    - num_plaza: Número de la plaza
    - ocupadas: Cantidad de plazas ocupadas
    - libres: Cantidad de plazas libres
    - total_plazas: Total de plazas
    - id_escala: Identificador de la escala
    - desc_escala: Descripción de la escala
    - id_subescala: Identificador de la subescala
    - desc_subescala: Descripción de la subescala
    - id_clase: Identificador de la clase
    - desc_clase: Descripción de la clase
    - desc_plaza: Descripción de la plaza
    - id_funcionario: ID del funcionario asignado (NULL si vacante)
    - nombre: Nombre completo del funcionario o 'VACANTE'
    - contratacion: Tipo de contratación (natuplaz)

  SUBCONSULTAS:
    - T: Calcula estadísticas de ocupación por plaza
    - N: Obtiene detalles del personal y clasificación profesional

  JOINS UTILIZADOS:
    - personal_plaza: Relación plaza-funcionario
    - plaza_escala: Catálogo de escalas
    - plaza_subescala: Catálogo de subescalas (LEFT JOIN)
    - plaza_clase: Catálogo de clases (LEFT JOIN)
    - plaza_plaza: Catálogo de plazas
    - personal: Datos del personal

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    OPTIMIZACIONES APLICADAS:
    =========================================================================
    1. Se mantiene DISTINCT por necesidad funcional (múltiples versiones)
    2. La subconsulta pma obtiene la versión más reciente (max(versfase))
    3. Filtro por fechaeli > sysdate OR fechaeli IS NULL excluye plazas eliminadas

    ADVERTENCIAS:
    - La vista es compleja con múltiples subconsultas anidadas
    - El DISTINCT puede impactar el rendimiento con grandes volúmenes
    - La función DECODE para calcular ocupadas/libres es eficiente

    ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_pers_plaza_pk ON personal_plaza(id_plaza, num_plaza, versfase);
    - CREATE INDEX idx_pers_plaza_func ON personal_plaza(id_funcionario, fechaeli);
    - CREATE INDEX idx_personal_activo ON personal(fecha_baja, contratacion);

  LÓGICA DE CÁLCULO:
    - ocupadas: Cuenta plazas con id_funcionario no NULL y sin fecha fin
    - libres: Cuenta plazas sin funcionario asignado o con fecha fin
    - total_plazas: Suma total de registros por plaza

  DEPENDENCIAS:
    - Tabla: personal_plaza
    - Tabla: plaza_escala
    - Tabla: plaza_subescala
    - Tabla: plaza_clase
    - Tabla: plaza_plaza
    - Vista/Tabla: personal

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación completa
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.personal_plaza_v AS
SELECT DISTINCT
    n.grupo,
    t.id_plaza,
    n.num_plaza,
    ocupadas,
    libres,
    total_plazas,
    n.id_escala,
    n.desc_escala,
    n.id_subescala,
    n.desc_subescala,
    n.id_clase,
    n.desc_clase,
    n.desc_plaza,
    id_funcionario,
    nombre,
    t.natuplaz AS contratacion
FROM 
    -- Subconsulta T: Estadísticas de ocupación por plaza
    (
        SELECT
            pe.natuplaz,
            -- Cuenta plazas ocupadas (funcionario asignado sin fecha fin)
            SUM(DECODE(DECODE(ffinplaz, NULL, id_funcionario, NULL), NULL, 0, 1)) AS ocupadas,
            -- Cuenta plazas libres (sin funcionario o con fecha fin)
            SUM(DECODE(DECODE(ffinplaz, NULL, id_funcionario, NULL), NULL, 1, 0)) AS libres,
            SUM(1) AS total_plazas,
            pe.id_plaza
        FROM 
            personal_plaza pe
            INNER JOIN (
                -- Subconsulta para obtener la versión más reciente
                SELECT 
                    natuplaz,
                    id_plaza,
                    num_plaza,
                    MAX(versfase) AS versfase 
                FROM personal_plaza 
                GROUP BY natuplaz, id_plaza, num_plaza
            ) pma 
                ON pe.id_plaza = pma.id_plaza 
                AND pe.num_plaza = pma.num_plaza 
                AND pe.versfase = pma.versfase
                AND pe.natuplaz = pma.natuplaz
        WHERE 
            (pe.fechaeli > SYSDATE OR pe.fechaeli IS NULL)
        GROUP BY 
            pe.natuplaz, 
            pe.id_plaza
    ) t,
    -- Subconsulta N: Detalles del personal y clasificación
    (
        SELECT DISTINCT
            pe.codigrup AS grupo,
            p.id_funcionario,
            DECODE(nombre, NULL, 'VACANTE', nombre) AS nombre,
            pe.num_plaza,
            pe.id_escala,
            desc_escala,
            pe.id_subescala AS id_subescala,
            desc_subescala,
            pe.id_clase AS id_clase,
            desc_clase,
            pa.id_plaza AS id_plaza,
            pa.desc_plaza,
            pe.natuplaz
        FROM 
            personal_plaza pe
            INNER JOIN plaza_escala e ON pe.id_escala = e.id_escala
            LEFT OUTER JOIN plaza_subescala se ON pe.id_subescala = se.id_subescala
            LEFT OUTER JOIN plaza_clase c ON pe.id_clase = c.id_clase
            INNER JOIN plaza_plaza pa ON pe.id_plaza = pa.id_plaza
            LEFT OUTER JOIN (
                -- Personal activo con contratación
                SELECT DISTINCT 
                    id_funcionario, 
                    ape1 || ' ' || ape2 || ' ' || nombre AS nombre, 
                    contratacion, 
                    fecha_baja 
                FROM personal 
                WHERE contratacion IS NOT NULL 
                AND (fecha_baja IS NULL OR fecha_baja > SYSDATE)
            ) p ON pe.id_funcionario = p.id_funcionario
            INNER JOIN (
                -- Versión más reciente de cada plaza
                SELECT 
                    natuplaz,
                    id_plaza,
                    num_plaza,
                    MAX(versfase) AS versfase 
                FROM personal_plaza 
                GROUP BY natuplaz, id_plaza, num_plaza
            ) pma 
                ON pe.id_plaza = pma.id_plaza 
                AND pe.num_plaza = pma.num_plaza 
                AND pe.versfase = pma.versfase
                AND pe.natuplaz = pma.natuplaz
        WHERE 
            (pe.fechaeli > SYSDATE OR pe.fechaeli IS NULL)
    ) n
WHERE 
    t.id_plaza = n.id_plaza 
    AND n.natuplaz = t.natuplaz;

