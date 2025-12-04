CREATE OR REPLACE PROCEDURE RRHH.PERMISOS_ALTA_RRHH_NEW (
          V_ID_ANO in number,
          V_ID_FUNCIONARIO in number,
          V_ID_TIPO_FUNCIONARIO in out varchar2,
          V_ID_TIPO_PERMISO in varchar2,
          V_ID_ESTADO_PERMISO in varchar2,
          V_ID_TIPO_DIAS in VARCHAR2,
          V_FECHA_INICIO in DATE,
          V_FECHA_FIN in out DATE,
          V_HORA_INICIO  in varchar2,
          V_HORA_FIN  in  varchar2,
          V_ID_GRADO IN VARCHAR2,
          V_DPROVINCIA IN VARCHAR2,
          V_JUSTIFICACION in varchar2,
          v_T1 in varchar2,
          v_T2 in varchar2,
          v_t3 in varchar2,
          V_UNICO2  out varchar2,
          V_TIPO_BAJA in varchar2,--cambiar por TIPO_BAJA
          msgsalida out varchar2,todook out varchar2
          ,V_ID_USUARIO in   varchar2
          ,V_OBSERVACIONES in  varchar2
          ,V_DESCUENTO_BAJAS in  varchar2
          ,V_DESCUENTO_DIAS in  varchar2
          ,V_IP in  varchar2 -- NUEVO
          ) is
i_ficha number;
v_num_dias number;
v_id_tipo_dias_per varchar2(1);
v_codpers varchar2(5);
v_total_horas number;
i_todo_ok_B number;
msgBasico  varchar2(256);
v_id_tipo_dias_ent  varchar2(256);
i_codpers varchar(5);
i_id_funcionario number;
v_num_dias_tiene_per number;
i_no_hay_permisos number;
v_total_horas_mete varchar2(5);
i_reglas number;
i_t1 number;
V_GUARDIAS varchar2(1256);
v_provincias varchar2(5);
i_dias_descuenta number;
v_unico varchar2(5);
I_messagessss  varchar2(1256);

V_ID_USUARIO2 varchar2(1256);

begin

V_GUARDIAS:='';
V_id_USUARIO2:=V_ID_USUARIO;
--No hay usuario



   /*msgsalida:='Estoy haciendo tareas de Administracion. Hasta las 14:30 no se podran meter permisos. :) ' ||   V_TIPO_BAJA || ' ' ||v_id_tipo_dias_ent ;

   I_messagessss:=

   ' ANO ' || V_ID_ANO  ||
   ' ID_FUNCIONARIO '  || V_ID_FUNCIONARIO  ||
   ' TIPO_ID_FUNCIONARIO '  ||        V_ID_TIPO_FUNCIONARIO  ||
   ' TIPO_ID_PERMISO '  ||       V_ID_TIPO_PERMISO           ||
   ' ESTADO_PERMISO '  ||          V_ID_ESTADO_PERMISO  ||
   ' tipo_diasS '  ||          V_ID_TIPO_DIAS ||
   ' Fecha_inicio '  ||                 V_FECHA_INICIO ||
   ' Fecha_fin '  ||         V_FECHA_FIN ||
   ' hora_inicio '  ||       V_HORA_INICIO ||
   ' hora_fin '  ||        V_HORA_FIN ||
   ' GRADO '  ||        V_ID_GRADO ||
   ' Provincia '  ||        V_DPROVINCIA ||
   ' Justi '  ||        V_JUSTIFICACION ||
   ' t1 '  ||        v_T1 ||
   ' t2 '  ||         v_T2 ||
   ' t3 '  ||        v_t3 ||
   ' Unico '  ||        V_UNICO ||
   ' IP '  ||        V_IP ||
   ' Usuario '  ||      V_ID_USUARIO ||
    ' TIPO_BAJA: '  ||  V_TIPO_BAJA  ||
   ' Observaciones '  || V_OBSERVACIONES ||
   ' descuento bajas '  ||  V_DESCUENTO_BAJAS ||
   ' descuento dias '  ||       V_DESCUENTO_DIAS;

     envio_correo('noresponde@aytosalamanca.es' ,
               'carlos@aytosalamanca.es' ,
               '' ,
               'hola'  ,
               I_messagessss);
    return;
   rollback;*/


             i_reglas:=0;
      IF  V_IP = '' or v_ip is null then
          i_reglas:=0;
      else if V_IP = '1'  then
          i_reglas:=1 ;
          end if;
      end if;

