create or replace procedure rrhh.Chequeo_Basico_NEW
       (V_ID_ANO in number,
        V_ID_FUNCIONARIO in number,
        V_ID_TIPO_FUNCIONARIO in number,
        V_ID_TIPO_PERMISO in varchar2,
        V_ID_TIPO_DIAS in out VARCHAR2,
        V_FECHA_INICIO in DATE,
        V_FECHA_FIN in out DATE,
        V_HORA_INICIO  in varchar2,
        V_HORA_FIN  in varchar2,
        V_UNICO in varchar2,
        V_DPROVINCIA in varchar2,
        V_ID_GRADO in varchar2, V_TURNOS in varchar2,
        v_num_dias out number,v_id_tipo_dias_per out varchar2,
        v_num_dias_tiene_per out number,
        todo_ok_Basico out integer,msgBasico out varchar2, V_REGLAS in number,V_RRHH in number) is

i_hora_inicio number;
i_hora_fin number;
i_no_hay_permisos number;
i_num_dias number;
i_id_tipo_dias varchar2(1);
i_unico varchar2(2);
i_resta_fechas number;
i_contador_laboral number;
i_contador_natural number;
i_contador number;
i_faltan_calendario number;
i_contador_calen_laboral number;
i_contador_calen_natural number;
i_dentro number;
i_fecha_limite_inicio date;
i_fecha_limite_fin date;
i_num_dias_per_enfer number;
i_operacion_solapamiento varchar2(512);
V_REGLAS_P number;
i_contratacion number;

begin
/*
  V_ID_TIPO_DIAS
v_id_tipo_dias_per*/



/* Aádido error tipo de dias intranet nueva*/
IF  V_ID_TIPO_PERMISO <> '01000' THEN
    BEGIN
     select id_tipo_dias
     into V_ID_TIPO_DIAS
     from permiso_funcionario
     where id_tipo_permiso=V_ID_TIPO_PERMISO and
         id_ano=V_ID_ANO AND
         id_funcionario=V_ID_FUNCIONARIO AND ROWNUM<2;
               EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                   V_ID_TIPO_DIAS  :='N';
     END;
END IF;

todo_ok_basico:=0;
msgBasico:='';






/*todo_ok_basico:=1;

           msgBasico:='Operacion no realizada ID_TIPO_DIAS. ' ||  V_ID_TIPO_DIAS || V_ID_TIPO_PERMISO ;
 return;
   rollback;*/

   i_dentro:=0;
   --Fechas estan dentro de los limites del permiso
   --Comprobacion V_REGLAS = 0 se permite incumplir
   BEGIN
         select 1,FECHA_INICIO,FECHA_FIN
           into i_dentro,
                i_fecha_limite_inicio,
                i_fecha_limite_fin
           from tr_tipo_permiso
          where
                id_tipo_permiso=V_ID_TIPO_PERMISO and
                id_ano=V_ID_ANO AND
                ( FECHA_INICIO > V_FECHA_INICIO OR
                  FECHA_INICIO > V_FECHA_FIN OR
                  FECHA_FIN < V_FECHA_INICIO OR
                  FECHA_FIN < V_FECHA_FIN );
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
                   i_dentro:=0;

    END;

    V_REGLAS_P:=V_REGLAS;
    --añadido para bomberos
    --peticion damian
    --chm 12/12/2017
    --chm13/02/2018
    IF  ( V_ID_ANO=2017 ) and ( V_ID_TIPO_FUNCIONARIO =23 OR V_ID_TIPO_FUNCIONARIO=21) THEN
      V_REGLAS_P:=1;
    END IF;

    --chequeamos que no Haya AP con nada
--COMPROBACION DE LA FORMULA
--15/01/2025
IF i_dentro <> 0  AND V_REGLAS_P=0 THEN
     todo_ok_basico:= chequea_formula(v_id_funcionario,
                             v_id_tipo_permiso ,
                             v_id_tipo_funcionario ,
                             v_fecha_inicio ,
                             v_fecha_fin);
     IF todo_ok_basico = 1 then
             --todo_ok_basico:=1;
             msgBasico:='Operacion no realizada.El permiso de Asuntos propios y AP extras por trienios, no pueden ser unidos a otros permisos hay que dejar un día laborable.';
             return;
        END IF;
