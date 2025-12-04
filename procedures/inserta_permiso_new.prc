--------------------------------------------------------------------------------
-- PROCEDURE: INSERTA_PERMISO_NEW
--------------------------------------------------------------------------------
-- Propósito: Insertar solicitud de permiso del funcionario (usuario final)
-- Autor: RRHH / Optimizado por Carlos (04/12/2025)
-- Versión: 2.0.0
--
-- Descripción:
--   Inserta nueva solicitud de permiso iniciada por el funcionario.
--   El permiso queda en estado SOLICITADO (10) o PENDIENTE FIRMA (20/21/22)
--   según la jerarquía de firmas configurada.
--
--   Funcionalidades especiales:
--   - Gestión de firmas para funcionarios normales (JS → JA → RRHH)
--   - Gestión específica para BOMBEROS (jefe de guardia actual)
--   - Soporte para delegados de firma (suplentes)
--   - Envío de notificaciones por correo electrónico
--   - Generación de enlace para adjuntar documentación
--
-- Estados de permiso:
--   10 - Solicitado
--   20 - Pendiente Firma Jefe Sección
--   21 - Pendiente Firma Jefe Área
--   22 - Pendiente Visto Bueno RRHH
--
-- Parámetros:
--   V_ID_ANO              - Año del permiso (IN)
--   V_ID_FUNCIONARIO      - ID funcionario solicitante (IN)
--   V_ID_TIPO_FUNCIONARIO - Tipo funcionario (23=Bombero) (IN)
--   V_ID_TIPO_PERMISO     - Código tipo permiso (IN)
--   V_ID_TIPO_DIAS        - Tipo días L/N/H (IN OUT)
--   V_FECHA_INICIO        - Fecha inicio (IN)
--   V_FECHA_FIN           - Fecha fin (IN)
--   V_HORA_INICIO         - Hora inicio (IN)
--   V_HORA_FIN            - Hora fin (IN)
--   V_UNICO               - Permiso único (IN OUT)
--   V_DPROVINCIA          - Provincia (IN)
--   V_ID_GRADO            - Grado funcionario (IN)
--   V_JUSTIFICACION       - Justificación requerida (IN)
--   V_NUM_DIAS            - Número de días (IN)
--   v_total_horas         - Total horas (IN)
--   V_t1/V_t2/V_t3        - Turnos bomberos (IN)
--   V_GUARDIAS            - Observaciones guardias (IN)
--   todo_ok_Basico        - 0=OK, 1=Error (OUT)
--   msgBasico             - Mensaje resultado (OUT)
--   enlace_fichero        - Enlace para adjuntar docs (OUT)
--
-- Historial:
--   04/12/2025 - Carlos - Optimización v2.0
--   27/10/2025 - CHM - Comentado envío correos
--   16/03/2017 - CHM - Validación especial JA bomberos
--   12/02/2017 - CHM - Mejorada búsqueda nombre
--   25/01/2017 - CHM - Añadido soporte bomberos
--   01/06/2016 - CHM - Delegados múltiples de firma
--   25/07/2013 - CHM - Correo a suplente si JS de vacaciones
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE RRHH.INSERTA_PERMISO_NEW (
        V_ID_ANO IN NUMBER,
        V_ID_FUNCIONARIO IN NUMBER,
        V_ID_TIPO_FUNCIONARIO IN NUMBER,
        V_ID_TIPO_PERMISO IN VARCHAR2,
        V_ID_TIPO_DIAS IN OUT VARCHAR2,
        V_FECHA_INICIO IN DATE,
        V_FECHA_FIN IN DATE,
        V_HORA_INICIO IN VARCHAR2,
        V_HORA_FIN IN VARCHAR2,
        V_UNICO IN OUT VARCHAR2,
        V_DPROVINCIA IN VARCHAR2,
        V_ID_GRADO IN VARCHAR2,
        V_JUSTIFICACION IN VARCHAR2,
        V_NUM_DIAS IN NUMBER,
        v_total_horas IN NUMBER,
        V_t1 IN VARCHAR2,
        V_t2 IN VARCHAR2,
        V_t3 IN VARCHAR2,
        V_GUARDIAS IN VARCHAR2,
        todo_ok_Basico OUT INTEGER,
        msgBasico OUT VARCHAR2,
        enlace_fichero OUT VARCHAR2
) IS

  --------------------------------------------------------------------------------
  -- CONSTANTES
  --------------------------------------------------------------------------------
  C_OK CONSTANT INTEGER := 0;
  C_ERROR CONSTANT INTEGER := 1;
  
  -- Estados de permiso
  C_ESTADO_SOLICITADO CONSTANT NUMBER := 10;
  C_ESTADO_PENDIENTE_JS CONSTANT NUMBER := 20;
  C_ESTADO_PENDIENTE_JA CONSTANT NUMBER := 21;
  C_ESTADO_PENDIENTE_RRHH CONSTANT NUMBER := 22;
  
  -- Tipos especiales
  C_TIPO_FUNC_BOMBERO CONSTANT NUMBER := 23;
  C_PERMISO_COMPENSATORIO CONSTANT VARCHAR2(5) := '15000';
  C_EMAIL_DOMAIN CONSTANT VARCHAR2(20) := '@aytosalamanca.es';
  C_FLAG_NO CONSTANT VARCHAR2(2) := 'NO';
  
  -- IDs especiales
  C_ID_JA_BOMBEROS CONSTANT VARCHAR2(6) := '961110'; -- Luis Damián Ramos
  C_ID_JS_ESPECIAL CONSTANT VARCHAR2(6) := '101217';
  
  --------------------------------------------------------------------------------
  -- VARIABLES LOCALES (OPTIMIZADAS)
  --------------------------------------------------------------------------------
  
  -- Secuencias
  i_secuencia_operacion NUMBER;
  i_secuencia_permiso NUMBER;
  
  -- Jerarquía de firmas
  i_id_js VARCHAR2(6);
  i_id_delegado_js VARCHAR2(6);
  i_id_delegado_js2 VARCHAR2(6);
  i_id_delegado_js3 VARCHAR2(6);
  i_id_delegado_js4 VARCHAR2(6);
  i_id_ja VARCHAR2(6);
  i_id_delegado_ja VARCHAR2(6);
  i_id_delegado_firma NUMBER(1);
  
  -- Estado y fechas
  i_Estado_permiso NUMBER;
  i_fecha_js DATE;
  i_fecha_ja DATE;
  i_fecha_rrhh DATE;
  i_fecha VARCHAR2(10);
  i_hora VARCHAR2(10);
  i_id_ano VARCHAR2(4);
  
  -- Correos
  correo_v_funcionario VARCHAR2(100);
  correo_js VARCHAR2(100);
  correo_ja VARCHAR2(100);
  correo_js_delegado VARCHAR2(100);
  correo_js_delegado2 VARCHAR2(100);
  correo_js_delegado3 VARCHAR2(100);
  correo_js_delegado4 VARCHAR2(100);
  i_sender VARCHAR2(100);
  i_recipient VARCHAR2(100);
  I_ccrecipient VARCHAR2(100);
  i_subject VARCHAR2(200);
  I_message VARCHAR2(4000);
  
  -- Descriptivos
  i_nombre_peticion VARCHAR2(200);
  i_des_tipo_permiso_larga VARCHAR2(200);
  i_cadena2 VARCHAR2(500);
  v_mensaje VARCHAR2(4000);
  
  -- Bomberos
  V_JEFE_GUARDIA VARCHAR2(6);
  V_JUSTIFI VARCHAR2(6);