todook:='1';
v_id_tipo_dias_ent:=V_ID_TIPO_DIAS;
i_no_hay_permisos:=1;
 --V_ID_TIPO_FUNCIONARIO:=10;

IF V_ID_TIPO_PERMISO='15000' THEN
  V_UNICO := 'SI';
END IF;

IF V_UNICO = 'SI' OR V_UNICO='NO' THEN
todook:='1';
else
 BEGIN
         select unico
           into V_unico
           from TR_TIPO_permiso
          where
                id_tipo_permiso=V_ID_TIPO_PERMISO and
                id_ano=V_ID_ANO;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
                   i_no_hay_permisos:=0;

    END;

  IF i_no_hay_permisos=0 then
   rollback;
   return;
  END IF;
END IF;

--No hay usuario
IF V_ID_USUARIO = '' OR V_ID_USUARIO IS NULL then
   msgsalida:='Error, vuelva a entrar en la intranet';
   rollback;
   return;
END IF;



--chm 25/01/2017
 --añadido para el control de turnos.Numero de días
 i_t1:=0;
 IF V_T1 = '1' THEN
   i_t1:=i_t1+1;
 END IF;

 IF V_T2 = '1' THEN
   i_t1:=i_t1+1;
 END IF;

 IF V_T3 = '1' THEN
   i_t1:=i_t1+1;
 END IF;

/* msgsalida:='Estoy haciendo tareas de Administracion. Hasta las 11:00 no se podran meter permisos. :) ' ||   V_ID_TIPO_DIAS_PER  || ' ' ||v_id_tipo_dias_ent ;
 return;
   rollback;*/
--Comprobacion de que el permiso esta correcto.
Chequeo_Basico_NEW
       (V_ID_ANO,
        V_ID_FUNCIONARIO ,
        V_ID_TIPO_FUNCIONARIO ,
        V_ID_TIPO_PERMISO ,
        v_id_tipo_dias_ent ,
        V_FECHA_INICIO ,
        V_FECHA_FIN ,
        V_HORA_INICIO  ,
        V_HORA_FIN  ,
        V_UNICO ,
        V_DPROVINCIA ,V_ID_GRADO, i_t1,
        v_num_dias,v_id_tipo_dias_per,v_num_dias_tiene_per,
        i_todo_ok_B,msgBasico,i_reglas,1); --1 no me comprueba el limite 3 dias. a?adido 6 de abril 2010

/*msgsalida:='Estoy haciendo tareas de Administracion. Des che.Hasta las 11:00 no se podran meter permisos. :) ' ||   V_ID_TIPO_DIAS_PER  || ' ' ||v_id_tipo_dias_ent ;
 return;
   rollback;*/
--Hay errores fin
IF i_todo_ok_B=1 then
   msgsalida:=msgbasico;
   rollback;
   return;
END IF;

--Comprobacion de vacaciones
IF (V_ID_TIPO_PERMISO='01000'  OR
   V_ID_TIPO_PERMISO='02000' or
   V_ID_TIPO_PERMISO='02081' or
   V_ID_TIPO_PERMISO='02082' or
   V_ID_TIPO_PERMISO='02162' or
   V_ID_TIPO_PERMISO='02241' or
   V_ID_TIPO_PERMISO='02242' or
   SUBSTR(V_ID_TIPO_PERMISO,1,3)='030'  OR
--   V_ID_TIPO_PERMISO='01015' OR --Vacacione extras quitado
   V_ID_TIPO_PERMISO='15000' OR
   V_ID_TIPO_PERMISO='02015')   and    V_ID_TIPO_FUNCIONARIO <> 23
                                           THEN
     chequeo_vacaciones_new(v_id_ano ,
                   v_id_funcionario,
                   v_id_tipo_funcionario,
                   v_id_tipo_permiso,
                   v_id_tipo_dias_ent ,
                   v_fecha_inicio ,
                   v_fecha_fin ,
                   v_num_dias ,
                   i_todo_ok_B ,
                   msgbasico,i_reglas );

  --Hay errores fin
   IF i_todo_ok_B=1 then
    msgsalida:=msgbasico;
       rollback;
       return;
   END IF;

