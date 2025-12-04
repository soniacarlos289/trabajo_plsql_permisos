create or replace force view rrhh.fichaje_test_borra as
select distinct ID_DIA as F,
               '<a href=../Finger/detalle_dia.jsp?ID_DIA=' ||
       to_CHAR(to_DATE(ID_DIA, 'dd/mm/yy'), 'DD/MM/') || '20' || to_CHAR(to_DATE(ID_DIA, 'dd/mm/yy'), 'yy') || '>' ||
       to_CHAR(to_DATE(ID_DIA, 'dd/mm/yy'), 'DD/MM/yy') || '</a>' AS FECHA,
               to_char(fecha_fichaje_entrada, 'hh24:mi') AS ENTRADA,
               to_char(fecha_fichaje_salida, 'hh24:mi') AS SALIDA,
                HR  as Horas_fichadas_m,
                decode(tipo_funcionario2,21,0,23,0,HH) as horas_hacer_m,
                lpad(TRUNC((HR)/60),2,'0') ||':'  ||
                lpad(nvl(TRUNC(HR) -TRUNC((HR)/60)*60,0),2,'0') as Horas_fichadas,
                lpad(nvl(TRUNC((HH)/60),0),2,'0') ||':'  ||
                 lpad(round(nvl((HH -TRUNC((HH)/60)*60),0)),2,'0') as horas_hacer,
                nvl(saldo_dia,0) as diferencia_minutos,fuera_saldo,
                devuelve_observaciones_fichaje(p.id_funcionario,tipo_funcionario2,
                                               observaciones ,
                                           id_dia,
                                            round(hh),
                                            round(hr))
                  as observaciones,
                periodo as mes_fecha_ano,
                to_number(p.id_funcionario) as id_funcionario
         from resumen_saldo r,personal p
         where r.id_funcionario=p.id_funcionario;

