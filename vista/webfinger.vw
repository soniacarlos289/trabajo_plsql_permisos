create or replace force view rrhh.webfinger as
select
 A.CODPERS,
 A.FECHA,
 (to_char(A.HORTEO,'hh24')*60+to_char(A.HORTEO,'mi')) as HOBLIG,
 (0 - (to_char(A.HORTEO,'hh24')*60+to_char(A.HORTEO,'mi'))) as CAMPO11,
 NVL(sum((to_char(B.HFichadas,'hh24')*60+to_char(B.HFichadas,'mi'))),0) AS HFICH,
 NVL(sum((to_char(B.HCOMPUTABLEF,'hh24')*60+to_char(B.HCOMPUTABLEF,'mi'))),0) AS CAMPO9
from
 PRESENCI A, PERSFICH B
where
 A.CODINCI='000' and

 A.FECHA between to_Date(sysdate-365,'dd/mm/yy') and to_Date(sysdate-1,'dd/mm/yy') and
 A.CODPERS = B.NPERSONAL(+) and
 A.FECHA = B.FECHA(+)
group by
 A.CODPERS,
 A.FECHA,
 (to_char(A.HORTEO,'hh24')*60+to_char(A.HORTEO,'mi')),
 (0 - (to_char(A.HORTEO,'hh24')*60+to_char(A.HORTEO,'mi'))) WITH READ ONLY;

