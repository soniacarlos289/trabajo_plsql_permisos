create or replace force view rrhh.vista_permiso_bomberos as
select "ID_PERMISO","ESTADO","ID_FUNCIONARIO","NOMBRE","APE1","APE2","ID_TIPO_PERMISO","DESC_TIPO_PERMISO","FECHA_GUARDIA","FECHA_INICIO","FECHA_FIN","DURACION_HORAS","OBSERVACIONES" from(
select distinct p.id_permiso as ID_PERMISO,
                decode(p.id_estado,80,'Activo',21,'Activo',22,'Activo',20,'Activo',--añadido 20
                                    'Anulado') as Estado,
                p.id_funcionario,
                nombre,
                ape1,
                ape2,
                DECODE(p.id_tipo_permiso,'11300', DECODE(tipo_baja,'AL','11303','AR','11304','AN','11302','EC','11301'),p.id_tipo_permiso) as ID_TIPO_PERMISO,
                desc_tipo_permiso || decode( p.id_tipo_permiso,'11300',  DECODE(tipo_baja,'AL','ACCIDENTE LABORAL','AR','ACCIDENTE LABORAL RECAIDA','AN','ACCIDENTE NO LABORAL','EC','ENFERMEDAD COMUN'),'') as DESC_TIPO_PERMISO,
                p.fecha_inicio as FECHA_GUARDIA,



           CASE when  p.fecha_inicio>= to_Date('21/05/2022','dd/mm/yyyy')  THEN

                  to_Date( DECODE(p.id_tipo_permiso,
                  '11000',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 08:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 16:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 00:00'))) ,
                  '01501',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 08:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 16:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 00:00'))) ,
                                         --'02031',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 08:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 16:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 00:00'))) ,
                                         '02030',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 08:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 16:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 00:00'))) ,
                                         '02000',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 08:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 16:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 00:00'))) ,
                                         '01015',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 08:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 16:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 00:00'))),
                                         '02015',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 08:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 16:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 00:00'))),
                                         '02031',  to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' ' ||Hora_inicio ,
                                         '15000',  to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' ' ||Hora_inicio  ,
                    to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 08:00' )  , 'dd/mm/yyyy hh24:mi'  )
           ELSE
                  to_Date( DECODE(p.id_tipo_permiso,
                  '11000',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 14:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 22:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 06:00'))) ,
                  '01501',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 14:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 22:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 06:00'))) ,
                                         --'02031',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 14:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 22:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 06:00'))) ,
                                         '02030',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 14:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 22:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 06:00'))) ,
                                         '02000',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 14:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 22:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 06:00'))) ,
                                         '01015',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 14:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 22:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 06:00'))),
                                         '02015',  DECODE(tu1_14_22,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 14:00', DECODE(tu2_22_06,1,to_char(p.fecha_inicio, 'dd/mm/yyyy') ||' 22:00', DECODE(tu3_04_14,1,to_char(p.fecha_inicio+1, 'dd/mm/yyyy') ||' 06:00'))),
                                         '02031',  to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' ' ||Hora_inicio ,
                                         '15000',  to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' ' ||Hora_inicio  ,
                    to_char(p.fecha_inicio, 'dd/mm/yyyy') || ' 14:00' )  , 'dd/mm/yyyy hh24:mi'  )
      END

          as fecha_inicio,





                to_DATE(
                    /*
                    DECODE(nvl(tu1_14_22,0) ,1, decode(tu3_04_14 ||tu2_22_06, 11,to_char(nvl(p.fecha_fin,p.fecha_fin+7), 'dd/mm/yyyy'),
                                                    to_char(nvl(p.fecha_inicio,p.fecha_inicio+7), 'dd/mm/yyyy'))
                                            ,0 ,to_char(nvl(p.fecha_fin,p.fecha_inicio+7), 'dd/mm/yyyy')
                                               ,to_char(nvl(p.fecha_fin,p.fecha_inicio+7), 'dd/mm/yyyy'))*/
                    decode(p.id_tipo_permiso,'01000', to_char(to_date(DECODE(nvl(tu1_14_22,0) ,1, decode(tu3_04_14 ||tu2_22_06, 11,to_char(nvl(p.fecha_fin,p.fecha_fin+7), 'dd/mm/yyyy'),
                                                    to_char(nvl(p.fecha_inicio,p.fecha_inicio+7), 'dd/mm/yyyy'))
                                            ,0 ,to_char(nvl(p.fecha_fin,p.fecha_inicio+7), 'dd/mm/yyyy')
                                               ,to_char(nvl(p.fecha_fin,p.fecha_inicio+7), 'dd/mm/yyyy')),'dd/mm/yyyy')+4,'dd/mm/yyyy'),
                    decode(tu3_04_14 ||tu2_22_06, 11,p.fecha_inicio+1,
                                                  10,p.fecha_inicio+1,
                                                  01,p.fecha_inicio+1,
                                                  00,to_char(nvl(p.fecha_fin,sysdate+7), 'dd/mm/yyyy')
                                                   ,to_char(nvl(p.fecha_fin,sysdate+7), 'dd/mm/yyyy')
                                               ) )
                    /*         antiguo chm. 19Enero
                       DECODE(nvl(tu1_14_22,0) ,1, decode(tu3_04_14 ||tu2_22_06, 11,to_char(nvl(p.fecha_fin,p.fecha_fin+7), 'dd/mm/yyyy'),
                                                    to_char(nvl(p.fecha_fin,p.fecha_inicio+7), 'dd/mm/yyyy'))
                                            ,0 ,to_char(nvl(p.fecha_fin,p.fecha_inicio+7), 'dd/mm/yyyy')
                                               ,to_char(nvl(p.fecha_fin,p.fecha_inicio+7), 'dd/mm/yyyy'))
                                               )*/

         /* decode(p.id_tipo_permiso,'01000', to_char(to_date(DECODE(nvl(tu1_14_22,0) ,1, decode(tu3_04_14 ||tu2_22_06, 11,to_char(nvl(p.fecha_fin,p.fecha_fin+7), 'dd/mm/yyyy'),
                                                    to_char(nvl(p.fecha_inicio,p.fecha_inicio+7), 'dd/mm/yyyy'))
                                            ,0 ,to_char(nvl(p.fecha_fin,p.fecha_inicio+7), 'dd/mm/yyyy')
                                               ,to_char(nvl(p.fecha_fin,p.fecha_inicio+7), 'dd/mm/yyyy')),'dd/mm/yyyy')+4,'dd/mm/yyyy'),
                                             DECODE(nvl(tu1_14_22,0) ,1, decode(tu3_04_14 ||tu2_22_06, 11,to_char(nvl(p.fecha_fin,p.fecha_fin+7), 'dd/mm/yyyy'),
                                                    to_char(nvl(p.fecha_fin,p.fecha_inicio+7), 'dd/mm/yyyy'))
                                            ,0 ,to_char(nvl(p.fecha_fin,p.fecha_inicio+7), 'dd/mm/yyyy')
                                               ,to_char(nvl(p.fecha_fin,p.fecha_inicio+7), 'dd/mm/yyyy'))
                                               )*/
                              ||
         CASE when  p.fecha_inicio>= to_Date('21/05/2022','dd/mm/yyyy')  THEN

                    DECODE(p.id_tipo_permiso
                                         ,'11000',  DECODE(tu3_04_14,1, ' 08:00', DECODE(tu2_22_06,1,' 00:00', DECODE(tu1_14_22,1,' 16:00'))) ,
                                         '01501',  DECODE(tu3_04_14,1, ' 08:00', DECODE(tu2_22_06,1,' 00:00', DECODE(tu1_14_22,1,' 16:00'))) ,
                                         '02030',  DECODE(tu3_04_14,1, ' 08:00', DECODE(tu2_22_06,1,' 00:00', DECODE(tu1_14_22,1,' 16:00'))) ,
                                        -- '02031',  DECODE(tu3_04_14,1, ' 08:00', DECODE(tu2_22_06,1,' 00:00', DECODE(tu1_14_22,1,' 16:00'))) ,
                                         '02000',  DECODE(tu3_04_14,1, ' 08:00', DECODE(tu2_22_06,1,' 00:00', DECODE(tu1_14_22,1,' 16:00'))) ,
                                         '01015',  DECODE(tu3_04_14,1, ' 08:00', DECODE(tu2_22_06,1,' 00:00', DECODE(tu1_14_22,1, ' 16:00'))),
                                         '02015',  DECODE(tu3_04_14,1, ' 08:00', DECODE(tu2_22_06,1,' 00:00', DECODE(tu1_14_22,1, ' 16:00'))),
                                         '02031',   ' ' ||Hora_fin  ,
                                         '15000',   ' ' ||Hora_fin  ,
                                         ' 08:00' )
         ELSE

            DECODE(p.id_tipo_permiso
                                         ,'11000',  DECODE(tu3_04_14,1, ' 14:00', DECODE(tu2_22_06,1,' 06:00', DECODE(tu1_14_22,1,' 22:00'))) ,
                                         '01501',  DECODE(tu3_04_14,1, ' 14:00', DECODE(tu2_22_06,1,' 06:00', DECODE(tu1_14_22,1,' 22:00'))) ,
                                         '02030',  DECODE(tu3_04_14,1, ' 14:00', DECODE(tu2_22_06,1,' 06:00', DECODE(tu1_14_22,1,' 22:00'))) ,
                                        -- '02031',  DECODE(tu3_04_14,1, ' 14:00', DECODE(tu2_22_06,1,' 06:00', DECODE(tu1_14_22,1,' 22:00'))) ,
                                         '02000',  DECODE(tu3_04_14,1, ' 14:00', DECODE(tu2_22_06,1,' 06:00', DECODE(tu1_14_22,1,' 22:00'))) ,
                                         '01015',  DECODE(tu3_04_14,1, ' 14:00', DECODE(tu2_22_06,1,' 06:00', DECODE(tu1_14_22,1, ' 22:00'))),
                                         '02015',  DECODE(tu3_04_14,1, ' 14:00', DECODE(tu2_22_06,1,' 06:00', DECODE(tu1_14_22,1, ' 22:00'))),
                                         '02031',   ' ' ||Hora_fin  ,
                                         '15000',   ' ' ||Hora_fin  ,
                                         ' 14:00' )
             END

                   , 'dd/mm/yyyy hh24:mi'  )  as fecha_Fin,





                DECODE(p.id_tipo_permiso,
                       '02031','3',
                       '15000',
                       trunc(total_horas / 60) || ':' ||
                       lpad(mod(total_horas, 60), 2, '0'),
                       p.num_dias * 8) as duracion_horas, DECODE(tipo_baja,'AL','ACCIDENTE LABORAL','AR','ACCIDENTE LABORAL RECAIDA','AN','ACCIDENTE NO LABORAL','EC','ENFERMEDAD COMUN',   OBSERVACIONES) as  OBSERVACIONES
  from permiso p, rrhh.personal_new pe, tr_tipo_permiso tr
where pe.id_funcionario = p.id_funcionario
   and tr.id_tipo_permiso = p.id_tipo_permiso and tr.id_ano=p.id_ano
   and p.id_ano > 2023 --and p.id_tipo_permiso<>'11300'
   and tipo_funcionario2 = 23
   and id_estado in(80,40,41,32,21,22,30,32) and id_permiso<>549117
   union
   select distinct  p.id_ausencia as ID_PERMISO,
                decode(p.id_estado,80,'Activo',21,'Activo',22,'Activo',
                                    'Anulado') as Estado,
                p.id_funcionario,
                nombre,
                ape1,
                ape2,
                p.id_tipo_ausencia,
                desc_tipo_ausencia,
                p.fecha_inicio as FECHA_GUARDIA,


                  fecha_inicio,

                 fecha_Fin,


                       trunc(total_horas / 60) || ':' ||
                       lpad(mod(total_horas, 60), 2, '0')
                        as duracion_horas, OBSERVACIONES
  from ausencia p, personal_new pe, tr_tipo_ausencia tr
where pe.id_funcionario = p.id_funcionario
   and tr.id_tipo_ausencia = p.id_tipo_ausencia
   and p.id_ano > 2023 and p.id_tipo_ausencia<>'11300'
   and tipo_funcionario2 = 23
   and id_estado in(80,40,41,32,21,22,30,32)
union
select  549117 as  ID_PERMISO,  'Activo' as estado,  203356 as id_funcionario, 'RUBEN' AS NOMBRE, 'VERDE' AS APE1 ,'FERNANDEZ' AS APE2 ,
        '02000'  AS id_tipo_permiso,'Asuntos particulares' AS desc_tipo_permiso,  TO_DATE('23/04/2025','DD/MM/YYYY') AS FECHA_GUARDIA,
           TO_DATE('23/04/2025 8:00:00','DD/MM/YYYY HH24:MI:SS') AS fecha_inicio,   TO_DATE('23/04/0025 16:00:00','DD/MM/YYYY HH24:MI:ss') AS FECHA_FIN , '8:00' AS  duracion_horas , '' AS oBSERVACIONES  from dual
union
select  949117 as  ID_PERMISO,  'Activo' as estado,  203356 as id_funcionario, 'RUBEN' AS NOMBRE, 'VERDE' AS APE1 ,'FERNANDEZ' AS APE2 ,
        '02000'  AS id_tipo_permiso,'Asuntos particulares' AS desc_tipo_permiso,  TO_DATE('23/04/2025','DD/MM/YYYY') AS FECHA_GUARDIA,
           TO_DATE('24/04/2025 00:00:00','DD/MM/YYYY HH24:MI:SS') AS fecha_inicio,   TO_DATE('24/04/0025 08:00:00','DD/MM/YYYY HH24:MI:ss') AS FECHA_FIN , '8:00' AS  duracion_horas , '' AS oBSERVACIONES  from dual


   )ORDER BY 1
;

