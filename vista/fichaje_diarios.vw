create or replace force view rrhh.fichaje_diarios as
select Fecha,hora,codigo,id_funcionario,pin,numero,tipotrans from (
select fecha as fecha_d,to_char(FECHA,'dd/mm/yyyy') AS FECHA,  to_char(HORA,'hh24:mi') AS HORA,'0' ||substr(codigo,2,4)as codigo  ,id_funcionario,t.pin,t.numero,tipotrans
from persona p, transacciones t ,funcionario_fichaje ff1
where ff1.pin=p.numtarjeta and t.fecha=to_char(sysdate,'DD/mm/YYYY')  and t.pin=p.numtarjeta
 and tipotrans in ('2','55','39','4865','4356','4098','4102')
union

   select fecha as fecha_d,to_char(FECHA,'dd/mm/yyyy') AS FECHA,  to_char(HORA,'hh24:mi') AS HORA,'0' ||substr(codigo,2,4)as codigo  ,id_funcionario,t.pin,t.numero,tipotrans
from persona p, transacciones t ,funcionario_fichaje ff1
where ff1.pin2=p.numtarjeta and t.fecha=to_char(sysdate,'DD/mm/YYYY')  and t.pin=p.numtarjeta
 and tipotrans in ('2','55','39','4865','4356','4098','4102','4097')
     )


     ORDER BY FECHA desc,HORA;

