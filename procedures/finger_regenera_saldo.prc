CREATE OR REPLACE PROCEDURE RRHH."FINGER_REGENERA_SALDO" (V_ID_funcionario in varchar2,
                                                V_PERIODO        in varchar2,V_tipo_funci in number) is

  i_id_dia            date;
  i_id_funcionario    varchar2(10);
  i_tipo_funcionario2 number;

  --Funcionarios en activo
  CURSOR C0 is
 select distinct id_funcionario,nvl(tipo_funcionario2, 0)
      from personal_new
      where  --chm 16/03/2021 fecha_fin_contrato pot fecha_bajaa
       (
       ((fecha_baja is  null and fecha_fin_contrato is not null) OR 
                                  (fecha_baja >sysdate)  OR
                                  (fecha_baja is null  and fecha_fin_contrato is  null )   
       )    
        and
       (id_funcionario=V_id_funcionario OR 0=V_id_funcionario) and
       (tipo_funcionario2 = V_tipo_funci OR 0 = V_tipo_funci) )
     /* and  id_funcionario in
      (101149,
962925,
110012,
961093,
960875,
101249,
962602,
510599,
60830,
101282,
961253,
600092,
101209,
962407,
101198,
961954,
962153,
62006,

600125
)*/

--Mantenimiento
/*and  id_funcionario in
(
101218,
101219,
101220,
101221,
101223,
101238,
101240,
101247,
101250,
101260,
101261,
101262,
101263,
101269,
101271,
101272,
101273,
101276,
1141,
39082,
39106,
501357,
50175,
502331,
502332,
504442,
510595,
510599,
510600,
510601,
510606,
510607,
510608,
52003,
53002,
55106,
65147,
961073,
962072

)*/



 union
 select   to_char(101207) ,10 from dual where 101207=v_id_funcionario
 union
 select  to_char(10013),10   from dual where 10013=v_id_funcionario
 order by 1;

  --FICHAJES
  CURSOR C2 is
    select to_date(to_char(id_dia, 'dd/mm/yyyy'), 'dd/mm/yyyy')
      from webperiodo o, calendario_laboral cl
     where id_dia between inicio and fin
       and
          --ano=2018
           mes || ano =devuelve_periodo(V_PERIODO)
             --and periodo > '062018'
            --ano ||lpad(mes,2,'0') > '201811'
       and id_dia < sysdate
     order by id_dia;

Begin

  --abrimos cursor.
  OPEN C0;
  LOOP
    FETCH C0
      into i_id_funcionario, i_tipo_funcionario2;
    EXIT WHEN C0%NOTFOUND;

    --FECHA DE CALCULO DE SALDO
    OPEN C2;

    LOOP
      FETCH C2
        INTO I_ID_DIA;
      EXIT WHEN C2%NOTFOUND;

      IF i_tipo_funcionario2 <> 21 THEN
        finger_calcula_saldo(i_id_funcionario, I_ID_DIA);
      ELSE
        finger_calcula_saldo_policia(i_id_funcionario, I_ID_DIA);
      END IF;

    END LOOP;
    CLOSE C2;

  END LOOP;
  CLOSE C0;

  commit;

  --  rollback;
end FINGER_REGENERA_SALDO;
/

