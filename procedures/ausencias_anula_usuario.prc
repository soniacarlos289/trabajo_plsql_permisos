create or replace procedure rrhh.AUSENCIAS_ANULA_USUARIO(
          V_ID_AUSENCIA in  number,
          V_ID_FUNCIONARIO in number,
           todo_ok_Basico out integer,
            msgBasico out varchar2
           ) is

i_ficha number;
v_num_dias number;
v_id_tipo_dias_per varchar2(1);
v_codpers varchar2(5);
i_total_horas number;
i_todo_ok_B number;

v_id_tipo_dias_ent  varchar2(256);
i_codpers varchar(5);
i_id_funcionario number;
v_num_dias_tiene_per number;
i_formato_fecha_inicio date;
i_formato_fecha_fin date;
i_diferencia_TOTAL date;
i_total_dias number;
i_contador number;
i_cambia_estado number;
 I_id_estado_ausencia number;
 i_ausencia_no_encontrado number;
  i_observaciones varchar2(1000);
  i_justificacion varchar2(2);
i_total_utilizadas number;
i_id_ano number;
i_id_tipo_ausencia number;
i_id_mes number;
i_fecha_inicio varchar2(12);
i_fecha_fin varchar2(12);
i_hora_inicio  varchar2(12);
i_hora_fin varchar2(12);
i_id_js number;
  correo_v_funcionario varchar2(512);
  i_nombre_peticion    varchar2(512);
  correo_js            varchar2(512);
  correo_ja            varchar2(512);
  i_sender             varchar2(256);
  i_recipient          varchar2(256);
  I_ccrecipient        varchar2(256);
  i_subject            varchar2(256);
  I_message            varchar2(15120);
 i_desc_mensaje varchar2(25120);
 i_DESC_TIPO_AUSENCIA varchar2(512);
fecha_hoy date;
 i_tipo_funcionario number;
begin
-- 10 Solicitado
-- 20 Pde. Firma Jefe Secc.
-- 21 Pde. Firma Jefe Area
-- 22 Pde Vo de RRHH.
-- 30 Rechazado Jefe Secc.
-- 31 Rechazado Jefe Area.
-- 32 Denegado RRHH
-- 41 Anulado por USUARIO //añadido 03/03/2017
-- 40 Anulado RRHH
-- 80 Concedido  RRHH

todo_ok_basico:=0;
 I_id_estado_ausencia:=0;

/* msgsalida:= V_ID_AUSENCIA || ' .'||
          V_ID_ESTADO_AUSENCIA || ' .'||
          V_JUSTIFICACION|| ' .'||V_OBSERVACIONES ;
          return;
*/
i_ausencia_no_encontrado:=0;


--obtenemos los datos del permiso actual.
BEGIN

         select  t.id_estado,OBSERVACIONES,t.JUSTIFICADO,t.total_horas,
         to_char(t.fecha_inicio,'MM') ,t.id_ano,t.id_tipo_ausencia,t.id_funcionario,
          to_char(t.fecha_inicio,'DD/mm/yyyy') as fecha_inicio,
           to_char(t.fecha_fin,'DD/mm/yyyy') as fecha_fin,
       to_char(t.fecha_inicio,'HH24:mi') hora_inicio,
       to_char(t.fecha_fin,'HH24:mi') hora_fin,t.firmado_js,DESC_TIPO_AUSENCIA
         into   I_id_estado_ausencia,
         i_observaciones ,
  i_justificacion,i_total_utilizadas,i_id_mes,i_id_ano,i_id_tipo_ausencia,
  i_id_funcionario,i_fecha_inicio,i_fecha_fin,i_hora_inicio,i_hora_fin,i_id_js,
  i_DESC_TIPO_AUSENCIA
    from ausencia t,tr_tipo_ausencia  tr
    where ID_AUSENCIA=V_ID_AUSENCIA and
          t.id_tipo_ausencia=tr.id_tipo_ausencia;
EXCEPTION
WHEN NO_DATA_FOUND THEN
                   i_ausencia_no_encontrado:=1;

END;


IF  V_ID_FUNCIONARIO <>i_id_funcionario THEN
     todo_ok_basico:=1;
     msgBasico:='Operacion no realizada. Avisar a RRHH.'  || V_ID_FUNCIONARIO  || '--' || i_id_funcionario;
     RETURN;
END IF;


--chm 01/04/2017
--Compruebo el tipo de funcionario de la solicitud
 i_tipo_funcionario:=10;
  BEGIN
    select tipo_funcionario2
      into i_tipo_funcionario
      from personal_new pe
     where id_funcionario = i_id_funcionario  and rownum<2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_tipo_funcionario:=-1;
  END;

  IF i_tipo_funcionario = -1 then
    todo_ok_basico := 1;
    msgBasico      := 'Operacion no realizada. TIPO FUNCIONARIO NO ENCONTRADO.';
    RETURN;
  END IF;


select to_date(to_char(sysdate-1,'dd/mm/yyyy'),'dd/mm/yyyy') into fecha_hoy from dual;

