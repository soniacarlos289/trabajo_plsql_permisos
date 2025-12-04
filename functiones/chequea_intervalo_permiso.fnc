create or replace function rrhh.
CHEQUEA_INTERVALO_PERMISO(V_ID_FUNCIONARIO in varchar2,
v_DIA_CALENDARIO in DATE) return varchar2 is

Result varchar2(512);

v_desc_tipo_columna varchar2(512);
i_encontrado number;

begin

    i_encontrado:=1;

    BEGIN
         select tc.desc_tipo_columna
           into v_desc_tipo_columna
           from permiso  p,    rrhh.tr_tipo_columna_calendario tc
          where id_funcionario=V_id_funcionario  and
                p.id_tipo_permiso = tc.id_tipo_permiso and
                p.id_estado = tc.id_tipo_estado   and
                v_DIA_CALENDARIO between fecha_inicio and fecha_fin   and
                (anulado='NO' OR ANULADO IS NULL) and id_estado not in ('30','31','32','40')
                and rownum<2;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
                  v_desc_tipo_columna :='<td bgcolor=FFFFFF> </td>';
                  i_encontrado:=0;
    END;


if  i_encontrado= 0 then
   --bajas
   -- a?adido dia 31 marzo
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
                  v_desc_tipo_columna :='<td bgcolor=FFFFFF> </td>';
    END;

END IF;


    result:=v_desc_tipo_columna;



  return(Result);
end CHEQUEA_INTERVALO_PERMISO;
/