end if;

    IF i_dentro <> 0  AND V_REGLAS_P=0 THEN
           todo_ok_basico:=1;
           msgBasico:='Operacion no realizada. Las fechas para pedir este permiso son ' || i_fecha_limite_inicio || ' y ' || i_fecha_limite_fin;
         RETURN;
    END IF;
    --Fin comprobación


    --Comprobacion FECHA INICIO > FINAL
    IF V_FECHA_INICIO > V_FECHA_FIN THEN
           todo_ok_basico:=1;
           msgBasico:='Operacion no realizada.Fecha Inicio mayor a Fecha Fin';
            RETURN;
    END IF;

    /*
    --Se quita
    --Hay que pedirlo con 3 dias de antelación.
    --V_RRHH 1 no se hace la comprobacion por ser RRHH
    IF V_RRHH = 0 THEN
    IF V_ID_TIPO_PERMISO='01000' OR
       V_ID_TIPO_PERMISO='02000' OR
       V_ID_TIPO_PERMISO='01015' OR
       V_ID_TIPO_PERMISO='02015' OR
     --  V_ID_TIPO_PERMISO='15000' OR  modificado por peticion de marta 14/06/2010
       V_ID_TIPO_PERMISO='03010' OR
       V_ID_TIPO_PERMISO='03020' OR
       V_ID_TIPO_PERMISO='03030' OR
       V_ID_TIPO_PERMISO='03040' OR
       V_ID_TIPO_PERMISO='03050' THEN
       --Regla tiempo 96
       IF round(V_FECHA_INICIO-sysdate,0) < 2 THEN --cambiado a 2
           todo_ok_basico:=1;
           msgBasico:='Operacion no realizada. Este Permiso se tiene que pedir con 3 dias de antelacion .';
           RETURN;
          -- todo_ok_basico:=0;--quitar
      END IF;
    END IF;
    END IF;
    */


    --Obtengo el numero de dias que le quedan de ese  permiso al funcionario
    i_no_hay_permisos:=1;
    BEGIN
         select num_dias,unico,id_tipo_dias
           into i_num_dias,i_unico,i_id_tipo_dias
           from permiso_funcionario
          where id_funcionario=V_ID_FUNCIONARIO and
                id_tipo_permiso=V_ID_TIPO_PERMISO and
                id_ano=V_ID_ANO;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
                   i_no_hay_permisos:=0;
                   i_num_dias:=-1;
    END;

    --CHM 25/01
    -- QUITO BOMBEROS. Y and V_UNICO='NO'
    IF i_num_dias = -1   then
       BEGIN
         select num_dias,unico,tipo_dias
           into i_num_dias,i_unico,i_id_tipo_dias
           from tr_tipo_permiso
          where
                id_tipo_permiso=V_ID_TIPO_PERMISO and
                id_ano=V_ID_ANO;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
           i_num_dias:=0;
           todo_ok_basico:=1;
           msgBasico:='Operacion no realizada. No tiene generado este permiso. 1.-Pongase en contacto con RRHH.';
           RETURN;
       END;
    END IF;

    --Un compensatorio
    IF V_ID_TIPO_PERMISO='15000' THEN
       i_no_hay_permisos := 1;
       i_num_dias:=1;
       --chm 20/03/2017
       --bomberos una guardia 2 días
     IF   V_ID_TIPO_FUNCIONARIO = 23 OR  V_ID_FUNCIONARIO=101217 THEN
       i_num_dias:=2;
      END IF;

    END IF;

    v_id_tipo_dias_per:=i_id_tipo_diaS;
    v_num_dias_tiene_per:=i_num_dias;--dias que quedan de ese permiso

    --Por si falta algun dia en el calendario
    BEGIN
         SELECT count(*) as contador_calen_laboral,
                           to_number(V_FECHA_FIN-V_FECHA_INICIO)+1
         into i_contador_calen_laboral,i_contador_calen_natural
         from calendario_laboral
            where id_dia between V_FECHA_INICIO and
                               V_FECHA_FIN;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
           i_faltan_calendario:=0;
    END;

    --comprobacion calendario
     IF  i_contador_calen_laboral <> i_contador_calen_natural THEN
           todo_ok_basico:=1;
           msgBasico:='Operacion no realizada. Falta Calendario. Pongase en contacto con RRHH.';
           RETURN;
       END IF;

     i_resta_fechas:=0;
    --Obtengo los dias comprendidos entre las dos fechas naturales y laborales
    BEGIN
         SELECT count(*) as contador_laboral,to_number(V_FECHA_FIN-V_FECHA_INICIO)+1
         into i_contador_laboral,i_contador_natural
         from calendario_laboral
          where id_dia between V_FECHA_INICIO and
                               V_FECHA_FIN and laboral='SI';
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
           i_resta_fechas:=0;
    END;

    --AÑADIDO por los contratados por el dia 22/05/2019
    --PARA QUE LE SUME UN DIA MAR
    --CHM 6/05/2019
    BEGIN
       select distinct contratacion into i_contratacion from personal_new
       where id_funcionario=V_ID_FUNCIONARIO and rownum<2;
     EXCEPTION
    WHEN NO_DATA_FOUND THEN
          i_contratacion:=0;
    END;

    IF i_contratacion =2  and
       ( to_Date('22/05/2019','dd/mm/yyyy') between V_FECHA_INICIO and V_FECHA_FIN ) THEN
        i_contador_laboral:=i_contador_laboral+1;
    end if;


    --AÑADIDO A MAYORES POR ERROR SIEMPRE SON NATURALES
    --PATERNIDAD
    --quitado 17/07/2020
  /*  IF V_ID_TIPO_PERMISO='07010' THEN
       V_ID_TIPO_DIAS:='N';
       IF i_contador_natural<30 THEN
                 todo_ok_basico:=1;
                 msgBasico:='Operacion no realizada. Este permiso se tiene que disfrutar los 35 dias juntos.';
                 return;
       END IF;
    END IF;*/

    --Compruebo Calendario
    IF V_ID_TIPO_FUNCIONARIO = 21 OR
       V_ID_TIPO_FUNCIONARIO = 23 OR
       (V_ID_TIPO_FUNCIONARIO = 50 and v_id_tipo_permiso<>'01000' ) OR
       V_ID_TIPO_FUNCIONARIO = 40 OR --quitado error taller de empleo
       V_ID_TIPO_FUNCIONARIO = 30 then
       i_resta_fechas:=i_contador_natural;
       V_ID_TIPO_DIAS:='N';
        v_id_tipo_dias_per:='N';
    ELSE  IF V_ID_TIPO_FUNCIONARIO = 10 OR V_ID_TIPO_FUNCIONARIO = 50 OR V_ID_TIPO_FUNCIONARIO = 40 THEN
                IF V_ID_TIPO_DIAS='N' THEN
                   i_resta_fechas:=i_contador_natural;
                ELSE
                   i_resta_fechas:=i_contador_laboral;
                END IF;
             ELSE
                 todo_ok_basico:=1;
                 msgBasico:='Operacion no realizada. TIPO no encontrado.' || V_ID_TIPO_FUNCIONARIO;
                 return;
             END IF;

    END IF;



   --Salvo los permisos De antiguedad   LABORAL
   IF (V_ID_TIPO_FUNCIONARIO = 21 OR
       V_ID_TIPO_FUNCIONARIO = 23 OR
       V_ID_TIPO_FUNCIONARIO = 50 OR
       V_ID_TIPO_FUNCIONARIO = 30) AND
       (V_ID_TIPO_PERMISO = '01501' OR
       V_ID_TIPO_PERMISO = '01502')
       then
        V_ID_TIPO_DIAS:='L';
        v_id_tipo_dias_per:='L';
         i_resta_fechas:=i_contador_laboral;
  END IF;

  IF  V_ID_TIPO_FUNCIONARIO = 23 AND V_ID_TIPO_PERMISO = '01501' THEN

      i_resta_fechas:=i_contador_natural;

  END IF;

    V_NUM_DIAS:=i_resta_fechas;

    --SI cogemos un dia festivo no nos deje
    IF V_NUM_DIAS<1 THEN
        todo_ok_basico:=1;
        msgBasico:='Operacion no realizada. Numero de dias del permiso es 0.Posiblemente el dia sea no laborable.';
        return;
    END IF;
    --añadido15/09/2023
    --ENfermedad y Fallecimiento
    --A?adido por que son hasta 5 dias pero para algunos son 1 o 2 o 4 o5
    IF  V_ID_GRADO=6 THEN
     i_num_dias_per_enfer:=1;
   END IF;
    IF  V_ID_GRADO=5 THEN
     i_num_dias_per_enfer:=5;
    END IF;

   IF  V_ID_GRADO=4 and V_ID_TIPO_PERMISO = '04000'  THEN
     i_num_dias_per_enfer:=4;
   ELSE IF  V_ID_GRADO=4 and V_ID_TIPO_PERMISO = '04500' THEN
          i_num_dias_per_enfer:=5;
        END IF;
   END IF;

  IF  V_ID_GRADO=3 and V_ID_TIPO_PERMISO = '04000'  THEN
     i_num_dias_per_enfer:=2;
   ELSE IF  V_ID_GRADO=3 and V_ID_TIPO_PERMISO = '04500' THEN
        i_num_dias_per_enfer:=4;
        END IF;
   END IF;

     IF (
          (V_ID_TIPO_PERMISO = '04000' or  V_ID_TIPO_PERMISO ='04500')
              and
          (
            (V_DPROVINCIA='SI' and   i_resta_fechas > i_num_dias_per_enfer+1) OR
             (V_DPROVINCIA='NO' and   i_resta_fechas > i_num_dias_per_enfer)
           )
         )
                  THEN
           todo_ok_basico:=1;
           msgBasico:='Operacion no realizada. Numero de dias solicitados mayor que el disponible para ese grado.';
           return;
     END IF;


