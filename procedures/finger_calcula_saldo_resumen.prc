CREATE OR REPLACE PROCEDURE RRHH."FINGER_CALCULA_SALDO_RESUMEN" (i_funcionario in varchar2,
                                                         v_fecha_p     in date) is

  i_horas_saldo NUMBER;
  i_horas_hacer number;
  I_ID_SEC      NUMBER;
  i_pin         NUMBER;
  i_turno1      NUMBER;
  i_turno2      NUMBER;
  i_turno3      NUMBER;
  i_festivo     number;
  i_ausencias   number;
  i_permiso    number;
  i_id_calendario number;
  i_horas_extras_pagadas number;
  i_horas_extras_comp number;
   i_incidencias number;
   i_numero_transacc number;
   i_numero_fichajes number;

   i_p1d   VARCHAR2(10);
   i_p1h VARCHAR2(10);
   i_p2d VARCHAR2(10);
   i_p2h VARCHAR2(10);
   i_p3d VARCHAR2(10);
   i_p3h VARCHAR2(10);
   i_po1d VARCHAR2(10);
   i_po1h VARCHAR2(10);
   i_po2d VARCHAR2(10);
   i_po2h VARCHAR2(10);
   i_po3d VARCHAR2(10);
   i_po3h VARCHAR2(10);
    i_contar_comida VARCHAR2(10);
    i_libre VARCHAR2(10);
    i_turnos  VARCHAR2(10);

    dia_semana number;
    i_periodo_hc VARCHAR2(10);
    i_funcionariohc VARCHAR2(10);
    i_diahc date;
    i_laboralhc VARCHAR2(10);

    es_sabado number;
    es_domingo number;
          i_horas_fichadas number;
    i_teletrabajo number;
    i_tipo_funcionario number;
    i_contratacion number;
Begin

 --PIN Y TURNOS
  begin
   select ID_CALENDARIO,sum(DECODE(TURNO,1,1,0)) as TURNO1
          ,sum(DECODE(TURNO,2,1,0)) as TURNO2
          ,sum(DECODE(TURNO,3,1,0)) as TURNO3
          into i_id_calendario,i_turno1,i_turno2,i_turno3
      from FICHAJE_FUNCIONARIO
     where id_funcionario = i_funcionario
       and to_date(to_char(fecha_fichaje_entrada, 'dd/mm/yyyy'),
                   'dd/mm/yyyy') = v_fecha_p
       group by ID_CALENDARIO;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN

           i_turno1  := 0;
           i_turno2  := 0;
           i_turno3    := 0;
    when too_many_rows THEN
       i_turno1  := 0;
           i_turno2  := 0;
           i_turno3    := 0;
  END;

   -- PIN
  begin
  select NVL(PIN, 0) as PIN,teletrabajo,tipo_funcionario2
    into i_pin,i_teletrabajo, i_tipo_funcionario
    from FUNCIONARIO_FICHAJE f, personal_new p
   where f.id_funcionario(+) = p.id_funcionario
     and p.id_funcionario = I_funcionario
     and rownum < 2;
  EXCEPTION
     WHEN NO_DATA_FOUND
       THEN i_pin := 0;
        i_teletrabajo:=0;
        i_tipo_funcionario:=0;
 END;

 --calculamos una especial para el teletrabajo.
  IF i_teletrabajo= 0 THEN
        ----horas_saldo en el día
        begin
          select nvl(TRUNC(sum(HORAS_SALDO)),0),nvl(TRUNC(sum(HORAS_FICHADAS)),0)
           into i_horas_saldo,i_horas_fichadas
               --   into i_horas_saldo,i_horas_fichadas
            from FICHAJE_FUNCIONARIO
           where id_funcionario = i_funcionario
             and to_date(to_char(fecha_fichaje_entrada, 'dd/mm/yyyy'),
                         'dd/mm/yyyy') =v_fecha_p
                        and PERMISO_EN_DIA(ID_FUNCIONARIO,to_date(to_char(fecha_fichaje_entrada, 'dd/mm/yyyy'),'dd/mm/yyyy'))=0  --quitado compute los domingos/teletrabajo/permiso dias
             and computadas = 0;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_horas_saldo := 0;
            i_horas_fichadas:=0;
        END;
  ELSE --TELETRABAJO
        ----horas_saldo en el día
        begin
          select nvl(TRUNC(sum(HORAS_SALDO)),0),nvl(TRUNC(sum(HORAS_FICHADAS)),0)
           into i_horas_saldo,i_horas_fichadas
               --   into i_horas_saldo,i_horas_fichadas
            from FICHAJE_FUNCIONARIO
           where id_funcionario = i_funcionario
             and to_date(to_char(fecha_fichaje_entrada, 'dd/mm/yyyy'),
                         'dd/mm/yyyy') =v_fecha_p
                        --and PERMISO_EN_DIA(ID_FUNCIONARIO,to_date(to_char(fecha_fichaje_entrada, 'dd/mm/yyyy'),'dd/mm/yyyy'))=0  --quitado compute los domingos/teletrabajo/permiso dias
             and computadas = 0;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            i_horas_saldo := 0;
            i_horas_fichadas:=0;
        END;



  END IF;



   --horas_hacer en el día

  begin
  select ow.mes||ow.ano as periodo,id_funcionario,cl.id_dia,cl.laboral,
        DECODE(cl.laboral,'NO',0, sum(
         ((f.horas_jornada-to_Date('01/01/1900 00:00','DD/mm/yyyy hh24:mi'))*60*24)*(devuelve_dia_jornada(dias_semana,cl.id_dia )))) as horas_hacer
   into i_periodo_hc,i_funcionariohc,i_diahc,i_laboralhc,i_horas_hacer

  from  fichaje_funcionario_jornada f,calendario_laboral cl, webperiodo ow
  where
      cl.id_dia  between f.fecha_inicio and nvl(f.fecha_fin ,sysdate) and
      cl.id_dia  between ow.inicio and ow.fin and
      cl.id_dia=v_fecha_p and
      f.id_funcionario=i_funcionario and PERMISO_EN_DIA(f.ID_FUNCIONARIO,cl.id_dia)=0 --ese dia no tenga permiso.
  group by ow.mes||ow.ano, id_funcionario,cl.id_dia,cl.laboral ;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
     i_horas_hacer := 0;
  END;

      --añadir los subcontratados. chm 08/05/2019
   -- DIa santa rita y lunes de agua 29/04/2019 y 22/05/2019.
