create or replace procedure rrhh.INSERTA_PERMISO_new
       (V_ID_ANO in number,
        V_ID_FUNCIONARIO in number,
        V_ID_TIPO_FUNCIONARIO in number,
        V_ID_TIPO_PERMISO in varchar2,
        V_ID_TIPO_DIAS in out VARCHAR2,
        V_FECHA_INICIO in DATE,
        V_FECHA_FIN in DATE,
        V_HORA_INICIO  in varchar2,
        V_HORA_FIN  in varchar2,
        V_UNICO in out varchar2,
        V_DPROVINCIA in varchar2,
        V_ID_GRADO in varchar2,
        V_JUSTIFICACION in  varchar2,
        V_NUM_DIAS in number,
        v_total_horas in number,
        V_t1 in varchar2,
        V_t2 in varchar2,
        V_t3 in varchar2,V_GUARDIAS in varchar2,
        todo_ok_Basico out integer,msgBasico out varchar2,enlace_fichero out varchar2) is

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
 i_secuencia_permiso number;
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
 i_des_tipo_permiso_larga varchar2(512);
 i_cadena2 varchar2(512);
 i_desc_mensaje varchar2(10000);
 v_mensaje varchar2(15000);
 V_JEFE_GUARDIA varchar2(6);
 i_id_delegado_js2 varchar2(6);
 i_id_delegado_js3   varchar2(6);
 i_id_delegado_js4   varchar2(6);
 V_JUSTIFI        varchar2(6);

begin
todo_ok_basico:=0;
msgBasico:='';


-- 10 Solicitado
-- 20 Pde. Firma Jefe Secc.
-- 21 Pde. Firma Jefe Area
-- 22 Pde Vo de RRHH.
-- 30 Rechazado Jefe Secc.
-- 31 Rechazado Jefe Area.
-- 32 Denegado RRHH
-- 40 Anulado RRHH
-- 41 Anulado por USUARIO //añadido 03/03/2017
-- 80 Concedido
--obtenemos las persona que tienen que firmar si no tiene personas
--no se deja coger le permiso .
--a?adido distinct dia 8 - junio  repetidos


--Añadido chm 25/01/2017
--FIRMAS PARA BOMBEROS ELSE
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
--añadido el cambio de tabla por el sftp
--quitamos el enlace
i_id_ja:='0';
i_id_js:='0';
correo_js:='';
V_JEFE_GUARDIA:='';
--Comprobamos que esta el jefe de guardia. JA LUIS DAMIAN 961110 ldramos@aytosalamanca.es
BEGIN  --login  sustituir
  select login || '@aytosalamanca.es',lpad(funcionario,6,'0'),'961110','ldramos@aytosalamanca.es'
   into correo_js,i_id_js,i_id_ja,correo_ja

    from --sige.GUARDIAS@lsige s,
         bomberos_guardias_plani s,

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


----

/*
--Comprobamos que el funcionario esta de guardia.
BEGIN
  select login || '@aytosalamanca.es' into correo_js  from sige.GUARDIAS@lsige s, apliweb.usuario a
  where desde =DECODE( trunc(to_char(sysdate+0/24,'hh24')/14),1,
        to_date(to_char(sysdate,'DD/mm/yyyy')   || '14:00','DD/mm/yyyy hh24:mi') ,
        to_date(to_char(sysdate-1,'DD/mm/yyyy') || '14:00','DD/mm/yyyy hh24:mi')
         ) and dotacion='M' and lpad(funcionario,6,'0')=lpad(id_funcionario,6,'0');
EXCEPTION
     WHEN NO_DATA_FOUND THEN
     i_id_js:='';
END;

IF  correo_js:='' then
        todo_ok_basico:=1;
        msgBasico:='La guardia no tiene asignada Jefe, intentelo más tarde.';
        RETURN;
END IF;
----
*/


END IF;--FIN busqueda firmas


--Descripcion del permiso .
BEGIN
    select distinct des_tipo_permiso_larga

     into  i_des_tipo_permiso_larga

     from TR_TIPO_PERMISO
     where V_ID_TIPO_PERMISO=ID_TIPO_PERMISO AND ID_ANO=V_ID_ANO;
EXCEPTION
     WHEN NO_DATA_FOUND THEN
     i_des_tipo_permiso_larga:='';
END;



  i_Estado_permiso:=10;
  i_fecha_js:='';
  i_fecha_ja:='';
  i_fecha_rrhh:='';
  i_sender:=correo_v_funcionario;


IF V_ID_TIPO_PERMISO<> '15000' THEN
   i_cadena2:='Fecha Inicio: ' || to_char(V_FECHA_INICIO,'DD-MON-YY') ||  chr(10)||'Fecha Fin:     ' || to_char(V_FECHA_FIN,'DD-MON-YY');
ELSE
   i_cadena2:='Fecha Inicio: ' || to_char(V_FECHA_INICIO,'DD-MON-YY') ||  chr(10)||'Hora de Inicio:     ' || V_HORA_INICIO ||  chr(10)||'Hora Fin: ' || V_HORA_FIN;
END IF;