END IF;

--Comprobacion de vacaciones       BOMBEROS
IF (V_ID_TIPO_PERMISO='01000'  AND  V_ID_TIPO_FUNCIONARIO = 23)          THEN
     Chequeo_VACACIONES_BOMBEROS(v_id_ano ,
                   v_id_funcionario,
                   v_id_tipo_funcionario,
                   v_id_tipo_permiso,
                   v_id_tipo_dias_ent ,
                   v_fecha_inicio ,
                   v_fecha_fin ,
                   v_num_dias ,V_GUARDIAS,
                   i_todo_ok_B ,
                   msgbasico ,1);--EL 0 es que cumpruebe reglas

  --Hay errores fin
   IF i_todo_ok_B=1 then
    msgsalida:=msgbasico;
       rollback;
       return;
   END IF;

END IF;

--Este permiso es el de un bombero
V_GUARDIAS:=V_GUARDIAS|| ' '||V_OBSERVACIONES;

--Chequeo si es un compensatorio por horas
IF V_ID_TIPO_PERMISO='15000' THEN

  chequeo_compensatorio(v_id_ano,
                        v_id_funcionario,
                        v_fecha_inicio,
                        v_fecha_fin,
                        v_hora_inicio,
                        v_hora_fin,
                        v_total_horas,
                        i_todo_ok_B ,
                        msgbasico);

   --Hay errores fin
    IF i_todo_ok_B=1 then
          msgsalida:=msgbasico;
           rollback;
         return;
    END IF;
END IF;

--Actualizo para permisos que son UNICOS
IF V_UNICO='SI' AND V_ID_TIPO_PERMISO<>'15000' THEN

/*
msgsalida:='Estoy haciendo tareas de Administracion. Hasta las 11:00 no se podran meter permisos. :) ' ||   V_ID_TIPO_DIAS_PER  || ' ' ||v_id_tipo_dias_ent ;
 return;
   rollback;*/
 --Cambiado a new
     ACTUALIZAR_UNICO_NEW(V_ID_ANO ,
        V_ID_FUNCIONARIO ,
        V_ID_TIPO_FUNCIONARIO ,
        V_ID_TIPO_PERMISO,
        v_id_tipo_dias_ent ,
        V_ID_TIPO_DIAS_PER ,
        V_FECHA_INICIO ,
        V_FECHA_FIN ,
        V_NUM_DIAS , v_num_dias_tiene_per,
        i_todo_ok_B ,
                   msgbasico ,i_reglas,0);
    --Hay errores fin
    IF i_todo_ok_B=1 then
     msgsalida:=msgbasico;
         rollback;
         return;
    END IF;
END IF;

--Descuento por baja por enfermedad justificadas
--Añadido 01/03/2013
IF V_ID_TIPO_PERMISO='11100'
  OR ( V_ID_TIPO_PERMISO='11300' AND V_DESCUENTO_BAJAS='SI')--añadido 7/04/2017

  THEN

   IF    V_DESCUENTO_BAJAS='SI' AND V_DESCUENTO_DIAS IS  NULL   THEN
    msgsalida:='Descuento a bolsa número de días tiene que ser mayor que 0.';
    return;
    rollback;
  END IF;

  IF   V_DESCUENTO_DIAS > 3 AND V_DESCUENTO_DIAS IS NOT NULL   THEN
    msgsalida:='Descuento a bolsa son solo maximo 3 días.';
    return;
    rollback;
  END IF;

  IF  V_ID_TIPO_PERMISO='11100' THEN
     i_dias_descuenta:=v_num_dias;
  ELSE
     i_dias_descuenta:= nvl(V_DESCUENTO_DIAS,0);
  END IF;

                       --chm 13/02/2019
   -- i_id_funcionario,i_fecha_inicio,
        finger_regenera_saldo(v_id_funcionario,
                          devuelve_periodo( to_char(V_FECHA_INICIO,'dd/mm/yyyy') ),
                         0);


   MOV_BOLSA_DESCUENTO_ENFERME
        (V_ID_ANO ,
         V_ID_FUNCIONARIO , V_ID_TIPO_FUNCIONARIO ,
         V_FECHA_INICIO ,
         i_dias_descuenta,    ---------v_num_dias ,
         i_todo_ok_B,
         msgbasico);
         IF i_todo_ok_B=1 then
               msgsalida:=msgbasico;
               rollback;
               return;
       END IF;
