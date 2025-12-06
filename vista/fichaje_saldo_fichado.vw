/*
================================================================================
  VISTA: rrhh.fichaje_saldo_fichado
================================================================================
  PROPÓSITO:
    Proporciona información de las horas fichadas por funcionario y día,
    incluyendo timestamps de entrada/salida, horas realizadas y turno.

  CAMPOS RETORNADOS:
    - periodo: Código de período (MMAAAA)
    - id_funcionario: Identificador del funcionario
    - id_dia: Fecha del día de trabajo
    - horas_realizadas: Horas de saldo computadas
    - fecha_fichaje_entrada: Timestamp de la primera entrada
    - fecha_fichaje_salida: Timestamp de la última salida
    - id_fichaje_dia: Identificador del fichaje del día
    - turno: Código del turno (1=Mañana, 2=Tarde, 3=Noche)
    - computadas: Indicador si ya fue computado
    - horas_fichadas: Total de horas fichadas
    - fuera_saldo: Horas fichadas fuera del cómputo de saldo

  JOINS UTILIZADOS:
    - fichaje_funcionario (f): Datos de fichaje
    - calendario_laboral (cl): Calendario de días laborables
    - webperiodo (ow): Definición de períodos

  CONDICIONES DE JOIN:
    - cl.id_dia = fecha de entrada del fichaje (solo parte de fecha)
    - cl.id_dia dentro del rango del período
    - computadas = 0 (solo fichajes no procesados)
    - cl.id_dia < sysdate - 1 (excluye días recientes)

  NOTAS DE OPTIMIZACIÓN:
    - La conversión de fecha (to_date/to_char) es costosa pero necesaria
      para comparar solo la parte de fecha
    - ALTERNATIVA: Usar TRUNC(f.fecha_fichaje_entrada) = cl.id_dia
    - El filtro computadas=0 y fecha reduce significativamente los datos

    ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_fich_func_fecha ON fichaje_funcionario(fecha_fichaje_entrada);
    - CREATE INDEX idx_cal_lab_dia ON calendario_laboral(id_dia);
    - CREATE INDEX idx_webper_rango ON webperiodo(inicio, fin);

  CÁLCULOS:
    - fuera_saldo = horas_fichadas - horas_saldo: Diferencia entre fichado y computable

  DEPENDENCIAS:
    - Tabla: fichaje_funcionario
    - Tabla: calendario_laboral
    - Tabla: webperiodo

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación añadida
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.fichaje_saldo_fichado AS
(
SELECT 
    ow.mes || ow.ano AS periodo,
    id_funcionario,
    cl.id_dia,
    horas_saldo AS horas_realizadas,
    fecha_fichaje_entrada,
    fecha_fichaje_salida,
    id_fichaje_dia,
    turno,
    computadas,
    horas_fichadas,
    horas_fichadas - horas_saldo AS fuera_saldo    -- Horas fuera del cómputo
FROM 
    fichaje_funcionario f,
    calendario_laboral cl,
    webperiodo ow
WHERE
    -- JOIN: Fecha del fichaje coincide con día del calendario
    cl.id_dia = TO_DATE(TO_CHAR(f.fecha_fichaje_entrada, 'dd/mm/yyyy'), 'dd/mm/yyyy')
    -- Día dentro del período
    AND cl.id_dia BETWEEN ow.inicio AND ow.fin
    -- Solo fichajes no procesados
    AND computadas = 0
    -- Excluir días recientes (ayer y hoy)
    AND cl.id_dia < SYSDATE - 1
);

