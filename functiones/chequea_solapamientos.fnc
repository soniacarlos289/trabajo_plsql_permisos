create or replace function rrhh.CHEQUEA_SOLAPAMIENTOS(V_ID_ANO          IN NUMBER,
                                                 V_ID_FUNCIONARIO  IN VARCHAR2,
                                                 V_ID_TIPO_PERMISO IN VARCHAR2,
                                                 V_FECHA_INICIO    in DATE,
                                                 v_FECHA_FIN       in DATE,
                                                 V_HORA_INICIO     VARCHAR2,
                                                 V_HORA_FIN        VARCHAR2

                                                 ) return varchar2 is
  Result varchar2(256);

  i_contador             number;
   i_contador2             number;
    i_contador3             number;
     i_contador1             number;
  i_formato_fecha_inicio DATE;
  i_formato_fecha_fin    DATE;

BEGIN

  i_contador             := 0;
  i_contador1             := 0;
  i_contador2             := 0;
  i_contador3             := 0;

  i_formato_fecha_inicio := to_date(to_char(V_FECHA_INICIO, 'DD/MM/YYYY') ||
                                    V_HORA_INICIO,
                                    'DD/MM/YYYY HH24:MI');


 if  (V_FECHA_FIN is not null) then


  i_formato_fecha_fin    := to_date(to_char(V_FECHA_FIN, 'DD/MM/YYYY') ||
                                    V_HORA_FIN,
                                    'DD/MM/YYYY HH24:MI');
  --Solapamiento  Permisos
  BEGIN
    select count(*)
      into i_contador
      from permiso
     where (
               (fecha_inicio between to_date(to_char(V_fecha_inicio,'DD/MM/YYYY'),'DD/MM/YYYY') and to_date(to_char(V_fecha_fin,'DD/MM/YYYY'),'DD/MM/YYYY')   ) OR
               (fecha_fin between to_date(to_char(V_fecha_inicio,'DD/MM/YYYY'),'DD/MM/YYYY') and to_date(to_char(V_fecha_fin,'DD/MM/YYYY'),'DD/MM/YYYY') ) )
       and id_funcionario = V_id_funcionario
       and id_ano = V_id_ano
       and (ANULADO = 'NO' OR ANULADO IS NULL)
       and id_estado not in ('30', '31', '32', '40','41') and id_tipo_permiso <> '15000';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_contador := 0;
  END;


 IF V_ID_TIPO_PERMISO = '15000' AND I_CONTADOR>0 THEN
    --Comprobacion por horas PERMISO 15000 --cambiado i_contado>0
    i_contador1 := 0;
    BEGIN
      select count(*)
        into i_contador1
        from permiso
       where ((to_date(to_char(FECHA_INICIO, 'DD/MM/YYYY') ||
                                    HORA_INICIO,
                                    'DD/MM/YYYY HH24:MI')   between i_formato_fecha_inicio and
             i_formato_fecha_fin) OR
             (to_date(to_char(FECHA_FIN, 'DD/MM/YYYY') ||
                                    HORA_FIN,
                                    'DD/MM/YYYY HH24:MI') between i_formato_fecha_inicio and
             i_formato_fecha_fin))
         AND id_funcionario = V_id_funcionario
        -- and id_tipo_permiso = '15000'
         and id_ano = V_id_ano
         and (ANULADO = 'NO' OR ANULADO IS NULL)
         and id_estado not in ('30', '31', '32', '40','41');
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_contador1 := 0;
    END;


  END IF;

  --Solapamiento  ausencias
  BEGIN
    select count(*)
      into i_contador2
      from ausencia
     where ((FECHA_INICIO between i_formato_fecha_inicio and
           i_formato_fecha_fin) OR
           (FECHA_FIN between i_formato_fecha_inicio and
           i_formato_fecha_fin))
       AND

           id_funcionario = V_id_funcionario
       and id_ano = V_id_ano
       and (ANULADO = 'NO' OR ANULADO IS NULL
        and id_estado not in ('30', '31', '32', '40','41'));
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_contador2 := 0;
  END;

  --Solapamiento  bajas /*borrado*/ ya esta metido como permiso
 /* BEGIN
    select count(*)
      into i_contador3
      from bajas_ilt
     where ((to_date(to_char(V_fecha_inicio, 'DD/MM/YY'), 'DD/MM/YY') between
           TO_date(to_CHAR(FECHA_INICIO, 'DD/mm/yy'), 'dd/mm/yy') and
           to_date(TO_CHAR(FECHA_FIN, 'DD/mm/yy'), 'dd/mm/yy')) OR
           (to_date(to_char(V_fecha_fin, 'DD/MM/YY'), 'DD/MM/YY') between
           to_date(TO_CHAR(FECHA_INICIO, 'DD/mm/yy'), 'DD/mm/yy') and
           to_date(TO_char(FECHA_FIN, 'DD/mm/yy'), 'DD/mm/yy')) --OR
           )
       and id_funcionario = V_id_funcionario
       and id_ano = V_id_ano
       and ANULADA = 'NO';
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_contador3 := 0;
  END;*/
  end if;
  if (I_CONTADOR<>0 AND v_id_tipo_permiso<>15000)or
     (I_CONTADOR1<>0 AND v_id_tipo_permiso=15000)
  THEN
      Result := 'Existe un permiso entre esas fechas';--hAY COINCIDENCIA
  Else if   I_CONTADOR2<>0 THEN
          Result := 'Existe una ausencia entre esas fechas';--hAY COINCIDENCIA
       else if   I_CONTADOR3<>0 THEN
                Result := 'Existe una baja entre esas fechas';--hAY COINCIDENCIA
             end if;
       end if;
      Result := '0';
  END IF;
  return(Result);
end CHEQUEA_SOLAPAMIENTOS;
/

