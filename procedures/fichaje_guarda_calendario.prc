CREATE OR REPLACE PROCEDURE RRHH."FICHAJE_GUARDA_CALENDARIO" (
          V_ID_CALENDARIO in number,
          V_DESC_CALENDARIO in varchar2,
          v_audit_usuario in varchar2,
          V_TURNO in varchar2,
          v_horas_semanales in number,
          V_ID_TODO in varchar2,
          msgsalida out varchar2,todook out varchar2) is

v_cadena_t varchar2(22222);

 i_id_tipo_ausencia number;
 v_tr_anulado varchar(2);
 v_id_tipo_ausencia_c varchar(4);
 msgBasico  varchar2(255);
 v_horas  varchar2(5);
 i_horas varchar2(8);
 i_horas_n number;
 i_minutos varchar2(8);
 i_minutos_n number;
  i_id_mes number;
  i_actualizado number;


i_id_calendario number;

 campo1 varchar2(100);
 campo2 varchar2(100);
 campo3 varchar2(100);
 campo4 varchar2(100);

 campor varchar2(100);

 pos number;
 pos2 number;

 i_que_campo number;
 v_dia number;
 V_horas_teoricas date;
 V_p1_obl_desde date;--2
 V_p1_obl_hasta date;--3
 V_p1_fle_desde date;--4
 V_p1_fle_hasta date;--5
 V_p2_obl_desde date;--6
 v_p2_obl_hasta date;--7
 v_p2_fle_desde date;--8
 v_p2_fle_hasta date;--9
 v_p3_obl_desde date;--10
 V_p3_obl_hasta date;--11
 V_p3_fle_desde date;--12
 v_p3_fle_hasta date;--13
 /*            fecha_inicio,
             fecha_fin*/

