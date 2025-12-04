CREATE OR REPLACE PROCEDURE RRHH."FICHAJE_INSERTA_HEXTRAS" (

          V_ID_FUNCIONARIO in number,
           V_ID_ANO in number,


          V_ID_TIPO_OPERACION in  varchar2, --1 ALTA -- 0 BAJA -2 ACTUALZACION
          v_ID_TIPO_HORAS in number,--FACTOR
          V_ID_TRP_NOMINA in out varchar2,

          V_FECHA_HORAS in DATE,


          V_HORA_INICIO  in varchar2,
          V_HORA_FIN  in varchar2,

           v_phe IN out VARCHAR2,--FICHAJE , SIN NUMERO NO HAY FICHAJE

          v_DESC_MOTIVO_HORAS  IN VARCHAR2,
          V_ANULADO in varchar2,

          V_ID_USUARIO in varchar2
          ) is


-- local variables here
  i_hora varchar2(5);
  i_secuencia number;

  i_id_ano number(4);


  i_fecha VARCHAR2(10);
  i_fecha_modi date;
  i_usuario varchar2(25);
  i_secuencia_ausencia number;
  i_minutos_diferencia number;
  i_horas_diferencia number;
  i_contador number;
  i_hora_fin number;
  i_hora_inicio number;
  i_minuto_inicio number;
  i_minuto_fin number;
  i_secuencia_horas_Extras number;
  i_factor number;
  i_minutos number;

  V_Fecha_Anulado date;
  i_tOTAL_HORAS varchar2(5);
  i_hora_sec number;

  v_minutos_old number;
  v_phe_old number;
  v_trp_nomina_old number;

  v_fecha_actualizacion date;
  v_Fechas_horas_old date;
  v_hora_inicio_old varchar2(5);
  v_hora_fin_old varchar2(5);
 v_ID_TIPO_HORAS_OLD number;