BEGIN
  
  --------------------------------------------------------------------------------
  -- FASE 1: INICIALIZACIÓN
  --------------------------------------------------------------------------------
  
  todo_ok_basico := C_OK;
  msgBasico := '';


-- 10 Solicitado
-- 20 Pde. Firma Jefe Secc.
-- 21 Pde. Firma Jefe Area
-- 22 Pde Vo de RRHH.
-- 30 Rechazado Jefe Secc.
-- 31 Rechazado Jefe Area.
-- 32 Denegado RRHH
-- 40 Anulado RRHH
-- 41 Anulado por USUARIO //a�adido 03/03/2017
-- 80 Concedido
--obtenemos las persona que tienen que firmar si no tiene personas
--no se deja coger le permiso .
--a?adido distinct dia 8 - junio  repetidos



  --A�adido chm 25/01/2017
  --FIRMAS PARA BOMBEROS ELSE
  IF V_ID_TIPO_FUNCIONARIO <> 23 THEN
  
    BEGIN
      SELECT DISTINCT 
             id_js,
             id_delegado_js,
             id_ja,
             id_delegado_ja,
             id_delegado_firma,
             id_delegado_js2,
             id_delegado_js3,
             id_delegado_js4
      INTO i_id_js,
           i_id_delegado_js,
           i_id_ja,
           i_id_delegado_ja,
           i_id_delegado_firma,
           i_id_delegado_js2,
           i_id_delegado_js3,
           i_id_delegado_js4
      FROM funcionario_firma
      WHERE V_ID_FUNCIONARIO = ID_FUNCIONARIO;
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_id_ja := '0';
        i_id_js := '0';
    END;
  
    --------------------------------------------------------------------------------
    -- FASE 4: OBTENER CORREOS ELECTRÓNICOS (PETICIONARIO Y FIRMANTES)
    --------------------------------------------------------------------------------
    
    -- Búsqueda de nombre del peticionario mediante apliweb_usuario
    BEGIN
      SELECT MIN(peticion),
             MIN(nombre_peticion),
             MIN(js),
             MIN(js_delegado),
             MIN(ja),
             MIN(js_delegado2),
             MIN(js_delegado3),
             MIN(js_delegado4)
      INTO correo_v_funcionario,
           i_nombre_peticion,
           correo_js,
           correo_js_delegado,
           correo_ja,
           correo_js_delegado2,
           correo_js_delegado3,
           correo_js_delegado4
      FROM (
        -- Correo del peticionario
        SELECT login || C_EMAIL_DOMAIN AS peticion,
               TRIM(SUBSTR(dist_NAME, 4, INSTR(dist_NAME, ',', 1) - 4)) AS nombre_peticion,
               '' AS js,
               '' AS js_delegado,
               '' AS ja,
               '' AS js_delegado2,
               '' AS js_delegado3,
               '' AS js_delegado4
        FROM apliweb_usuario
        WHERE LPAD(id_funcionario, 6, '0') = LPAD(TO_CHAR(V_ID_FUNCIONARIO), 6, '0')
        
        UNION
        
        -- Correo JS
        SELECT '' AS peticion,
               '' AS nombre_peticion,
               login || C_EMAIL_DOMAIN AS js,
               '' AS js_delegado,
               '' AS ja,
               '' AS js_delegado2,
               '' AS js_delegado3,
               '' AS js_delegado4
        FROM apliweb_usuario
        WHERE LPAD(id_funcionario, 6, '0') = LPAD(i_id_js, 6, '0')
        
        UNION
        
        -- Correo delegado JS
        SELECT '' AS peticion,
               '' AS nombre_peticion,
               '' AS js,
               login || C_EMAIL_DOMAIN AS js_delegado,
               '' AS ja,
               '' AS js_delegado2,
               '' AS js_delegado3,
               '' AS js_delegado4
        FROM apliweb_usuario
        WHERE LPAD(id_funcionario, 6, '0') = LPAD(i_id_delegado_js, 6, '0')
        
        UNION
        
        -- Correo JA
        SELECT '' AS peticion,
               '' AS nombre_peticion,
               '' AS js,
               '' AS js_delegado,
               login || C_EMAIL_DOMAIN AS ja,
               '' AS js_delegado2,
               '' AS js_delegado3,
               '' AS js_delegado4
        FROM apliweb_usuario
        WHERE LPAD(id_funcionario, 6, '0') = LPAD(i_id_ja, 6, '0')
        
        UNION
        
        -- Correo delegado JS2
        SELECT '' AS peticion,
               '' AS nombre_peticion,
               '' AS js,
               '' AS js_delegado,
               '' AS ja,
               login || C_EMAIL_DOMAIN AS js_delegado2,
               '' AS js_delegado3,
               '' AS js_delegado4
        FROM apliweb_usuario
        WHERE LPAD(id_funcionario, 6, '0') = LPAD(i_id_delegado_js2, 6, '0')
        
        UNION
        
        -- Correo delegado JS3
        SELECT '' AS peticion,
               '' AS nombre_peticion,
               '' AS js,
               '' AS js_delegado,
               '' AS ja,
               '' AS js_delegado2,
               login || C_EMAIL_DOMAIN AS js_delegado3,
               '' AS js_delegado4
        FROM apliweb_usuario
        WHERE LPAD(id_funcionario, 6, '0') = LPAD(i_id_delegado_js3, 6, '0')
        
        UNION
        
        -- Correo delegado JS4
        SELECT '' AS peticion,
               '' AS nombre_peticion,
               '' AS js,
               '' AS js_delegado,
               '' AS ja,
               '' AS js_delegado2,
               '' AS js_delegado3,
               login || C_EMAIL_DOMAIN AS js_delegado4
        FROM apliweb_usuario
        WHERE LPAD(id_funcionario, 6, '0') = LPAD(i_id_delegado_js4, 6, '0')
      );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_id_ja := '0';
        i_id_js := '0';
    END;
    
    -- Validación: Si no hay jefes para firmar el permiso → error
    IF i_id_js = '0' AND i_id_ja = '0' THEN
      todo_ok_basico := C_ERROR;
      msgBasico := 'Operacion no realizada. Pongase en contacto con RRHH. Sin firmas.';
      RETURN;
    END IF;
  
  ELSE
  
    --------------------------------------------------------------------------------
    -- FASE 5: BÚSQUEDA FIRMA BOMBEROS (JEFE DE GUARDIA ACTUAL)
    --------------------------------------------------------------------------------
    
    i_id_ja := '0';
    i_id_js := '0';
    correo_js := '';
    V_JEFE_GUARDIA := '';
    
    -- Buscar jefe de guardia actual (dotación M) y correo JA bomberos
    BEGIN
      SELECT login || C_EMAIL_DOMAIN,
             LPAD(funcionario, 6, '0'),
             C_ID_JA_BOMBEROS,
             'ldramos' || C_EMAIL_DOMAIN
      INTO correo_js,
           i_id_js,
           i_id_ja,
           correo_ja
      FROM bomberos_guardias_plani s,
           apliweb_usuario a
      WHERE desde = DECODE(
              TRUNC(TO_CHAR(SYSDATE + 0/24, 'hh24') / 8),
              0, TO_DATE(TO_CHAR(SYSDATE - 1, 'DD/mm/yyyy') || '08:00', 'DD/mm/yyyy hh24:mi'),
              TO_DATE(TO_CHAR(SYSDATE, 'DD/mm/yyyy') || '08:00', 'DD/mm/yyyy hh24:mi')
            )
        AND dotacion = 'M'
        AND LPAD(funcionario, 6, '0') = LPAD(id_funcionario, 6, '0')
        AND ROWNUM < 2;
        
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_id_js := '0';
    END;
    
    -- Validación: Si no hay jefe de guardia asignado → error
    IF i_id_js = '0' AND i_id_ja = '0' THEN
      todo_ok_basico := C_ERROR;
      msgBasico := 'La guardia no tiene asignada Jefe, intentelo m�s tarde.';
      RETURN;
    END IF;
    
    -- Obtener nombre peticionario y correo
    BEGIN
      SELECT MIN(correo_funcionario),
             MIN(nombre_peticion)
      INTO correo_v_funcionario,
           i_nombre_peticion
      FROM (
        SELECT login || C_EMAIL_DOMAIN AS correo_funcionario,
               TRIM(SUBSTR(dist_NAME, 4, INSTR(dist_NAME, ',', 1) - 4)) AS nombre_peticion
        FROM apliweb_usuario
        WHERE LPAD(id_funcionario, 6, '0') = LPAD(TO_CHAR(V_ID_FUNCIONARIO), 6, '0')
      );
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        correo_v_funcionario := '';
    END;
  
  END IF;
  
  /*
  -- Código legado comentado (lógica antigua de guardias)
  --Comprobamos que el funcionario esta de guardia.
  BEGIN
    SELECT login || '@aytosalamanca.es' INTO correo_js FROM sige.GUARDIAS@lsige s, apliweb.usuario a
    WHERE desde = DECODE(TRUNC(TO_CHAR(sysdate+0/24,'hh24')/14),1,
          TO_DATE(TO_CHAR(sysdate,'DD/mm/yyyy')   || '14:00','DD/mm/yyyy hh24:mi'),
          TO_DATE(TO_CHAR(sysdate-1,'DD/mm/yyyy') || '14:00','DD/mm/yyyy hh24:mi')
           ) AND dotacion='M' AND LPAD(funcionario,6,'0')=LPAD(id_funcionario,6,'0');
  EXCEPTION
       WHEN NO_DATA_FOUND THEN
       i_id_js:='';
  END;
  
  IF correo_js := '' THEN
    todo_ok_basico:=1;
    msgBasico:='La guardia no tiene asignada Jefe, intentelo m�s tarde.';
    RETURN;
  END IF;
  */
  
  --------------------------------------------------------------------------------
  -- FASE 6: PREPARAR DATOS DEL PERMISO Y DETERMINAR ESTADO
  --------------------------------------------------------------------------------
  
  -- Descripción del tipo de permiso
  BEGIN
    SELECT DISTINCT des_tipo_permiso_larga
    INTO i_des_tipo_permiso_larga
    FROM TR_TIPO_PERMISO
    WHERE V_ID_TIPO_PERMISO = ID_TIPO_PERMISO
      AND ID_ANO = V_ID_ANO;
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_des_tipo_permiso_larga := '';
  END;
  
  -- Estado inicial: Solicitado (10)
  i_Estado_permiso := C_ESTADO_SOLICITADO;
  i_fecha_js := '';
  i_fecha_ja := '';
  i_fecha_rrhh := '';
  i_sender := correo_v_funcionario;
  
  -- Cadena descriptiva según tipo de permiso
  IF V_ID_TIPO_PERMISO <> C_PERMISO_COMPENSATORIO THEN
    i_cadena2 := 'Fecha Inicio: ' || TO_CHAR(V_FECHA_INICIO, 'DD-MON-YY') || CHR(10) ||
                 'Fecha Fin:     ' || TO_CHAR(V_FECHA_FIN, 'DD-MON-YY');
  ELSE
    i_cadena2 := 'Fecha Inicio: ' || TO_CHAR(V_FECHA_INICIO, 'DD-MON-YY') || CHR(10) ||
                 'Hora de Inicio:     ' || V_HORA_INICIO || CHR(10) ||
                 'Hora Fin: ' || V_HORA_FIN;
  END IF;
  
  -- Obtener secuencias y fecha/hora actual
  SELECT sec_operacion.NEXTVAL,
         sec_permiso.NEXTVAL,
         TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
         TO_CHAR(SYSDATE, 'HH:MI'),
         TO_CHAR(SYSDATE, 'YYYY')
  INTO i_secuencia_operacion,
       i_secuencia_permiso,
       i_fecha,
       i_hora,
       i_id_ano
  FROM dual;
  
  -- Generar enlace para adjuntar fichero
  enlace_fichero := V_ID_ANO || V_ID_FUNCIONARIO || i_secuencia_permiso;
  
  -- Determinar justificación requerida
  IF V_JUSTIFICACION = 'N0' THEN
    BEGIN
      SELECT DECODE(JUSTIFICAcion, 'SI', 'NO', '--')
      INTO V_JUSTIFI
      FROM tr_tipo_permiso
      WHERE id_tipo_permiso = V_ID_TIPO_PERMISO
        AND id_ano = V_ID_ANO
        AND ROWNUM < 2;
        
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        V_JUSTIFI := '--';
    END;
  END IF;

