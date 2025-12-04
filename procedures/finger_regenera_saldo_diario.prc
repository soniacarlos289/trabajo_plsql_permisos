CREATE OR REPLACE PROCEDURE RRHH."FINGER_REGENERA_SALDO_DIARIO" (V_ID_funcionario in varchar2,
                                                V_tipo_funci in number,i_AYER in number) is

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
     IF i_ayer = 0 then
       I_ID_DIA:=to_date(to_char(sysdate,'dd/mm/yyyy'),'dd/mm/yyyy');
     ELSE
       I_ID_DIA:=to_date(to_char(sysdate-1,'dd/mm/yyyy'),'dd/mm/yyyy');
     END IF;

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
end FINGER_REGENERA_SALDO_DIARIO;
/

