CREATE OR REPLACE PROCEDURE RRHH."INSERTA_HISTORICO"
       (V_ID_ANO in number,
        V_ID_FUNCIONARIO in number,
        V_ID_TIPO_FUNCIONARIO in number,
        V_ID_TIPO_PERMISO in varchar2,
        V_ID_TIPO_DIAS in out VARCHAR2,
        V_FECHA_INICIO in DATE,
        V_FECHA_FIN in DATE,
        V_HORA_INICIO  in varchar2,
        V_HORA_FIN  in varchar2,
        V_UNICO in varchar2,
        V_DPROVINCIA in varchar2,
        V_ID_GRADO in varchar2,
        V_JUSTIFICACION in varchar2,
        V_NUM_DIAS in number,
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
 i_sender varchar2(256);
 i_recipient varchar2(256);
 I_ccrecipient varchar2(256);
 i_subject varchar2(256);
 I_message varchar2(256);
 i_nombre_peticion varchar2(256);
 i_des_tipo_permiso_larga varchar2(512);
 i_cadena2 varchar2(512);
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
-- 80 Concedido
--obtenemos las persona que tienen que firmar si no tiene personas
--no se deja coger le permiso .
BEGIN
    select id_js,
           id_delegado_js,
           id_ja,
           id_delegado_ja
     into  i_id_js,
           i_id_delegado_js,
           i_id_ja,
           i_id_delegado_ja
     from funcionario_firma
     where V_ID_FUNCIONARIO=ID_FUNCIONARIO;
EXCEPTION
     WHEN NO_DATA_FOUND THEN
i_id_ja:='';
i_id_js:='';
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
i_id_ja:='';
i_id_js:='';
END;


--Descripcion del permiso .
BEGIN
    select des_tipo_permiso_larga

     into  i_des_tipo_permiso_larga

     from TR_TIPO_PERMISO
     where V_ID_TIPO_PERMISO=ID_TIPO_PERMISO;
EXCEPTION
     WHEN NO_DATA_FOUND THEN
     i_des_tipo_permiso_larga:='';
END;
--Si No hay jefes para firmar el permiso.
IF   i_id_js='' AND i_id_ja='' then
        todo_ok_basico:=1;
        msgBasico:='Operacion no realizada. Pongase en contacto con RRHH. Sin firmas.';
        RETURN;
END IF;
  i_Estado_permiso:=10;
  i_fecha_js:='';
  i_fecha_ja:='';
  i_fecha_rrhh:='';

i_sender:=correo_v_funcionario;
i_cadena2:='Fecha Inicio: ' || V_FECHA_INICIO || ' a Fecha Fin: ' || V_FECHA_FIN || ' Numero de Dias: ' || V_NUM_DIAS;
--Comprobamos quien firma
IF i_id_js=V_ID_FUNCIONARIO THEN
  i_Estado_permiso:=21;
  i_fecha_js:=sysdate;
  i_id_ja:='';
  i_fecha_ja:='';
 i_recipient:=correo_ja;
 i_subject:='Solicitud de Permiso de: ' || i_nombre_peticion;
 I_message:= 'Solicitud de autorizacion para permiso.'||  chr(10)||
             'Necesita su autorizacion para que este permiso sea concedido.' || chr(10)||  chr(10)||
             'Solicitud de Permiso de: '|| i_nombre_peticion || chr(10)||
             'Tipo permiso: '  || i_DES_TIPo_PERMISO_larga || chr(10)||
              i_cadena2;

ELSE IF i_id_ja=V_ID_FUNCIONARIO THEN
          i_Estado_permiso:=22;
          i_fecha_ja:=sysdate;
          i_id_js:=i_id_ja;
          i_fecha_js:=i_fecha_ja;
     ELSE --curri normal
          i_Estado_permiso:=20;
          i_id_ja:='';
          i_fecha_ja:='';
          i_recipient:=correo_js;
          i_subject:='Solicitud de Permiso de: ' || i_nombre_peticion;
           I_message:= 'Solicitud de autorizacion para permiso.'||  chr(10)||
             'Necesita su autorizacion para que este permiso sea concedido.' || chr(10)||  chr(10)||
             'Solicitud de Permiso de: '|| i_nombre_peticion || chr(10)||
             'Tipo permiso: '  || i_DES_TIPo_PERMISO_larga || chr(10)||
              i_cadena2;
     END IF;
END IF;




--obtenemos el dia y hora, secuencia de la operacion. ,secuencia del permiso
select sec_operacion.nextval,sec_permiso.nextval,to_char(sysdate,'DD/MM/YYYY'),
      to_char(sysdate,'HH:MI'),to_char(sysdate,'YYYY')
into  i_secuencia_operacion,i_secuencia_permiso,i_fecha,i_hora,i_id_ano
 from dual;

 /*
   todo_ok_basico:=1;
        msgBasico:=i_secuencia_permiso || ','||
                V_id_ANO|| ','||
                V_ID_FUNCIONARIO|| ','||
                V_ID_TIPO_PERMISO|| ','||
                i_estado_permiso|| ','||
               sysdate|| ','||
                i_id_js|| ','||
                i_fecha_js||  ','||
                i_id_ja|| ','||
               i_fecha_ja||  ','||
                ''|| ','||
               NULL || ','||
               V_FECHA_INICIO|| ','||
                V_FECHA_FIN|| ','||
                V_NUM_DIAS|| ','||
                V_HORA_INICIO|| ','||
                V_HORA_FIN|| ','||
                V_ID_TIPO_DIAS|| ','||
                V_DPROVINCIA|| ','||
                V_ID_GRADO|| ','||
                V_JUSTIFICACION|| ','||
                ''|| ','||
                ''|| ','||
                ''|| ','||
                V_ID_FUNCIONARIO  || ','||
                sysdate;

     RETURN;            */

 --INSERT EN PERMISOS
 insert into permiso (
               id_permiso,
               id_ano,
               id_funcionario,
               id_tipo_permiso,
               id_estado,
              fecha_soli  ,
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
               id_usuario
             ,  fecha_modi
               )
       vaLues
               (i_secuencia_permiso ,
                V_id_ANO,
                V_ID_FUNCIONARIO,
                V_ID_TIPO_PERMISO,
                i_estado_permiso,
               to_date(to_char(sysdate,'DD/MM/yy'),'DD/MM/yy'),
                i_id_js,
                to_date(to_char(i_fecha_js,'DD/MM/yy'),'DD/MM/yy'),
                i_id_ja,
                to_date(to_char(i_fecha_ja,'DD/MM/yy'),'DD/MM/yy'),
                to_date(to_char(V_FECHA_INICIO,'DD/MM/YY'),'DD/MM/yy'),
                to_date(to_char(V_FECHA_FIN,'DD/MM/YY'),'DD/MM/yy') ,
                V_NUM_DIAS,
                V_HORA_INICIO,
                V_HORA_FIN,
                v_total_horas,
                V_ID_TIPO_DIAS,
                V_DPROVINCIA,
                V_ID_GRADO,
                'NO',
                V_JUSTIFICACION,

                V_ID_FUNCIONARIO
               ,to_date(to_char(sysdate,'DD/MM/yy'),'DD/MM/yy')
                 );


IF i_estado_permiso <> 22 then

 -- ENVIO DE CORREO
  envio_correo(i_sender ,
               i_recipient ,
               I_ccrecipient ,
               i_subject ,
               I_message);

END IF;

/*
 --Insert en el historico
   insert into historico_operaciones values(i_secuencia,i_tipo_operacion,i_clase_operacion,
                       i_id_ano, SYSDATE,i_hora,i_orden_sql,i_usuario,i_fecha_modi);
 */

end INSERTA_HISTORICO;
/

