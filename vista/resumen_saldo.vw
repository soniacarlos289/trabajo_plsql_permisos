/*
================================================================================
  VISTA: rrhh.resumen_saldo
================================================================================
  PROPÓSITO:
    Genera un resumen del saldo de fichaje diario por funcionario, combinando
    las horas que se deben hacer con las horas fichadas reales. Calcula el
    saldo (diferencia) y añade observaciones sobre incidencias.

  CAMPOS RETORNADOS:
    - id_dia: Fecha del día
    - fecha_fichaje_entrada: Timestamp de la primera entrada
    - fecha_fichaje_salida: Timestamp de la última salida
    - hr: Horas realizadas (fichadas) en minutos
    - hh: Horas a hacer según jornada
    - saldo_dia: Diferencia entre horas realizadas y horas a hacer
    - fuera_saldo: Horas fuera del saldo computable
    - periodo: Código de período (MMAAAA)
    - id_funcionario: Identificador del funcionario
    - observaciones: Texto con incidencias o información del turno

  JOINS UTILIZADOS:
    - fichaje_saldo_hacer (fh): Horas que debe hacer el funcionario
    - fichaje_saldo_fichado (fc): Horas realmente fichadas (LEFT OUTER JOIN)

  CONDICIONES DE JOIN:
    - Mismo funcionario
    - Mismo día (con conversión de fecha)
    - Mismo período

  FILTROS APLICADOS:
    - PERMISO_EN_DIA() = 0: Excluye días con permisos activos
    - computadas = 0: Solo registros no computados
    - fh.id_dia > sysdate - 1700: Aproximadamente últimos 4.5 años

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    ESTRUCTURA COMPLEJA - Varias llamadas a funciones
    =========================================================================
    Esta vista utiliza:
    1. JOIN con conversión de fechas (costoso)
    2. Función PERMISO_EN_DIA() ejecutada por cada fila
    3. ORDER BY que fuerza ordenamiento

    OPTIMIZACIONES APLICADAS:
    - Convertido de sintaxis (+) a LEFT OUTER JOIN estándar
    - Se mantiene la lógica de negocio original

    ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_fsh_func_dia ON fichaje_saldo_hacer(id_funcionario, id_dia);
    - CREATE INDEX idx_fsf_func_dia ON fichaje_saldo_fichado(id_funcionario, id_dia);

  OBSERVACIONES GENERADAS:
    - 'SIN FICHAJE EN EL DÍA + icono': Cuando horas_realizadas = 0
    - Nombre del turno (Mañana/Tarde/Noche): Según campo turno

  DEPENDENCIAS:
    - Vista: fichaje_saldo_hacer
    - Vista: fichaje_saldo_fichado
    - Función: permiso_en_dia()

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - JOIN moderno y documentación
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.resumen_saldo AS
SELECT 
    fh.id_dia,
    fc.fecha_fichaje_entrada,
    fc.fecha_fichaje_salida,
    NVL(horas_realizadas, 0) AS hr,                        -- Horas realizadas
    -- Horas a hacer: 0 si no laboral, según fichaje_dia si existe
    DECODE(laboral, 'NO', 0, 
        DECODE(fc.id_fichaje_dia, NULL, horas_hacer, 1, horas_hacer, 0.00001)
    ) AS hh,
    -- Saldo: horas realizadas - horas a hacer
    NVL(horas_realizadas, 0) - 
        DECODE(fc.id_fichaje_dia, NULL, horas_hacer, 1, horas_hacer, 0) AS saldo_dia,
    fuera_saldo,
    fh.periodo AS periodo,
    fh.id_funcionario,
    -- Observaciones: incidencia o nombre del turno
    DECODE(NVL(horas_realizadas, 0), 0,
        'SIN FICHAJE EN EL DÍA   <img src="../../imagen/icono_advertencia.jpg" alt="INCIDENCIA" width="22" height="22" border="0" >',
        DECODE(fc.turno, 0, '', 
            1, 'Turno Mañana',
            2, 'Turno Tarde',
            3, 'Turno Noche'
        )
    ) AS observaciones
FROM 
    fichaje_saldo_hacer fh
    LEFT OUTER JOIN fichaje_saldo_fichado fc 
        ON fh.id_funcionario = fc.id_funcionario 
        AND fh.id_dia = fc.id_dia
        AND TO_DATE(TO_CHAR(fc.fecha_fichaje_entrada, 'dd/mm/yyyy'), 'dd/mm/yyyy') =
            TO_DATE(TO_CHAR(fh.id_dia, 'dd/mm/yyyy'), 'dd/mm/yyyy')
        AND fh.periodo = fc.periodo
WHERE 
    permiso_en_dia(fh.id_funcionario, fh.id_dia) = 0       -- Sin permiso en el día
    AND NVL(computadas, 0) = 0                              -- No computados
    AND fh.id_dia > SYSDATE - 1700                          -- Últimos ~4.5 años
ORDER BY 
    1, 2;

