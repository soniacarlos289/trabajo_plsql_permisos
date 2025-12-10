CREATE OR REPLACE PROCEDURE RRHH.ANULA_FICHAJE_FINGER_15000 (
  V_ID_ANO           IN  NUMBER,
  V_ID_FUNCIONARIO   IN  NUMBER,
  V_FECHA_INICIO     IN  DATE,
  V_HORA_INICIO      IN  VARCHAR2,
  V_HORA_FIN         IN  VARCHAR2,
  v_codpers          IN  VARCHAR2,
  v_total_horas      IN  VARCHAR2,
  V_ID_TIPO_PERMISO  IN  VARCHAR2,
  todo_ok_Basico     OUT INTEGER,
  msgBasico          OUT VARCHAR2
) IS
  /**
   * @description Elimina fichajes virtuales (finger) de permisos y ausencias cancelados
   * @details Procedimiento que elimina transacciones de fichaje simuladas cuando se anula un permiso/ausencia.
   *          Proceso:
   *          1. Determina número de reloj según tipo permiso (90=permiso 15000, 92=ausencia)
   *          2. Busca PIN del funcionario en tabla persona
   *          3. Elimina fichaje de entrada (hora_inicio) si existe
   *          4. Elimina fichaje de salida (hora_fin) si existe
   *          5. Confirma cambios con COMMIT
   * @param V_ID_ANO Año del permiso/ausencia (no utilizado actualmente)
   * @param V_ID_FUNCIONARIO ID del funcionario
   * @param V_FECHA_INICIO Fecha del fichaje a anular
   * @param V_HORA_INICIO Hora de entrada a eliminar formato 'HH:MI' o 'HHMM'
   * @param V_HORA_FIN Hora de salida a eliminar formato 'HH:MI' o 'HHMM'
   * @param v_codpers Código de persona (5 dígitos, se busca PIN asociado)
   * @param v_total_horas Total de horas del permiso/ausencia (no utilizado)
   * @param V_ID_TIPO_PERMISO Tipo de permiso ('15000'=compensatorio, otros=ausencia)
   * @param todo_ok_Basico OUT 0=éxito, 1=error
   * @param msgBasico OUT Mensaje resultado operación
   * @notes 
   *   - Reloj 90: permisos tipo 15000 (compensatorios)
   *   - Reloj 92: ausencias y otros permisos
   *   - Limita eliminación a 1 registro por operación (ROWNUM < 2)
   *   - No recalcula saldo automáticamente (debe hacerse externamente)
   */

  -- Constantes
  C_TIPO_PERMISO_15000  CONSTANT VARCHAR2(5) := '15000';
  C_RELOJ_PERMISO       CONSTANT VARCHAR2(2) := '90';
  C_RELOJ_AUSENCIA      CONSTANT VARCHAR2(2) := '92';
  C_FECHA_REF_HORA      CONSTANT VARCHAR2(8) := '30/12/99';
  C_TODO_OK             CONSTANT INTEGER := 0;
  C_ERROR               CONSTANT INTEGER := 1;
  C_LONGITUD_CODIGO     CONSTANT NUMBER := 5;

  -- Variables
  i_pin               VARCHAR2(4);
  I_NUMERO_FINGER     VARCHAR2(2);

BEGIN

  -- **********************************
  -- FASE 1: Determinar número de reloj según tipo de permiso
  -- **********************************
  IF V_ID_TIPO_PERMISO = C_TIPO_PERMISO_15000 THEN
    I_NUMERO_FINGER := C_RELOJ_PERMISO;  -- Permiso 15000 → reloj 90
  ELSE
    I_NUMERO_FINGER := C_RELOJ_AUSENCIA; -- Ausencias y otros → reloj 92
  END IF;

  -- Inicializar salidas
  todo_ok_basico := C_TODO_OK;
  msgBasico      := '';

  -- **********************************
  -- FASE 2: Buscar PIN del funcionario
  -- **********************************
  BEGIN
    SELECT numtarjeta
    INTO i_pin
    FROM persona
    WHERE codigo = LPAD(v_codpers, C_LONGITUD_CODIGO, '0');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_pin := '';
  END;
  -- **********************************
  -- FASE 3: Eliminar fichaje de entrada
  -- **********************************
  DELETE FROM transacciones
  WHERE fecha  = TO_DATE(V_FECHA_INICIO, 'DD/MM/YY')
    AND TO_CHAR(hora, 'HH24:MI') = LPAD(v_hora_inicio, 5, '0')
    AND pin    = i_pin
    AND numero = I_NUMERO_FINGER
    AND ROWNUM < 2;

  -- **********************************
  -- FASE 4: Eliminar fichaje de salida
  -- **********************************
  DELETE FROM transacciones
  WHERE fecha  = TO_DATE(V_FECHA_INICIO, 'DD/MM/YY')
    AND TO_CHAR(hora, 'HH24:MI') = LPAD(v_hora_fin, 5, '0')
    AND pin    = i_pin
    AND numero = I_NUMERO_FINGER
    AND ROWNUM < 2;

  -- **********************************
  -- FASE 5: Confirmar transacción
  -- **********************************
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    todo_ok_basico := C_ERROR;
    msgBasico      := 'Error: ' || SQLERRM;
    RAISE;

END ANULA_FICHAJE_FINGER_15000;
/

