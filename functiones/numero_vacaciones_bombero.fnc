create or replace function rrhh.NUMERO_VACACIONES_BOMBERO(D_FECHA_INICIO IN date ,D_FECHA_FIN IN date,D_FUNCIONARIO IN VARCHAR2,V_numero  out number) return varchar2 is
  Result varchar2(1256);

  i_contador number;
  i_resultado number;
  V_GUARDIA varchar2(255);
  v_RESULTADO varchar2(377);

   cursor c1  (V_FECHA_INICIO date ,V_FECHA_FIN date,V_FUNCIONARIO varchar2) is
    select 'Guardia: '|| GUARDIA || ' -- ' from bomberos_guardias_plani --sige.GUARDIAS@lsige
      where
      desde between  to_date(to_char(V_FECHA_INICIO,'dd/mm/yyyy')  || '08:00' ,'dd/mm/yyyy hh24:mi') and
                      to_date(to_char(v_FECHA_FIN ,'dd/mm/yyyy')   ||  '08:00','dd/mm/yyyy hh24:mi')  and substr(guardia,1,7) > 2017001
               And funcionario=v_funcionario
               order by 1;


BEGIN

          v_RESULTADO:='';
          i_contador:=0;

    OPEN C1(D_FECHA_INICIO,D_FECHA_FIN,d_FUNCIONARIO );
    LOOP

      FETCH C1
            INTO   V_GUARDIA;
      EXIT WHEN C1%NOTFOUND;

 v_RESULTADO:= v_RESULTADO ||V_GUARDIA ;
 i_contador:=1+i_contador;

 END LOOP;
   CLOSE C1;

    V_numero:=i_contador;

Result:= v_RESULTADO;
return(Result);
end NUMERO_VACACIONES_BOMBERO;
/

