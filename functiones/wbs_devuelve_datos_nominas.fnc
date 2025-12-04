create or replace function rrhh.wbs_devuelve_datos_nominas(i_id_funcionario IN VARCHAR2,
                                                      cuantas_nominas  in number,
                                                      v_id_nomina        in varchar2)  
    return clob is
  --cuantas_nominas 24 ---> todas dos ultimos años.
  --cuantas_nominas 2 ---> solo las dos ultimas
  Resultado clob;
  observaciones varchar2(12000);

  saldo_horario       varchar2(123);
  fichaje_teletrabajo varchar2(123);
  firma_planificacion varchar2(123);
  datos               varchar2(12000);
  datos_tmp           clob;
  contador            number;
  i_mes               number;
  i_anio              number;
  --Funcionarios en activo   
  CURSOR C0 is
    select distinct json_object('ID_NoMINA' is
                                lpad(periodo, 6, '0') || ID_NOMINA,
                                'Periodo' is
                                substr(lpad(periodo, 6, '0'), 3, 4) || ' ' ||
                                DECODE(substr(lpad(periodo, 6, '0'), 1, 2),
                                       '01',
                                       'ENERO',
                                       '02',
                                       'FEBRERO',
                                       '03',
                                       'MARZO',
                                       '04',
                                       'ABRIL',
                                       '05',
                                       'MAYO',
                                       '06',
                                       'JUNIO',
                                       '07',
                                       'JULIO',
                                       '08',
                                       'AGOSTO',
                                       '09',
                                       'SEPTIEMBRE',
                                       '10',
                                       'OCTUBRE',
                                       '11',
                                       'NOVIEMBRE',
                                       '12',
                                       'DICIEMBRE',
                                       '') || ' ID_NOMINA:' || ID_NOMINA,
                                'anio' is
                                substr(lpad(periodo, 6, '0'), 3, 4),
                                'mes' is substr(lpad(periodo, 6, '0'), 1, 2),
                                'cantidad' is
                                nvl(cantidad,0))
                                ,
                    substr(lpad(periodo, 6, '0'), 1, 2) as mes,
                    substr(lpad(periodo, 6, '0'), 3, 4) as anio
      from personal_new A, NOMINA_FUNCIONARIO n
     WHERE lpad(NIF, 9, '0') = lpad(DNI, 8, '0') || DNI_LETRA
       AND A.ID_FUNCIONARIO = i_id_funcionario
       and substr(lpad(periodo, 6, '0'), 3, 4) >
           to_char(sysdate - 800, 'yyyy')
    
     ORDER BY ANIO DESC, MES DESC;

begin

  datos    := '';
  contador := 0;
  --abrimos cursor.  

  if v_id_nomina = '0' then
    OPEN C0;
    LOOP
      FETCH C0
        into datos_tmp, i_mes, i_anio;
      EXIT WHEN C0%NOTFOUND;
    
      if contador <= cuantas_nominas or contador = 0 then
        if contador = 0 then
          datos := datos_tmp;
        else
          datos := datos || ',' || datos_tmp;
        end if;
      end if;
      contador := contador + 1;
    END LOOP;
    CLOSE C0;
    If cuantas_nominas = 24 then
      resultado := '{"nominas": [' || datos || ']}';
    else
      resultado := '"nominas": [' || datos || ']';
    end if;
  else
  
    select
     '  "file": [ {    "mime": "application/pdf","data": "' || base64encode(nomina) || '"}]'
      into datos_tmp
       from personal_new A, NOMINA_FUNCIONARIO n
     WHERE lpad(NIF, 9, '0') = lpad(DNI, 8, '0') || DNI_LETRA
       AND A.ID_FUNCIONARIO = i_id_funcionario and 
        lpad(n.periodo||n.id_nomina,7,'0')=lpad(v_id_nomina,7,'0')
            and rownum < 2 ;

      
       
    resultado :=  datos_tmp;
  ENd if;

  return(Resultado);
end;
/

