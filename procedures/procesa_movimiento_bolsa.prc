CREATE OR REPLACE PROCEDURE RRHH."PROCESA_MOVIMIENTO_BOLSA" (

          V_ID_REGISTRO in number,--ID_REGISTRO, ACTUALIZAR Y BORRAR
          V_ID_FUNCIONARIO in number,
          V_PERIODO in varchar2,
          V_ID_TIPO_MOVIMIENTO in  varchar2,
          V_EXCESOS_EN_HORAS in varchar2,
          V_EXCESOS_EN_MINUTOS in varchar2,
          V_FECHA_MOVIMIENTO       in varchar2,
          V_ID_TIPO_OPERACION in varchar2,
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
begin

periodo_mes:=substr(V_PERIODO,1,2);
periodo_ano:=substr(V_PERIODO,3,4);
i_anulado:=0;

i_registro:=V_ID_REGISTRO;
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

--Solo movimiento negativos
IF V_ID_TIPO_MOVIMIENTO =3 AND  ( V_EXCESOS_EN_MINUTOS > 0 OR V_EXCESOS_EN_HORAS > 0) THEN
     msgbasico:='El movimiento Descuento por incumplimiento del horario ,solo permite saldos negativos. Ej: -1 -20';
     msgsalida:=msgbasico;
     v_todo_ok_B:=1;
   rollback;
   return;
END IF;

IF V_ID_TIPO_MOVIMIENTO =5 AND  ( V_EXCESOS_EN_MINUTOS < 0 OR V_EXCESOS_EN_HORAS < 0)   THEN
     msgbasico:='El movimiento Saldo superior a 8 horas,solo permite saldos positivos. Ej: 1 20';
     msgsalida:=msgbasico;
     v_todo_ok_B:=1;
   rollback;
   return;
END IF;

IF V_ID_TIPO_MOVIMIENTO =6 AND  ( V_EXCESOS_EN_MINUTOS > 0 OR V_EXCESOs_EN_HORAS > 0)   THEN
     msgbasico:='El movimiento Deficit Horas,solo permite saldos negativos. Ej: -1 -20';
     msgsalida:=msgbasico;
     v_todo_ok_B:=1;
     rollback;
     return;
END IF;

IF V_ID_TIPO_MOVIMIENTO =7 AND  ( V_EXCESOS_EN_MINUTOS < 0 OR V_EXCESOs_EN_HORAS < 0)   THEN
     msgbasico:='El movimiento Jornada Programada,solo permite saldos positivos. Ej: 1 20';
     msgsalida:=msgbasico;
     v_todo_ok_B:=1;
     rollback;
     return;
END IF;

IF V_EXCESOS_EN_MINUTOS >59 OR V_EXCESOS_EN_MINUTOS<-59 then --No superen los limites
     msgbasico:='Los minutos tiene que estar entre el rango entre -59 a 59 Ej: 1 20';
     msgsalida:=msgbasico;
     v_todo_ok_B:=1;
     rollback;
     return;
END IF;

IF V_EXCESOs_EN_HORAS>200 then --No superen los limites
     msgbasico:='Las horas no pueden superar las 200';
     msgsalida:=msgbasico;
     v_todo_ok_B:=1;
     rollback;
     return;


case
     WHEN V_ID_TIPO_MOVIMIENTO =1
             THEN
                Begin
                   msgbasico:='El movimiento Acumulación de saldo solo se puede generar automaticamente.';
                   msgsalida:=msgbasico;
                   v_todo_ok_B:=1;
                   rollback;
                   return;
                end;

    WHEN v_ID_TIPO_MOVIMIENTO =2
             THEN
                Begin
                   msgbasico:='El movimiento Descuento por enfermedad, se genera automaticamente desde los permisos.';
                   msgsalida:=msgbasico;
                   v_todo_ok_B:=1;
                   rollback;
                   return;
                end;
                      ELSE  v_todo_ok_B:=0;
  END CASE;


END IF;
--COMPROBACIONES FIN

--MOVIMIENTO ES ALTA
IF V_ID_TIPO_OPERACION = 'A' THEN
i_movimientos_ini:=0;

     Begin
         select count(*) into i_movimientos_ini
         from BOLSA_MOVIMIENTO t
          where id_ANO=periodo_ano and
          id_funcionario=V_ID_FUNCIONARIO and
          id_tipo_movimiento in (4)
          and anulado=0;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                      i_movimientos_ini  := 0;
                WHEN OTHERS THEN
                      i_movimientos_ini := 0;
      end;

    case
     WHEN V_ID_TIPO_MOVIMIENTO =4 AND i_movimientos_ini>0
             THEN
                Begin
                   msgbasico:='El movimiento Carga Inicial Bolsa de Horas para el año Ya existe .ALTA.';
                   msgsalida:=msgbasico;
                   v_todo_ok_B:=1;
                   rollback;
                   return;
                end;

    WHEN V_ID_TIPO_MOVIMIENTO =5 --comprobar que no existe otro
             THEN
                Begin

                   periodo_mes:=substr(V_PERIODO,1,2);

                   Begin
                              select count(*) into i_movimientos_ini
                              from BOLSA_MOVIMIENTO t
                              where id_ANO=periodo_ano and
                              id_funcionario=V_ID_FUNCIONARIO and
                              PERIODO=periodo_mes and
                              id_tipo_movimiento in (5) and anulado=0;
                              EXCEPTION
                                   WHEN NO_DATA_FOUND THEN
                                        i_movimientos_ini  := 0;
                                   WHEN OTHERS THEN
                                        i_movimientos_ini := 0;
                   end;
                   IF i_movimientos_ini > 0 then
                                msgbasico:='El movimiento Saldo superior a 8 horas.  Ya existe';
                                msgsalida:=msgbasico;
                                v_todo_ok_B:=1;
                                rollback;
                                return;
                   END IF;
                end;

     WHEN V_ID_TIPO_MOVIMIENTO =6  --comprobar que no existe otro
             THEN
                Begin

                  i_movimientos_ini:=0;

                    Begin
                      select count(*) into i_movimientos_ini
                      from BOLSA_MOVIMIENTO t
                      where id_ANO=periodo_ano and
                            id_funcionario=V_ID_FUNCIONARIO and
                            id_tipo_movimiento in (6) and anulado=0;
                      EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                          i_movimientos_ini  := 0;
                       WHEN OTHERS THEN
                          i_movimientos_ini := 0;
                    end;

                   IF i_movimientos_ini > 0 THEN
                      msgbasico:='El movimiento Deficit bolsa, se genera automaticamente cada año.';
                      msgsalida:=msgbasico;
                      v_todo_ok_B:=1;
                      rollback;
                      return;
                   END IF;

                end;
      ELSE  v_todo_ok_B:=0;


      /*msgbasico:=V_ID_FUNCIONARIO ||' '||periodo_ano||' '||periodo_mes
       ||' '||v_id_tipo_movimiento||' '|| V_OBSERVACIONES
       ||' '|| V_EXCESOS_EN_HORAS
       ||' '|| V_EXCESOS_EN_MINUTOS || sec_id_bolsa_mov.nextval

       ;
                   msgsalida:=msgbasico;
                   v_todo_ok_B:=1;
                   rollback;
                   return;*/



      insert into bolsa_movimiento values
               (to_number(V_ID_FUNCIONARIO),
                to_number(periodo_ano),
                to_number(periodo_mes),
                to_number(v_id_tipo_movimiento),
              to_date(V_FECHA_MOVIMIENTO,'dd/mm/yyyy'),
                0,--ANULADO
                0,
                V_OBSERVACIONES,
                to_number(V_EXCESOS_EN_HORAS),
                 to_number(V_EXCESOS_EN_MINUTOS),
                 V_ID_USUARIO,
                sysdate,
                sec_id_bolsa_mov.nextval
             );
             commit;

             msgsalida:='Insercción correcta';
             v_todo_ok_B:=0;
             rollback;
             return;
  END CASE;

END IF;

--MOVIMIENTO ES Editar
IF V_ID_TIPO_OPERACION = 'E' THEN

  case

    WHEN V_ID_TIPO_MOVIMIENTO =7
             THEN
                Begin
                   msgbasico:='No se puede Actualizar Jornada programada.';
                   msgsalida:=msgbasico;
                   v_todo_ok_B:=1;
                   rollback;
                   return;
                end;

             ELSE  v_todo_ok_B:=0;
  END CASE;

END IF;

--borrado
IF V_ID_TIPO_OPERACION = 'B' THEN
   i_anulado:=1;
END IF;

  update bolsa_movimiento
  set id_ano=periodo_ano,
     periodo=periodo_mes,
     id_tipo_movimiento=V_ID_TIPO_MOVIMIENTO,
     fecha_movimiento= to_date(V_FECHA_MOVIMIENTO,'dd/mm/yyyy'),
     anulado=i_anulado,
     observaciones=V_OBSERVACIONES,
     exceso_en_horas=to_number(V_EXCESOS_EN_HORAS),
     excesos_en_minutos=to_number(V_EXCESOS_EN_MINUTOS),
     id_usuario=V_ID_USUARIO,
     fecha_modi=sysdate
  where
   id_registro= i_registro and
   rownum<2;
  commit;

  msgsalida:='Actualización correcta';
  v_todo_ok_B:=0;
  rollback;
  return;

end PROCESA_MOVIMIENTO_BOLSA;
/

