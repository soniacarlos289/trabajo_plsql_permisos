/*
================================================================================
  VISTA: rrhh.bolsa_saldo_periodo
================================================================================
  PROPÓSITO:
    Calcula el saldo acumulado de horas (en minutos) por funcionario, año, 
    período y tipo de acumulador. Consolida los excesos de tiempo de todos 
    los meses aplicando reglas de penalización según la configuración de cada
    período.

  CAMPOS RETORNADOS:
    - id_funcionario: Identificador del funcionario
    - id_ano: Año del saldo
    - periodo: Período del cálculo (1-13, donde 13=Enero del año siguiente)
    - tope_horas: Límite máximo de horas configurado para el acumulador
    - id_acumulador: Tipo de acumulador (ej: horas extra, compensación, etc.)
    - saldo_periodo: Total de minutos acumulados en el período

  LÓGICA DE CÁLCULO:
    Para cada período (1-13), se evalúa si hay penalización:
    - Si penal_X = 0: Se suman los excesos (exceso_en_horas * 60 + excesos_en_minutos)
    - Si penal_X != 0 y hay valores negativos: Se permiten los valores negativos
    - Si penal_X != 0 y valores positivos: Se aplica 0 (penalización)

  JOINS UTILIZADOS:
    - bolsa_funcionario (b): Datos base del funcionario y acumulador
    - bolsa_movimiento (bm): Movimientos de horas (LEFT OUTER JOIN)
    - bolsa_tipo_acumulacion (t): Configuración del tipo de acumulación

  NOTAS DE OPTIMIZACIÓN:
    =========================================================================
    OPTIMIZACIÓN PRINCIPAL: Se eliminaron 13 UNIONs redundantes
    =========================================================================
    La versión anterior repetía el mismo JOIN 13 veces (una por cada mes),
    lo que multiplicaba x13 el costo de acceso a las tablas.

    VERSIÓN OPTIMIZADA: Un solo SELECT con DECODE condicional para cada mes,
    reduciendo drásticamente el número de escaneos de tabla.

    Mejora estimada de rendimiento: 60-80% menos tiempo de ejecución.

    ÍNDICES RECOMENDADOS:
    - CREATE INDEX idx_bolsa_func_acum ON bolsa_funcionario(id_funcionario, id_acumulador, id_ano);
    - CREATE INDEX idx_bolsa_mov_all ON bolsa_movimiento(id_funcionario, id_ano, periodo, anulado);

  DEPENDENCIAS:
    - Tabla: bolsa_funcionario
    - Tabla: bolsa_movimiento
    - Tabla: bolsa_tipo_acumulacion

  HISTORIAL:
    - Versión original: 13 UNIONs separados
    - 05/12/2025: Optimización completa - un solo SELECT con DECODEs condicionales

  NOTA: Los campos penal_enero, penal_febrero, etc. son columnas de la tabla
        bolsa_movimiento que indican si se aplica penalización en ese mes.
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.bolsa_saldo_periodo AS
SELECT 
    id_funcionario, 
    id_ano, 
    periodo, 
    tope_horas,
    id_acumulador,
    -- Suma de todos los meses para obtener el saldo del período
    SUM(penal_enero) + SUM(penal_febrero) + SUM(penal_marzo) +
    SUM(penal_abril) + SUM(penal_mayo) + SUM(penal_junio) +
    SUM(penal_julio) + SUM(penal_agosto) + SUM(penal_septiembre) +
    SUM(penal_octubre) + SUM(penal_noviembre) + SUM(penal_diciembre) +
    SUM(penal_enero_mas) AS saldo_periodo
FROM (
    /*
     * Subconsulta optimizada: calcula todos los períodos en una sola pasada
     * usando DECODE condicional por período en lugar de 13 UNIONs separados.
     * Cada columna penal_X solo calcula valores cuando PERIODO = X.
     */
    SELECT 
        b.id_funcionario, 
        b.id_ano,
        bm.periodo, 
        t.tope_horas,
        b.id_acumulador,
        
        -- ENERO (Periodo 1): Calcula exceso o aplica penalización
        SUM(DECODE(bm.periodo, 1, 
            DECODE(bm.penal_enero, 0, 
                bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                DECODE(SIGN(bm.excesos_en_minutos), -1, 
                    bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                    DECODE(SIGN(bm.exceso_en_horas), -1, 
                        bm.exceso_en_horas * 60 + bm.excesos_en_minutos, 
                        0)
                )
            ), 
            0)
        ) AS penal_enero,
        
        -- FEBRERO (Periodo 2)
        SUM(DECODE(bm.periodo, 2, 
            DECODE(bm.penal_febrero, 0, 
                bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                DECODE(SIGN(bm.excesos_en_minutos), -1, 
                    bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                    DECODE(SIGN(bm.exceso_en_horas), -1, 
                        bm.exceso_en_horas * 60 + bm.excesos_en_minutos, 
                        0)
                )
            ), 
            0)
        ) AS penal_febrero,
        
        -- MARZO (Periodo 3)
        SUM(DECODE(bm.periodo, 3, 
            DECODE(bm.penal_marzo, 0, 
                bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                DECODE(SIGN(bm.excesos_en_minutos), -1, 
                    bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                    DECODE(SIGN(bm.exceso_en_horas), -1, 
                        bm.exceso_en_horas * 60 + bm.excesos_en_minutos, 
                        0)
                )
            ), 
            0)
        ) AS penal_marzo,
        
        -- ABRIL (Periodo 4)
        SUM(DECODE(bm.periodo, 4, 
            DECODE(bm.penal_abril, 0, 
                bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                DECODE(SIGN(bm.excesos_en_minutos), -1, 
                    bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                    DECODE(SIGN(bm.exceso_en_horas), -1, 
                        bm.exceso_en_horas * 60 + bm.excesos_en_minutos, 
                        0)
                )
            ), 
            0)
        ) AS penal_abril,
        
        -- MAYO (Periodo 5)
        SUM(DECODE(bm.periodo, 5, 
            DECODE(bm.penal_mayo, 0, 
                bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                DECODE(SIGN(bm.excesos_en_minutos), -1, 
                    bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                    DECODE(SIGN(bm.exceso_en_horas), -1, 
                        bm.exceso_en_horas * 60 + bm.excesos_en_minutos, 
                        0)
                )
            ), 
            0)
        ) AS penal_mayo,
        
        -- JUNIO (Periodo 6)
        SUM(DECODE(bm.periodo, 6, 
            DECODE(bm.penal_junio, 0, 
                bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                DECODE(SIGN(bm.excesos_en_minutos), -1, 
                    bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                    DECODE(SIGN(bm.exceso_en_horas), -1, 
                        bm.exceso_en_horas * 60 + bm.excesos_en_minutos, 
                        0)
                )
            ), 
            0)
        ) AS penal_junio,
        
        -- JULIO (Periodo 7)
        SUM(DECODE(bm.periodo, 7, 
            DECODE(bm.penal_julio, 0, 
                bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                DECODE(SIGN(bm.excesos_en_minutos), -1, 
                    bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                    DECODE(SIGN(bm.exceso_en_horas), -1, 
                        bm.exceso_en_horas * 60 + bm.excesos_en_minutos, 
                        0)
                )
            ), 
            0)
        ) AS penal_julio,
        
        -- AGOSTO (Periodo 8)
        SUM(DECODE(bm.periodo, 8, 
            DECODE(bm.penal_agosto, 0, 
                bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                DECODE(SIGN(bm.excesos_en_minutos), -1, 
                    bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                    DECODE(SIGN(bm.exceso_en_horas), -1, 
                        bm.exceso_en_horas * 60 + bm.excesos_en_minutos, 
                        0)
                )
            ), 
            0)
        ) AS penal_agosto,
        
        -- SEPTIEMBRE (Periodo 9)
        SUM(DECODE(bm.periodo, 9, 
            DECODE(bm.penal_septiembre, 0, 
                bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                DECODE(SIGN(bm.excesos_en_minutos), -1, 
                    bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                    DECODE(SIGN(bm.exceso_en_horas), -1, 
                        bm.exceso_en_horas * 60 + bm.excesos_en_minutos, 
                        0)
                )
            ), 
            0)
        ) AS penal_septiembre,
        
        -- OCTUBRE (Periodo 10)
        SUM(DECODE(bm.periodo, 10, 
            DECODE(bm.penal_octubre, 0, 
                bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                DECODE(SIGN(bm.excesos_en_minutos), -1, 
                    bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                    DECODE(SIGN(bm.exceso_en_horas), -1, 
                        bm.exceso_en_horas * 60 + bm.excesos_en_minutos, 
                        0)
                )
            ), 
            0)
        ) AS penal_octubre,
        
        -- NOVIEMBRE (Periodo 11)
        SUM(DECODE(bm.periodo, 11, 
            DECODE(bm.penal_noviembre, 0, 
                bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                DECODE(SIGN(bm.excesos_en_minutos), -1, 
                    bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                    DECODE(SIGN(bm.exceso_en_horas), -1, 
                        bm.exceso_en_horas * 60 + bm.excesos_en_minutos, 
                        0)
                )
            ), 
            0)
        ) AS penal_noviembre,
        
        -- DICIEMBRE (Periodo 12)
        SUM(DECODE(bm.periodo, 12, 
            DECODE(bm.penal_diciembre, 0, 
                bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                DECODE(SIGN(bm.excesos_en_minutos), -1, 
                    bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                    DECODE(SIGN(bm.exceso_en_horas), -1, 
                        bm.exceso_en_horas * 60 + bm.excesos_en_minutos, 
                        0)
                )
            ), 
            0)
        ) AS penal_diciembre,
        
        -- ENERO SIGUIENTE AÑO (Periodo 13)
        SUM(DECODE(bm.periodo, 13, 
            DECODE(bm.penal_enero_mas, 0, 
                bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                DECODE(SIGN(bm.excesos_en_minutos), -1, 
                    bm.exceso_en_horas * 60 + bm.excesos_en_minutos,
                    DECODE(SIGN(bm.exceso_en_horas), -1, 
                        bm.exceso_en_horas * 60 + bm.excesos_en_minutos, 
                        0)
                )
            ), 
            0)
        ) AS penal_enero_mas
        
    FROM 
        bolsa_funcionario b
        INNER JOIN bolsa_tipo_acumulacion t 
            ON b.id_acumulador = t.id_acumulador
        LEFT OUTER JOIN bolsa_movimiento bm 
            ON b.id_funcionario = bm.id_funcionario
            AND b.id_ano = bm.id_ano
            AND NVL(bm.anulado, 0) = 0          -- Excluir movimientos anulados
    GROUP BY 
        b.id_ano, 
        bm.periodo, 
        b.id_funcionario, 
        t.tope_horas, 
        b.id_acumulador
)
GROUP BY 
    id_ano, 
    periodo, 
    id_funcionario, 
    tope_horas, 
    id_acumulador;

