CREATE OR REPLACE PROCEDURE RRHH."FINGER_RELOJES_CHEQUEA" is

    V_IMPAR varchar(15);
    V_numero varchar(15);
    v_denom  varchar(151);
    V_FECHA_CON varchar(151);
    V_ULT_CON varchar(151);
    d_dia varchar(151);
    d_dia1 varchar(151);
    d_dia2 varchar(151);
  --CHEQUEO RELOJES.
 CURSOR C2 is
 select DECODE(to_char(FECHA, 'dd/mm/yyyy'),
              to_char(sysdate, 'dd/mm/yyyy'),
              '0',
              '1') as IMPAR,
       t.numero AS NUM_FIN,
       denom AS DENOM_FIN,
       to_char(Fecha, 'dd/mm/yyyy') AS FECHA,
       to_char(hora, 'hh24:MI:SS') as ULT_CON
  from transacciones t, relojes r
 where t.fecha > sysdate - 15
   and to_number(t.numero) = to_number(r.numero)
   and r.activo = 'S'
   and (t.numserie, t.numero) in
       (select max(numserie), numero
          from transacciones
         where fecha between sysdate - 15 and sysdate + 5
           and numero not in ('91', 'MA','88','90')
         group by numero)
 order by t.numero;

begin

--COMPROBación de relojes.

delete  temp_reloj_ko;
commit;
--abrimos cursor.
OPEN C2;



  LOOP
    FETCH C2
      into V_IMPAR, V_numero , v_denom  ,
           V_FECHA_CON ,  V_ULT_CON;
    EXIT WHEN C2%NOTFOUND;


    select to_char(sysdate,'d')
    into d_dia
    from dual;



   IF V_IMPAR = '1'  aND (d_DIA<>'1' AND D_DIA<>'7' )  then --ENVIAMOS CORREO

      insert into temp_reloj_ko values(v_numero);
      envio_correo('noresponda@aytosalamanca.es' ,
                   'carlos@aytosalamanca.es' ,
                   '' ,
                   'Reloj sin fichajes: ' || v_denom,
                   'Posible avería de reloj, Ultima conexion:' ||  V_FECHA_CON || ' ' || V_ULT_CON);

    /* envio_correo('noresponda@aytosalamanca.es' ,
                   'cpelaez@aytosalamanca.es' ,
                   '' ,
                   'Reloj sin fichajes: ' || v_denom,
                   'Posible avería de reloj, Ultima conexion:' ||  V_FECHA_CON || ' ' || V_ULT_CON);

       envio_correo('noresponda@aytosalamanca.es' ,
                   'jmsalinero@aytosalamanca.es' ,
                   '' ,
                   'Reloj sin fichajes: ' || v_denom,
                   'Posible avería de reloj, Ultima conexion:' ||  V_FECHA_CON || ' ' || V_ULT_CON);
   */     envio_correo('noresponda@aytosalamanca.es' ,
                   'permisos@aytosalamanca.es' ,
                   '' ,
                   'Reloj sin fichajes: ' || v_denom,
                   'Posible avería de reloj, Ultima conexion:' ||  V_FECHA_CON || ' ' || V_ULT_CON);


   END IF;


END LOOP;
CLOSE C2;




end FINGER_RELOJES_CHEQUEA;
/

