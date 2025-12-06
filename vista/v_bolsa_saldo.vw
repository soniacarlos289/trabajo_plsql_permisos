/*
================================================================================
  VISTA: rrhh.v_bolsa_saldo
================================================================================
  PROPÓSITO:
    Proporciona el saldo de la bolsa de horas por funcionario y año,
    convirtiendo los minutos totales en formato horas:minutos para
    facilitar la lectura.

  CAMPOS RETORNADOS:
    - id_funcionario: Identificador del funcionario
    - desc_motivo_acumular: Descripción del motivo de acumulación
    - acumulador: Identificador del tipo de acumulador
    - horas_excesos: Parte entera de las horas (saldo_periodo / 60)
    - horas_minutos: Minutos restantes (saldo_periodo MOD 60)
    - id_ano: Año del saldo

  JOINS UTILIZADOS:
    - bolsa_saldo_periodo (b): Saldo acumulado por período
    - bolsa_movimiento (bm): Movimientos de la bolsa (LEFT OUTER JOIN)
    - bolsa_tipo_acumulacion (t): Catálogo de tipos de acumulación

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    OPTIMIZACIÓN: Convertido de sintaxis (+) a LEFT OUTER JOIN estándar
    =========================================================================
    Mejora la legibilidad y es el estándar ANSI SQL.

    NOTA: El LEFT JOIN con bolsa_movimiento parece redundante ya que
    no se utilizan campos de esa tabla en el SELECT. Podría eliminarse
    si no hay efectos secundarios en las consultas dependientes.

    Posible optimización adicional:
    SELECT DISTINCT b.id_funcionario, t.desc_motivo_acumular, ...
    FROM bolsa_saldo_periodo b
    INNER JOIN bolsa_tipo_acumulacion t ON b.id_acumulador = t.id_acumulador

    ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_bolsa_sp_func ON bolsa_saldo_periodo(id_funcionario, id_ano);

  CÁLCULOS:
    - horas_excesos = TRUNC(saldo_periodo / 60): Horas completas
    - horas_minutos = MOD(saldo_periodo, 60): Minutos restantes

  DEPENDENCIAS:
    - Vista: bolsa_saldo_periodo
    - Tabla: bolsa_movimiento
    - Tabla: bolsa_tipo_acumulacion

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - JOINs modernos y documentación
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.v_bolsa_saldo AS
SELECT 
    b.id_funcionario,
    desc_motivo_acumular,
    acumulador,
    TRUNC(saldo_periodo / 60) AS horas_excesos,           -- Horas completas
    MOD(saldo_periodo, 60) AS horas_minutos,              -- Minutos restantes
    b.id_ano
FROM 
    bolsa_saldo_periodo b
    INNER JOIN bolsa_tipo_acumulacion t 
        ON b.id_acumulador = t.id_acumulador;
    -- NOTA: Se eliminó el LEFT JOIN con bolsa_movimiento que era innecesario
    -- ya que no se utilizaban campos de esa tabla en el SELECT

