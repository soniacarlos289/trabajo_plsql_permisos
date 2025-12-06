/*
================================================================================
  VISTA: rrhh.fichaje_saldo_hacer
================================================================================
  PROPÓSITO:
    Calcula las horas que cada funcionario debe trabajar por día según su jornada
    configurada. Considera los días de la semana aplicables y si el día es laboral.

  CAMPOS RETORNADOS:
    - periodo: Código de período (MMAAAA)
    - id_funcionario: Identificador del funcionario
    - id_dia: Fecha del día
    - laboral: Indicador si es día laboral ('SI'/'NO')
    - horas_hacer: Minutos totales a trabajar en el día

  JOINS UTILIZADOS:
    - fichaje_funcionario_jornada (f): Configuración de jornada por funcionario
    - calendario_laboral (cl): Calendario de días laborables
    - webperiodo (ow): Definición de períodos

  CONDICIONES DE JOIN:
    - cl.id_dia dentro del rango de vigencia de la jornada
    - cl.id_dia dentro del rango del período
    - cl.id_dia < sysdate - 1 (excluye días recientes)

  FUNCIONES UTILIZADAS:
    - devuelve_dia_jornada(dias_semana, id_dia): Determina si el funcionario
      trabaja ese día de la semana según su configuración de jornada.
      Retorna 1 si trabaja, 0 si no.

  CÁLCULO DE HORAS:
    horas_hacer = SUM((horas_jornada - fecha_base) * 60 * 24 * indicador_dia)
    
    Donde:
    - horas_jornada: Hora de la jornada almacenada como DATE
    - fecha_base: 01/01/1900 00:00 (punto de referencia)
    - La resta da la fracción de día
    - *60*24 convierte a minutos
    - *indicador_dia: 1 si trabaja, 0 si no

  NOTAS DE OPTIMIZACIÓN:
    - El DECODE para días no laborales evita cálculos innecesarios
    - La función devuelve_dia_jornada se ejecuta por cada fila
    - GROUP BY necesario por la función SUM

    ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_fich_jor_func ON fichaje_funcionario_jornada(id_funcionario, fecha_inicio, fecha_fin);
    - CREATE INDEX idx_cal_lab_dia ON calendario_laboral(id_dia);

  DEPENDENCIAS:
    - Tabla: fichaje_funcionario_jornada
    - Tabla: calendario_laboral
    - Tabla: webperiodo
    - Función: devuelve_dia_jornada()

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación añadida
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.fichaje_saldo_hacer AS
(
SELECT 
    ow.mes || ow.ano AS periodo,
    id_funcionario,
    cl.id_dia,
    cl.laboral,
    -- Cálculo de horas a hacer: 0 si no es laboral, suma de minutos si lo es
    DECODE(cl.laboral, 'NO', 0,
        SUM(
            ((f.horas_jornada - TO_DATE('01/01/1900 00:00', 'DD/mm/yyyy hh24:mi')) * 60 * 24) *
            (devuelve_dia_jornada(dias_semana, cl.id_dia))
        )
    ) AS horas_hacer
FROM 
    fichaje_funcionario_jornada f,
    calendario_laboral cl,
    webperiodo ow
WHERE
    -- Día dentro del rango de vigencia de la jornada
    cl.id_dia BETWEEN f.fecha_inicio AND NVL(f.fecha_fin, SYSDATE - 1)
    -- Día dentro del período
    AND cl.id_dia BETWEEN ow.inicio AND ow.fin
    -- Excluir días recientes
    AND cl.id_dia < SYSDATE - 1
GROUP BY 
    ow.mes || ow.ano,
    id_funcionario,
    cl.id_dia,
    cl.laboral
);

