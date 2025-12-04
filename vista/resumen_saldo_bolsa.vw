CREATE OR REPLACE FORCE VIEW RRHH.RESUMEN_SALDO_BOLSA AS
(
select  id_funcionario,id_ano ,
     min(p_enero_sa) as  p_enero_sa,
 min(p_febrero_sa) as p_febrero_sa ,
 min(p_marzo_sa ) as p_marzo_sa ,
 min(p_abril_sa ) as p_abril_sa ,
min(p_mayo_sa ) as p_mayo_sa ,
  min(p_junio_sa ) as p_junio_sa  ,
  min(p_julio_sa) as  p_julio_sa,
 min(p_agosto_sa) as p_agosto_sa ,
 min(p_septiembre_sa ) as p_septiembre_sa ,
min(p_octubre_sa) as p_octubre_sa ,
min(p_noviembre_sa ) as p_noviembre_sa  ,
 min(p_diciembre_sa ) as  p_diciembre_sa ,
    min(p_ene_mas_sa ) as p_ene_mas_sa ,
   min(saldos_positivos) as saldos_positivos,
   min(saldos_negativos) as saldos_negativos
from (

SELECT id_funcionario,periodo,id_ano,
  DECODE(periodo,1,

      DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   ),'') p_enero_sa  ,
  '' p_febrero_sa ,
  '' p_marzo_sa ,
  '' p_abril_sa ,
  '' p_mayo_sa ,
  '' p_junio_sa ,
  '' p_julio_sa ,
  '' p_agosto_sa ,
  '' p_septiembre_sa ,
  '' p_octubre_sa ,
  '' p_noviembre_sa ,
  '' p_diciembre_sa  ,
   '' p_ene_mas_sa   ,
  '' saldos_positivos ,
  '' saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
      and  bm.anulado(+)=0 and periodo=1
group by periodo,id_funcionario,id_ano
union
SELECT id_funcionario,periodo,id_ano,
  '' p_enero_sa  ,
  DECODE(periodo,2,

      DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   ),'') p_febrero_sa ,
  '' p_marzo_sa ,
  '' p_abril_sa ,
  '' p_mayo_sa ,
  '' p_junio_sa ,
  '' p_julio_sa ,
  '' p_agosto_sa ,
  '' p_septiembre_sa ,
  '' p_octubre_sa ,
  '' p_noviembre_sa ,
  '' p_diciembre_sa   ,
   '' p_ene_mas_sa  ,
  '' saldos_positivos ,
  '' saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
      and  bm.anulado(+)=0 and periodo=2
group by periodo,id_funcionario,id_ano
union
SELECT id_funcionario,periodo,id_ano,
  '' p_enero_sa  ,
  ''  p_febrero_sa ,
  DECODE(periodo,3,

      DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   ),'') p_marzo_sa ,
  '' p_abril_sa ,
  '' p_mayo_sa ,
  '' p_junio_sa ,
  '' p_julio_sa ,
  '' p_agosto_sa ,
  '' p_septiembre_sa ,
  '' p_octubre_sa ,
  '' p_noviembre_sa ,
  '' p_diciembre_sa   ,
   '' p_ene_mas_sa  ,
  '' saldos_positivos ,
  '' saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
      and  bm.anulado(+)=0 and periodo=3
group by periodo,id_funcionario,id_ano
union
SELECT id_funcionario,periodo,id_ano,
  '' p_enero_sa  ,
  ''  p_febrero_sa ,
  '' p_marzo_sa ,
    DECODE(periodo,4,

      DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   ),'') p_abril_sa ,
  '' p_mayo_sa ,
  '' p_junio_sa ,
  '' p_julio_sa ,
  '' p_agosto_sa ,
  '' p_septiembre_sa ,
  '' p_octubre_sa ,
  '' p_noviembre_sa ,
  '' p_diciembre_sa   ,
   '' p_ene_mas_sa  ,
  '' saldos_positivos ,
  '' saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
      and  bm.anulado(+)=0 and periodo=4
