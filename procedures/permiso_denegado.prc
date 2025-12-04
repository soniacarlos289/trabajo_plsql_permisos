CREATE OR REPLACE PROCEDURE RRHH."PERMISO_DENEGADO"
       (V_ID_PERMISO in number,
        todo_ok_Basico out integer,msgBasico out varchar2) is

i_no_hay_permisos number;
i_id_funcionario varchar2(6);
i_num_dias number;
i_id_unico varchar2(2);
i_num_dias_total number;
i_num_dias_restan number;
i_id_ano number;
i_id_tipo_dias varchar2(2);
i_contador number;
v_id_tipo_permiso varchar2(6);
i_total_horas number;
d_fecha_inicio date;
I_DESCUENTO_BAJAS varchar2(2);
I_DESCUENTO_DIAS number;
begin

todo_ok_basico:=0;
msgBasico:='';

--Compruebo que el permiso esta en la tabla
i_no_hay_permisos:=0;
BEGIN
    select p.id_funcionario,p.num_dias,unico,tr.num_dias,p.id_tipo_permiso,p.id_ano,total_horas,p.fecha_inicio,DESCUENTO_BAJAS,DESCUENTO_DIAS
    into i_id_funcionario,i_num_dias,i_id_unico,i_num_dias_total,v_id_tipo_permiso,i_id_ano,i_total_horas,d_fecha_inicio,I_DESCUENTO_BAJAS,I_DESCUENTO_DIAS
    from permiso p,tr_tipo_permiso  tr
    where id_permiso=v_id_permiso and
          p.id_ano=tr.id_ano and --incluida salian 2 lineas
          p.id_tipo_permiso=tr.id_tipo_permiso and
          (anulado='NO' OR ANULADO IS NULL) and rownum<2;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
         i_no_hay_permisos:=-1;
END;

IF  i_no_hay_permisos = -1 then
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada.Permiso no existe.';
             RETURN;
END IF;

--elimino las bolsa de horas
IF V_ID_TIPO_PERMISO = '11100' OR (I_DESCUENTO_BAJAS='SI' AND V_ID_TIPO_PERMISO = '11300') THEN
  UPDATE bolsa_movimiento
       SET    ANULADO=1
       where  id_funcionario=i_id_funcionario
              and fecha_movimiento= d_fecha_inicio;


END IF;


--Compruebo que el permiso es Unico hay que actualizarlo.
IF I_ID_UNICO='SI' AND V_ID_TIPO_PERMISO<>'15000' THEN

   --Buscamos los dias que tiene en permiso funcionario
    i_no_hay_permisos:=0;
    BEGIN
        select pe.num_dias,id_tipo_dias
        into  i_num_dias_restan,i_id_tipo_dias
        from permiso_funcionario pe
        where id_ano=i_id_ano and
              id_funcionario=i_id_funcionario and
              id_tipo_permiso=v_id_tipo_permiso;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_no_hay_permisos:=-1;
    END;

    IF  i_no_hay_permisos = -1 then
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada.No existe dias para eses permiso.';
             RETURN;
    END IF;

    --quitado por esta mal 18/11/2014
    -- EL numero de dia no supera el total
   /* IF (i_num_dias_restan + i_num_dias) > i_num_dias_total then
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada.No existe dias para eses permiso.';
             RETURN;
    END IF;*/

    IF V_ID_TIPO_PERMISO='01000'  THEN

      IF (i_num_dias_restan + i_num_dias) >29 and i_num_dias_total=31  THEN
       --Actualizamos a 31 dias las vacaciones
       UPDATE permiso_funcionario
       SET    num_dias=31, id_tipo_dias='N'
       where  id_funcionario=i_id_funcionario and
           id_tipo_permiso='01000' and
           id_ano= i_id_ano and
           rownum  < 2 ;
       --busco que la actualizacion sera correcta.
       IF SQL%ROWCOUNT = 0 then
                  todo_ok_basico:=1;
                   msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                   RETURN;
       END IF;
      ELSE IF (i_num_dias_restan + i_num_dias) =22  and i_num_dias_total=31 and i_id_tipo_dias='L'  THEN
                 UPDATE permiso_funcionario
                 SET    num_dias=31, id_tipo_dias='N'
                 where  id_funcionario=i_id_funcionario and
                        id_tipo_permiso='01000' and
                        id_ano= i_id_ano and
                        rownum  < 2 ;
                --busco que la actualizacion sera correcta.
                IF SQL%ROWCOUNT = 0 then
                        todo_ok_basico:=1;
                        msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                        RETURN;
                END IF;
            ELSE
                --Sumo los dias
                UPDATE permiso_funcionario
                SET    num_dias=num_dias+i_num_dias
                where  id_funcionario=i_id_funcionario and
                       id_tipo_permiso=V_ID_TIPO_PERMISO and
                       id_ano= i_id_ano and
                       rownum  < 2 ;
                --busco que la actualizacion sera correcta.
                IF SQL%ROWCOUNT = 0 then
                       todo_ok_basico:=1;
                       msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                       RETURN;
                END IF;
            END IF;
      END IF;
    ELSE
       --Sumo los dias
       UPDATE permiso_funcionario
       SET    num_dias=num_dias+i_num_dias
       where  id_funcionario=i_id_funcionario and
           id_tipo_permiso=V_ID_TIPO_PERMISO and
           id_ano= i_id_ano and
           rownum  < 2 ;
       --busco que la actualizacion sera correcta.
       IF SQL%ROWCOUNT = 0 then
                  todo_ok_basico:=1;
                   msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Firma. ';
                   RETURN;
       END IF;
    END IF;
-- Para los compensatorios que van por horas....
ELSE IF V_ID_TIPO_PERMISO='15000' AND i_total_horas > 0 and i_total_horas < 1450 THEN

       UPDATE  horas_extras_ausencias
       set utilizadas=utilizadas-i_total_horas
       where id_funcionario=i_ID_funcionario and rownum <3;

       IF SQL%ROWCOUNT = 0 then
               todo_ok_basico:=1;
               msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Horas Extras Ausencia. ';
               RETURN;
       END IF;
       --AÑADIDO PARA LA BOLSA CONCILIACION
       ELSE IF V_ID_TIPO_PERMISO='40000' AND i_total_horas > 0 and i_total_horas < 1450 THEN
         UPDATE  bolsa_concilia
       set utilizadas=utilizadas-i_total_horas
       where id_funcionario=i_ID_funcionario and rownum <3 and id_ano= i_id_ano;

       IF SQL%ROWCOUNT = 0 then
               todo_ok_basico:=1;
               msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update Horas BOLSA_CONCILIA. ';
               RETURN;
       END IF;

       END IF;
     END IF;
 END IF;
 todo_ok_basico:=0;
 msgBasico:='TODO bien';

end PERMISO_DENEGADO;
/

