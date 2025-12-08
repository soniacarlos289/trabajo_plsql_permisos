CREATE OR REPLACE PROCEDURE RRHH.FINGER_REGENERA_SALDO_DIARIO (
  v_id_funcionario IN VARCHAR2,
  v_tipo_funci     IN NUMBER,
  i_ayer           IN NUMBER
) IS
  /**
   * @description Regenera el cálculo de saldos finger diarios para funcionarios activos
   * @details Proceso diario que recalcula saldos de fichaje para el día actual o el día anterior.
   *          Registra la ejecución en tabla de control y aplica cálculo diferenciado por tipo funcionario.
   *          - Tipo 21 (Policía): Utiliza cálculo especializado finger_calcula_saldo_policia
   *          - Otros tipos: Utiliza cálculo general finger_calcula_saldo
   *          - Excepción: Funcionario 962342 siempre usa cálculo general
   * @param v_id_funcionario ID funcionario específico o 0 para todos los activos
   * @param v_tipo_funci Tipo de funcionario filtro (10=Administrativo, 21=Policía, 23=Bombero) o 0 para todos
   * @param i_ayer Flag temporal: 0=hoy, 1=ayer
   * @notes 
   *   - Usa tabla fichaje_ejecucion_error para registrar y controlar ejecuciones
   *   - Solo procesa funcionarios en activo (sin fecha_baja o con fecha_baja futura)
   *   - Excepción hardcoded para funcionario 962342 (requiere cálculo estándar)
   */

  -- Constantes
  C_TIPO_FUNC_POLICIA CONSTANT NUMBER := 21;
  C_FUNC_EXCEPCION    CONSTANT VARCHAR2(10) := '962342';
  C_NOMBRE_PROC       CONSTANT VARCHAR2(30) := 'REGENERA_SALDO_DIARIO';

  -- Variables
  i_id_dia            DATE;
  i_id_funcionario    VARCHAR2(10);
  i_tipo_funcionario2 NUMBER;

  -- Cursor: Funcionarios en activo según filtros
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
    ORDER BY id_funcionario DESC;

BEGIN

  -- **********************************
  -- FASE 1: Determinar fecha de cálculo
  -- **********************************
  IF i_ayer = 0 THEN
    i_id_dia := TRUNC(SYSDATE);  -- Hoy
  ELSE
    i_id_dia := TRUNC(SYSDATE) - 1;  -- Ayer
  END IF;

  -- **********************************
  -- FASE 2: Iterar funcionarios activos
  -- **********************************
  OPEN c0;
  LOOP
    FETCH c0 INTO i_id_funcionario, i_tipo_funcionario2;
    EXIT WHEN c0%NOTFOUND;

    -- **********************************
    -- FASE 3: Registrar inicio ejecución
    -- **********************************
    INSERT INTO fichaje_ejecucion_error
      (fecha_ejecucion, id_funcionario, procedimiento)
    VALUES
      (SYSDATE, i_id_funcionario, C_NOMBRE_PROC);

    -- **********************************
    -- FASE 4: Calcular saldo según tipo funcionario
    -- **********************************
    IF i_tipo_funcionario2 <> C_TIPO_FUNC_POLICIA OR i_id_funcionario = C_FUNC_EXCEPCION THEN
      -- Cálculo estándar para no-policías o funcionario excepción 962342
      finger_calcula_saldo(i_id_funcionario, i_id_dia);
    ELSE
      -- Cálculo especializado para policías
      finger_calcula_saldo_policia(i_id_funcionario, i_id_dia);
    END IF;

    -- **********************************
    -- FASE 5: Limpiar registro de ejecución (finalizado correctamente)
    -- **********************************
    DELETE FROM fichaje_ejecucion_error 
    WHERE id_funcionario = i_id_funcionario 
      AND procedimiento = C_NOMBRE_PROC;

  END LOOP;
  
  CLOSE c0;

  -- **********************************
  -- FASE 6: Confirmar transacción
  -- **********************************
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    IF c0%ISOPEN THEN
      CLOSE c0;
    END IF;
    ROLLBACK;
    RAISE;

END FINGER_REGENERA_SALDO_DIARIO;
/

