CREATE OR REPLACE PROCEDURE RRHH."FICHAJE_INSERTA_TRAN_HEXTRAS"
( I_FUNCIONARIO in varchar2,
  V_PHE in out number,
  v_Fechas_horas in date,
  v_hora_inicio in varchar2,
  v_hora_fin in varchar2,
  TRP_NOMINA in number
  )



 is  --FICHAJE, i_clave, i_operacion

  i_leidos   number;
  v_id_secuencia  number;
  v_id_sec_salida number;
  v_id_sec_entrada number;
  v_computadas number;

  i_hora varchar2(30);
  i_ficha number;
  i_hora_real varchar2(2);
  i_minuto_real varchar2(2);
  v_fecha_fichaje_entrada date;
  v_fecha_fichaje_ent_h varchar2(5);
  v_fecha_fichaje_sal_h varchar2(5);
  i_id_ano number;

  i_id_hora number;
  hora_i   date;
  hora_ii   date;
  i_inserta number;
  I_CODIGO_PERS_C1 varchar2(5);
  i_resultado number;

  v_pin varchar2(5);
  v_id_sec number;

begin

    i_leidos          := 1;
    i_ficha:=1;

    --PIN
    Begin
          select nvl(lpad(pin,4,'0'),0) into v_pin from funcionario_fichaje
          where id_funcionario= i_funcionario;
          EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                             v_pin :=-1;
     END;

    --si PHE es 0, hay que meter las transacciones,fichaje_funcionario
    IF V_PHE =0 AND V_PIN <>-1 THEN

         fichaje_chequea_hextras_tran( v_pin, v_Fechas_horas ,v_hora_inicio, 0, 2); --añadir
         fichaje_chequea_hextras_tran( v_pin, v_Fechas_horas ,v_hora_fin, 0, 2); --añadir

         finger_calcula_saldo( i_funcionario,v_Fechas_horas);



         update fichaje_funcionario
         set computadas=TRP_NOMINA
         where fecha_fichaje_entrada = to_Date(to_char(v_Fechas_horas,'dd/mm/yyyy')  || ' '|| v_hora_inicio,'DD/MM/YYYY HH24:MI')
         and  id_funcionario = i_funcionario and rownum<2;


         --leemos el fichaje
         BEGIN
           select       id_sec_salida,   id_sec_entrada,id_secuencia
                 into v_id_sec_salida, v_id_sec_entrada  , v_id_sec
              from fichaje_funcionario
             where fecha_fichaje_entrada = to_Date(to_char(v_Fechas_horas,'dd/mm/yyyy')  || ' '|| v_hora_inicio,'DD/MM/YYYY HH24:MI')
                and  id_funcionario = i_funcionario and rownum<2;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                     i_ficha:=0;
                     v_id_sec:=0;
            END;

            V_PHE:=v_id_sec;

          --añadido nuevo
          --chm 20/03/2019
           update fichaje_funcionario_tran
                   set computadas = TRP_NOMINA
                 where
                   id_funcionario = i_funcionario and
                       id_sec in  (  v_id_sec_salida, v_id_sec_entrada) and rownum<3;

           finger_calcula_saldo( i_funcionario,v_Fechas_horas);

    END IF;

    --MODIFICACION
    IF V_PHE <>0 AND V_PIN <>-1 THEN

            --leemos el fichaje
            BEGIN
               select    id_secuencia,   id_sec_salida,   id_sec_entrada, to_char(sysdate,'yyyy'),
                         to_Date(to_char(fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy'),
                          to_char(fecha_fichaje_entrada,'hh24:mi'),
                          to_char(fecha_fichaje_salida,'hh24:mi'),computadas
                 into v_id_secuencia,  v_id_sec_salida, v_id_sec_entrada, i_id_ano,v_fecha_fichaje_entrada
                 ,v_fecha_fichaje_ent_h,v_fecha_fichaje_sal_h,v_computadas
              from fichaje_funcionario
             where id_funcionario = i_funcionario and
                   id_secuencia= V_PHE;

            EXCEPTION
                               WHEN NO_DATA_FOUND THEN
                                      i_ficha:=0;
            END;


            fichaje_chequea_hextras_tran( v_pin, v_Fechas_horas ,v_hora_inicio,v_id_sec_entrada,  1);  --modificado
            fichaje_chequea_hextras_tran( v_pin, v_Fechas_horas ,v_hora_fin,v_id_sec_salida, 1); --modificado


             update fichaje_funcionario
                set computadas=0
                where id_secuencia=  v_id_secuencia
                and  id_funcionario = i_funcionario and rownum<2;


          --añadido nuevo
          --chm 20/03/2019
           update fichaje_funcionario_tran
                set computadas = 0
                where  id_funcionario = i_funcionario and
                       id_sec in  (  v_id_sec_salida, v_id_sec_entrada) and rownum<3;

             finger_calcula_saldo( i_funcionario,v_Fechas_horas);


           update fichaje_funcionario
         set computadas=TRP_NOMINA
         where fecha_fichaje_entrada = to_Date(to_char(v_Fechas_horas,'dd/mm/yyyy')   || ' '|| v_hora_inicio,'DD/MM/YYYY HH24:MI')
         and  id_funcionario = i_funcionario and rownum<2;


         --leemos el fichaje
         BEGIN
           select       id_sec_salida,   id_sec_entrada
                 into v_id_sec_salida, v_id_sec_entrada
              from fichaje_funcionario
             where fecha_fichaje_entrada = to_Date(to_char(v_Fechas_horas,'dd/mm/yyyy')  || ' '|| v_hora_inicio,'DD/MM/YYYY HH24:MI')
                and  id_funcionario = i_funcionario and rownum<2;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                     i_ficha:=0;
            END;

          --añadido nuevo
          --chm 20/03/2019
           update fichaje_funcionario_tran
                   set computadas = TRP_NOMINA
                 where
                   id_funcionario = i_funcionario and
                       id_sec in  (  v_id_sec_salida, v_id_sec_entrada) and rownum<3;

           finger_calcula_saldo( i_funcionario,v_Fechas_horas);


    END IF;

    --ANulacion
    IF V_PHE =-1 AND V_PIN <>-1 THEN

            --leemos el fichaje
            BEGIN
               select    id_secuencia,   id_sec_salida,   id_sec_entrada, to_char(sysdate,'yyyy'),
                         to_Date(to_char(fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy'),
                          to_char(fecha_fichaje_entrada,'hh24:mi'),
                          to_char(fecha_fichaje_salida,'hh24:mi'),computadas
                 into v_id_secuencia,  v_id_sec_salida, v_id_sec_entrada, i_id_ano,v_fecha_fichaje_entrada
                 ,v_fecha_fichaje_ent_h,v_fecha_fichaje_sal_h,v_computadas
              from fichaje_funcionario
             where id_funcionario = i_funcionario and
                   id_secuencia= V_PHE;

            EXCEPTION
                               WHEN NO_DATA_FOUND THEN
                                      i_ficha:=0;
            END;


            fichaje_chequea_hextras_tran( v_pin, v_Fechas_horas ,v_hora_inicio,v_id_sec_entrada,  3);  --borrado
            fichaje_chequea_hextras_tran( v_pin, v_Fechas_horas ,v_hora_fin,v_id_sec_salida, 3); --borrado


             update fichaje_funcionario
                set computadas=0
                where id_secuencia=  v_id_secuencia
                and  id_funcionario = i_funcionario and rownum<2;


          --añadido nuevo
          --chm 20/03/2019
           update fichaje_funcionario_tran
                set computadas = 0
                where  id_funcionario = i_funcionario and
                       id_sec in  (  v_id_sec_salida, v_id_sec_entrada) and rownum<3;

             finger_calcula_saldo( i_funcionario,v_Fechas_horas);


         update fichaje_funcionario
         set computadas=TRP_NOMINA
         where fecha_fichaje_entrada = to_Date(to_char(v_Fechas_horas,'dd/mm/yyyy')  || ' '|| v_hora_inicio,'DD/MM/YYYY HH24:MI')
         and  id_funcionario = i_funcionario and rownum<2;


         --leemos el fichaje
         BEGIN
           select       id_sec_salida,   id_sec_entrada
                 into v_id_sec_salida, v_id_sec_entrada
              from fichaje_funcionario
             where fecha_fichaje_entrada = to_Date(to_char(v_Fechas_horas,'dd/mm/yyyy') || ' '|| v_hora_inicio,'DD/MM/YYYY HH24:MI')
                and  id_funcionario = i_funcionario and rownum<2;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                     i_ficha:=0;
            END;

          --añadido nuevo
          --chm 20/03/2019
           update fichaje_funcionario_tran
                   set computadas = TRP_NOMINA
                 where
                   id_funcionario = i_funcionario and
                       id_sec in  (  v_id_sec_salida, v_id_sec_entrada) and rownum<3;

           finger_calcula_saldo( i_funcionario,v_Fechas_horas);


    END IF;









end  FICHAJE_INSERTA_TRAN_HEXTRAS;
/

