CREATE OR REPLACE PROCEDURE RRHH.FINGER_REGENERA_SALDO_UN_DIA (
  v_id_funcionario IN VARCHAR2,
  v_tipo_funci     IN NUMBER,
  v_ayer           IN VARCHAR2
) IS
  /**
   * @description Regenera el cálculo de saldos finger para una fecha específica
   * @details Proceso que recalcula saldos de fichaje para un día determinado (pasado como parámetro).
   *          Procesa funcionarios activos con contrato vigente o sin fecha de baja.
   *          - Tipo 21 (Policía): Utiliza cálculo especializado finger_calcula_saldo_policia
   *          - Otros tipos: Utiliza cálculo general finger_calcula_saldo
   *          - Excepción: Funcionario 962342 siempre usa cálculo general
   *          - Incluye hardcode de funcionarios 101207 y 10013 (tipo 10=Administrativo)
   * @param v_id_funcionario ID funcionario específico o 0 para todos los activos
   * @param v_tipo_funci Tipo de funcionario filtro (10=Administrativo, 21=Policía, 23=Bombero) o 0 para todos
   * @param v_ayer Fecha a recalcular formato 'DD/MM/YYYY'
   * @notes 
   *   - Usa tabla fichaje_ejecucion_error para registrar y controlar ejecuciones
   *   - Solo procesa funcionarios con contrato vigente (fecha_fin_contrato futura o null)
   *   - UNION hardcoded: agrega funcionarios 101207 y 10013 si coinciden con filtros
   *   - Funcionarios hardcoded siempre tipo 10 (Administrativo)
   */

  -- Constantes
  C_TIPO_FUNC_POLICIA    CONSTANT NUMBER := 21;
  C_TIPO_FUNC_ADMIN      CONSTANT NUMBER := 10;
  C_FUNC_EXCEPCION       CONSTANT VARCHAR2(10) := '962342';
  C_FUNC_HARDCODE_1      CONSTANT VARCHAR2(10) := '101207';
  C_FUNC_HARDCODE_2      CONSTANT VARCHAR2(10) := '10013';
  C_NOMBRE_PROC          CONSTANT VARCHAR2(30) := 'REGENERA_SALDO_DIARIO';
  C_FECHA_MAXIMA         CONSTANT DATE := TO_DATE('01/01/2050', 'DD/MM/YYYY');

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
    WHERE (fecha_fin_contrato IS NULL OR
           (fecha_fin_contrato > SYSDATE AND
            NVL(fecha_baja, SYSDATE) < C_FECHA_MAXIMA))
      AND (id_funcionario = v_id_funcionario OR 0 = v_id_funcionario)
      AND (tipo_funcionario2 = v_tipo_funci OR 0 = v_tipo_funci)
    UNION
    -- Funcionario hardcoded 101207
    SELECT C_FUNC_HARDCODE_1, C_TIPO_FUNC_ADMIN
    FROM DUAL
    WHERE TO_NUMBER(C_FUNC_HARDCODE_1) = v_id_funcionario 
       OR 0 = v_tipo_funci
    UNION
    -- Funcionario hardcoded 10013
    SELECT C_FUNC_HARDCODE_2, C_TIPO_FUNC_ADMIN
    FROM DUAL
    WHERE TO_NUMBER(C_FUNC_HARDCODE_2) = v_id_funcionario 
       OR 0 = v_tipo_funci
    ORDER BY 1 DESC;

BEGIN

  -- **********************************
  -- FASE 1: Convertir fecha parámetro
  -- **********************************
  i_id_dia := TO_DATE(v_ayer, 'DD/MM/YYYY');

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

END FINGER_REGENERA_SALDO_UN_DIA;
/

