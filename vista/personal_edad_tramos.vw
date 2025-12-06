/*
================================================================================
  VISTA: rrhh.personal_edad_tramos
================================================================================
  PROPÓSITO:
    Proporciona estadísticas del personal activo agrupado por tramos de edad.
    Útil para análisis demográficos de la plantilla.

  CAMPOS RETORNADOS:
    - id_anno: Identificador del tramo de edad (ej: '18_a_29')
    - num_funcionario: Cantidad de funcionarios en ese tramo

  TRAMOS DE EDAD:
    - 18_a_29: De 18 a 29 años
    - 30_a_39: De 30 a 39 años
    - 40_a_49: De 40 a 49 años
    - 50_a_59: De 50 a 59 años
    - 60_o_mas: 60 años o más

  FILTROS APLICADOS:
    - Solo personal activo (fecha_baja IS NULL OR fecha_baja > SYSDATE)

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    OPTIMIZACIÓN PRINCIPAL: Eliminación de 5 UNIONs redundantes
    =========================================================================
    La versión anterior escaneaba la tabla 5 veces (una por cada tramo).

    VERSIÓN OPTIMIZADA: Un solo SELECT con CASE WHEN que clasifica cada
    funcionario en su tramo correspondiente, agrupando por el resultado.

    Mejora estimada de rendimiento: ~80% menos tiempo de ejecución

    NOTA: El cálculo de edad es aproximado (solo compara años, no fecha exacta)

    ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_personal_activo ON personal(fecha_baja, fecha_nacimiento);

  DEPENDENCIAS:
    - Tabla: personal

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Eliminados UNIONs, optimización completa
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.personal_edad_tramos AS
SELECT 
    id_anno,
    COUNT(*) AS num_funcionario
FROM (
    SELECT 
        CASE 
            WHEN TO_CHAR(SYSDATE, 'yyyy') - TO_CHAR(fecha_nacimiento, 'yyyy') BETWEEN 18 AND 29 THEN '18_a_29'
            WHEN TO_CHAR(SYSDATE, 'yyyy') - TO_CHAR(fecha_nacimiento, 'yyyy') BETWEEN 30 AND 39 THEN '30_a_39'
            WHEN TO_CHAR(SYSDATE, 'yyyy') - TO_CHAR(fecha_nacimiento, 'yyyy') BETWEEN 40 AND 49 THEN '40_a_49'
            WHEN TO_CHAR(SYSDATE, 'yyyy') - TO_CHAR(fecha_nacimiento, 'yyyy') BETWEEN 50 AND 59 THEN '50_a_59'
            WHEN TO_CHAR(SYSDATE, 'yyyy') - TO_CHAR(fecha_nacimiento, 'yyyy') >= 60 THEN '60_o_mas'
        END AS id_anno
    FROM 
        personal
    WHERE 
        (fecha_baja IS NULL OR fecha_baja > SYSDATE)
)
WHERE 
    id_anno IS NOT NULL
GROUP BY 
    id_anno
ORDER BY 
    id_anno;
