/*
================================================================================
  VISTA: rrhh.calendario_final
================================================================================
  PROPÓSITO:
    Genera un calendario completo por funcionario indicando si cada día es
    laboral o no según la función laboral_dia(). Combina la información
    de personal con el calendario laboral y los períodos web.

  CAMPOS RETORNADOS:
    - id_dia: Fecha del día
    - des_col: Indicador de día laboral ('SI'/'NO') según laboral_dia()
    - mes: Mes del período
    - ano: Año del período
    - id_funcionario: Identificador del funcionario
    - id_ano: Año (duplicado de ano para compatibilidad)
    - observacion: Observaciones del día en calendario_laboral
    - compensable: Indicador si el día es compensable

  JOINS UTILIZADOS (implícitos - producto cartesiano controlado):
    - personal_new (f): Lista de funcionarios
    - calendario_laboral (cl): Días del calendario
    - webperiodo (ow): Definición de períodos

  FILTROS APLICADOS:
    - cl.id_dia BETWEEN ow.inicio AND ow.fin: Solo días dentro del período

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    ADVERTENCIA: Producto Cartesiano Costoso
    =========================================================================
    Esta vista genera un producto cartesiano entre:
    - Todos los funcionarios (personal_new)
    - Todos los días del calendario (calendario_laboral)
    - Filtrado por períodos (webperiodo)

    La función laboral_dia() se ejecuta para CADA combinación, lo cual
    puede ser muy costoso en términos de rendimiento.

    RECOMENDACIONES:
    1. Filtrar siempre por id_funcionario y rango de fechas en las consultas
    2. Considerar materializar resultados si se consultan frecuentemente
    3. Índices recomendados:
       - CREATE INDEX idx_cal_lab_dia ON calendario_laboral(id_dia);
       - CREATE INDEX idx_webperiodo_fechas ON webperiodo(inicio, fin);

    NOTA: ORDER BY en una vista no es una buena práctica, se mantiene
    por compatibilidad con código existente.

  DEPENDENCIAS:
    - Vista: personal_new
    - Tabla: calendario_laboral
    - Tabla: webperiodo
    - Función: laboral_dia()

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación y advertencias
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.calendario_final AS
SELECT 
    cl.id_dia,
    laboral_dia(id_funcionario, id_dia) AS des_col,    -- Evalúa si es laboral para el funcionario
    mes,
    ano,
    id_funcionario,
    ano AS id_ano,                                      -- Duplicado para compatibilidad
    cl.observacion,
    compensable
FROM 
    personal_new f,
    calendario_laboral cl,
    webperiodo ow
WHERE
    cl.id_dia BETWEEN ow.inicio AND ow.fin             -- Días dentro del período
ORDER BY 
    id_dia;

