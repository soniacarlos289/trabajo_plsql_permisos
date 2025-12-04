create or replace function rrhh.
CHEQUEA_ENLACE_FICHERO_JUSTI(V_ANNO in varchar2,V_ID_FUNCIONARIO in varchar2,
                           v_ID_PERMISO in varchar2) return varchar2 is

Result varchar2(5012);

  i_encontrado number;
  v_desc_tipo_columna varchar2(4024);


begin

    i_encontrado:=1;
    v_desc_tipo_columna :='';





--buscamos el enlace
      BEGIN
           select distinct id
             into i_encontrado
             from ficheros_justificantes
            where id=V_ANNO || V_ID_FUNCIONARIO ||v_ID_PERMISO;
      EXCEPTION
           WHEN NO_DATA_FOUND THEN
                       i_encontrado:=0;
      END;

      result:= '';
    if  i_encontrado>0 then
         result:=   V_ANNO || V_ID_FUNCIONARIO ||v_ID_PERMISO ;
    Else
          result:=  'Sin Justificar' ;
    end if;

  return(Result);
end CHEQUEA_ENLACE_FICHERO_JUSti;
/

