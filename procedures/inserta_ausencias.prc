CREATE OR REPLACE PROCEDURE RRHH."INSERTA_AUSENCIAS"
       (V_ID_ANO in number,
        V_ID_FUNCIONARIO in number,
        V_ID_TIPO_FUNCIONARIO in number,
        V_ID_TIPO_AUSENCIA in varchar2,
        V_FECHA_INICIO in DATE,
        V_FECHA_FIN in DATE,
        V_HORA_INICIO  in varchar2,
        V_HORA_FIN  in varchar2,
        V_JUSTIFICACION in varchar2,
        v_total_horas in number,
        todo_ok_Basico out integer,msgBasico out varchar2) is

i_hora_inicio number;
i_hora_fin number;
i_no_hay_permisos number;
i_num_dias number;
i_id_tipo_dias number;
i_unico varchar2(2);
i_resta_fechas number;
i_contador_laboral number;
i_contador_natural number;
i_contador number;
i_id_js  varchar2(6);
i_id_delegado_js varchar2(6);
i_id_ja  varchar2(6);
i_id_delegado_ja    varchar2(6);
i_id_delegado_firma number;
i_Estado_permiso number;
i_fecha_js date;
i_fecha_ja date;
 i_fecha_rrhh date;
 i_secuencia_operacion number;
 i_secuencia_ausencia number;
 i_fecha varchar2(10);
 i_hora  varchar2(10);
 i_id_ano  varchar2(4);
 correo_v_funcionario varchar2(256);
 correo_js varchar2(256);
 correo_ja varchar2(256);
 correo_js_delegado varchar2(256);
 correo_js_delegado2 varchar2(256);
 correo_js_delegado3 varchar2(256);
 correo_js_delegado4 varchar2(256);
 i_sender varchar2(256);
 i_recipient varchar2(256);
 I_ccrecipient varchar2(256);
 i_subject varchar2(256);
 I_message varchar2(15000);
 i_nombre_peticion varchar2(256);
 i_desc_tipo_ausencia varchar2(512);
 i_cadena2 varchar2(512);
 i_desc_mensaje varchar2(10000);
 i_formato_fecha_inicio date;
 i_formato_fecha_fin date;
 i_mes_inicio number;
i_mes_fin number;
i_mes_actual number;
i_año_inicio number;
i_año_fin number;
i_año_actual number;
V_JEFE_GUARDIA varchar2(6);
 i_id_delegado_js2 varchar2(6);
 i_id_delegado_js3   varchar2(6);
 i_id_delegado_js4   varchar2(6);

begin
todo_ok_basico:=0;
msgBasico:='';

i_mes_inicio:=to_char(V_FECHA_INICIO,'MM');
i_mes_fin:=to_char(V_FECHA_FIN,'MM');
i_mes_actual:=to_char(sysdate,'MM');


i_año_inicio:=to_char(V_FECHA_INICIO,'YYYY');
i_año_fin:=to_char(V_FECHA_FIN,'YYYY');
i_año_actual:=to_char(sysdate,'YYYY');


i_formato_fecha_inicio:= to_date(to_char(V_FECHA_INICIO,'DD/MM/YYYY') || V_HORA_INICIO,'DD/MM/YYYY HH24:MI');
i_formato_fecha_fin:= to_date(to_char(V_FECHA_FIN,'DD/MM/YYYY') || V_HORA_FIN,'DD/MM/YYYY HH24:MI');

-- 10 Solicitado
-- 20 Pde. Firma Jefe Secc.
-- 21 Pde. Firma Jefe Area
-- 22 Pde Vo de RRHH.
-- 30 Rechazado Jefe Secc.
-- 31 Rechazado Jefe Area.
-- 32 Denegado RRHH
-- 40 Anulado RRHH
-- 80 Concedido
--obtenemos las persona que tienen que firmar si no tiene personas
--no se deja coger le permiso .
IF  V_ID_TIPO_FUNCIONARIO <> 23 then

BEGIN
     select distinct id_js,
           id_delegado_js,
           id_ja,
           id_delegado_ja,
           id_delegado_firma, --añadido 1 de junio
           id_delegado_js2,
           id_delegado_js3,
           id_delegado_js4
     into  i_id_js,
           i_id_delegado_js,
           i_id_ja,
           i_id_delegado_ja,
           i_id_delegado_firma, --añadido 1 de junio
           i_id_delegado_js2,
           i_id_delegado_js3        ,
                      i_id_delegado_js4
     from funcionario_firma
     where V_ID_FUNCIONARIO=ID_FUNCIONARIO;