--chm bomberos 13/03/2017
--ENFERMEDAD o FALLECIMIENTO

     IF (V_ID_TIPO_PERMISO = '04000' or  V_ID_TIPO_PERMISO ='04500')
         and V_ID_TIPO_FUNCIONARIO = 23 THEN

        V_NUM_DIAS:=3;
        V_FECHA_FIN:= V_FECHA_INICIO +1;


     END IF;




--chm bombero 09/02/2017
--cambiar la fecha _fin
--cambiado 13/10/2022
      IF (V_TURNOS=0 and V_ID_TIPO_FUNCIONARIO = 23) aND
        (V_ID_TIPO_PERMISO = '02000' or  V_ID_TIPO_PERMISO ='01015' or  V_ID_TIPO_PERMISO ='02015' or  V_ID_TIPO_PERMISO ='02030' or  V_ID_TIPO_PERMISO ='11000'
        or V_ID_TIPO_PERMISO = '01501'
        )
        THEN
        todo_ok_basico:=1;
           msgBasico:='Operacion no realizada. No se ha seleccionado ningun turno.';
     END IF;

     IF V_TURNOS=1 and V_ID_TIPO_FUNCIONARIO = 23 THEN
       i_resta_fechas:=1;
        V_NUM_DIAS:=i_resta_fechas;
       V_FECHA_FIN:= V_FECHA_INICIO;   --cambio 23/10/2022
     END IF;
      IF V_TURNOS=2 and V_ID_TIPO_FUNCIONARIO = 23 THEN
       i_resta_fechas:=2;
        V_NUM_DIAS:=i_resta_fechas;
       V_FECHA_FIN:= V_FECHA_INICIO+1;   --cambio 17/11/2022  +1
     END IF;
      IF V_TURNOS=3 and V_ID_TIPO_FUNCIONARIO = 23 THEN
       i_resta_fechas:=3;
        V_NUM_DIAS:=i_resta_fechas;
        V_FECHA_FIN:= V_FECHA_INICIO +1;
     END IF;
