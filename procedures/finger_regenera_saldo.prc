CREATE OR REPLACE PROCEDURE RRHH.FINGER_REGENERA_SALDO (
  v_id_funcionario IN VARCHAR2,
  v_periodo        IN VARCHAR2,
  v_tipo_funci     IN NUMBER
) IS
  /**
   * @description Regenera el cálculo de saldos finger para un periodo determinado
   * @details Proceso que recalcula saldos de fichaje para funcionarios activos en periodo especificado.
   *          Procesa funcionarios con contrato vigente o sin fecha de baja.
   *          - Tipo 21 (Policía): Utiliza cálculo especializado finger_calcula_saldo_policia
   *          - Otros tipos: Utiliza cálculo general finger_calcula_saldo
   *          - Incluye hardcode de funcionarios 101207 y 10013 (tipo 10=Administrativo)
   *          - Listas comentadas de funcionarios específicos (mantenimiento histórico)
   * @param v_id_funcionario ID funcionario específico o 0 para todos los activos
   * @param v_periodo Periodo a recalcular formato 'MMAAAA' (ej: '012023')
   * @param v_tipo_funci Tipo de funcionario filtro (10=Administrativo, 21=Policía, 23=Bombero) o 0 para todos
   * @notes 
   *   - Solo procesa funcionarios activos (sin fecha_baja o baja futura o con contrato vigente)
   *   - Periodo: usa función devuelve_periodo(v_periodo) para convertir formato
   *   - Recorre todos los días del calendario laboral del periodo
   *   - Listas comentadas: mantener por referencia histórica (backups, mantenimiento)
   *   - UNION hardcoded: agrega funcionarios 101207 y 10013 si coinciden con filtros
   */

  -- Constantes
  C_TIPO_FUNC_POLICIA    CONSTANT NUMBER := 21;
  C_TIPO_FUNC_ADMIN      CONSTANT NUMBER := 10;
  C_FUNC_HARDCODE_1      CONSTANT VARCHAR2(10) := '101207';
  C_FUNC_HARDCODE_2      CONSTANT VARCHAR2(10) := '10013';

  -- Variables
  i_id_dia            DATE;
  i_id_funcionario    VARCHAR2(10);
  i_tipo_funcionario2 NUMBER;

  -- Cursor: Funcionarios activos + hardcoded
  CURSOR c0 IS
    SELECT DISTINCT 
           id_funcionario,
           NVL(tipo_funcionario2, 0) AS tipo_func
    FROM personal_new
    WHERE (
            -- Funcionario activo: sin fecha_baja o con fecha_baja futura o con contrato vigente
            ((fecha_baja IS NULL AND fecha_fin_contrato IS NOT NULL) OR 
             (fecha_baja > SYSDATE) OR
             (fecha_baja IS NULL AND fecha_fin_contrato IS NULL))
          )
      AND (id_funcionario = v_id_funcionario OR 0 = v_id_funcionario)
      AND (tipo_funcionario2 = v_tipo_funci OR 0 = v_tipo_funci)
    /* Listas comentadas - mantener por referencia histórica
    AND id_funcionario IN (
      101149, 962925, 110012, 961093, 960875, 101249, 962602, 510599,
      60830, 101282, 961253, 600092, 101209, 962407, 101198, 961954,
      962153, 62006, 600125
    )
    -- Lista Mantenimiento
    AND id_funcionario IN (
      101218, 101219, 101220, 101221, 101223, 101238, 101240, 101247,
      101250, 101260, 101261, 101262, 101263, 101269, 101271, 101272,
      101273, 101276, 1141, 39082, 39106, 501357, 50175, 502331,
      502332, 504442, 510595, 510599, 510600, 510601, 510606, 510607,
      510608, 52003, 53002, 55106, 65147, 961073, 962072
    )
    */
    UNION
    -- Funcionario hardcoded 101207
    SELECT C_FUNC_HARDCODE_1, C_TIPO_FUNC_ADMIN
    FROM DUAL
    WHERE TO_NUMBER(C_FUNC_HARDCODE_1) = v_id_funcionario
    UNION
    -- Funcionario hardcoded 10013
    SELECT C_FUNC_HARDCODE_2, C_TIPO_FUNC_ADMIN
    FROM DUAL
    WHERE TO_NUMBER(C_FUNC_HARDCODE_2) = v_id_funcionario
    ORDER BY 1;

  -- Cursor: Días del periodo en calendario laboral
  CURSOR c2 IS
    SELECT TRUNC(id_dia) AS dia_calc
    FROM webperiodo o
    CROSS JOIN calendario_laboral cl
    WHERE id_dia BETWEEN inicio AND fin
      AND mes || ano = devuelve_periodo(v_periodo)
      AND id_dia < SYSDATE
    ORDER BY id_dia;

BEGIN

  -- **********************************
  -- FASE 1: Iterar funcionarios activos
  -- **********************************
  OPEN c0;
  LOOP
    FETCH c0 INTO i_id_funcionario, i_tipo_funcionario2;
    EXIT WHEN c0%NOTFOUND;

    -- **********************************
    -- FASE 2: Iterar días del periodo
    -- **********************************
    OPEN c2;
    LOOP
      FETCH c2 INTO i_id_dia;
      EXIT WHEN c2%NOTFOUND;

      -- **********************************
      -- FASE 3: Calcular saldo según tipo funcionario
      -- **********************************
      IF i_tipo_funcionario2 <> C_TIPO_FUNC_POLICIA THEN
        -- Cálculo estándar para no-policías
        finger_calcula_saldo(i_id_funcionario, i_id_dia);
      ELSE
        -- Cálculo especializado para policías
        finger_calcula_saldo_policia(i_id_funcionario, i_id_dia);
      END IF;

    END LOOP;
    CLOSE c2;

  END LOOP;
  CLOSE c0;

  -- **********************************
  -- FASE 4: Confirmar transacción
  -- **********************************
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    IF c0%ISOPEN THEN
      CLOSE c0;
    END IF;
    IF c2%ISOPEN THEN
      CLOSE c2;
    END IF;
    ROLLBACK;
    RAISE;

END FINGER_REGENERA_SALDO;
/