EXCEPTION
     WHEN NO_DATA_FOUND THEN
i_id_ja:='0';
i_id_js:='0';
END;
--Buscamos el correo en la usuario.intranet.
BEGIN
    select MIN(peticion), MIN(nombre_peticion),MIN(js),MIN(ja)
    into correo_v_funcionario,i_nombre_peticion,correo_js,correo_ja

 from (
     select login || '@aytosalamanca.es' as peticion,substr(  DIST_NAME,  INSTR(DIST_NAME,'=',1) +1,INSTR(DIST_NAME,',',1) -INSTR(DIST_NAME,'=',1)-1) as nombre_peticion,''as js ,'' as ja from apliweb_usuario where id_funcionario=to_char(V_ID_FUNCIONARIO)
     union
     select '' as peticion, '' as nombre_peticion ,login || '@aytosalamanca.es' as js,'' as ja  from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_js,6,'0')
      union
    select '' as peticion ,'' as nombre_peticion ,'' as ja,login || '@aytosalamanca.es' as ja from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_ja,6,'0')
 );
EXCEPTION
                        WHEN NO_DATA_FOUND THEN
i_id_ja:='0';
i_id_js:='0';
END;

--Codigo nuevo
--añadido 25 de Julio
BEGIN
    select MIN(peticion), MIN(nombre_peticion),MIN(js),MIN(js_delegado),MIN(ja),MIN(js_delegado2),MIN(js_delegado3),MIN(js_delegado4)
    into correo_v_funcionario,i_nombre_peticion,correo_js,correo_js_delegado,correo_ja,correo_js_delegado2,correo_js_delegado3,correo_js_delegado4

 from (
     select login || '@aytosalamanca.es' as peticion,TRIM(substr(dist_NAME,4,instr(dist_NAME,',',1)-4)) as nombre_peticion,''as js ,''as js_delegado ,'' as ja,'' as js_delegado2,'' as js_delegado3,'' as js_delegado4 from apliweb_usuario
    where lpad(id_funcionario,6,'0')=lpad(to_char(V_ID_FUNCIONARIO),6,'0')
     union
     select '' as peticion, '' as nombre_peticion ,login || '@aytosalamanca.es' as js,''as js_delegado ,'' as ja,'' as js_delegado2,'' as js_delegado3 ,'' as js_delegado4 from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_js,6,'0')
      union
      select '' as peticion, '' as nombre_peticion ,''as js,login || '@aytosalamanca.es' as js_delegado ,'' as ja ,'' as js_delegado2,'' as js_delegado3,'' as js_delegado4 from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_delegado_js,6,'0')
      union
      select '' as peticion ,'' as nombre_peticion ,'' as js,''as js_delegado ,login || '@aytosalamanca.es' ,'' as js_delegado2,'' as js_delegado3,'' as js_delegado4   from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_ja,6,'0')
      union
      select '' as peticion, '' as nombre_peticion ,''as js,'' as js_delegado ,'' as ja ,login || '@aytosalamanca.es' as js_delegado2,'' as js_delegado3,'' as js_delegado4 from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_delegado_js2,6,'0')
      union
      select '' as peticion, '' as nombre_peticion ,''as js,'' as js_delegado ,'' as ja ,'' as js_delegado2,login || '@aytosalamanca.es' as js_delegado3,'' as js_delegado4 from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_delegado_js3,6,'0')
       union
      select '' as peticion, '' as nombre_peticion ,''as js,'' as js_delegado ,'' as ja ,'' as js_delegado2,'' as js_delegado3,login || '@aytosalamanca.es' as js_delegado4 from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_delegado_js4,6,'0')

 );
EXCEPTION
                        WHEN NO_DATA_FOUND THEN
i_id_ja:='0';
i_id_js:='0';
END;


--Descripcion del permiso .
BEGIN
    select desc_tipo_ausencia

     into  i_desc_tipo_ausencia

     from TR_TIPO_AUSENCIA
     where id_tipo_ausencia=V_ID_TIPO_AUSENCIA;
EXCEPTION
     WHEN NO_DATA_FOUND THEN
     i_desc_tipo_ausencia:='';
