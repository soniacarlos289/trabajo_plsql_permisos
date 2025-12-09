CREATE OR REPLACE PROCEDURE RRHH."FINGER_GENERA_INFORME" (
          V_ID_FUNCIONARIO in number,
          V_ID_INFORME in varchar2) is

I_ID_TIPO_INFORME number;
I_FILTRO_1        varchar2(100);
I_FILTRO_1_PARA   varchar2(100);
I_FILTRO_2        varchar2(100);
I_FILTRO_2_PARA   varchar2(100);

V_FECHAS_FILTRO     varchar2(100);
V_FECHA_INICIO    date;
V_FECHA_FIN    date;

I_Id_funcionario varchar2(100);
V_CODPERS varchar2(100);
V_nombre varchar2(100);

i_impar varchar2(100);
F_txt varchar2(100);

V_f date;
V_fecha date;
V_entrada varchar2(100);
V_salida varchar2(100);
V_horas_fichadas varchar2(100);
V_horas_hacer varchar2(100);
V_diferencia_minutos varchar2(100);
v_observaciones varchar2(5000);

V_horas_fichadas_M number;
V_horas_hacer_m number;

V_SALDO_TOTAL number;

v_FECHA_EJECUCION date;
 n_col number;
 i_ejecucion numbeR;

  V_acumulado number;
  i_id_unidad number;
  i_horas_fichadas_m number;
  i_horas_hacer_m number;

V_FORMATO_campo varchar2(1000);
V_FORMATO_campo_acumu varchar2(1000);
V_FORMATO_campo_fichadas varchar2(1000);
V_FORMATO_campo_hacer varchar2(1000);
i_tipo_funcionario number;

V_desc_calendario varchar2(1000);
i_HORAS_SEMANALES number;
v_turno varchar2(20);
i_turno number;
vf_fecha_inicio varchar2(20);
vf_fecha_fin varchar2(20);
i_reduccion number;
vf_horas_jornada  varchar2(20);
i_dias number;
v_contar_comida varchar2(20);
v_libre varchar2(20);
v_bolsa varchar2(20);

t_fecha_inicio date;

v_horas_saldo varchar2(120);
n_bajas number;
                          n_permisos number;
                          v_horas_ausencia varchar2(120);
                          v_horas_compensadas varchar2(120);
                          v_BOLSA_SALDO varchar2(120);
                          v_BOLSA_UTIL varchar2(120);


                          v_horas_extras_reali varchar2(120);
                          v_horas_extras_pagadas varchar2(120);
                          v_horas_extras_comp varchar2(120);
                          v_horas_sindicales varchar2(120);
                          n_dias_trabajos number;
                          n_festivo number;
                          n_domingo number;
                          n_sabado number;
                          n_turno_m number;
                          n_turno_t number;
                          n_turno_n number;
                          n_descuento_prod  number;


  I_total varchar2(120);
  i_p2 varchar2(120);
       i_p3 varchar2(120);
       i_p4 varchar2(120);
       i_p5 varchar2(120);
       i_p6 varchar2(120);
       i_p7 varchar2(120);
       i_p8 varchar2(120);
       i_p9 varchar2(120);
       i_p10 varchar2(120);
       i_p11 varchar2(120);
       i_p12 varchar2(120);
       i_p13 varchar2(120);

i_total_numero number;
d_lunes_agua date;
d_santa_rita date;
 i_primer_fichaje_dia number;

 V_TIPO_INCIDENCIAS varchar2(1020);
v_fecha_incidencia date;


V_ID_ANO_p    varchar2(15);
V_TIPO_P      varchar2(120);
V_DESC_PER     Varchar2(1120);
V_FECHA_INICIO_P varchar2(25);
V_FECHA_FIN_P   varchar2(25);
V_NUM_DIAS_p   varchar2(111);

v_id_dia date;
v_fecha_fichaje  varchar2(21);
V_hora varchar2(11);

v_observa varchar2(500);

v_observa_aus varchar2(500);


v_fecha_fichaje_ord date;
i_fuera_saldo number;

--PERSONAS CON EL PARAPETO DE SELECCIóN DE PERSONAS
CURSOR C1 (V_PARAM varchar2) is
select distinct p.Id_funcionario,ID_FICHAJE ,nombre || '  '|| ape1 || '  '|| ape2,'' as id_unidad ,tipo_funcionario2
from    apliweb_usuario u,personal_new p
where 
        u.id_funcionario=p.id_funcionario
       and (p.fecha_baja is null or p.fecha_baja > sysdate)
       and u.id_fichaje is not null
       order by id_funcionario;
CURSOR INFORME_1(v_id_funcionario varchar2,v_fecha_inicio date,v_fecha_fin date) is
/* ANTIGUO*/
   select
        to_char(f, 'dd/mm/yyyy') as F_txt,
       f,
       entrada,
       salida,
       horas_fichadas,
       horas_fichadas_m,
       horas_hacer,
       round(horas_hacer_m) as horas_hacer_m ,
       DECODE(observaciones,'NO COMPUTA PARA SALDO.',0,
      round(to_char(diferencia_minutos))) as dminutos,fuera_saldo,
       observaciones
  from FICHAJE_SALDO_COMPLETA_NEW t
 where id_funcionario =v_id_funcionario
       and f between V_fecha_inicio and  v_fecha_fin
   and (horas_fichadas_m <> 0 OR horas_hacer_m <> 0)
 ORDER BY 2;
 
/* select
       to_char(id_dia, 'dd/mm/yyyy') as f_txt,
       id_dia,
       entrada,
       salida,
       devuelve_min_fto_hora(horas_saldo) as  horas_fichadas,
       horas_saldo  as  horas_fichadas_m,
       devuelve_min_fto_hora(horas_hacer) as horas_hacer,
       horas_hacer as horas_hacer_m,
        to_char(round(diferencia)) as dminutos,
      fuera_saldo as fuera_saldo,
       observaciones
  from FICHAJE_SALDO_COMPLETA_FIN t
 where id_funcionario =v_id_funcionario
       and id_dia between V_fecha_inicio and  v_fecha_fin
 ORDER BY 2, ENTRADA, observaciones desc;*/

CURSOR INFORME_4(v_id_funcionario varchar2,v_fecha_inicio date,v_fecha_fin date) is
select distinct
                   desc_calendario,
                f.HORAS_SEMANALES,
                turno,
                to_char(f.fecha_inicio,'dd/mm/yyyy'),
                to_char(nvl(f.fecha_fin,sysdate+400),'dd/mm/yyyy'),
                reduccion,
                to_char(horas_jornada,'hh24:mi'),
                f.dias,
                contar_comida,
                libre,
                bolsa,f.fecha_inicio
from  fichaje_funcionario_jornada f,calendario_laboral cl, FICHAJE_CALENDARIO FC
where

      cl.id_dia  between f.fecha_inicio and nvl(f.fecha_fin ,sysdate-1) and
      id_funcionario =v_id_funcionario   and
      cl.id_dia between V_fecha_inicio and  v_fecha_fin
      and fc.id_calendario=f.id_calendario order by f.fecha_inicio;

