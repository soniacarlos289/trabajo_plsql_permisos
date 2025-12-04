create or replace force view rrhh.resumen_saldo as
select fh.id_dia,fc.fecha_fichaje_entrada,fc.fecha_fichaje_salida,nvl(horas_realizadas,0) as HR,
DECODE(laboral,'NO',0, DECODE(fc.id_fichaje_dia,null,horas_hacer,1,horas_hacer,0.00001)) as HH,
nvl(horas_realizadas,0)-DECODE(fc.id_fichaje_dia,null,horas_hacer,1,horas_hacer,0)
as SAldo_dia,fuera_saldo,
fh.periodo as periodo,fh.id_funcionario,  DECODE(nvl(horas_realizadas,0),0,
                             'SIN FICHAJE EN EL DÍA   <img src=\"../../imagen/icono_advertencia.jpg\" alt=\"INCIDENCIA\"  width=\"22\" height=\"22\" border=\"0\" >',
                             decode(fc.turno,0,'',1, 'Turno Mañana'
                                              ,2, 'Turno Tarde'
                                              ,3, 'Turno Noche'
                             ) ) as observaciones
 from fichaje_saldo_hacer  fh ,fichaje_saldo_fichado fc
where fh.id_funcionario=fc.id_funcionario(+) and fh.id_dia=fc.id_dia(+) and
       to_date(to_char(fc.fecha_fichaje_entrada(+),'dd/mm/yyyy'),'dd/mm/yyyy')
                                       =to_date(to_char(fh.id_dia,'dd/mm/yyyy'),'dd/mm/yyyy')
and fh.id_funcionario=fc.id_funcionario(+) and
fh.periodo=fc.periodo(+)

and PERMISO_EN_DIA(fh.ID_FUNCIONARIO,fh.id_dia)=0 --quitados chm 13/03/2019
and computadas(+)=0 and fh.id_dia > sysdate -1700


order by 1,2
;