v_fecha_anulacion date;
begin

   --Comprobaciones
   IF V_HORA_INICIO > V_HORA_FIN THEN
           raise_application_error(-20005,'*Operacion no realizada. Hora Inicio mayor a Hora Fin.*');
   END IF;

   --Calculo de total horas
   IF length(V_HORA_INICIO) =5 and length(V_HORA_FIN)=5 then
         i_minutos:=devuelve_horas_extras_min(v_hora_inicio , v_hora_fin , v_id_tipo_horas );

         select (i_minutos-mod(i_minutos,60))/60  ,
               mod(i_minutos,60) into i_horas_diferencia , i_minutos_diferencia
         from dual;

         i_tOTAL_HORAS:=lpad(i_horas_diferencia,2,0) || ':'|| lpad(i_minutos_diferencia,2,0);
   ELSE
         raise_application_error(-20005,'*Operacion no realizada. Formato de las horas no es correcto. Formato correcto Ej: 08:00 .*');
   END IF;

   IF   V_ID_TRP_NOMINA is null OR V_ID_TRP_NOMINA<0  THEN
           V_ID_TRP_NOMINA :=0;
   END IF;

   --Compruebo que exiten las horas

   i_contador:=0;
   BEGIN
             select id_hora,devuelve_horas_extras_min(hora_inicio,hora_fin,ID_TIPO_HORAS),phe,TRP_NOMINA  ,fecha_anulado,Fecha_horas,hora_inicio,hora_fin,id_tipo_horas
             into   i_hora_sec ,v_minutos_old,v_phe_old,v_trp_nomina_old,v_fecha_anulacion,v_Fechas_horas_old,v_hora_inicio_old,v_hora_fin_old,v_ID_TIPO_HORAS_OLD
             from  horas_extras
             where v_FECHA_HORAS = FECHA_HORAS
                    and  (
                          (V_HORA_INICIO   between HORA_INICIO and HORA_FIN ) OR
                         (V_HORA_FIN      between HORA_INICIO and HORA_FIN )  OR
                         (HORA_INICIO     between V_HORA_INICIO and V_HORA_FIN ) OR
                         (HORA_FIN     between V_HORA_INICIO and V_HORA_FIN )
                         )
                    and  id_funcionario=V_ID_FUNCIONARIO
              and  (ANULADO='NO' or ANULADO is null) and rownum<2;
    EXCEPTION
                WHEN NO_DATA_FOUND THEN
                 i_hora_sec :=0;
    END;



     --obtenemos el dia y hora, secuencia de la operacion.
    select sec_operacion.nextval,to_char(sysdate,'DD/MM/YYYY'),
           to_char(sysdate,'HH:MI'),to_char(sysdate,'YYYY')
    into  i_secuencia,i_fecha,i_hora,i_id_ano
    from dual;


    i_usuario:=V_ID_USUARIO;
    i_fecha_modi:=to_Date(sysdate,'DD/MM/YYYY');

    Select sec_horas_extras.nextval
          into i_secuencia_horas_Extras
    from dual;

     --ALTA HORAS_EXTRAS
     IF  V_ID_TIPO_OPERACION = 1 and i_hora_sec=0 THEN



           --AÑADIDO POR LAS HORAS QUE VAN A LA NOMINA
           --ACTUALIZO LAS HORAS_EXTRAS_AUSENCIAS
           --CHM 18/03/2019
           IF   V_ID_TRP_NOMINA = 0  THEN
             --Modificacion Id_A?o
             update horas_extras_ausencias set total=total+i_minutos
             where id_funcionario=V_ID_FUNCIONARIO;
           END IF;


            --INSERTAMOS LOS FICHAJES
            IF v_phe is not null or v_phe=0 THEN

                  FICHAJE_INSERTA_TRAN_HEXTRAS(V_ID_FUNCIONARIO,V_PHE,v_Fecha_horas,v_hora_inicio,v_hora_fin,  V_ID_TRP_NOMINA+1);

            END IF;






       -- 96019 110001 2019 10/01/19 4 16:05 20:40 04:35 2163720   0   101217 22/03/19 NO
            --FICHAJE_INSERTA_FICHAJE (V_PHE_OLD)
           insert into horas_extras values
                 ( i_secuencia_horas_Extras,
                  V_ID_ANO                 ,
                  V_ID_FUNCIONARIO         ,
                  v_FECHA_HORAS,
                  V_ID_TIPO_HORAS          ,
                  V_HORA_INICIO           ,
                  V_HORA_FIN             ,
                 i_tOTAL_HORAS       ,
                  V_PHE,
                  '',--:new.CANTIDAD          ,
                  v_DESC_MOTIVO_HORAS,
                   V_ID_TRP_NOMINA,
                  '',--:new.FECHA_COMISION,
                  '',--:new.COMPENSA,
                  V_ID_USUARIO,
                  sysdate,
                  'NO' ,
                  '');   --FECHA_ANULACION


       END IF;

     --ACTUALIZACION HORAS_EXTRAS
     IF  V_ID_TIPO_OPERACION = 2 and i_hora_sec <>0  THEN

            --LAS HORAS SE ANULAN
            IF   V_Anulado = 'SI'  and  v_FECHA_ANULACION is null THEN

               IF V_TRP_NOMINA_OLD = 0 then
                  update horas_extras_ausencias
                     set total=total-v_minutos_old
                   where id_funcionario=V_ID_FUNCIONARIO;
               END IF;

                BEGIN
                update horas_extras
                  set
                         ID_USUARIO=V_ID_USUARIO,
                         FECHA_MODI=sysdate,
                         ANULADO='SI',
                         FECHA_ANULADO=sysdate
                where  ID_HORA= i_hora_sec            AND
                         ID_FUNCIONARIO=V_ID_FUNCIONARIO;
                      EXCEPTION
                      WHEN others THEN
                          raise_application_error(-20005,'*Operacion no realizada.*');
                end;
                    V_PHE:=-1;
                 FICHAJE_INSERTA_TRAN_HEXTRAS(V_ID_FUNCIONARIO,v_phe,v_Fecha_horas,v_hora_inicio,v_hora_fin,  V_ID_TRP_NOMINA+1);

            END IF;--FIN ANULACION

            --ACTUALIZAMOS OTRO CAMPO
            IF   V_Anulado = 'NO'  AND    v_FECHA_ANULACION is null THEN

                  IF  v_Fechas_horas_old<>v_FECHA_HORAS OR v_hora_inicio_old<>v_hora_inicio OR  v_hora_fin_old<>v_hora_fin OR
                    v_ID_TIPO_HORAS<>v_ID_TIPO_HORAS_OLD THEN
                              IF V_TRP_NOMINA_OLD = 0 THEN
                                  update horas_extras_ausencias
                                  set total=total-v_minutos_old
                                  where id_funcionario=V_ID_FUNCIONARIO;
                              END IF;

                              IF   V_ID_TRP_NOMINA = 0  THEN
                               update horas_extras_ausencias
                                 set total=total+i_minutos
                               where id_funcionario=V_ID_FUNCIONARIO;
                              END IF;
                    IF  v_Fechas_horas_old<>v_FECHA_HORAS OR v_hora_inicio_old<>v_hora_inicio OR  v_hora_fin_old<>v_hora_fin   THEN

                       FICHAJE_INSERTA_TRAN_HEXTRAS(V_ID_FUNCIONARIO,V_PHE_old,v_Fecha_horas,v_hora_inicio,v_hora_fin,  V_ID_TRP_NOMINA+1);

                    END IF;

                  END IF;--CAmbia
                  Begin
                  update horas_extras set
                                     FECHA_HORAS=v_FECHA_HORAS,
                                     ID_TIPO_HORAS=v_ID_TIPO_HORAS,
                                     HORA_INICIO=V_HORA_INICIO,
                                     HORA_FIN=V_HORA_FIN,
                                     TOTAL_HORAS=i_TOTAL_HORAS,
                                     DESC_HORAS_MOTIVO=v_DESC_MOTIVO_HORAS,
                                     TRP_NOMINA=V_ID_TRP_NOMINA,
                                     ID_USUARIO=V_ID_USUARIO,
                                     FECHA_MODI=sysdate,
                                     ANULADO=V_ANULADO
                   where    ID_HORA= i_hora_sec            AND
                            ID_FUNCIONARIO=V_ID_FUNCIONARIO;
                   EXCEPTION
                   WHEN others THEN
                                      raise_application_error(-20005,'*Operacion no realizada.*');
                   end;

            END IF;


        end if;
















END FICHAJE_INSERTA_HEXTRAS;
/

