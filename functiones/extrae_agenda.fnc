create or replace function rrhh.EXTRAE_AGENDA return varchar2 is
  Result varchar2(122);

  pos    number;
  pos2   number;
  v_todo clob;
  vuelta number;

  tmp_hora      varchar2(4000);
  tmp_lugar     varchar2(4000);
  tmp_contenido varchar2(4000);

  posicion_hora          number;
  posicion_lugar         number;
  posicion_lugar_fin     number;
  posicion_contenido_fin number;

  cuantas_horas      number;
  cuantos_lugares    number;
  cuantos_contenidos number;

  operacion_s number;
  i_vacio     number;
    siguiente_posicion_hora number;

  v_id   varchar2(4000);
  d_date date;
  cursor c1 is
    select id, fechas, todo
      from WEB_CONVOCATORIA t
     where todo is not null
       and fechas < '12/05/2021'
       and fechas > '01/01/2018'
       and replace(id, 'C:\temp\noticias\es\agenda\', '') not in
           (select id from TEMP_WEB_CF) --and replace(id, 'C:\temp\noticias\es\agenda\', '') ='convocatoria_1440'
     order by 1 desc;

begin

  OPEN C1;
  LOOP

    FETCH C1
      INTO v_id, d_date, v_todo;
    EXIT WHEN C1%NOTFOUND;

    vuelta             := 1;
    cuantas_horas      := 1;
    cuantos_lugares    := 1;
    cuantos_contenidos := 1;

    posicion_hora := instr(v_todo, 'Hora:', 1, vuelta);
    siguiente_posicion_hora:=instr(v_todo, 'Hora:', 1, vuelta+1);
    operacion_s   := posicion_hora + 6;

    if posicion_hora = 0 then
      posicion_hora := instr(v_todo, 'horas', 1, vuelta);
      siguiente_posicion_hora:=instr(v_todo, 'horas', 1, vuelta+1);
      operacion_s   := posicion_hora - 6;
    end if;

    WHILE posicion_hora > 0 LOOP

      tmp_hora := substr(v_todo, operacion_s, 5);

      if posicion_hora = 0 then
        tmp_hora := substr(v_todo, operacion_s, 5);
      end if;

      if posicion_hora > 0 then
        cuantas_horas := cuantas_horas + 1;
      end if;
      posicion_lugar := instr(v_todo, 'Lugar:', 1, vuelta);


      if posicion_lugar > 0      then
        cuantos_lugares := cuantos_lugares + 1;
      else
         posicion_lugar := instr(v_todo, tmp_hora || ' horas', 1,1)+11;
          posicion_lugar := instr(v_todo, tmp_hora || 'hora: ', 1,1)+5;
      end if;
     /*
      if posicion_lugar > siguiente_posicion_hora then
           posicion_lugar := posicion_hora+11;
       end if;*/



      posicion_lugar_fin     := instr(v_todo, '<br />', posicion_lugar, 1);
       /*if  posicion_lugar_fin = 0 then
           posicion_lugar_fin := instr(v_todo, '</p>', posicion_lugar, 1);
       end IF;*/
      posicion_contenido_fin := instr(v_todo, '<br />', posicion_lugar, 2);

      if posicion_contenido_fin = 0 then
        posicion_contenido_fin := instr(v_todo, '</p>', posicion_lugar, 1);
      end if;
      tmp_lugar     := substr(v_todo,
                              posicion_lugar,
                              posicion_lugar_fin - posicion_lugar);
      tmp_contenido := substr(v_todo,
                              posicion_lugar_fin,
                              posicion_contenido_fin - posicion_lugar_fin);

      tmp_lugar     := replace(replace(replace(replace(tmp_lugar,
                                                       '<strong>',
                                                       ''),
                                               '</strong>',
                                               ''),
                                       '<br />',
                                       ''),
                               '<u>Convocatoria:</u>',
                               '');
      tmp_contenido := replace(replace(replace(replace(replace(replace(replace(replace(tmp_contenido,
                                                                                       '<strong>',
                                                                                       ''),
                                                                               '</strong>',
                                                                               ''),
                                                                       '<br />',
                                                                       ''),
                                                               '<u>Convocatoria:,'')',
                                                               ''),
                                                       '<span style="text-decoration: underline;"',
                                                       ''),
                                               '</span>',
                                               ''),
                                       '<u>',
                                       ''),
                               '</u>',
                               '');

      tmp_hora := replace( replace(tmp_hora, '<', ''),'>', '');
      v_id     := replace(v_id, 'C:\temp\noticias\es\agenda\', '');

   /*  DBMS_OUTPUT.PUT_LINE( '----------'  );
        DBMS_OUTPUT.PUT_LINE( 'Hora: ' || tmp_hora );
        DBMS_OUTPUT.PUT_LINE( 'Lugar: ' ||  tmp_lugar );
        DBMS_OUTPUT.PUT_LINE( 'Contenido: ' || tmp_contenido  );  */

      insert into web_convocatoria_final
        (id, fecha, hora, lugar, contenido)
      values
        (v_id, d_date - 1, tmp_hora, tmp_lugar, tmp_contenido);

      i_vacio := 0;
      if tmp_hora = '' or tmp_lugar = '' OR tmp_contenido = '' or
         tmp_hora is null or tmp_lugar is null OR tmp_contenido is null then
        i_vacio := 1;
      end if;

      vuelta        := vuelta + 1;
      posicion_hora := instr(v_todo, 'Hora:', 1, vuelta);
      operacion_s   := posicion_hora + 6;
      if posicion_hora = 0 then
        posicion_hora := instr(v_todo, 'horas', 1, vuelta);
        operacion_s   := posicion_hora - 6;
      end if;

      Result := 1;
    END LOOP;

    if (cuantas_horas <> cuantos_lugares) or (i_vacio = 1) then
      DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ' vuelta:' || vuelta);
     -- rollback;
    end if;

    commit;
  END LOOP;

  CLOSE C1;

  return(Result);
end EXTRAE_AGENDA;
/