--turnos policia
CURSOR INFORME_5(v_fecha_inicio date,v_fecha_fin date) is
select fc.id_funcionario,
      to_char(fecha_fichaje_entrada,'dd/mm/yyyy') as f_txt,

      to_date(to_char(fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy')  as fec
      ,turno,      DECODE(TURNO,1,'Mañana'
                                        ,2,'Tarde'
                                        ,3,'Noche'
                                        ,'???') as V_TURNO,

                                          f.NOMBRE || ' ' || Ape1 || ' ' || Ape2 as Nombre,
      to_char(fecha_fichaje_entrada,'hh24:mi'),
      to_char(fecha_fichaje_salida,'hh24:mi')
  from FICHAJE_FUNCIONARIO fc, personal_new f
 where
       to_date(to_char(fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy')
            between v_fecha_inicio and  v_fecha_fin and
       fc.id_funcionario=f.id_funcionario
       and f.tipo_funcionario2=21

ORDER BY     fec,TURNO,fc.id_funcionario,   f.NOMBRE || ' ' || Ape1 || ' ' || Ape2;


--turnos bomberos
CURSOR INFORME_6(v_fecha_inicio date,v_fecha_fin date) is
select f.id_funcionario,  f.NOMBRE || ' ' || Ape1 || ' ' || Ape2 ,
       To_char(desde,'dd/mm/yyyy hh24:mi') ,To_char(hasta,'dd/mm/yyyy hh24:mi')
  from BOMBEROS_GUARDIAS_PLANI t,personal_new f
where t.funcionario=f.id_funcionario and
      desde between
      to_Date(to_char(v_fecha_inicio,'dd/mm/yyyy')  || ' 14:00','dd/mm/yyyy hh24:mi') and
      to_Date(to_char(v_fecha_fin,'dd/mm/yyyy')  || ' 14:00','dd/mm/yyyy hh24:mi');


--Estadistica por Año de los funcionarios.
CURSOR INFORME_7(v_id_funcionario varchar2,v_fecha_inicio date) is
select distinct f.id_funcionario,  f.NOMBRE || ' ' || Ape1 || ' ' || Ape2 ,
       devuelve_min_fto_hora(horas_hacer),devuelve_min_fto_hora(horas_saldo),bajas,permisos,
       devuelve_min_fto_hora(horas_ausencia),devuelve_min_fto_hora(horas_compensadas),
       devuelve_min_fto_hora(horas_extras_reali),devuelve_min_fto_hora(horas_extras_pagadas),devuelve_min_fto_hora(horas_extras_comp),
       devuelve_min_fto_hora(horas_sindicales),dias_trabajos,festivo,domingo,sabado,turno_m,turno_t,turno_n,descuento_prod,devuelve_min_fto_hora( bolsa_po),
                                                                                                                           devuelve_min_fto_hora(bolsa_ne)

  from funcionario_resumen t,personal_new f
where t.id_funcionario=f.id_funcionario and (f.fecha_baja is null or fecha_baja > sysdate -730) and --2 años de baja
      t.id_funcionario =v_id_funcionario and
      t.id_ano=to_char(v_fecha_inicio,'yyyy');
      --4 7 FUNCIONARIO NOMBRE  HORAS_ANUALES H_SALDO H_BOLSA_SALDO H_BOLSA_UTILIZADO DIAS_TRABAJADO  D_TRA_FESTIVO D_TRA_DOMIN D_TRA_SABADO  D_BAJA  D_PERMISOS  D_PRODUC  H_AUSENCIAS H_COMPENSADAS H_EXTRAS_HECHAS H_EXTRAS_NOMINA H_EXTRAS_COMP H_SINDICAL  TURNO_T TURNO_N D_PRODUC      AAEpoEABPAAAhmrAAA

-- Incidencias
CURSOR INFORME_8(v_id_funcionario varchar2,v_fecha_inicio date,v_fecha_fin date) is
select distinct
                desc_tipo_incidencia as TI,
                nombre || ' ' || ape1 || ' ' || ape2 as nombres,
                to_char(fecha_incidencia, 'dd/mm/yyyy') as fecha_inc,
                observaciones
FROM FICHAJE_INCIDENCIA f, personal_new pe, tr_tipo_incidencia tr
 where (fecha_baja is null or fecha_baja > sysdate - 1)
   and f.id_funcionario = pe.id_funcionario
   and f.id_tipo_incidencia = tr.id_tipo_incidencia
   and id_Estado_inc = 0
   and f.id_funcionario =v_id_funcionario
   and fecha_incidencia between V_fecha_inicio and  v_fecha_fin;


--Bolsa por Año de los funcionarios.
CURSOR INFORME_11(v_id_funcionario varchar2,v_fecha_inicio date) is
select distinct f.id_funcionario,  f.NOMBRE || ' ' || Ape1 || ' ' || Ape2 ,
   devuelve_min_fto_hora(total),
    total,
       devuelve_min_fto_hora( p2),
        devuelve_min_fto_hora(p3),
        devuelve_min_fto_hora(p4),
        devuelve_min_fto_hora(p5),
        devuelve_min_fto_hora(p6),
        devuelve_min_fto_hora(p7),
        devuelve_min_fto_hora(p8),
        devuelve_min_fto_hora(p9),
        devuelve_min_fto_hora(p10),
        devuelve_min_fto_hora(p11),
        devuelve_min_fto_hora(p12),
       devuelve_min_fto_hora(p13)

  from BOLSA_SALDO_PERIODO_RESUMEN t ,personal_new f
where t.id_funcionario=f.id_funcionario and (f.fecha_baja is null or fecha_baja > sysdate -730) and --2 años de baja
      t.id_funcionario =v_id_funcionario and
      t.id_ano=to_char(v_fecha_inicio,'yyyy');

--PERMISOS SIN JUSTIFICAR
CURSOR INFORME_12(v_id_funcionario varchar2,v_fecha_inicio date,v_fecha_fin date) is
select distinct
        p.NOMBRE || ' ' || Ape1 || ' ' || Ape2 as NOMBREs ,
         pe.ID_ANO ,
          'PERMISO' AS TIPO ,
        tr.DESC_tipo_PERMISO  as DESC_PER ,
        to_char(pe.FECHA_INICIO,'DD/mm/yyyy') as FECHA_INICIO ,
        to_char(pe.FECHA_FIN,'DD/mm/yyyy') as FECHA_FIN ,
        to_char(pe.Num_dias) as NUM_DIAS
from permiso pe,tr_tipo_permiso tr,personal_new p
where  pe.id_ano> 2017 and pe.id_estado=80 and pe.JUSTIFICACION='NO'
and tr.id_tipo_permiso=pe.id_tipo_permiso and
    tr.id_ano=pe.id_ano  and
    pe.fecha_fin< sysdate and
    pe.id_tipo_permiso<>'10000' and--curso
    pe.id_funcionario=p.id_funcionario and
    pe.id_funcionario=v_id_funcionario and
    (
       ( to_DAte(to_char(pe.fecha_inicio,'dd/mm/yyyy'),'dd/mm/yyyy') between V_fecha_inicio and  v_fecha_fin ) OR
       ( to_DAte(to_char(pe.fecha_fin,'dd/mm/yyyy'),'dd/mm/yyyy') between V_fecha_inicio and  v_fecha_fin )
    )  and
    (pe.ANULADO='NO' OR pe.anulado is null)

UNION
--Ausencias SIN JUSTIFICAR

  select
        p.NOMBRE || ' ' || Ape1 || ' ' || Ape2 as NOMBREs ,
          pe.ID_ANO ,
        'AUSENCIA' AS TIPO,
        tr.DESC_tipo_AUSENCIA  as DESC_PER ,
        to_char(pe.FECHA_INICIO,'DD/mm/yyyy hh24:mi') as FECHA_INICIO ,
        to_char(pe.FECHA_FIN,'DD/mm/yyyy hh24:mi') as FECHA_FIN ,
        devuelve_min_fto_hora(TOTAL_HORAS)  AS Num_dias
from ausencia pe,tr_tipo_ausencia tr,personal_new p
where pe.id_ano>2017 and pe.id_estado=80 and pe.JUSTIFICADO='NO'
and tr.id_tipo_ausencia=pe.id_tipo_ausencia and
    pe.id_tipo_ausencia<500 and
    pe.id_tipo_ausencia<>'090' and
    pe.id_tipo_ausencia<>'105' and
    pe.id_funcionario=p.id_funcionario and
    pe.id_funcionario=v_id_funcionario and
    (
       ( to_DAte(to_char(pe.fecha_inicio,'dd/mm/yyyy'),'dd/mm/yyyy') between V_fecha_inicio and  v_fecha_fin ) OR
       ( to_DAte(to_char(pe.fecha_fin,'dd/mm/yyyy'),'dd/mm/yyyy') between V_fecha_inicio and  v_fecha_fin )
    )                                  and
    (pe.ANULADO='NO' OR pe.anulado is null);

--PERMISOS Y AUSENCIAS EN DIA
CURSOR INFORME_13(v_id_funcionario varchar2,v_fecha_inicio date,v_fecha_fin date) is
select distinct
        p.NOMBRE || ' ' || Ape1 || ' ' || Ape2 as NOMBREs ,
         pe.ID_ANO ,
          'PERMISO' AS TIPO ,
        tr.DESC_tipo_PERMISO  as DESC_PER ,
        to_char(pe.FECHA_INICIO,'DD/mm/yyyy') as FECHA_INICIO ,
        to_char(pe.FECHA_FIN,'DD/mm/yyyy') as FECHA_FIN ,
        to_char(pe.Num_dias) as NUM_DIAS
from permiso pe,tr_tipo_permiso tr,personal_new p
where  pe.id_ano> 2017 and pe.id_estado not in (30,31,32,40,41)
and tr.id_tipo_permiso=pe.id_tipo_permiso and
    tr.id_ano=pe.id_ano  and

    --pe.id_tipo_permiso<>'10000' and--curso
    pe.id_funcionario=p.id_funcionario and
    pe.id_funcionario=v_id_funcionario and
    (
       ( V_fecha_inicio  between to_DAte(to_char(pe.fecha_inicio,'dd/mm/yyyy'),'dd/mm/yyyy') and to_DAte(to_char(pe.fecha_fin,'dd/mm/yyyy'),'dd/mm/yyyy') ) OR
       ( v_fecha_fin between to_DAte(to_char(pe.fecha_inicio,'dd/mm/yyyy'),'dd/mm/yyyy') and to_DAte(to_char(pe.fecha_fin,'dd/mm/yyyy'),'dd/mm/yyyy')   )
    )  and
    (pe.ANULADO='NO' OR pe.anulado is null)

UNION
--Ausencias SIN JUSTIFICAR

  select
        p.NOMBRE || ' ' || Ape1 || ' ' || Ape2 as NOMBREs ,
          pe.ID_ANO ,
        'AUSENCIA' AS TIPO,
        tr.DESC_tipo_AUSENCIA  as DESC_PER ,
        to_char(pe.FECHA_INICIO,'DD/mm/yyyy hh24:mi') as FECHA_INICIO ,
        to_char(pe.FECHA_FIN,'DD/mm/yyyy hh24:mi') as FECHA_FIN ,
        devuelve_min_fto_hora(TOTAL_HORAS)  AS Num_dias
from ausencia pe,tr_tipo_ausencia tr,personal_new p
where pe.id_ano>2017 and pe.id_estado not in (30,31,32,40,41)
and tr.id_tipo_ausencia=pe.id_tipo_ausencia and

    pe.id_funcionario=p.id_funcionario and
    pe.id_funcionario=v_id_funcionario and
    (
       ( V_fecha_inicio  between to_DAte(to_char(pe.fecha_inicio,'dd/mm/yyyy'),'dd/mm/yyyy') and to_DAte(to_char(pe.fecha_fin,'dd/mm/yyyy'),'dd/mm/yyyy') ) OR
       ( v_fecha_fin between to_DAte(to_char(pe.fecha_inicio,'dd/mm/yyyy'),'dd/mm/yyyy') and to_DAte(to_char(pe.fecha_fin,'dd/mm/yyyy'),'dd/mm/yyyy') )
    )                                  and
    (pe.ANULADO='NO' OR pe.anulado is null);

--FICHAJES
 CURSOR INFORME_14(v_id_funcionario varchar2,v_fecha_inicio date,v_fecha_fin date) is
select v_id_funcionario,fecha_fichaje,
       ID_DIA,
       TO_CHAR(FECHA_FICHAJE,'DD/mm/yyyy') as FECHA,
       TO_CHAR(FECHA_FICHAJE,'hh24:mi') as HORA,
       DECODE(FECHA_FICHAJE,NULL,'SIN FICHAJE',DECODE(denom,null,'Manual',denom)) as OBSERVACIONES
 from fichaje_funcionario_tran t , relojes r ,calendario_laboral ca
 where  t.id_funcionario(+)=v_id_funcionario and
       valido(+)=1 and
       ca.id_dia between v_fecha_inicio and v_fecha_fin  and
       ca.id_dia=TO_DATE(TO_CHAR(FECHA_FICHAJE(+),'DD/mm/yyyy'),'DD/mm/yyyy') and
       to_char(reloj)=to_char(numero(+))
 order by ca.id_dia,FECHA_FICHAJE asc,HORA asc;

BEGIN

   --PARAMETROS DEL INFORME
   --PARA EL
   BEGIN
      select        ID_TIPO_INFORME,  FILTRO_1,  FILTRO_1_PARA,  FILTRO_2,  FILTRO_2_PARA
             into I_ID_TIPO_INFORME,I_FILTRO_1,I_FILTRO_1_PARA,I_FILTRO_2,I_FILTRO_2_PARA
      from fichaje_informe
      where id_secuencia_informe=V_ID_INFORME;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
            I_ID_TIPO_INFORME:=0;
   END;

  i_ejecucion:=sec_id_fichaje_ejec.nextval;
  n_col:= 0;

  ------------FILTRO FECHAS ------
  --I_FILTRO_2=A  -->I_FILTRO_2_PARA
  --I_FILTRO_2=P   -->I_FILTRO_2_PARA --DA sysdate-1, MA sysdate - MES, --PA periodo-1, I_FILTRO_2_PARA
  --I_FILTRO_2=M  ---> FI Devuelve valor  I_FILTRO_2_PARA,FF Devuelve valor  I_FILTRO_2_PARA
  --------------------------------

  V_FECHAS_FILTRO  :=devuelve_parametro_fecha(i_filtro_2 , i_filtro_2_para );
  V_FECHA_INICIO   :=to_date(devuelve_valor_campo(V_FECHAS_FILTRO ,'FI'),'dd/mm/yyyy');
  V_FECHA_FIN      :=to_date(devuelve_valor_campo(V_FECHAS_FILTRO ,'FF'),'dd/mm/yyyy');
  v_FECHA_EJECUCION:=to_date(to_char(sysdate,'dd/mm/yyyy hh24:mi'),'dd/mm/yyyy hh24:mi');

CASE I_ID_TIPO_INFORME
    WHEN 1 THEN
        --PERSONAS
        OPEN C1(I_FILTRO_1_PARA);
        LOOP
            FETCH C1
              into I_Id_funcionario,V_CODPERS,V_nombre,i_id_unidad,i_tipo_funcionario;
            EXIT WHEN C1%NOTFOUND;

              insert into fichaje_ejecucion_error
                 (fecha_ejecucion, id_funcionario, procedimiento)
                values
                 (sysdate,i_id_funcionario,'INFORME 1');


               --SALDO
               select round(sum(diferencia_minutos)) ,  round(sum(horas_fichadas_m)) ,
                      round(sum(horas_hacer_m))
                       into V_SALDO_TOTAL, i_horas_fichadas_m, i_horas_hacer_m
               from (
                       select distinct f,diferencia_minutos,horas_fichadas_m,horas_hacer_m
                       from  fichaje_saldo_completa_new t
                       where id_funcionario =I_Id_funcionario
                             and f between V_FECHA_INICIO and  V_FECHA_FIN
                             and (horas_fichadas_m <> 0 OR horas_hacer_m <> 0)) ;
                             --and nvl(observaciones,0) <> 'NO COMPUTA PARA SALDO.'); --quitado 26/

               V_FORMATO_campo:= devuelve_min_fto_hora(V_SALDO_TOTAL);
               V_FORMATO_campo_fichadas := devuelve_min_fto_hora(i_horas_fichadas_m);
               V_FORMATO_campo_hacer:= devuelve_min_fto_hora(i_horas_hacer_m);
               V_acumulado:=0;
               i_primer_fichaje_dia:=1;

               OPEN INFORME_1(I_Id_funcionario,V_FECHA_INICIO,V_FECHA_FIN);

                    LOOP
                      FETCH INFORME_1
                        into   F_txt,
                               V_f,
                               V_entrada,
                               V_salida,
                               V_horas_fichadas,
                               V_horas_fichadas_M,
                               V_horas_hacer,
                               V_horas_hacer_m,
                               V_diferencia_minutos,i_fuera_saldo,
                               v_observaciones;
                      EXIT WHEN INFORME_1%NOTFOUND;


                     n_col:= n_col+1;

                    /* --VIEJO*/
                     V_horas_fichadas_M:= substr( V_horas_fichadas,1,2)*60+ substr( V_horas_fichadas,4,2);
                     V_horas_hacer_m:=    substr( V_horas_hacer,1,2)*60+ substr( V_horas_hacer,4,2);

                     V_acumulado:=V_diferencia_minutos+ V_acumulado;
                     V_FORMATO_campo_acumu:=devuelve_min_fto_hora(V_acumulado);

                     --COMPROBAMOS QUE NO SEA LUNES DE AGUA O SANTA RITA
                     d_lunes_agua:= devuelve_lunes_agua(to_char(V_FECHA_INICIO,'yyyy'));
                     d_santa_rita:= to_Date('22/05/' ||to_char(V_FECHA_INICIO,'yyyy'),'dd/mm/yyyy');

                     --IF V_FECHA_INICIO = d_lunes_agua OR V_FECHA_INICIO =d_santa_rita THEN
                       BEGIN
                         select horas_hacer into V_horas_hacer_m
                             from fichaje_saldo_hacer
                         where id_dia=to_Date('25/04/2019','dd/mm/yyyy') and id_funcionario=I_Id_funcionario and rownum<2;
                         EXCEPTION
                          WHEN NO_DATA_FOUND THEN
                                    V_horas_hacer_m:= -15;
                        END;
                          --Añadido 28/04/2019. --cuente todo.
                          V_horas_fichadas_M:=  V_diferencia_minutos+i_fuera_saldo;


                          V_horas_hacer:=devuelve_min_fto_hora( V_horas_hacer_m );
                         IF  i_primer_fichaje_dia =1 then
                          V_diferencia_minutos:=nvl(V_horas_fichadas_M-V_horas_hacer_m,0);
                          i_primer_fichaje_dia:=0;
                         else
                           V_diferencia_minutos:=V_horas_fichadas_M;
                         end if;
                     --END IF;

                     insert into fichaje_informe_campo
                     (id_secuencia_informe, campo1, campo2, campo3, campo4, campo5, campo6, campo7, campo8, campo9, campo10, campo11, campo12, campo13, campo14, campo15, campo16, campo17, campo18, campo19, campo20
                     ,id_col,fecha_ejecucion,id_ejecucion,id_tipo_informe,campo31
                     )
                      values
                     (V_ID_INFORME,I_Id_funcionario, V_nombre, V_SALDO_TOTAL, F_txt,
                      V_entrada, V_salida, V_horas_fichadas, V_horas_fichadas_M,
                      V_horas_hacer, V_horas_hacer_m,  V_diferencia_minutos,
                       '' ,--v_campo12,
                       '',--v_campo13,
                       '',--v_campo14,
                        v_observaciones,
                         V_FORMATO_campo_acumu,--v_campo16, --SALDO ACUMULADO_EN DIAS
                        i_fuera_saldo,--v_campo17,
                        '',--v_campo18,
                        '',--v_campo19,
                        '',--v_campo20
                        n_col,v_FECHA_EJECUCION,i_ejecucion, I_ID_TIPO_INFORME,V_FORMATO_campo

                        --campo31
                        );

                     END LOOP;
                   CLOSE INFORME_1;
                  delete  fichaje_ejecucion_error where id_funcionario=i_id_funcionario and procedimiento='INFORME 1';

              END LOOP;
        CLOSE C1;

 WHEN 2 THEN
        --PERSONAS
        OPEN C1(I_FILTRO_1_PARA);
        LOOP
            FETCH C1
              into I_Id_funcionario,V_CODPERS,V_nombre,i_id_unidad,i_tipo_funcionario;
            EXIT WHEN C1%NOTFOUND;

            insert into fichaje_ejecucion_error
                 (fecha_ejecucion, id_funcionario, procedimiento)
                values
                 (sysdate,i_id_funcionario,'INFORME 2');

               --SALDO
               /*select round(sum(diferencia_minutos)) ,  round(sum(horas_fichadas_m)) ,
                      round(sum(horas_hacer_m))
                       into V_SALDO_TOTAL, i_horas_fichadas_m, i_horas_hacer_m
               from (
                       select distinct f,diferencia_minutos,horas_fichadas_m,horas_hacer_m
                       from FICHAJE_SALDO_COMPLETA_NEW t
                       where id_funcionario =I_Id_funcionario
                             and f between V_FECHA_INICIO and  V_FECHA_FIN
                             and (horas_fichadas_m <> 0 OR horas_hacer_m <> 0) and nvl(observaciones,0) <> 'NO COMPUTA PARA SALDO.');
                   */
               select round(sum(diferencia_minutos)) ,  round(sum(horas_fichadas_m)) ,
                      round(sum(horas_hacer_m))
                       into V_SALDO_TOTAL, i_horas_fichadas_m, i_horas_hacer_m
               from (
                       select distinct f,diferencia_minutos,horas_fichadas_m,horas_hacer_m
                       from  fichaje_saldo_completa_new t
                       where id_funcionario =I_Id_funcionario
                             and f between V_FECHA_INICIO and  V_FECHA_FIN
                             and (horas_fichadas_m <> 0 OR horas_hacer_m <> 0)) ;

               V_FORMATO_campo:= devuelve_min_fto_hora(V_SALDO_TOTAL);
               V_FORMATO_campo_fichadas := devuelve_min_fto_hora(i_horas_fichadas_m);
               V_FORMATO_campo_hacer:= devuelve_min_fto_hora(i_horas_hacer_m);
               V_acumulado:=0;

               n_col:= n_col+1;

                 insert into fichaje_informe_campo
                 (id_secuencia_informe, campo1, campo2, campo3,campo7, campo8, campo9, campo10,
                  id_col,fecha_ejecucion,id_ejecucion,id_tipo_informe,campo31
                 )
                  values
                 (V_ID_INFORME,I_Id_funcionario, V_nombre, V_SALDO_TOTAL,
                  V_FORMATO_campo_fichadas, i_horas_fichadas_m,
                  V_FORMATO_campo_hacer, i_horas_hacer_m,
                  n_col,v_FECHA_EJECUCION,i_ejecucion, I_ID_TIPO_INFORME,V_FORMATO_campo);

               delete  fichaje_ejecucion_error where id_funcionario=i_id_funcionario and procedimiento='INFORME 2';
             END LOOP;
        CLOSE C1;

   WHEN 3 THEN
         --PERSONAS
        OPEN C1(I_FILTRO_1_PARA);
        LOOP
            FETCH C1
              into I_Id_funcionario,V_CODPERS,V_nombre,i_id_unidad,i_tipo_funcionario;
            EXIT WHEN C1%NOTFOUND;


            insert into fichaje_ejecucion_error
                 (fecha_ejecucion, id_funcionario, procedimiento)
                values
                 (sysdate,i_id_funcionario,'INFORME 3');


               --SALDO
               /*select round(sum(diferencia_minutos)) ,  round(sum(horas_fichadas_m)) ,
                      round(sum(horas_hacer_m))
                       into V_SALDO_TOTAL, i_horas_fichadas_m, i_horas_hacer_m
               from (
                       select distinct f,diferencia_minutos,horas_fichadas_m,horas_hacer_m
                       from FICHAJE_SALDO_COMPLETA_NEW t
                       where id_funcionario =I_Id_funcionario
                             and f between V_FECHA_INICIO and  V_FECHA_FIN
                             and (horas_fichadas_m <> 0 OR horas_hacer_m <> 0) and nvl(observaciones,0) <> 'NO COMPUTA PARA SALDO.');
*/

               select round(sum(diferencia_minutos)) ,  round(sum(horas_fichadas_m)) ,
                      round(sum(horas_hacer_m))
                       into V_SALDO_TOTAL, i_horas_fichadas_m, i_horas_hacer_m
               from (
                       select distinct f,diferencia_minutos,horas_fichadas_m,horas_hacer_m
                       from  fichaje_saldo_completa_new t
                       where id_funcionario =I_Id_funcionario
                             and f between V_FECHA_INICIO and  V_FECHA_FIN
                             and (horas_fichadas_m <> 0 OR horas_hacer_m <> 0)) ;

               V_FORMATO_campo:= devuelve_min_fto_hora(V_SALDO_TOTAL);
               V_FORMATO_campo_fichadas := devuelve_min_fto_hora(i_horas_fichadas_m);
               V_FORMATO_campo_hacer:= devuelve_min_fto_hora(i_horas_hacer_m);
               V_acumulado:=0;


             IF   (i_TIPO_FUNCIONARIO<>21 AND i_TIPO_FUNCIONARIO<>23) and
                   permiso_en_dia(I_Id_funcionario, V_FECHA_INICIO)=0
                   THEN   --   lunes de Agua/santa rita

                   select  round(sum(horas_fichadas_m))
                       into  i_horas_fichadas_m
                     from (
                    select distinct f,diferencia_minutos,horas_fichadas_m,horas_hacer_m
                      --from FICHAJE_SALDO_COMPLETA_NEW t
                      from  fichaje_saldo_completa_new t
                     where id_funcionario =I_Id_funcionario
                           and f between V_FECHA_INICIO and  V_FECHA_FIN
                       and (horas_fichadas_m <> 0 OR horas_hacer_m <> 0));

                       n_col:= n_col+1;

                  --i_horas_hacer_m es
                 select min(horas_hacer)
                 into i_horas_hacer_m
                from fichaje_saldo_hacer  fh
                where fh.id_funcionario=I_Id_funcionario and
                      id_dia between to_date('01/01/' || to_char(sysdate,'yyyy'),'dd/mm/yyyy') and
                             to_date('31/12/' || to_char(sysdate,'yyyy'),'dd/mm/yyyy')  and
                     horas_hacer >0
                     order by 1;

                 V_SALDO_TOTAL:=i_horas_fichadas_m-i_horas_hacer_m;
                 V_FORMATO_campo:= devuelve_min_fto_hora(V_SALDO_TOTAL);
                 V_FORMATO_campo_fichadas := devuelve_min_fto_hora(i_horas_fichadas_m);
                 V_FORMATO_campo_hacer:= devuelve_min_fto_hora(i_horas_hacer_m);

                 insert into fichaje_informe_campo
                 (id_secuencia_informe, campo1, campo2, campo3,campo7, campo8, campo9, campo10,
                   id_col,fecha_ejecucion,id_ejecucion,id_tipo_informe,campo31
                 )
                          values
                 (V_ID_INFORME,I_Id_funcionario, V_nombre, V_SALDO_TOTAL,
                  V_FORMATO_campo_fichadas, i_horas_fichadas_m,
                  V_FORMATO_campo_hacer, i_horas_hacer_m,
                    n_col,v_FECHA_EJECUCION,i_ejecucion, I_ID_TIPO_INFORME,V_FORMATO_campo);

              END IF;

               delete  fichaje_ejecucion_error where id_funcionario=i_id_funcionario and procedimiento='INFORME 3';
            END LOOP;
        CLOSE C1;

     WHEN 4 THEN
         --PERSONAS
         OPEN C1(I_FILTRO_1_PARA);
         LOOP
            FETCH C1
              into I_Id_funcionario,V_CODPERS,V_nombre,i_id_unidad,i_tipo_funcionario;
            EXIT WHEN C1%NOTFOUND;


                insert into fichaje_ejecucion_error
                 (fecha_ejecucion, id_funcionario, procedimiento)
                values
                 (sysdate,i_id_funcionario,'INFORME 4');

               --SALDO
               /*select round(sum(diferencia_minutos)) ,  round(sum(horas_fichadas_m)) ,
                      round(sum(horas_hacer_m))
                       into V_SALDO_TOTAL, i_horas_fichadas_m, i_horas_hacer_m
               from (
                       select distinct f,diferencia_minutos,horas_fichadas_m,horas_hacer_m
                       from FICHAJE_SALDO_COMPLETA_NEW t
                       where id_funcionario =I_Id_funcionario
                             and f between V_FECHA_INICIO and  V_FECHA_FIN
                             and (horas_fichadas_m <> 0 OR horas_hacer_m <> 0) and nvl(observaciones,0) <> 'NO COMPUTA PARA SALDO.');
               */
                select round(sum(diferencia_minutos)) ,  round(sum(horas_fichadas_m)) ,
                      round(sum(horas_hacer_m))
                       into V_SALDO_TOTAL, i_horas_fichadas_m, i_horas_hacer_m
               from (
                       select distinct f,diferencia_minutos,horas_fichadas_m,horas_hacer_m
                       from  fichaje_saldo_completa_new t
                       where id_funcionario =I_Id_funcionario
                             and f between V_FECHA_INICIO and  V_FECHA_FIN
                             and (horas_fichadas_m <> 0 OR horas_hacer_m <> 0)) ;

               V_FORMATO_campo:= devuelve_min_fto_hora(V_SALDO_TOTAL);
               V_FORMATO_campo_fichadas := devuelve_min_fto_hora(i_horas_fichadas_m);
               V_FORMATO_campo_hacer:= devuelve_min_fto_hora(i_horas_hacer_m);
               V_acumulado:=0;

                n_col:= n_col+1;

                OPEN INFORME_4(I_Id_funcionario,V_FECHA_INICIO,V_FECHA_FIN);

                          LOOP
                            FETCH INFORME_4
                              into
                                     V_desc_calendario,
                                     i_HORAS_SEMANALES,
                                     v_turno,
                                     vf_fecha_inicio,
                                     vf_fecha_fin,
                                     i_reduccion,
                                     vf_horas_jornada,
                                     i_dias,
                                     v_contar_comida,
                                     v_libre,
                                     v_bolsa,T_fecha_inicio;
                            EXIT WHEN INFORME_4%NOTFOUND;

                            n_col:= n_col+1;


                          insert into fichaje_informe_campo
                           (id_secuencia_informe, campo1, campo2, campo3, campo4,
                            campo5, campo6,campo7, campo8, campo9,
                            campo10, campo11,campo12, campo13, campo14,campo15,
                            campo16, campo17,campo18, campo19, campo20
                             ,id_col,fecha_ejecucion,id_ejecucion,id_tipo_informe,campo31
                                 )
                                  values
                             (V_ID_INFORME,I_Id_funcionario, V_nombre, '', vf_horas_jornada,
                               vf_fecha_inicio, vf_fecha_fin, '', i_reduccion,V_desc_calendario,
                               v_turno,   v_libre,
                                  v_contar_comida ,--v_campo12,
                                  v_bolsa,--v_campo13,
                                   '',--v_campo14,
                                   '',
                                     '',--v_campo16, --SALDO ACUMULADO_EN DIAS
                                    '',--v_campo17,
                                    '',--v_campo18,
                                    '',--v_campo19,
                                    '',--v_campo20
                                    n_col,v_FECHA_EJECUCION,i_ejecucion, I_ID_TIPO_INFORME,
                                   ''

                                    --campo31
                                    );


                         END LOOP;
                     CLOSE INFORME_4;
                     delete  fichaje_ejecucion_error where id_funcionario=i_id_funcionario and procedimiento='INFORME 4';
               END LOOP;
        CLOSE C1;
   WHEN 5 THEN
         OPEN INFORME_5(V_FECHA_INICIO,V_FECHA_FIN);

              LOOP
                FETCH INFORME_5
                  into   i_id_funcionario,
                       f_txt,
                       V_f,
                       i_turno,
                       V_TURNO,
                       V_nombre,V_entrada,V_salida;
               EXIT WHEN INFORME_5%NOTFOUND;
                   insert into fichaje_ejecucion_error
                 (fecha_ejecucion, id_funcionario, procedimiento)
                values
                 (sysdate,i_id_funcionario,'INFORME 5');

                n_col:= n_col+1;

           insert into fichaje_informe_campo
               (id_secuencia_informe, campo1, campo2, campo3, campo4, campo5, campo6,
                id_col,fecha_ejecucion,id_ejecucion,id_tipo_informe
               )
                values
               (V_ID_INFORME,F_TXT,V_TURNO, V_nombre, i_id_funcionario,V_entrada,V_salida,
                 n_col,v_FECHA_EJECUCION,i_ejecucion, I_ID_TIPO_INFORME);

                 delete  fichaje_ejecucion_error where id_funcionario=i_id_funcionario and procedimiento='INFORME 5';
                END LOOP;
               CLOSE INFORME_5;
   WHEN 6 THEN
        OPEN INFORME_6(V_FECHA_INICIO,V_FECHA_FIN);

              LOOP
                FETCH INFORME_6
                  into   i_id_funcionario,
                         V_nombre,
                         V_entrada,
                         V_salida;
               EXIT WHEN INFORME_6%NOTFOUND;

                   insert into fichaje_ejecucion_error
                 (fecha_ejecucion, id_funcionario, procedimiento)
                values
                 (sysdate,i_id_funcionario,'INFORME 6');


               n_col:= n_col+1;

               insert into fichaje_informe_campo
               (id_secuencia_informe,  campo3, campo4, campo5, campo6,
                id_col,fecha_ejecucion,id_ejecucion,id_tipo_informe
               )
                values
               (V_ID_INFORME, V_nombre, i_id_funcionario,V_entrada,V_salida,
                 n_col,v_FECHA_EJECUCION,i_ejecucion, I_ID_TIPO_INFORME);
                   delete  fichaje_ejecucion_error where id_funcionario=i_id_funcionario and procedimiento='INFORME 6';
                END LOOP;
      CLOSE INFORME_6;
   WHEN 7 THEN
       OPEN C1(I_FILTRO_1_PARA);
        LOOP
            FETCH C1
              into I_Id_funcionario,V_CODPERS,V_nombre,i_id_unidad,i_tipo_funcionario;
            EXIT WHEN C1%NOTFOUND;

                 insert into fichaje_ejecucion_error
                 (fecha_ejecucion, id_funcionario, procedimiento)
                values
                 (sysdate,i_id_funcionario,'INFORME 7');

            OPEN INFORME_7(I_Id_funcionario,V_FECHA_INICIO);

                  LOOP
                    FETCH INFORME_7
                      into   i_id_funcionario,
                             V_nombre,
                              v_horas_hacer,
                              v_horas_saldo,
                              n_bajas,
                              n_permisos,
                              v_horas_ausencia,
                              v_horas_compensadas,
                              v_horas_extras_reali,
                              v_horas_extras_pagadas,
                              v_horas_extras_comp,
                              v_horas_sindicales,
                              n_dias_trabajos,
                              n_festivo,
                              n_domingo,
                              n_sabado,
                              n_turno_m,
                              n_turno_t,
                              n_turno_n,
                              n_descuento_prod ,v_BOLSA_SALDO, v_BOLSA_UTIL;

                   EXIT WHEN INFORME_7%NOTFOUND;

                   n_col:= n_col+1;

                   insert into fichaje_informe_campo
                   (id_secuencia_informe, campo1, campo2, campo3, campo4, campo5, campo6, campo7, campo8, campo9, campo10, campo11, campo12, campo13, campo14, campo15, campo16, campo17, campo18, campo19, campo20,
                    campo21,campo22,
                    id_col,fecha_ejecucion,id_ejecucion,id_tipo_informe
                   )
                    values
                   (V_ID_INFORME, i_id_funcionario, V_nombre,
                             v_horas_hacer,
                              v_horas_saldo,
                              v_BOLSA_SALDO, v_BOLSA_UTIL,
                              n_dias_trabajos,
                               n_festivo,
                              n_domingo,
                              n_sabado,
                              n_bajas,
                              n_permisos,
                              n_descuento_prod ,
                              v_horas_ausencia,
                              v_horas_compensadas,
                              v_horas_extras_reali,
                              v_horas_extras_pagadas,
                              v_horas_extras_comp,
                              v_horas_sindicales,


                              n_turno_m,
                              n_turno_t,
                              n_turno_n,

                     n_col,v_FECHA_EJECUCION,i_ejecucion, I_ID_TIPO_INFORME);


                    END LOOP;
          CLOSE INFORME_7;
             delete  fichaje_ejecucion_error where id_funcionario=i_id_funcionario and procedimiento='INFORME 7';
       END LOOP;
       CLOSE c1;
  WHEN 8 THEN
       OPEN C1(I_FILTRO_1_PARA);
        LOOP
            FETCH C1
              into I_Id_funcionario,V_CODPERS,V_nombre,i_id_unidad,i_tipo_funcionario;
            EXIT WHEN C1%NOTFOUND;

                 insert into fichaje_ejecucion_error
                 (fecha_ejecucion, id_funcionario, procedimiento)
                values
                 (sysdate,i_id_funcionario,'INFORME 8');

            OPEN INFORME_8(I_Id_funcionario,V_FECHA_INICIO,V_FECHA_FIN);

                  LOOP
                    FETCH INFORME_8
                      into   V_TIPO_INCIDENCIAS,
                             V_nombre,
                             v_fecha_incidencia,
                             v_observaciones;

                   EXIT WHEN INFORME_8%NOTFOUND;

                   n_col:= n_col+1;

                   insert into fichaje_informe_campo
                   (id_secuencia_informe, campo1, campo2, campo3, campo4,CAMPO5,
                    id_col,fecha_ejecucion,id_ejecucion,id_tipo_informe
                   )
                    values
                   (V_ID_INFORME, i_id_funcionario, V_nombre,
                             V_TIPO_INCIDENCIAS,
                             v_fecha_incidencia,
                            v_observaciones,

                     n_col,v_FECHA_EJECUCION,i_ejecucion, I_ID_TIPO_INFORME);


                    END LOOP;
          CLOSE INFORME_8;
             delete  fichaje_ejecucion_error where id_funcionario=i_id_funcionario and procedimiento='INFORME 8';
       END LOOP;
       CLOSE c1;
WHEN 11 THEN
       OPEN C1(I_FILTRO_1_PARA);
        LOOP
            FETCH C1
              into I_Id_funcionario,V_CODPERS,V_nombre,i_id_unidad,i_tipo_funcionario;
            EXIT WHEN C1%NOTFOUND;

                 insert into fichaje_ejecucion_error
                 (fecha_ejecucion, id_funcionario, procedimiento)
                values
                 (sysdate,i_id_funcionario,'INFORME 11');

            OPEN INFORME_11(I_Id_funcionario,V_FECHA_INICIO);

                  LOOP
                    FETCH INFORME_11
                      into   i_id_funcionario,
                             V_nombre,
                               i_total,i_total_numero,
                                 i_p2,
                                 i_p3,
                                 i_p4,
                                 i_p5,
                                 i_p6,
                                 i_p7,
                                 i_p8,
                                 i_p9,
                                 i_p10,
                                 i_p11,
                                 i_p12,
                                i_p13;
                   EXIT WHEN INFORME_11%NOTFOUND;

                   n_col:= n_col+1;

                   insert into fichaje_informe_campo
                   (id_secuencia_informe, campo1, campo2, campo3, campo4, campo5, campo6, campo7, campo8, campo9, campo10, campo11, campo12, campo13, campo14, campo15,
                    campo16,
                    id_col,fecha_ejecucion,id_ejecucion,id_tipo_informe
                   )
                    values
                   (V_ID_INFORME, i_id_funcionario, V_nombre,
                             i_total,
                                 i_p2,
                                 i_p3,
                                 i_p4,
                                 i_p5,
                                 i_p6,
                                 i_p7,
                                 i_p8,
                                 i_p9,
                                 i_p10,
                                 i_p11,
                                 i_p12,
                                i_p13,   i_total_numero   ,

                     n_col,v_FECHA_EJECUCION,i_ejecucion, I_ID_TIPO_INFORME);


                    END LOOP;
          CLOSE INFORME_11;
             delete  fichaje_ejecucion_error where id_funcionario=i_id_funcionario and procedimiento='INFORME 11';
       END LOOP;
       CLOSE c1;
 WHEN 12 THEN
       OPEN C1(I_FILTRO_1_PARA);
        LOOP
            FETCH C1
              into I_Id_funcionario,V_CODPERS,V_nombre,i_id_unidad,i_tipo_funcionario;
            EXIT WHEN C1%NOTFOUND;

                 insert into fichaje_ejecucion_error
                 (fecha_ejecucion, id_funcionario, procedimiento)
                values
                 (sysdate,i_id_funcionario,'INFORME 12');

            OPEN INFORME_12(I_Id_funcionario,V_FECHA_INICIO,V_FECHA_FIN);

                  LOOP
                    FETCH INFORME_12
                      into   V_nombre,
                             V_ID_ANO_p    ,
                              V_TIPO_P      ,
                              V_DESC_PER     ,
                              V_FECHA_INICIO_P,
                              V_FECHA_FIN_P  ,
                              V_NUM_DIAS_p;
                   EXIT WHEN INFORME_12%NOTFOUND;

                   n_col:= n_col+1;

                   insert into fichaje_informe_campo
                   (id_secuencia_informe, campo1, campo2, campo3, campo4,CAMPO5,CAMPO6,CAMPO7,CAMPO8,
                    id_col,fecha_ejecucion,id_ejecucion,id_tipo_informe
                   )
                    values
                   (V_ID_INFORME, i_id_funcionario, V_nombre,
                            V_ID_ANO_p    ,
                              V_TIPO_P      ,
                              V_DESC_PER     ,
                              V_FECHA_INICIO_P,
                              V_FECHA_FIN_P  ,
                               V_NUM_DIAS_p     ,
                     n_col,v_FECHA_EJECUCION,i_ejecucion, I_ID_TIPO_INFORME);


                    END LOOP;
          CLOSE INFORME_12;
             delete  fichaje_ejecucion_error where id_funcionario=i_id_funcionario and procedimiento='INFORME 12';
       END LOOP;
       CLOSE c1;
  WHEN 13 THEN
       OPEN C1(I_FILTRO_1_PARA);
        LOOP
            FETCH C1
              into I_Id_funcionario,V_CODPERS,V_nombre,i_id_unidad,i_tipo_funcionario;
            EXIT WHEN C1%NOTFOUND;

                 insert into fichaje_ejecucion_error
                 (fecha_ejecucion, id_funcionario, procedimiento)
                values
                 (sysdate,i_id_funcionario,'INFORME 13');

            OPEN INFORME_13(I_Id_funcionario,V_FECHA_INICIO,V_FECHA_FIN);

                  LOOP
                    FETCH INFORME_13
                      into   V_nombre,
                             V_ID_ANO_p    ,
                              V_TIPO_P      ,
                              V_DESC_PER     ,
                              V_FECHA_INICIO_P,
                              V_FECHA_FIN_P  ,
                              V_NUM_DIAS_p;
                   EXIT WHEN INFORME_13%NOTFOUND;

                   n_col:= n_col+1;

                   insert into fichaje_informe_campo
                   (id_secuencia_informe, campo1, campo2, campo3, campo4,CAMPO5,CAMPO6,CAMPO7,CAMPO8,
                    id_col,fecha_ejecucion,id_ejecucion,id_tipo_informe
                   )
                    values
                   (V_ID_INFORME, i_id_funcionario, V_nombre,
                            V_ID_ANO_p    ,
                              V_TIPO_P      ,
                              V_DESC_PER     ,
                              V_FECHA_INICIO_P,
                              V_FECHA_FIN_P  ,
                               V_NUM_DIAS_p     ,
                     n_col,v_FECHA_EJECUCION,i_ejecucion, I_ID_TIPO_INFORME);


                    END LOOP;
          CLOSE INFORME_13;
             delete  fichaje_ejecucion_error where id_funcionario=i_id_funcionario and procedimiento='INFORME 13';
       END LOOP;
       CLOSE c1;
  WHEN 14 THEN
       OPEN C1(I_FILTRO_1_PARA);
        LOOP
            FETCH C1
              into I_Id_funcionario,V_CODPERS,V_nombre,i_id_unidad,i_tipo_funcionario;
            EXIT WHEN C1%NOTFOUND;

                 insert into fichaje_ejecucion_error
                 (fecha_ejecucion, id_funcionario, procedimiento)
                values
                 (sysdate,i_id_funcionario,'INFORME 14');

            BEGIN
                  select id_funcionario
                  into i_id_funcionario
                  from funcionario_fichaje
                  where id_tipo_fichaje<>9 and
                        id_funcionario=I_Id_funcionario and rownum<2;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   i_id_funcionario :=0;
            END;


          IF  i_id_funcionario<> 0 and i_tipo_funcionario<>21 THEN
            OPEN INFORME_14(I_Id_funcionario,V_FECHA_INICIO,V_FECHA_FIN);

                  LOOP
                    FETCH INFORME_14
                      into  i_id_funcionario,v_fecha_fichaje_ord,v_id_dia,v_fecha_fichaje,V_hora,v_observaciones;
                   EXIT WHEN INFORME_14%NOTFOUND;

                   n_col:= n_col+1;
                       v_observa :='';
                     BEGIN
                      SELECT DISTINCT
                        '<a href="../Permisos/ver.jsp?ID_PERMISO=' ||
                        ID_PERMISO || '" >' ||
                        substr(DESC_TIPO_PERMISO, 1, 35) || '</a>  '|| 'Justificado:' || a.Justificacion  AS observaciones
                     into v_observa
                     FROM RRHH.PERMISO         A,               RRHH.TR_TIPO_PERMISO B
                     WHERE a.id_tipo_permiso = b.id_tipo_permiso   and
                           a.id_ano = b.id_ano   and rownum<2 and
                           a.id_funcionario=I_Id_funcionario   and a.id_estado not in ('30', '31', '32', '40', '41') And
                           ANULADO = 'NO'  AND
                           (
                                  ( V_fecha_inicio  between to_DAte(to_char(a.fecha_inicio,'dd/mm/yyyy'),'dd/mm/yyyy') and to_DAte(to_char(a.fecha_fin,'dd/mm/yyyy'),'dd/mm/yyyy') ) OR
                                  ( v_fecha_fin between to_DAte(to_char(a.fecha_inicio,'dd/mm/yyyy'),'dd/mm/yyyy') and to_DAte(to_char(a.fecha_fin,'dd/mm/yyyy'),'dd/mm/yyyy')   )
                            );
                    EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                            v_observa :='';
                    END;
                  v_observa_aus :='';
                     BEGIN
                        SELECT
                            '<a href="../Ausencias/ver.jsp?ID_AUSENCIA=' || ID_AUSENCIA ||
                            '" >' || substr(DESC_TIPO_AUSENCIA, 1, 35) || '</a>' || ' Justificada:' || JUSTIFICADO AS observaciones
                            into v_observa_aus
                        FROM RRHH.ausencia         A,
                             RRHH.TR_TIPO_ausencia B
                        WHERE
                             a.id_tipo_ausencia = b.id_tipo_ausencia
                        and  a.id_funcionario=I_Id_funcionario      and rownum<2
                        and a.id_estado not in ('30', '31', '32', '40', '41') and
                        (
                        ( V_fecha_inicio  between to_DAte(to_char(a.fecha_inicio,'dd/mm/yyyy'),'dd/mm/yyyy') and to_DAte(to_char(a.fecha_fin,'dd/mm/yyyy'),'dd/mm/yyyy') ) OR
                        ( v_fecha_fin between to_DAte(to_char(a.fecha_inicio,'dd/mm/yyyy'),'dd/mm/yyyy') and to_DAte(to_char(a.fecha_fin,'dd/mm/yyyy'),'dd/mm/yyyy')   )
                        )
                        And (ANULADO = 'NO' OR ANULADO IS NULL);
                        EXCEPTION
                       WHEN NO_DATA_FOUND THEN
                            v_observa_aus :='';
                            END;


                   insert into fichaje_informe_campo
                   (id_secuencia_informe, campo1, campo2, campo3, campo4,CAMPO5,
                    id_col,fecha_ejecucion,id_ejecucion,id_tipo_informe
                   )
                    values
                   (V_ID_INFORME, i_id_funcionario, V_nombre,
                            v_id_dia   ,
                              V_hora    ,
                            DECODE(v_observa ,null,  DECODE (v_observa_aus,null,v_observaciones,v_observa_aus),v_observa),

                     n_col,v_FECHA_EJECUCION,i_ejecucion, I_ID_TIPO_INFORME);


            END LOOP;
            CLOSE INFORME_14;
         END IF;


             delete  fichaje_ejecucion_error where id_funcionario=i_id_funcionario and procedimiento='INFORME 14';
       END LOOP;
       CLOSE c1;

END CASE;


      UPDATE fichaje_informe
      SET FECHA_ULT_EJEC=v_FECHA_EJECUCION,
          VALIDO=1,id_ejecucion=i_ejecucion
      where id_secuencia_informe=V_ID_INFORME;

commit;
END FINGER_GENERA_INFORME;
/

