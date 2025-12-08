CREATE OR REPLACE PROCEDURE RRHH.FINGER_REGENERA_SALDO_LISTA (
  v_id_funcionario IN VARCHAR2,
  v_periodo        IN VARCHAR2,
  v_tipo_funci     IN NUMBER
) IS
  /**
   * @description Regenera el cálculo de saldos finger para lista específica de funcionarios en periodo
   * @details Proceso que recalcula saldos de fichaje para lista hardcoded de funcionarios en periodo especificado.
   *          Similar a finger_regenera_saldo pero con filtro adicional de lista fija de IDs.
   *          - Tipo 21 (Policía): Utiliza cálculo especializado finger_calcula_saldo_policia
   *          - Otros tipos: Utiliza cálculo general finger_calcula_saldo
   *          - Lista hardcoded: 30 funcionarios específicos (600119, 114001, 203322, etc.)
   *          - Filtro modificado: usa 1 como comodín (en lugar de 0 en otros procedimientos)
   * @param v_id_funcionario ID funcionario específico o 1 para todos los de la lista
   * @param v_periodo Periodo a recalcular formato 'MMAAAA' (ej: '012023')
   * @param v_tipo_funci Tipo de funcionario filtro (10=Administrativo, 21=Policía, 23=Bombero) o 1 para todos
   * @notes 
   *   - Lista fija: 600119, 114001, 203322, 201394, 50196, 101157, 962730, 800050, 10109, 201436,
   *                 962006, 39152, 39081, 961503, 600106, 600093, 961507, 65240, 10109, 961113,
   *                 962598, 961719, 962000 (incluye duplicados 600119, 600093, 10109, 962598)
   *   - Solo procesa funcionarios con contrato vigente (fecha_fin_contrato futura o null)
   *   - Periodo: usa función devuelve_periodo(v_periodo) para convertir formato
   *   - Recorre todos los días del calendario laboral del periodo
   *   - Diferencia con finger_regenera_saldo: filtro 1 vs 0 y lista hardcoded obligatoria
   */

  -- Constantes
  C_TIPO_FUNC_POLICIA    CONSTANT NUMBER := 21;
  C_FECHA_MAXIMA         CONSTANT DATE := TO_DATE('01/01/2050', 'DD/MM/YYYY');

  -- Variables
  i_id_dia            DATE;
  i_id_funcionario    VARCHAR2(10);
  i_tipo_funcionario2 NUMBER;

  -- Cursor: Funcionarios de lista específica con contrato vigente
  CURSOR c0 IS
    SELECT DISTINCT 
           id_funcionario,
           NVL(tipo_funcionario2, 0) AS tipo_func
    FROM personal_new
    WHERE (
            -- Funcionario con contrato vigente o sin fecha de baja
            (fecha_fin_contrato IS NULL OR
             (fecha_fin_contrato > SYSDATE AND
              NVL(fecha_baja, SYSDATE) < C_FECHA_MAXIMA))
          )
      AND (id_funcionario = v_id_funcionario OR 1 = v_id_funcionario)
      AND (tipo_funcionario2 = v_tipo_funci OR 1 = v_tipo_funci)
      -- Lista hardcoded de funcionarios específicos
      AND id_funcionario IN (
            600119, 114001, 203322, 201394, 50196, 101157,
            962730, 800050, 10109, 201436, 600119, 962006,
            39152, 39081, 961503, 600106, 600093, 961507,
            65240, 600093, 600093, 10109, 600119, 961113,
            962598, 962598, 961719, 962000
          );
    /* Lista Mantenimiento comentada - mantener por referencia histórica
    AND id_funcionario IN (
      101218, 101219, 101220, 101221, 101223, 101238, 101240, 101247,
      101250, 101260, 101261, 101262, 101263, 101269, 101271, 101272,
      101273, 101276, 1141, 39082, 39106, 501357, 50175, 502331,
      502332, 504442, 510595, 510599, 510600, 510601, 510606, 510607,
      510608, 52003, 53002, 55106, 65147, 961073, 962072
    )
    */

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
  -- FASE 1: Iterar funcionarios de la lista
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

END FINGER_REGENERA_SALDO_LISTA;
/

