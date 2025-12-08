CREATE OR REPLACE PROCEDURE RRHH.FINGER_LEE_TRANS (
  i_pin     IN VARCHAR2,
  v_fecha_p IN DATE
) IS
  /**
   * @description Lee y procesa transacciones de fichaje desde relojes para fecha y PIN específicos
   * @details Procedimiento que importa transacciones desde tabla transacciones (relojes físicos) a fichaje_funcionario_tran.
   *          Proceso:
   *          1. Limpia transacciones previas no computadas del día
   *          2. Lee transacciones del reloj para PIN y fecha
   *          3. Identifica funcionario por PIN (pin o pin2)
   *          4. Obtiene jornada laboral del funcionario
   *          5. Calcula periodo de fichaje (policía usa turno_policia, otros devuelve_periodo_fichaje)
   *          6. Inserta en fichaje_funcionario_tran para posterior procesamiento
   *          
   *          Tipos transacción válidos: 2, 55, 39, 40, 4355, 4865, 4098, 4102, 4356, numserie=0, dedo=17/49 con tipo 3
   * @param i_pin PIN del funcionario (4 dígitos)
   * @param v_fecha_p Fecha de las transacciones a procesar
   * @notes 
   *   - Limpia transacciones con computadas=0 antes de procesar
   *   - Reloj 'MA' se convierte a '91'
   *   - Funcionarios hardcoded: PIN 0707→101207, PIN 0305→10013
   *   - Tipo 21 (Policía): usa turno_policia para determinar periodo
   *   - Otros tipos: usa devuelve_periodo_fichaje
   *   - Solo funcionarios activos (sin fecha_baja o baja futura)
   *   - Secuencia: sec_id_fichaje_trans.nextval
   *   - DUP_VAL_ON_INDEX: transacción duplicada, se ignora
   */

  -- Constantes
  C_TIPO_FUNC_POLICIA    CONSTANT NUMBER := 21;
  C_TIPO_TRANS_2         CONSTANT NUMBER := 2;
  C_TIPO_TRANS_55        CONSTANT NUMBER := 55;
  C_TIPO_TRANS_39        CONSTANT NUMBER := 39;
  C_TIPO_TRANS_40        CONSTANT NUMBER := 40;
  C_TIPO_TRANS_4355      CONSTANT NUMBER := 4355;
  C_TIPO_TRANS_4865      CONSTANT NUMBER := 4865;
  C_TIPO_TRANS_4098      CONSTANT NUMBER := 4098;
  C_TIPO_TRANS_4102      CONSTANT NUMBER := 4102;
  C_TIPO_TRANS_4356      CONSTANT NUMBER := 4356;
  C_DEDO_17              CONSTANT VARCHAR2(2) := '17';
  C_DEDO_49              CONSTANT VARCHAR2(2) := '49';
  C_TIPO_TRANS_3         CONSTANT VARCHAR2(1) := '3';
  C_RELOJ_MA             CONSTANT VARCHAR2(2) := 'MA';
  C_RELOJ_91             CONSTANT VARCHAR2(2) := '91';
  C_PIN_HARDCODE_1       CONSTANT VARCHAR2(4) := '0707';
  C_PIN_HARDCODE_2       CONSTANT VARCHAR2(4) := '0305';
  C_FUNC_HARDCODE_1      CONSTANT NUMBER := 101207;
  C_FUNC_HARDCODE_2      CONSTANT NUMBER := 10013;
  C_COMPUTADAS_NO        CONSTANT NUMBER := 0;
  C_PREFIJO_POLICIA      CONSTANT VARCHAR2(1) := 'P';

  -- Variables funcionario
  i_id_funcionario    NUMBER;
  i_tipo_funcionario2 NUMBER;

  -- Variables transacción
  v_pin               VARCHAR2(4);
  d_fecha_fichaje     DATE;
  i_reloj             NUMBER;
  i_ausencia          NUMBER;
  i_numserie          NUMBER;
  i_claveomesa        NUMBER;
  d_audit_fecha       DATE;
  v_audit_usuario     NUMBER;
  i_tipotrans         NUMBER;
  i_horas_f           NUMBER;
  i_periodo           VARCHAR2(4);
  i_id_secuencia      NUMBER;

  -- Variables jornada
  i_p1d               NUMBER;
  i_p1h               NUMBER;
  i_p2d               NUMBER;
  i_p2h               NUMBER;
  i_p3d               NUMBER;
  i_p3h               NUMBER;
  i_po1d              NUMBER;
  i_po1h              NUMBER;
  i_po2d              NUMBER;
  i_po2h              NUMBER;
  i_po3d              NUMBER;
  i_po3h              NUMBER;
  i_contar_comida     NUMBER;
  i_libre             NUMBER;
  i_turnos            NUMBER;
  i_sin_calendario    NUMBER;

  -- Cursor: Transacciones del PIN en fecha
  CURSOR c1 (p_fecha_p DATE, p_pin VARCHAR2) IS
    SELECT 
           LPAD(pin, 4, '0') AS pin,
           TO_DATE(TO_CHAR(fecha, 'DD/MM/YYYY') || ' ' || TO_CHAR(hora, 'HH24:MI'), 'DD/MM/YYYY HH24:MI') AS fecha_fichaje,
           DECODE(numero, C_RELOJ_MA, C_RELOJ_91, numero) AS reloj,
           DECODE(codinci, NULL, 0, 1) AS ausencia,
           claveomesa AS numserie,
           TO_DATE(TO_CHAR(fechacap, 'DD/MM/YYYY') || ' ' || TO_CHAR(horacap, 'HH24:MI'), 'DD/MM/YYYY HH24:MI') AS audit_fecha,
           '000000' AS audit_usuario,
           tipotrans AS tipotrans,
           TO_CHAR(hora, 'HH24MI') AS horas_f
    FROM transacciones
    WHERE pin <> '0000' 
      AND pin > 0
      AND (
           (tipotrans = C_TIPO_TRANS_2) OR 
           (numserie = 0) OR
           (dedo = C_DEDO_17 AND tipotrans = C_TIPO_TRANS_3) OR
           (dedo = C_DEDO_49 AND tipotrans = C_TIPO_TRANS_3) OR
           (tipotrans IN (C_TIPO_TRANS_55, C_TIPO_TRANS_39, C_TIPO_TRANS_40, 
                          C_TIPO_TRANS_4355, C_TIPO_TRANS_4865, C_TIPO_TRANS_4098, C_TIPO_TRANS_4102)) OR
           (tipotrans = C_TIPO_TRANS_4356 AND pin IN (
             '1562','1655','0940','1636','1322','1511','1631','1634','1510','1450',
             '1491','1302','0736','1517','1569','1518','1515','0628','1259','0702',
             '0651','1226','1213','1312','0400','0260','0271','0619','0811','0972',
             '0990','1017','1134','1189','1230','5240','5908'))
          )
      AND LPAD(pin, 4, '0') = LPAD(p_pin, 4, '0')
      AND LENGTH(pin) <= 4
      AND fecha = p_fecha_p
    ORDER BY claveomesa ASC;