--   REDUCCIONES
--961156  21.5
--961183  57.1
--961731  50
--961733  50

    BEGIN
       select distinct contratacion into i_contratacion from personal_new
       where id_funcionario=I_FUNCIONARIO and rownum<2 and (fecha_baja is null or fecha_baja> sysdate);
     EXCEPTION
    WHEN NO_DATA_FOUND THEN
          i_contratacion:=0;
    END;

    IF i_contratacion =2 and (v_fecha_p = to_Date('22/05/2019','dd/mm/yyyy') OR v_fecha_p =to_Date('29/04/2019','dd/mm/yyyy')
         OR v_fecha_p =to_Date('25/04/2022','dd/mm/yyyy') OR v_fecha_p =to_Date('17/04/2023','dd/mm/yyyy')   OR v_fecha_p =to_Date('22/05/2023','dd/mm/yyyy')
         OR v_fecha_p =to_Date('08/04/2024','dd/mm/yyyy')   OR v_fecha_p =to_Date('22/05/2024','dd/mm/yyyy')
          OR v_fecha_p =to_Date('28/04/2025','dd/mm/yyyy')   OR v_fecha_p =to_Date('22/05/2025','dd/mm/yyyy')
         )
       and PERMISO_EN_DIA(I_FUNCIONARIO,v_fecha_p)=0

     THEN
       i_horas_hacer:=420;
       i_laboralhc:='SI';

       --reducciones de jornada
     /*  IF I_FUNCIONARIO=961731 OR I_FUNCIONARIO=961733 THEN
          i_horas_hacer:=210;
       END IF;
       IF I_FUNCIONARIO=961183 THEN
          i_horas_hacer:=240;
       END IF;

       IF I_FUNCIONARIO=961156 THEN
          i_horas_hacer:=225;
       END IF;*/

    end if;
    --No cuente para saldo
     IF  i_tipo_funcionario<>21 and i_contratacion =1 and (v_fecha_p = to_Date('22/05/2019','dd/mm/yyyy') OR v_fecha_p =to_Date('29/04/2019','dd/mm/yyyy')
           OR v_fecha_p =to_Date('25/04/2022','dd/mm/yyyy')   OR v_fecha_p =to_Date('17/04/2023','dd/mm/yyyy')   OR v_fecha_p =to_Date('22/05/2023','dd/mm/yyyy')
               OR v_fecha_p =to_Date('08/04/2024','dd/mm/yyyy')   OR v_fecha_p =to_Date('22/05/2024','dd/mm/yyyy')
          OR v_fecha_p =to_Date('28/04/2025','dd/mm/yyyy')   OR v_fecha_p =to_Date('22/05/2025','dd/mm/yyyy')
           ) THEN
        i_horas_saldo:=0;
         i_horas_hacer:=0;

    end if;


  ----horas_extras_compensadas en el día
  begin
    select nvl(TRUNC(sum(HORAS_SALDO)),0)
      into i_horas_extras_comp
      from FICHAJE_FUNCIONARIO
     where id_funcionario = i_funcionario
       and to_date(to_char(fecha_fichaje_entrada, 'dd/mm/yyyy'),
                   'dd/mm/yyyy') = v_fecha_p
       and computadas = 1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_horas_extras_comp := 0;
  END;


  ----horas_extras_compensadas en el día
  begin
    select nvl(trunc(sum(HORAS_SALDO)),0)
      into i_horas_extras_pagadas
      from FICHAJE_FUNCIONARIO
     where id_funcionario = i_funcionario
       and to_date(to_char(fecha_fichaje_entrada, 'dd/mm/yyyy'),
                   'dd/mm/yyyy') = v_fecha_p
       and computadas = 2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_horas_extras_pagadas := 0;
  END;



  --FESTIVOS
   begin
    select DECODE(FESTIVO,'SI',1,0)
    into i_festivo
    from CALENDARIO_LABORAL t
    where  to_date(to_char(id_dia, 'dd/mm/yyyy'),
                   'dd/mm/yyyy') = v_fecha_p;
   EXCEPTION
    WHEN NO_DATA_FOUND THEN
          i_festivo   := 0;
   END;

   --ausencias
    Begin
      select COunt(*)
        into i_ausencias
        from ausencia
       where to_date(to_char(fecha_inicio, 'dd/mm/yyyy'), 'dd/mm/yyyy') =
             to_date(to_char(v_fecha_p, 'dd/mm/yyyy'), 'dd/mm/yyyy')
      --   and JUSTIFICADO = 'SI'
         and (ANULADO = 'NO' OR ANULADO is null)
         and id_estado = 80
         and id_funcionario = i_funcionario;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_ausencias:=0;
      when too_many_rows THEN
       i_ausencias:=2;
    END;

                    --permisos en dia
                    Begin
                      select count(*)
                        into i_permiso
                        from permiso
                       where to_date(to_char(fecha_inicio, 'dd/mm/yyyy'),
                                     'dd/mm/yyyy') =
                             to_date(to_char(v_fecha_p, 'dd/mm/yyyy'),
                                     'dd/mm/yyyy')

                         and (ANULADO = 'NO' OR ANULADO is null)
                         and id_estado = 80
                         and id_funcionario = I_funcionario;
                    EXCEPTION
                      WHEN NO_DATA_FOUND THEN
                        i_permiso := 0;
                      when too_many_rows THEN
                        i_permiso := 2;
                    END;


