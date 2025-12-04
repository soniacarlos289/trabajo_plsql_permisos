create or replace procedure rrhh.ACTUALIZAR_UNICO_NEW
       (V_ID_ANO in number,
        V_ID_FUNCIONARIO in number,
        V_ID_TIPO_FUNCIONARIO in number,
        V_ID_TIPO_PERMISO in varchar2,
        V_ID_TIPO_DIAS in  VARCHAR2,
        V_ID_TIPO_DIAS_PER in  VARCHAR2,
        V_FECHA_INICIO in date,
        V_FECHA_FIN in date,
        V_NUM_DIAS in number,v_num_dias_tiene_per in number,
        todo_ok_Basico out integer,msgBasico out varchar2,V_REGLAS in number,V_DIAS_LABORABLES in number) is

i_no_hay_permisos number;
i_num_dias number;
i_id_tipo_dias varchar2(1);
i_ingreso_actual number;
num_semana number;
num_inicio_vaca number;
num_fin_vaca number;
i_num_dias_p number;
i_id_dia_anterior date;
i_id_dia_posterior date;
i_num_dias_va number;
i_cambiado number;
begin

todo_ok_basico:=0;
msgBasico:='';

--Compruebo que no hay permiso de vacaciones
i_num_dias_va:=-1;
BEGIN
    select decode(SUM(num_dias),NULL,-1,SUM(NUM_DIAS))
    into i_num_dias_va
    from permiso
    where id_funcionario=V_id_funcionario and
          id_tipo_permiso='01000' and
          id_ano=V_id_ano AND
          (anulado='NO' OR ANULADO IS NULL) and id_estado not in ('30','31','32','40','41');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
         i_num_dias_va:=-1;
END;


--chm 16/02/2017 21 días naturales.
--Bomberos

IF  V_id_tipo_permiso ='01000'  AND   V_ID_TIPO_FUNCIONARIO= 23 and i_num_dias_va=-1 then
     update permiso_funcionario
             set num_dias=21
             where id_ano=V_id_ano   and
                   id_tipo_permiso='01000'and
                  id_funcionario=V_id_funcionario;
                         --busco que la actualizacion sera correcta.
            IF SQL%ROWCOUNT = 0 then
               todo_ok_basico:=0;
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada.ERROR UPDATE VACACIONES BOMBEROS.';
             RETURN;
            END IF;


END IF;



--Cambio XXn por xx Laborales o 31 n por 22 L
IF V_id_tipo_permiso ='01000' and V_id_TIPO_DIAS='L' and  i_num_dias_va=-1 AND   V_ID_TIPO_FUNCIONARIO <> 23 then
    IF v_num_dias_tiene_per<>31   then --Distinto a 31 dias, --A?adido resta V_num_dias
             update permiso_funcionario
             set num_dias=(num_dias-trunc(num_dias/7)*2)-V_num_dias,id_TIPO_DIAS='L'
             where id_ano=V_id_ano   and
                          id_tipo_permiso='01000'and
                          id_TIPO_DIAS='N' and
                          ((num_dias-trunc(num_dias/7)*2)-V_num_dias)>-1 and
                          num_dias<>31 and id_funcionario=V_id_funcionario;
                         --busco que la actualizacion sera correcta.
            IF SQL%ROWCOUNT = 0 then

               todo_ok_basico:=0;
                --añadido personal_new que no tiene todos los días.
                update permiso_funcionario
                set num_dias=num_dias-V_num_dias
                where id_ano=V_id_ano   and
                          id_tipo_permiso='01000'and
                          id_TIPO_DIAS='L' and
                           id_funcionario=V_id_funcionario and rownum<2;

             /*todo_ok_basico:=1;
             msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update. CAMBIO LABORALES';
             RETURN; */ --Modificado dia 14 de junio 2010
            END IF;

    ELSE    --si son 31 días.
      IF 22-V_num_dias > -1 THEN
             update permiso_funcionario
             set num_dias=22-V_num_dias,id_TIPO_DIAS='L'
             where id_ano=V_id_ano   and
                        id_tipo_permiso='01000'and
                        id_tipo_dias='N' and
                        num_dias=31 and id_funcionario=V_id_funcionario;
             --busco que la actualizacion sera correcta.
             IF SQL%ROWCOUNT = 0 then
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update. ';
             RETURN;
            END IF;
          -- QUITADO TEMPORALMENTE
            ELSE
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada.Numero de dias solicitados mayor que el disponible ' || V_NUM_DIAS;
             RETURN;
           END IF;
    END IF;