begin

 v_cadena_t:='';
 /*msgsalida:= to_char(V_ID_CALENDARIO) || ' ' ||V_DESC_CALENDARIO|| ' ' ||
          V_TURNO || ' ' ||
          v_audit_usuario;
         rollback;
         return;*/
   i_actualizado:=0;
 --Calendario es nuevo. INSERCIÛN  FICHAJE_CALENDARIO
 IF  V_ID_CALENDARIO = 0 then

            select max(id_calendario)+1 into  i_id_calendario      from fichaje_calendario where rownum<2;

            insert into fichaje_calendario
              (id_calendario, desc_calendario, dias, horas_semanales, turno, audit_usuario, audit_fecha, fecha_inicio)
            values
              (i_id_calendario, v_desc_calendario, '5', v_horas_semanales, v_turno, v_audit_usuario, sysdate, to_date(to_char(sysdate,'dd/mm/yyyy'),'dd/mm/yyyy'));
 ELSE --Actualizo el que esta.

             BEGIN
                   insert into fichaje_calendario
              (id_calendario, desc_calendario, dias, horas_semanales, turno, audit_usuario, audit_fecha, fecha_inicio)
              values
              (v_id_calendario, v_desc_calendario, 5, v_horas_semanales, v_turno, v_audit_usuario, sysdate, to_date(to_char(sysdate,'dd/mm/yyyy'),'dd/mm/yyyy'));
                EXCEPTION
             WHEN  DUP_VAL_ON_INDEX THEN
               update   fichaje_calendario
               set desc_calendario = v_desc_calendario,
                   horas_semanales = v_horas_semanales,
                   turno =  v_turno,
                   audit_usuario =  v_audit_usuario,
                   audit_fecha = sysdate
               where
                  id_calendario=v_id_calendario;

                  i_actualizado:=1;
             END;

            if   i_actualizado = 0 then
                        update   fichaje_calendario
                        set fecha_fin=  to_date(to_char(sysdate-1,'dd/mm/yyyy'))
                        where id_calendario=to_char(V_ID_CALENDARIO) and fecha_fin is null
                              and fecha_inicio<sysdate-1;
            end if;

      i_actualizado:=0;

 END IF;

      v_cadena_t:='';

      FOR x IN 0 .. 6 LOOP
        i_que_campo:=1;--que campo tengo que meter en base de datos
         V_p1_obl_desde:=null;
         V_p1_obl_hasta:=null;
         V_p1_fle_desde:=null;
         V_p1_fle_hasta:=null;
         V_p2_obl_desde:=null;
         V_p2_obl_hasta:=null;
         V_p2_fle_desde:=null;
         V_p2_fle_hasta:=null;
         V_p3_obl_desde:=null;
         V_p3_obl_hasta:=null;
         V_p3_fle_desde:=null;
         V_p3_fle_hasta:=null;
          V_horas_teoricas:=null;

        FOR y IN 1 .. 3 LOOP
           FOR W IN 1 .. 4 LOOP
             i_que_campo:=i_que_campo+1;
             campo1:= x || 'P' || y || 'OMD';
             campo2:= x || 'P' || y || 'OMH';
             campo3:= x || 'P' || y || 'FMD';
             campo4:= x || 'P' || y || 'FMH';

             IF  W  = 1 then
                  campor:=campo1;
                ELSE IF  W  = 2 then
                          campor:=campo2;
                       ELSE IF  W  = 3 then
                                  campor:=campo3;
                             ELSE IF  W  = 4 then
                                        campor:=campo4;
                                  END IF;
                            END IF;
                     END IF;
                END IF;

            pos:=instr (V_ID_TODO, campor,1,1)+6;
            pos2:=instr (V_ID_TODO,';', pos,1);

            if pos2-pos> 1 and pos2-pos<6  then

               v_horas:=substr(V_ID_TODO, pos,pos2-pos);
               pos:=instr(v_horas,':',1,1);
               i_horas:=lpad(substr(v_horas,1,pos-1),2,'0');
               i_minutos:=lpad(substr(v_horas,pos+1,2),2,'0');


            --Comprobamos que es numero
            if   es_numero(i_horas) = 0 then
                 i_horas_n:=to_number(i_horas);
            else
                 i_horas_n:=0;
                 msgsalida:='Error en las Horas. Del campo: '|| x || 'P' || y || 'OMD'  ;
                 todook:='1';
                 rollback;
                 return;
            end if;

            --Comprobamos que es numero
            if   es_numero(i_minutos) = 0 then
                 i_minutos_n:=to_number(i_minutos);
            else
                 i_minutos_n:=0;
                 i_horas_n:=0;
                 msgsalida:='Error en las Minutos. Del campo: '|| x || 'P' || y || 'OMD'  ;
                 todook:='1';
                 rollback;
                 return;
           end if;

            v_cadena_t:= v_cadena_t ||'x' || x ||' y'|| y || ' w'|| w || ' '||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ;

            -- que campo hay que actualizar
            case
              WHEN  i_que_campo=2 THEN V_p1_obl_desde:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');
              WHEN  i_que_campo=3 THEN V_p1_obl_hasta:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');
              WHEN  i_que_campo=4 THEN V_p1_fle_desde:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');
              WHEN  i_que_campo=5 THEN V_p1_fle_hasta:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');
              WHEN  i_que_campo=6 THEN V_p2_obl_desde:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');
              WHEN  i_que_campo=7 THEN V_p2_obl_hasta:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');
              WHEN  i_que_campo=8 THEN V_p2_fle_desde:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');
              WHEN  i_que_campo=9 THEN V_p2_fle_hasta:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');
              WHEN  i_que_campo=10 THEN V_p3_obl_desde:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');
              WHEN  i_que_campo=11 THEN V_p3_obl_hasta:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');
              WHEN  i_que_campo=12 THEN V_p3_fle_desde:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');
              WHEN  i_que_campo=13 THEN V_p3_fle_hasta:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');

              ELSE   V_p1_obl_hasta:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');
            END CASE;
          end if;

       end loop;    --w  4 campos
      end loop; --y periodos

      --Buscamos las horas  V_horas_teoricas
      pos:=instr (V_ID_TODO,x|| 'HORAS'  ,1,1)+6;
      pos2:=instr (V_ID_TODO,';', pos,1);

         if pos2-pos> 1 and pos2-pos<6 then

               v_horas:=substr(V_ID_TODO, pos,pos2-pos);
               pos:=instr(v_horas,':',1,1);
               i_horas:=lpad(substr(v_horas,1,pos-1),2,'0');
               i_minutos:=lpad(substr(v_horas,pos+1,2),2,'0');

       --Comprobamos que es numero
            if   es_numero(i_horas) = 0 then
                 i_horas_n:=to_number(i_horas);
            else
                 i_horas_n:=0;
                 msgsalida:='Error en las Horas. Del campo Horas Teoricas'  ;
                 todook:='1';
                 rollback;
                 return;
            end if;

       --Comprobamos que es numero
            if   es_numero(i_minutos) = 0 then
                 i_minutos_n:=to_number(i_minutos);
            else
                 i_minutos_n:=0;
                 i_horas_n:=0;
                 msgsalida:='Error en las Horas. Del campo Horas Teoricas';
                 todook:='1';
                 rollback;
                 return;
           end if;



         V_horas_teoricas:=to_date('01/01/1900 ' ||  lpad(i_horas,2,'0') ||':'||lpad(i_minutos,2,'0') ,'DD/mm/yyyy hh24:mi');
         end if;

         v_dia:=x+2;


         i_actualizado:=0;
         --Calendario es nuevo. INSERCIÛN  FICHAJE_calendario_jornada
         IF  V_ID_CALENDARIO = 0 then
             insert into fichaje_calendario_jornada
             (id_calendario, dia, horas_teoricas, p1_obl_desde, p1_obl_hasta, p1_fle_desde, p1_fle_hasta, p2_obl_desde, p2_obl_hasta, p2_fle_desde, p2_fle_hasta, p3_obl_desde, p3_obl_hasta, p3_fle_desde, p3_fle_hasta, audit_usuario, audit_fecha, fecha_inicio)
             values
             (i_id_calendario, v_dia, v_horas_teoricas, v_p1_obl_desde, v_p1_obl_hasta, v_p1_fle_desde, v_p1_fle_hasta, v_p2_obl_desde, v_p2_obl_hasta, v_p2_fle_desde, v_p2_fle_hasta, v_p3_obl_desde, v_p3_obl_hasta, v_p3_fle_desde, v_p3_fle_hasta, v_audit_usuario,sysdate, to_date(to_char(sysdate,'dd/mm/yyyy'),'dd/mm/yyyy'));

         ELSE --Actualizo el que esta.

              BEGIN
                   insert into fichaje_calendario_jornada
                    (id_calendario, dia, horas_teoricas, p1_obl_desde, p1_obl_hasta, p1_fle_desde, p1_fle_hasta, p2_obl_desde, p2_obl_hasta, p2_fle_desde, p2_fle_hasta, p3_obl_desde, p3_obl_hasta, p3_fle_desde, p3_fle_hasta, audit_usuario, audit_fecha, fecha_inicio)
                  values
                    (v_id_calendario, v_dia, v_horas_teoricas, v_p1_obl_desde, v_p1_obl_hasta, v_p1_fle_desde, v_p1_fle_hasta, v_p2_obl_desde, v_p2_obl_hasta, v_p2_fle_desde, v_p2_fle_hasta, v_p3_obl_desde, v_p3_obl_hasta, v_p3_fle_desde, v_p3_fle_hasta, v_audit_usuario,sysdate, to_date(to_char(sysdate,'dd/mm/yyyy'),'dd/mm/yyyy'));
              EXCEPTION
             WHEN DUP_VAL_ON_INDEX THEN
               update   fichaje_calendario_jornada
               set horas_teoricas =   v_horas_teoricas,
                   p1_obl_desde =  v_p1_obl_desde,
                   p1_obl_hasta =  v_p1_obl_hasta,
                   p1_fle_desde =  v_p1_fle_desde,
                   p1_fle_hasta =  v_p1_fle_hasta,
                   p2_obl_desde =  v_p2_obl_desde,
                   p2_obl_hasta =  v_p2_obl_hasta,
                   p2_fle_desde =  v_p2_fle_desde,
                   p2_fle_hasta =  v_p2_fle_hasta,
                   p3_obl_desde =  v_p3_obl_desde,
                   p3_obl_hasta =  v_p3_obl_hasta,
                   p3_fle_desde =  v_p3_fle_desde,
                   p3_fle_hasta =  v_p3_fle_hasta,
                   audit_usuario =  v_audit_usuario,
                   audit_fecha = sysdate
               where
                  id_calendario=v_id_calendario and
                  dia=v_dia ;
                  i_actualizado:=1;
             END;

        --La insercion fue correcta, no hubo actualizaciÛn.
        IF i_actualizado = 0 then
            update   fichaje_calendario_jornada
            set fecha_fin=  to_date(to_char(sysdate-1,'dd/mm/yyyy'))
            where id_calendario=to_char(V_ID_CALENDARIO) and fecha_fin is null
            and fecha_inicio<sysdate-1;
        end if;


         END IF;



end loop; --x dias

COMMIT;
msgsalida:=v_cadena_t;
todook:='0';
END FICHAJE_GUARDA_CALENDARIO;
/

