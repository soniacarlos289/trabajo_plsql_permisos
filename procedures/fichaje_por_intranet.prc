CREATE OR REPLACE PROCEDURE RRHH."FICHAJE_POR_INTRANET" (
          V_ID_FUNCIONARIO in number,id_teletrajo in number,
          msgsalida out varchar2,todook out varchar2,n_fichaje out varchar2) is
i_ficha_hora varchar2(20);
i_ficha_hora_n varchar2(20);
i_ficha_hora_suma5 varchar2(20);
i_ficha_hora_quita5 varchar2(20);

i_ficha_Hoy varchar2(20);
i_horas_a number;
i_ficha number;
i_codpers number;
i_teletrabajo number;
V_FECHA_INICIO varchar2(30);
i_pin number;
V_FECHA_INICIO_M date;
V_FECHA_INICIO_h  date;
i_resto number;
i_encontrado number;
v_terminal varchar2(30);

begin

--hora de fichaje
select to_char(sysdate - 0.00348,'dd/mm/yyyy hh24:mi:ss'),to_number(to_char(sysdate,'hh24'))
into i_ficha_hora_quita5  ,i_horas_a
from dual;

select to_char(sysdate + 0.00348,'dd/mm/yyyy hh24:mi:ss'),to_number(to_char(sysdate,'hh24'))
into i_ficha_hora_suma5 ,i_horas_a
from dual;

--hora de fichaje
select to_char(sysdate ,'dd/mm/yyyy hh24:mi:ss'),to_number(to_char(sysdate,'hh24'))
into i_ficha_hora_quita5  ,i_horas_a
from dual;

select to_char(sysdate ,'dd/mm/yyyy hh24:mi:ss'),to_number(to_char(sysdate,'hh24'))
into i_ficha_hora_suma5 ,i_horas_a
from dual;


/*select to_char(sysdate,'dd/mm/yyyy hh24:mi:ss'),to_number(to_char(sysdate,'hh24'))
into i_ficha_hora_n ,i_horas_a
from dual;*/

todook:='1';
i_ficha:=1;






--ficha calendario
BEGIN
    SELECT
        distinct codigo
        into i_codpers
    FROM
        personal_new p  ,persona pr, apliweb_usuario u
    WHERE
       p.id_funcionario=V_ID_FUNCIONARIO  and
       p.id_funcionario=u.id_funcionario and
       u.id_fichaje is not null and
       lpad(u.id_fichaje,5,'0')=pr.codigo and rownum <2;
EXCEPTION
          WHEN NO_DATA_FOUND THEN
           i_ficha:=0;
END;

  msgsalida:='Fichado Erroneo. Pongase en contacto con RRHH.';

if i_ficha = 1 then
--Tiene teletrabajo ¿?
BEGIN
    SELECT
        distinct teletrabajo
        into i_teletrabajo
    FROM
        funcionario_fichaje
    WHERE
       id_funcionario=V_ID_FUNCIONARIO  and
       teletrabajo=1  and   rownum <2;
EXCEPTION
          WHEN NO_DATA_FOUND THEN
           i_ficha:=0;
END;

  msgsalida:='Fichado Erroneo. No tiene autorizado el TELETRABAJO. Pongase en contacto con RRHH.';

end if;


if i_ficha = 1 then
 --Transaccion
    --Busqueda del PIN del usuario
    BEGIN
      select numtarjeta
       into  i_pin
       from persona
     where   codigo=lpad(i_codpers,5,'0');
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
         i_pin:='';
    END;

    if i_pin >0 then

    i_ficha_Hoy:=to_char(sysdate,'DD/mm/yy');

    select mod(count(*),2)
    into i_resto
    from transacciones where
    pin=lpad(i_pin,4,'0') and  to_char(fecha,'DD/mm/yy')=i_ficha_Hoy
 --   and (numero='MA' OR numero='91')--metido para los dos sistemas
       and ((tipotrans = '2') OR (numserie = 0) or
           -- (dedo='17' and tipotrans='3') OR
           (tipotrans = '2') OR  (tipotrans = '55') OR  (tipotrans = '4865') OR --OR 4865
           -- (dedo='49' and tipotrans='3') OR
           (tipotrans = '47'));


    IF i_resto=0 then
        i_ficha_hora:=i_ficha_hora_quita5;
    else
        i_ficha_hora:=i_ficha_hora_suma5;
    end if;

 --quitar los 5 minutos.
  --  i_ficha_hora:=i_ficha_hora_n;

    V_FECHA_INICIO:=to_char(to_date(i_ficha_hora,'dd/mm/yyyy hh24:mi:ss'),'dd/mm/yyyy hh24:mi:ss');
    V_FECHA_INICIO_M:=to_date(substr(i_ficha_hora,1,10),'dd/mm/yyyy');
    V_FECHA_INICIO_h:=to_date(i_ficha_hora,'dd/mm/yyyy hh24:mi:ss');

    i_encontrado:=1;
      BEGIN
            select to_char(hora,'hh24:mi')
            into i_ficha_hora_n
            from transacciones where
            pin=lpad(i_pin,4,'0') and  to_char(fecha,'DD/mm/yy')=i_ficha_Hoy
         --   and (numero='MA' OR numero='91')--metido para los dos sistemas
               and ((tipotrans = '2') OR (numserie = 0) or
                   -- (dedo='17' and tipotrans='3') OR
                   (tipotrans = '2') OR  (tipotrans = '55') OR  (tipotrans = '4865') OR --OR 4865
                   -- (dedo='49' and tipotrans='3') OR
                   (tipotrans = '47')) and hora between sysdate - 0.00349*2 and  sysdate + 0.00349*2;
            EXCEPTION
      WHEN NO_DATA_FOUND THEN
         i_encontrado:=0;
     END;
     --añadido 25 septiembre
   if  id_teletrajo = 1 then
     v_terminal:='94';
   else
          v_terminal:='91';
   end if;

    if  i_encontrado = 0 then
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
           centro,
           claveomesa )
   values( '0',
           V_FECHA_INICIO_m,
           V_FECHA_INICIO_H,
           lpad(i_pin,4,'0'),
           17,
           2,
           '',
           'F',
           v_terminal,--'91',
           to_date(substr(to_char(sysdate,'DD/MM/YYYY'),1,10) ,'DD/MM/YYYY'),
                     to_date('30/12/1899'   || substr(to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'),11,20) ,'DD/MM/YYYY HH24:MI:SS'),
           '','0000000000',
           TRANSACCIONESCLAVEOMESA.nextval);
           commit;


     msgsalida:=' Fichado correctamente en: ' || i_ficha_hora;
   else
     msgsalida:=' Fichado correctamente en: ' || i_ficha_hora_n;
   end if;
  end if;
end if;

todook:=msgsalida;
n_fichaje:=i_resto;
END FICHAJE_POR_INTRANET;
/

