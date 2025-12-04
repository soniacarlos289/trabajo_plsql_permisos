create or replace procedure rrhh.PERMISOS_NEW(
          V_ID_ANO in number,
          V_ID_FUNCIONARIO in number,
          V_ID_TIPO_FUNCIONARIO in out varchar2,
          V_ID_TIPO_PERMISO in varchar2,
          V_ID_ESTADO_PERMISO in varchar2,
          V_ID_TIPO_DIAS in VARCHAR2,
          V_FECHA_INICIO in DATE,
          V_FECHA_FIN in out DATE,
          V_HORA_INICIO  in out varchar2,
          V_HORA_FIN  in out varchar2,
          V_ID_GRADO IN VARCHAR2,
          V_DPROVINCIA IN VARCHAR2,
          V_JUSTIFICACION in  varchar2,
            v_T1 in varchar2,
          v_T2 in varchar2,
          v_t3 in varchar2,
          V_UNICO in out varchar2,
          V_IP in varchar2,msgsalida out varchar2,todook out varchar2,v_enlace_fichero out varchar2) is
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
V_GUARDIAS varchar2(1256);
v_justificacion2 varchar2(4);
i_num_dias_laborables number;

i_t1 number;

begin
todook:='1';
v_id_tipo_dias_ent:=V_ID_TIPO_DIAS;

V_GUARDIAS:='';

V_HORA_INICIO:=substr(V_HORA_INICIO,1,5);
V_HORA_FIN:=substr(V_HORA_FIN,1,5);

v_justificacion2:='NO';
--chm 04/03/2025
if V_JUSTIFICACION = 'NO' OR  V_JUSTIFICACION is null OR  V_JUSTIFICACION ='--'  THEN 
 
BEGIN
    select DECODE(JUSTIFICACION,'SI','NO',JUSTIFICACION)
    into v_justificacion2
    from  tr_tipo_permiso tr
    where tr.id_ano=V_ID_ANO and --incluida salian 2 lineas
          tr.id_tipo_permiso=V_ID_TIPO_PERMISO and rownum<2;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
         v_justificacion2:='NO';
END;

end if;
/*
todook:='1';
  msgsalida:='Por motivos de Administración no se pueden solicitar permisos. Perdón por las molestias. ' ||  V_JUSTIFICACION2 || ' JUST'||  V_JUSTIFICACION;
  return;
rollback;

todook:='1';
  msgsalida:='Por motivos de Administración no se pueden solicitar permisos desde las 10:00 a las 12:00. Perdón por las molestias. ' ||  V_ID_TIPO_FUNCIONARIO;

   return;
rollback;
*/

IF V_ID_FUNCIONARIO=961388 THEN
   V_ID_TIPO_FUNCIONARIO:=10;
END IF;


 --Descuento por baja por enfermedad justificadas
 --Añadido 01/03/2013
 --Solo se puede pedir por RRHH
 IF V_ID_TIPO_PERMISO='11100' OR V_ID_TIPO_PERMISO='11300' THEN
    todook:='1';
    msgsalida:='Este permiso es procesado solamente por RRHH. Perdón por las molestias.';
   return;
   rollback;
 END IF;

 --chm 25/01/2017
 --añadido para el control de turnos.Numero de días
 --añadido para control que la fecha fin sea igual fecha inicio para turnos 1-2.
  --AÑADIDO 11/10/2022
 i_t1:=0;
 IF V_T1 = '1' THEN
   i_t1:=i_t1+1;
   --AÑADIDO 11/10/2022
   IF (V_ID_TIPO_PERMISO<>'01000'  AND  V_ID_TIPO_FUNCIONARIO = 23) then
          V_FECHA_FIN := V_FECHA_INICIO;
   END IF;
 END IF;

 IF V_T2 = '1' THEN
   i_t1:=i_t1+1;
    --AÑADIDO 11/10/2022
   IF (V_ID_TIPO_PERMISO<>'01000'  AND  V_ID_TIPO_FUNCIONARIO = 23) then
          V_FECHA_FIN := V_FECHA_INICIO+1;--añadido +1 //15/11/2022
   END IF;
 END IF;

 IF V_T3 = '1' THEN
   i_t1:=i_t1+1;

 END IF;

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
        i_todo_ok_B,msgBasico,0,0);