--incidencias en dia
Begin
  select count(*)
    into i_incidencias
    from FICHAJE_INCIDENCIA t
   where id_funcionario = i_funcionario
     and to_date(to_char(fecha_incidencia, 'dd/mm/yyyy'), 'dd/mm/yyyy') =
         v_fecha_p;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    i_permiso := 0;
  when too_many_rows THEN
    i_permiso := 2;
END;

 ----numnero de fichaje
  begin
    select count(*)
      into i_numero_fichajes
      from FICHAJE_FUNCIONARIO
     where id_funcionario = i_funcionario
       and to_date(to_char(fecha_fichaje_entrada, 'dd/mm/yyyy'),
                   'dd/mm/yyyy') = v_fecha_p;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_numero_fichajes := 0;
  END;

  --numero de transacciones
   begin
    select count(*)
      into i_numero_transacc
      from fichaje_funcionario_tran
     where id_funcionario = i_funcionario
       and to_date(to_char(fecha_fichaje, 'dd/mm/yyyy'),
                   'dd/mm/yyyy') = v_fecha_p;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       i_numero_transacc := 0;
  END;

     --Si da 1 se ejecuta desde la web
                --si da 2 se ejecuta desde pl/sql
                select tO_char(to_date('07/01/2019','dd/mm/yyyy'), 'D') into  dia_semana  from dual;

                If dia_semana = 1 THEN
                  dia_semana:=1;
                ELSE
                  dia_semana:=0;
                End if;



  --lee la jornada para ese día
  --buscamos periodo del fichaje
      BEGIN
      select distinct  to_char(p1_fle_desde,'hh24:mi')   as p1d,
              to_char(p1_fle_hasta,'hh24:mi')  as p1h,
              to_char(p2_fle_desde, 'hh24:mi')  as p2d,
              to_char(p2_fle_hasta, 'hh24:mi') as p2h,
              to_char(p3_fle_desde, 'hh24:mi') as p3d,
              to_char(p3_fle_hasta, 'hh24:mi') as p3h,
              to_char(p1_obl_desde, 'hh24:mi') as po1d,
              to_char(p1_obl_hasta, 'hh24:mi') as po1h,
              to_char(p2_obl_desde, 'hh24:mi') as po2d,
              to_char(p2_obl_hasta, 'hh24:mi') as po2h,
              to_char(p3_obl_desde, 'hh24:mi') as po3d,
              to_char(p3_obl_hasta, 'hh24:mi') as po3h,
                 CONTAR_COMIDA,
                          LIBRE,DECODE(TURNO,'SI',1,0)
            into  i_p1d,i_p1h,
                  i_p2d,i_p2h,
                  i_p3d,i_p3h ,
                  i_po1d,i_po1h,
                  i_po2d,i_po2h,
                  i_po3d,i_po3h
                  , i_contar_comida,i_libre,i_turnos
        from FICHAJE_CALENDARIO_JORNADA t, fichaje_funcionario_jornada ff,  fichaje_calendario fc
        where t.id_calendario=ff.id_calendario and
               t.id_calendario=fc.id_calendario and
           id_funcionario=i_funcionario and
           dia=DECODE(to_number(to_char(v_fecha_p,'d'))+dia_semana,1,8, to_char(v_fecha_p,'d')+dia_semana)
            and  to_date(to_char(v_fecha_p,'dd/mm/yyyy'),'dd/mm/yyyy') between ff.fecha_inicio  and nvl(ff.fecha_fin,sysdate+1)
            and  to_date(to_char(v_fecha_p,'dd/mm/yyyy'),'dd/mm/yyyy') between t.fecha_inicio   and nvl(t.fecha_fin,sysdate+1)
            and rownum<2;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
           i_p1d :=0;
       END;


  --chm 25/02/2019
  --ES sabado.
   es_sabado:=devuelve_dia_jornada('0000010',v_fecha_p);

   --Biblioteca torrente 1cada 4 Sabados
   IF ES_sabado=1 and  i_id_calendario=10 THEN
    i_horas_hacer:=300;--5 horas
   ENd IF;

 --chm 26/02/2019
  --ES domingo.
   es_domingo:=devuelve_dia_jornada('0000001',v_fecha_p);

   --DOMINGO NO CUENTA SALDO.
   -- SALVO A LOS TELETRABAJO --chm 13/03/2019
   --SALVO POLICIAS           --chm18/03/2019
 /*  IF es_domingo = 1 and i_teletrabajo=0 and i_tipo_funcionario<>21  THEN

     i_horas_saldo:=0;--0 horas

   ENd IF;*/




   --Expecciones de jornada
   BEGIN
      select distinct
         jornada_minutos
        into i_horas_hacer
      from   FICHAJE_EXPECION
      where
       dia=DECODE(to_number(to_char(v_fecha_p,'d'))+dia_semana,1,8, to_char(v_fecha_p,'d')+dia_semana) and
           id_funcionario=i_funcionario;
   EXCEPTION
       WHEN NO_DATA_FOUND THEN
           dia_semana:=0;
   END;


