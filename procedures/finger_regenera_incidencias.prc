/**
 * FINGER_REGENERA_INCIDENCIAS
 *
 * @description
 * Regenera el cálculo de saldos finger para funcionarios afectados por una incidencia
 * de fichaje específica o para todos los funcionarios de una fecha.
 *
 * @details
 * Operaciones realizadas:
 * - Obtener incidencia y fecha afectada
 * - Buscar funcionarios con incidencias en esa fecha
 * - Recalcular saldo finger según tipo funcionario:
 *   * Tipo 21 (Policía): usa finger_calcula_saldo_policia
 *   * Otros tipos: usa finger_calcula_saldo
 *
 * Modos de ejecución:
 * - i_todos=0: Solo regenera para el funcionario de la incidencia
 * - i_todos=1: Regenera para TODOS los funcionarios con incidencias en esa fecha
 *
 * Tipos de funcionario:
 * - 10: Administrativo
 * - 21: Policía Local (cálculo especial)
 * - 23: Bombero
 *
 * @param i_id_incidencia IN ID de la incidencia fichaje a regenerar
 * @param i_todos         IN 0=Solo incidencia, 1=Todos funcionarios fecha
 *
 * @notes
 * - Policía (tipo 21): usa lógica especial de turnos
 * - Regeneración afecta saldos de horas trabajadas
 * - Procesa por fecha de incidencia
 *
 * @see finger_calcula_saldo         Cálculo saldo general
 * @see finger_calcula_saldo_policia Cálculo saldo policía
 *
 * @author Sistema Finger RRHH
 * @version 2.0
 */
CREATE OR REPLACE PROCEDURE RRHH.FINGER_REGENERA_INCIDENCIAS (
  i_id_incidencia IN VARCHAR2,
  i_todos         IN VARCHAR2
) IS

  -- Constantes
  C_TIPO_FUNC_POLICIA CONSTANT NUMBER := 21;
  
  -- Variables
  i_id_inc           NUMBER;
  v_fecha_incidencia DATE;
  v_fecha_inc        DATE;
  i_id_funcionario   NUMBER;
  v_id_funcionario   NUMBER;
  i_tipo_funcionario NUMBER;
  
  -- Cursor funcionarios con incidencias en fecha
  CURSOR c1 (
    p_id_funcionario   VARCHAR2,
    p_fecha_incidencia DATE
  ) IS
    SELECT DISTINCT f.fecha_incidencia,
                    f.id_funcionario,
                    NVL(p.tipo_funcionario2, 0) AS tipo_func
    FROM   fichaje_incidencia f,
           personal_new p
    WHERE  f.fecha_incidencia = p_fecha_incidencia
      AND  p.id_funcionario = f.id_funcionario
      AND  (f.id_funcionario = p_id_funcionario OR 0 = p_id_funcionario)
    ORDER BY 1 DESC;

BEGIN

  --------------------------------------------------------------------------------
  -- FASE 1: VALIDAR Y OBTENER INCIDENCIA
  --------------------------------------------------------------------------------
  
  i_id_inc := 1;
  
  BEGIN
    SELECT fecha_incidencia,
           id_funcionario
    INTO   v_fecha_incidencia,
           i_id_funcionario
    FROM   fichaje_incidencia
    WHERE  id_incidencia = i_id_incidencia
      AND  ROWNUM < 2;
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_id_inc := 0;
  END;
  
  --------------------------------------------------------------------------------
  -- FASE 2: DETERMINAR ALCANCE (INDIVIDUAL O TODOS)
  --------------------------------------------------------------------------------
  
  IF i_todos = 1 THEN
    i_id_funcionario := 0; -- 0 = todos los funcionarios
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 3: RECALCULAR SALDOS PARA FUNCIONARIOS AFECTADOS
  --------------------------------------------------------------------------------
  
  OPEN c1(i_id_funcionario, v_fecha_incidencia);
  
  LOOP
    FETCH c1 INTO v_fecha_inc, v_id_funcionario, i_tipo_funcionario;
    EXIT WHEN c1%NOTFOUND;
    
    -- Recalcular según tipo funcionario
    IF i_tipo_funcionario <> C_TIPO_FUNC_POLICIA THEN
      finger_calcula_saldo(v_id_funcionario, v_fecha_incidencia);
    ELSE
      finger_calcula_saldo_policia(v_id_funcionario, v_fecha_incidencia);
    END IF;
    
  END LOOP;
  
  CLOSE c1;
  
EXCEPTION
  WHEN OTHERS THEN
    IF c1%ISOPEN THEN
      CLOSE c1;
    END IF;
    DBMS_OUTPUT.PUT_LINE('Error en finger_regenera_incidencias: ' || SQLERRM);
    RAISE;
    
END FINGER_REGENERA_INCIDENCIAS;
/

