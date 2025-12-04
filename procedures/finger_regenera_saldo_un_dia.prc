CREATE OR REPLACE PROCEDURE RRHH.FINGER_REGENERA_SALDO_UN_DIA (V_ID_funcionario in varchar2,
                                                V_tipo_funci in number,v_AYER in varchar2) is

  i_id_dia            date;
  i_id_funcionario    varchar2(10);
  i_tipo_funcionario2 number;

  --Funcionarios en activo
  CURSOR C0 is
    select distinct id_funcionario,

                    nvl(tipo_funcionario2, 0)

      from personal_new
       --chm 16/03/2021 fecha_fin_contrato pot fecha_bajaa
     where (fecha_fin_contrato is null or
           (fecha_fin_contrato > sysdate and
            nvl(fecha_baja,sysdate) < to_date('01/01/2050', 'dd/mm/yyyy')))
       and (id_funcionario = v_id_funcionario OR 0 = v_id_funcionario)
     --  and tipo_funcionario2=21
     and  (tipo_funcionario2 = V_tipo_funci OR 0 = V_tipo_funci)
      union
 select   to_char(101207) ,10 from dual where 101207=v_id_funcionario OR 0 = V_tipo_funci
 union
 select  to_char(10013),10   from dual where 10013=v_id_funcionario   OR 0 = V_tipo_funci

     order by 1 desc;


Begin

  --abrimos cursor.
  OPEN C0;
  LOOP
    FETCH C0
      into i_id_funcionario, i_tipo_funcionario2;
    EXIT WHEN C0%NOTFOUND;

       insert into fichaje_ejecucion_error
                 (fecha_ejecucion, id_funcionario, procedimiento)
                values
                 (sysdate,i_id_funcionario,'REGENERA_SALDO_DIARIO');

      --DIARIO
       I_ID_DIA:=to_date(v_AYER,'dd/mm/yyyy');

      IF i_tipo_funcionario2 <> 21 OR i_id_funcionario=962342 THEN
        finger_calcula_saldo(i_id_funcionario, I_ID_DIA);
      ELSE
        finger_calcula_saldo_policia(i_id_funcionario, I_ID_DIA);
      END IF;

     delete  fichaje_ejecucion_error where id_funcionario=i_id_funcionario and procedimiento='REGENERA_SALDO_DIARIO';

  END LOOP;
  CLOSE C0;

  commit;

  --  rollback;
end FINGER_REGENERA_SALDO_UN_DIA;
/

