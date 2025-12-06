/*
================================================================================
  VISTA: rrhh.fichaje_test_borra
================================================================================
  PROPÓSITO:
    Vista de prueba/desarrollo para el resumen de saldo de fichaje.
    Similar a fichaje_saldo_completa_new pero usando la tabla PERSONAL
    directamente en lugar de PERSONAL_NEW.

  NOTA: El nombre sugiere que esta vista es para pruebas y podría ser
        candidata para eliminación en producción.

  CAMPOS RETORNADOS:
    - Mismos que fichaje_saldo_completa_new pero con DISTINCT
    - f: Fecha para ordenamiento
    - fecha: Enlace HTML al detalle del día
    - entrada/salida: Horas de entrada/salida
    - horas_fichadas_m/horas_hacer_m: Horas en minutos
    - horas_fichadas/horas_hacer: Horas en formato HH:MM
    - diferencia_minutos: Saldo del día
    - fuera_saldo: Horas fuera del cómputo
    - observaciones: Texto generado por función
    - mes_fecha_ano: Período
    - id_funcionario: Identificador del funcionario

  DIFERENCIAS CON fichaje_saldo_completa_new:
    - Usa tabla PERSONAL en lugar de PERSONAL_NEW
    - No incluye UNIONs con permisos, ausencias u horas extras
    - Solo muestra fichajes reales del resumen_saldo

  DEPENDENCIAS:
    - Vista: resumen_saldo
    - Tabla: personal
    - Función: devuelve_observaciones_fichaje()

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Documentación añadida
================================================================================
*/
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

