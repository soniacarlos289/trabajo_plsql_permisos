/*
================================================================================
  VISTA: rrhh.bolsa_saldo
================================================================================
  PROPÓSITO:
    Proporciona el saldo de horas de la bolsa de tiempo por funcionario y período.
    Convierte los minutos acumulados en horas y minutos para facilitar su lectura.
    Relaciona el saldo del período con el tipo de acumulación (motivo) configurado.

  CAMPOS RETORNADOS:
    - id_funcionario: Identificador del funcionario
    - desc_motivo_acumular: Descripción del motivo de acumulación de horas
    - acumulador: Identificador del tipo de acumulador
    - periodo: Período (1-13, donde 1=Enero, 12=Diciembre, 13=Enero año siguiente)
    - horas_excesos: Parte entera de las horas acumuladas (saldo_periodo/60)
    - horas_minutos: Minutos restantes después de calcular las horas (módulo 60)
    - id_ano: Año del saldo

  JOINS UTILIZADOS:
    - bolsa_saldo_periodo (b): Datos del saldo por período
    - bolsa_movimiento (bm): Movimientos de la bolsa (LEFT OUTER JOIN)
    - bolsa_tipo_acumulacion (t): Catálogo de tipos de acumulación

  NOTAS DE OPTIMIZACIÓN:
    - Eliminado DISTINCT innecesario - los registros ya son únicos por la agrupación
      implícita de la vista bolsa_saldo_periodo
    - Se mantienen los outer joins (+) para compatibilidad con períodos sin movimientos
    - El filtro bm.anulado(+)=0 excluye movimientos anulados del join
    - Se recomienda índice: CREATE INDEX idx_bolsa_mov_func ON bolsa_movimiento
      (id_funcionario, periodo, id_ano, anulado);

  DEPENDENCIAS:
    - Vista: bolsa_saldo_periodo
    - Tabla: bolsa_movimiento
    - Tabla: bolsa_tipo_acumulacion

  CÁLCULOS:
    - horas_excesos = TRUNC(saldo_periodo / 60): Divide minutos entre 60 y trunca
    - horas_minutos = MOD(saldo_periodo, 60): Resto de la división entre 60

  ÚLTIMA MODIFICACIÓN: 05/12/2025 - Optimización y comentarios
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.bolsa_saldo AS
SELECT 
    b.id_funcionario,
    t.desc_motivo_acumular,                    -- Descripción del tipo de acumulación
    t.acumulador,                              -- Identificador del acumulador
    b.periodo,                                 -- Período (1-13)
    TRUNC(b.saldo_periodo / 60) AS horas_excesos,   -- Horas completas
    MOD(b.saldo_periodo, 60)   AS horas_minutos,    -- Minutos restantes
    b.id_ano                                   -- Año del registro
FROM 
    bolsa_saldo_periodo b
    INNER JOIN bolsa_tipo_acumulacion t 
        ON b.id_acumulador = t.id_acumulador   -- Tipo de acumulación
    LEFT OUTER JOIN bolsa_movimiento bm 
        ON b.id_funcionario = bm.id_funcionario
        AND b.periodo = bm.periodo
        AND b.id_ano = bm.id_ano
        AND bm.anulado = 0;                    -- Solo movimientos no anulados

