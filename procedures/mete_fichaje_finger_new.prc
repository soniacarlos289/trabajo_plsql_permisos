CREATE OR REPLACE PROCEDURE RRHH.METE_FICHAJE_FINGER_NEW (
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
   * @description Inserta fichajes virtuales (finger) para permisos y ausencias
   * @details Procedimiento que crea transacciones de fichaje simuladas en tabla transacciones
   *          para permisos tipo 15000 (compensatorios) y ausencias.
   *          Proceso:
   *          1. Determina número de reloj según tipo permiso (90=permiso 15000, 92=ausencia)
   *          2. Busca PIN del funcionario en tabla persona
   *          3. Verifica que no existan fichajes duplicados (misma hora/fecha/PIN)
   *          4. Inserta dos transacciones: entrada (hora_inicio) y salida (hora_fin)
   *          5. Recalcula saldo del día mediante finger_calcula_saldo
   * @param V_ID_ANO Año del permiso/ausencia (no utilizado actualmente)
   * @param V_ID_FUNCIONARIO ID del funcionario
   * @param V_FECHA_INICIO Fecha del fichaje virtual
   * @param V_HORA_INICIO Hora de entrada formato 'HH:MI' o 'HHMM'
   * @param V_HORA_FIN Hora de salida formato 'HH:MI' o 'HHMM'
   * @param v_codpers Código de persona (5 dígitos, se busca PIN asociado)
   * @param v_total_horas Total de horas del permiso/ausencia (no utilizado)
   * @param V_ID_TIPO_PERMISO Tipo de permiso ('15000'=compensatorio, otros=ausencia)
   * @param todo_ok_Basico OUT 0=éxito, 1=error
   * @param msgBasico OUT Mensaje resultado operación
   * @notes 
   *   - Reloj 90: permisos tipo 15000 (compensatorios)
   *   - Reloj 92: ausencias y otros permisos
   *   - Solo inserta si no existe fichaje duplicado (misma hora/fecha/PIN)
   *   - Transacciones insertadas con numserie=0, tipotrans=0, tipofic=1
   *   - Usa secuencia TRANSACCIONESCLAVEOMESA.nextval para claveomesa
   *   - Recalcula saldo automáticamente tras inserción
   */

  -- Constantes
  C_TIPO_PERMISO_15000  CONSTANT VARCHAR2(5) := '15000';
  C_RELOJ_PERMISO       CONSTANT VARCHAR2(2) := '90';
  C_RELOJ_AUSENCIA      CONSTANT VARCHAR2(2) := '92';
  C_NUMSERIE_VIRTUAL    CONSTANT VARCHAR2(1) := '0';
  C_TIPOTRANS_VIRTUAL   CONSTANT NUMBER := 0;
  C_DEDO_VIRTUAL        CONSTANT NUMBER := 0;
  C_TIPTER_OMESA        CONSTANT VARCHAR2(1) := 'O';
  C_TIPOFIC_ENTRADA     CONSTANT NUMBER := 1;
  C_CENTRO_DEFAULT      CONSTANT VARCHAR2(10) := '0000000000';
  C_SUPREMA_DEFAULT     CONSTANT NUMBER := 0;
  C_FECHA_REF_HORA      CONSTANT DATE := TO_DATE('30/12/1899', 'DD/MM/YYYY');
  C_FECHA_REF_HORA2     CONSTANT VARCHAR2(8) := '30/12/99';
  C_TODO_OK             CONSTANT INTEGER := 0;
  C_ERROR               CONSTANT INTEGER := 1;
  C_CODINCI_VACIO       CONSTANT VARCHAR2(1) := '';
  C_LONGITUD_CODIGO     CONSTANT NUMBER := 5;

  -- Variables
  i_pin               VARCHAR2(4);
  i_existe            NUMBER;
  I_NUMERO_FINGER     VARCHAR2(2);
  V_DIAS_p            DATE;

  -- Cursor: Días del calendario laboral en rango (actualmente solo usa fecha única)
  CURSOR DIAS(v_fecha_inicio DATE, v_fecha_fin DATE) IS
    SELECT ID_DIA
    FROM CALENDARIO_LABORAL
    WHERE ID_DIA BETWEEN v_fecha_inicio AND v_fecha_fin;

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
  -- FASE 3: Insertar fichaje de entrada (si no existe)
  -- **********************************
  i_existe := 0;
  SELECT COUNT(*)
  INTO i_existe
  FROM transacciones
  WHERE hora  = TO_DATE(C_FECHA_REF_HORA2 || ' ' || LPAD(v_hora_inicio, 5, '0') || ':00', 'DD/MM/YY HH24:MI:SS')
    AND fecha = TO_DATE(V_FECHA_INICIO, 'DD/MM/YY')
    AND pin   = i_pin;

  IF i_existe = 0 THEN
    INSERT INTO transacciones (
      numserie, fecha, hora, pin, dedo, tipotrans, codinci, tipter,
      numero, fechacap, horacap, tipofic, claveomesa, centro, SUPREMA
    ) VALUES (
      C_NUMSERIE_VIRTUAL,
      TO_DATE(V_FECHA_INICIO, 'DD/MM/YY'),
      TO_DATE(C_FECHA_REF_HORA2 || ' ' || LPAD(v_hora_inicio, 5, '0') || ':00', 'DD/MM/YY HH24:MI:SS'),
      i_pin,
      C_DEDO_VIRTUAL,
      C_TIPOTRANS_VIRTUAL,
      C_CODINCI_VACIO,
      C_TIPTER_OMESA,
      I_NUMERO_FINGER,
      TRUNC(SYSDATE),
      C_FECHA_REF_HORA + (SYSDATE - TRUNC(SYSDATE)),
      C_TIPOFIC_ENTRADA,
      TRANSACCIONESCLAVEOMESA.NEXTVAL,
      C_CENTRO_DEFAULT,
      C_SUPREMA_DEFAULT
    );
  END IF;



  -- **********************************
  -- FASE 4: Insertar fichaje de salida (si no existe)
  -- **********************************
  i_existe := 0;
  SELECT COUNT(*)
  INTO i_existe
  FROM transacciones
  WHERE hora  = TO_DATE(C_FECHA_REF_HORA2 || ' ' || LPAD(v_hora_fin, 5, '0') || ':00', 'DD/MM/YY HH24:MI:SS')
    AND fecha = TO_DATE(V_FECHA_INICIO, 'DD/MM/YY')
    AND pin   = i_pin;

  IF i_existe = 0 THEN
    INSERT INTO transacciones (
      numserie, fecha, hora, pin, dedo, tipotrans, codinci, tipter,
      numero, fechacap, horacap, tipofic, claveomesa, centro, SUPREMA
    ) VALUES (
      C_NUMSERIE_VIRTUAL,
      TO_DATE(V_FECHA_INICIO, 'DD/MM/YY'),
      TO_DATE(C_FECHA_REF_HORA2 || ' ' || LPAD(v_hora_fin, 5, '0') || ':00', 'DD/MM/YY HH24:MI:SS'),
      i_pin,
      C_DEDO_VIRTUAL,
      C_TIPOTRANS_VIRTUAL,
      C_CODINCI_VACIO,
      C_TIPTER_OMESA,
      I_NUMERO_FINGER,
      TRUNC(SYSDATE),
      C_FECHA_REF_HORA + (SYSDATE - TRUNC(SYSDATE)),
      C_TIPOFIC_ENTRADA,
      TRANSACCIONESCLAVEOMESA.NEXTVAL,
      C_CENTRO_DEFAULT,
      C_SUPREMA_DEFAULT
    );
  END IF;

  -- **********************************
  -- FASE 5: Recalcular saldo del día
  -- **********************************
  OPEN DIAS(V_FECHA_INICIO, V_FECHA_INICIO);
  LOOP
    FETCH DIAS INTO V_DIAS_p;
    EXIT WHEN DIAS%NOTFOUND;

    finger_calcula_saldo(V_ID_FUNCIONARIO, V_DIAS_p);
  END LOOP;
  CLOSE DIAS;

  -- **********************************
  -- FASE 6: Confirmar transacción
  -- **********************************
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    IF DIAS%ISOPEN THEN
      CLOSE DIAS;
    END IF;
    ROLLBACK;
    todo_ok_basico := C_ERROR;
    msgBasico      := 'Error: ' || SQLERRM;
    RAISE;

END METE_FICHAJE_FINGER_NEW;
/

