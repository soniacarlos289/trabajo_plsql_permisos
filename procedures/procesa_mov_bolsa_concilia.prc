CREATE OR REPLACE PROCEDURE RRHH."PROCESA_MOV_BOLSA_CONCILIA" (

          V_ID_REGISTRO in number,--ID_REGISTRO, ACTUALIZAR Y BORRAR
          V_ID_FUNCIONARIO in number,
          V_ID_TIPO_MOVIMIENTO in  varchar2,
          V_EXCESOS_EN_HORAS in varchar2,
          V_EXCESOS_EN_MINUTOS in varchar2,
          V_FECHA_MOVIMIENTO       in varchar2,
          V_ID_TIPO_OPERACION in out  varchar2,
          V_ID_USUARIO in  varchar2,
          V_OBSERVACIONES in  varchar2,
          msgsalida  out  varchar2,
          v_todo_ok_B  out varchar2
          ) is

i_todo_ok_B number;
msgbasico varchar2(30000);
periodo_mes number;
periodo_ano number;
i_movimientos_ini  number;
i_registro number;
i_anulado number;
v_exceso number;
v_total  number;
v_utilizadas number;
v_exceso_jornada number;
V_exceso_old number;
v_utilizadas_old number;
ID_TIPO_MOVIMIENTO number;
v_exceso_jornada_old number;
begin

/*

 msgbasico:= V_ID_REGISTRO || ' ' ||
          V_ID_FUNCIONARIO || ' ' ||
          V_ID_TIPO_MOVIMIENTO || ' ' ||
          V_EXCESOS_EN_HORAS || ' ' ||
          V_EXCESOS_EN_MINUTOS || ' ' ||
          V_FECHA_MOVIMIENTO       || ' tipo opera ' ||
          V_ID_TIPO_OPERACION || ' ' ||
          V_ID_USUARIO || ' ' ||
          V_OBSERVACIONES;
    msgsalida:=msgbasico;
    v_todo_ok_B:=1;
   rollback;
   return;*/

periodo_mes:=substr(V_FECHA_MOVIMIENTO,1,2);
periodo_ano:=substr(V_FECHA_MOVIMIENTO,7,4);

i_anulado:=0;

i_registro:=V_ID_REGISTRO;

Begin
   select  total, utilizadas, exceso_jornada
   into    v_total, v_utilizadas,  v_exceso_jornada
  from bolsa_concilia
 where id_ano = periodo_ano
   and id_funcionario = v_id_funcionario;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
       v_total :=-13;
END;

--si no existe la bolsa la creo para ese año.
IF  v_total =-13 THEN
  insert into bolsa_concilia
    (id_ano, id_funcionario, total, utilizadas, pendientes_justificar, audit_usuario, audti_fecha, exceso_jornada)
  values
    (periodo_ano, v_id_funcionario, 3000, 0, 0, v_id_usuario, sysdate, 0);
   v_total:=3000;
   v_utilizadas:=0;
   v_exceso_jornada:=0;
END IF;

--leemos historico
v_utilizadas_old:=v_utilizadas;
v_exceso_jornada_old:=v_exceso_jornada;


--COMPROBACIONES INICIO
--Ni nulos y  2 ceros
IF ((V_EXCESOS_EN_MINUTOS) is null OR (V_EXCESOs_EN_HORAS) is null)
    AND (V_EXCESOS_EN_MINUTOS=0 AND V_EXCESOs_EN_HORAS=0) THEN
    msgbasico:='No se permiten valores nulos';
    msgsalida:=msgbasico;
    v_todo_ok_B:=1;
   rollback;
   return;
END IF;


IF V_EXCESOs_EN_HORAS>50 then --No superen los limites
     msgbasico:='Las horas no pueden superar las 24';
     msgsalida:=msgbasico;
     v_todo_ok_B:=1;
     rollback;
     return;

END IF;

--Solo movimiento negativos
--Positivo  1 Exceso de jornada  --Positivo
--Negativo  2 Cogemos permiso  . --Negativo
ID_TIPO_MOVIMIENTO:=1; --Cargamos en exceso

v_exceso:=to_number(V_EXCESOS_EN_HORAS)*60+to_number(V_EXCESOS_EN_MINUTOS);

IF to_number(V_EXCESOS_EN_HORAS) < 0  then
   v_exceso:=to_number(V_EXCESOS_EN_HORAS)*60+to_number(V_EXCESOS_EN_MINUTOS)*-1;
   ID_TIPO_MOVIMIENTO:=2;

