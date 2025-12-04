create or replace procedure rrhh.FICHAJE_CALCULA_SALDO_REGE_ANT(
          V_ID_PRIMER_FICHAJE in varchar2,
          V_ID_SEGUNDO_FICHAJE in varchar2,
          V_ID_FUNCIONARIO in number,
          v_codpers     in number,

          msgsalida out varchar2,todook out varchar2,primero_f in number) is

 v_cadena_t varchar2(22222);

  msgBasico        varchar2(255);

  PRIMER_SEC            number;
  PRIMER_RELOJ          varchar2(3);
  PRIMER_AUSENCIA       number;
  PRIMER_TIPOTRANS      number;
  PRIMER_PERIODO         varchar2(3);
  PRIMER_FECHA_FICHAJE  date;
  Poriginal_FECHA_FICHAJE date;

  segundo_SEC            number;
  segundo_RELOJ          varchar2(3);
  segundo_AUSENCIA       number;
  segundo_TIPOTRANS      number;
  segundo_PERIODO         varchar2(3);
  segundo_FECHA_FICHAJE  date;
  Soriginal_FECHA_FICHAJE date;

   i_hora_comp         NUMBER;
    i_MINUTOS_comp     NUMBER;
     i_hora_comp_f         NUMBER;
    i_MINUTOS_comp_f     NUMBER;
     i_hora_comp_f2         NUMBER;
    i_MINUTOS_comp_f2     NUMBER;

    fuera_com number;

  i_p1d          date;
  i_p1h          date;
  i_p2d          date;
  i_p2h          date;
  i_p3d          date;
  i_p3h          date;
  i_po1d         date;
  i_po1h         date;
  i_po2d         date;
  i_po2h         date;
  i_po3d         date;
  i_po3h         date;

  i_horas_saldo  number;
  i_horas_fichadas number;

  I_SIN_CALENDARIO number;

  d_computables   date;
  d_fichadas     date;
  d_horas_fuera  date;
   d_computables_o date;

    i_incidencia number;
    V_INCIDENCIA_OBS varchar2(256);
