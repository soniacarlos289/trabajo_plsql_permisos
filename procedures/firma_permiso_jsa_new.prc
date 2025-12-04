--------------------------------------------------------------------------------
-- PROCEDURE: FIRMA_PERMISO_JSA_NEW
--------------------------------------------------------------------------------
-- Propósito: Procesar firma de permiso por Jefe de Sección (JS) o Jefe de Área (JA)
-- Autor: RRHH / Optimizado por Carlos (04/12/2025)
-- Versión: 2.0.0
--
-- Descripción:
--   Gestiona las firmas de autorización o denegación de permisos por parte
--   de los responsables jerárquicos (JS/JA).
--
--   Funcionalidades principales:
--   - Validación de permisos existentes y estado correcto
--   - Verificación de jerarquía de firmas (titular/delegados)
--   - Lógica especial para BOMBEROS (jefe de guardia actual)
--   - Soporte para múltiples delegados (4 niveles)
--   - Delegación activa solo cuando titular está de permiso (modo 0)
--   - Delegación permanente (modo 1) para ciertos colectivos
--   - Actualización de estado según nivel jerárquico
--   - Notificaciones por correo electrónico
--   - Auditoría en histórico de operaciones
--
-- Estados gestionados:
--   20 - Pendiente Firma JS → 22 (Pde RRHH) o 21 (Pde JA bomberos)
--   21 - Pendiente Firma JA → 22 (Pde RRHH)
--   30 - Rechazado JS
--   31 - Rechazado JA
--
-- Parámetros:
--   V_ID_FIRMA             - 1=Autorizar, 0=Denegar (IN)
--   V_ID_FUNCIONARIO_FIRMA - ID del jefe que firma (IN)
--   V_ID_PERMISO           - ID del permiso a firmar (IN)
--   V_ID_MOTIVO            - Motivo si deniega (IN)
--   todo_ok_Basico         - 0=OK, 1=Error (OUT)
--   msgBasico              - Mensaje resultado (OUT)
--
-- Historial:
--   04/12/2025 - Carlos - Optimización v2.0
--   01/06/2022 - CHM - Ajuste validación bomberos
--   10/05/2018 - CHM - IDs específicos JA bomberos (961110, 600077)
--   10/02/2017 - CHM - Añadida lógica bomberos
--   31/05/2016 - CHM - Modo delegación permanente (id_delegado_firma=1)
--   05/04/2010 - CHM - Función chequeo_entra_delegado
--------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE RRHH.FIRMA_PERMISO_JSA_NEW (
  V_ID_FIRMA             IN VARCHAR2,
  V_ID_FUNCIONARIO_FIRMA IN NUMBER,
  V_ID_PERMISO           IN NUMBER,
  V_ID_MOTIVO            IN VARCHAR2,
  todo_ok_Basico         OUT INTEGER,
  msgBasico              OUT VARCHAR2
) IS

  --------------------------------------------------------------------------------
  -- CONSTANTES
  --------------------------------------------------------------------------------
  C_OK CONSTANT INTEGER := 0;
  C_ERROR CONSTANT INTEGER := 1;
  
  -- Estados
  C_ESTADO_PENDIENTE_JS CONSTANT NUMBER := 20;
  C_ESTADO_PENDIENTE_JA CONSTANT NUMBER := 21;
  C_ESTADO_PENDIENTE_RRHH CONSTANT NUMBER := 22;
  C_ESTADO_RECHAZADO_JS CONSTANT NUMBER := 30;
  C_ESTADO_RECHAZADO_JA CONSTANT NUMBER := 31;
  
  -- Tipos especiales
  C_TIPO_FUNC_BOMBERO CONSTANT VARCHAR2(2) := '23';
  C_PERMISO_COMPENSATORIO CONSTANT VARCHAR2(5) := '15000';
  C_EMAIL_DOMAIN CONSTANT VARCHAR2(20) := '@aytosalamanca.es';
  
  -- IDs específicos bomberos
  C_ID_JA_BOMBEROS_1 CONSTANT VARCHAR2(6) := '961110'; -- Luis Damián Ramos
  C_ID_JA_BOMBEROS_2 CONSTANT VARCHAR2(6) := '600077'; -- Antonio Fiz
  C_EMAIL_JA_BOMBEROS_1 CONSTANT VARCHAR2(50) := 'ldramos@aytosalamanca.es';
  C_EMAIL_JA_BOMBEROS_2 CONSTANT VARCHAR2(50) := 'afiz@aytosalamanca.es';
  
  -- Modos de delegación
  C_DELEGACION_PERMISO CONSTANT NUMBER := 0; -- Solo cuando titular está de permiso
  C_DELEGACION_PERMANENTE CONSTANT NUMBER := 1; -- Siempre puede firmar
  
  --------------------------------------------------------------------------------
  -- VARIABLES LOCALES
  --------------------------------------------------------------------------------
  
  -- Control de existencia
  i_no_hay_permisos NUMBER;
  i_no_hay_firma NUMBER;
  i_contador NUMBER;
  
  -- Datos del permiso
  i_id_funcionario VARCHAR2(6);
  i_id_estado VARCHAR2(2);
  i_id_ano NUMBER(4);
  i_dias NUMBER(4);
  v_id_tipo_permiso VARCHAR2(5);
  v_id_tipo_dias VARCHAR2(1);
  v_num_dias NUMBER;
  v_fecha_inicio DATE;
  v_fecha_fin DATE;
  V_HORA_INICIO VARCHAR2(5);
  V_HORA_FIN VARCHAR2(5);
  V_ID_GRADO VARCHAR2(300);
  v_tipo_funcionario VARCHAR2(10);
  v_t1 VARCHAR2(5);
  v_t2 VARCHAR2(5);
  v_t3 VARCHAR2(5);
  
  -- Jerarquía de firmas
  i_id_js VARCHAR2(6);
  i_id_delegado_js VARCHAR2(6);
  i_id_delegado_js2 VARCHAR2(6);
  i_id_delegado_js3 VARCHAR2(6);
  i_id_delegado_js4 VARCHAR2(6);
  i_id_ja VARCHAR2(6);
  i_id_delegado_ja VARCHAR2(6);
  i_id_delegado_firma VARCHAR2(6);
  
  -- Correos y mensajes
  correo_v_funcionario VARCHAR2(100);
  i_nombre_peticion VARCHAR2(200);
  correo_js VARCHAR2(100);
  correo_ja VARCHAR2(100);
  i_sender VARCHAR2(100);
  i_recipient VARCHAR2(100);
  I_ccrecipient VARCHAR2(100);
  i_subject VARCHAR2(200);
  I_message VARCHAR2(4000);
  v_mensaje VARCHAR2(4000);
  
  -- Descriptivos
  i_DESC_TIPO_PERMISO VARCHAR2(200);
  i_CADENA2 VARCHAR2(500);
  i_firma VARCHAR2(200);