group by periodo,id_funcionario,id_ano
union
SELECT id_funcionario,periodo,id_ano,
  '' p_enero_sa  ,
  ''  p_febrero_sa ,
  '' p_marzo_sa ,
    ''p_abril_sa ,
  DECODE(periodo,5,

      DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   ),'')  p_mayo_sa ,
  '' p_junio_sa ,
  '' p_julio_sa ,
  '' p_agosto_sa ,
  '' p_septiembre_sa ,
  '' p_octubre_sa ,
  '' p_noviembre_sa ,
  '' p_diciembre_sa   ,
   '' p_ene_mas_sa  ,
  '' saldos_positivos ,
  '' saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
      and  bm.anulado(+)=0 and periodo=5
group by periodo,id_funcionario,id_ano
union
SELECT id_funcionario,periodo,id_ano,
  '' p_enero_sa  ,
  ''  p_febrero_sa ,
  '' p_marzo_sa ,
    ''p_abril_sa ,
   ''  p_mayo_sa ,
   DECODE(periodo,6,

      DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   ),'') p_junio_sa ,
  '' p_julio_sa ,
  '' p_agosto_sa ,
  '' p_septiembre_sa ,
  '' p_octubre_sa ,
  '' p_noviembre_sa ,
  '' p_diciembre_sa  ,
   '' p_ene_mas_sa   ,
  '' saldos_positivos ,
  '' saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
      and  bm.anulado(+)=0 and periodo=6
group by periodo,id_funcionario,id_ano
union
SELECT id_funcionario,periodo,id_ano,
  '' p_enero_sa  ,
  ''  p_febrero_sa ,
  '' p_marzo_sa ,
    ''p_abril_sa ,
   ''  p_mayo_sa ,
   '' p_junio_sa ,
DECODE(periodo,7,

      DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   ),'') p_julio_sa ,
  '' p_agosto_sa ,
  '' p_septiembre_sa ,
  '' p_octubre_sa ,
  '' p_noviembre_sa ,
  '' p_diciembre_sa   ,
   '' p_ene_mas_sa  ,
  '' saldos_positivos ,
  '' saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
      and  bm.anulado(+)=0 and periodo=7
group by periodo,id_funcionario,id_ano
union
SELECT id_funcionario,periodo,id_ano,
  '' p_enero_sa  ,
  ''  p_febrero_sa ,
  '' p_marzo_sa ,
    ''p_abril_sa ,
   ''  p_mayo_sa ,
   '' p_junio_sa ,
  '' p_julio_sa ,
  DECODE(periodo,8,

      DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   ),'')  p_agosto_sa ,
  '' p_septiembre_sa ,
  '' p_octubre_sa ,
  '' p_noviembre_sa ,
  '' p_diciembre_sa  ,
   '' p_ene_mas_sa   ,
  '' saldos_positivos ,
  '' saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
      and  bm.anulado(+)=0 and periodo=8
group by periodo,id_funcionario,id_ano
union
SELECT id_funcionario,periodo,id_ano,
  '' p_enero_sa  ,
  ''  p_febrero_sa ,
  '' p_marzo_sa ,
    ''p_abril_sa ,
   ''  p_mayo_sa ,
   '' p_junio_sa ,
 '' p_julio_sa ,
    '' p_agosto_sa ,
  DECODE(periodo,9,

      DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   ),'')  p_septiembre_sa ,
  '' p_octubre_sa ,
  '' p_noviembre_sa ,
  '' p_diciembre_sa   ,
   '' p_ene_mas_sa  ,
  '' saldos_positivos ,
  '' saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
      and  bm.anulado(+)=0 and periodo=9
group by periodo,id_funcionario,id_ano
union
SELECT id_funcionario,periodo,id_ano,
  '' p_enero_sa  ,
  ''  p_febrero_sa ,
  '' p_marzo_sa ,
    ''p_abril_sa ,
   ''  p_mayo_sa ,
   '' p_junio_sa ,
  '' p_julio_sa ,
  '' p_agosto_sa ,
  '' p_septiembre_sa ,
   DECODE(periodo,10,

      DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   ),'') p_octubre_sa ,
  '' p_noviembre_sa ,
  '' p_diciembre_sa   ,
   '' p_ene_mas_sa  ,
  '' saldos_positivos ,
  '' saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
      and  bm.anulado(+)=0 and periodo=10
