create or replace function rrhh.CALCULA_DIAS_VACACIONES(D_FECHA_INICIO IN date ,D_FECHA_FIN IN date,V_TIPO_DIA IN VARCHAR2,D_INICIO in date ,D_FIN in DATE) return number is
  Result number;

  v_inicio date;
  v_fin date;
begin

  v_inicio:=D_FECHA_INICIO;
IF D_FECHA_INICIO < d_inicio THEN
  v_inicio:=d_inicio;
END IF;

  v_fin:=D_FECHA_FIN;
IF D_FECHA_FIN > d_fin THEN
  v_fin:=d_fin;
END IF;


  Result:=CALCULA_DIAS(v_inicio,v_fin ,'L' );


  return(Result);
end CALCULA_DIAS_VACACIONES;
/

