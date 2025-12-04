CREATE OR REPLACE PROCEDURE RRHH."INSERTA_AUSENCIAS_RRHH"
       (V_ID_ANO in number,
        V_ID_FUNCIONARIO in number,
        V_ID_TIPO_FUNCIONARIO in number,
        V_ID_TIPO_AUSENCIA in varchar2,
        V_FECHA_INICIO in DATE,
        V_FECHA_FIN in DATE,
        V_HORA_INICIO  in varchar2,
        V_HORA_FIN  in varchar2,
        V_JUSTIFICACION in varchar2,  V_OBSERVACIONES in  varchar2,
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
 i_secuencia_ausencia number;
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




--obtenemos el dia y hora, secuencia de la operacion. ,secuencia del ausencia
select sec_operacion.nextval,sec_ausencia.nextval,to_char(sysdate,'DD/MM/YYYY'),
      to_char(sysdate,'HH:MI'),to_char(sysdate,'YYYY')
into  i_secuencia_operacion,i_secuencia_ausencia,i_fecha,i_hora,i_id_ano
 from dual;

--FALTARIA ID_USUARIO
  i_Estado_permiso:=80;
  i_fecha_js:=sysdate;
  i_id_js:='';
  i_id_ja:='';
  i_fecha_ja:=sysdate;

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
               fecha_modi,
               OBSERVACIONES , JUSTIFICADO
               )
       vaLues
               (i_secuencia_ausencia ,
                V_id_ANO,
                V_ID_FUNCIONARIO,
                V_ID_TIPO_AUSENCIA,
                i_estado_permiso,
                 i_id_js,
                to_date(to_char(sysdate,'DD/MM/yy'),'DD/MM/yy'),
                i_id_ja,
                to_date(to_char(i_fecha_ja,'DD/MM/yy'),'DD/MM/yy'),
                i_formato_fecha_inicio,
                i_formato_fecha_fin,
                v_total_horas,
               V_ID_FUNCIONARIO
               ,to_date(to_char(sysdate,'DD/MM/yy'),'DD/MM/yy'),
               V_OBSERVACIONES, V_JUSTIFICACION
                 );



--quito las horas sindicales.
IF V_ID_TIPO_AUSENCIA > 500 THEN

   UPDATE HORA_SINDICAL
   SET TOTAL_UTILIZADAS=TOTAL_UTILIZADAS+v_total_horas
   where
                id_ano=i_año_inicio AND --cambiado calculaba las horas sindicales
                id_MES=i_mes_inicio and  --cambiado calculaba las horas sindicales
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
   where id_ano=i_año_inicio AND  id_funcionario=V_ID_FUNCIONARIO;

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


end INSERTA_AUSENCIAS_RRHH;
/