END;

--Si No hay jefes para firmar el permiso.
IF   i_id_js='0' AND i_id_ja='0' then
        todo_ok_basico:=1;
        msgBasico:='Operacion no realizada. Pongase en contacto con RRHH. Sin firmas.';
        RETURN;
END IF;


ELSE
--añadido chm 25/02/2017
--BUSQUEDA FIRMA BOMBEROS
--añadir la función
i_id_ja:='0';
i_id_js:='0';
correo_js:='';
V_JEFE_GUARDIA:='';
--chm 22/07/2022
--Comprobamos que esta el jefe de guardia. JA LUIS DAMIAN 961110 ldramos@aytosalamanca.es
--chm 16/09/2022 cambio de la tabla    bomberos_guardias_plani s,se elimina el enlace
BEGIN --login
  select login || '@aytosalamanca.es',lpad(funcionario,6,'0'),'961110','ldramos@aytosalamanca.es'
   into correo_js,i_id_js,i_id_ja,correo_ja
    from    bomberos_guardias_plani s,
          --sige.GUARDIAS@lsige s,
         apliweb_usuario a
  where desde =DECODE( trunc(to_char(sysdate+0/24,'hh24')/8),0,
        to_date(to_char(sysdate-1,'DD/mm/yyyy') || '08:00','DD/mm/yyyy hh24:mi')  ,
        to_date(to_char(sysdate,'DD/mm/yyyy')   || '08:00','DD/mm/yyyy hh24:mi')
         ) and dotacion='M' and lpad(funcionario,6,'0')=lpad(id_funcionario,6,'0') and rownum<2;
EXCEPTION
     WHEN NO_DATA_FOUND THEN
     i_id_js:='0';--cambiar a 0
END;


IF  i_id_js='0' AND i_id_ja='0' then
        todo_ok_basico:=1;
        msgBasico:='La guardia no tiene asignada Jefe, intentelo más tarde.';
        RETURN;
END IF;


--nombre petición y correo
--chm 12/02/2017
BEGIN
select  MIN(correo_funcionario) ,MIN(nombre_peticion)
    into correo_v_funcionario,i_nombre_peticion
 from (
     select login || '@aytosalamanca.es' as correo_funcionario ,TRIM(substr(dist_NAME,4,instr(dist_NAME,',',1)-4)) as nombre_peticion from apliweb_usuario
    where lpad(id_funcionario,6,'0')=lpad(to_char(V_ID_FUNCIONARIO),6,'0')
      );

EXCEPTION
     WHEN NO_DATA_FOUND THEN
     correo_v_funcionario:='';
END;




END IF;--FIN busqueda firmas


  i_Estado_permiso:=10;
  i_fecha_js:='';
  i_fecha_ja:='';
  i_fecha_rrhh:='';

i_sender:=correo_v_funcionario;
IF V_ID_TIPO_AUSENCIA> '500' THEN
      i_cadena2:='Fecha Inicio: ' || to_char(V_FECHA_INICIO,'DD-MON-YY') ||  chr(10)||
                 'Fecha Fin: ' || to_char(V_FECHA_FIN,'DD-MON-YY') ||  chr(10)||
                'Hora de Inicio:     ' || V_HORA_INICIO ||  chr(10)||'Hora Fin: ' || V_HORA_FIN;
ELSE
   i_cadena2:='Fecha Ausencia: ' || to_char(V_FECHA_INICIO,'DD-MON-YY') ||  chr(10)||'Hora de Inicio:     ' || V_HORA_INICIO ||  chr(10)||'Hora Fin: ' || V_HORA_FIN;
END IF;

--CHM 15/02/3021
IF V_ID_TIPO_AUSENCIA = '998' THEN
       i_cadena2:='Fecha Inicio: '       || to_char(V_FECHA_INICIO,'DD-MON-YY') ||  chr(10)||
                  'Hora de Inicio:     ' || V_HORA_INICIO;
END IF;

--obtenemos el dia y hora, secuencia de la operacion. ,secuencia del ausencia
select sec_operacion.nextval,sec_ausencia.nextval,to_char(sysdate,'DD/MM/YYYY'),
      to_char(sysdate,'HH:MI'),to_char(sysdate,'YYYY')
into  i_secuencia_operacion,i_secuencia_ausencia,i_fecha,i_hora,i_id_ano
 from dual;

