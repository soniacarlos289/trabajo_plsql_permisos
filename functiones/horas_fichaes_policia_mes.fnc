create or replace function rrhh.HORAS_FICHAES_POLICIA_MES(i_ID_FUNCIONARIO IN VARCHAR2,
i_MES IN number,i_id_Anno in number)
 return varchar2 is
  Result varchar2(100);

  i_contador number;
  i_resultado number;
  i_prox_anno number;

BEGIN

  i_prox_anno:=i_id_Anno+1;
  BEGIN
  select  sum(horas_fichadas)
       into  i_contador
  from FICHAJE_FUNCIONARIO fc, personal_new f
   where
         to_date(to_char(fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy')
              between to_date('01/01/'||i_id_Anno  ,'DD/mm/yyyy') and to_date('01/01/' || i_prox_anno,'DD/mm/yyyy')
              and  (to_char(fecha_fichaje_entrada,'mm')=i_mes OR 13=i_mes)
         and fc.id_funcionario=f.id_funcionario
         and fc.id_funcionario=i_ID_FUNCIONARIO;
  EXCEPTION
            WHEN NO_DATA_FOUND THEN
            i_contador:=0;
  END;


  Result:= devuelve_min_fto_hora(i_contador);
  return(Result);
end HORAS_FICHAES_POLICIA_MES;
/

