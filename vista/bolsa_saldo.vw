create or replace force view rrhh.bolsa_saldo as
select distinct B.id_funcionario,DESC_MOTIVO_ACUMULAR,ACUMULADOR,b.periodo,
   trunc(saldo_periodo/60) as horas_excesos,
      mod(saldo_periodo,60) as   horas_minutos,
       b.id_ano
  from bolsa_saldo_periodo b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
       b.periodo=bm.periodo(+) and
        bm.anulado(+)=0 and
       b.id_acumulador=t.id_acumulador
   and b.id_ano = bm.id_ano(+);