--configuracion formato_correo SI ES UNA HORA SINDICAL
--LO UNICO QUE SE TIENE QUE ENVIAR ES UN CORREO DICIENDO QUE SE HA COGER ESA HORA

IF  V_ID_TIPO_AUSENCIA< '500' THEN
--Descripcion del ausencia.
  BEGIN
    select CABECERA || ' '||
           'Petición Autorización de Ausencia ' ||' '||
           SOLICITADO || ' '||
           i_nombre_peticion ||' '||
           TIPO_PERMISO ||' '||
           i_desc_tipo_ausencia||' '||
           FECHA_INICIO  ||' '||
           to_char(V_FECHA_INICIO,'DD-MON-YY')  ||' '||
           DECODE(substr(V_ID_TIPO_AUSENCIA,1,1) ,'5',
                 FECHA_FIN  ||' '||
                 to_char(V_FECHA_FIN,'DD-MON-YY')
                   ,'') ||' '||
           HORA_INICIO ||' '|| V_HORA_INICIO   ||' '||  --
           HORA_FIN    ||' '|| V_HORA_FIN      || ' '|| --
           TOTAL_HORAS ||' '||  lpad(trunc( v_total_horas/60 ),2,'0')  || ':'||
            lpad(trunc( mod(v_total_horas,60 ) ),2,'0')  || ' '||
           CABECERA_FI ||' '||
           'Esta ausencia requiere su autorización para ser concedido'||' '||
           CABECERA_FIN_1
           ||
           CABECERA_FIN_1_1

     into  i_desc_mensaje
     from  FORMATO_CORREO
     where DECODE( substr(V_ID_TIPO_AUSENCIA,1,1) ,
                     '5' , '500' ,
                     '222'
             )=ID_TIPO_PERMISO;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
     i_desc_tipo_ausencia:='';
  END;
ELSE
  BEGIN
  select CABECERA || ' '||
           'Para su conocimiento  ' ||' '||
           SOLICITADO || ' '||
           i_nombre_peticion ||' '||
           TIPO_PERMISO ||' '||
           i_desc_tipo_ausencia||' '||
           FECHA_INICIO  ||' '||
           to_char(V_FECHA_INICIO,'DD-MON-YY')  ||' '||
           DECODE(substr(V_ID_TIPO_AUSENCIA,1,1) ,'5',
                 FECHA_FIN  ||' '||
                 to_char(V_FECHA_FIN,'DD-MON-YY')
                   ,'') ||' '||
           HORA_INICIO ||' '|| V_HORA_INICIO   ||' '||  --
           HORA_FIN    ||' '|| V_HORA_FIN      || ' '|| --
           TOTAL_HORAS ||' '||  lpad(trunc( v_total_horas/60 ),2,'0')  || ':'||
            lpad(trunc( mod(v_total_horas,60 ) ),2,'0')  || ' '||
           CABECERA_FI ||' '||
           'Horas Sindicales '||' '||
           CABECERA_FIN_1
           ||'ID_AUSENCIA =' ||i_secuencia_ausencia || '2025=2012' ||
           CABECERA_FIN_1_1

     into  i_desc_mensaje
     from  FORMATO_CORREO
     where DECODE( substr(V_ID_TIPO_AUSENCIA,1,1) ,
                     '5' , '500' ,
                     '222'
             )=ID_TIPO_PERMISO;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
     i_desc_tipo_ausencia:='';
  END;
    i_recipient:=i_id_js;
    I_ccrecipient:=i_id_ja;

END IF;


--CHM 15/02/3021
IF V_ID_TIPO_AUSENCIA = '998' THEN
--Descripcion del ausencia.
  BEGIN
    select CABECERA || ' '||
           'Petición Autorización de Resolución Incidencia de Fichaje ' ||' '||
           SOLICITADO || ' '||
           i_nombre_peticion ||' '||
           TIPO_PERMISO ||' '||
           i_desc_tipo_ausencia||' '||
           FECHA_INICIO  ||' '||
           to_char(V_FECHA_INICIO,'DD-MON-YY')  ||' '||
           DECODE(substr(V_ID_TIPO_AUSENCIA,1,1) ,'5',
                 FECHA_FIN  ||' '||
                 to_char(V_FECHA_FIN,'DD-MON-YY')
                   ,'') ||' '||
           HORA_INICIO ||' '|| V_HORA_INICIO   ||' '||  --
           CABECERA_FI ||' '||
           'Esta petición requiere su autorización para este fichaje sea valido'||' '||
           CABECERA_FIN_1
           ||
           CABECERA_FIN_1_1

     into  i_desc_mensaje
     from  FORMATO_CORREO
     where DECODE( substr(V_ID_TIPO_AUSENCIA,1,1) ,
                     '5' , '500' ,
                     '222'
             )=ID_TIPO_PERMISO;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
     i_desc_tipo_ausencia:='';
  END;
