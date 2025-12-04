create or replace procedure rrhh.ACTUALIZA_FINGER(V_ID_ANO            in number,
                                             V_ID_FUNCIONARIO    in number,
                                             V_ID_TIPO_PERMISO   in varchar2,
                                             V_FECHA_INICIO      in DATE,
                                             V_FECHA_FIN         in DATE,
                                             v_codpers           in varchar2,
                                             V_ID_ESTADO_PERMISO in number,
                                             todo_ok_Basico      out integer,
                                             msgBasico           out varchar2) is

  i_hora_inicio      number;
  i_hora_fin         number;
  i_no_hay_permisos  number;
  i_num_dias         number;
  i_id_tipo_dias     number;
  i_unico            varchar2(2);
  i_resta_fechas     number;
  i_contador_laboral number;
  i_contador_natural number;
  i_contador         number;
  i_ficha            number;
  i_codpers          number;
  i_id_funcionario   number;
  i_fecha_in         number;
  i_fecha_out        number;
  i_dia_encontrado   number;
  i_dias             date;

  i_id_ano_inicio varchar2(4);
  i_id_ano_fin    varchar2(4);
  v_fecha_fins date;
 V_DIAS_p DATE;


CURSOR DIAS(v_fecha_inicio date,v_fecha_fin date) is
select ID_DIA
from caLENDARIO_LABORAL
where  ID_DIA BETWEEN V_fecha_inicio and  v_fecha_fin ;

