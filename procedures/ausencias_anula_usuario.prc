/**
 * AUSENCIAS_ANULA_USUARIO
 *
 * @description
 * Permite a un empleado anular su propia solicitud de ausencia antes de que comience.
 * Revierte las bolsas (concilia/sindical), anula finger y notifica por correo.
 *
 * @details
 * Requisitos para anulación por usuario:
 * - Fecha inicio ausencia > fecha actual (no puede anular ausencias ya iniciadas)
 * - El funcionario debe ser propietario de la ausencia
 * - Tipo funcionario válido en personal_new
 *
 * Operaciones realizadas:
 * - Cambio estado 41 (Anulado por usuario)
 * - Reversión bolsa_concilia (tipo 50)
 * - Reversión hora_sindical (tipos > 500)
 * - Anulación en sistema finger (si el usuario ficha)
 * - Notificación correo al JS
 *
 * Estados ausencias:
 * 10=Solicitado, 20=Pde JS, 21=Pde JA, 22=Pde RRHH
 * 30=Rechazado JS, 31=Rechazado JA, 32=Denegado RRHH
 * 40=Anulado RRHH, 41=Anulado Usuario, 80=Concedido
 *
 * @param V_ID_AUSENCIA    IN ID de la ausencia a anular
 * @param V_ID_FUNCIONARIO IN ID del funcionario que solicita anular
 * @param todo_ok_Basico   OUT 0=Éxito, 1=Error
 * @param msgBasico        OUT Mensaje resultado
 *
 * @notes
 * - Solo puede anular ausencias futuras (fecha_inicio > hoy)
 * - Anulación finger solo si usuario ficha (codpers en presenci)
 * - Revertir bolsa_concilia: utilizadas y pendientes_justificar
 * - Revertir hora_sindical: total_utilizadas por mes
 * - Notificación correo enviado a JS de la ausencia anulada
 *
 * @see anula_fichaje_finger_15000  Anulación en sistema finger
 * @see envio_correo                Envío notificación
 *
 * @author Sistema Ausencias RRHH
 * @date   Actualizado 03/03/2017 (añadido estado 41)
 * @version 2.0
 */
CREATE OR REPLACE PROCEDURE RRHH.AUSENCIAS_ANULA_USUARIO (
  V_ID_AUSENCIA    IN NUMBER,
  V_ID_FUNCIONARIO IN NUMBER,
  todo_ok_Basico   OUT INTEGER,
  msgBasico        OUT VARCHAR2
) IS

  -- Constantes
  C_ESTADO_ANULADO_USUARIO CONSTANT VARCHAR2(2) := '41';
  C_TIPO_AUSENCIA_CONCILIA CONSTANT VARCHAR2(3) := '50';
  C_TIPO_AUSENCIA_SINDICAL CONSTANT NUMBER := 500;
  
  -- Variables ausencia
  I_id_estado_ausencia     NUMBER;
  i_ausencia_no_encontrado NUMBER;
  i_observaciones          VARCHAR2(1000);
  i_justificacion          VARCHAR2(2);
  i_total_utilizadas       NUMBER;
  i_id_ano                 NUMBER;
  i_id_tipo_ausencia       NUMBER;
  i_id_mes                 NUMBER;
  i_fecha_inicio           DATE;
  i_fecha_fin              DATE;
  i_hora_inicio            VARCHAR2(12);
  i_hora_fin               VARCHAR2(12);
  i_id_funcionario         NUMBER;
  i_id_js                  NUMBER;
  i_DESC_TIPO_AUSENCIA     VARCHAR2(100);
  fecha_hoy                DATE;
  i_tipo_funcionario       NUMBER;
  
  -- Variables finger
  i_ficha   NUMBER;
  i_codpers VARCHAR2(5);
  
  -- Variables correo
  correo_v_funcionario VARCHAR2(100);
  i_nombre_peticion    VARCHAR2(100);
  correo_js            VARCHAR2(100);
  i_sender             VARCHAR2(100);
  i_recipient          VARCHAR2(100);
  I_ccrecipient        VARCHAR2(100);
  i_subject            VARCHAR2(100);
  I_message            VARCHAR2(4000);
  i_desc_mensaje       VARCHAR2(4000);

