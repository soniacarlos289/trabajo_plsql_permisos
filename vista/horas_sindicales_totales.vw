/*
================================================================================
  VISTA: rrhh.horas_sindicales_totales
================================================================================
  PROPÓSITO:
    Proporciona un resumen pivoteado de horas sindicales por funcionario y año,
    mostrando las horas totales y utilizadas de cada mes como columnas separadas.

  CAMPOS RETORNADOS:
    Por cada mes (E=Enero, F=Febrero, M=Marzo, etc.):
    - X_TOTAL: Horas totales asignadas del mes
    - X_UTILIZADAS: Horas utilizadas del mes

    Campos de agrupación:
    - id_funcionario: Identificador del funcionario
    - id_tipo_ausencia: Tipo de ausencia sindical
    - id_ano: Año de los datos

  FUENTE DE DATOS:
    - hora_sindical: Tabla de horas sindicales con id_mes

  TÉCNICA DE PIVOTEO:
    Utiliza DECODE en una subconsulta para transponer filas a columnas,
    seguido de SUM y GROUP BY para consolidar los resultados.

  NOTAS DE OPTIMIZACIÓN:
    - La estructura ya es óptima para este tipo de pivoteo en Oracle
    - El NVL(,0) maneja valores NULL correctamente
    - La subconsulta evita múltiples scans de la tabla
    - RECOMENDACIÓN: Índice en hora_sindical(id_funcionario, id_ano, id_mes)

  ORDEN DE MESES EN EL SELECT:
    E, F, M, A, MA, J, JU, AG, S, O, N, D
    (Enero, Febrero, Marzo, Abril, Mayo, Junio, Julio, Agosto, 
     Septiembre, Octubre, Noviembre, Diciembre)

  DEPENDENCIAS:
    - Tabla: hora_sindical

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación añadida
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.horas_sindicales_totales AS
(
SELECT 
    -- Enero
    NVL(SUM(enero_total), 0) AS e_total,
    NVL(SUM(enero_utilizadas), 0) AS e_utilizadas,
    -- Febrero
    NVL(SUM(febrero_total), 0) AS f_total,
    NVL(SUM(febrero_utilizadas), 0) AS f_utilizadas,
    -- Marzo
    NVL(SUM(marzo_total), 0) AS m_total,
    NVL(SUM(marzo_utilizadas), 0) AS m_utilizadas,
    -- Abril
    NVL(SUM(abril_total), 0) AS a_total,
    NVL(SUM(abril_utilizadas), 0) AS a_utilizadas,
    -- Mayo
    NVL(SUM(mayo_total), 0) AS ma_total,
    NVL(SUM(mayo_utilizadas), 0) AS ma_utilizadas,
    -- Junio
    NVL(SUM(junio_utilizadas), 0) AS j_utilizadas,
    NVL(SUM(junio_total), 0) AS j_total,
    -- Julio
    NVL(SUM(julio_utilizadas), 0) AS ju_utilizadas,
    NVL(SUM(julio_total), 0) AS ju_total,
    -- Agosto
    NVL(SUM(agosto_utilizadas), 0) AS ag_utilizadas,
    NVL(SUM(agosto_total), 0) AS ag_total,
    -- Septiembre
    NVL(SUM(septiembre_utilizadas), 0) AS s_utilizadas,
    NVL(SUM(septiembre_total), 0) AS s_total,
    -- Noviembre (nota: aparece antes de Octubre en el original)
    NVL(SUM(noviembre_utilizadas), 0) AS n_utilizadas,
    NVL(SUM(noviembre_total), 0) AS n_total,
    -- Octubre
    NVL(SUM(octubre_utilizadas), 0) AS o_utilizadas,
    NVL(SUM(octubre_total), 0) AS o_total,
    -- Diciembre
    NVL(SUM(diciembre_utilizadas), 0) AS d_utilizadas,
    NVL(SUM(diciembre_total), 0) AS d_total,
    -- Campos de agrupación
    id_funcionario,
    id_tipo_ausencia,
    id_ano
FROM (
    /*
     * Subconsulta: Pivotea los datos de filas (por mes) a columnas
     * usando DECODE para crear una columna por cada mes
     */
    SELECT
        -- Enero (mes 1)
        DECODE(id_mes, 1, total_horas, 0) AS enero_total,
        DECODE(id_mes, 1, total_utilizadas, 0) AS enero_utilizadas,
        -- Febrero (mes 2)
        DECODE(id_mes, 2, total_horas, 0) AS febrero_total,
        DECODE(id_mes, 2, total_utilizadas, 0) AS febrero_utilizadas,
        -- Marzo (mes 3)
        DECODE(id_mes, 3, total_horas, 0) AS marzo_total,
        DECODE(id_mes, 3, total_utilizadas, 0) AS marzo_utilizadas,
        -- Abril (mes 4)
        DECODE(id_mes, 4, total_horas, 0) AS abril_total,
        DECODE(id_mes, 4, total_utilizadas, 0) AS abril_utilizadas,
        -- Mayo (mes 5)
        DECODE(id_mes, 5, total_horas, 0) AS mayo_total,
        DECODE(id_mes, 5, total_utilizadas, 0) AS mayo_utilizadas,
        -- Junio (mes 6)
        DECODE(id_mes, 6, total_horas, 0) AS junio_total,
        DECODE(id_mes, 6, total_utilizadas, 0) AS junio_utilizadas,
        -- Julio (mes 7)
        DECODE(id_mes, 7, total_horas, 0) AS julio_total,
        DECODE(id_mes, 7, total_utilizadas, 0) AS julio_utilizadas,
        -- Agosto (mes 8)
        DECODE(id_mes, 8, total_horas, 0) AS agosto_total,
        DECODE(id_mes, 8, total_utilizadas, 0) AS agosto_utilizadas,
        -- Septiembre (mes 9)
        DECODE(id_mes, 9, total_horas, 0) AS septiembre_total,
        DECODE(id_mes, 9, total_utilizadas, 0) AS septiembre_utilizadas,
        -- Octubre (mes 10)
        DECODE(id_mes, 10, total_horas, 0) AS octubre_total,
        DECODE(id_mes, 10, total_utilizadas, 0) AS octubre_utilizadas,
        -- Noviembre (mes 11)
        DECODE(id_mes, 11, total_horas, 0) AS noviembre_total,
        DECODE(id_mes, 11, total_utilizadas, 0) AS noviembre_utilizadas,
        -- Diciembre (mes 12)
        DECODE(id_mes, 12, total_horas, 0) AS diciembre_total,
        DECODE(id_mes, 12, total_utilizadas, 0) AS diciembre_utilizadas,
        -- Campos de agrupación
        id_funcionario,
        id_tipo_ausencia,
        id_ano 
    FROM 
        hora_sindical
)
GROUP BY 
    id_funcionario, 
    id_tipo_ausencia, 
    id_ano
);
