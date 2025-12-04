CREATE OR REPLACE PROCEDURE RRHH."FICHAJE_CHEQUEA_HEXTRAS_TRAN"
(I_PIN in varchar2,i_fecha_p in date,i_fichaje in varchar2, i_clave in varchar2,
  i_operacion in varchar2)
 is  --FICHAJE, i_clave, i_operacion

  i_leidos   number;
  i_longitud_fichajes number;
  i_longitud number;
  i_longitud_computa number;
  i_longitud_actualiza number;
  i_cadena_computa_tmp varchar2(1000);
  i_cadena_fichaje_tmp varchar2(1000);

  i_hora varchar2(30);

  i_hora_real varchar2(2);
  i_minuto_real varchar2(2);

  lista_no_actualiza varchar2(1000);
  hora_i   date;
  hora_ii   date;
  i_inserta number;
  I_CODIGO_PERS_C1 varchar2(5);

  i_existe number;

begin

    i_leidos          := 1;
  /*  i_hora:=nvl(substr(i_fichaje,1,instr(i_fichaje,'v',1)-1),'0');
    i_hora_real:=lpad(substr(i_hora,1,instr(i_hora,':',1)-1),2,'0');
    i_minuto_real:=lpad(substr(i_hora,instr(i_hora,':',1)+1,2),2,'0');
    i_hora:=i_hora_real ||':'|| i_minuto_real;   */

    hora_i:= to_date('30/12/1899 ' || i_fichaje,'DD/MM/YYYY HH24:MI');

    IF  i_operacion = 1 THEN--Si el fichaje modificado


   --GUARDO LA MODIFICACION
    insert into fichaje_funcionario_tran_opera
               ( select numserie,
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
                         suprema,
                         fechaimp,
                         horaimp,
                         claveomesa,
                         fechahorainsercion,
                         coordenada1,
                         coordenada2,
                         foto,
                         2 --MODIFICACION
                          from transacciones
                                     where   pin=i_PIN
                        and fecha=i_fecha_p
                        and rownum<2
                        and claveomesa=i_clave) ;


               update transacciones
                  set hora=hora_i
                  where     pin=i_PIN
                        and fecha=i_fecha_p
                        and rownum<2
                        and claveomesa=i_clave ;


      ELSE IF  i_operacion = 2 THEN --fichaje es nuevo
          hora_ii:=to_Date('30/12/1899 ' || ' ' || to_char(sysdate,'hh24:mi'),'DD/MM/YYYY HH24:MI');
            i_existe:=0;

          BEGIN
          select numserie
          into i_existe
           from transacciones
            where   pin=i_PIN
                        and fecha=i_fecha_p
                        and rownum<2
                        and claveomesa=i_clave;
              EXCEPTION
                           WHEN NO_DATA_FOUND THEN
                                   i_existe:=0;
           END;

        IF i_existe = 0 THEN
       --GUARDO LA MODIFICACION
          insert into fichaje_funcionario_tran_opera
            ( numserie,fecha, hora, pin,  id_operacion)
          values
            (0, i_fecha_p, hora_i, lpad(I_PIN,4,'0'), 1);

                 BEGIN
                   insert into transacciones
                       ( numserie, fecha, hora,
                         pin,      dedo,  tipotrans, tipter,
                         numero,      fechacap,       horacap,
                      tipofic,       centro)
                   VALUES (  0, i_fecha_p, hora_i
                  ,lpad(I_PIN,4,'0'),0,0,'O'
                 ,'MA',to_date( to_char(sysdate,'dd/mm/yyyy'),'dd/mm/yyyy'),hora_ii,
                   1,'0000000000');
                     EXCEPTION
                     WHEN DUP_VAL_ON_INDEX THEN
                       i_inserta := 0;
                 END;
             END IF;
            ELSE IF  i_operacion = 3 THEN  --fichaje se elimina

              --GUARDO LA MODIFICACION
                insert into fichaje_funcionario_tran_opera
               ( select numserie,
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
                         suprema,
                         fechaimp,
                         horaimp,
                         claveomesa,
                         fechahorainsercion,
                         coordenada1,
                         coordenada2,
                         foto,
                         3 --BORRADO
                          from transacciones
                                     where   pin=i_PIN
                        and fecha=i_fecha_p
                        and rownum<2
                        and claveomesa=i_clave) ;

               delete transacciones
                  where   pin=i_PIN
                        and fecha=i_fecha_p
                        and rownum<2
                        and claveomesa=i_clave ;

                END IF;
           END IF;
      end if;

    i_leidos := i_leidos + 1;


end FICHAJE_CHEQUEA_HEXTRAS_TRAN;
/