end if;

--Es un moviento de presencia o de ausencia
IF ID_TIPO_MOVIMIENTO = 1 then
    v_exceso_jornada:=v_exceso_jornada+v_exceso;
ELSE
    v_utilizadas:=(v_utilizadas+v_exceso*-1);
END IF;



--MOVIMIENTO ES ALTA
IF V_ID_TIPO_OPERACION = 'A'  THEN

  insert into bolsa_concilia_mov
    (id_funcionario, id_ano, fecha_movimiento, anulado, exceso, observaciones, audit_usuario, audit_fecha_modi, id_registro, id_tipo_mov)
  values
    (v_id_funcionario, periodo_ano, v_fecha_movimiento, 0, v_exceso, v_observaciones,  V_ID_USUARIO, sysdate,  sec_id_bolsa_mov_concilia.nextval, ID_TIPO_MOVIMIENTO);
  commit;

END IF;
 V_exceso_old :=0;

--MOVIMIENTO ES Editar
IF V_ID_TIPO_OPERACION = 'E' THEN

BEGIN
  select exceso
    into V_exceso_old
    from bolsa_concilia_mov
   where id_registro=V_ID_REGISTRO and rownum<2;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
       V_exceso_old :=0;
END;

 update bolsa_concilia_mov
    set fecha_movimiento = v_fecha_movimiento,
        id_ano=periodo_ano,
        exceso = v_exceso,
        observaciones = v_observaciones,
        audit_usuario =  V_ID_USUARIO,
        audit_fecha_modi = sysdate
  where id_registro=V_ID_REGISTRO and rownum<2;

 If   (v_exceso_old > 0 and v_exceso <0) THEN
   msgbasico:='No se pueden modificar movimiento de Saldo Positivo a Saldo Negativo. Elimine movimiento vuelva a crearlo.';
    msgsalida:=msgbasico;
    v_todo_ok_B:=1;
   rollback;
   return;
 END IF;

 If   (v_exceso_old < 0 and v_exceso >0) THEN
   msgbasico:='No se pueden modificar movimiento de Saldo Negativo a Saldo Positivo. Elimine movimiento vuelva a crearlo.';
    msgsalida:=msgbasico;
    v_todo_ok_B:=1;
   rollback;
   return;
 END IF;

 IF v_exceso_old > 0  then
    v_exceso_jornada:=v_exceso_jornada_old+v_exceso-v_exceso_old;
   ELSE
     v_utilizadas:=v_utilizadas_old+v_exceso+v_exceso_old*-1;
   END IF;


END IF;



/*
msgbasico:=  ' Registro:' || V_ID_REGISTRO || ' exceso antiguo:' ||
          V_exceso_old || '-- Nuevo:' ||
         v_exceso_jornada || '-- OPeracion:' ||
          V_ID_TIPO_OPERACION;
    msgsalida:=msgbasico;
    v_todo_ok_B:=1;
   rollback;
   return;*/
--borrado
IF V_ID_TIPO_OPERACION = 'B' THEN

BEGIN
  select exceso
    into V_exceso_old
    from bolsa_concilia_mov
   where id_registro=V_ID_REGISTRO and rownum<2;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
       V_exceso_old :=0;
END;

  update bolsa_concilia_mov
    set fecha_movimiento = v_fecha_movimiento,
        id_ano=periodo_ano,
        anulado = 1,
        observaciones = v_observaciones,
        audit_usuario =  V_ID_USUARIO,
        audit_fecha_modi = sysdate
  where id_registro=V_ID_REGISTRO and rownum<2;

IF  ID_TIPO_MOVIMIENTO =1 then
    v_exceso_jornada:=v_exceso_jornada_old-v_exceso_old;
   ELSE
     v_utilizadas:=v_utilizadas_OLD-v_exceso_old*-1;
   END IF;

END IF;




IF v_utilizadas > 3000 then
   msgbasico:='No se pueden superar las 50 horas de conciliación';
    msgsalida:=msgbasico;
    v_todo_ok_B:=1;
   rollback;
   return;
END IF;



update bolsa_concilia
   set
       utilizadas = v_utilizadas,
       exceso_jornada = v_exceso_jornada
 where id_ano = periodo_ano
   and id_funcionario = v_id_funcionario;

 commit;
   msgbasico:='Guardado correcto.';
    msgsalida:=msgbasico;
    v_todo_ok_B:=0;

end PROCESA_MOV_BOLSA_CONCILIA;
/