BEGIN
  
  --------------------------------------------------------------------------------
  -- FASE 1: INICIALIZACIÓN
  --------------------------------------------------------------------------------
  
  todo_ok_basico := C_OK;
  msgBasico := '';

  --------------------------------------------------------------------------------
  -- FASE 2: VALIDAR EXISTENCIA Y ESTADO DEL PERMISO
  --------------------------------------------------------------------------------
  
  i_no_hay_permisos := 0;
  
  BEGIN
    SELECT HORA_INICIO,
           HORA_FIN,
           ID_GRADO,
           p.FECHA_INICIO,
           p.fecha_fin,
           p.NUM_DIAS,
           p.id_tipo_dias,
           p.id_tipo_permiso,
           p.id_ano,
           id_estado,
           id_funcionario,
           DES_TIPO_PERMISO_LARGA,
           DECODE(p.id_tipo_permiso,
                  '15000',
                  'Fecha Inicio: ' || TO_CHAR(p.FECHA_INICIO, 'DD-MON-YY') ||
                  CHR(10) || 'Hora de Inicio: ' || HORA_INICIO || CHR(10) ||
                  'Hora Fin: ' || HORA_FIN,
                  'Fecha Inicio: ' || TO_CHAR(p.FECHA_INICIO, 'DD-MON-YY') ||
                  CHR(10) || 'Fecha Fin:    ' ||
                  TO_CHAR(p.FECHA_FIN, 'DD-MON-YY') || CHR(10) ||
                  'Numero de Dias: ' || p.NUM_DIAS),
           p.NUM_DIAS,
           tu1_14_22,
           tu2_22_06,
           tu3_04_14
    INTO V_HORA_INICIO,
         V_HORA_FIN,
         V_ID_GRADO,
         v_fecha_inicio,
         v_fecha_fin,
         V_num_DIAs,
         v_id_tipo_dias,
         v_id_tipo_permiso,
         i_id_ano,
         i_id_estado,
         i_id_funcionario,
         i_DESC_TIPO_PERMISO,
         i_CADENA2,
         i_dias,
         v_t1,
         v_t2,
         v_t3
    FROM permiso p, tr_tipo_permiso tr
    WHERE id_permiso = v_id_permiso
      AND tr.id_ano = p.id_ano
      AND p.id_tipo_permiso = tr.id_tipo_permiso
      AND (anulado = 'NO' OR ANULADO IS NULL);
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_no_hay_permisos := -1;
  END;
  
  IF i_no_hay_permisos = -1 THEN
    todo_ok_basico := C_ERROR;
    msgBasico := 'Operacion no realizada. Permiso no existe.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 3: OBTENER TIPO DE FUNCIONARIO
  --------------------------------------------------------------------------------
  
  v_tipo_funcionario := '10';
  
  BEGIN
    SELECT tipo_funcionario2
    INTO v_tipo_funcionario
    FROM personal_new
    WHERE id_funcionario = i_id_funcionario
      AND ROWNUM < 2;
      
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_tipo_funcionario := '-1';
  END;
  
  IF v_tipo_funcionario = '-1' THEN
    todo_ok_basico := C_ERROR;
    msgBasico := 'Operacion no realizada. TIPO FUNCIONARIO NO ENCONTRADO.';
    RETURN;
  END IF;
  
  IF v_tipo_funcionario = '-1' THEN
    todo_ok_basico := C_ERROR;
    msgBasico := 'Operacion no realizada. TIPO FUNCIONARIO NO ENCONTRADO.';
    RETURN;
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 5: BÚSQUEDA Y VALIDACIÓN DE JERARQUÍA DE FIRMAS
  --------------------------------------------------------------------------------
  
  IF v_tipo_funcionario <> C_TIPO_FUNC_BOMBERO THEN
    
    -- Funcionarios regulares: validar JS/JA con delegados
    BEGIN
      SELECT id_js,
             id_delegado_js,
             id_ja,
             id_delegado_ja,
             id_delegado_firma,
             id_delegado_js2,
             id_delegado_js3,
             id_delegado_js4
      INTO   i_id_js,
             i_id_delegado_js,
             i_id_ja,
             i_id_delegado_ja,
             i_id_delegado_firma,
             i_id_delegado_js2,
             i_id_delegado_js3,
             i_id_delegado_js4
      FROM   funcionario_firma
      WHERE  id_funcionario = i_id_funcionario
        AND  (id_JS = V_ID_FUNCIONARIO_FIRMA OR
              id_DELEGADO_JS = V_ID_FUNCIONARIO_FIRMA OR
              id_DELEGADO_JS2 = V_ID_FUNCIONARIO_FIRMA OR
              id_DELEGADO_JS3 = V_ID_FUNCIONARIO_FIRMA OR
              id_DELEGADO_JS4 = V_ID_FUNCIONARIO_FIRMA OR
              id_JA = V_ID_FUNCIONARIO_FIRMA OR
              id_DELEGADO_JA = V_ID_FUNCIONARIO_FIRMA);
              
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_no_hay_firma := -1;
    END;
    
    -- Validar delegados con chequeo_entra_delegado
    -- ID_DELEGADO_FIRMA: 0=Solo cuando titular está de permiso, 1=Siempre
    IF (i_id_delegado_js = V_ID_FUNCIONARIO_FIRMA AND i_Id_js <> i_id_delegado_js) OR
       (i_id_delegado_js2 = V_ID_FUNCIONARIO_FIRMA AND i_Id_js <> i_id_delegado_js2) OR
       (i_id_delegado_js3 = V_ID_FUNCIONARIO_FIRMA AND i_Id_js <> i_id_delegado_js3) OR
       (i_id_delegado_js4 = V_ID_FUNCIONARIO_FIRMA AND i_Id_js <> i_id_delegado_js4) THEN
      
      -- Verificar si delegado puede firmar (titular de permiso?)
      i_contador := chequeo_entra_delegado(i_id_delegado_js);
      
      IF i_contador = 0 AND i_id_delegado_firma = 0 THEN
        todo_ok_basico := C_ERROR;
        msgBasico := 'Operacion no realizada. La delegacion de permisos solo es efectiva cuando el responsable esta de Permiso.';
        RETURN;
      ELSE
        -- Asignar delegado correspondiente como JS efectivo
        IF i_id_delegado_js = V_ID_FUNCIONARIO_FIRMA THEN
          i_id_js := i_id_delegado_js;
        ELSIF i_id_delegado_js2 = V_ID_FUNCIONARIO_FIRMA THEN
          i_id_js := i_id_delegado_js2;
        ELSIF i_id_delegado_js3 = V_ID_FUNCIONARIO_FIRMA THEN
          i_id_js := i_id_delegado_js3;
        ELSIF i_id_delegado_js4 = V_ID_FUNCIONARIO_FIRMA THEN
          i_id_js := i_id_delegado_js4;
        END IF;
      END IF;
    END IF;
    
    IF i_no_hay_firma = -1 THEN
      todo_ok_basico := C_ERROR;
      msgBasico := 'Operacion no realizada. No hay personas para firmar.';
      RETURN;
    END IF;
    
    -- Obtener correos electrónicos (funcionario, JS, JA)
    BEGIN
      SELECT MIN(peticion),
             MIN(nombre_peticion),
             MIN(js),
             MIN(ja)
      INTO   correo_v_funcionario,
             i_nombre_peticion,
             correo_js,
             correo_ja
      FROM (
        SELECT login || C_EMAIL_DOMAIN AS peticion,
               SUBSTR(DIST_NAME, INSTR(DIST_NAME, '=', 1) + 1,
                      INSTR(DIST_NAME, ',', 1) - INSTR(DIST_NAME, '=', 1) - 1) AS nombre_peticion,
               '' AS js,
               '' AS ja
        FROM   apliweb_usuario
        WHERE  id_funcionario = TO_CHAR(i_ID_FUNCIONARIO)
        UNION
        SELECT '' AS peticion,
               '' AS nombre_peticion,
               login || C_EMAIL_DOMAIN AS js,
               '' AS ja
        FROM   apliweb_usuario
        WHERE  LPAD(id_funcionario, 6, '0') = LPAD(i_id_js, 6, '0')
        UNION
        SELECT '' AS peticion,
               '' AS nombre_peticion,
               '' AS ja,
               login || C_EMAIL_DOMAIN AS ja
        FROM   apliweb_usuario
        WHERE  LPAD(id_funcionario, 6, '0') = LPAD(i_id_ja, 6, '0')
      );
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_id_ja := '';
        i_id_js := '';
    END;
    
    IF i_id_js = '' AND i_id_ja = '' THEN
      todo_ok_basico := C_ERROR;
      msgBasico := 'Operacion no realizada. Pongase en contacto con RRHH. Sin firmas.';
      RETURN;
    END IF;
    IF i_id_js = '' AND i_id_ja = '' THEN
      todo_ok_basico := C_ERROR;
      msgBasico := 'Operacion no realizada. Pongase en contacto con RRHH. Sin firmas.';
      RETURN;
    END IF;
    
  --------------------------------------------------------------------------------
  -- FASE 6: LÓGICA ESPECIAL BOMBEROS
  --------------------------------------------------------------------------------
  
  ELSE
    
    -- Bomberos: buscar jefe de guardia actual y JA bomberos
    i_id_ja := '0';
    i_id_js := '0';
    correo_js := '';
    correo_ja := '';
    
    -- Verificar si firmante es Jefe de Guardia actual en dotación M (mañana)
    BEGIN
      SELECT login || C_EMAIL_DOMAIN,
             LPAD(funcionario, 6, '0'),
             C_ID_JA_BOMBEROS_2,
             'afiz' || C_EMAIL_DOMAIN
      INTO   correo_js,
             i_id_js,
             i_id_ja,
             correo_ja
      FROM   bomberos_guardias_plani s, apliweb_usuario a
      WHERE  desde = DECODE(TRUNC(TO_CHAR(SYSDATE + 0/24, 'hh24') / 8), 0,
                            TO_DATE(TO_CHAR(SYSDATE - 1, 'DD/mm/yyyy') || '08:00', 'DD/mm/yyyy hh24:mi'),
                            TO_DATE(TO_CHAR(SYSDATE, 'DD/mm/yyyy') || '08:00', 'DD/mm/yyyy hh24:mi'))
        AND  dotacion = 'M'
        AND  LPAD(funcionario, 6, '0') = LPAD(V_ID_FUNCIONARIO_FIRMA, 6, '0')
        AND  s.funcionario = a.id_funcionario
        AND  ROWNUM < 2;
        
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_id_js := '0';
    END;
    
    -- Casos especiales: JA Bomberos (Luis Damián Ramos o Antonio Fiz)
    IF V_ID_FUNCIONARIO_FIRMA = C_ID_JA_BOMBEROS_1 THEN
      i_id_ja := C_ID_JA_BOMBEROS_1;
      correo_ja := 'ldramos' || C_EMAIL_DOMAIN;
    END IF;
    
    IF V_ID_FUNCIONARIO_FIRMA = C_ID_JA_BOMBEROS_2 THEN
      i_id_ja := C_ID_JA_BOMBEROS_2;
      correo_ja := 'afiz' || C_EMAIL_DOMAIN;
    END IF;
    
    -- Si no es ni Jefe Guardia ni JA, buscar en apliweb_usuario
    IF i_id_js = '0' AND i_id_ja = '0' THEN
      
      BEGIN
        SELECT login || C_EMAIL_DOMAIN,
               LPAD(id_funcionario, 6, '0'),
               C_ID_JA_BOMBEROS_2,
               'afiz' || C_EMAIL_DOMAIN
        INTO   correo_js,
               i_id_js,
               i_id_ja,
               correo_ja
        FROM   apliweb_usuario a
        WHERE  LPAD(a.id_funcionario, 6, '0') = LPAD(V_ID_FUNCIONARIO_FIRMA, 6, '0')
          AND  ROWNUM < 2;
          
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_id_ja := '';
          i_id_js := '';
      END;
      
      -- Revalidar casos especiales JA
      IF V_ID_FUNCIONARIO_FIRMA = C_ID_JA_BOMBEROS_1 THEN
        i_id_ja := C_ID_JA_BOMBEROS_1;
        correo_ja := 'ldramos' || C_EMAIL_DOMAIN;
      END IF;
      
      IF V_ID_FUNCIONARIO_FIRMA = C_ID_JA_BOMBEROS_2 THEN
        i_id_ja := C_ID_JA_BOMBEROS_2;
        correo_ja := 'afiz' || C_EMAIL_DOMAIN;
      END IF;
      
      IF i_id_js = '' THEN
        todo_ok_basico := C_ERROR;
        msgBasico := 'Operacion no realizada. Pongase en contacto con RRHH. Sin firmas.';
        RETURN;
      END IF;
      
    END IF;
    
    -- Obtener nombre y correo del peticionario bombero
    BEGIN
      SELECT MIN(correo_funcionario),
             MIN(nombre_peticion)
      INTO   correo_v_funcionario,
             i_nombre_peticion
      FROM (
        SELECT login || C_EMAIL_DOMAIN AS correo_funcionario,
               TRIM(SUBSTR(dist_NAME, 4, INSTR(dist_NAME, ',', 1) - 4)) AS nombre_peticion
        FROM   apliweb_usuario
        WHERE  LPAD(id_funcionario, 6, '0') = LPAD(TO_CHAR(i_ID_FUNCIONARIO), 6, '0')
      );
      
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        correo_v_funcionario := '';
    END;
    
  END IF; -- FIN VALIDACIÓN BOMBEROS/REGULARES

  END IF; -- FIN VALIDACIÓN BOMBEROS/REGULARES
  
  --------------------------------------------------------------------------------
  -- FASE 7: DETERMINAR PRÓXIMO ESTADO Y ACTUALIZAR PERMISO
  --------------------------------------------------------------------------------
  
  IF ((i_id_estado = C_ESTADO_PENDIENTE_JS AND V_ID_FUNCIONARIO_FIRMA = i_ID_JS) OR
      (i_id_estado = C_ESTADO_PENDIENTE_JS AND V_ID_FUNCIONARIO_FIRMA = i_ID_JA) OR
      (i_id_estado = C_ESTADO_PENDIENTE_JA AND v_tipo_funcionario = C_TIPO_FUNC_BOMBERO)) THEN
    
    -- Determinar próximo estado según tipo funcionario
    IF i_id_estado = C_ESTADO_PENDIENTE_JS AND v_tipo_funcionario = C_TIPO_FUNC_BOMBERO THEN
      -- Bomberos: 20 → 21 (Pendiente JA Bomberos)
      i_id_estado := C_ESTADO_PENDIENTE_JA;
    ELSE
      -- Regulares: 20 → 22 (Pendiente Vo RRHH)
      i_id_estado := C_ESTADO_PENDIENTE_RRHH;
    END IF;
    
    --------------------------------------------------------------------------------
    -- FASE 8: AUTORIZACIÓN O DENEGACIÓN
    --------------------------------------------------------------------------------
    
    IF V_ID_FIRMA = '1' THEN
      
      -- =========================================================================
      -- OPCIÓN 1: AUTORIZADO
      -- =========================================================================
      
      IF (i_id_estado = C_ESTADO_PENDIENTE_RRHH AND v_tipo_funcionario <> C_TIPO_FUNC_BOMBERO) OR
         i_id_estado = C_ESTADO_PENDIENTE_JA THEN
        
        -- Actualizar estado y firma JS
        UPDATE permiso
        SET    id_estado = i_id_estado,
               firmado_js = V_ID_FUNCIONARIO_FIRMA,
               FECHA_JS = SYSDATE
        WHERE  id_funcionario = i_id_funcionario
          AND  id_permiso = V_id_permiso
          AND  ROWNUM < 2;
        
        IF SQL%ROWCOUNT = 0 THEN
          todo_ok_basico := C_ERROR;
          msgBasico := 'Operacion no realizada. Pongase contacto RRHH. Error Update Firma.';
          RETURN;
        END IF;
        
      END IF;
      
      IF i_id_estado = C_ESTADO_PENDIENTE_RRHH AND v_tipo_funcionario = C_TIPO_FUNC_BOMBERO THEN
        
        -- Bomberos: actualizar firma JA
        UPDATE permiso
        SET    id_estado = i_id_estado,
               firmado_ja = V_ID_FUNCIONARIO_FIRMA,
               FECHA_Ja = SYSDATE
        WHERE  id_funcionario = i_id_funcionario
          AND  id_permiso = V_id_permiso
          AND  ROWNUM < 2;
        
        IF SQL%ROWCOUNT = 0 THEN
          todo_ok_basico := C_ERROR;
          msgBasico := 'Operacion no realizada. Pongase contacto RRHH. Error Update Firma.';
          RETURN;
        END IF;
        
      END IF;
      
      --------------------------------------------------------------------------------
      -- FASE 9: ENVIAR NOTIFICACIONES DE AUTORIZACIÓN
      --------------------------------------------------------------------------------
      
      -- Construir mensaje autorización
      envia_correo_informa_new(
        '1',
        V_ID_TIPO_PERMISO,
        i_nombre_peticion,
        i_DESC_TIPO_PERMISO,
        '',
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
        V_TIPO_FUNCIONARIO,
        v_mensaje
      );
      
      i_sender := correo_js;
      I_ccrecipient := '';
      i_recipient := correo_ja;
      I_message := v_mensaje;
      i_firma := 'Operacion realizada. El permiso esta pendiente del V°B° de RRHH.';
      
      -- Bomberos: enviar correo a JA para 2º nivel
      IF i_id_estado = C_ESTADO_PENDIENTE_JA AND v_tipo_funcionario = C_TIPO_FUNC_BOMBERO THEN
        i_firma := 'Operacion realizada. El permiso esta pendiente del V°B° Jefe de Bomberos.';
        envio_correo(
          i_sender,
          i_recipient,
          I_ccrecipient,
          i_subject,
          I_message
        );
      END IF;
      
      -- Registrar en histórico
      INSERT INTO historico_operaciones
      VALUES (
        sec_operacion.NEXTVAL,
        V_ID_PERMISO,
        C_ESTADO_PENDIENTE_JS,
        i_id_ano,
        V_ID_FUNCIONARIO_FIRMA,
        TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
        TO_CHAR(SYSDATE, 'HH:MI'),
        'FIRMA PERMISO JSA',
        V_ID_FUNCIONARIO_FIrMA,
        TO_CHAR(SYSDATE, 'DD/MM/YYYY')
      );
      
    ELSE
      
      -- =========================================================================
      -- OPCIÓN 2: DENEGADO
      -- =========================================================================
      
      IF V_ID_FIRMA = '0' THEN
        
        -- Bomberos JA: estado 31 (Rechazado JA)
        IF C_ID_JA_BOMBEROS_2 = V_ID_FUNCIONARIO_FIRMA THEN
          
          UPDATE permiso
          SET    id_estado = C_ESTADO_RECHAZADO_JA,
                 firmado_ja = V_ID_FUNCIONARIO_FIRMA,
                 motivo_denega = V_ID_MOTIVO,
                 FECHA_Ja = SYSDATE
          WHERE  id_funcionario = i_id_funcionario
            AND  id_permiso = V_id_permiso
            AND  ROWNUM < 2;
          
          IF SQL%ROWCOUNT = 0 THEN
            todo_ok_basico := C_ERROR;
            msgBasico := 'Operacion no realizada. Pongase contacto RRHH. Error Update PERMISO.';
            RETURN;
          END IF;
          
        ELSE
          
          -- Regulares: estado 30 (Rechazado JS)
          UPDATE permiso
          SET    id_estado = C_ESTADO_RECHAZADO_JS,
                 firmado_js = V_ID_FUNCIONARIO_FIRMA,
                 motivo_denega = V_ID_MOTIVO,
                 FECHA_JS = SYSDATE
          WHERE  id_funcionario = i_id_funcionario
            AND  id_permiso = V_id_permiso
            AND  ROWNUM < 2;
          
          IF SQL%ROWCOUNT = 0 THEN
            todo_ok_basico := C_ERROR;
            msgBasico := 'Operacion no realizada. Pongase contacto RRHH. Error Update PERMISO.';
            RETURN;
          END IF;
          
        END IF;
        
        --------------------------------------------------------------------------------
        -- FASE 10: ENVIAR NOTIFICACIONES DE DENEGACIÓN
        --------------------------------------------------------------------------------
        
        -- Construir mensaje denegación
        envia_correo_informa_new(
          '0',
          V_ID_TIPO_PERMISO,
          i_nombre_peticion,
          i_DESC_TIPo_PERMISO,
          v_id_motivo,
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
          V_TIPO_FUNCIONARIO,
          v_mensaje
        );
        
        i_sender := correo_js;
        I_ccrecipient := '';
        i_recipient := correo_v_funcionario;
        I_message := v_mensaje;
        
        -- Determinar subject según firmante
        IF C_ID_JA_BOMBEROS_2 = V_ID_FUNCIONARIO_FIRMA THEN
          i_subject := 'Denegacion de Permiso por el Jefe de Bomberos.';
          i_sender := correo_ja;
        ELSIF v_tipo_funcionario = C_TIPO_FUNC_BOMBERO THEN
          i_subject := 'Denegacion de Permiso por el Jefe Guardia.';
        ELSE
          i_subject := 'Denegacion de Permiso por el Jefe de Secc/Serv.';
        END IF;
        
        envio_correo(
          i_sender,
          i_recipient,
          I_ccrecipient,
          i_subject,
          I_message
        );
        
        -- Registrar en histórico
        INSERT INTO historico_operaciones
        VALUES (
          sec_operacion.NEXTVAL,
          V_ID_PERMISO,
          C_ESTADO_RECHAZADO_JS,
          i_id_ano,
          V_ID_FUNCIONARIO_FIRMA,
          TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
          TO_CHAR(SYSDATE, 'HH:MI'),
          'FIRMA PERMISO JSA',
          V_ID_FUNCIONARIO_FIrMA,
          TO_CHAR(SYSDATE, 'DD/MM/YYYY')
        );
        
        -- Revertir descuento de bolsa si permiso único
        permiso_denegado(v_id_permiso, todo_ok_basico, msgbasico);
        
        IF todo_ok_basico = C_ERROR THEN
          RETURN;
        ELSE
          i_firma := 'Operacion realizada. El permiso se ha denegado correctamente.';
        END IF;
        
      END IF;
      
    END IF;
    
  END IF;
  
  todo_ok_basico := C_EXITO;
  msgBasico := i_firma;
  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error en firma_permiso_jsa_new: ' || SQLERRM);
    ROLLBACK;
    todo_ok_basico := C_ERROR;
    msgBasico := 'Error en firma_permiso_jsa_new: ' || SQLERRM;
    
END FIRMA_PERMISO_JSA_NEW;
/

