CREATE OR REPLACE PROCEDURE RRHH.FINGER_LIMPIA_TRANS0 (
  i_funcionario IN VARCHAR2,
  v_fecha_p     IN DATE
) IS
  /**
   * @description Variante de limpieza y validación de transacciones de fichaje (versión 0)
   * @details Proceso similar a FINGER_LIMPIA_TRANS con filtro diferente de funcionarios activos.
   *          Esta versión verifica únicamente fecha_baja (sin validar fecha_fin_contrato).
   *          Lógica de validación:
   *          1. Itera funcionarios activos (sin fecha_baja o con fecha_baja futura)
   *          2. Para cada fichaje del día (computadas=0):
   *             - Consulta jornada laboral del funcionario
   *             - Busca ausencias justificadas (id_estado=80) con margen de 30 min
   *             - Busca permisos 15000 (compensatorios) con margen de 15 min
   *             - Descarta fichajes dentro de estos rangos horarios
   *             - Descarta fichajes duplicados (diferencia < 5 minutos)
   *          3. Valida fichajes según periodo P2 (mañana/tarde)
   *          4. Genera alertas de fichaje en sede diferente (alerta_7)
   * @param i_funcionario ID del funcionario a procesar
   * @param v_fecha_p Fecha de las transacciones a validar
   * @notes 
   *   - Diferencia con FINGER_LIMPIA_TRANS: no incluye funcionarios hardcoded 101207/10013
   *   - Solo verifica fecha_baja (no fecha_fin_contrato)
   *   - Orden descendente en cursor de funcionarios
   *   - Resto de lógica idéntica a FINGER_LIMPIA_TRANS
   */

  -- Constantes
  C_FECHA_LIMITE         CONSTANT DATE := TO_DATE('01/01/2050', 'DD/MM/YYYY');
  C_COMPUTADAS_NO        CONSTANT NUMBER := 0;
  C_VALIDO_SI            CONSTANT NUMBER := 1;
  C_VALIDO_NO            CONSTANT NUMBER := 0;
  C_JUSTIFICADO_SI       CONSTANT VARCHAR2(2) := 'SI';
  C_ESTADO_APROBADO      CONSTANT NUMBER := 80;
  C_TIPO_PERMISO_15000   CONSTANT VARCHAR2(5) := '15000';
  C_MARGEN_AUSENCIA      CONSTANT NUMBER := 0.5; -- 30 minutos
  C_MARGEN_PERMISO       CONSTANT NUMBER := 15;  -- 15 minutos
  C_UMBRAL_MINUTOS_DUP   CONSTANT NUMBER := 4;   -- 5 minutos (>4)
  C_MINUTOS_DIA          CONSTANT NUMBER := 1440; -- 60*24
  C_RELOJ_MA             CONSTANT VARCHAR2(2) := 'MA';
  C_RELOJ_90             CONSTANT VARCHAR2(2) := '90';
  C_RELOJ_91             CONSTANT VARCHAR2(2) := '91';
  C_RELOJ_92             CONSTANT VARCHAR2(2) := '92';
  C_TIPO_INCIDENCIA_7    CONSTANT NUMBER := 7;
  C_ESTADO_INCIDENCIA    CONSTANT NUMBER := 0;
  C_AUDIT_USUARIO        CONSTANT NUMBER := 101217;
  C_OBS_SEDE_DIFERENTE   CONSTANT VARCHAR2(20) := 'Sede diferente';
  C_HORA_AUSENCIA_DEF    CONSTANT NUMBER := 800;
  C_HORA_FIN_AUSENCIA    CONSTANT NUMBER := 1430;
  C_HORA_INVALIDA        CONSTANT NUMBER := -1;
  C_HORA_FIN_INVALIDA    CONSTANT NUMBER := -11;
  C_VALIDOS_MIN          CONSTANT NUMBER := 2;

  -- Variables funcionario
  i_id_funcionario    NUMBER;
  i_tipo_funcionario2 NUMBER;
  i_id_func_ant       NUMBER;

  -- Variables transacción fichaje
  v_pin               VARCHAR2(4);
  i_reloj             VARCHAR2(4);
  i_ausencia          NUMBER;
  i_numserie          NUMBER;
  d_fecha_fichaje     DATE;
  i_tipotrans         NUMBER;
  i_horas_f           NUMBER;
  i_horas_f_anterior  NUMBER;
  i_periodo           VARCHAR2(4);
  I_ID_SEC            NUMBER;
  I_ID_SEC_ANTERIOR   NUMBER;

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
  I_SIN_CALENDARIO    NUMBER;

  -- Variables ausencias/permisos
  hinicio             NUMBER;
  hfin                NUMBER;
  hinicio_com         NUMBER;
  hfin_com            NUMBER;

  -- Variables control fichajes
  v_fecha_viejo       VARCHAR2(20);
  v_fecha_nuevo       VARCHAR2(20);
  d_fecha_viejo       DATE;
  d_fecha_nuevo       DATE;
  i_numero_fichaje    NUMBER;
  i_diferencia_saldo  NUMBER;
  i_valido_ant        NUMBER;
  i_validos           NUMBER;

  -- Variables control sede/reloj
  i_cuantos_reloj     NUMBER;
  i_alerta_7          NUMBER;

  -- Cursor: Funcionarios en activo (versión simplificada sin hardcoded)
  CURSOR C0 IS
    SELECT DISTINCT 
           id_funcionario,
           NVL(tipo_funcionario2, 0) AS tipo_func
    FROM personal_new
    WHERE (fecha_baja IS NULL OR 
           (fecha_baja > SYSDATE AND fecha_baja < C_FECHA_LIMITE))
      AND id_funcionario = i_funcionario 
      AND ROWNUM < 2
    ORDER BY 1 DESC;

  -- Cursor: Fichajes no computados del día
  CURSOR C2 (v_id_funcionario VARCHAR2) IS
    SELECT id_sec,
           pin,
           TO_DATE(TO_CHAR(fecha_fichaje, 'DD/MM/YYYY HH24:MI'), 'DD/MM/YYYY HH24:MI') AS fecha_fichaje,
           reloj,
           ausencia,
           numserie,
           tipotrans,
           periodo,
           TO_CHAR(fecha_fichaje, 'HH24MI') AS horas_f
    FROM fichaje_funcionario_tran
    WHERE id_funcionario = v_id_funcionario
      AND TRUNC(fecha_fichaje) = v_fecha_p
      AND computadas = C_COMPUTADAS_NO
    ORDER BY fecha_fichaje;

