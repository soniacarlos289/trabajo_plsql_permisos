/*
================================================================================
  VISTA: rrhh.v_bolsa_movimiento
================================================================================
  PROPÓSITO:
    Proporciona información de movimientos de la bolsa de horas por funcionario,
    incluyendo excesos de tiempo, período y tipo de movimiento.

  CAMPOS RETORNADOS:
    - acumulador: Indicador simplificado (1 si id_acumulador=1, 0 en otro caso)
    - id_funcionario: Identificador del funcionario
    - exceso_en_horas: Horas de exceso registradas
    - excesos_en_minutos: Minutos de exceso registrados
    - id_ano: Año del registro
    - periodo: Período (mes) del movimiento
    - id_tipo_movimiento: Tipo de movimiento realizado
    - desc_tipo_movimiento: Descripción del tipo de movimiento
    - fecha_movimiento: Fecha del movimiento

  JOINS UTILIZADOS:
    - bolsa_funcionario (b): Datos del funcionario en la bolsa
    - bolsa_movimiento (bm): Movimientos de horas
    - bolsa_tipo_movimiento (tim): Catálogo de tipos de movimiento

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    OPTIMIZACIÓN: Eliminado DISTINCT innecesario
    =========================================================================
    El DISTINCT original era innecesario porque:
    - La combinación de bm.id_funcionario + bm.id_ano + bm.periodo + 
      bm.fecha_movimiento debería ser única
    - Si hay duplicados en los datos fuente, el problema está en los datos,
      no en la vista

    Sin embargo, si la consulta sigue retornando duplicados, considerar:
    1. Agregar una clave primaria a bolsa_movimiento
    2. O usar un GROUP BY explícito

    ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_bolsa_func_ano ON bolsa_funcionario(id_funcionario, id_ano);
    - CREATE INDEX idx_bolsa_mov_func ON bolsa_movimiento(id_funcionario, id_ano);

  CÁLCULOS:
    - acumulador: Simplificación del id_acumulador (1 -> 1, otros -> 0)

  DEPENDENCIAS:
    - Tabla: bolsa_funcionario
    - Tabla: bolsa_movimiento
    - Tabla: bolsa_tipo_movimiento

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Eliminado DISTINCT, JOINs modernos, documentación
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.v_bolsa_movimiento AS
SELECT 
    DECODE(id_acumulador, 1, 1, 0) AS acumulador,         -- Simplificación del acumulador
    bm.id_funcionario,
    exceso_en_horas,
    excesos_en_minutos,
    b.id_ano,
    periodo,
    bm.id_tipo_movimiento,
    desc_tipo_movimiento,
    fecha_movimiento
FROM 
    bolsa_funcionario b
    INNER JOIN bolsa_movimiento bm 
        ON b.id_funcionario = bm.id_funcionario
        AND b.id_ano = bm.id_ano
    INNER JOIN bolsa_tipo_movimiento tim 
        ON bm.id_tipo_movimiento = tim.id_tipo_movimiento;

