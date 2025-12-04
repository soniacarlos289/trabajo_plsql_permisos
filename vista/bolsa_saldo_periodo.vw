create or replace force view rrhh.bolsa_saldo_periodo as
(
select id_funcionario, id_ano,periodo, tope_horas,ID_ACUMULADOR,

        sum(penal_enero)+
        sum(penal_febrero)       +
        sum(penal_marzo)+
        sum(penal_abril)+
        sum(penal_mayo) +
        sum(penal_junio) +
        sum(penal_julio) +
        sum(penal_agosto) +
        sum(penal_septiembre) +
        sum(penal_octubre) +
        sum(penal_noviembre) +
        sum(penal_diciembre) +
        sum(penal_enero_mas)  as saldo_periodo from (

select b.id_funcionario, b.id_ano,bm.periodo, tope_horas,b.ID_ACUMULADOR,
       sum(DECODE(PERIODO,1,DECODE(penal_enero,0, exceso_en_horas * 60 + Excesos_en_minutos,
             DECODE(sign(Excesos_en_minutos),-1,exceso_en_horas * 60 + Excesos_en_minutos,DECODE(sign(exceso_en_horas),-1,  exceso_en_horas * 60 + Excesos_en_minutos,0))),0)) as penal_enero,
       0 as penal_febrero,
       0 as penal_marzo,
       0 as penal_abril,
       0 as penal_mayo,
       0 as penal_junio,
       0 as penal_julio,
       0 as penal_agosto,
       0 as penal_septiembre,
       0 as penal_octubre,
       0 as penal_noviembre,
       0 as penal_diciembre,
       0 as penal_enero_mas
  from bolsa_funcionario b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
         bm.anulado(+)=0 and
       b.ID_ACUMULADOR=t.ID_ACUMULADOR
   and b.id_ano = bm.id_ano(+)
 group by  b.id_ano,bm.periodo,B.id_funcionario, tope_horas,b.ID_ACUMULADOR

union
select b.id_funcionario, b.id_ano,bm.periodo,tope_horas,b.ID_ACUMULADOR,
       0 as penal_enero,
       sum(DECODE(PERIODO,2,DECODE(penal_febrero,0, exceso_en_horas * 60 + Excesos_en_minutos,
             DECODE(sign(Excesos_en_minutos),-1,exceso_en_horas * 60 + Excesos_en_minutos,DECODE(sign(exceso_en_horas),-1,  exceso_en_horas * 60 + Excesos_en_minutos,0))),0))  as penal_febrero,
       0 as penal_marzo,
       0 as penal_abril,
       0 as penal_mayo,
       0 as penal_junio,
       0 as penal_julio,
       0 as penal_agosto,
       0 as penal_septiembre,
       0 as penal_octubre,
       0 as penal_noviembre,
       0 as penal_diciembre,
       0 as penal_enero_mas
  from bolsa_funcionario b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
    bm.anulado(+)=0 and
       b.ID_ACUMULADOR=t.ID_ACUMULADOR
   and b.id_ano = bm.id_ano(+)
 group by  b.id_ano,bm.periodo,B.id_funcionario ,tope_horas,b.ID_ACUMULADOR
union
select b.id_funcionario, b.id_ano,bm.periodo,tope_horas,b.ID_ACUMULADOR,
       0 as penal_enero,
       0  as penal_febrero,
        sum(DECODE(PERIODO,3,DECODE(penal_marzo,0, exceso_en_horas * 60 + Excesos_en_minutos,
             DECODE(sign(Excesos_en_minutos),-1,exceso_en_horas * 60 + Excesos_en_minutos,DECODE(sign(exceso_en_horas),-1,  exceso_en_horas * 60 + Excesos_en_minutos,0))),0)) as penal_marzo,
       0 as penal_abril,
       0 as penal_mayo,
       0 as penal_junio,
       0 as penal_julio,
       0 as penal_agosto,
       0 as penal_septiembre,
       0 as penal_octubre,
       0 as penal_noviembre,
       0 as penal_diciembre,
       0 as penal_enero_mas
  from bolsa_funcionario b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
   bm.anulado(+)=0 and
       b.ID_ACUMULADOR=t.ID_ACUMULADOR
   and b.id_ano = bm.id_ano(+)
 group by  b.id_ano,bm.periodo,B.id_funcionario,tope_horas,b.ID_ACUMULADOR
union
select b.id_funcionario, b.id_ano,bm.periodo,tope_horas,b.ID_ACUMULADOR,
       0 as penal_enero,
       0  as penal_febrero,
       0 as penal_marzo,
        sum(DECODE(PERIODO,4,DECODE(penal_abril,0, exceso_en_horas * 60 + Excesos_en_minutos,
             DECODE(sign(Excesos_en_minutos),-1,exceso_en_horas * 60 + Excesos_en_minutos,DECODE(sign(exceso_en_horas),-1,  exceso_en_horas * 60 + Excesos_en_minutos,0))),0)) as penal_abril,
       0 as penal_mayo,
       0 as penal_junio,
       0 as penal_julio,
       0 as penal_agosto,
       0 as penal_septiembre,
       0 as penal_octubre,
       0 as penal_noviembre,
       0 as penal_diciembre,
       0 as penal_enero_mas
  from bolsa_funcionario b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
       b.ID_ACUMULADOR=t.ID_ACUMULADOR
   and b.id_ano = bm.id_ano(+)
 group by  b.id_ano,bm.periodo,B.id_funcionario ,tope_horas,b.ID_ACUMULADOR
union
select b.id_funcionario, b.id_ano,bm.periodo,tope_horas,b.ID_ACUMULADOR,
       0 as penal_enero,
      0  as penal_febrero,
       0 as penal_marzo,
       0 as penal_abril,
        sum(DECODE(PERIODO,5,DECODE(penal_mayo,0, exceso_en_horas * 60 + Excesos_en_minutos,
             DECODE(sign(Excesos_en_minutos),-1,exceso_en_horas * 60 + Excesos_en_minutos,DECODE(sign(exceso_en_horas),-1,  exceso_en_horas * 60 + Excesos_en_minutos,0))),0)) as penal_mayo,
       0 as penal_junio,
       0 as penal_julio,
       0 as penal_agosto,
       0 as penal_septiembre,
       0 as penal_octubre,
       0 as penal_noviembre,
       0 as penal_diciembre,
       0 as penal_enero_mas
  from bolsa_funcionario b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
   bm.anulado(+)=0 and
       b.ID_ACUMULADOR=t.ID_ACUMULADOR
   and b.id_ano = bm.id_ano(+)
 group by  b.id_ano,bm.periodo,B.id_funcionario ,tope_horas,b.ID_ACUMULADOR
union
select b.id_funcionario, b.id_ano,bm.periodo,tope_horas,b.ID_ACUMULADOR,
       0 as penal_enero,
       0  as penal_febrero,
       0 as penal_marzo,
       0 as penal_abril,
       0 as penal_mayo,
        sum(DECODE(PERIODO,6,DECODE(penal_junio,0, exceso_en_horas * 60 + Excesos_en_minutos,
             DECODE(sign(Excesos_en_minutos),-1,exceso_en_horas * 60 + Excesos_en_minutos,DECODE(sign(exceso_en_horas),-1,  exceso_en_horas * 60 + Excesos_en_minutos,0))),0)) as penal_junio,
       0 as penal_julio,
       0 as penal_agosto,
       0 as penal_septiembre,
       0 as penal_octubre,
       0 as penal_noviembre,
       0 as penal_diciembre,
       0 as penal_enero_mas
  from bolsa_funcionario b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
   bm.anulado(+)=0 and
       b.ID_ACUMULADOR=t.ID_ACUMULADOR
   and b.id_ano = bm.id_ano(+)
 group by  b.id_ano,bm.periodo,B.id_funcionario ,tope_horas,b.ID_ACUMULADOR
union
select b.id_funcionario, b.id_ano,bm.periodo,tope_horas,b.ID_ACUMULADOR,
       0 as penal_enero,
       0  as penal_febrero,
       0 as penal_marzo,
       0 as penal_abril,
       0 as penal_mayo,
       0 as penal_junio,
        sum(DECODE(PERIODO,7,DECODE(penal_julio,0, exceso_en_horas * 60 + Excesos_en_minutos,
             DECODE(sign(Excesos_en_minutos),-1,exceso_en_horas * 60 + Excesos_en_minutos,DECODE(sign(exceso_en_horas),-1,  exceso_en_horas * 60 + Excesos_en_minutos,0))),0)) as penal_julio,
       0 as penal_agosto,
       0 as penal_septiembre,
       0 as penal_octubre,
       0 as penal_noviembre,
       0 as penal_diciembre,
       0 as penal_enero_mas
  from bolsa_funcionario b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
   bm.anulado(+)=0 and
       b.ID_ACUMULADOR=t.ID_ACUMULADOR
   and b.id_ano = bm.id_ano(+)
 group by  b.id_ano,bm.periodo,B.id_funcionario ,tope_horas,b.ID_ACUMULADOR
union
select b.id_funcionario, b.id_ano,bm.periodo,tope_horas,b.ID_ACUMULADOR,
       0 as penal_enero,
       0  as penal_febrero,
       0 as penal_marzo,
       0 as penal_abril,
       0 as penal_mayo,
       0 as penal_junio,
       0 as penal_julio,
        sum(DECODE(PERIODO,8,DECODE(penal_agosto,0, exceso_en_horas * 60 + Excesos_en_minutos,
             DECODE(sign(Excesos_en_minutos),-1,exceso_en_horas * 60 + Excesos_en_minutos,DECODE(sign(exceso_en_horas),-1,  exceso_en_horas * 60 + Excesos_en_minutos,0))),0)) as penal_agosto,
       0 as penal_septiembre,
       0 as penal_octubre,
       0 as penal_noviembre,
       0 as penal_diciembre,
       0 as penal_enero_mas
  from bolsa_funcionario b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
   bm.anulado(+)=0 and
       b.ID_ACUMULADOR=t.ID_ACUMULADOR
   and b.id_ano = bm.id_ano(+)
 group by  b.id_ano,bm.periodo,B.id_funcionario ,tope_horas,b.ID_ACUMULADOR
union
select b.id_funcionario, b.id_ano,bm.periodo,tope_horas,b.ID_ACUMULADOR,
       0 as penal_enero,
       0  as penal_febrero,
       0 as penal_marzo,
       0 as penal_abril,
       0 as penal_mayo,
       0 as penal_junio,
       0 as penal_julio,
       0 as penal_agosto,
        sum(DECODE(PERIODO,9,DECODE(penal_septiembre,0, exceso_en_horas * 60 + Excesos_en_minutos,
             DECODE(sign(Excesos_en_minutos),-1,exceso_en_horas * 60 + Excesos_en_minutos,DECODE(sign(exceso_en_horas),-1,  exceso_en_horas * 60 + Excesos_en_minutos,0))),0)) as penal_septiembre,
       0 as penal_octubre,
       0 as penal_noviembre,
       0 as penal_diciembre,
       0 as penal_enero_mas
  from bolsa_funcionario b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
   bm.anulado(+)=0 and
       b.ID_ACUMULADOR=t.ID_ACUMULADOR
   and b.id_ano = bm.id_ano(+)
 group by  b.id_ano,bm.periodo,B.id_funcionario,tope_horas,b.ID_ACUMULADOR
union
select b.id_funcionario, b.id_ano,bm.periodo,tope_horas,b.ID_ACUMULADOR,
       0 as penal_enero,
       0  as penal_febrero,
       0 as penal_marzo,
       0 as penal_abril,
       0 as penal_mayo,
       0 as penal_junio,
       0 as penal_julio,
       0 as penal_agosto,
       0 as penal_septiembre,
        sum(DECODE(PERIODO,10,DECODE(penal_octubre,0, exceso_en_horas * 60 + Excesos_en_minutos,
             DECODE(sign(Excesos_en_minutos),-1,exceso_en_horas * 60 + Excesos_en_minutos,DECODE(sign(exceso_en_horas),-1,  exceso_en_horas * 60 + Excesos_en_minutos,0))),0)) as penal_octubre,
       0 as penal_noviembre,
       0 as penal_diciembre,
       0 as penal_enero_mas
  from bolsa_funcionario b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
   bm.anulado(+)=0 and
       b.ID_ACUMULADOR=t.ID_ACUMULADOR
   and b.id_ano = bm.id_ano(+)
 group by  b.id_ano,bm.periodo,B.id_funcionario, tope_horas,b.ID_ACUMULADOR
union
select b.id_funcionario, b.id_ano,bm.periodo,tope_horas,b.ID_ACUMULADOR,
       0 as penal_enero,
       0  as penal_febrero,
       0 as penal_marzo,
       0 as penal_abril,
       0 as penal_mayo,
       0 as penal_junio,
       0 as penal_julio,
       0 as penal_agosto,
       0 as penal_septiembre,
       0 as penal_octubre,
        sum(DECODE(PERIODO,11,DECODE(penal_noviembre,0, exceso_en_horas * 60 + Excesos_en_minutos,
             DECODE(sign(Excesos_en_minutos),-1,exceso_en_horas * 60 + Excesos_en_minutos,DECODE(sign(exceso_en_horas),-1,  exceso_en_horas * 60 + Excesos_en_minutos,0))),0)) as penal_noviembre,
       0 as penal_diciembre,
       0 as penal_enero_mas
  from bolsa_funcionario b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
   bm.anulado(+)=0 and
       b.ID_ACUMULADOR=t.ID_ACUMULADOR
   and b.id_ano = bm.id_ano(+)
 group by  b.id_ano,bm.periodo,B.id_funcionario ,tope_horas,b.ID_ACUMULADOR

union
select b.id_funcionario, b.id_ano,bm.periodo,tope_horas,b.ID_ACUMULADOR,
       0 as penal_enero,
       0  as penal_febrero,
       0 as penal_marzo,
       0 as penal_abril,
       0 as penal_mayo,
       0 as penal_junio,
       0 as penal_julio,
       0 as penal_agosto,
       0 as penal_septiembre,
       0 as penal_octubre,
        0 as penal_noviembre,
       sum(DECODE(PERIODO,12,DECODE(penal_diciembre,0, exceso_en_horas * 60 + Excesos_en_minutos,
             DECODE(sign(Excesos_en_minutos),-1,exceso_en_horas * 60 + Excesos_en_minutos,DECODE(sign(exceso_en_horas),-1,  exceso_en_horas * 60 + Excesos_en_minutos,0))),0)) as penal_diciembre,
       0 as penal_enero_mas
  from bolsa_funcionario b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
   bm.anulado(+)=0 and
       b.ID_ACUMULADOR=t.ID_ACUMULADOR
   and b.id_ano = bm.id_ano(+)
 group by  b.id_ano,bm.periodo,B.id_funcionario ,tope_horas,b.ID_ACUMULADOR
union
select b.id_funcionario, b.id_ano,bm.periodo,tope_horas,b.ID_ACUMULADOR,
       0 as penal_enero,
       0  as penal_febrero,
       0 as penal_marzo,
       0 as penal_abril,
       0 as penal_mayo,
       0 as penal_junio,
       0 as penal_julio,
       0 as penal_agosto,
       0 as penal_septiembre,
       0 as penal_octubre,
        0 as penal_noviembre,
       0 as penal_diciembre,
       sum(DECODE(PERIODO,13,DECODE(penal_enero_mas,0, exceso_en_horas * 60 + Excesos_en_minutos,
             DECODE(sign(Excesos_en_minutos),-1,exceso_en_horas * 60 + Excesos_en_minutos,DECODE(sign(exceso_en_horas),-1,  exceso_en_horas * 60 + Excesos_en_minutos,0))),0)) as penal_enero_mas
  from bolsa_funcionario b, BOLSA_MOVIMIENTO bm, bolsa_tipo_acumulacion t
 where b.ID_FUNCIONARIO = bm.ID_FUNCIONARIO(+) and
   bm.anulado(+)=0 and
       b.ID_ACUMULADOR=t.ID_ACUMULADOR
   and b.id_ano = bm.id_ano(+)
 group by  b.id_ano,bm.periodo,B.id_funcionario,tope_horas,b.ID_ACUMULADOR )



 group by  id_ano,periodo,id_funcionario ,tope_horas,ID_ACUMULADOR
);