BEGIN

  -- **********************************
  -- FASE 1: Inicializar variables
  -- **********************************
  i_id_func_ant := 0;

  -- **********************************
  -- FASE 2: Iterar funcionarios activos
  -- **********************************
  OPEN C0;
  LOOP
    FETCH C0 INTO i_id_funcionario, i_tipo_funcionario2;
    EXIT WHEN C0%NOTFOUND;

    -- Inicializar variables para cada funcionario
    i_numero_fichaje   := 0;
    v_fecha_viejo      := NULL;
    v_fecha_nuevo      := NULL;
    d_fecha_viejo      := NULL;
    d_fecha_nuevo      := NULL;
    i_id_sec_anterior  := 0;
    i_validos          := 0;

    -- **********************************
    -- FASE 3: Iterar fichajes del día
    -- **********************************
    OPEN C2(i_id_funcionario);
    LOOP
      FETCH C2 INTO I_ID_SEC, V_PIN, d_fecha_fichaje, i_reloj, i_ausencia,
                    i_numserie, i_tipotrans, I_PERIODO, i_horas_f;
      EXIT WHEN C2%NOTFOUND;

      -- **********************************
      -- FASE 4: Obtener jornada laboral del funcionario
      -- **********************************
      finger_busca_jornada_fun(
        i_id_funcionario, d_fecha_fichaje,
        i_p1d, i_p1h, i_p2d, i_p2h, i_p3d, i_p3h,
        i_po1d, i_po1h, i_po2d, i_po2h, i_po3d, i_po3h,
        i_contar_comida, i_libre, i_turnos, i_sin_calendario
      );

      i_numero_fichaje := i_numero_fichaje + 1;

      -- **********************************
      -- FASE 5: Buscar ausencias justificadas del día (margen ±30 min)
      -- **********************************
      hinicio := C_HORA_INVALIDA;
      hfin    := C_HORA_FIN_INVALIDA;
      
      BEGIN
        SELECT TO_NUMBER(TO_CHAR(fecha_inicio - ((C_MARGEN_AUSENCIA) / 24), 'HH24MI')),
               TO_NUMBER(TO_CHAR(fecha_fin + ((C_MARGEN_AUSENCIA) / 24), 'HH24MI'))
        INTO hinicio, hfin
        FROM ausencia
        WHERE TRUNC(fecha_inicio) = TRUNC(d_fecha_fichaje)
          AND JUSTIFICADO = C_JUSTIFICADO_SI
          AND id_estado = C_ESTADO_APROBADO
          AND id_funcionario = i_id_funcionario;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          hinicio := C_HORA_INVALIDA;
          hfin    := C_HORA_FIN_INVALIDA;
        WHEN TOO_MANY_ROWS THEN
          hinicio := C_HORA_AUSENCIA_DEF;
          hfin    := C_HORA_FIN_AUSENCIA;
      END;

      -- **********************************
      -- FASE 6: Buscar permisos compensatorios 15000 del día (margen ±15 min)
      -- **********************************
      BEGIN
        SELECT TO_NUMBER(TO_CHAR(TO_DATE('01/01/1900 ' || NVL(hora_inicio, '00:00'), 'DD/MM/YYYY HH24:MI'), 'HH24MI')) - C_MARGEN_PERMISO,
               TO_NUMBER(TO_CHAR(TO_DATE('01/01/1900 ' || NVL(hora_fin, '00:00'), 'DD/MM/YYYY HH24:MI'), 'HH24MI')) + C_MARGEN_PERMISO
        INTO hinicio_com, hfin_com
        FROM permiso
        WHERE TRUNC(fecha_inicio) = TRUNC(d_fecha_fichaje)
          AND id_tipo_permiso = C_TIPO_PERMISO_15000
          AND id_estado = C_ESTADO_APROBADO
          AND id_funcionario = i_id_funcionario;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          hinicio_com := C_HORA_INVALIDA;
          hfin_com    := C_HORA_FIN_INVALIDA;
        WHEN TOO_MANY_ROWS THEN
          hinicio_com := C_HORA_AUSENCIA_DEF;
          hfin_com    := C_HORA_FIN_AUSENCIA;
      END;

      -- **********************************
      -- FASE 7: Validar fichaje anterior si estaba descartado
      -- **********************************
      IF i_valido_ant = 1 THEN
        IF i_horas_f >= i_p2d THEN
          UPDATE fichaje_funcionario_tran
          SET valido = C_VALIDO_SI
          WHERE id_sec = i_id_sec_anterior;
          
          COMMIT;
          i_validos := i_validos + 1;
        END IF;
      END IF;

      -- **********************************
      -- FASE 8: Ajustar rango ausencias según reloj
      -- **********************************
      IF i_reloj <> C_RELOJ_MA AND i_reloj <> C_RELOJ_90 AND i_reloj <> C_RELOJ_91 THEN
        IF i_horas_f > i_po1d AND i_horas_f < i_po1h THEN
          hinicio := C_HORA_INVALIDA;
        END IF;
      END IF;

      -- **********************************
      -- FASE 9: Actualizar control de fechas
      -- **********************************
      v_fecha_nuevo := TO_CHAR(d_fecha_fichaje, 'DD/MM/YYYY');
      d_fecha_nuevo := d_fecha_fichaje;

      IF v_fecha_nuevo <> v_fecha_viejo THEN
        i_numero_fichaje := 1;
      END IF;

      -- **********************************
      -- FASE 10: Descartar fichajes en ausencias/permisos
      -- **********************************
      IF ((
            (i_horas_f >= hinicio AND i_horas_f <= hfin AND
             i_horas_f >= i_po1d AND i_horas_f <= i_po1h) 
            OR 
            (i_horas_f >= hinicio_com AND i_horas_f <= hfin_com AND
             i_horas_f > i_po1d AND i_horas_f < i_po1h)
          ) 
          AND i_numero_fichaje > 1)
         AND v_fecha_viejo = v_fecha_nuevo THEN
        
        UPDATE fichaje_funcionario_tran
        SET valido = C_VALIDO_NO
        WHERE id_sec = i_id_sec;
        
        COMMIT;
        i_valido_ant := 1;
        i_validos    := i_validos - 1;
      ELSE
        i_valido_ant := 0;
        i_validos    := i_validos + 1;
      END IF;

      -- **********************************
      -- FASE 11: Descartar fichajes duplicados (< 5 minutos diferencia)
      -- **********************************
      i_diferencia_saldo := (d_fecha_nuevo - d_fecha_viejo) * C_MINUTOS_DIA;

      IF i_diferencia_saldo <= C_UMBRAL_MINUTOS_DUP AND i_id_func_ant = i_id_funcionario THEN
        UPDATE fichaje_funcionario_tran
        SET valido = C_VALIDO_NO
        WHERE id_sec = i_id_sec;
        
        COMMIT;
      END IF;

      -- **********************************
      -- FASE 12: Actualizar variables para siguiente iteración
      -- **********************************
      v_fecha_viejo      := v_fecha_nuevo;
      d_fecha_viejo      := d_fecha_nuevo;
      i_id_func_ant      := i_id_funcionario;
      i_id_sec_anterior  := i_id_sec;
      i_horas_f_anterior := i_horas_f;

      -- **********************************
      -- FASE 13: Validar reloj asignado al funcionario (alerta sede diferente)
      -- **********************************
      IF i_reloj <> C_RELOJ_MA AND i_reloj <> C_RELOJ_90 AND 
         i_reloj <> C_RELOJ_91 AND i_reloj <> C_RELOJ_92 THEN
        
        i_cuantos_reloj := 0;
        BEGIN
          SELECT COUNT(*)
          INTO i_cuantos_reloj
          FROM FICHAJE_FUNCIONARIO_RELOJ
          WHERE id_funcionario = i_id_funcionario
            AND relojes = i_reloj;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_cuantos_reloj := 0;
        END;

        IF i_cuantos_reloj = 0 THEN
          BEGIN
            SELECT alerta_7
            INTO i_alerta_7
            FROM fichaje_funcionario_alerta
            WHERE id_funcionario = i_id_funcionario;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              i_alerta_7 := 0;
          END;

          IF i_alerta_7 = 1 THEN
            BEGIN
              INSERT INTO rrhh.fichaje_incidencia (
                id_incidencia, id_tipo_incidencia, nombre_fichero, 
                audit_usuario, audit_fecha, fecha_incidencia, 
                id_funcionario, nombre_ape, id_estado_inc, observaciones
              ) VALUES (
                rrhh.sec_id_incidencia_fihaje.NEXTVAL,
                C_TIPO_INCIDENCIA_7, '', C_AUDIT_USUARIO, SYSDATE, 
                d_fecha_fichaje, i_id_funcionario, '', C_ESTADO_INCIDENCIA, 
                C_OBS_SEDE_DIFERENTE
              );
            EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                NULL;
            END;
          END IF;
        END IF;
      END IF;

    END LOOP;
    CLOSE C2;

    -- **********************************
    -- FASE 14: Validar último fichaje descartado si es necesario
    -- **********************************
    IF i_valido_ant = 1 AND i_validos < C_VALIDOS_MIN THEN
      UPDATE fichaje_funcionario_tran
      SET valido = C_VALIDO_SI
      WHERE id_sec = i_id_sec_anterior;
      
      COMMIT;
      i_validos := i_validos + 1;
    END IF;

  END LOOP;
  CLOSE C0;

  -- **********************************
  -- FASE 15: Confirmar transacción final
  -- **********************************
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    IF C0%ISOPEN THEN
      CLOSE C0;
    END IF;
    IF C2%ISOPEN THEN
      CLOSE C2;
    END IF;
    ROLLBACK;
    RAISE;

END FINGER_LIMPIA_TRANS0;
/

