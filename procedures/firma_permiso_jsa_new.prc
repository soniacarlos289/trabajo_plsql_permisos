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
  
  --------------------------------------------------------------------------------
  -- FASE 4: BÚSQUEDA Y VALIDACIÓN DE JERARQUÍA DE FIRMAS
  --------------------------------------------------------------------------------
IF v_tipo_funcionario <> '23' then

  --Busco que la persona que firma sea la correcta
  BEGIN
    select id_js, id_delegado_js, id_ja, id_delegado_ja ,id_delegado_firma, id_delegado_js2,id_delegado_js3,id_delegado_js4
      into i_id_js, i_id_delegado_js, i_id_ja, i_id_delegado_ja
           ,i_id_delegado_firma --a�adido 31 mayo 2016. Para poder firmar 2
           ,i_id_delegado_js2,i_id_delegado_js3,i_id_delegado_js4
      from funcionario_firma
     where id_funcionario = i_id_funcionario
       and (id_JS = V_ID_FUNCIONARIO_FIRMA OR
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
  ----a�adido 31 mayo 2016. Para poder firmar cualquiera de los 2. Por ahora solo policias.
  ------ID_DELEGADO_FIRMA---------------------------------------
  ------ 0 Permite firma al delegado cuando el titular no esta
  ------ 1 Permite firmar siempre
  ----------------------------------------------------------------
  --Meter Sustituto.
  IF (i_id_delegado_js = V_ID_FUNCIONARIO_FIRMA AND i_Id_js<>i_id_delegado_js) OR
     (i_id_delegado_js2 = V_ID_FUNCIONARIO_FIRMA AND i_Id_js<>i_id_delegado_js2) OR
     (i_id_delegado_js3 = V_ID_FUNCIONARIO_FIRMA AND i_Id_js<>i_id_delegado_js3) OR
     (i_id_delegado_js4 = V_ID_FUNCIONARIO_FIRMA AND i_Id_js<>i_id_delegado_js4)
    THEN

  --a?adido el 5 de Abril 2010. Funcion nueva /*delegado
  i_contador:= chequeo_entra_delegado(i_id_delegado_js);

    IF i_contador = 0 and i_id_delegado_firma= 0 then ----a�adido 31 mayo 2016. Para poder firmar cualquiera de los  2
      todo_ok_basico := 1;
      msgBasico      := 'Operacion no realizada. La delegacion de permisos solo es efectiva cuando el responable esta de Permiso.';
      RETURN;
    ELSE
       -- i_id_js := i_id_delegado_js;
       IF i_id_delegado_js = V_ID_FUNCIONARIO_FIRMA THEN
          i_id_js := i_id_delegado_js;
       ELSE IF   i_id_delegado_js2 = V_ID_FUNCIONARIO_FIRMA          THEN
               i_id_js := i_id_delegado_js2;
            ELSE IF   i_id_delegado_js3 = V_ID_FUNCIONARIO_FIRMA          THEN
                              i_id_js := i_id_delegado_js3;
                 ELSE IF   i_id_delegado_js4 = V_ID_FUNCIONARIO_FIRMA          THEN
                                           i_id_js := i_id_delegado_js4;
                      END IF;
                 END IF;
            END IF   ;
       END IF;
     END IF;
  END IF;

  IF i_no_hay_firma = -1 then
    todo_ok_basico := 1;
    msgBasico      := 'Operacion no realizada. No hay personas para firmar.';
    RETURN;
  END IF;

  --Buscamos el correo en la usuario.intranet.
  BEGIN
    select MIN(peticion), MIN(nombre_peticion), MIN(js), MIN(ja)
      into correo_v_funcionario, i_nombre_peticion, correo_js, correo_ja

      from (select login || '@aytosalamanca.es' as peticion,substr(  DIST_NAME,  INSTR(DIST_NAME,'=',1) +1,INSTR(DIST_NAME,',',1) -INSTR(DIST_NAME,'=',1)-1) as nombre_peticion,''as js ,'' as ja from apliweb_usuario where id_funcionario=to_char(I_ID_FUNCIONARIO)
     union
     select '' as peticion, '' as nombre_peticion ,login || '@aytosalamanca.es' as js,'' as ja  from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_js,6,'0')
      union
    select '' as peticion ,'' as nombre_peticion ,'' as ja,login || '@aytosalamanca.es' as ja from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_ja,6,'0'))
;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_id_ja := '';
      i_id_js := '';
  END;

  --Si No hay jefes para firmar el permiso.
  IF i_id_js = '' AND i_id_ja = '' then
    todo_ok_basico := 1;
    msgBasico      := 'Operacion no realizada. Pongase en contacto con RRHH. Sin firmas.';
    RETURN;
  END IF;

ELSE
  --a�adido chm 25/02/2017
  --BUSQUEDA FIRMA BOMBEROS
  --a�adir la funci�n
  i_id_ja:='0';
  i_id_js:='0';
  correo_js:='';
  correo_ja:='';

  --600077
  --afiz
  --Comprobamos que esta el jefe de guardia. JA LUIS DAMIAN 961110 ldramos@aytosalamanca.es
  BEGIN --login
    select login || '@aytosalamanca.es',lpad(funcionario,6,'0'),'600077','afiz@aytosalamanca.es'   --'961110','ldramos@aytosalamanca.es'
     into correo_js,i_id_js,i_id_ja,correo_ja
    from --sige.GUARDIAS@lsige s,
     bomberos_guardias_plani s,
     apliweb_usuario a
    where desde =DECODE( trunc(to_char(sysdate+0/24,'hh24')/8),0,
        to_date(to_char(sysdate-1,'DD/mm/yyyy') || '08:00','DD/mm/yyyy hh24:mi') ,
        to_date(to_char(sysdate,'DD/mm/yyyy')   || '08:00','DD/mm/yyyy hh24:mi')

         ) and dotacion='M' and lpad(funcionario,6,'0')=lpad(V_ID_FUNCIONARIO_FIRMA,6,'0')
         and s.funcionario=a.id_funcionario
          and rownum<2;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
     i_id_js:='0';
  END;

  --chm 10/05/2018
  IF V_ID_FUNCIONARIO_FIRMA='961110'   THEN
    i_id_ja:='961110';
    correo_ja:='ldramos@aytosalamanca.es';
  END IF;

  IF V_ID_FUNCIONARIO_FIRMA='600077'  THEN
    i_id_ja:='600077';
    correo_ja:='afiz@aytosalamanca.es';
  END IF;

  IF  i_id_js='0' AND i_id_ja='0' then

        BEGIN
    select login || '@aytosalamanca.es',lpad(id_funcionario,6,'0'),'600077','afiz@aytosalamanca.es'   --'961110','ldramos@aytosalamanca.es'
     into correo_js,i_id_js,i_id_ja,correo_ja
    from  apliweb_usuario a
    where lpad(a.id_funcionario,6,'0')=lpad(V_ID_FUNCIONARIO_FIRMA,6,'0')
          and rownum<2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_id_ja := '';
      i_id_js := '';
  END;
    IF V_ID_FUNCIONARIO_FIRMA='961110'   THEN
    i_id_ja:='961110';
    correo_ja:='ldramos@aytosalamanca.es';
  END IF;

  IF V_ID_FUNCIONARIO_FIRMA='600077'  THEN
    i_id_ja:='600077';
    correo_ja:='afiz@aytosalamanca.es';
  END IF;
  --Si No hay jefes para firmar el permiso.
  IF i_id_js = ''  then
    todo_ok_basico := 1;
    msgBasico      := 'Operacion no realizada. Pongase en contacto con RRHH. Sin firmas.';
    RETURN;
        --cambiado 01/06/2022
        /*todo_ok_basico:=1;
        msgBasico:='No coincide el jefe de la guardia actual con la persona que firma el permiso.';
        RETURN;*/
  END IF;
end if;

--nombre petici�n y correo
--chm 12/02/2017
BEGIN
select  MIN(correo_funcionario) ,MIN(nombre_peticion)
    into correo_v_funcionario,i_nombre_peticion
 from (
     select login || '@aytosalamanca.es' as correo_funcionario ,TRIM(substr(dist_NAME,4,instr(dist_NAME,',',1)-4)) as nombre_peticion from apliweb_usuario
    where lpad(id_funcionario,6,'0')=lpad(to_char(I_ID_FUNCIONARIO),6,'0')
      );

EXCEPTION
     WHEN NO_DATA_FOUND THEN
     correo_v_funcionario:='';
END;



END IF;--FIN NO ES BOMBERO



 --Actualizar permisos
IF ((i_id_estado = 20 AND V_ID_FUNCIONARIO_FIRMA = I_ID_JS) OR
     (i_id_estado = 20 AND V_ID_FUNCIONARIO_FIRMA = I_ID_JA)
     OR (i_id_estado =21  AND v_tipo_funcionario = '23' ) --chm 10/02/2017
     ) then

    --chm 10/02/2017
    if (i_id_estado = 20 and v_tipo_funcionario = '23') then
       i_id_estado:=21;
    else
       --Firma JS
       i_id_estado:=22;
    end if;

    /*quitar */
   -- IF i_id_estado = 22 AND I_ID_JS = 101217 then
          --   i_id_estado:=21;
    --end if;


    IF V_ID_FIRMA = 1 THEN
       if ((i_id_estado = 22  and v_tipo_funcionario <> '23') OR i_id_estado=21 ) then
          --AUTORIZADO--JS
             update permiso
             set id_estado  = i_id_estado,
                 firmado_js = V_ID_FUNCIONARIO_FIRMA,
                 FECHA_JS   = SYsDATE
             where id_funcionario = i_id_funcionario
             and id_permiso = V_id_permiso
             and rownum < 2;
          --busco que la actualizacion sera correcta.
            IF SQL%ROWCOUNT = 0 then
               todo_ok_basico := 1;
                msgBasico      := 'Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                RETURN;
            END IF;
       END IF;--ESTADO 22 y NOES BOMbERO

      if (i_id_estado = 22  and v_tipo_funcionario ='23')  then
          --AUTORIZADO-- JA
             update permiso
             set id_estado  = i_id_estado,
                 firmado_ja = V_ID_FUNCIONARIO_FIRMA,
                 FECHA_Ja   = SYsDATE
             where id_funcionario = i_id_funcionario
             and id_permiso = V_id_permiso
             and rownum < 2;
          --busco que la actualizacion sera correcta.
            IF SQL%ROWCOUNT = 0 then
               todo_ok_basico := 1;
                msgBasico      := 'Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                RETURN;
            END IF;
       END IF;--ESTADO 22 y NOES BOMbERO


      --ENVIO DE CORREO AL JEFE DE AREA
      i_sender      := correo_js;
      I_ccrecipient := '';
      i_recipient   := correo_ja;
      I_message := '';


      --chm 10/02/2017,Autorizado JEFE DE gUARDIA
      envia_correo_informa_new('1',  V_ID_TIPO_PERMISO,
                       i_nombre_peticion,
                       i_DESC_TIPO_PERMISO,
                       '' , --desc motivo
                       v_fecha_inicio ,
                       v_fecha_fin ,
                       v_hora_inicio ,
                       v_hora_fin ,
                       v_id_grado ,
                       v_id_tipo_dias,
                       v_num_dias,
                       v_t1,
                       v_t2,
                       v_t3,
                       V_TIPO_FUNCIONARIO,
                       v_mensaje);

       I_message:= v_mensaje;
    i_firma := 'Operacion realizada. El permiso esta pendiente del V�B� de RRHH.';
      --chm 10/02/2017
      --Envio correo al ja, para el 2� nivel.
    if (i_id_estado = 21 and v_tipo_funcionario = '23') then
   i_firma := 'Operacion realizada. El permiso esta pendiente del V�B� Jefe de Bomberos.';
        envio_correo(i_sender ,
               i_recipient ,
               I_ccrecipient ,
               i_subject  ,
               I_message);
    end if;

      --Insert en el historico
      insert into historico_operaciones
      values
        (sec_operacion.nextval,
         V_ID_PERMISO,
         20,
         i_id_ano,
         V_ID_FUNCIONARIO_FIRMA,
         to_char(sysdate, 'DD/MM/YYYY'),
         to_char(sysdate, 'HH:MI'),
         'FIRMA PERMISO JSA',
         V_ID_FUNCIONARIO_FIrMA,
         to_char(sysdate, 'DD/MM/YYYY'));

   --   i_firma := 'Operacion realizada. El permiso esta pendiente del V?B? de RRHH.';

    ELSE
      IF V_ID_FIRMA = 0 THEN
        --denegado '961110 luis damian
        --600077 antonio fiz
       IF  ( '600077' <> V_ID_FUNCIONARIO_FIRMA OR v_tipo_funcionario <>'23') THEN
        update permiso
           set id_estado     = 30,
               firmado_js    = V_ID_FUNCIONARIO_FIRMA,
               motivo_denega = V_ID_MOTIVO,
               FECHA_JS      = SYsDATE
         where id_funcionario = i_id_funcionario
           and id_permiso = V_id_permiso
           and rownum < 2;
        --busco que la actualizacion sera correcta.
        IF SQL%ROWCOUNT = 0 then
          todo_ok_basico := 1;
          msgBasico      := 'Operacion no realizada.Pongase contacto RRHH. Error Update PERMISO linea 219. ';
          RETURN;
        END IF;
       ELSE  --BOMBEROS DENEGACION JA
         update permiso
           set id_estado     = 31,
               firmado_ja    = V_ID_FUNCIONARIO_FIRMA,
               motivo_denega = V_ID_MOTIVO,
               FECHA_Ja      = SYsDATE
         where id_funcionario = i_id_funcionario
           and id_permiso = V_id_permiso
           and rownum < 2;
        --busco que la actualizacion sera correcta.
        IF SQL%ROWCOUNT = 0 then
          todo_ok_basico := 1;
          msgBasico      := 'Operacion no realizada.Pongase contacto RRHH. Error Update PERMISO linea 219. ';
          RETURN;
        END IF;
       END IF;
        --ENVIO DE CORREO AL FUNCIONARIO CON LA DENEGACION
        i_sender      := correo_js;
        I_ccrecipient := '';
        i_recipient   := correo_v_funcionario;
        I_message     := '';

         --chm 14/02/2017,DENEGACION
         envia_correo_informa_new('0',  V_ID_TIPO_PERMISO,
                       i_nombre_peticion,
                       i_DESC_TIPo_PERMISO,
                       v_id_motivo ,
                       v_fecha_inicio ,
                       v_fecha_fin ,
                       v_hora_inicio ,
                       v_hora_fin ,
                       v_id_grado ,
                       v_id_tipo_dias,
                       v_num_dias,
                       v_t1,
                       v_t2,
                       v_t3,
                       V_TIPO_FUNCIONARIO,
                       v_mensaje);

        I_message := V_mensaje;

        --chm13/02/2017
        -- 961110
         IF  ( '600077' = V_ID_FUNCIONARIO_FIRMA) THEN
                  i_subject := 'Denegacion de Permiso por el Jefe de Bomberos.';
                  i_sender:=correo_ja;
         ELSE  IF  v_tipo_funcionario ='23' then
                  i_subject := 'Denegacion de Permiso por el Jefe Guardia.';
               ELSE
                  i_subject := 'Denegacion de Permiso por el Jefe de Secc/Serv.';
               END IF;
         END IF;
        envio_correo(i_sender,
                     i_recipient,
                     I_ccrecipient,
                     i_subject,
                     I_message);

        --Insert en el historico
        insert into historico_operaciones
        values
          (sec_operacion.nextval,
           V_ID_PERMISO,
           30,
           i_id_ano,
           V_ID_FUNCIONARIO_FIRMA,
           to_char(sysdate, 'DD/MM/YYYY'),
           to_char(sysdate, 'HH:MI'),
           'FIRMA PERMISO JSA',
           V_ID_FUNCIONARIO_FIrMA,
           to_char(sysdate, 'DD/MM/YYYY'));

        -- Actualizo el permiso si es UNICO
        permiso_denegado(v_id_permiso, todo_ok_basico, msgbasico);
        IF todo_ok_basico = 1 THEN
          RETURN;
        ELSE
          i_firma := 'Operacion realizada. El permiso se ha denegado correctamente.';
        END IF;

      END IF;
    END IF;

  END IF;

  todo_ok_basico := 0;
  msgBasico      := i_firma;
  commit;


end FIRMA_PERMISO_JSA_NEW;
/

