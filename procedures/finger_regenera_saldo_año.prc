CREATE OR REPLACE PROCEDURE RRHH."FINGER_REGENERA_SALDO_AÑO" (V_ID_funcionario in varchar2,
                                                V_PERIODO        in varchar2,V_tipo_funci in number) is

  i_id_dia            date;
  i_id_funcionario    varchar2(10);
  i_tipo_funcionario2 number;

  --Funcionarios en activo
  CURSOR C0 is
    select distinct id_funcionario,

                    nvl(tipo_funcionario2, 0)

      from personal_new
     where (fecha_baja is null or
           (fecha_baja > sysdate and
           fecha_baja < to_date('01/01/2050', 'dd/mm/yyyy')))
       and (id_funcionario = v_id_funcionario OR 0 = v_id_funcionario)


     --  and tipo_funcionario2=21
     and  (tipo_funcionario2 = V_tipo_funci OR 0 = V_tipo_funci)
    -- and   sysdate between fecha_ingreso and nvl(fecha_fin_contrato ,sysdate + 5)
     order by 1 desc;

  --FICHAJES
  CURSOR C2 is
    select to_date(to_char(id_dia, 'dd/mm/yyyy'), 'dd/mm/yyyy')
      from webperiodo o, calendario_laboral cl
     where id_dia between inicio and fin
       and
          ano=2018
          -- mes || ano =devuelve_periodo(V_PERIODO)
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
end FINGER_REGENERA_SALDO_AÑO;
/

