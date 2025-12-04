CREATE OR REPLACE PROCEDURE RRHH."FINGER_LEE_TRANS" (i_pin  in varchar2,
                                                 v_fecha_p in date) is

   i_id_funcionario number;
   v_pin            varchar2(4);
   i_reloj          number;
   i_ausencia       number;
   i_numserie       number;
   i_claveomesa     number;
   d_fecha_fichaje  date;
   d_audit_fecha    date;
   v_audit_usuario  number;
   i_tipotrans      number;
   i_p1d           number;
   i_p1h            number;
   i_p2d            number;
   i_p2h            number;
   i_p3d            number;
   i_p3h            number;
   i_po1d           number;
   i_po1h            number;
   i_po2d            number;
   i_po2h            number;
   i_po3d            number;
   i_po3h            number;
   i_horas_f        number;
   i_periodo        varchar2(4);
   i_tipo_funcionario2 number;
   i_encontrado     number;
   I_SIN_CALENDARIO number;
   hinicio          number;
   hfin             number;

   i_par_fichaje    number;
   i_id_secuencia   number;

    v_fichaje_nuevo varchar2(115);
    v_fecha_nuevo   varchar2(115);
    v_fichaje_viejo varchar2(115);
    v_fecha_viejo   varchar2(115);

     i_contar_comida number;
     i_libre number;
     i_turnos number;

 --Funcionarios en activo
 CURSOR C1 (v_fecha_p date,i_pin varchar2) is
      select lpad(pin,4,'0') as pin,
             to_date(to_char(fecha,'dd/mm/yyyy') || ' ' || to_char(hora,'hh24:mi'),'dd/mm/yyyy hh24:mi')
                      as  FECHA_FICHAJE,
            DECODE(numero,'MA','91',NUMERO) as  RELOJ,
            DECODE(CODINCI,NULL,0,1) as AUSENCIA,
            claveomesa   as numserie,
           to_date(to_char(fechaCAP,'dd/mm/yyyy') || ' ' || to_char(HORACAP,'hh24:mi'),'dd/mm/yyyy hh24:mi')
                        as  audit_fecha,
            '000000'      as  audit_usuario,
            tipotrans    as tipotrans      ,
            to_char(hora,'hh24mi')   as   horas_f
      from transacciones
     where pin<>'0000' and pin>0

         and ((tipotrans = '2') OR (numserie = 0) or
            (dedo='17' and tipotrans='3') OR
           (tipotrans = '2') OR
           (dedo='49' and tipotrans='3') OR
           (tipotrans in (55,39,40,4355,4865,4098,4102))
           OR
           (tipotrans=4356  and  pin in ('1562','1655','0940','1636','1322','1511','1631','1634','1510','1450','1491','1302','0736','1517','1569','1518','1515','0628','1259','0702','0651','1226','1213','1312','0400','0260','0271','0619','0811','0972','0990','1017','1134','1189','1230','5240','5908')) --añadido evitar fichajes fantasmas 18/05/2023
           ) and --añadido el 40 CHM 15/05/2019 --añadido 19/07 cchm (4865,4356) --4098 chm 1/10/2019
            lpad(pin,4,'0')=lpad(I_pin,4,'0') and length(pin)<= 4
           AND FECHA=v_fecha_p

        order by claveomesa asc;
Begin
 i_claveomesa :=0;
--Busco ultimo registro cargado
BEGIN
    SELECT   NVL(max(NUMSERIE),0)
             into i_claveomesa
     FROM FICHAJE_FUNCIONARIO_TRAN;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
       i_claveomesa :=0;
END;

delete fichaje_funcionario_tran
where  pin=i_pin and
 to_DAte(to_char(fecha_fichaje,'dd/mm/yyyy'),'dd/mm/yyyy')= v_fecha_p and computadas=0;
--DBMS_OUTPUT.PUT_LINE( 'BORRADO');
OPEN C1(v_fecha_p,i_pin );

  LOOP
    FETCH C1
      into  v_pin, d_fecha_fichaje,  i_reloj,   i_ausencia,
             i_numserie,  d_audit_fecha, v_audit_usuario,i_tipotrans,   i_horas_f ;
    EXIT WHEN C1%NOTFOUND;

  I_ID_FUNCIONARIO :=0;
 -- DBMS_OUTPUT.PUT_LINE(i_horas_f);

  --buscamos en la funcionario este activo del fichaje
  --chm 11/03 quitar apliweb.usuario por si no esta dado de alta.

  BEGIN
    SELECT
      distinct P.id_FUNCIONARIO,tipo_funcionario2
      into i_id_funcionario,i_tipo_funcionario2
    FROM
      personal_new p  ,  funcionario_fichaje u
      --chm 16/03/2021 fecha_fin_contrato pot fecha_bajaa
    WHERE ( 
            lpad(u.pin,4,'0')=lpad(V_pin,4,'0') OR lpad(u.pin2,4,'0')=lpad(V_pin,4,'0')
          )
     and
          ((
          (p.fecha_baja is  null and p.fecha_fin_contrato is not null) OR 
                                  (p.fecha_baja >sysdate)  OR
                                  (p.fecha_baja is null  and p.fecha_fin_contrato is  null ))) and
          lpad(p.id_funcionario,6,0)=lpad(u.id_funcionario,6,0) and
       rownum <2;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
       I_ID_FUNCIONARIO :=0;
       -- DBMS_OUTPUT.PUT_LINE('usuario no encontrado');
  END;

  IF  i_pin= '0707' THEN
    i_id_funcionario:=101207;
  END IF;
  IF  i_pin= '0305'THEN
       i_id_funcionario:=10013;
  END IF;

  I_SIN_CALENDARIO :=1;
  --No hacer nada Si no hay funcionario
  IF  I_ID_FUNCIONARIO <> 0   THEN

          finger_busca_jornada_fun(i_id_funcionario,
                                         d_fecha_fichaje,
                                         i_p1d,
                                         i_p1h,
                                         i_p2d,
                                         i_p2h,
                                         i_p3d,
                                         i_p3h,
                                         i_po1d,
                                         i_po1h,
                                         i_po2d,
                                         i_po2h,
                                         i_po3d,
                                         i_po3h,
                                         i_contar_comida,
                                         i_libre,i_turnos,
                                         i_sin_calendario);



    IF  I_SIN_CALENDARIO <> 0 THEN


      IF i_tipo_funcionario2 <> 21 then --no turnos policia
        i_periodo:=devuelve_periodo_fichaje(i_id_funcionario,
                                v_pin,
                                d_fecha_fichaje,
                                 i_horas_f);

            --  DBMS_OUTPUT.PUT_LINE('Perido:' ||i_periodo);

      ELSE ---POLICIAS

       i_periodo := 'P' ||turno_policia( I_numserie, V_pin);


      END IF;

    END IF;--calendario
         i_id_secuencia:=sec_id_fichaje_trans.nextval;
      Begin
       insert into fichaje_funcionario_tran
      (id_sec, id_funcionario, pin, fecha_fichaje, ausencia, numserie, reloj, audit_usuario, audit_fecha,tipotrans,periodo)
      values
      (i_id_secuencia  , I_id_funcionario, v_pin, D_fecha_fichaje, I_ausencia, I_numserie, I_reloj, v_audit_usuario, D_audit_fecha,i_tipotrans,i_periodo);

        EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
           i_periodo  :=0;
        END;

  END IF;--IDFUNCIONARIO








commit;

END LOOP;
CLOSE C1;
commit;

--  rollback;
end FINGER_LEE_TRANS;
/