--obtenemos el dia y hora, secuencia de la operacion. ,secuencia del permiso
select sec_operacion.nextval,sec_permiso.nextval,to_char(sysdate,'DD/MM/YYYY'),
      to_char(sysdate,'HH:MI'),to_char(sysdate,'YYYY')
into  i_secuencia_operacion,i_secuencia_permiso,i_fecha,i_hora,i_id_ano
 from dual;
 enlace_fichero:=V_ID_ANO ||        V_ID_FUNCIONARIO||i_secuencia_permiso;

if V_JUSTIFICACION = 'N0' then
 BEGIN
         select DECODE(JUSTIFICAcion,'SI','NO','--')
           into  V_JUSTIFI
           from tr_tipo_permiso

          where
                id_tipo_permiso=V_ID_TIPO_PERMISO and
                id_ano=V_ID_ANO and rownum<2;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
          V_JUSTIFI:='--';

    END;
end if;

-- V_JUSTIFICACION :=  V_JUSTIFI;

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


--chm 10/02/2017
--chm 27/10/2025
 /*envia_correo_informa_new('2',  V_ID_TIPO_PERMISO,
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
                       v_t1,
                       v_t2,
                       v_t3,
                       V_ID_TIPO_FUNCIONARIO,
                       v_mensaje);*/

 I_message:= v_mensaje;
--Estado del Permiso
IF i_id_ja=V_ID_FUNCIONARIO OR i_id_jS=V_ID_FUNCIONARIO THEN
          i_Estado_permiso:=22;
          i_fecha_ja:=sysdate;
          i_fecha_js:=i_fecha_ja;
          --Bomberos
          -- AÑADIDO AND 16/03/2017
           IF i_id_ja='961110' AND i_id_ja<>V_ID_FUNCIONARIO  THEN --cambiar quitar i_id_ja='101217'
                i_Estado_permiso:=21;
                i_recipient:=correo_ja;
                i_fecha_ja:=''; --tiene que firmar
                i_id_ja:='';
                i_subject:='Solicitud de Permiso de: ' || i_nombre_peticion;
           END IF;
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
          i_subject:='Solicitud de Permiso de: ' || i_nombre_peticion;

END IF;

IF i_id_jS=101217 THEN
      i_Estado_permiso:=20;

end if;

--INSERT EN PERMISOS
 insert into permiso ( id_permiso, id_ano, id_funcionario, id_tipo_permiso, id_estado, fecha_soli  ,
                       firmado_js, fecha_js, firmado_ja, fecha_ja, fecha_inicio, fecha_fin, num_dias,
                       hora_inicio, hora_fin, total_horas, id_tipo_dias, dprovincia, ID_GRADO, ANULADO,
                       justificacion, id_usuario ,  fecha_modi,tu1_14_22,tu2_22_06,tu3_04_14,OBSERVACIONES )
     vaLues
      (i_secuencia_permiso , V_id_ANO, V_ID_FUNCIONARIO, V_ID_TIPO_PERMISO, i_estado_permiso,
     to_date(to_char(sysdate,'DD/MM/yy'),'DD/MM/yy'), i_id_js, to_date(to_char(i_fecha_js,'DD/MM/yy'),'DD/MM/yy'),
     i_id_ja, to_date(to_char(i_fecha_ja,'DD/MM/yy'),'DD/MM/yy'),  to_date(to_char(V_FECHA_INICIO,'DD/MM/YY'),'DD/MM/yy'),
     to_date(to_char(V_FECHA_FIN,'DD/MM/YY'),'DD/MM/yy') , V_NUM_DIAS, V_HORA_INICIO, V_HORA_FIN, v_total_horas,
      V_ID_TIPO_DIAS,V_DPROVINCIA,V_ID_GRADO,'NO', V_JUSTIFICACION,V_ID_FUNCIONARIO
      ,to_date(to_char(sysdate,'DD/MM/yy'),'DD/MM/yy') ,to_number(v_t1),  to_number(v_t2),to_number(v_t3),V_GUARDIAS);


/*
--ENVIOS CORREOS
IF i_estado_permiso <> 22 then

 -- ENVIO DE CORREO AL JEFE DE SERVICIO.

 IF correo_js <> 'gmperez@aytosalamanca.es' then
  envio_correo(i_sender ,
               i_recipient ,
               I_ccrecipient ,
               i_subject  ,
               I_message);
 end if;
 --envio correo guardiabomberos.
 --chm 01/03/2017
 IF  V_ID_TIPO_FUNCIONARIO = 23 then
     envio_correo(i_sender ,
                       'guardiabomberos@aytosalamanca.es' ,
                       I_ccrecipient ,
                       i_subject ,
                       I_message);



 END IF;

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

END IF;--FIN ENVIOS CORREOS
*/
 --Insert en el historico
   insert into historico_operaciones
      values(i_secuencia_operacion,
             i_secuencia_permiso ,
             10,
             v_id_ano,
             V_ID_FUNCIONARIO,
             to_Date(i_fecha,'DD/MM/YYYY'),
             i_hora,
             'INSERTA PERMISO',
              V_ID_FUNCIONARIO,to_Date(i_fecha,'DD/MM/YYYY'));


end INSERTA_PERMISO_NEW;
/

