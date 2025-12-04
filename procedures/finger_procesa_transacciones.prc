CREATE OR REPLACE PROCEDURE RRHH."FINGER_PROCESA_TRANSACCIONES"
(I_ID_FUNCIONARIO in varchar2,v_fecha_p in varchar2, i_cadena_fichaje in varchar2,
  i_cadena_computa in varchar2,i_cadena_observaciones out varchar2)
 is

  i_leidos   number;
  i_longitud_fichajes number;
  i_longitud number;
  i_longitud_computa number;
  i_longitud_actualiza number;
  i_cadena_computa_tmp varchar2(1000);
  i_cadena_fichaje_tmp varchar2(1000);
  i_fichaje varchar2(30);
  i_hora varchar2(30);
  i_operacion number;
  i_clave varchar2(40);
  i_hora_real varchar2(2);
  i_minuto_real varchar2(2);
  i_pin varchar2(4);
  i_pin2 varchar2(4);
  lista_no_actualiza varchar2(1000);
  hora_i   date;
  hora_ii   date;
  i_inserta number;
  I_CODIGO_PERS_C1 varchar2(5);
  i_tipo_horas number;
  I_tipo_funcionario2 number;
  i_fecha_p date;
begin

    i_leidos          := 1;
  --  RETURN;
  /*raise_application_error(-20005,'*Operacion no realizada.*' ||I_ID_FUNCIONARIO || ' transacciones:' ||i_cadena_fichaje
    || ' fichaje:' ||i_cadena_computa
    || ' fecha:' ||v_fecha_p

    ) ;
  */
  i_fecha_p:=to_date(v_fecha_p,'dd/mm/yyyy');

    BEGIN
    /* SELECT  numtarjeta,codigo,tipo_funcionario2 into i_pin  ,I_CODIGO_PERS_C1 ,  I_tipo_funcionario2
        FROM rrhh.personal_new p, omesa.persona pr, apliweb.usuario u
       WHERE p.id_funcionario = I_ID_FUNCIONARIO
         and lpad(p.id_funcionario, 6, 0) = lpad(u.id_funcionario, 6, 0)
         and u.id_fichaje is not null
         and u.id_fichaje = pr.codigo
          --and codigo < '02000' --quitado chm 12/03/2019
          and rownum<2;    */
      select distinct lpad(pin,4,'0'),codpers,tipo_funcionario2,lpad(pin2,4,'0')
              into i_pin  ,I_CODIGO_PERS_C1 ,  I_tipo_funcionario2,i_pin2
       from funcionario_fichaje f,personal_new p
       where p.id_funcionario=I_ID_FUNCIONARIO and
            lpad(p.id_funcionario, 6, 0) = lpad(f.id_funcionario, 6, 0) and
            ( p.fecha_fin_contrato is null or p.fecha_fin_contrato> sysdate) and pin > 0
              order by 1;
     EXCEPTION
      WHEN NO_DATA_FOUND THEN
        I_PIN := 0;
    END;


