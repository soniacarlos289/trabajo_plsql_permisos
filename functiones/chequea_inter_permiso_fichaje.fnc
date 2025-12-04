create or replace function rrhh.
CHEQUEA_INTER_PERMISO_FICHAJE(V_ID_FUNCIONARIO in varchar2,
v_DIA_CALENDARIO in DATE,v_posicion in number) return varchar2 is

Result varchar2(512);

v_desc_tipo_columna varchar2(512);
i_encontrado number;
v_fichaje varchar2(5);
i_mas_fichaje  varchar2(5);
begin

    i_encontrado:=1;
    v_desc_tipo_columna :='<td bgcolor=FFFFFF align="center"></td>';

    BEGIN
         select tc.desc_tipo_columna
           into v_desc_tipo_columna
           from permiso  p,    rrhh.tr_tipo_columna_calendario tc
          where id_funcionario=V_id_funcionario  and
                p.id_tipo_permiso = tc.id_tipo_permiso and
                p.id_estado = tc.id_tipo_estado   and
                v_DIA_CALENDARIO between fecha_inicio and nvl(fecha_fin,sysdate+1)   and
                (anulado='NO' OR ANULADO IS NULL) and id_estado not in ('30','31','32','40')
                and rownum<2;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
                  v_desc_tipo_columna :='<td bgcolor=FFFFFF align="center"></td>';
                  i_encontrado:=0;
    END;


if  i_encontrado= 0 then
   --bajas
   -- a?adido dia 31 marzo
    i_encontrado:=1;
   BEGIN
      select distinct tc.desc_tipo_columna
     into v_desc_tipo_columna
     from bajas_ilt b,rrhh.tr_tipo_columna_calendario tc
     where  id_funcionario=V_id_funcionario  and
           '88888' = tc.id_tipo_permiso and
           '80' =    tc.id_tipo_estado   and
           (  v_DIA_CALENDARIO between  FECHA_INICIO and FECHA_FIN )
                 and (ANULADA ='NO' OR ANULADA is NULL) and rownum<2;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
                  v_desc_tipo_columna :='<td bgcolor=FFFFFF align="center"></td>';
                   i_encontrado:=0;
    END;

END IF;
/*  CHM 30/03/2021

   No tiene vacaciones ni esta de baja ,DAME EL FICHAJE */

  i_encontrado:= 1;
    BEGIN
        select to_char(fecha_fichaje,'hh24:mi')
        into v_fichaje
         from
        (select id_funcionario,fecha_fichaje,rownum as fila from fichaje_funcionario_tran where id_funcionario in V_id_funcionario
            and to_date(to_char(fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy')=to_date(to_char(v_DIA_CALENDARIO,'dd/mm/yyyy'),'dd/mm/yyyy')
        order by id_funcionario, fecha_fichaje ) d where fila=v_posicion;
    EXCEPTION
             WHEN NO_DATA_FOUND THEN

                       i_encontrado:=0;
                        v_fichaje:=' ';
    END;

i_mas_fichaje:='A';

result:=replace(v_desc_tipo_columna, '</td>','') ||v_fichaje || '</td>';

    IF v_posicion =23 then
       BEGIN
        select count(*)
        into v_fichaje
         from
        (select id_funcionario,fecha_fichaje,rownum as fila from fichaje_funcionario_tran where id_funcionario in V_id_funcionario
            and to_date(to_char(fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy') between to_date(to_char(v_DIA_CALENDARIO,'dd/mm/yyyy'),'dd/mm/yyyy')-7
            and    to_date(to_char(v_DIA_CALENDARIO,'dd/mm/yyyy'),'dd/mm/yyyy') -1
        order by id_funcionario, fecha_fichaje ) group by to_char(fecha_fichaje,'dd/mm/yyyy') having count(*)>2;
         EXCEPTION
             WHEN NO_DATA_FOUND THEN
                       i_encontrado:=0;
                      i_mas_fichaje:='B';
                   when   too_many_rows then
                     i_mas_fichaje:='A';
         END;
           result:= i_mas_fichaje;
    end if;
    IF v_posicion =33 then
       BEGIN
        select count(*)
        into v_fichaje
         from
        (select id_funcionario,fecha_fichaje,rownum as fila from fichaje_funcionario_tran where id_funcionario in V_id_funcionario
           and to_date(to_char(fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy') between to_date(to_char(v_DIA_CALENDARIO,'dd/mm/yyyy'),'dd/mm/yyyy')-7
            and    to_date(to_char(v_DIA_CALENDARIO,'dd/mm/yyyy'),'dd/mm/yyyy') -1
            order by id_funcionario, fecha_fichaje ) group by to_char(fecha_fichaje,'dd/mm/yyyy') having count(*)>4;
        EXCEPTION
             WHEN NO_DATA_FOUND THEN
                       i_encontrado:=0;
                      i_mas_fichaje:='B';
                   when   too_many_rows then
                     i_mas_fichaje:='A';
         END;
         result:= i_mas_fichaje;
    end if;

  return(Result);
end CHEQUEA_INTER_PERMISO_FICHAJE;
/

