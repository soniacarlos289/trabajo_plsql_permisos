CREATE OR REPLACE PROCEDURE RRHH."HORAS_SINDICALES" (
          V_ID_FUNCIONARIO in number,
          ID_FUNCIONARIO_NOMBRE in varchar2,
          V_ID_TIPO_AUSENCIA in varchar2,
          V_ID_SINDICATO in varchar2,
          V_ID_HORAS_SINDICALES in varchar2,
          V_ID_ANO in number,
          msgsalida out varchar2,todook out varchar2) is


 i_id_tipo_ausencia number;
 v_tr_anulado varchar(2);
 v_id_tipo_ausencia_c varchar(4);
 msgBasico  varchar2(255);

 i_horas varchar2(8);
 i_horas_n number;
 i_minutos varchar2(8);
 i_minutos_n number;
  i_id_mes number;
 i integer;
 i_pc number;
 V_ID_FUNCIONARIO_NOMBRE  varchar2(512);
begin

begin
select  nombre || ' ' || ape1 || ' ' ape2
into V_ID_FUNCIONARIO_NOMBRE
from personal_new where id_funcionario=V_ID_FUNCIONARIO
and rownum<2;
 EXCEPTION
    WHEN NO_DATA_FOUND THEN
       V_ID_FUNCIONARIO_NOMBRE:='Sin nombre';--ausencia no encontrada


  end;
--chm 20/11/2017
 --Compruebo que el funcionario no este primero en las horas sindicales

  i_id_tipo_ausencia:=1;
  BEGIN
  select distinct TR.TR_ANULADO, TR.ID_TIPO_AUSENCIA
     into v_tr_anulado,v_id_tipo_ausencia_c
     from tr_tipo_ausencia tr ,hora_sindical h
  where h.id_funcionario= V_ID_FUNCIONARIO and
      TR.ID_TIPO_AUSENCIA =h.ID_TIPO_AUSENCIA
       and rownum<2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       i_id_tipo_ausencia:=0;--ausencia no encontrada
  END;


 if i_id_tipo_ausencia =1 then --funcionario ya tenia horas sindicales.
      --Actualiza la ausencia por si estaba ANULADA
      update RRHH.TR_TIPO_AUSENCIA
         set           tr_anulado = 'NO'
      where id_tipo_ausencia = V_ID_TIPO_AUSENCIA_C ;
 else
       insert into tr_tipo_ausencia
         (id_tipo_ausencia, desc_tipo_ausencia, id_usuario, fecha_modi, tr_anulado)
       values
         (v_id_tipo_ausencia,      V_ID_SINDICATO || ' '||    V_ID_FUNCIONARIO_NOMBRE  , 101217, sysdate, 'NO');

 end if;
    i_pc:=0;
   FOR i IN 65 .. 76 LOOP
        i_id_mes:=i-64;

          i_pc:=1+i_pc;
       --todos
        i_horas:=REPLACE(substr(V_ID_HORAS_SINDICALES,instr(V_ID_HORAS_SINDICALES,  Chr(i) || 'H',1,1),instr(V_ID_HORAS_SINDICALES,';',1,  i_pc)-instr(V_ID_HORAS_SINDICALES,Chr(i) || 'H',1,1)) ,Chr(i) || 'H',' ');
       --Comprobamos que es numero
        if   es_numero(i_horas) = 0 then
            i_horas_n:=to_number(i_horas);
        else
            i_horas_n:=0;
        end if;
        i_pc:=1+i_pc;
         --todos
        i_minutos:=REPLACE(substr(V_ID_HORAS_SINDICALES,instr(V_ID_HORAS_SINDICALES,  Chr(i) || 'M',1,1),instr(V_ID_HORAS_SINDICALES,';',1,  i_pc)-instr(V_ID_HORAS_SINDICALES,Chr(i) || 'M',1,1)) ,Chr(i) || 'M',' ');
       --Comprobamos que es numero
        if   es_numero(i_minutos) = 0 then
            i_minutos_n:=to_number(i_minutos);
        else
            i_minutos_n:=0;
        end if;


/* todook:='1';
    msgsalida:='Por' || i_horas_n || 'aa ' || i_minutos_n;
   return;
rollback;*/

        if i_id_tipo_ausencia =1 then --funcionario ya tenia horas sindicales.

              --todos
              update hora_sindical
              set  total_horas = i_horas_n * 60  + i_minutos_n,
                   fecha_modi = sysdate
              where id_ano = V_ID_ANO  and
                    id_mes =  i_id_mes and
                    id_tipo_ausencia=V_ID_TIPO_AUSENCIA_C and
                    id_funcionario=V_ID_FUNCIONARIO and rownum<2;
                    commit;
           /*  if   i_id_mes > 11 then

 todook:='1';
    msgsalida:=V_ID_ANO || ' ' || i_ID_MES || ' ' ||V_ID_TIPO_AUSENCIA_C|| ' Por' ||  i_horas_n ||' '|| V_ID_FUNCIONARIO ||' '|| i_id_tipo_ausencia;
   return;
rollback;
end if;*/

        else
            insert into hora_sindical
               (id_hora_sindical, id_funcionario, id_ano, id_mes, id_tipo_ausencia, total_horas, total_utilizadas, id_usuario, fecha_modi)
             values
               (sec_tr_tipo_ausencia.nextval, v_id_funcionario, V_ID_ANO, i_id_mes, v_id_tipo_ausencia, i_horas_n * 60  + i_minutos_n, 0, 101217, sysdate);


         end if;
   end loop;














   todook:='1';
    msgBasico      := 'Operacion no realizada. TIPO FUNCIONARIO NO ENCONTRADO.';
  /*
 todook:='1';
    msgsalida:='Por motivos de Administración no se pueden solicitar ausencias hasta 13:00. Perdón por las molestias' || V_ID_TIPO_FUNCIONARIO;
   return;
rollback;
*/
 /*
 todook:='1';
 msgsalida:='Solo se pueden solicitar los permisos de Vacaciones, Asuntos Propios, Compensatorios, Compensatorio por horas y dias por Antiguedad';
 return;
 rollback;
*/


COMMIT;
msgsalida:='La solicitud de ausencia ha sido enviada para su firma.';
todook:='0';
END HORAS_SINDICALES;
/

