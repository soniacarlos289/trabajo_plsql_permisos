create or replace force view rrhh.bolsa_saldo_periodo_resumen as
(select sum(total) as total ,sum(p2) as p2 ,sum(p3) as p3 ,sum(p4) as p4 ,
                             sum(p5) as p5 ,sum(p6) as p6 ,sum(p7) as p7 ,
                             sum(p8) as p8 ,sum(p9) as p9 ,sum(p10) as p10,
                             sum(p11) as p11,sum(p12)as p12 ,sum(p13) as p13,
       ID_ANO,id_FUNCIONARIO

 from

(select saldo_periodo as total,
       saldo_periodo as p2,
       0 as p3,
       0 as p4,
       0 as p5,
       0 as p6,
       0 as p7,
       0 as p8,
       0 as p9,
       0 as p10,
     0 as p11,
       0 as p12,
     0 as p13,id_ano,id_funcionario

from bOLSA_SALDO_PERIODO where  periodo=2
UNION
select saldo_periodo as total,
       0 as p2,
        saldo_periodo as p3,
       0 as p4,
       0 as p5,
       0 as p6,
       0 as p7,
       0 as p8,
       0 as p9,
       0 as p10,
     0 as p11,
       0 as p12,
     0 as p13,id_ano,id_funcionario

from bOLSA_SALDO_PERIODO where  periodo=3
UNION
select saldo_periodo as total,
       0 as p2,
       0 as p3,
        saldo_periodo as p4,
       0 as p5,
       0 as p6,
       0 as p7,
       0 as p8,
       0 as p9,
       0 as p10,
     0 as p11,
       0 as p12,
     0 as p13,id_ano,id_funcionario

from bOLSA_SALDO_PERIODO where  periodo=4
UNION
select saldo_periodo as total,
       0 as p2,
       0  as p3,
       0 as p4,
       saldo_periodo as p5,
       0 as p6,
       0 as p7,
       0 as p8,
       0 as p9,
       0 as p10,
     0 as p11,
       0 as p12,
     0 as p13,id_ano,id_funcionario

from bOLSA_SALDO_PERIODO where  periodo=5
UNION
select saldo_periodo as total,
       0 as p2,
       0 as p3,
        0 as p4,
       0 as p5,
       saldo_periodo as p6,
       0 as p7,
       0 as p8,
       0 as p9,
       0 as p10,
     0 as p11,
       0 as p12,
     0 as p13,id_ano,id_funcionario

from bOLSA_SALDO_PERIODO where  periodo=6
UNION
select saldo_periodo as total,
       0 as p2,
        0 as p3,
       0 as p4,
       0 as p5,
       0 as p6,
       saldo_periodo  as p7,
       0 as p8,
       0 as p9,
       0 as p10,
     0 as p11,
       0 as p12,
     0 as p13,id_ano,id_funcionario

from bOLSA_SALDO_PERIODO where  periodo=7
UNION
select saldo_periodo as total,
       0 as p2,
       0 as p3,
      0 as p4,
       0 as p5,
       0 as p6,
       0 as p7,
         saldo_periodo as p8,
       0 as p9,
       0 as p10,
     0 as p11,
       0 as p12,
     0 as p13,id_ano,id_funcionario

from bOLSA_SALDO_PERIODO where  periodo=8
UNION
select saldo_periodo as total,
       0 as p2,
       0  as p3,
       0 as p4,
      0 as p5,
       0 as p6,
       0 as p7,
       0 as p8,
        saldo_periodo as p9,
       0 as p10,
     0 as p11,
       0 as p12,
     0 as p13,id_ano,id_funcionario

from bOLSA_SALDO_PERIODO where  periodo=9
UNION
select saldo_periodo as total,
       0 as p2,
       0 as p3,
        0 as p4,
       0 as p5,
       0 as p6,
       0 as p7,
       0 as p8,
       0 as p9,
       saldo_periodo as p10,
     0 as p11,
       0 as p12,
     0 as p13,id_ano,id_funcionario

from bOLSA_SALDO_PERIODO where  periodo=10
UNION
select saldo_periodo as total,
       0 as p2,
       0 as p3,
      0 as p4,
       0 as p5,
       0 as p6,
       0 as p7,
         0 as p8,
       0 as p9,
       0 as p10,
     saldo_periodo as p11,
       0 as p12,
     0 as p13,id_ano,id_funcionario

from bOLSA_SALDO_PERIODO where  periodo=11
UNION
select saldo_periodo as total,
       0 as p2,
       0  as p3,
       0 as p4,
      0 as p5,
       0 as p6,
       0 as p7,
       0 as p8,
       0 as p9,
       0 as p10,
     0 as p11,
        saldo_periodo as p12,
     0 as p13,id_ano,id_funcionario

from bOLSA_SALDO_PERIODO where  periodo=12
UNION
select saldo_periodo as total,
       0 as p2,
       0 as p3,
        0 as p4,
       0 as p5,
       0 as p6,
       0 as p7,
       0 as p8,
       0 as p9,
       0 as p10,
     0 as p11,
       0 as p12,
     saldo_periodo as  p13,id_ano,id_funcionario

from bOLSA_SALDO_PERIODO where  periodo=13
)
group by id_funcionario,id_ano);

