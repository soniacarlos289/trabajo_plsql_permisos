create or replace procedure rrhh.EXPE_ACTUA_TRANSCURRIDO_TODO is

begin


    UPDATE CONTRATACION_BIENES
       set total_dias =calcula_dias(DECODE(fecha_inicio,
                                            NULL,
                                            sysdate,
                                            fecha_inicio),
                                     DECODE(fecha_fin,
                                            NULL,
                                            sysdate,
                                            fecha_fin),
                                     'L')-
                         nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0)+1,
         OBJETIVO   = DECODE(trunc((((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') -
                                      nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0)+1) ))/31),
                               0,
                               'SI',
                               'NO')
     WHERE ID_INDICADOR = 1
       AND TIPO_REGISTRO = 'CONTRATACION';


  --DIAS LABORABLES 15

    UPDATE CONTRATACION_BIENES
       set total_dias =calcula_dias(DECODE(fecha_inicio,
                                            NULL,
                                            sysdate,
                                            fecha_inicio),
                                     DECODE(fecha_fin,
                                            NULL,
                                            sysdate,
                                            fecha_fin),
                                     'L')-
                         nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0)+1,
         OBJETIVO   = DECODE(trunc((((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') -
                                      nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0)) ))/16),
                               0,
                               'SI',
                               'NO')
     WHERE (ID_INDICADOR = 2)
       AND TIPO_REGISTRO = 'CONTRATACION'
       AND URGENTE = 'NO'
       AND ID_ANO>2017;


  --DIAS LABORABLES 26

      UPDATE CONTRATACION_BIENES
        set total_dias =calcula_dias(DECODE(fecha_inicio,
                                            NULL,
                                            sysdate,
                                            fecha_inicio),
                                     DECODE(fecha_fin,
                                            NULL,
                                            sysdate,
                                            fecha_fin),
                                     'L')-
                         nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0),
         OBJETIVO   = DECODE(trunc((((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') -
                                      nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0)) ))/4),
                               0,
                               'SI',
                               'NO')
     WHERE (ID_INDICADOR = 3)
       AND TIPO_REGISTRO = 'CONTRATACION'
       AND URGENTE = 'SI' and id_ano>2017;


    UPDATE CONTRATACION_BIENES
       set total_dias =calcula_dias(DECODE(fecha_inicio,
                                            NULL,
                                            sysdate,
                                            fecha_inicio),
                                     DECODE(fecha_fin,
                                            NULL,
                                            sysdate,
                                            fecha_fin),
                                     'L')-
                         nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0),
         OBJETIVO   = DECODE(trunc((((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') -
                                      nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0)) ))/6),
                               0,
                               'SI',
                               'NO')

     WHERE (ID_INDICADOR = 3)
       AND TIPO_REGISTRO = 'CONTRATACION'
       AND URGENTE = 'NO' and id_ano>2017;
       commit;




    UPDATE CONTRATACION_BIENES
         set total_dias =calcula_dias(DECODE(fecha_inicio,
                                            NULL,
                                            sysdate,
                                            fecha_inicio),
                                     DECODE(fecha_fin,
                                            NULL,
                                            sysdate,
                                            fecha_fin),
                                     'L')-
                         nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0)+1,
         OBJETIVO   = DECODE(trunc((((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') -
                                      nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0)) ))/11),
                               0,
                               'SI',
                               'NO')

     WHERE (ID_INDICADOR = 4)
       AND TIPO_REGISTRO = 'CONTRATACION'
    AND ID_ANO>2017;
commit;
  --bienes objetivo 1, 2 dias habiles

    UPDATE CONTRATACION_BIENES
       set total_dias = calcula_dias(DECODE(fecha_inicio,
                                            NULL,
                                            sysdate,
                                            fecha_inicio),
                                     DECODE(fecha_fin,
                                            NULL,
                                            sysdate,
                                            fecha_fin),
                                     'L') -
                         nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0),
           OBJETIVO   = DECODE(trunc((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') -
                                      nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0)  ) / 11),
                               0,
                               'SI',
                               'NO')
     WHERE (ID_INDICADOR = 1)
       AND TIPO_REGISTRO = 'BIENES';


  --bienes objetivo 2, 10 dias habiles
    UPDATE CONTRATACION_BIENES
       set total_dias = calcula_dias(DECODE(fecha_inicio,
                                            NULL,
                                            sysdate,
                                            fecha_inicio),
                                     DECODE(fecha_fin,
                                            NULL,
                                            sysdate,
                                            fecha_fin),
                                     'L')
                        ,
           OBJETIVO   = DECODE(trunc((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') ) / 11),
                               0,
                               'SI',
                               'NO')
     WHERE (ID_INDICADOR = 2)
       AND TIPO_REGISTRO = 'BIENES'  and id_registro<>7087;



    UPDATE CONTRATACION_BIENES
       set total_dias = calcula_dias(DECODE(fecha_inicio,
                                            NULL,
                                            sysdate,
                                            fecha_inicio),
                                     DECODE(fecha_fin,
                                            NULL,
                                            sysdate,
                                            fecha_fin),
                                     'L') -
                         nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0),
           OBJETIVO   = DECODE(trunc((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') -
                                     nvl( calcula_dias(fecha_inicio_sub , fecha_fin_sub, 'L'),0) ) / 11),
                               0,
                               'SI',
                               'NO')
     WHERE (ID_INDICADOR = 3)
       AND TIPO_REGISTRO = 'BIENES';


  commit;
end EXPE_ACTUA_TRANSCURRIDO_todo;
/

