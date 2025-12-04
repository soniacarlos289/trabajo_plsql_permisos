create or replace function rrhh.CHEQUEA_VACACIONES_JS(V_ID_JS IN VARCHAR2) return varchar2 is
  Result varchar2(256);

  i_contador number;
  i_resultado number;



BEGIN

   i_contador:=0;

   BEGIN
       select distinct id_funcionario
       into  i_contador
       from  permiso
       where   to_date(to_char(sysdate,'DD/MM/YYYY'),'DD/MM/YYYY') between fecha_inicio and fecha_fin  and
              id_funcionario=V_id_js and
              (id_ano=2010 OR ID_ANO=2011 OR ID_ANO=2012 OR ID_ANO=2013 OR ID_ANO=2014) and (ANULADO='NO' OR ANULADO IS NULL)
              and id_estado not in ('30','31','32','40');
   EXCEPTION
          WHEN NO_DATA_FOUND THEN
          i_contador:=0;
   END;

    --A?adido 5 de Abril 2010
    --Bajas en la firma de ausencias
    IF i_contador = 0 then
      BEGIN
        select distinct id_funcionario
          into i_contador
          from bajas_ilt
         where id_funcionario = V_id_js
           and to_date(to_char(sysdate, 'DD/MM/YYYY'), 'DD/MM/YYYY') between
               FECHA_INICIO and FECHA_FIN
           and (ANULADA = 'NO' OR ANULADA is NULL);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_contador := 0;
      END;
    END IF;

    IF i_contador <> 0 then
      i_resultado:=1;
    else
        i_resultado:=0;
   END IF;


Result:= i_resultado;
return(Result);
end CHEQUEA_VACACIONES_JS;
/

