create or replace procedure rrhh.Chequeo_VACACIONES_BOMBEROS
       (V_ID_ANO in number,
        V_ID_FUNCIONARIO in number,
        V_ID_TIPO_FUNCIONARIO in number,
        V_ID_TIPO_PERMISO in varchar2,
        V_ID_TIPO_DIAS in out VARCHAR2,
        V_FECHA_INICIO in date,
        V_FECHA_FIN in date,
        V_NUM_DIAS in out  number,
        V_GUARDIAS OUT varchar2,
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
v_numero number;
v_guardia varchar2(678);
begin

todo_ok_basico:=0;
msgBasico:='';

V_NUMERO:=6;
v_guardia:='GUARDIAS CARLOS TTTTTPP***';

v_guardia:=numero_vacaciones_bombero( V_FECHA_INICIO,
                           V_FECHA_FIN,
                           V_ID_FUNCIONARIO,
                           v_numero);



V_NUM_DIAS:=V_NUMERO*3;


 --Obtengo el numero de dias que le quedan de ese  permiso al funcionario
    i_no_hay_permisos:=1;
    BEGIN
         select num_dias
           into i_num_dias_p
           from permiso_funcionario
          where id_funcionario=V_ID_FUNCIONARIO and
                id_tipo_permiso='01000' and
                id_ano=V_ID_ANO;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN

                   i_num_dias_p:=-1;
    END;


    IF  i_num_dias_p = -1 THEN
           todo_ok_basico:=1;
             msgBasico:='Operacion no realizada. Vacaciones no generadas.';
             return;
    END IF;

     IF  V_NUM_DIAS > i_num_dias_p   THEN
           todo_ok_basico:=1;
           msgBasico:='Operacion no realizada. No tiene tantos días para este permiso.';
           return;
    END IF;

     IF   V_NUM_DIAS=0 THEN
           todo_ok_basico:=1;
           msgBasico:='Operacion no realizada. No tiene guardia en esas fechas.';
           return;
    END IF;

  V_GUARDIAS:=v_guardia;

end Chequeo_VACACIONES_BOMBEROS;
/

