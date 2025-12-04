create or replace procedure rrhh.ANULA_FICHAJE_FINGER_15000
       (V_ID_ANO in number,
        V_ID_FUNCIONARIO in number,
        V_FECHA_INICIO in DATE,
        V_HORA_INICIO in varchar2,
        V_HORA_FIN in varchar2,
        v_codpers in varchar2,
        v_total_horas in varchar2,V_ID_TIPO_PERMISO in varchar2,
        todo_ok_Basico out integer,msgBasico out varchar2) is

i_hora_inicio number;
i_hora_fin number;
i_no_hay_permisos number;
i_num_dias number;
i_pin varchar2(4);
I_NUMERO_FINGER varchar2(3);

begin
I_NUMERO_FINGER:='90';

if V_ID_TIPO_PERMISO = '15000' THEN
    I_NUMERO_FINGER:='90';
ELSE
    I_NUMERO_FINGER:='92';
END IF;

todo_ok_basico:=0;
msgBasico:='';


    --Transaccion
    --Busqueda del PIN del usuario
    BEGIN
      select numtarjeta
       into  i_pin
       from persona
     where   codigo=lpad(v_codpers,5,'0');
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
         i_pin:='';
    END;
 --inicio
   delete  transacciones
   where  fecha=to_date(V_FECHA_INICIO,'DD/MM/YY') and
           to_char(hora,'hh24:mi')= lpad(v_hora_inicio,5,'0') and
           pin = i_pin  and
           numero=I_NUMERO_FINGER and
           rownum < 2;
    --fin
    delete  transacciones
   where  fecha=to_date(V_FECHA_INICIO,'DD/MM/YY') and
           to_char(hora,'hh24:mi')= lpad(v_hora_fin,5,'0') and
           pin = i_pin  and
           numero= I_NUMERO_FINGER and
           rownum < 2;

   commit;


end ANULA_FICHAJE_FINGER_15000;
/

