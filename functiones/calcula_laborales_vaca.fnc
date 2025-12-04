create or replace function rrhh.CALCULA_LABORALES_VACA(D_FECHA_INICIO IN date ,D_FECHA_FIN IN date,
                                                  V_TIPO_DIA IN VARCHAR2,V_ID_FUNCIONARIO in number,V_ID_ANO in number ) return number is
  Result number;

  i_num_dias_va number;
  i_num_dias number;
begin

/*Obtenemos los días de los permisos de un funcionario*/
BEGIN   select
        NVL(sum(DECODE(id_TIPO_DIAS,'N',num_dias-trunc(num_dias/7)*2,num_dias )),0)
        into i_num_dias_va
        from permiso
        where id_funcionario=V_id_funcionario and
          id_tipo_permiso='01000' and
          id_ano=V_id_ano AND
          (anulado='NO' OR ANULADO IS NULL) and id_estado not in ('30','31','32','40','41');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
         i_num_dias_va:=0;
END;


  i_num_dias:=CALCULA_DIAS(D_FECHA_INICIO,D_FECHA_FIN ,'L' );


  Result:=i_num_dias +i_num_dias_va;
  --solicitamos mes completo
  IF   i_num_dias_va = 0 and i_num_dias = 23 Then
        Result:=22;
  END IF;

  IF  (substr(to_char(D_FECHA_INICIO,'dd/mm/yyyy'),1,2) = '01' OR
        substr(to_char(D_FECHA_INICIO,'dd/mm/yyyy'),1,2)='16') AND
      (substr(to_char(D_FECHA_INICIO,'dd/mm/yyyy'),1,2) = '30' OR
        substr(to_char(D_FECHA_INICIO,'dd/mm/yyyy'),1,2)='31') AND
        Result >22  THEN
        Result:=22;
  END IF;

  return(Result);
end CALCULA_LABORALES_VACA;
/

