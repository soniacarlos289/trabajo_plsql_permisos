CREATE OR REPLACE PROCEDURE RRHH."INSERTA_PERMISO_RRHH"
       (    V_ID_USUARIO in varchar2,
        V_ID_ANO in number,
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

        todo_ok_Basico out integer,msgBasico out varchar2,
        V_OBSERVACIONES in  varchar2) is

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
i_firmado_js varchar2(6);

      i_firmado_ja varchar2(6);

      I_firmado_rrhh varchar2(6);

 i_cadena2 varchar2(512);
 i_desc_mensaje varchar2(10000);
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
-- 80 Concedido  RRHH


  i_Estado_permiso:=80;
  i_fecha_rrhh:=sysdate;


--obtenemos el dia y hora, secuencia de la operacion. ,secuencia del permiso
select sec_operacion.nextval,sec_permiso.nextval,to_char(sysdate,'DD/MM/YYYY'),
      to_char(sysdate,'HH:MI'),to_char(sysdate,'YYYY')
into  i_secuencia_operacion,i_secuencia_permiso,i_fecha,i_hora,i_id_ano
from dual;

      i_firmado_js:=  V_ID_USUARIO;
      I_fecha_js:= sysdate;
      i_firmado_ja:=   V_ID_USUARIO;
      I_fecha_ja:= sysdate;
      I_firmado_rrhh:=  V_ID_USUARIO;
      I_fecha_rrhh:= sysdate;


 --INSERT EN PERMISOS
 insert into permiso (
               id_permiso,
               id_ano,
               id_funcionario,
               id_tipo_permiso,
               id_estado,
                firmado_js,
               fecha_js,
               firmado_ja,
               fecha_ja,
               firmado_rrhh,
               fecha_rrhh,
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
             ,  fecha_modi,
              OBSERVACIONES
                           )
       vaLues
               (i_secuencia_permiso ,
                V_id_ANO,
                V_ID_FUNCIONARIO,
                V_ID_TIPO_PERMISO,
                i_estado_permiso,
                i_firmado_js,
               i_fecha_js,
               i_firmado_ja,
               i_fecha_ja,
               i_firmado_rrhh,
               i_fecha_rrhh,
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
                 V_ID_USUARIO
               ,to_date(to_char(sysdate,'DD/MM/yy'),'DD/MM/yy')
                ,V_OBSERVACIONES
                 );


 --Insert en el historico
  /* insert into historico_operaciones
      values(i_secuencia_operacion,
             i_secuencia_permiso ,
             80,
             v_id_ano,
             V_ID_FUNCIONARIO,
             i_fecha,
             i_hora,
             'ALTA PERMISO',
              V_ID_USUARIO,i_fecha);*/


end INSERTA_PERMISO_RRHH;
/