BEGIN

  --------------------------------------------------------------------------------
  -- FASE 1: VALIDAR AUSENCIA Y OBTENER DATOS
  --------------------------------------------------------------------------------
  
  todo_ok_basico := 0;
  I_id_estado_ausencia := 0;
  i_ausencia_no_encontrado := 0;
  
  -- Obtener datos ausencia
  BEGIN
    SELECT t.id_estado,
           OBSERVACIONES,
           t.JUSTIFICADO,
           t.total_horas,
           TO_CHAR(t.fecha_inicio, 'MM'),
           t.id_ano,
           t.id_tipo_ausencia,
           t.id_funcionario,
           t.fecha_inicio,
           t.fecha_fin,
           TO_CHAR(t.fecha_inicio, 'HH24:mi'),
           TO_CHAR(t.fecha_fin, 'HH24:mi'),
           t.firmado_js,
           DESC_TIPO_AUSENCIA
    INTO   I_id_estado_ausencia,
           i_observaciones,
           i_justificacion,
           i_total_utilizadas,
           i_id_mes,
           i_id_ano,
           i_id_tipo_ausencia,
           i_id_funcionario,
           i_fecha_inicio,
           i_fecha_fin,
           i_hora_inicio,
           i_hora_fin,
           i_id_js,
           i_DESC_TIPO_AUSENCIA
    FROM   ausencia t,
           tr_tipo_ausencia tr
    WHERE  ID_AUSENCIA = V_ID_AUSENCIA
      AND  t.id_tipo_ausencia = tr.id_tipo_ausencia;
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_ausencia_no_encontrado := 1;
  END;
  
  -- Validar propiedad ausencia
  IF V_ID_FUNCIONARIO <> i_id_funcionario THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada. Avisar a RRHH.' || V_ID_FUNCIONARIO || '--' || i_id_funcionario;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 2: VALIDAR TIPO FUNCIONARIO
  --------------------------------------------------------------------------------
  
  i_tipo_funcionario := 10;
  
  BEGIN
    SELECT tipo_funcionario2
    INTO   i_tipo_funcionario
    FROM   personal_new pe
    WHERE  id_funcionario = i_id_funcionario
      AND  ROWNUM < 2;
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_tipo_funcionario := -1;
  END;
  
  IF i_tipo_funcionario = -1 THEN
    todo_ok_basico := 1;
    msgBasico := 'Operacion no realizada. TIPO FUNCIONARIO NO ENCONTRADO.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 3: VALIDAR FECHA INICIO > HOY
  --------------------------------------------------------------------------------
  
  SELECT TO_DATE(TO_CHAR(SYSDATE - 1, 'dd/mm/yyyy'), 'dd/mm/yyyy')
  INTO   fecha_hoy
  FROM   DUAL;
  
  IF fecha_hoy >= i_fecha_inicio THEN
    msgbasico := 'Para anular la Fecha de Inicio del permiso tiene que ser menor que la fecha actual .';
    todo_ok_basico := 1;
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 4: ANULAR EN FINGER (si ficha)
  --------------------------------------------------------------------------------
  
  i_ficha := 1;
  
  BEGIN
    SELECT DISTINCT codpers
    INTO   i_codpers
    FROM   personal_new p,
           presenci pr,
           apliweb_usuario u
    WHERE  p.id_funcionario = i_id_funcionario
      AND  LPAD(p.id_funcionario, 6, 0) = LPAD(u.id_funcionario, 6, 0)
      AND  u.id_fichaje IS NOT NULL
      AND  u.id_fichaje = pr.codpers
      AND  codinci <> 999
      AND  ROWNUM < 2;
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_ficha := 0;
  END;
  
  IF i_ficha = 1 THEN
    ANULA_FICHAJE_FINGER_15000(
      i_id_ano,
      i_id_funcionario,
      i_fecha_inicio,
      i_hora_inicio,
      i_hora_fin,
      i_codpers,
      0,
      '00000',
      todo_ok_basico,
      msgbasico
    );
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 5: ACTUALIZAR ESTADO Y REVERTIR BOLSAS
  --------------------------------------------------------------------------------
  
  -- Cambiar estado a 41 (Anulado Usuario)
  UPDATE AUSENCIA
  SET    id_Estado = C_ESTADO_ANULADO_USUARIO,
         fecha_modi = SYSDATE
  WHERE  ID_AUSENCIA = V_ID_AUSENCIA
    AND  ROWNUM < 2;
  
  -- Revertir bolsa concilia (tipo 50)
  IF i_ID_TIPO_AUSENCIA = C_TIPO_AUSENCIA_CONCILIA THEN
    UPDATE BOLSA_CONCILIA
    SET    utilizadas = utilizadas - i_total_utilizadas,
           pendientes_justificar = pendientes_justificar - i_total_utilizadas
    WHERE  id_ano = i_id_ano
      AND  id_funcionario = V_ID_FUNCIONARIO;
  END IF;
  
  -- Revertir horas sindicales (tipos > 500)
  IF i_id_tipo_ausencia > C_TIPO_AUSENCIA_SINDICAL THEN
    UPDATE HORA_SINDICAL
    SET    TOTAL_UTILIZADAS = TOTAL_UTILIZADAS - i_total_utilizadas
    WHERE  id_ano = i_id_ano
      AND  id_MES = i_id_mes
      AND  id_funcionario = i_id_funcionario
      AND  ID_TIPO_AUSENCIA = i_id_tipo_ausencia
      AND  ROWNUM < 2;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 6: NOTIFICAR POR CORREO
  --------------------------------------------------------------------------------
  
  -- Obtener correos
  BEGIN
    SELECT MIN(peticion),
           MIN(nombre_peticion),
           MIN(js)
    INTO   correo_v_funcionario,
           i_nombre_peticion,
           correo_js
    FROM   (SELECT login || '@aytosalamanca.es' AS peticion,
                   SUBSTR(DIST_NAME, INSTR(DIST_NAME, '=', 1) + 1, INSTR(DIST_NAME, ',', 1) - INSTR(DIST_NAME, '=', 1) - 1) AS nombre_peticion,
                   '' AS js
            FROM   apliweb_usuario
            WHERE  id_funcionario = TO_CHAR(i_id_funcionario)
            UNION
            SELECT '' AS peticion,
                   '' AS nombre_peticion,
                   login || '@aytosalamanca.es' AS js
            FROM   apliweb_usuario
            WHERE  LPAD(id_funcionario, 6, '0') = LPAD(i_id_js, 6, '0'));
            
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_id_js := '';
  END;
  
  -- Preparar mensaje correo
  i_sender := correo_v_funcionario;
  I_ccrecipient := '';
  i_recipient := correo_js;
  
  BEGIN
    SELECT CABECERA || ' ' ||
           'Ausencia ANULADA por' || ' ' ||
           SOLICITADO || ' ' ||
           i_nombre_peticion || ' ' ||
           TIPO_PERMISO || ' ' ||
           i_desc_tipo_ausencia || ' ' ||
           FECHA_INICIO || ' ' ||
           TO_CHAR(i_fecha_inicio, 'DD/MM/YYYY') || ' ' ||
           DECODE(SUBSTR(i_ID_TIPO_AUSENCIA, 1, 1), '5',
                  FECHA_FIN || ' ' || TO_CHAR(i_fecha_fin, 'DD/MM/YYYY'), '') || ' ' ||
           HORA_INICIO || ' ' || i_HORA_INICIO || ' ' ||
           HORA_FIN || ' ' || i_HORA_FIN || ' ' ||
           CABECERA_FI || ' ' ||
           'Esta Ausencia ha sido ANULADA' || ' ' ||
           CABECERA_FIN_2
    INTO   i_desc_mensaje
    FROM   FORMATO_CORREO
    WHERE  DECODE(SUBSTR(i_ID_TIPO_AUSENCIA, 1, 1), '5', '500', '222') = ID_TIPO_PERMISO;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_desc_tipo_ausencia := '';
  END;
  
  I_message := i_desc_mensaje;
  i_subject := 'Ausencia ha sido Anulada por el Usuario.';
  
  envio_correo(i_sender, i_recipient, I_ccrecipient, i_subject, I_message);
  
  msgbasico := 'Permiso anulado correctamente.';
  todo_ok_basico := 0;
  
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error en ausencias_anula_usuario: ' || SQLERRM);
    ROLLBACK;
    todo_ok_basico := 1;
    msgBasico := 'Error en ausencias_anula_usuario: ' || SQLERRM;
    
END AUSENCIAS_ANULA_USUARIO;
/