if i_pin is not null and i_pin >0 then
 BEGIN
  insert into fichaje_funcionario_resu_dia
    (id_secuencia,
     id_funcionario,
     pin,
     id_dia,
     horas_saldo,
     horas_hacer,
     festivo,
     permiso,
     ausencia,
     turno1,
     turno2,
     turno3,
     id_calendario,
     horas_extras_pagada,
     horas_extras_compensada,
     audit_usuario,
     audit_fecha,
     incidencias,numero_fichajes,numero_transacciones,obli_mañana_1,
                                                     obli_mañana_2,
                                                     fle_mañana_1,
                                                     fle_mañana_2,
                                                     obli_tarde_1,
                                                     obli_tarde_2,
                                                     fle_tarde_1,
                                                     fle_tarde_2,
                                                     obli_noche_1,
                                                     obli_noche_2,
                                                     fle_noche_1,
                                                     fle_noche_2,
                                                     comida,
                                                     libre,
                                      horas_fichadas  ,  horas_fuera_saldo           )
  values
    ( sec_id_fichaje_resu_dia.nextval ,
     i_funcionario,
     i_pin,
     v_fecha_p,
     i_horas_saldo,
     i_horas_hacer,
     i_festivo,
     i_permiso,
     i_ausencias,
     i_turno1,
     i_turno2,
     i_turno3,
     i_id_calendario,
     i_horas_extras_pagadas,
     i_horas_extras_comp,
     101217,
     sysdate,
     i_incidencias,i_numero_fichajes,i_numero_transacc,
      i_po1d,i_po1h,
     i_p1d,i_p1h,i_po2d,i_po2h,
                  i_p2d,i_p2h,
                  i_po3d,i_po3h ,
                  i_p3d,i_p3h ,
                   i_contar_comida,i_libre, i_horas_fichadas, i_horas_fichadas-i_horas_saldo

     );
      EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                  i_incidencias := 0;
           END;
  commit;
end if;

end FINGER_CALCULA_SALDO_RESUMEN;
/

