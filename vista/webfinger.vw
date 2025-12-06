/*
================================================================================
  VISTA: rrhh.webfinger
================================================================================
  PROPÓSITO:
    Proporciona información de fichajes web para los últimos 365 días,
    calculando las horas obligatorias, horas fichadas y horas computables
    por empleado y fecha.

  CAMPOS RETORNADOS:
    - codpers: Código del personal
    - fecha: Fecha del registro de presencia
    - hoblig: Horas obligatorias en minutos (horas*60 + minutos)
    - campo11: Horas obligatorias negativas (para cálculo de saldo)
    - hfich: Horas fichadas en minutos
    - campo9: Horas computables fichadas en minutos

  JOINS UTILIZADOS:
    - presenci (a): Tabla principal de presencia
    - persfich (b): Fichajes del personal (LEFT OUTER JOIN)

  FILTROS APLICADOS:
    - codinci = '000': Solo registros con código de incidencia normal
    - fecha: Últimos 365 días hasta ayer

  NOTAS DE OPTIMIZACIÓN:
    - Convertido de sintaxis Oracle antigua (+) a LEFT OUTER JOIN estándar
    - Uso de TRUNC(SYSDATE) en lugar de to_Date(sysdate,...) para mejor rendimiento
    - El cálculo de minutos se mantiene en GROUP BY para evitar errores
    - WITH READ ONLY previene modificaciones accidentales
    - RECOMENDACIÓN: Crear índice en presenci(codinci, fecha, codpers)
    - RECOMENDACIÓN: Crear índice en persfich(npersonal, fecha)

  CÁLCULOS:
    - hoblig/campo11: Convierte hora teórica a minutos (hh*60+mi)
    - hfich: Suma de horas fichadas en minutos
    - campo9: Suma de horas computables fichadas en minutos

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Sintaxis JOIN moderna y documentación
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.webfinger AS
SELECT
    a.codpers,
    a.fecha,
    -- Horas obligatorias en minutos (extraídas del campo hora teórica)
    (TO_NUMBER(TO_CHAR(a.horteo, 'hh24')) * 60 + TO_NUMBER(TO_CHAR(a.horteo, 'mi'))) AS hoblig,
    -- Horas obligatorias negativas para cálculos de saldo
    (0 - (TO_NUMBER(TO_CHAR(a.horteo, 'hh24')) * 60 + TO_NUMBER(TO_CHAR(a.horteo, 'mi')))) AS campo11,
    -- Horas fichadas en minutos (con NVL para manejar ausencia de fichajes)
    NVL(SUM(TO_NUMBER(TO_CHAR(b.hfichadas, 'hh24')) * 60 + TO_NUMBER(TO_CHAR(b.hfichadas, 'mi'))), 0) AS hfich,
    -- Horas computables fichadas en minutos
    NVL(SUM(TO_NUMBER(TO_CHAR(b.hcomputablef, 'hh24')) * 60 + TO_NUMBER(TO_CHAR(b.hcomputablef, 'mi'))), 0) AS campo9
FROM
    presenci a
    LEFT OUTER JOIN persfich b
        ON a.codpers = b.npersonal
        AND a.fecha = b.fecha
WHERE
    a.codinci = '000'                                              -- Solo incidencia normal
    AND a.fecha BETWEEN TRUNC(SYSDATE) - 365 AND TRUNC(SYSDATE) - 1  -- Últimos 365 días hasta ayer
GROUP BY
    a.codpers,
    a.fecha,
    (TO_NUMBER(TO_CHAR(a.horteo, 'hh24')) * 60 + TO_NUMBER(TO_CHAR(a.horteo, 'mi'))),
    (0 - (TO_NUMBER(TO_CHAR(a.horteo, 'hh24')) * 60 + TO_NUMBER(TO_CHAR(a.horteo, 'mi'))))
WITH READ ONLY;