ELSE  IF V_id_tipo_dias_PER = V_id_tipo_dias then

            update permiso_funcionario
            set    num_dias=num_dias-V_num_dias
            where  id_funcionario=V_id_funcionario and
                     id_tipo_permiso=V_id_tipo_permiso and
                    id_ano=V_id_ano and
                    num_dias-V_num_dias > -1 ;
            --busco que la actualizacion sera correcta.
            IF SQL%ROWCOUNT = 0 then
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada.Pongase contacto RRHH. Error Update. ' || V_id_funcionario ||' ' || V_id_ano ||  ' ' ||V_id_tipo_permiso || ' ' ||V_num_dias ||' ' ||i_num_dias;
             RETURN;
            END IF;

      ELSE
            todo_ok_basico:=1;
            msgBasico:='Operacion no realizada.Los permisos de vacaciones no se pueden mezclar dias naturales y laborables. ' || V_id_tipo_dias_PER || ' ' ||V_id_tipo_dias;
            RETURN;
      END IF;
END IF;

--cambiado de la parte de arriba---30/05/2018 CHM
--a?adido 04/06/2009
--quitamos un dia en los permisos de vacaciones y tipo NATURALES
--por periodos, Solamente en el primero
--a?adido 8 de junio el dia num_dias>0 para no actualice cuando esta en 0
i_cambiado:=0;
IF V_id_tipo_permiso ='01000' and
   V_id_TIPO_DIAS='N' and
   i_num_dias_va=-1 and V_NUM_DIAS<>15 and V_NUM_DIAS<>16
   AND   V_ID_TIPO_FUNCIONARIO <> 23
    then
   update permiso_funcionario set num_dias=num_dias-1
         where id_ano=V_id_ano   and
               id_tipo_permiso='01000' and
               id_TIPO_DIAS='N' and num_dias>0 and
               -- num_dias>29 and --añadido 19/07/2017 cuidado--quitado 06/06/2018
               rownum<2 and id_funcionario=V_id_funcionario;
    i_cambiado:=1;
          /*   todo_ok_basico:=1;
            msgBasico:='Operacion no realizada.PRUEBAS ' || ' ' ||V_NUM_DIAS;
            RETURN;*/
END IF;


-- DIAS 30 NATURALES-----> quedan 1------->se actualiza--->0-->Vacaciones
--Añadido chm 25/01/2017 AND  V_ID_TIPO_FUNCIONARIO <> 23;
update permiso_funcionario set num_dias=0
where id_ano=V_id_ano   and
      id_tipo_permiso='01000'and
      id_TIPO_DIAS='N' and
      num_dias=1 and
      id_funcionario=V_id_funcionario  AND  V_ID_TIPO_FUNCIONARIO <> 23;

--Añadido chm 25/01/2017
--Que no sea bombero.
IF V_id_tipo_permiso ='01000'  AND   V_ID_TIPO_FUNCIONARIO <> 23 then
     --Compruebo que no hay dias sueltos al disfrutar el ultimo periodo
     i_num_dias_va:=-1;
     BEGIN
         select num_dias,id_tipo_dias
         into i_num_dias_va,i_id_tipo_dias
         from permiso_funcionario
         where id_funcionario=V_id_funcionario and
                    id_tipo_permiso='01000' and
                    id_ano=V_id_ano;
     EXCEPTION
           WHEN NO_DATA_FOUND THEN
                i_num_dias_va:=-1;
     END;

 --15 junio 2020
 IF  V_DIAS_LABORABLES =22 and V_ID_TIPO_FUNCIONARIO <> 21 THEN
     update permiso_funcionario
     set num_dias=0
     where id_ano=V_id_ano   and
      id_tipo_permiso='01000'and
      num_dias=0 and
      id_funcionario=V_id_funcionario  AND  V_ID_TIPO_FUNCIONARIO <> 23;


 ELSE
       IF ( (i_num_dias_va < 5 and i_num_dias_va > 0
                    and  V_id_tipo_dias='L') OR
            (i_num_dias_va < 7 and i_num_dias_va > 0
                    and V_id_tipo_dias='N') ) AND V_REGLAS=0 and v_id_funcionario < 960000 then --quitar para los contratados
               todo_ok_basico:=1;
               msgBasico:='Operacion no realizada2. Si disfruta de este permiso quedan dias sueltos de vacaciones.' || ' ' || i_num_dias_va || ' ' || V_id_tipo_dias;
               RETURN;
        END IF;
  END IF;
  --15 de junio 2020
END IF;

end ACTUALIZAR_UNICO_NEW;
/

