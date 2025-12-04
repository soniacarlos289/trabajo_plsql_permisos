CREATE OR REPLACE PROCEDURE RRHH."FINGER_LEE_TRANS_HIST" is

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

 --Funcionarios en activo
 CURSOR C1 (clave_emp number) is
      select pin,
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
     where pin<>'0000'
         and ((tipotrans = '2') OR (numserie = 0) or
            (dedo='17' and tipotrans='3') OR
           (tipotrans = '2') OR
           (dedo='49' and tipotrans='3') OR
           (tipotrans in (55,39,40,4865,4356,4355)))
            and  Claveomesa>clave_emp and length(pin)<= 4
           AND FECHA>TO_DATE('01/01/2019','dd/MM/YYYY')

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

OPEN C1(i_claveomesa);

  LOOP
    FETCH C1
      into  v_pin, d_fecha_fichaje,  i_reloj,   i_ausencia,
             i_numserie,  d_audit_fecha, v_audit_usuario,i_tipotrans,   i_horas_f ;
    EXIT WHEN C1%NOTFOUND;

  I_ID_FUNCIONARIO :=0;
  --buscamos en la funcionario este activo del fichaje
  BEGIN
    SELECT
      distinct P.id_FUNCIONARIO,tipo_funcionario2
      into i_id_funcionario,i_tipo_funcionario2
    FROM
      personal_new p  ,      apliweb_usuario u, persona ope
    WHERE ope.numtarjeta=V_pin and
          codigo  = u.id_FICHAJE and
          (ope.fechabaja > sysdate OR ope.fechabaja is null) and
          (
          (p.fecha_baja is  null and p.fecha_fin_contrato is not null) OR 
                                  (p.fecha_baja >sysdate)  OR
                                  (p.fecha_baja is null  and p.fecha_fin_contrato is  null )) and
          lpad(p.id_funcionario,6,0)=lpad(u.id_funcionario,6,0) and
       rownum <2;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
       I_ID_FUNCIONARIO :=0;
  END;

  I_SIN_CALENDARIO :=1;
  --No hacer nada Si no hay funcionario
  IF  I_ID_FUNCIONARIO <> 0 THEN

      --buscamos periodo del fichaje
      BEGIN
      select to_char(p1_fle_desde,'hh24mi') as p1d,
            to_char(p1_fle_hasta,'hh24mi') as p1h,
            to_char(p2_fle_desde,'hh24mi') as p2d,
            to_char(p2_fle_hasta,'hh24mi') as p2h,
            to_char(p3_fle_desde,'hh24mi') as p3d,
            to_char(p3_fle_hasta,'hh24mi') as p3h,
            to_char(p1_obl_desde,'hh24mi') as po1d,
            to_char(p1_obl_hasta,'hh24mi') as po1h,
            to_char(p2_obl_desde,'hh24mi') as po2d,
            to_char(p2_obl_hasta,'hh24mi') as po2h,
            to_char(p3_obl_desde,'hh24mi') as po3d,
            to_char(p3_obl_hasta,'hh24mi') as po3h
            into  i_p1d,i_p1h,
                  i_p2d,i_p2h,
                  i_p3d,i_p3h ,
                  i_po1d,i_po1h,
                  i_po2d,i_po2h,
                  i_po3d,i_po3h
        from FICHAJE_CALENDARIO_JORNADA t, fichaje_funcionario_jornada ff
        where t.id_calendario=ff.id_calendario and
           id_funcionario=I_id_funcionario and
           dia=DECODE(to_char(D_fecha_fichaje,'d'),1,8, to_char(D_fecha_fichaje,'d'))
            and  to_date('01/01/2018','DD/mm/YYYY') between
                ff.fecha_inicio
            and nvl(ff.fecha_fin,sysdate+1)
            and  to_date('01/01/2018','DD/mm/YYYY') between
                t.fecha_inicio
            and nvl(t.fecha_fin,sysdate+1);
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
           I_SIN_CALENDARIO :=0;
       END;

    IF  I_SIN_CALENDARIO <> 0 THEN

      IF i_tipo_funcionario2 <> 21 then --no turnos policia
        IF  i_horas_f < i_p1d then
          i_periodo:='P1';
        END IF;

        IF i_p1d <= i_horas_f and i_horas_f  <=i_p1h then
             i_periodo:='P1';
        END IF;

        IF  i_horas_f >= i_p1h and i_p2h is null  then
          i_periodo:='P1';
        ELSE IF   i_horas_f  >i_p1h and i_p2d> i_horas_f then
                          i_periodo:='P1';
             END IF;
        END IF;

        IF i_p2d <= i_horas_f and i_horas_f  <= i_p2h then
                    i_periodo:='P2';
        END IF;

        IF  i_horas_f >= i_p2h and i_p3h is null  then
          i_periodo:='P2';
        END IF;

        IF i_p3d <= i_horas_f and i_horas_f  <= i_p3h then
                    i_periodo:='P3';
        END IF;

          IF  i_horas_f > i_p3h then
          i_periodo:='P3';
        END IF;




      ELSE ---POLICIAS

       i_periodo := 'P' ||turno_policia(i_Claveomesa, V_pin);


      END IF;

    END IF;
         i_id_secuencia:=sec_id_fichaje_trans.nextval;
       insert into fichaje_funcionario_tran
      (id_sec, id_funcionario, pin, fecha_fichaje, ausencia, numserie, reloj, audit_usuario, audit_fecha,tipotrans,periodo)
      values
      (i_id_secuencia  , I_id_funcionario, v_pin, D_fecha_fichaje, I_ausencia, I_numserie, I_reloj, v_audit_usuario, D_audit_fecha,i_tipotrans,i_periodo);


  END IF;--IDFUNCIONARIO








commit;
END LOOP;
CLOSE C1;


--  rollback;
end FINGER_LEE_TRANS_hist;
/

