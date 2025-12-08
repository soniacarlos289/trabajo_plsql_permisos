CREATE OR REPLACE PROCEDURE RRHH.FINGER_RELOJES_CHEQUEA IS
  /**
   * @description Chequea el estado de los relojes de fichaje y envía alertas por correo en caso de inactividad
   * @details Proceso de monitoreo que detecta relojes de fichaje sin transacciones el día actual (laborable).
   *          Verifica última transacción de cada reloj activo en últimos 15 días:
   *          - Si última transacción NO es de hoy → reloj posiblemente averiado
   *          - Solo envía alertas en días laborables (lunes a viernes, excluyendo sábado/domingo)
   *          - Envía correos de alerta a carlos@aytosalamanca.es y permisos@aytosalamanca.es
   *          - Registra relojes problemáticos en tabla temp_reloj_ko para seguimiento
   * @notes 
   *   - Relojes excluidos del chequeo: 91, MA, 88, 90
   *   - Ventana temporal: últimos 15 días (desde sysdate-15)
   *   - Solo relojes con activo='S' en tabla relojes
   *   - Limpia temp_reloj_ko al inicio de cada ejecución
   *   - Correos comentados: cpelaez@, jmsalinero@ (mantener por referencia histórica)
   */

  -- Constantes
  C_DIAS_VENTANA        CONSTANT NUMBER := 15;
  C_DIAS_FUTURO         CONSTANT NUMBER := 5;
  C_ESTADO_ACTIVO       CONSTANT VARCHAR2(1) := 'S';
  C_RELOJ_EXCL_1        CONSTANT VARCHAR2(2) := '91';
  C_RELOJ_EXCL_2        CONSTANT VARCHAR2(2) := 'MA';
  C_RELOJ_EXCL_3        CONSTANT VARCHAR2(2) := '88';
  C_RELOJ_EXCL_4        CONSTANT VARCHAR2(2) := '90';
  C_DIA_SABADO          CONSTANT VARCHAR2(1) := '7';
  C_DIA_DOMINGO         CONSTANT VARCHAR2(1) := '1';
  C_FLAG_DESACTUALIZADO CONSTANT VARCHAR2(1) := '1';
  C_FLAG_ACTUALIZADO    CONSTANT VARCHAR2(1) := '0';
  C_CORREO_FROM         CONSTANT VARCHAR2(50) := 'noresponda@aytosalamanca.es';
  C_CORREO_CARLOS       CONSTANT VARCHAR2(50) := 'carlos@aytosalamanca.es';
  C_CORREO_PERMISOS     CONSTANT VARCHAR2(50) := 'permisos@aytosalamanca.es';
  C_CORREO_CC           CONSTANT VARCHAR2(1) := '';
  C_ASUNTO_PREFIJO      CONSTANT VARCHAR2(30) := 'Reloj sin fichajes: ';
  C_CUERPO_PREFIJO      CONSTANT VARCHAR2(50) := 'Posible avería de reloj, Ultima conexion: ';

  -- Variables
  v_impar        VARCHAR2(15);
  v_numero       VARCHAR2(15);
  v_denom        VARCHAR2(151);
  v_fecha_con    VARCHAR2(151);
  v_ult_con      VARCHAR2(151);
  d_dia          VARCHAR2(151);

  -- Cursor: Última transacción de cada reloj activo (últimos 15 días)
  CURSOR c2 IS
    SELECT 
           -- Flag: '1' si última transacción NO es de hoy, '0' si es de hoy
           DECODE(TO_CHAR(fecha, 'DD/MM/YYYY'),
                  TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
                  C_FLAG_ACTUALIZADO,
                  C_FLAG_DESACTUALIZADO) AS impar,
           t.numero AS num_fin,
           denom AS denom_fin,
           TO_CHAR(fecha, 'DD/MM/YYYY') AS fecha,
           TO_CHAR(hora, 'HH24:MI:SS') AS ult_con
    FROM transacciones t
    INNER JOIN relojes r ON TO_NUMBER(t.numero) = TO_NUMBER(r.numero)
    WHERE t.fecha > SYSDATE - C_DIAS_VENTANA
      AND r.activo = C_ESTADO_ACTIVO
      AND (t.numserie, t.numero) IN (
            -- Subconsulta: última transacción (max numserie) por reloj
            SELECT MAX(numserie), numero
            FROM transacciones
            WHERE fecha BETWEEN SYSDATE - C_DIAS_VENTANA AND SYSDATE + C_DIAS_FUTURO
              AND numero NOT IN (C_RELOJ_EXCL_1, C_RELOJ_EXCL_2, C_RELOJ_EXCL_3, C_RELOJ_EXCL_4)
            GROUP BY numero
          )
    ORDER BY t.numero;

BEGIN

  -- **********************************
  -- FASE 1: Limpiar tabla temporal de relojes problemáticos
  -- **********************************
  DELETE FROM temp_reloj_ko;
  COMMIT;

  -- **********************************
  -- FASE 2: Obtener día de semana actual
  -- **********************************
  SELECT TO_CHAR(SYSDATE, 'D')
  INTO d_dia
  FROM DUAL;

  -- **********************************
  -- FASE 3: Iterar relojes y detectar inactividad
  -- **********************************
  OPEN c2;
  LOOP
    FETCH c2 INTO v_impar, v_numero, v_denom, v_fecha_con, v_ult_con;
    EXIT WHEN c2%NOTFOUND;

    -- **********************************
    -- FASE 4: Evaluar y alertar relojes desactualizados (solo días laborables)
    -- **********************************
    IF v_impar = C_FLAG_DESACTUALIZADO 
       AND (d_dia <> C_DIA_DOMINGO AND d_dia <> C_DIA_SABADO) THEN
      
      -- Registrar reloj problemático
      INSERT INTO temp_reloj_ko VALUES (v_numero);

      -- Enviar correo a Carlos
      envio_correo(
        C_CORREO_FROM,
        C_CORREO_CARLOS,
        C_CORREO_CC,
        C_ASUNTO_PREFIJO || v_denom,
        C_CUERPO_PREFIJO || v_fecha_con || ' ' || v_ult_con
      );

      /* Correos adicionales comentados (mantener por referencia histórica)
      envio_correo(
        C_CORREO_FROM,
        'cpelaez@aytosalamanca.es',
        C_CORREO_CC,
        C_ASUNTO_PREFIJO || v_denom,
        C_CUERPO_PREFIJO || v_fecha_con || ' ' || v_ult_con
      );

      envio_correo(
        C_CORREO_FROM,
        'jmsalinero@aytosalamanca.es',
        C_CORREO_CC,
        C_ASUNTO_PREFIJO || v_denom,
        C_CUERPO_PREFIJO || v_fecha_con || ' ' || v_ult_con
      );
      */

      -- Enviar correo a equipo Permisos
      envio_correo(
        C_CORREO_FROM,
        C_CORREO_PERMISOS,
        C_CORREO_CC,
        C_ASUNTO_PREFIJO || v_denom,
        C_CUERPO_PREFIJO || v_fecha_con || ' ' || v_ult_con
      );

    END IF;

  END LOOP;
  CLOSE c2;

EXCEPTION
  WHEN OTHERS THEN
    IF c2%ISOPEN THEN
      CLOSE c2;
    END IF;
    ROLLBACK;
    RAISE;

END FINGER_RELOJES_CHEQUEA;
/

