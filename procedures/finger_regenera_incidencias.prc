CREATE OR REPLACE PROCEDURE RRHH."FINGER_REGENERA_INCIDENCIAS" (i_id_incidencia   in varchar2,
                                                 i_todos in varchar2) is

 i_id_inc number;
 v_fecha_incidencia date;
 v_fecha_inc date;

 i_id_funcionario number;
v_id_funcionario number;
i_tipo_funcionario number;

  cursor c1(i_id_funcionario varchar2,v_fecha_incidencia date) is
    select distinct fecha_incidencia,f.id_funcionario,   nvl(tipo_funcionario2,0)   from fichaje_incidencia f,personal_new p
 where     fecha_incidencia=v_fecha_incidencia
       and p.id_funcionario=f.id_funcionario
       and (f.id_funcionario=i_id_funcionario OR 0=i_id_funcionario)
        order by 1 desc;


begin

      i_id_inc :=1;
   BEGIN
   select fecha_incidencia,id_funcionario
        into v_fecha_incidencia,i_id_funcionario
   from fichaje_incidencia
   where id_incidencia=i_id_incidencia  and rownum<2;
   EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    i_id_inc :=0;
                END;

  IF i_todos=1 then

   i_id_funcionario:=0;
  END IF;


  OPEN C1(i_id_funcionario,v_fecha_incidencia);
  LOOP

    FETCH C1
      INTO v_fecha_inc,v_id_funcionario,i_tipo_funcionario;
    EXIT WHEN C1%NOTFOUND;
     IF i_tipo_funcionario <> 21 then
      finger_calcula_saldo(v_id_funcionario,v_fecha_incidencia);
     ELSE
            finger_calcula_saldo_policia(v_id_funcionario,v_fecha_incidencia);
     END IF;

  END LOOP;
  CLOSE C1;


end FINGER_REGENERA_INCIDENCIAS;
/

