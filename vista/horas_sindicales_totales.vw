create or replace force view rrhh.horas_sindicales_totales as
(
select nvl(SUM(ENERO_TOTAL),0) as E_TOTAL,
         nvl(SUM(ENERO_UTILIZADAS),0) as E_UTILIZADAS,
          nvl(SUM(FEBRERO_TOTAL),0) as F_TOTAL,
         nvl(SUM(FEBRERO_UTILIZADAS),0) as F_UTILIZADAS,
         nvl( SUM(MARZO_TOTAL),0) as M_TOTAL,
        nvl( SUM(MARZO_UTILIZADAS),0) as M_UTILIZADAS,
         nvl( SUM(ABRIL_TOTAL),0) as A_TOTAL,
        nvl( SUM(ABRIL_UTILIZADAS),0) as A_UTILIZADAS,
        nvl(  SUM(MAYO_TOTAL),0) as MA_TOTAL,
        nvl( SUM(MAYO_UTILIZADAS),0) as ma_UTILIZADAS,

        nvl( SUM(JUNIO_UTILIZADAS),0) as J_UTILIZADAS,
        nvl(   SUM(JUNIO_TOTAL),0) as J_TOTAL,
         nvl(SUM(JULIO_UTILIZADAS),0) as JU_UTILIZADAS,
         nvl(  SUM(JULIO_TOTAL),0) as JU_TOTAL,
        nvl( SUM(AGOSTO_UTILIZADAS),0) as AG_UTILIZADAS,
         nvl(  SUM(AGOSTO_TOTAL),0) as AG_TOTAL,
        nvl( SUM(SEPTIEMBRE_UTILIZADAS),0) as S_UTILIZADAS,
        nvl(   SUM(SEPTIEMBRE_TOTAL),0) as S_TOTAL,
       nvl(  SUM(NOVIEMBRE_UTILIZADAS),0) as N_UTILIZADAS,
         nvl(  SUM(NOVIEMBRE_TOTAL),0) as N_TOTAL,
        nvl( SUM(OCTUBRE_UTILIZADAS),0) as O_UTILIZADAS,
         nvl(  SUM(OCTUBRE_TOTAL),0) as O_TOTAL,
        nvl( SUM(DICIEMBRE_UTILIZADAS),0) as D_UTILIZADAS,
        nvl(   SUM(DICIEMBRE_TOTAL),0) as D_TOTAL,

        id_funcionario,id_tipo_ausencia,id_ano  from (
select





 DECODE(id_mes,1,total_horas,0) as ENERO_TOTAL,
 DECODE(id_mes,1,total_utilizadas,0) as ENERO_UTILIZADAS,

 DECODE(id_mes,2,total_horas,0) as FEBRERO_TOTAL,
 DECODE(id_mes,2,total_utilizadas,0) as FEBRERO_UTILIZADAS,

 DECODE(id_mes,3,total_horas,0) as MARZO_TOTAL,
 DECODE(id_mes,3,total_utilizadas,0) as MARZO_UTILIZADAS,

 DECODE(id_mes,4,total_horas,0) as abril_TOTAL,
 DECODE(id_mes,4,total_utilizadas,0) as abril_UTILIZADAS,

 DECODE(id_mes,5,total_horas,0) as MAYO_TOTAL,
 DECODE(id_mes,5,total_utilizadas,0) as MAYO_UTILIZADAS,

 DECODE(id_mes,6,total_horas,0) as JUNIO_TOTAL,
 DECODE(id_mes,6,total_utilizadas,0) as JUNIO_UTILIZADAS,

 DECODE(id_mes,7,total_horas,0) as JULIO_TOTAL,
 DECODE(id_mes,7,total_utilizadas,0) as JULIO_UTILIZADAS,

 DECODE(id_mes,8,total_horas,0) as AGOSTO_TOTAL,
 DECODE(id_mes,8,total_utilizadas,0) as AGOSTO_UTILIZADAS,

 DECODE(id_mes,9,total_horas,0) as SEPTIEMBRE_TOTAL,
 DECODE(id_mes,9,total_utilizadas,0) as SEPTIEMBRE_UTILIZADAS,

 DECODE(id_mes,10,total_horas,0) as OCTUBRE_TOTAL,
 DECODE(id_mes,10,total_utilizadas,0) as OCTUBRE_UTILIZADAS,

 DECODE(id_mes,11,total_horas,0) as NOVIEMBRE_TOTAL,
 DECODE(id_mes,11,total_utilizadas,0) as NOVIEMBRE_UTILIZADAS,

  DECODE(id_mes,12,total_horas,0) as DICIEMBRE_TOTAL,
 DECODE(id_mes,12,total_utilizadas,0) as DICIEMBRE_UTILIZADAS,


id_funcionario,id_tipo_ausencia,id_ano from hora_sindical
)
group by id_funcionario,id_tipo_ausencia,id_ano);