group by periodo,id_funcionario,id_ano
union
SELECT id_funcionario,periodo,id_ano,
  '' p_enero_sa  ,
  ''  p_febrero_sa ,
  '' p_marzo_sa ,
    ''p_abril_sa ,
   ''  p_mayo_sa ,
   '' p_junio_sa ,
   '' p_julio_sa ,
  '' p_agosto_sa ,
  '' p_septiembre_sa ,
  '' p_octubre_sa ,
    DECODE(periodo,11,

      DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   ),'') p_noviembre_sa ,
  '' p_diciembre_sa   ,
   '' p_ene_mas_sa  ,
  '' saldos_positivos ,
  '' saldos_negativos

 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
      and  bm.anulado(+)=0 and periodo=11
group by periodo,id_funcionario,id_ano
union
SELECT id_funcionario,periodo,id_ano,
  '' p_enero_sa  ,
  ''  p_febrero_sa ,
  '' p_marzo_sa ,
    ''p_abril_sa ,
   ''  p_mayo_sa ,
   '' p_junio_sa ,
   '' p_julio_sa ,
  '' p_agosto_sa ,
  '' p_septiembre_sa ,
  '' p_octubre_sa ,
   '' p_noviembre_sa ,
   DECODE(periodo,12,

      DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   ),'') p_diciembre_sa ,
   '' p_ene_mas_sa  ,
  '' saldos_positivos ,
  '' saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
      and  bm.anulado(+)=0 and periodo=12
group by periodo,id_funcionario,id_ano
union
SELECT id_funcionario,periodo,id_ano,
  '' p_enero_sa  ,
  ''  p_febrero_sa ,
  '' p_marzo_sa ,
    ''p_abril_sa ,
   ''  p_mayo_sa ,
   '' p_junio_sa ,
   '' p_julio_sa ,
  '' p_agosto_sa ,
  '' p_septiembre_sa ,
  '' p_octubre_sa ,
   '' p_noviembre_sa ,
   ''p_diciembre_sa  ,
   DECODE(periodo,13,

      DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   ),'') p_ene_mas_sa   ,
  '' saldos_positivos ,
  '' saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
      and  bm.anulado(+)=0 and periodo=13
group by periodo,id_funcionario,id_ano
union
SELECT id_funcionario,0,id_ano,
  '' p_enero_sa  ,
  ''  p_febrero_sa ,
  '' p_marzo_sa ,
    ''p_abril_sa ,
   ''  p_mayo_sa ,
   '' p_junio_sa ,
   '' p_julio_sa ,
  '' p_agosto_sa ,
  '' p_septiembre_sa ,
  '' p_octubre_sa ,
   '' p_noviembre_sa ,
   '' p_diciembre_sa  ,
   '' p_ene_mas_sa  ,
        DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   )  saldos_positivos ,
  '' as saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
 WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
and sign(EXCESO_en_horas*60+EXCESOs_en_minutos)=1
and  bm.anulado(+)=0
group by id_funcionario,id_ano
union
SELECT id_funcionario,0,id_ano,
  '' p_enero_sa  ,
  ''  p_febrero_sa ,
  '' p_marzo_sa ,
    ''p_abril_sa ,
   ''  p_mayo_sa ,
   '' p_junio_sa ,
   '' p_julio_sa ,
  '' p_agosto_sa ,
  '' p_septiembre_sa ,
  '' p_octubre_sa ,
   '' p_noviembre_sa ,
   ''p_diciembre_sa  ,
   '' p_ene_mas_sa  ,
    '' saldos_positivos ,
        DECODE(sign(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)),-1,
   '<font color="#FF0000">' || '-' ||
  lpad( trunc(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos))/60,0),2,'0') || ':' ||
  lpad( mod(sum(abs(EXCESO_en_horas)*60+abs(EXCESOs_en_minutos)),60),2,'0')   || '</font>'
  ,
   '<font color="#000000">'  ||
  lpad( trunc(sum(EXCESO_en_horas*60+EXCESOs_en_minutos)/60,0),2,'0') || ':' ||
  lpad( mod(sum(EXCESO_en_horas*60+EXCESOs_en_minutos),60),2,'0')   || '</font>'
   )  saldos_negativos
 FROM BOLSA_MOVIMIENTO BM,bolsa_tipo_MOVIMIENTO BT
 WHERE BM.ID_TIPO_MOVIMIENTO=BT.ID_TIPO_MOVIMIENTO
and sign(EXCESO_en_horas*60+EXCESOs_en_minutos)=-1
and  bm.anulado(+)=0
group by id_funcionario,id_ano

)

group by id_funcionario,id_ano );