BEGIN

  -- **********************************
  -- FASE 1: Limpiar transacciones previas no computadas
  -- **********************************
  DELETE FROM fichaje_funcionario_tran
  WHERE pin = i_pin
    AND TRUNC(fecha_fichaje) = v_fecha_p
    AND computadas = C_COMPUTADAS_NO;

  -- **********************************
  -- FASE 2: Iterar transacciones del reloj
  -- **********************************
  OPEN c1(v_fecha_p, i_pin);
  LOOP
    FETCH c1 INTO v_pin, d_fecha_fichaje, i_reloj, i_ausencia,
                  i_numserie, d_audit_fecha, v_audit_usuario, i_tipotrans, i_horas_f;
    EXIT WHEN c1%NOTFOUND;

    i_id_funcionario := 0;

    -- **********************************
    -- FASE 3: Identificar funcionario por PIN
    -- **********************************
    BEGIN
      SELECT DISTINCT 
             p.id_funcionario,
             tipo_funcionario2
      INTO i_id_funcionario, i_tipo_funcionario2
      FROM personal_new p
      INNER JOIN funcionario_fichaje u ON LPAD(p.id_funcionario, 6, 0) = LPAD(u.id_funcionario, 6, 0)
      WHERE (LPAD(u.pin, 4, '0') = LPAD(v_pin, 4, '0') OR 
             LPAD(u.pin2, 4, '0') = LPAD(v_pin, 4, '0'))
        AND ((p.fecha_baja IS NULL AND p.fecha_fin_contrato IS NOT NULL) OR 
             (p.fecha_baja > SYSDATE) OR
             (p.fecha_baja IS NULL AND p.fecha_fin_contrato IS NULL))
        AND ROWNUM < 2;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_id_funcionario := 0;
    END;

    -- Funcionarios hardcoded
    IF i_pin = C_PIN_HARDCODE_1 THEN
      i_id_funcionario := C_FUNC_HARDCODE_1;
    END IF;
    IF i_pin = C_PIN_HARDCODE_2 THEN
      i_id_funcionario := C_FUNC_HARDCODE_2;
    END IF;

    -- **********************************
    -- FASE 4: Procesar si funcionario válido
    -- **********************************
    IF i_id_funcionario <> 0 THEN

      i_sin_calendario := 1;

      -- Obtener configuración jornada
      finger_busca_jornada_fun(
        i_id_funcionario, d_fecha_fichaje,
        i_p1d, i_p1h, i_p2d, i_p2h, i_p3d, i_p3h,
        i_po1d, i_po1h, i_po2d, i_po2h, i_po3d, i_po3h,
        i_contar_comida, i_libre, i_turnos, i_sin_calendario
      );

      -- **********************************
      -- FASE 5: Determinar periodo de fichaje
      -- **********************************
      IF i_sin_calendario <> 0 THEN

        IF i_tipo_funcionario2 <> C_TIPO_FUNC_POLICIA THEN
          -- No policía: calcular periodo estándar
          i_periodo := devuelve_periodo_fichaje(i_id_funcionario, v_pin, d_fecha_fichaje, i_horas_f);
        ELSE
          -- Policía: obtener turno
          i_periodo := C_PREFIJO_POLICIA || turno_policia(i_numserie, v_pin);
        END IF;

      END IF;

      -- **********************************
      -- FASE 6: Insertar transacción procesada
      -- **********************************
      i_id_secuencia := sec_id_fichaje_trans.NEXTVAL;
      
      BEGIN
        INSERT INTO fichaje_funcionario_tran (
          id_sec, id_funcionario, pin, fecha_fichaje, ausencia,
          numserie, reloj, audit_usuario, audit_fecha, tipotrans, periodo
        ) VALUES (
          i_id_secuencia, i_id_funcionario, v_pin, d_fecha_fichaje, i_ausencia,
          i_numserie, i_reloj, v_audit_usuario, d_audit_fecha, i_tipotrans, i_periodo
        );
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          NULL; -- Transacción duplicada, ignorar
      END;

    END IF; -- Fin IF funcionario válido

    COMMIT;

  END LOOP;
  CLOSE c1;

  -- **********************************
  -- FASE 7: Confirmar transacción final
  -- **********************************
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    IF c1%ISOPEN THEN
      CLOSE c1;
    END IF;
    ROLLBACK;
    RAISE;

END FINGER_LEE_TRANS;
/