--fin bombero turnos


IF  V_ID_TIPO_FUNCIONARIO <> 23 OR V_ID_TIPO_PERMISO <>'01000' THEN
    IF  i_resta_fechas > i_num_dias then
        IF ( (V_ID_TIPO_PERMISO = '04000' or  V_ID_TIPO_PERMISO ='04500')
              and V_DPROVINCIA='SI' and   i_resta_fechas = i_num_dias+1)
                            OR
           (  V_ID_TIPO_PERMISO ='06100'  and V_DPROVINCIA='SI'
              and i_resta_fechas <= i_num_dias+2 ) then
                             i_contador:=0; --todo bien un dia mas para la provincia
        ELSE
           todo_ok_basico:=1;
           msgBasico:='Operacion no realizada. Numero de dias solicitados mayor que el disponible.' || i_resta_fechas || '- ' ||i_num_dias;
           return;
        END IF;
   END IF;
END IF;
  --FIN ENfermedad y Fallecimiento

  --Chequea solapamiento
  --A?adido 6 de abril 2010
  i_operacion_solapamiento:=chequea_solapamientos(v_id_ano ,
                        v_id_funcionario,
                        v_id_tipo_permiso,
                        v_fecha_inicio,
                        v_fecha_fin,
                        v_hora_inicio ,
                        v_hora_fin);

   --Se deja meter permisos en un mismo dias para bomberos
   IF length(i_operacion_solapamiento) > 1 and  V_ID_TIPO_FUNCIONARIO <> 23 then
           todo_ok_basico:=1;
           msgBasico:='Operacion no realizada.' || i_operacion_solapamiento ;
           return;
   END IF;


end Chequeo_Basico_NEW;
/

