CREATE OR REPLACE PROCEDURE RRHH."FICHAJE_CHEQUEA_HEXTRAS"
(I_FUNCIONARIO in varchar2, i_clave in varchar2,
  i_operacion in varchar2,i_lista_no_actualiza in out varchar2,i_tipo_horas in varchar2)


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
  i_trp_nomina number;

begin

    i_leidos          := 1;
    i_ficha:=1;
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
           id_sec_entrada= i_clave;

    EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                              i_ficha:=0;
    END;


    --OPERACION HORAS.
    IF i_operacion =1 OR i_operacion=2 THEN
        --incluimos en la lista de no borra
        i_lista_no_actualiza:= i_lista_no_actualiza || ' * '||  v_id_sec_entrada || ' * ' ||  v_id_sec_salida ||' * ';
    END IF;

    --Ya estaba.
    IF i_ficha <> 0 and v_computadas=0 and (i_operacion =1 OR i_operacion=2)  THEN


        --Compruebo si la hora esta metida
         BEGIN
           select    id_hora
             into i_id_hora
            from horas_extras
           where phe = v_id_secuencia  And (ANULADO = 'NO' OR ANULADO IS NULL);
          EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                    i_id_hora:=0;
          END;

       --No existen las horas
       IF i_id_hora = 0 THEN
            i_trp_nomina:=i_operacion-1;
           i_resultado:=0;

           IF i_resultado =0 then

                update fichaje_funcionario
                   set computadas = i_operacion
                 where
                   id_funcionario = i_funcionario and
                       id_secuencia=v_id_secuencia and rownum<2;

               --añadido nuevo
               --chm 20/03/2019
               update fichaje_funcionario_tran
                   set computadas = i_operacion
                 where
                   id_funcionario = i_funcionario and
                       id_sec in  (  v_id_sec_salida, v_id_sec_entrada) and rownum<3;

                commit;
           END IF;
           /* raise_application_error(-20005,'*Operacion no realizada.*'
            || v_id_secuencia || ' '
            ||v_id_sec_salida|| ' '
                        || v_id_sec_entrada || ' '

            );*/


       fichaje_inserta_hextras(I_FUNCIONARIO,
                             i_id_ano,
                               i_operacion,
                               i_tipo_horas,--v_id_tipo_horas => v_v_id_tipo_horas,
                               i_trp_nomina,
                               v_fecha_fichaje_entrada,
                               v_fecha_fichaje_ent_h,
                               v_fecha_fichaje_sal_h,
                               v_id_secuencia,
                               '',--v_desc_motivo_horas => v_v_desc_motivo_horas,
                               'NO',--v_anulado => v_v_anulado,
                               '000001');



           /* Begin
                insert into horas_extras_aux
                  ( id_ano, id_funcionario, fecha_horas, id_tipo_horas, hora_inicio, hora_fin,  phe, trp_nomina,
                   id_usuario, fecha_modi)
                values
                  (  i_id_ano,I_FUNCIONARIO, v_fecha_fichaje_entrada, i_tipo_horas, v_fecha_fichaje_ent_h,
                  v_fecha_fichaje_sal_h, v_id_secuencia,  DECODE(i_operacion,1,0,2,1), '000001',sysdate);
             EXCEPTION
             WHEN OTHERS THEN
               i_resultado:=1;
             end; */



       eND IF;
     END IF;

        --ANULAMOS CUANDO EXISTEN  y es 0
        --Es que seguramente se han anulado
        IF i_ficha <> 0 and v_computadas=1 and i_operacion =0 THEN


               --Compruebo si la hora esta metida
             BEGIN
               select    id_hora
                 into i_id_hora
                from horas_extras
               where phe = v_id_secuencia  And (ANULADO = 'NO' OR ANULADO IS NULL);
              EXCEPTION
                           WHEN NO_DATA_FOUND THEN
                        i_id_hora:=0;
              END;

              update  horas_extras
              set ANULADO='SI',
                  FECHA_ANULADO=sysdate
              where   id_hora=i_id_hora and rownum<2;

               update fichaje_funcionario
                   set computadas = i_operacion
                 where
                   id_funcionario = i_funcionario and
                       id_secuencia=v_id_secuencia and rownum<2;

               --añadido nuevo
               --chm 20/03/2019
               update fichaje_funcionario_tran
                   set computadas = i_operacion
                 where
                   id_funcionario = i_funcionario and
                       id_sec in  (  v_id_sec_salida, v_id_sec_entrada) and rownum<3;


        END IF;









end FICHAJE_CHEQUEA_HEXTRAS;
/

