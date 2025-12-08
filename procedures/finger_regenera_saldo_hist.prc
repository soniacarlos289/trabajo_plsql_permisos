CREATE OR REPLACE PROCEDURE RRHH.FINGER_REGENERA_SALDO_HIST (
  v_id_funcionario IN VARCHAR2,
  v_periodo        IN VARCHAR2,
  v_tipo_funci     IN NUMBER
) IS
  /**
   * @description Regenera el cálculo histórico de saldos finger para un periodo determinado
   * @details Proceso que recalcula saldos de fichaje históricos para funcionarios con desajustes.
   *          Detecta funcionarios con diferencias entre horas_fichadas y horas_saldo en últimos 8 días,
   *          luego recalcula todos los días del periodo especificado.
   *          - Tipo 21 (Policía): Utiliza cálculo especializado finger_calcula_saldo_policia
   *          - Otros tipos: Utiliza cálculo general finger_calcula_saldo
   *          - Solo aplica a funcionarios NO policías en detección inicial
   * @param v_id_funcionario ID funcionario específico o 0 para todos con desajustes
   * @param v_periodo Periodo a recalcular formato 'MMAAAA' (ej: '012023')
   * @param v_tipo_funci Tipo de funcionario filtro (10=Administrativo, 21=Policía, 23=Bombero) o 0 para todos
   * @notes 
   *   - Detección inicial: solo funcionarios no-policía con fichajes recientes (últimos 8 días)
   *   - Periodo: usa función devuelve_periodo(v_periodo) para convertir formato
   *   - Rango de cálculo: desde inicio hasta fin del periodo, excluyendo días futuros
   *   - Recorre todos los días del calendario laboral del periodo
   */

  -- Constantes
  C_TIPO_FUNC_POLICIA   CONSTANT NUMBER := 21;
  C_DIAS_DETECCION      CONSTANT NUMBER := 8;

  -- Variables
  i_id_dia            DATE;
  i_id_funcionario    VARCHAR2(10);
  i_tipo_funcionario2 NUMBER;

  -- Cursor: Funcionarios con desajuste horas_fichadas <> horas_saldo (últimos 8 días, NO policías)
  CURSOR c0 IS
    SELECT DISTINCT 
           pe.id_funcionario,
           tipo_funcionario2 AS tipo_func
    FROM fichaje_funcionario f
    INNER JOIN personal_new pe ON pe.id_funcionario = f.id_funcionario
    WHERE fecha_fichaje_entrada > SYSDATE - C_DIAS_DETECCION
      AND horas_fichadas <> horas_saldo
      AND tipo_funcionario2 <> C_TIPO_FUNC_POLICIA
    ORDER BY pe.id_funcionario;

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
  -- FASE 1: Iterar funcionarios con desajustes
  -- **********************************
  OPEN c0;
  LOOP
    FETCH c0 INTO i_id_funcionario, i_tipo_funcionario2;
    EXIT WHEN c0%NOTFOUND;

    -- **********************************
    -- FASE 2: Iterar días del periodo histórico
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

END FINGER_REGENERA_SALDO_HIST;
/