END IF; --fin 11100

--chm para meter tipo de baja
IF V_ID_TIPO_PERMISO='11300' THEN
   v_provincias:= V_TIPO_BAJA;
ELSE
 v_provincias:=v_dprovincia;
END IF;

--INSERTA PERMISO Y ENVIA CORREO
 inserta_permiso_rrhh_new(V_id_USUARIO2,
                    v_id_ano ,
                   v_id_funcionario ,
                   v_id_tipo_funcionario ,
                   v_id_tipo_permiso ,
                   v_id_tipo_dias_ent ,
                   v_fecha_inicio ,
                   v_fecha_fin ,
                   v_hora_inicio ,
                   v_hora_fin ,
                   v_unico ,
                   v_provincias ,
                   v_id_GRADO,
                   v_justificacion ,
                   v_num_dias ,
                   v_total_horas,
                     v_T1,
                    v_T2 ,
                    v_t3 ,
                   i_todo_ok_B,
                   msgbasico,
                   V_GUARDIAS,
                   V_DESCUENTO_BAJAS ,
                   V_DESCUENTO_DIAS
                   );
--Hay errores fin
IF i_todo_ok_B=1 then
 msgsalida:=msgbasico;
   rollback;
   return;
END IF;



 --El funcionario Ficha ??
   --22 0ctubre 2006
   i_ficha:=1;
   BEGIN
    SELECT
        distinct codigo
        into i_codpers
    FROM
        personal_new p  ,persona pr,  apliweb_usuario  u
    WHERE

        p.id_funcionario=V_ID_FUNCIONARIO  and
      LPAD(p.id_funcionario,6,'0')=LPAD(u.id_funcionario,6,'0') AND --pROBLEMAS CON LO QUE TENIAN MENOS 6
        u.id_fichaje is not null and
        u.id_fichaje=pr.codigo and
        rownum <2;
   EXCEPTION
          WHEN NO_DATA_FOUND THEN
           i_ficha:=0;
   END;
   v_codpers:=i_codpers;


 --FICHA
 IF I_FICHA = 1  AND V_ID_TIPO_PERMISO<>'15000' AND  V_JUSTIFICACION<>'NO' then--chm 14/02/2018


  -- Actualizamos el finger
  actualiza_finger(v_id_ano ,
                   v_id_funcionario ,
                   v_id_tipo_permiso ,
                   v_fecha_inicio ,
                   v_fecha_fin ,
                   V_codpers,80,
                   i_todo_ok_B ,
                   msgbasico);
   --Hay errores fin
  IF i_todo_ok_B=1 then
   msgsalida:=msgbasico;
     rollback;
     return;
  END IF;
 ELSE IF I_FICHA = 1  AND V_ID_TIPO_PERMISO='15000' THEN
    v_total_horas_mete:=lpad(trunc(V_total_horas/60),2,'0') || ':' || lpad(mod(V_total_horas,60),2,'0');

                   --mete_fichaje en la tabla transacciones y en persfich
                       mete_fichaje_finger_new(V_id_ano ,
                                V_id_funcionario ,
                                V_fecha_inicio,
                                v_hora_inicio ,
                                V_hora_fin ,
                                V_codpers ,
                                v_total_horas_mete ,'15000',
                                 i_todo_ok_B ,
                                msgbasico);
           --Hay errores fin
           IF i_todo_ok_B=1 then
               msgsalida:=msgbasico;
               rollback;
                return;
                END IF;
        END IF;
 END IF;


COMMIT;
msgsalida:='La solicitud  ha sido incorporada en el programa de RRHH.';
todook:='0';
END PERMISOS_ALTA_RRHH_NEW;
/