IF i_PIN > 0 THEN

    --- FICHAJES
    --- CAMPO i_cadena_fichaje
    ----FORMATO
    ---->CLAVE_FICHAJE  + Numero + ; +  VALOR + Numero +; + *<--FIN REGISTRO
    ----  VALOR
    -------- 0 el fichaje computa para saldo
    -------- 1 el fichaje son horas extras compensadas.
    -------- 2 el fichaje son horas extras pagadas.
    --- TABLA FICHAJE_FUNCIONARIO
    --- Modificado Carlos 4 diciembre 2018

    --TIPO_HORAS

    i_cadena_computa_tmp:='';
    i_longitud_computa:=length(i_cadena_computa);
    i_longitud:=1;

    WHILE i_longitud_computa > i_longitud LOOP

     i_cadena_computa_tmp:=substr( i_cadena_computa,i_longitud ,200);
     i_clave:=devuelve_valor_campo(i_cadena_computa_tmp,'CLAVE_FICHAJE');


     i_operacion:=devuelve_valor_campo(i_cadena_computa_tmp,'VALOR');
     i_tipo_horas:=devuelve_valor_campo(i_cadena_computa_tmp,'TIPO_HORAS');

      IF i_tipo_horas=0 then
        i_tipo_horas:=4;--ESpecial dedicacion no selecionas ninguna
      END IF;

        --Si Valor es 1 o 2(el fichaje son horas extras y no
        --   computa para saldo) lo incluimos en la lista de transacciones
        --   que no se pueden borrar.

        --Comprobar horas_extras --añadido 0 chm 20/03/2019
        IF  i_operacion =1 OR i_operacion =2 OR i_operacion =0  THEN

         --Comprobar
         FICHAJE_CHEQUEA_HEXTRAS(I_ID_FUNCIONARIO, i_clave, i_operacion,lista_no_actualiza,i_tipo_horas);

        END  IF;

     i_longitud:=instr(i_cadena_computa ,'*',i_longitud)+1;

    END LOOP;

    --- TRANSACCIONES
    --- CAMPO i_cadena_fichaje
    ----FORMATO
    ---->CLAVE  + Numero + ; + FICHAJE + HORA + : +Minuto + ; + VALOR + Numero +; + *<--FIN REGISTRO
    ----  VALOR
    -------- 0 La transacción no cambia,
    -------- 1 La transacción ha cambiado
    -------- 2 La transacción es nueva
    -------- 3 Eliminar la transacción
    --- TABLA FICHAJE_FUNCIONARIO_TRAN , OMESA.TRANSACCIONES
    --- Modificado Carlos 4 diciembre 2018

    i_longitud:=1;
    i_cadena_fichaje_tmp:='';
    i_longitud_fichajes:=length(i_cadena_fichaje);
    i_fichaje:='';
    i_clave:='';
    i_operacion:='';

    WHILE i_longitud_fichajes > i_longitud LOOP

     i_cadena_fichaje_tmp:=substr( i_cadena_fichaje,i_longitud ,200);

     i_fichaje:=devuelve_valor_campo(i_cadena_fichaje_tmp,'FICHAJE');
     i_clave:=devuelve_valor_campo(i_cadena_fichaje_tmp,'CLAVE');
     i_operacion:=devuelve_valor_campo(i_cadena_fichaje_tmp,'VALOR');

     --Si esta en la lista_no_actualiza no podemos actualizar la transacción
     i_longitud_actualiza:=instr(i_cadena_fichaje ,lista_no_actualiza,1);

      IF   i_longitud_actualiza =0 AND (i_operacion =1 OR i_operacion =2  OR i_operacion =3) THEN

            i_cadena_observaciones:='No se pueden eliminar transacciones que afectan a horas extras.';
            return;
      else    IF    (i_operacion =1 OR i_operacion =2  OR i_operacion =3) THEN
                   --Comprobar FICHAJE_CHEQUEA_HEXTRAS_TRAN(ID_FUNCIONARIO, i_clave, i_operacion,)
                   fichaje_chequea_hextras_tran(i_pin,i_fecha_p,i_fichaje,i_clave ,i_operacion);
                   fichaje_chequea_hextras_tran(i_pin2,i_fecha_p,i_fichaje,i_clave ,i_operacion);
              END IF;

        END  IF;


     i_longitud:=instr(i_cadena_fichaje ,'*',i_longitud)+1;

    END LOOP;
    COMMIT;

END IF;


      --cambiado chm 29/11/2018
      --finger_regenera_saldo(i_id_funcionario ,i_fecha_p);

      IF i_tipo_funcionario2 <> 21 THEN
        finger_calcula_saldo(i_id_funcionario, i_fecha_p);
      ELSE
        finger_calcula_saldo_policia(i_id_funcionario, i_fecha_p);
      END IF;


   i_cadena_observaciones:='Todo es correcto';





end FINGER_PROCESA_TRANSACCIONES;
/

