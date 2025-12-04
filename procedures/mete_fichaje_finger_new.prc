CREATE OR REPLACE PROCEDURE RRHH."METE_FICHAJE_FINGER_NEW"
       (V_ID_ANO in number,
        V_ID_FUNCIONARIO in number,
        V_FECHA_INICIO in DATE,
        V_HORA_INICIO in varchar2,
        V_HORA_FIN in varchar2,
        v_codpers in varchar2,
        v_total_horas in varchar2,V_ID_TIPO_PERMISO in varchar2,
        todo_ok_Basico out integer,msgBasico out varchar2) is
--19/09/2019  METE_FICHAJE_FINGER_NEW
--cambiado no mete las transacciones 150000
i_hora_inicio number;
i_hora_fin number;
i_no_hay_permisos number;
i_num_dias number;
i_pin varchar2(4);
i_existe number;
I_NUMERO_FINGER varchar2(4); --a?ADIDO 6 DE ABRIL DE 2010, 90 PERMISO 15000,92 AUSENCIAS.

V_DIAS_p DATE;


CURSOR DIAS(v_fecha_inicio date,v_fecha_fin date) is
select ID_DIA
from caLENDARIO_LABORAL
where  ID_DIA BETWEEN V_fecha_inicio and  v_fecha_fin ;

begin

I_NUMERO_FINGER:=90;

if V_ID_TIPO_PERMISO = '15000' THEN
    I_NUMERO_FINGER:=90;
ELSE
    I_NUMERO_FINGER:=92;
END IF;

todo_ok_basico:=0;
msgBasico:='';
 /*
         todo_ok_basico:=1;
           msgBasico:='Operacion no realizada' ||  lpad(v_codpers,5,'0') || ' ' || V_TOTAL_HORAS;
           return;*/
    --mete en persfich
if V_ID_TIPO_PERMISO <> '00000' THEN -- No meta Ausencias. 13/05/2011

todo_ok_basico:=0;

end if;

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

    i_existe:=0;
    select count(*) into i_existe
                    from  transacciones
                    where hora =  to_date('30/12/99' || ' ' || lpad(v_hora_inicio,5,'0')  || ':00','DD/MM/YY HH24:MI:SS') and
                          fecha =  to_date(V_FECHA_INICIO,'DD/MM/YY') and
                          pin  =   i_pin;
    if i_existe = 0 then


             --Fichaje de entrada
             insert into transacciones
                 (   numserie,
                     fecha,
                     hora,
                     pin,
                     dedo,
                     tipotrans,
                     codinci,
                     tipter,
                     numero,
                     fechacap,
                     horacap,
                     tipofic,
                     claveomesa,centro,

                      SUPREMA )
             values( '0',
                     to_date(V_FECHA_INICIO,'DD/MM/YY'),
                     to_date('30/12/99' || ' ' || lpad(v_hora_inicio,5,'0')  || ':00','DD/MM/YY HH24:MI:SS'),
                     i_pin      ,
                     0,
                     0,
                     '',
                     'O',
                     I_NUMERO_FINGER,
                     to_date(substr(to_char(sysdate,'DD/MM/YYYY'),1,10) ,'DD/MM/YYYY'),
                               to_date('30/12/1899'   || substr(to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'),11,20) ,'DD/MM/YYYY HH24:MI:SS'),
                     1,
                     TRANSACCIONESCLAVEOMESA.nextval,'0000000000',0);
   end if;



               i_existe:=0;
              select count(*) into i_existe
                              from  transacciones
                              where hora =  to_date('30/12/99' || ' ' || lpad(v_hora_Fin,5,'0')  || ':00','DD/MM/YY HH24:MI:SS') and
                                    fecha =  to_date(V_FECHA_INICIO,'DD/MM/YY') and
                                    pin  =   i_pin;
        if i_existe = 0 then

             --Fichaje de salida
             insert into transacciones
                 (   numserie,
                     fecha,
                     hora,
                     pin,
                     dedo,
                     tipotrans,
                     codinci,
                     tipter,
                     numero,
                     fechacap,
                     horacap,
                     tipofic,
                     claveomesa,centro,

                      SUPREMA

                      )
             values( '0',
                     to_date(V_FECHA_INICIO,'DD/MM/YY'),
                     to_date('30/12/99' || ' ' || lpad(v_hora_fin,5,'0')  || ':00','DD/MM/YY HH24:MI:SS'),
                     i_pin      ,
                     0,
                     0,
                     '',
                     'O',
                     I_NUMERO_FINGER,
                     to_date(substr(to_char(sysdate,'DD/MM/YYYY'),1,10) ,'DD/MM/YYYY'),
                     to_date('30/12/1899'   || substr(to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'),11,20) ,'DD/MM/YYYY HH24:MI:SS'),
                     1,
                     TRANSACCIONESCLAVEOMESA.nextval,'0000000000',0);
          end if;
/*
 omesa.ayto_reg_nuevo_fichajes( lpad(v_codpers,5,'0'),
                         to_char(V_FECHA_INICIO,'DD/MM/YYYY'));*/


    --sustituido dia 6/febrero/2018
     /*     omesa.PROCESO_FINGER_AUSENCIA_NEW(v_id_funcionario,
                         V_FECHA_INICIO,
                          v_hora_inicio,
                          v_hora_fin);
            commit;*/

             --CHM 15/02/2019
      --CALCULO DE SALDO TODOS LOS DIAS DEL PERMISO
      OPEN DIAS( V_FECHA_INICIO, V_FECHA_INICIO);

                  LOOP
                    FETCH DIAS
                      into    V_DIAS_p;
                   EXIT WHEN DIAS%NOTFOUND;

                  finger_calcula_saldo(V_ID_FUNCIONARIO,
                                       V_DIAS_p);




                    END LOOP;
        CLOSE DIAS;
     commit;







end METE_FICHAJE_FINGER_new;
/