--Hay errores fin
IF i_todo_ok_B=1 then
   msgsalida:=msgbasico;
   rollback;
   return;
END IF;

--Comprobacion de vacaciones
IF (V_ID_TIPO_PERMISO='01000'  OR
   V_ID_TIPO_PERMISO='02000' or
   SUBSTR(V_ID_TIPO_PERMISO,1,3)='030'  OR
  -- V_ID_TIPO_PERMISO='01015' OR quitado VACACIONES dias extra peticion RRHH
   V_ID_TIPO_PERMISO='15000' OR
   V_ID_TIPO_PERMISO='02015'  ) and    V_ID_TIPO_FUNCIONARIO <> 23
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
                   msgbasico ,0);--EL 0 es que cumpruebe reglas

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


--Chequeo si es un compensatorio por horas
IF V_ID_TIPO_PERMISO='40000' THEN

  chequeo_bolsa_concilia(v_id_ano,
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

/*msgsalida:='Estoy haciendo tareas de Administracion. Hasta las 15:00 no se podran meter permisos. :) ' ||   v_id_tipo_dias_ent  || ' ' ||V_ID_TIPO_DIAS_PER ;
 return;
   rollback;*/

                                         --añadido 11 de junio 2020
   -- 22 días laborables de vacaciones aunque se soliciten por periodos naturales.

    IF   V_ID_TIPO_PERMISO='01000'  AND  V_ID_TIPO_FUNCIONARIO <> 23 AND  V_ID_TIPO_FUNCIONARIO <> 21  THEN
     i_num_dias_laborables := calcula_laborales_vaca(V_FECHA_INICIO,
                                    V_FECHA_FIN,
                                    V_ID_TIPO_DIAS_PER,
                                    V_ID_FUNCIONARIO,
                                    V_ID_ANO);
                 /*   msgsalida:='Las vacaciones superan el limite de 22 días laborables.' ||  i_num_dias_laborables;
         rollback;
         return;        */
       IF i_num_dias_laborables > 22 then
            msgsalida:='Las vacaciones superan el limite de 22 días laborables.';
         rollback;
         return;
       END IF;


    END IF;

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
                   msgbasico,0 ,i_num_dias_laborables);
    --Hay errores fin
    IF i_todo_ok_B=1 then
     msgsalida:=msgbasico;
         rollback;
         return;
    END IF;
END IF;



--INSERTA PERMISO Y ENVIA CORREO
 inserta_permiso_new(v_id_ano ,
                   v_id_funcionario ,
                   v_id_tipo_funcionario ,
                   v_id_tipo_permiso ,
                   v_id_tipo_dias_ent ,
                   v_fecha_inicio ,
                   v_fecha_fin ,
                   v_hora_inicio ,
                   v_hora_fin ,
                   v_unico ,
                   v_dprovincia ,
                   v_id_GRADO,
                   v_justificacion2 ,
                   v_num_dias ,
                   v_total_horas,
                      v_T1,
                     v_T2 ,
                     v_t3 ,V_GUARDIAS,
                   i_todo_ok_B,
                   msgbasico,v_enlace_fichero);
--Hay errores fin
IF i_todo_ok_B=1 then
 msgsalida:=msgbasico;
   rollback;
   return;
END IF;



 --El funcionario Ficha ??
   --22 0ctubre 2006
   --Modificado  lpad(to_char(p.id_funcionario),6,'0')=lpad(u.id_usuario,6,'0')
   --Fecha 24/03/2010
   i_ficha:=1;
   BEGIN
    SELECT
        distinct codpers
        into i_codpers
    FROM
        personal_new p  ,presenci pr,  apliweb_usuario  u
    WHERE

        p.id_funcionario=V_ID_FUNCIONARIO  and
         lpad(to_char(p.id_funcionario),6,'0')=lpad(u.id_funcionario,6,'0') and
        u.id_fichaje is not null and
        u.id_fichaje=pr.codpers and
        codinci<>999 and rownum <2;
   EXCEPTION
          WHEN NO_DATA_FOUND THEN
           i_ficha:=0;
   END;
   v_codpers:=i_codpers;


COMMIT;
msgsalida:='La solicitud de permiso ha sido enviada para su firma.';
todook:='0';
END PERMISOS_new;
/

