create or replace procedure rrhh.EXPE_ACTUA_TRANSCURRIDO(V_ID_INDICADOR  in varchar2,
                                                    V_TIPO_REGISTRO in varchar2) is

begin

  --DIAS LABORABLES 30
  IF V_ID_INDICADOR = 1 AND V_TIPO_REGISTRO = 'CONTRATACION' THEN

    UPDATE CONTRATACION_BIENES
       set total_dias = round(DECODE(fecha_fin, NULL, sysdate, fecha_fin) -
                              DECODE(fecha_inicio,
                                     NULL,
                                     sysdate,
                                     fecha_inicio) -
                              NVL((fecha_fin_sub - fecha_inicio_sub), 0),
                              0),
           OBJETIVO   = DECODE(trunc(round(DECODE(fecha_fin,
                                                  NULL,
                                                  sysdate,
                                                  fecha_fin) -
                                           DECODE(fecha_inicio,
                                                  NULL,
                                                  sysdate,
                                                  fecha_inicio) -
                                           NVL((fecha_fin_sub -
                                               fecha_inicio_sub),
                                               0),
                                           0) / 31),
                               0,
                               'SI',
                               'NO')
     WHERE ID_INDICADOR = 1
       AND TIPO_REGISTRO = 'CONTRATACION';
  END IF;

  --DIAS LABORABLES 15
  IF (V_ID_INDICADOR = 2) AND V_TIPO_REGISTRO = 'CONTRATACION' THEN

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
                        NVL((fecha_fin_sub - fecha_inicio_sub), 0),
           OBJETIVO   = DECODE(trunc((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') -
                                     NVL((fecha_fin_sub - fecha_inicio_sub),
                                          0)) / 16),
                               0,
                               'SI',
                               'NO')
     WHERE (ID_INDICADOR = 2)
       AND TIPO_REGISTRO = 'CONTRATACION'
       AND URGENTE = 'NO';

  END IF;

  --DIAS LABORABLES 26
  IF (V_ID_INDICADOR = 3) AND V_TIPO_REGISTRO = 'CONTRATACION' THEN

    UPDATE CONTRATACION_BIENES
       set total_dias = calcula_dias(DECODE(fecha_inicio,
                                            NULL,
                                            sysdate,
                                            fecha_inicio),
                                     DECODE(fecha_fin,
                                            NULL,
                                            sysdate,
                                            fecha_fin),
                                     'L'),
           OBJETIVO   = DECODE(trunc((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') ) / 6),
                               0,
                               'SI',
                               'NO')
     WHERE (ID_INDICADOR = 3)
       AND TIPO_REGISTRO = 'CONTRATACION'
       AND URGENTE = 'NO' and id_ano=2013;

    UPDATE CONTRATACION_BIENES
       set total_dias = calcula_dias(DECODE(fecha_inicio,
                                            NULL,
                                            sysdate,
                                            fecha_inicio),
                                     DECODE(fecha_fin,
                                            NULL,
                                            sysdate,
                                            fecha_fin),
                                     'L') ,
           OBJETIVO   = DECODE(trunc((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') ) / 4),
                               0,
                               'SI',
                               'NO')
     WHERE (ID_INDICADOR = 3)
       AND TIPO_REGISTRO = 'CONTRATACION'
       AND URGENTE = 'SI' and id_ano=2013;

  END IF;

  --DIAS NAturales 10
  IF (V_ID_INDICADOR = 4) AND V_TIPO_REGISTRO = 'CONTRATACION' THEN

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
                        NVL((fecha_fin_sub - fecha_inicio_sub), 0),
           OBJETIVO   = DECODE(trunc((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') -
                                     NVL((fecha_fin_sub - fecha_inicio_sub),
                                          0)) / 11),
                               0,
                               'SI',
                               'NO')
     WHERE (ID_INDICADOR = 4)
       AND TIPO_REGISTRO = 'CONTRATACION';
  END IF;

  --bienes objetivo 1, 2 dias habiles
  IF (V_ID_INDICADOR = 1) AND V_TIPO_REGISTRO = 'BIENES' THEN

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
                        NVL((fecha_fin_sub - fecha_inicio_sub), 0),
           OBJETIVO   = DECODE(trunc((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') -
                                     NVL((fecha_fin_sub - fecha_inicio_sub),
                                          0)) / 11),
                               0,
                               'SI',
                               'NO')
     WHERE (ID_INDICADOR = 1)
       AND TIPO_REGISTRO = 'BIENES';
  END IF;

  --bienes objetivo 2, 10 dias habiles
  IF (V_ID_INDICADOR = 2) AND V_TIPO_REGISTRO = 'BIENES' THEN

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
       AND TIPO_REGISTRO = 'BIENES';
  END IF;

  --bienes objetivo 3, 10 dias habiles
  IF (V_ID_INDICADOR = 3) AND V_TIPO_REGISTRO = 'BIENES' THEN

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
                        NVL((fecha_fin_sub - fecha_inicio_sub), 0),
           OBJETIVO   = DECODE(trunc((calcula_dias(DECODE(fecha_inicio,
                                                          NULL,
                                                          sysdate,
                                                          fecha_inicio),
                                                   DECODE(fecha_fin,
                                                          NULL,
                                                          sysdate,
                                                          fecha_fin),
                                                   'L') -
                                     NVL((fecha_fin_sub - fecha_inicio_sub),
                                          0)) / 11),
                               0,
                               'SI',
                               'NO')
     WHERE (ID_INDICADOR = 3)
       AND TIPO_REGISTRO = 'BIENES';
  END IF;

  commit;
end EXPE_ACTUA_TRANSCURRIDO;
/

