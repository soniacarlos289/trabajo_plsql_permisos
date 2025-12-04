create or replace function rrhh.CHEQUEO_ENTRA_DELEGADO_TEST(V_ID_JS_DELEGADO IN VARCHAR2) return varchar2 is
  Result varchar2(256);

  i_contador number;
  i_resultado  varchar2(556);
  V_ID_JS varchar2(6);

   cursor c1  (V_JS_DELEGADO VARCHAR2) is
    select distinct id_JS
       from  funcionario_firma
       where
              id_delegado_js=V_JS_DELEGADO
              and id_js<>V_JS_DELEGADO; --a?adido 9 de enero 2010;


BEGIN

          V_ID_JS:=0;
          i_contador:=0;

    OPEN C1(V_ID_JS_DELEGADO);
    LOOP

      FETCH C1
            INTO  V_ID_JS;
      EXIT WHEN C1%NOTFOUND;



   BEGIN
       select distinct id_funcionario
       into  i_contador
       from  permiso
       where   to_date(to_char(sysdate,'DD/MM/YYYY'),'DD/MM/YYYY') between fecha_inicio and fecha_fin  and
              id_funcionario=V_id_js and
              ( ID_ANO=2014 OR ID_ANO=2015 OR ID_ANO=2016 OR ID_ANO=2017) and (ANULADO='NO' OR ANULADO IS NULL)
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
      i_resultado:=  i_contador ||','|| i_resultado;
   END IF;

 END LOOP;
   CLOSE C1;

--QUitarlo
    IF V_id_js=101286 then
       i_contador:=101286;
    END IF;
    --es suplente de 3 ,modificado el día 16/01/2017
    -- IF V_ID_JS_DELEGADO=101292 then
     -- i_resultado:=101121;
     --end if ;


Result:= i_resultado;
return(Result);
end CHEQUEO_ENTRA_DELEGADO_TEST;
/