--Configuracion formato_correo
--Descripcion del permiso .
--CHM 14/12/2016
/* envia_correo_informa('2',  V_ID_TIPO_PERMISO,
                       i_nombre_peticion,
                       i_DES_TIPo_PERMISO_larga ,
                       '' , --desc motivo
                       v_fecha_inicio ,
                       v_fecha_fin ,
                       v_hora_inicio ,
                       v_hora_fin ,
                       v_id_grado ,
                       v_id_tipo_dias,
                       v_num_dias,
                       v_mensaje);

 I_message:= v_mensaje;*/
  
  --------------------------------------------------------------------------------
  -- FASE 7: DETERMINAR ESTADO INICIAL SEGÚN JERARQUÍA
  --------------------------------------------------------------------------------
  
  /* Lógica de envío de correos comentada (27/10/2025)
  envia_correo_informa_new('2', V_ID_TIPO_PERMISO,
                       i_nombre_peticion,
                       i_DES_TIPo_PERMISO_larga,
                       '', --desc motivo
                       v_fecha_inicio,
                       v_fecha_fin,
                       v_hora_inicio,
                       v_hora_fin,
                       v_id_grado,
                       v_id_tipo_dias,
                       v_num_dias,
                       v_t1,
                       v_t2,
                       v_t3,
                       V_ID_TIPO_FUNCIONARIO,
                       v_mensaje);
  */
  
  I_message := v_mensaje;
  
  -- Determinar estado según si el peticionario es su propio JA o JS
  IF i_id_ja = V_ID_FUNCIONARIO OR i_id_jS = V_ID_FUNCIONARIO THEN
    -- Peticionario es JA o JS → estado 22 (Pendiente RRHH)
    i_Estado_permiso := C_ESTADO_PENDIENTE_RRHH;
    i_fecha_ja := SYSDATE;
    i_fecha_js := i_fecha_ja;
    
    -- Caso especial bomberos: JA bomberos pero no es el peticionario
    IF i_id_ja = C_ID_JA_BOMBEROS AND i_id_ja <> V_ID_FUNCIONARIO THEN
      i_Estado_permiso := C_ESTADO_PENDIENTE_JA;
      i_recipient := correo_ja;
      i_fecha_ja := '';
      i_id_ja := '';
      i_subject := 'Solicitud de Permiso de: ' || i_nombre_peticion;
    END IF;
    
  ELSE
    -- Funcionario normal → estado 20 (Pendiente Firma JS)
    i_Estado_permiso := C_ESTADO_PENDIENTE_JS;
    
    -- Para bomberos: guardar jefe de guardia
    IF V_ID_TIPO_FUNCIONARIO = C_TIPO_FUNC_BOMBERO THEN
      V_JEFE_GUARDIA := i_id_js;
    ELSE
      i_id_js := '';
    END IF;
    
    i_fecha_js := '';
    i_id_ja := '';
    i_fecha_ja := '';
    i_recipient := correo_js;
    i_subject := 'Solicitud de Permiso de: ' || i_nombre_peticion;
    
  END IF;
  
  -- Caso especial: JS ID especial
  IF i_id_jS = C_ID_JS_ESPECIAL THEN
    i_Estado_permiso := C_ESTADO_PENDIENTE_JS;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 8: INSERTAR PERMISO EN BD
  --------------------------------------------------------------------------------
  
  INSERT INTO permiso (
    id_permiso,
    id_ano,
    id_funcionario,
    id_tipo_permiso,
    id_estado,
    fecha_soli,
    firmado_js,
    fecha_js,
    firmado_ja,
    fecha_ja,
    fecha_inicio,
    fecha_fin,
    num_dias,
    hora_inicio,
    hora_fin,
    total_horas,
    id_tipo_dias,
    dprovincia,
    ID_GRADO,
    ANULADO,
    justificacion,
    id_usuario,
    fecha_modi,
    tu1_14_22,
    tu2_22_06,
    tu3_04_14,
    OBSERVACIONES
  )
  VALUES (
    i_secuencia_permiso,
    V_id_ANO,
    V_ID_FUNCIONARIO,
    V_ID_TIPO_PERMISO,
    i_estado_permiso,
    TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/yy'), 'DD/MM/yy'),
    i_id_js,
    TO_DATE(TO_CHAR(i_fecha_js, 'DD/MM/yy'), 'DD/MM/yy'),
    i_id_ja,
    TO_DATE(TO_CHAR(i_fecha_ja, 'DD/MM/yy'), 'DD/MM/yy'),
    TO_DATE(TO_CHAR(V_FECHA_INICIO, 'DD/MM/YY'), 'DD/MM/yy'),
    TO_DATE(TO_CHAR(V_FECHA_FIN, 'DD/MM/YY'), 'DD/MM/yy'),
    V_NUM_DIAS,
    V_HORA_INICIO,
    V_HORA_FIN,
    v_total_horas,
    V_ID_TIPO_DIAS,
    V_DPROVINCIA,
    V_ID_GRADO,
    'NO',
    V_JUSTIFICACION,
    V_ID_FUNCIONARIO,
    TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/yy'), 'DD/MM/yy'),
    TO_NUMBER(v_t1),
    TO_NUMBER(v_t2),
    TO_NUMBER(v_t3),
    V_GUARDIAS
  );
  
  /*
  --------------------------------------------------------------------------------
  -- ENVÍOS DE CORREOS (COMENTADO 27/10/2025)
  --------------------------------------------------------------------------------
  
  IF i_estado_permiso <> 22 THEN
  
    -- ENVIO DE CORREO AL JEFE DE SERVICIO
    IF correo_js <> 'gmperez@aytosalamanca.es' THEN
      envio_correo(i_sender,
                   i_recipient,
                   I_ccrecipient,
                   i_subject,
                   I_message);
    END IF;
    
    -- Envio correo guardia bomberos
    IF V_ID_TIPO_FUNCIONARIO = 23 THEN
      envio_correo(i_sender,
                   'guardiabomberos@aytosalamanca.es',
                   I_ccrecipient,
                   i_subject,
                   I_message);
    END IF;
    
    -- Envio de correo al suplente si está de vacaciones el principal
    IF chequea_vacaciones_js(i_id_jS) = 1 THEN
      i_recipient := correo_js_delegado;
      envio_correo(i_sender,
                   i_recipient,
                   I_ccrecipient,
                   i_subject || ' .Firma suplente.',
                   I_message);
    END IF;
    
    -- Envio de correo al suplente si puede firmar siempre (múltiples delegados)
    IF i_id_delegado_firma = 1 THEN
      i_recipient := correo_js_delegado;
      envio_correo(i_sender,
                   i_recipient,
                   I_ccrecipient,
                   i_subject || ' .Firma suplente.El permiso puede ser Firmado tambien por otra persona.',
                   I_message);
                   
      i_recipient := correo_js_delegado2;
      envio_correo(i_sender,
                   i_recipient,
                   I_ccrecipient,
                   i_subject || ' .Firma suplente.El permiso puede ser Firmado tambien por otra persona.',
                   I_message);
                   
      i_recipient := correo_js_delegado3;
      envio_correo(i_sender,
                   i_recipient,
                   I_ccrecipient,
                   i_subject || ' .Firma suplente.El permiso puede ser Firmado tambien por otra persona.',
                   I_message);
                   
      i_recipient := correo_js_delegado4;
      envio_correo(i_sender,
                   i_recipient,
                   I_ccrecipient,
                   i_subject || ' .Firma suplente.El permiso puede ser Firmado tambien por otra persona.',
                   I_message);
    END IF;
    
  END IF;  -- FIN ENVIOS CORREOS
  */
  
  --------------------------------------------------------------------------------
  -- FASE 9: AUDITORÍA - INSERTAR EN HISTÓRICO DE OPERACIONES
  --------------------------------------------------------------------------------
  
  INSERT INTO historico_operaciones
  VALUES (
    i_secuencia_operacion,
    i_secuencia_permiso,
    10,
    v_id_ano,
    V_ID_FUNCIONARIO,
    TO_DATE(i_fecha, 'DD/MM/YYYY'),
    i_hora,
    'INSERTA PERMISO',
    V_ID_FUNCIONARIO,
    TO_DATE(i_fecha, 'DD/MM/YYYY')
  );
  
  --------------------------------------------------------------------------------
  -- FINALIZACIÓN EXITOSA
  --------------------------------------------------------------------------------
  
  todo_ok_basico := C_OK;
  msgBasico := 'Permiso solicitado correctamente. ID: ' || i_secuencia_permiso;
  
EXCEPTION
  WHEN OTHERS THEN
    todo_ok_basico := C_ERROR;
    msgBasico := 'Error al insertar permiso: ' || SQLERRM;
    ROLLBACK;
    
END INSERTA_PERMISO_NEW;
/