begin

  todo_ok_basico := 0;
  msgBasico      := '';


      --CHM 15/02/2019
      --CALCULO DE SALDO TODOS LOS DIAS DEL PERMISO
      OPEN DIAS(V_FECHA_INICIO,V_FECHA_FIN);

                  LOOP
                    FETCH DIAS
                      into    V_DIAS_p;
                   EXIT WHEN DIAS%NOTFOUND;

                  finger_calcula_saldo(V_ID_FUNCIONARIO,
                                       V_DIAS_p);




                    END LOOP;
        CLOSE DIAS;



  --chm 21/03/2017
  --BAJA MEDICA SIN FECHA
       IF  V_ID_TIPO_PERMISO = '11300' AND  v_fecha_fin is null THEN
         v_fecha_fins:= v_fecha_inicio+3;
       ELSE
           v_fecha_fins:=V_FECHA_FIN;
       END IF;
  --todo_ok_basico:=1;
  --msgBasico:=V_ID_ESTADO_PERMISO;
  -- Fechas las pasamos a numero para hacer el FOR.
  i_fecha_in  := to_number(to_char(to_date(V_FECHA_INICIO, 'DD/MM/YYYY'),
                                   'ddd'));
  i_fecha_out := to_number(to_char(to_date(v_fecha_fins, 'DD/MM/YYYY'),
                                   'ddd'));

  i_id_ano_inicio := substr(to_char(to_date(V_FECHA_INICIO, 'DD/MM/YY'),
                                    'DD/MM/YYYY'),
                            7,
                            4);
  i_id_ano_fin    := i_id_ano_inicio;

  --Si pedimos  de este a?o y del que viene
  IF i_fecha_in > i_fecha_out AND i_fecha_in > 340 THEN
    i_id_ano_inicio := substr(to_char(to_date(V_FECHA_INICIO, 'DD/MM/YY'),
                                      'DD/MM/YYYY'),
                              7,
                              4);
    i_id_ano_fin    := i_id_ano_inicio;
    i_fecha_out     := 365;

    --Primero hacemos  hasta fin de a?o.
    for fecha_au in i_fecha_in .. i_fecha_out loop
      i_dia_encontrado := 1;
      BEGIN
        SELECT ID_DIA
          into i_dias
          from calendario_laboral
         where to_char(id_dia, 'DD/MM/YYYY') between
               to_char(to_date(lpad(fecha_au, 3, 0) || i_id_ano_inicio,
                               'dddyyyy'),
                       'DD/MM/') || i_id_ano_inicio and
               to_char(to_date(lpad(fecha_au, 3, 0) || i_id_ano_inicio,
                               'dddyyyy'),
                       'DD/MM/') || i_id_ano_inicio
           and laboral = 'SI'
           and id_ano = i_id_ano_inicio;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_dia_encontrado := 0;
      END;
      -- raise_application_error(-20002,'*' || i_dia_encontrado ||to_char(i_dias,'DD/MM/YY')|| i_ficha ||'.*');

      IF i_dia_encontrado = 1 then
        IF (V_ID_ESTADO_PERMISO <> 40 AND V_ID_ESTADO_PERMISO <> 41) then --añadido 41. CHM 04/04/2017
          update presenci
             set codinci = substr(lpad(V_id_tipo_permiso,5,'0'), 1, 3)
           where to_char(fecha, 'DD/MM/YY') = to_char(i_dias, 'DD/MM/YY')
             and codpers = lpad(v_codpers, 5, '0')
             and rownum < 2
             and codinci <> 999;
        ELSE
          update --ANULACION
                 presenci
             set codinci = '000'
           where to_char(fecha, 'DD/MM/YY') = to_char(i_dias, 'DD/MM/YY')
             and codpers = lpad(v_codpers, 5, '0')
             and rownum < 2
             and codinci <> 999;
        END IF;

      END IF;

    end loop;
    --AHORA LE DECIMOS QUE HAGA DESDE EL 1 hasta fecha_fin

    i_fecha_out  := to_number(to_char(to_date(v_fecha_fins, 'DD/MM/YYYY'),
                                      'ddd'));
    i_id_ano_fin := substr(to_char(to_date(v_fecha_fins, 'DD/MM/YY'),
                                   'DD/MM/YYYY'),
                           7,
                           4);

    i_id_ano_inicio := i_id_ano_fin;
    i_fecha_in      := 1;

    --porque esta puesto esto¿?
   /* IF i_fecha_out > i_fecha_in + 40 then
      raise_application_error(-20002,
                              '*' ||
                              ' Error Finger. Numero de Dia erroneo.' || '.*');

    END IF;*/

  END IF;

  for fecha_au in i_fecha_in .. i_fecha_out loop
    i_dia_encontrado := 1;
    BEGIN
      SELECT ID_DIA
        into i_dias
        from calendario_laboral
       where to_char(id_dia, 'DD/MM/YYYY') between
             to_char(to_date(lpad(fecha_au, 3, 0) || i_id_ano_fin,
                             'dddyyyy'),
                     'DD/MM/') || i_id_ano_fin and
             to_char(to_date(lpad(fecha_au, 3, 0) || i_id_ano_fin,
                             'dddyyyy'),
                     'DD/MM/') || i_id_ano_fin
         and laboral = 'SI'
         and id_ano = i_id_ano_fin;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_dia_encontrado := 0;
    END;
    -- raise_application_error(-20002,'*' || i_dia_encontrado ||to_char(i_dias,'DD/MM/YY')|| i_ficha ||'.*');

    IF i_dia_encontrado = 1 then
        IF (V_ID_ESTADO_PERMISO <> 40 AND V_ID_ESTADO_PERMISO <> 41) then --añadido 41. CHM 04/04/2017
        update presenci
           set codinci =  substr(lpad(V_id_tipo_permiso,5,'0'), 1, 3)
         where to_char(fecha, 'DD/MM/YY') = to_char(i_dias, 'DD/MM/YY')
           and codpers = lpad(v_codpers, 5, '0')
           and rownum < 2
           and codinci <> 999;
      ELSE
        update --ANULACION
               presenci
           set codinci = '000'
         where to_char(fecha, 'DD/MM/YY') = to_char(i_dias, 'DD/MM/YY')
           and codpers = lpad(v_codpers, 5, '0')
           and rownum < 2
           and codinci <> 999;
      END IF;

    END IF;

  end loop;

  /*añadido 18/10/2020 CHM*/
  finger_regenera_saldo(V_ID_FUNCIONARIO, devuelve_periodo(to_char(V_FECHA_FIN,'MMYYYY')), 10);
  /*añadido para las bajas 19/03/2021 CHM*/
  IF V_ID_TIPO_PERMISO='11300' THEN
     finger_regenera_saldo(V_ID_FUNCIONARIO, devuelve_periodo(to_char(V_FECHA_FIN-30,'MMYYYY')), 10);
  END IF;

end ACTUALIZA_FINGER;
/