END IF;




--Comprobamos quien firma
IF i_id_js=V_ID_FUNCIONARIO AND i_id_ja<>V_ID_FUNCIONARIO THEN
     i_Estado_permiso:=22;
          i_fecha_ja:=sysdate;
          i_fecha_js:=i_fecha_ja;
            i_subject:='Solicitud de Permiso de: ' || i_nombre_peticion;
          --Bomberos
           IF i_id_ja='961110'  THEN --cambiar quitar i_id_ja='101217'
                i_Estado_permiso:=21;--las ausencias VO guardia
                i_recipient:=correo_ja;
                i_fecha_ja:=''; --tiene que firmar
                i_id_ja:='';
                i_subject:='Solicitud de Permiso de: ' || i_nombre_peticion;
           END IF;

ELSE IF i_id_ja=V_ID_FUNCIONARIO THEN
          i_Estado_permiso:=22;
          i_fecha_ja:=sysdate;
          i_id_js:=i_id_ja;
          i_fecha_js:=i_fecha_ja;
     ELSE --curri normal
          i_Estado_permiso:=20;

           --chm 15/02/2017
          --jefe guardia.
          IF  V_ID_TIPO_FUNCIONARIO = 23 then
            V_JEFE_GUARDIA:=i_id_js;
          else
             i_id_js:='';
          end if;

          i_fecha_js:='';
          i_id_ja:='';
          i_fecha_ja:='';
          i_recipient:=correo_js;
        -- i_recipient:='carlos@aytosalamanca.es';
         -- I_ccrecipient:='carlos@aytosalamanca.es';
          i_subject:='Solicitud de Ausencia de: ' || i_nombre_peticion;
           I_message:= 'Solicitud de autorizacion para Ausencia.'||  chr(10)||
             'Necesita su autorizacion para que este Ausencia sea concedido.' || chr(10)||  chr(10)||
             'Solicitud de Ausencia de: '|| i_nombre_peticion || chr(10)||
             'Tipo Ausencia: '  || i_desc_tipo_ausencia|| chr(10)||
              i_cadena2;
          I_message:= i_desc_mensaje;
     END IF;
END IF;

IF V_ID_TIPO_AUSENCIA > '500' THEN
 /* CAMBIADO A PETICION DE rrhh 22 DE mARZO DE 1010 */
 -- i_Estado_permiso:=80;
 -- i_id_js:=V_ID_FUNCIONARIO;
 -- i_fecha_js:=sysdate;
 -- i_id_ja:=V_ID_FUNCIONARIO;
 -- i_fecha_ja:=sysdate;
 -- i_subject:='Horas Sindicales de: ' || i_nombre_peticion;
 -- i_recipient:=correo_ja;
 -- I_ccrecipient:=correo_js;
   i_fecha_ja:=sysdate;
END IF;

--CHM 15/02/3021
IF V_ID_TIPO_AUSENCIA = '998' THEN
   i_subject:='Solicitud  Resolución Incidencia en un  Fichaje: ' || i_nombre_peticion;
           I_message:= 'Solicitud de autorizacion para Resolución Incidencia de Fichaje.'||  chr(10)||
             'Necesita su autorizacion para que este Fichaje sea valido.' || chr(10)||  chr(10)||
             'Solicitud de Resolución Incidencia de Fichaje: '|| i_nombre_peticion || chr(10)||

              i_cadena2;
          I_message:= i_desc_mensaje;

