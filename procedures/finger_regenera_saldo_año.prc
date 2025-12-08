CREATE OR REPLACE PROCEDURE RRHH.FINGER_REGENERA_SALDO_AÑO (
  v_id_funcionario IN VARCHAR2,
  v_periodo        IN VARCHAR2,
  v_tipo_funci     IN NUMBER
) IS
  /**
   * @description Regenera el cálculo de saldos finger para todo el año 2018
   * @details Proceso que recalcula saldos de fichaje para todos los días del año 2018 en calendario laboral.
   *          Procesa funcionarios activos sin fecha de baja o con fecha de baja futura.
   *          - Tipo 21 (Policía): Utiliza cálculo especializado finger_calcula_saldo_policia
   *          - Otros tipos: Utiliza cálculo general finger_calcula_saldo
   *          - Año hardcoded: solo procesa año 2018
   * @param v_id_funcionario ID funcionario específico o 0 para todos los activos
   * @param v_periodo Periodo (parámetro no utilizado actualmente - año hardcoded a 2018)
   * @param v_tipo_funci Tipo de funcionario filtro (10=Administrativo, 21=Policía, 23=Bombero) o 0 para todos
   * @notes 
   *   - Año fijo: solo recalcula días del año 2018 (ANO=2018)
   *   - Solo procesa funcionarios sin fecha_baja o con fecha_baja futura (< 01/01/2050)
   *   - Parámetro v_periodo no se utiliza (comentado en código original)
   *   - Recorre todos los días del calendario laboral del año filtrados por webperiodo
   */

  -- Constantes
  C_TIPO_FUNC_POLICIA   CONSTANT NUMBER := 21;
  C_ANO_CALCULO         CONSTANT NUMBER := 2018;
  C_FECHA_MAXIMA        CONSTANT DATE := TO_DATE('01/01/2050', 'DD/MM/YYYY');

  -- Variables
  i_id_dia            DATE;
  i_id_funcionario    VARCHAR2(10);
  i_tipo_funcionario2 NUMBER;

  -- Cursor: Funcionarios activos (sin fecha_baja o baja futura)
  CURSOR c0 IS
    SELECT DISTINCT 
           id_funcionario,
           NVL(tipo_funcionario2, 0) AS tipo_func
    FROM personal_new
    WHERE (fecha_baja IS NULL OR
           (fecha_baja > SYSDATE AND fecha_baja < C_FECHA_MAXIMA))
      AND (id_funcionario = v_id_funcionario OR 0 = v_id_funcionario)
      AND (tipo_funcionario2 = v_tipo_funci OR 0 = v_tipo_funci)
    ORDER BY id_funcionario DESC;

  -- Cursor: Días del año 2018 en calendario laboral
  CURSOR c2 IS
    SELECT TRUNC(id_dia) AS dia_calc
    FROM webperiodo o
    CROSS JOIN calendario_laboral cl
    WHERE id_dia BETWEEN inicio AND fin
      AND ano = C_ANO_CALCULO
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
    -- FASE 2: Iterar días del año 2018
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

END FINGER_REGENERA_SALDO_AÑO;
/

