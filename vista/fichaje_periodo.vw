/*
================================================================================
  VISTA: rrhh.fichaje_periodo
================================================================================
  PROPÓSITO:
    Genera información de períodos de fichaje combinando el calendario laboral
    con los períodos web. Proporciona diferentes formatos de representación
    del período y calcula el número de semanas.

  CAMPOS RETORNADOS:
    - semana: Número de semanas en el período (4 si duración=27 días, 5 en otro caso)
    - periodo: Fecha del día en formato dd/mm/yyyy
    - per: Concatenación mes+año (ej: '012025')
    - per2: Nombre del mes formateado + año (ej: 'Enero:       de 2025')

  JOINS UTILIZADOS:
    - webperiodo (c): Definición de períodos (inicio, fin, mes, año)
    - calendario_laboral (ca): Días del calendario laboral

  NOTA IMPORTANTE:
    Esta vista genera un producto cartesiano entre webperiodo y calendario_laboral.
    Para un uso correcto, se debe filtrar por el rango de fechas del período.

  CÁLCULOS:
    - semana: Basado en la diferencia entre fin e inicio del período
      * 27 días = 4 semanas (febrero)
      * Otros = 5 semanas
    - per2: Nombre del mes con padding para alineación visual

  NOTAS DE OPTIMIZACIÓN:
    - ADVERTENCIA: Sin cláusula WHERE, genera producto cartesiano (muy costoso)
    - RECOMENDACIÓN: Agregar condición ca.id_dia BETWEEN c.inicio AND c.fin
    - Sin embargo, mantener la estructura actual por compatibilidad
    - El filtro debe aplicarse en las consultas que usan esta vista

  DEPENDENCIAS:
    - Tabla: webperiodo
    - Tabla: calendario_laboral

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Añadida documentación y advertencias
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.fichaje_periodo AS
SELECT
    -- Calcula semanas: 4 para febrero (27 días), 5 para otros meses
    DECODE((fin - inicio), 27, 4, 5) AS semana,
    -- Fecha del día formateada
    TO_CHAR(ca.id_dia, 'dd/mm/yyyy') AS periodo,
    -- Código de período (MMAAAA)
    mes || ano AS per,
    -- Nombre del mes formateado con padding + año
    DECODE(mes,
        '01', RPAD('Enero:', 13, ' '),
        '02', RPAD('Febrero:', 13, ' '),
        '03', RPAD('Marzo:', 13, ' '),
        '04', RPAD('Abril:', 13, ' '),
        '05', RPAD('Mayo:', 13, ' '),
        '06', RPAD('Junio:', 13, ' '),
        '07', RPAD('Julio:', 13, ' '),
        '08', RPAD('Agosto:', 13, ' '),
        '09', RPAD('Septiembre:', 13, ' '),
        '10', RPAD('Octubre:', 13, ' '),
        '11', RPAD('Noviembre:', 13, ' '),
        '12', RPAD('Diciembre:', 13, ' '),
        mes
    ) || ' de ' || ano AS per2
FROM
    webperiodo c,
    calendario_laboral ca;