END IF;

 --INSERT EN AUSENCIAS
 insert into ausencia (
               id_ausencia,
               id_ano,
               id_funcionario,
               id_tipo_ausencia,
               id_estado,
               firmado_js,
               fecha_js,
               firmado_ja,
               fecha_ja,
               fecha_inicio,
               fecha_fin,
               total_horas,
               id_usuario,
               fecha_modi
               )
       vaLues
               (i_secuencia_ausencia ,
                V_id_ANO,
                V_ID_FUNCIONARIO,
                V_ID_TIPO_AUSENCIA,
                i_estado_permiso,
                 i_id_js,
                to_date(to_char(i_fecha_js,'DD/MM/yy'),'DD/MM/yy'),
                i_id_ja,
                to_date(to_char(i_fecha_ja,'DD/MM/yy'),'DD/MM/yy'),
                i_formato_fecha_inicio,
                i_formato_fecha_fin,
                v_total_horas,
               V_ID_FUNCIONARIO
               ,to_date(to_char(sysdate,'DD/MM/yy'),'DD/MM/yy')
                 );

--chm 27/10/2025
 /*IF i_estado_permiso <> 22 then

 -- ENVIO DE CORREO
          envio_correo(i_sender ,
                       i_recipient ,
                       I_ccrecipient ,
                       i_subject ,
                       I_message);

 --envio correo guardiabomberos.
 --chm 01/03/2017
 IF  V_ID_TIPO_FUNCIONARIO = 23 then
     envio_correo(i_sender ,
                       'guardiabomberos@aytosalamanca.es' ,
                       I_ccrecipient ,
                       i_subject ,
                       I_message);


 END IF;



                       --i_sender:='c';
 --Envio de correo al suplente si esta de vacaciones el principal
 --añadido 25 Julio 2013
 if  chequea_vacaciones_js(i_id_jS)=1 then
     i_recipient:=correo_js_delegado;
     envio_correo(i_sender ,
                 i_recipient ,
                 I_ccrecipient ,
                 i_subject || ' .Firma suplente.',
                 I_message);
 end if;

 --Envio de correo al suplente si puede firmar siempre
 --añadido 1 Junio 2016
 if i_id_delegado_firma = 1 then
     i_recipient:=correo_js_delegado;
     envio_correo(i_sender ,
                 i_recipient ,
                 I_ccrecipient ,
                 i_subject || ' .Firma suplente.El permiso puede ser Firmado tambien por otra persona.',
                 I_message);
    i_recipient:=correo_js_delegado2;
     envio_correo(i_sender ,
                 i_recipient ,
                 I_ccrecipient ,
                 i_subject || ' .Firma suplente.El permiso puede ser Firmado tambien por otra persona.',
                 I_message);
     i_recipient:=correo_js_delegado3;
     envio_correo(i_sender ,
                 i_recipient ,
                 I_ccrecipient ,
                 i_subject || ' .Firma suplente.El permiso puede ser Firmado tambien por otra persona.',
                 I_message);
       i_recipient:=correo_js_delegado4;
     envio_correo(i_sender ,
                 i_recipient ,
                 I_ccrecipient ,
                 i_subject || ' .Firma suplente.El permiso puede ser Firmado tambien por otra persona.',
                 I_message);
 end if;

END IF;*/

--quito las horas sindicales.
IF V_ID_TIPO_AUSENCIA > 500 THEN

   UPDATE HORA_SINDICAL
   SET TOTAL_UTILIZADAS=TOTAL_UTILIZADAS+v_total_horas
   where
                id_ano=i_año_actual AND
                id_MES=i_mes_Actual and
                id_funcionario=V_ID_FUNCIONARIO AND
                ID_TIPO_AUSENCIA= V_ID_TIPO_AUSENCIA;

END IF;

--chm 13/02/2020
--quito las horas de las bolsa concilia
IF V_ID_TIPO_AUSENCIA = 50 THEN

   UPDATE BOLSA_CONCILIA
   SET
   utilizadas=nvl(utilizadas,0)+v_total_horas,
   pendientes_justificar=nvl(pendientes_justificar,0)+v_total_horas
   where id_ano=i_año_actual AND  id_funcionario=V_ID_FUNCIONARIO;

END IF;


 --Insert en el historico
   insert into historico_operaciones
      values(i_secuencia_operacion,
             i_secuencia_ausencia ,
             10,
             v_id_ano,
             V_ID_FUNCIONARIO,
             to_Date(i_fecha,'DD/MM/YYYY'),
             i_hora,
             'INSERTA AUSENCIA',
              V_ID_FUNCIONARIO,to_Date(i_fecha,'DD/MM/YYYY'));


end INSERTA_AUSENCIAS;
/

