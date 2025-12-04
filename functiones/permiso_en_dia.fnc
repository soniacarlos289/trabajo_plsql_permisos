create or replace function rrhh.
PERMISO_EN_DIA(V_ID_FUNCIONARIO in varchar2,
v_DIA in DATE) return varchar2 is

Result varchar2(512);


i_encontrado number;
v_id_permiso number;

i_TIPO_justifica varchar2(2);
i_permiso_justifica varchar2(2);

begin

    i_encontrado:=1;
    v_id_permiso:=1;

    BEGIN
         select id_permiso ,tc.JUSTIFICACION,nvl(p.justificacion,'NO')
         into v_id_permiso,i_TIPO_justifica, i_permiso_justifica
           from permiso  p,  tr_tipo_permiso tc
          where id_funcionario=V_id_funcionario  and
                p.id_tipo_permiso = tc.id_tipo_permiso and
                p.id_ano = tc.id_ano and
                v_DIA between p.fecha_inicio and nvl(p.fecha_fin,sysdate+1)   and
                (anulado='NO' OR ANULADO IS NULL) and id_estado  in ('80')
                and p.id_tipo_permiso not in (15000)

                and rownum<2;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN

                  i_encontrado:=0;
                  v_id_permiso:=0;
    END;


if  v_id_permiso<> 0  AND i_TIPO_justifica='SI' AND i_permiso_justifica='NO' then
    v_id_permiso:=0;
END IF;


    result:=v_id_permiso;



  return(Result);
end PERMISO_EN_DIA;
/

