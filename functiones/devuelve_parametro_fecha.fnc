create or replace function rrhh.DEVUELVE_PARAMETRO_FECHA
  (I_FILTRO_2 IN VARCHAR2,I_FILTRO_2_PARA IN VARCHAR2) return varchar2 is
  Result varchar2(122);

 v_fecha_inicio date;
 v_fecha_fin    date;
 i_id_dia          date;

begin

--PARA EL AÑO
IF I_FILTRO_2 ='A'  THEN

     Begin
       SELECT min(id_dia)
            into v_fecha_inicio
        FROM calendario_laboral
        where id_ano=I_FILTRO_2_PARA;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          result:='0';
       END;

     Begin
       SELECT max(id_dia)
            into v_fecha_fin
        FROM calendario_laboral
        where id_ano=I_FILTRO_2_PARA;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          result:='0';
       END;
  REsult:='FI' || to_char(v_fecha_inicio,'dd/mm/yyyy') || ';FF' || to_char(v_fecha_fin,'dd/mm/yyyy') ||';';
  return(Result);

END IF;

--PARA PERIODO
IF I_FILTRO_2 ='P'  THEN

          Begin
             select inicio,fin
             into v_fecha_inicio, v_fecha_fin
             from webperiodo
                where to_char(mes || ano) = I_FILTRO_2_PARA;
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
               result:='0';
             END;



        --dia anterior
        IF I_FILTRO_2_PARA = 'DA' THEN
           v_fecha_inicio:=sysdate-1;
           v_fecha_fin:=sysdate-1;
        END IF;

        --mes anterior
        IF I_FILTRO_2_PARA = 'MA' THEN

           i_id_dia:= ADD_MONTHS(sysdate,-1);

             Begin
               SELECT min(id_dia)
                into v_fecha_inicio
               FROM calendario_laboral
             where to_date(to_char(id_dia,'mm/yyyy'),'mm/yyyy')=to_Date(to_char(i_id_dia,'mm/yyyy'),'mm/yyyy');
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
               result:='0';
             END;

              Begin
               SELECT max(id_dia)
                into v_fecha_fin
               FROM calendario_laboral
               where to_date(to_char(id_dia,'mm/yyyy'),'mm/yyyy')=to_Date(to_char(i_id_dia,'mm/yyyy'),'mm/yyyy');
             EXCEPTION
             WHEN NO_DATA_FOUND THEN
               result:='0';
             END;

        END IF;

        --periodo anterior
        IF I_FILTRO_2_PARA = 'PA' THEN

            Begin
             select inicio,fin
             into v_fecha_inicio, v_fecha_fin
             from webperiodo
                where ano || mes in (
                     select DECODE(to_number(mes) - 1, 0, to_number(ano) - 1, ano) ||
                            DECODE(to_number(mes) - 1, 0, '12', lpad(to_number(mes)-1, 2, '0')) as anomes
                     from webperiodo
             where sysdate between inicio and fin);
            EXCEPTION
             WHEN NO_DATA_FOUND THEN
               result:='0';
             END;
        END IF;


  REsult:='FI' || to_char(v_fecha_inicio,'dd/mm/yyyy') || ';FF' || to_char(v_fecha_Fin,'dd/mm/yyyy') ||';';
  return(Result);

END IF;

IF I_FILTRO_2 ='M'  THEN

 REsult:=I_FILTRO_2_PARA;
  return(Result);

END IF;

end DEVUELVE_PARAMETRO_FECHA;
/

