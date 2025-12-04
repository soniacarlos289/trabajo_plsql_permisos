create or replace procedure rrhh.Chequeo_VACACIONES_NEW
       (V_ID_ANO in number,
        V_ID_FUNCIONARIO in number,
        V_ID_TIPO_FUNCIONARIO in number,
        V_ID_TIPO_PERMISO in varchar2,
        V_ID_TIPO_DIAS in out VARCHAR2,
        V_FECHA_INICIO in date,
        V_FECHA_FIN in date,
        V_NUM_DIAS in number,
        todo_ok_Basico out integer,msgBasico out varchar2,V_REGLAS in number) is

i_no_hay_permisos number;
i_num_dias number;
i_id_tipo_dias number;
i_ingreso_actual number;
num_semana number;
num_inicio_vaca number;
num_fin_vaca number;
i_num_dias_p number;
i_id_dia_anterior date;
i_id_dia_posterior date;
i_result number;

begin

todo_ok_basico:=0;
msgBasico:='';

    --Comprobacion de la fecha de ingreso
    --Si esta fecha es igual al a?o del permiso  nos saltamos esta validacion para
    --permitir que la gente con menos de 5 dias se puedan meter las vacaciones.
   i_ingreso_actual:=0;
   BEGIN
         select count(*)
         into i_ingreso_actual
         from personal_new
         where fecha_ingreso >  sysdate-270 and contratacion=2 and
         id_funcionario=V_ID_FUNCIONARIO;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
        i_ingreso_actual:=0;
    END;




    IF i_ingreso_actual=0 then
    --Comprobacion Periodos mayor de 5 y 7 para natural/laboral
        IF  V_ID_TIPO_PERMISO='01000' and V_ID_TIPO_DIAS='N' and V_NUM_DIAS< 7 AND V_REGLAS=0 then
            todo_ok_basico:=1;
            msgBasico:='Operacion no realizada. Por Periodos,dias naturales mayor de 7 dias.';
            return;
            ELSE IF V_ID_TIPO_PERMISO='01000' and V_ID_TIPO_DIAS='L' and V_NUM_DIAS< 5 AND V_REGLAS=0 then
                        todo_ok_basico:=1;
                        msgBasico:='Operacion no realizada. Por Periodos,dias laborables mayor de 5 dias. c';
                        return;
                 END IF;
        END IF;
    END IF;




  --Comprobaciones que las vacaciones permiso 01000,
    --se cogen por periodos 1-15 o 16-30/31 no tienen
    --por que empezar un lunes, el resto de periodos si,
    --la comprobacion solamente por dias naturales.
    IF   V_ID_TIPO_PERMISO='01000' and V_ID_TIPO_DIAS='N' AND V_REGLAS=0 then
       select to_char(to_Date(to_char(V_FECHA_INICIO,'dd/mm/yyyy'),'dd/mm/yyyy'),'d'),
              to_char(V_FECHA_INICIO,'dd') ,
              to_char(V_FECHA_FIN,'dd')
              into num_semana,num_inicio_vaca ,num_fin_vaca
              from dual;
       IF (
             (num_inicio_vaca<>1 OR num_fin_vaca<>15) AND
            (num_inicio_vaca<>16 OR num_fin_vaca<> 30) AND
            (num_inicio_vaca<>16 OR num_fin_vaca<> 15) AND --por un mes
            (num_inicio_vaca<>16 OR num_fin_vaca<> 31) AND
            (num_inicio_vaca<>1 OR num_fin_vaca<> 30) AND
            (num_inicio_vaca<>1 OR num_fin_vaca<> 31)
           ) AND num_semana <> 1          THEN
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada. Las vacaciones cuando se disfrutan por periodos de dias naturales tienen que empezar el LUNES.' || ' ' || V_ID_TIPO_DIAS;
             return;
       END IF;
    END IF;


   --COMPROBACION DE LA FORMULA
   IF (V_ID_TIPO_PERMISO='01000' or
      V_ID_TIPO_PERMISO='02000' or
      V_ID_TIPO_PERMISO='02015' or --Extras de AP
      SUBSTR(V_ID_TIPO_PERMISO,1,3)='030'  OR
       V_ID_TIPO_PERMISO='01015' OR
        V_ID_TIPO_PERMISO='15000') AND V_REGLAS=0   THEN

       i_result:= chequea_formula(v_id_funcionario,
                             v_id_tipo_permiso ,
                             v_id_tipo_funcionario ,
                             v_fecha_inicio ,
                             v_fecha_fin);
     IF i_result = 1 then
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada. VACACIONES + COMPENSATORIOS + ASUNTOS PROPIOS. No esta permitido.';
             return;
        END IF;
   END IF;


   --COMPROBACION VACACIONES NO ESTEN UNIDAS CON MOSCOSOS
   IF (V_ID_TIPO_PERMISO='01000' or
      V_ID_TIPO_PERMISO='02000' or
      V_ID_TIPO_PERMISO='02015' or --Extras de AP
      V_ID_TIPO_PERMISO='01015' ) AND V_REGLAS=0
                                           then

   --Para funcionarios SNP
   IF V_ID_TIPO_FUNCIONARIO = 10 THEN
      --Busco el dia anterior para saber si es laboral.
    i_id_dia_anterior:= calcula_ant_post(v_fecha_inicio,'A');
    i_id_dia_posterior:= calcula_ant_post(v_fecha_fin,'P');
   ELSE
    i_id_dia_anterior:= v_fecha_inicio-1;
    i_id_dia_posterior:= v_fecha_fin+1;
   END IF;

     i_num_dias_p:=0;
      -- FORMULA AP + VACACIONES O VACACIONES +AP .SOLITANDO VACACIONES oExtras
      --Busco si ese dia existe algun AP antes o despues
      --de las vacaciones o extras por vacaciones.
      IF V_id_tipo_permiso = '01000' --(quitado RRHH) OR V_id_tipo_permiso = '01015'
      then
        BEGIN
         select sum(num_dias)
           into i_num_dias_p
           from permiso
          where id_funcionario=V_id_funcionario and
                id_tipo_permiso in ('02000','02015','02081','02082' ,'02162' , '02241' ,'02242') and
                ((i_id_dia_posterior between fecha_inicio and fecha_fin )
                 OR
                (i_id_dia_anterior between fecha_inicio and fecha_fin )
                ) and
                id_ano=V_id_ano and
                (anulado='NO' OR ANULADO IS NULL) and id_estado not in ('30','31','32','40','41');
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
                   i_num_dias_p:=0;
         END;
     END IF;

     IF i_num_dias_p <> 0 then
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada. Hay dias asuntos propios unidos a vacaciones.';
             return;
     END IF;

     i_num_dias_p:=0;

      -- FORMULA AP + VACACIONES O VACACIONES +AP .SOLITANDO AP o extras AP
      --Busco si ese dia existe vaciones antes o despues
      --de  un moscoso.
      IF V_id_tipo_permiso = '02000' OR
         V_id_tipo_permiso = '02015'            then
        BEGIN
         select sum(num_dias)
           into i_num_dias_p
           from permiso
          where id_funcionario=V_id_funcionario and
                 (id_tipo_permiso='01000' --(quitado por RRHH) OR id_tipo_permiso='01015'
                 )  and
                  ((i_id_dia_posterior between fecha_inicio and fecha_fin )
                 OR
                (i_id_dia_anterior between fecha_inicio and fecha_fin )
                ) and
                id_ano=V_id_ano and
                (anulado='NO' OR ANULADO IS NULL) and id_estado not in ('30','31','32','40','41');
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
                   i_num_dias_p:=0;
        END;

        IF i_num_dias_p <> 0 then
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada. Hay dias de vacaciones antes de  moscosos.';
             return;
        END IF;
     END IF;


      -- FORMULA VACACIONES + VACACIONES O VACACIONES + VACACIONES .SOLICITANDO VACACIONES
      IF V_id_tipo_permiso = '01000'   then
         i_num_dias_p:=0;
        BEGIN
         select sum(num_dias)
           into i_num_dias_p
           from permiso
          where id_funcionario=V_id_funcionario and
                 (id_tipo_permiso='01000')  and
                  ((i_id_dia_posterior between fecha_inicio and fecha_fin )
                 OR
                (i_id_dia_anterior between fecha_inicio and fecha_fin )
                ) and
                id_ano=V_id_ano and
                (anulado='NO' OR ANULADO IS NULL) and id_estado not in ('30','31','32','40','41');
         EXCEPTION
         WHEN NO_DATA_FOUND THEN
                   i_num_dias_p:=0;
        END;

        IF i_num_dias_p <> 0 and i_num_dias_p is not null then
             todo_ok_basico:=1;
             msgBasico:='Operacion no realizada.sd Hay dias de vacaciones unido a vacaciones';
             return;
        END IF;
     END IF;



  END IF;   --NO SE PUEDEN UNIR VACACIONES  CON MOSCOSOS



end Chequeo_VACACIONES_NEW;
/

