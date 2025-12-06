/*
================================================================================
  VISTA: rrhh.personal_anno_bajas
================================================================================
  PROPÓSITO:
    Proporciona un listado de funcionarios que causaron baja en un año específico,
    organizados por año. Útil para estadísticas de rotación de personal.

  CAMPOS RETORNADOS:
    - id_ano: Año de la baja
    - id_funcionario: Identificador del funcionario

  FUENTE DE DATOS:
    - personal: Tabla de personal con fecha de baja

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    OPTIMIZACIÓN PRINCIPAL: Eliminación de 4 UNIONs redundantes
    =========================================================================
    La versión anterior repetía la misma consulta 4 veces con diferentes años.

    VERSIÓN OPTIMIZADA: Un solo SELECT que extrae el año de fecha_baja
    y filtra el rango de años deseado.

    Mejora estimada de rendimiento: ~75% menos tiempo de ejecución
    (1 scan de tabla vs 4 scans)

    NOTA: Para agregar nuevos años, solo modificar el filtro de fechas.
    No es necesario agregar más UNIONs.

    EXTENSIÓN RECOMENDADA:
    - Para incluir años adicionales, cambiar el rango de fechas
    - O mejor aún, eliminar el filtro de años para obtener todos los datos

  ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_personal_fecha_baja ON personal(fecha_baja);

  DEPENDENCIAS:
    - Tabla: personal

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Eliminados UNIONs, optimización completa
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.personal_anno_bajas AS
SELECT 
    EXTRACT(YEAR FROM fecha_baja) AS id_ano,
    id_funcionario
FROM 
    personal
WHERE 
    fecha_baja >= TO_DATE('01/01/2018', 'dd/mm/yyyy')
    AND fecha_baja < TO_DATE('01/01/2022', 'dd/mm/yyyy');

