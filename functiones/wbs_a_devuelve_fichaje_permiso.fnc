create or replace function rrhh.
WBS_A_DEVUELVE_FICHAJE_PERMISO(V_ID_FUNCIONARIO in varchar2,
v_DIA_CALENDARIO in DATE) return varchar2 is

Resultado varchar2(12512);

 v_salida varchar2(12512);
 datos varchar2(12512);
  datos_tmp varchar2(12512);
i_encontrado number;
v_fichaje varchar2(5);
i_mas_fichaje  varchar2(5);
 d_id_dia date;
contador number;

Cursor Cfichajes_dia is
SELECT DISTINCT json_object('entrada' is to_char(ff.fecha_fichaje_entrada,'hh24:MI'),
                                'salida' is to_char(ff.fecha_fichaje_salida,'hh24:MI')),
                                ff.fecha_fichaje_entrada

    from fichaje_funcionario ff
    where to_Date(to_char( ff.fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy')=v_DIA_CALENDARIO
    and ff.id_funcionario=V_ID_FUNCIONARIO
    order by ff.fecha_fichaje_entrada;

begin

    i_encontrado:=1;
    v_salida  :='';
  contador:=0;
   datos :='';
   BEGIN
         select json_object('id_tipo_permiso' is tr.id_tipo_permiso,
                 'desc_tipo_permiso' is desc_tipo_permiso)
           into v_salida
           from permiso  p, tr_tipo_permiso  tr
          where id_funcionario=V_id_funcionario  and
                p.id_tipo_permiso = tr.id_tipo_permiso and
                 p.id_ano=tr.id_ano and
                v_DIA_CALENDARIO between p.fecha_inicio and nvl(p.fecha_fin,sysdate+1)   and
                (anulado='NO' OR ANULADO IS NULL) and id_estado not in ('30','31','32','40')
                  --probar baja 11300
                and rownum<2 and p.id_ano=2024;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
                  v_salida  :='';
                  i_encontrado:=0;
    END;

   resultado := ',{"permisos_dia": [' ||  v_salida  || ']}';


if I_encontrado = 0 then

--abrimos cursor.
    OPEN Cfichajes_dia;
    LOOP
      FETCH Cfichajes_dia
        into datos_tmp,
             d_id_dia;
      EXIT WHEN Cfichajes_dia%NOTFOUND;

      contador := contador + 1;

      if contador = 1 then
        datos := datos_tmp;
      else
        datos := datos || ',' || datos_tmp;
      end if;

    END LOOP;
    CLOSE Cfichajes_dia;

    resultado := ',{"fichajes_dia": [' || datos || ']}';

end if;

  return(Resultado);
end WBS_A_DEVUELVE_FICHAJE_PERMISO;
/

