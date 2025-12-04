CREATE OR REPLACE PROCEDURE RRHH."FINGER_BUSCA_JORNADA_FUN" (i_id_funcionario  in varchar2,
                                                 v_fecha_p in date,
                                                 V_p1d in out number,
                                                 V_p1h in out number,
                                                 V_p2d in out number,
                                                 V_p2h in out number,
                                                 V_p3d in out number,
                                                 V_p3h in out number,
                                                 V_po1d in out number,
                                                 V_po1h in out number,
                                                 V_po2d in out number,
                                                 V_po2h in out number,
                                                 V_po3d in out number,
                                                 V_po3h in out number,
                                                 V_contar_comida in out number,
                                                 V_libre in out number ,
                                                  V_turnos in out number ,
                                                 V_SIN_CALENDARIO    in out number
                                                 ) is



  dia_semana        number;

Begin

                 --Si da 1 se ejecuta desde la web
                --si da 2 se ejecuta desde pl/sql
                select tO_char(to_date('07/01/2019','dd/mm/yyyy'), 'D') into  dia_semana  from dual;

                If dia_semana = 1 THEN
                  dia_semana:=1;
                ELSE
                  dia_semana:=0;
                End if;

                --buscamos periodo del fichaje
                BEGIN
                   select distinct to_char(p1_fle_desde,'hh24mi') as p1d,
                          to_char(p1_fle_hasta,'hh24mi') as p1h,
                          to_char(p2_fle_desde,'hh24mi') as p2d,
                          to_char(p2_fle_hasta,'hh24mi') as p2h,
                          to_char(p3_fle_desde,'hh24mi') as p3d,
                          to_char(p3_fle_hasta,'hh24mi') as p3h,
                          to_char(p1_obl_desde,'hh24mi') as po1d,
                          to_char(p1_obl_hasta,'hh24mi') as po1h,
                          to_char(p2_obl_desde,'hh24mi') as po2d,
                          to_char(p2_obl_hasta,'hh24mi') as po2h,
                          to_char(p3_obl_desde,'hh24mi') as po3d,
                          to_char(p3_obl_hasta,'hh24mi') as po3h,
                          DECODE(CONTAR_COMIDA,'SI',1,0),
                          DECODE(LIBRE,'SI',1,0),DECODE(TURNO,'SI',1,0)
                                    into  v_p1d,v_p1h,
                                          v_p2d,v_p2h,
                                          v_p3d,v_p3h ,
                                          v_po1d,v_po1h,
                                          v_po2d,v_po2h,
                                          v_po3d,v_po3h ,
                                          v_contar_comida,v_libre,v_turnos
                     from FICHAJE_CALENDARIO_JORNADA t, fichaje_funcionario_jornada ff,  fichaje_calendario fc
             where t.id_calendario=ff.id_calendario and
                 t.id_calendario=fc.id_calendario and
                    id_funcionario=i_id_funcionario and        dia=DECODE(to_number(to_char(v_fecha_p,'d'))+dia_semana,1,8, to_char(v_fecha_p,'d')+dia_semana) and
                         --to_date('01/01/2018','DD/mm/YYYY') ---> cambiar dia que estamos consultando.

                         v_fecha_p between ff.fecha_inicio  and nvl(ff.fecha_fin,sysdate+1) AND
                         v_fecha_p between t.fecha_inicio  and  nvl(t.fecha_fin,sysdate+1);
                EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                         V_SIN_CALENDARIO :=0;
                   WHEN TOO_MANY_ROWS THEN
                      V_SIN_CALENDARIO :=0;
                 END;



end FINGER_BUSCA_JORNADA_FUN;
/