--La fecha de hoy mayor a la fecha de inicio al permiso
IF FECHA_HOY < I_FECHA_INICIO THEN


   --Metemos la ausencia en el finger. --a?adido dia 6 de abril 2010
    --El funcionario Ficha ??
                 i_ficha:=1;
                 BEGIN
                      SELECT
                              distinct codpers
                              into i_codpers
                      FROM
                              personal_new p  ,presenci pr,
                              apliweb_usuario u
                      WHERE
                              p.id_funcionario=I_ID_FUNCIONARIO  and
                              lpad(p.id_funcionario,6,0)=lpad(u.id_funcionario,6,0) and --cambiado 29/03/2010
                              u.id_fichaje is not null and
                              u.id_fichaje=pr.codpers and
                              codinci<>999 and rownum <2;
                 EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                              i_ficha:=0;
                 END;

         if i_ficha=1 then
            ANULA_FICHAJE_FINGER_15000(i_id_ano ,
                                i_id_funcionario ,
                                i_fecha_inicio,
                                i_hora_inicio ,
                                i_hora_fin ,
                                i_codpers ,
                               0 ,'00000',
                              todo_ok_basico ,
                               msgbasico);
         end if;



    UPDATE AUSENCIA
    SET  id_Estado='41',fecha_modi=sysdate
    WHERE   ID_AUSENCIA=V_ID_AUSENCIA and rownum < 2;


  --chm 13/02/2020
--quito las horas de las bolsa concilia
IF i_ID_TIPO_AUSENCIA = 50 THEN

   UPDATE BOLSA_CONCILIA
   SET
   utilizadas=utilizadas-i_total_utilizadas,
   pendientes_justificar=pendientes_justificar-i_total_utilizadas
   where id_ano=i_id_ano AND  id_funcionario=V_ID_FUNCIONARIO;

END IF;

   --quito las horas sindicales.
   IF i_id_tipo_ausencia > 500 THEN

     UPDATE HORA_SINDICAL
     SET TOTAL_UTILIZADAS=TOTAL_UTILIZADAS-i_total_utilizadas
     where
                id_ano=i_id_ano AND
                id_MES=i_id_mes and
                id_funcionario=i_id_funcionario AND
                ID_TIPO_AUSENCIA= i_id_tipo_ausencia and rownum < 2;

   END IF;


    --busco correo del funcionario y la persona que firma
          BEGIN
             select MIN(peticion), MIN(nombre_peticion), MIN(js)
             into correo_v_funcionario, i_nombre_peticion, correo_js
             from (select login || '@aytosalamanca.es' as peticion,substr(  DIST_NAME,  INSTR(DIST_NAME,'=',1) +1,INSTR(DIST_NAME,',',1) -INSTR(DIST_NAME,'=',1)-1) as nombre_peticion,'' as js from apliweb_usuario where id_funcionario=to_char(I_ID_FUNCIONARIO)
             union
             select '' as peticion, '' as nombre_peticion ,login || '@aytosalamanca.es' as js  from apliweb_usuario where lpad(id_funcionario,6,'0')=lpad(i_id_js,6,'0') );
          EXCEPTION
             WHEN NO_DATA_FOUND THEN
                i_id_js := '';
          END;


          --ENVIO DE CORREO AL FUNCIONARIO CON LA DENEGACION
           i_sender      := correo_v_funcionario;
           I_ccrecipient := '';
           i_recipient   := correo_js;

               --Descripcion de la ausencia .
              BEGIN
              select CABECERA || ' '||
                     'Ausencia ANULADA por' ||' '||
                         SOLICITADO || ' '||
                         i_nombre_peticion ||' '||
                         TIPO_PERMISO ||' '||
                         i_desc_tipo_ausencia||' '||
                         FECHA_INICIO  ||' '||
                         i_FECHA_INICIO  ||' '||
                          DECODE(substr(i_ID_TIPO_AUSENCIA,1,1) ,'5',
                         FECHA_FIN  ||' '||
                         i_FECHA_FIN
                          ,'') ||' '||

                         HORA_INICIO ||' '|| i_HORA_INICIO   ||' '||  --
                         HORA_FIN    ||' '|| i_HORA_FIN      || ' '|| --
                         CABECERA_FI ||' '||
                      'Esta Ausencia ha sido ANULADA'||' '||
                      CABECERA_FIN_2
            into  i_desc_mensaje
                 from  FORMATO_CORREO
                 where DECODE( substr(i_ID_TIPO_AUSENCIA,1,1) ,
                     '5' , '500' ,
                     '222'
                     )=ID_TIPO_PERMISO;
          EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                   i_desc_tipo_ausencia:='';
          END;


          I_message:= i_desc_mensaje;
          i_subject := 'Ausencia ha sido Anulada por el Usuario.';
          envio_correo(i_sender ,     i_recipient ,
                              I_ccrecipient ,
                              i_subject ,
                              I_message);
         /* envio_correo(i_sender ,     'carlos@aytosalamanca.es' ,
                              I_ccrecipient ,
                              i_subject ,
                              I_message || ' ' || V_ID_AUSENCIA || ' ' ||   V_ID_FUNCIONARIO);
       */   msgbasico:='Permiso anulado correctamente.';
          todo_ok_basico:='0';
          commit;

ELSE
          msgbasico:='Para anular la Fecha de Inicio del permiso tiene que ser menor que la fecha actual .';
          todo_ok_basico:='1';
          RETURN;

END IF;

END AUSENCIAS_ANULA_USUARIO;
/