begin

  PRIMER_SEC:= devuelve_valor_campo(V_ID_PRIMER_FICHAJE ,'S');
  PRIMER_RELOJ:= devuelve_valor_campo(V_ID_PRIMER_FICHAJE ,'R');
  PRIMER_AUSENCIA:= devuelve_valor_campo(V_ID_PRIMER_FICHAJE ,'A');
  PRIMER_TIPOTRANS:= devuelve_valor_campo(V_ID_PRIMER_FICHAJE ,'T');
  PRIMER_PERIODO:= devuelve_valor_campo(V_ID_PRIMER_FICHAJE ,'P');
  PRIMER_FECHA_FICHAJE:= to_date(devuelve_valor_campo(V_ID_PRIMER_FICHAJE ,'F'),'dd/mm/yyyy hh24:mi');
    Poriginal_FECHA_FICHAJE:=PRIMER_FECHA_FICHAJE;
  segundo_SEC:= devuelve_valor_campo(V_ID_segundo_FICHAJE ,'S');
  segundo_RELOJ:= devuelve_valor_campo(V_ID_segundo_FICHAJE ,'R');
  segundo_AUSENCIA:= devuelve_valor_campo(V_ID_segundo_FICHAJE ,'A');
  segundo_TIPOTRANS:= devuelve_valor_campo(V_ID_segundo_FICHAJE ,'T');
  segundo_PERIODO:= devuelve_valor_campo(V_ID_segundo_FICHAJE ,'P');
  segundo_FECHA_FICHAJE:= to_date(devuelve_valor_campo(V_ID_segundo_FICHAJE ,'F'),'dd/mm/yyyy hh24:mi');
   Soriginal_FECHA_FICHAJE:=segundo_FECHA_FICHAJE;
   I_SIN_CALENDARIO :=1;
  --lee la jornada para ese día
  --buscamos periodo del fichaje
      BEGIN
        select to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(HIF1,'hh24:mi') ,'dd/mm/yyyy hh24:mi')  as p1d,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(HFF1,'hh24:mi'), 'dd/mm/yyyy hh24:mi')  as p1h,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(HIF2, 'hh24:mi'),'dd/mm/yyyy hh24:mi')  as p2d,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(HFF2, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as p2h,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(HIF3, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as p3d,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(HFF3, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as p3h,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(HIO1, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as po1d,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(HFO1, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as po1h,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(HIO2, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as po2d,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(HFO2, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as po2h,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(HIO3, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as po3d,
             to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy') || to_char(HFO3, 'hh24:mi'),'dd/mm/yyyy hh24:mi') as po3h
        into  i_p1d,i_p1h,
                          i_p2d,i_p2h,
                          i_p3d,i_p3h ,
                          i_po1d,i_po1h,
                          i_po2d,i_po2h,
                          i_po3d,i_po3h
                   from  presenci t
                   where fecha=to_Date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy'),'dd/mm/yyyy')
                         and codpers=v_codpers;
       EXCEPTION
       WHEN NO_DATA_FOUND THEN
           I_SIN_CALENDARIO :=0;
       END;


      IF   PRIMER_PERIODO  = 'P1' and SEGUNDO_PERIODO='P2'  THEN
        IF  PRIMER_FECHA_FICHAJE > i_p1h and SEGUNDO_FECHA_FICHAJE> i_p1h THEN
             PRIMER_PERIODO := 'P2';--cambiamos al periodo 2
        END IF;
      END IF;

      IF   PRIMER_PERIODO  = 'P1' THEN
        IF  PRIMER_FECHA_FICHAJE < i_p1d THEN
             PRIMER_FECHA_FICHAJE:=i_p1d;
        END IF;

      END IF;

      IF   PRIMER_PERIODO  = 'P1'   THEN
        IF   SEGUNDO_FECHA_FICHAJE> i_p1h THEN
             SEGUNDO_FECHA_FICHAJE:=i_p1h;
        END IF;
      END IF;


      IF   PRIMER_PERIODO  = 'P2' and SEGUNDO_PERIODO='P2'  THEN
        IF  PRIMER_FECHA_FICHAJE < i_p2d THEN
             PRIMER_FECHA_FICHAJE:=i_p2d;
        END IF;

        IF  SEGUNDO_FECHA_FICHAJE > i_p2h THEN
              SEGUNDO_FECHA_FICHAJE:=i_p2h;
        END IF;

      END IF;

      i_horas_saldo:=(SEGUNDO_FECHA_FICHAJE-PRIMER_FECHA_FICHAJE)*24*60;
      i_hora_comp:=horas_min_entre_dos_fechas(SEGUNDO_FECHA_FICHAJE,PRIMER_FECHA_FICHAJE,'H');
      i_minutos_comp:=horas_min_entre_dos_fechas(SEGUNDO_FECHA_FICHAJE,PRIMER_FECHA_FICHAJE,'M');


      d_computables    := to_date('30/12/1899 ' || lpad(i_hora_comp  , 2, '0') || ':' ||
                               lpad(i_minutos_comp, 2, '0') || ':' || '00',
                               'DD/MM/YYYY HH24:MI:SS');

      i_horas_fichadas:=(Soriginal_FECHA_FICHAJE- Poriginal_FECHA_FICHAJE)*24*60;
      i_hora_comp:=horas_min_entre_dos_fechas(Soriginal_FECHA_FICHAJE,Poriginal_FECHA_FICHAJE,'H');
      i_minutos_comp:=horas_min_entre_dos_fechas(Soriginal_FECHA_FICHAJE,Poriginal_FECHA_FICHAJE,'M');

 i_hora_comp_f:=0;
 i_minutos_comp_f:=0;
 i_hora_comp_f2:=0;
 i_minutos_comp_f2:=0;

    --horas fuera de fichaje
    --
     IF   Poriginal_FECHA_FICHAJE < PRIMER_FECHA_FICHAJE THEN

          i_hora_comp_f:=horas_min_entre_dos_fechas(PRIMER_FECHA_FICHAJE,Poriginal_FECHA_FICHAJE,'H');
          i_minutos_comp_f:=horas_min_entre_dos_fechas(PRIMER_FECHA_FICHAJE,Poriginal_FECHA_FICHAJE,'M');
     END IF;

     IF   Soriginal_FECHA_FICHAJE > SEGUNDO_FECHA_FICHAJE THEN

          i_hora_comp_f2:=horas_min_entre_dos_fechas(Soriginal_FECHA_FICHAJE,SEGUNDO_FECHA_FICHAJE,'H');
          i_minutos_comp_f2:=horas_min_entre_dos_fechas(Soriginal_FECHA_FICHAJE,SEGUNDO_FECHA_FICHAJE,'M');
     END IF;

    IF  i_hora_comp_f<>0 OR  i_minutos_comp_f<>0 OR i_hora_comp_f2<>0 OR i_minutos_comp_f2<>0 THEN

         i_hora_comp_f:=i_hora_comp_f+i_hora_comp_f2;
         i_minutos_comp_f:=i_minutos_comp_f+i_minutos_comp_f2;

       IF   i_minutos_comp_f >= 60  THEN
         i_minutos_comp_f:=i_minutos_comp_f-60;
         i_hora_comp_f:=i_hora_comp_f+1;
       END IF;

    END IF;

/*      i_hora_comp    :=(i_horas_fichadas-trunc(mod((i_horas_fichadas),60)))/60;
      i_minutos_comp :=trunc(mod(i_horas_fichadas,60));
      */
      d_fichadas    := to_date('30/12/1899 ' || lpad(i_hora_comp  , 2, '0') || ':' ||
                               lpad(i_minutos_comp, 2, '0') || ':' || '00',
                               'DD/MM/YYYY HH24:MI:SS');
                               --1999
      d_horas_fuera:=to_date('30/12/1899' || lpad(i_hora_comp_f  , 2, '0') || ':' ||
                               lpad(i_minutos_comp_f, 2, '0') || ':' || '00',
                               'DD/MM/YYYY HH24:MI:SS');
      d_computables_o:=d_computables;
      IF primero_f > 0 then
        d_computables_o:=to_date('30/12/1899','dd/mm/yyyy');
      END IF;

      --INCIDENCIAS------------------------------------------------------------------------------
      -------------------------------------------------------------------------------------------

      --INCIDENCIAS saldo supera las 8 horas-----------------------------------------------------
     /* IF  i_hora_comp >= 8  and  i_hora_comp> 1 THEN
         V_INCIDENCIA_OBS:='Saldo fichado: '  || i_hora_comp || ':'   || lpad(i_hora_comp,2,0);
         BEGIN
           insert into rrhh.fichaje_incidencia
              (id_incidencia, id_tipo_incidencia, nombre_fichero, audit_usuario, audit_fecha, fecha_incidencia, id_funcionario, nombre_ape, id_estado_inc, observaciones)
           values
              ( rrhh.sec_id_incidencia_fihaje.nextval,
                8, '',101217,sysdate, to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy'),'dd/mm/yyyy'),V_ID_FUNCIONARIO,  '', 0, V_INCIDENCIA_OBS);
           EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                  i_incidencia := 0;
           END;
      END IF;   */
       i_incidencia := 0;
      --INCIDENCIA   LIMITES---------------------------------------------------------------------
      --- 4	4	Limite Entrada superado
      ---5	5	Limite Salida no alcanzado
      ---6	6	Limite Ent/Sal Superados.      --30minutos entra
      IF PRIMER_PERIODO='P1' and PRIMER_FECHA_FICHAJE > i_po1d+(1/24*60)*30 THEN
         i_incidencia := 4;
          V_INCIDENCIA_OBS:='Entrada: ' ||   to_char(PRIMER_FECHA_FICHAJE,'hh24:mi')
                             || '<--> Obligatorio:'  ||   to_char(i_po1d,'hh24:mi');
      END IF;

      IF PRIMER_PERIODO='P1' and SEGUNDO_FECHA_FICHAJE < i_po1h THEN
         IF i_incidencia = 4  then
            i_incidencia := 6;
             V_INCIDENCIA_OBS:='Entrada/Salida: ' ||   to_char(PRIMER_FECHA_FICHAJE,'hh24:mi')
                             || '/' || to_char(SEGUNDO_FECHA_FICHAJE,'hh24:mi') ||
                               '<--> Obligatorio:'  ||   to_char(i_po1d,'hh24:mi') || '/' || to_char(i_po1h,'hh24:mi');
         ELSE IF to_number(to_char(i_po1h,'hh24mi'))-to_number(to_char(SEGUNDO_FECHA_FICHAJE,'hh24mi'))< 120 THEN --chm 14/05/2018
            i_incidencia := 5;
             V_INCIDENCIA_OBS:='Salida: ' ||   to_char(SEGUNDO_FECHA_FICHAJE,'hh24:mi')
                             || '<--> Obligatorio:'  ||   to_char(i_po1h,'hh24:mi');
              END IF;
         END IF;
      END IF;

   --   Soriginal_FECHA_FICHAJE- Poriginal_FECHA_FICHAJE
 /*     IF  i_incidencia<> 0 THEN
         BEGIN
           insert into rrhh.fichaje_incidencia
              (id_incidencia, id_tipo_incidencia, nombre_fichero, audit_usuario, audit_fecha, fecha_incidencia, id_funcionario, nombre_ape, id_estado_inc, observaciones)
           values
              ( rrhh.sec_id_incidencia_fihaje.nextval,
                i_incidencia, '',101217,sysdate, to_date(to_char(Poriginal_FECHA_FICHAJE,'dd/mm/yyyy'),'dd/mm/yyyy'),V_ID_FUNCIONARIO,  '', 0, V_INCIDENCIA_OBS);
           EXCEPTION
              WHEN DUP_VAL_ON_INDEX THEN
                  i_incidencia := 0;
           END;
      END IF;  */



      BEGIN

         insert into persfich
                  (npersonal,
         --  contador,
         fecha,
         hinicio,
         hfin,
         reloj,
         tipfich,
         hcomputableo,
         hfuera,
         HFICHADAS,
         HCOMPUTABLEF,
         REQJUSTI,FECHAIMP)
      values
        (lpad(v_codpers, 5, '0'),
         --  i_contador,
         to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy'),'dd/mm/yyyy'),
         Poriginal_FECHA_FICHAJE,
         Soriginal_FECHA_FICHAJE,
         PRIMER_RELOJ,
         '00',
          d_computables_o,--si es segundo fichaje
         d_horas_fuera,
         d_fichadas,
         d_computables,
         0,to_date(to_char(PRIMER_FECHA_FICHAJE,'dd/mm/yyyy'),'dd/mm/yyyy'));

              EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
           I_SIN_CALENDARIO :=0;
        END;

COMMIT;
msgsalida:=v_cadena_t;
todook:='0';
END  FICHAJE_CALCULA_SALDO_REGE_ANT;
/

