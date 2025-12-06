/*
================================================================================
  VISTA: rrhh.personal_anno_ingreso
================================================================================
  PROPÓSITO:
    Proporciona el conteo de funcionarios que ingresaron por año.
    Útil para estadísticas de incorporaciones al personal.

  CAMPOS RETORNADOS:
    - id_ano: Año de ingreso
    - num_funcionario: Cantidad de funcionarios que ingresaron ese año

  FUENTE DE DATOS:
    - personal: Tabla de personal con fecha de ingreso

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    OPTIMIZACIÓN PRINCIPAL: Eliminación de 4 UNIONs redundantes
    =========================================================================
    La versión anterior repetía la misma consulta 4 veces con diferentes años.

    VERSIÓN OPTIMIZADA: Un solo SELECT con GROUP BY que extrae el año
    de fecha_ingreso y cuenta funcionarios por año.

    Mejora estimada de rendimiento: ~75% menos tiempo de ejecución

    ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_personal_fecha_ingreso ON personal(fecha_ingreso);

  DEPENDENCIAS:
    - Tabla: personal

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Eliminados UNIONs, optimización completa
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.personal_anno_ingreso AS
SELECT 
    EXTRACT(YEAR FROM fecha_ingreso) AS id_ano,
    COUNT(*) AS num_funcionario
FROM 
    personal
WHERE 
    fecha_ingreso >= TO_DATE('01/01/2018', 'dd/mm/yyyy')
    AND fecha_ingreso < TO_DATE('01/01/2022', 'dd/mm/yyyy')
GROUP BY 
    EXTRACT(YEAR FROM fecha_ingreso);
