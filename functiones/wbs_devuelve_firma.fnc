create or replace function rrhh.wbs_devuelve_firma(i_id_funcionario IN VARCHAR2,
                                              operacion        in varchar2,
                                              tipo             in varchar2)
  return clob is
  ---operacion-------
  --- a Autorizados
  --- p pendientes
  --- d dengados

  --tipo------
  ---  pe permisos
  ---  au ausencias
  ---  fi fichajes
  datos_permisos_solicitados   clob;
  datos_permisos_sin_disfrutar clob;
  saldo_horario                varchar2(123);
  cabecera_periodos_consulta   varchar2(12300);
  d_fecha                      date;
  datos                        clob;
  datos_tmp                    clob;
  contador                     number;
  i_permiso                    number;
  Resultado                    clob;

  --Permisos pendientes de firma   
  CURSOR Cpermisos_pendientes is
    SELECT distinct json_object('nombre_apellidos' is
                                initcap(Nombre) || ' ' || INITCAP(Ape1) || ' ' ||
                                INITCAP(Ape2),
                                'permiso' is 
                                cambia_acentos(dEsc_tipo_permiso),
                                    'estado' is   cambia_acentos(tre.DESC_ESTADO_PERMISO) || DEcode(pe.id_estado,30,' - Motivo: '|| cambia_acentos(motivo_denega),''),
                     
                                'id_anio' is pe.ID_ano,
                                'fecha_inicio' is
                                to_char(pe.fecha_inicio, 'dd/mm/yyyy') || ' ' ||
                                decode(pe.id_tipo_permiso,
                                       15000,
                                       hora_inicio),
                                'fecha_fin' is
                                to_char(pe.fecha_fin, 'dd/mm/yyyy') || ' ' ||
                                decode(pe.id_tipo_permiso, 15000, hora_fin),
                                 'numero_dias' is
                                pe.num_dias || '-' || tipo_dias,
                                'id_permiso' is ID_PERMISO,
                                'justificado' is DECODE(pe.JUSTIFICACION,
                                              '--',
                                              '',
                                              CHEQUEA_ENLACE_FICHERO_JUSTI(pe.ID_ANO,
                                                                         pe.ID_FUNCIONARIO,
                                                                         ID_PERMISO
                                                                         ))
                               ),
                    pe.fecha_inicio
    
      FROM permiso pe,
           (select distinct id_funcionario,
                            nombre,
                            ape1,
                            ape2,
                            tipo_funcionario2
              from personal_new) p,
           funcionario_firma f,TR_ESTADO_permiso tre,
           tr_tipo_permiso tr
     WHERE TRE.ID_ESTADO_permiso = pe.ID_ESTADO and  ((id_estado in ('20') and firmado_js is null and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           f.id_js = i_id_funcionario) OR
           (id_estado in ('20') and firmado_js is null and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           f.id_delegado_js = i_id_funcionario and
           (chequeo_entra_delegado_new(id_delegado_js, p.id_funcionario) =
           f.id_js or ID_DELEGADO_FIRMA = 1)) OR
           (id_estado in ('20') and firmado_js is null and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           f.id_delegado_js2 = i_id_funcionario and ID_DELEGADO_FIRMA = 1) OR
           (id_estado in ('20') and firmado_js is null and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           f.id_delegado_js3 = i_id_funcionario and ID_DELEGADO_FIRMA = 1) OR
           (id_estado in ('20') and firmado_js is null and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           f.id_delegado_js4 = i_id_funcionario and ID_DELEGADO_FIRMA = 1) OR
           (id_estado in ('21') and firmado_ja is null and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           f.id_ja = i_id_funcionario) OR
           (id_estado in ('20') and pe.firmado_js = i_id_funcionario and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           tipo_funcionario2 = 23) OR
           (id_estado in ('21') and '600077' = i_id_funcionario and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           p.tipo_funcionario2 = 23))
       and tr.id_tipo_permiso = pe.id_tipo_permiso
       and tr.id_ano = pe.id_ano
     ORDER BY pe.fecha_inicio desc;

  --ausencias y fichajes pendientes de firma   
  CURSOR Causencias_pendientes is
    SELECT distinct   
                       json_object('nombre_apellidos' is
                                initcap(Nombre) || ' ' || INITCAP(Ape1) || ' ' ||
                                INITCAP(Ape2),
                                 'ausencia' is 
                                  TRANSLATE(REGEXP_REPLACE(dEsc_tipo_ausencia, '[^A-Za-z0-9¡…Õ”⁄·ÈÌÛ˙ ]', ''), 
                                       'Ò·ÈÌÛ˙‡ËÏÚ˘„ı‚ÍÓÙÙ‰ÎÔˆ¸Á—¡…Õ”⁄¿»Ã“Ÿ√’¬ Œ‘€ƒÀœ÷‹« ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC '),
                                                  'estado' is   cambia_acentos(DESC_ESTADO_PERMISO) || DEcode(id_estado_permiso,30,' - Motivo: '|| cambia_acentos(motivo_denega),''),
                                                                  'id_anio' is pe.ID_ano,
                                'fecha_inicio' is
                                to_char(pe.fecha_inicio,
                                        'dd/mm/yyyy hh24:mi'),
                                'fecha_fin' is
                                to_char(pe.fecha_fin, 'dd/mm/yyyy hh24:mi'),
                              'numero_horas' is
                                trunc(pe.total_horas / 60) || ':' ||
                                lpad(mod(pe.total_horas, 60), 2, '0'),
                                'id_ausencia' is ID_ausencia,
                                    'justificado' is DECODE(pe.justificado,
                                              '--',
                                              '',
                                              CHEQUEA_ENLACE_FICHERO_JUSTI(pe.ID_ANO,
                                                                         pe.ID_FUNCIONARIO,
                                                                         ID_AUSENCIA
                                                                         ))
                               ),
                                
                                
                                
                    pe.fecha_inicio
      FROM AUSENCIA          pe,TR_ESTADO_permiso tre,
           personal_new          p,
           funcionario_firma f,
           tr_tipo_AUSENCIA  tr
     WHERE  TRE.ID_ESTADO_permiso = pe.ID_ESTADO and ((id_estado in ('20') and firmado_js is null and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           f.id_js = i_id_funcionario) OR
           (id_estado in ('20') and firmado_js is null and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           f.id_delegado_js = i_id_funcionario and
           (chequeo_entra_delegado_new(id_delegado_js, p.id_funcionario) =
           f.id_js or ID_DELEGADO_FIRMA = 1)) OR
           (id_estado in ('20') and firmado_js is null and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           f.id_delegado_js2 = i_id_funcionario and ID_DELEGADO_FIRMA = 1) OR
           (id_estado in ('20') and firmado_js is null and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           f.id_delegado_js3 = i_id_funcionario and ID_DELEGADO_FIRMA = 1) OR
           (id_estado in ('20') and firmado_js is null and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           f.id_delegado_js4 = i_id_funcionario and ID_DELEGADO_FIRMA = 1) OR
           (id_estado in ('21') and firmado_ja is null and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           f.id_ja = i_id_funcionario) OR
           (id_estado in ('20') and pe.firmado_js = i_id_funcionario and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           tipo_funcionario2 = 23) OR
           (id_estado in ('21') and '600077' = i_id_funcionario and
           pe.id_funcionario = p.id_funcionario and
           pe.id_funcionario = f.id_funcionario and
           p.tipo_funcionario2 = 23))
       and tr.id_tipo_AUSENCIA = pe.id_tipo_AUSENCIA
       and (
            (operacion || tipo = 'pau' and tr.id_tipo_AUSENCIA <> '998' ) OR
            (operacion || tipo = 'pfi' and tr.id_tipo_AUSENCIA = '998')
           )
     ORDER BY pe.fecha_inicio;

--Permisos autorizados   
  CURSOR Cpermisos_autorizados is
 SELECT distinct json_object('nombre_apellidos' is
                                initcap(p.Nombre) || ' ' || INITCAP(p.Ape1) || ' ' ||
                                INITCAP(p.Ape2),
                                'permiso' is  TRANSLATE(REGEXP_REPLACE(dEsc_tipo_permiso, '[^A-Za-z0-9¡…Õ”⁄·ÈÌÛ˙ ]', ''), 
                                       'Ò·ÈÌÛ˙‡ËÏÚ˘„ı‚ÍÓÙÙ‰ÎÔˆ¸Á—¡…Õ”⁄¿»Ã“Ÿ√’¬ Œ‘€ƒÀœ÷‹« ', 
                                        'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC '),
                                 'estado' is   cambia_acentos(tre.DESC_ESTADO_PERMISO) || DEcode(pe.id_estado,30,' - Motivo: '|| cambia_acentos(motivo_denega),''),
                     
                                'id_anio' is pe.ID_ano,
                                'fecha_inicio' is
                                to_char(pe.fecha_inicio, 'dd/mm/yyyy') || ' ' ||
                                decode(pe.id_tipo_permiso,
                                       15000,
                                       hora_inicio),
                                'fecha_fin' is
                                to_char(pe.fecha_fin, 'dd/mm/yyyy') || ' ' ||
                                decode(pe.id_tipo_permiso, 15000, hora_fin),
                                 'numero_dias' is
                                pe.num_dias || '-' || tipo_dias,
                                'id_permiso' is ID_PERMISO,
                                'firma en' is to_char(pe.fecha_js ,'dd/mm/yyyy'), 
                                'observaciones' is ''
                               ),
                    pe.fecha_js
  FROM permiso pe,
       tr_tipo_permiso tr,
       (select distinct id_funcionario,
                        nombre,
                        ape1,
                        ape2,
                        tipo_funcionario2
          from personal_new) p,
       personal_new je,
       tr_estado_permiso tr,TR_ESTADO_permiso tre,
       (select id_funcionario,
               id_delegado_js,
               id_js,
               ID_DELEGADO_FIRMA,
               id_delegado_js2,
               id_delegado_js3,
               id_delegado_js4
          from funcionario_firma
         where id_funcionario = i_id_funcionario) f
 WHERE  TRE.ID_ESTADO_permiso = pe.ID_ESTADO and ((id_estado not in ('30', '40') and
       firmado_js = i_id_funcionario and
       fecha_js is not null) OR
       (id_estado not in ('30', '40') and firmado_js = f.id_delegado_js AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado not in ('30', '40') and firmado_js = f.id_js AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado not in ('30', '40') and firmado_js = f.id_delegado_js2 AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado not in ('30', '40') and firmado_js = f.id_delegado_js3 AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado not in ('30', '40') and firmado_js = f.id_delegado_js4 AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado not in ('31', '40') and
       firmado_ja = i_id_funcionario and
       fecha_ja is not null))
   and tr.id_tipo_permiso = pe.id_tipo_permiso
   and pe.id_funcionario = p.id_funcionario
   and tr.id_estado_permiso = pe.id_estado
   and pe.firmado_js = je.id_funcionario
   and tr.id_ano = pe.id_ano
   and pe.id_ANO > to_number(to_char(sysdate, 'yyyy')) - 2
 ORDER BY fecha_js desc;

--Permisos denegados
  CURSOR Cpermisos_denegados is
 SELECT distinct json_object('nombre_apellidos' is
                                initcap(p.Nombre) || ' ' || INITCAP(p.Ape1) || ' ' ||
                                INITCAP(p.Ape2),
                                'permiso' is  TRANSLATE(REGEXP_REPLACE(dEsc_tipo_permiso, '[^A-Za-z0-9¡…Õ”⁄·ÈÌÛ˙ ]', ''), 
                                       'Ò·ÈÌÛ˙‡ËÏÚ˘„ı‚ÍÓÙÙ‰ÎÔˆ¸Á—¡…Õ”⁄¿»Ã“Ÿ√’¬ Œ‘€ƒÀœ÷‹« ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC '),
                                        'estado' is   cambia_acentos(tre.DESC_ESTADO_PERMISO) || DEcode(pe.id_estado,30,' - Motivo: '|| cambia_acentos(motivo_denega),''),
                             
                                'id_anio' is pe.ID_ano,
                                'fecha_inicio' is
                                to_char(pe.fecha_inicio, 'dd/mm/yyyy') || ' ' ||
                                decode(pe.id_tipo_permiso,
                                       15000,
                                       hora_inicio),
                                'fecha_fin' is
                                to_char(pe.fecha_fin, 'dd/mm/yyyy') || ' ' ||
                                decode(pe.id_tipo_permiso, 15000, hora_fin),
                                 'numero_dias' is
                                pe.num_dias || '-' || tipo_dias,
                                'id_permiso' is ID_PERMISO,
                                'firma en' is to_char(pe.fecha_js ,'dd/mm/yyyy'), 
                                'observaciones' is MOTIVO_DENEGA
                               ),
                    pe.fecha_js
  FROM permiso pe,
       tr_tipo_permiso tr,
       (select distinct id_funcionario,
                        nombre,
                        ape1,
                        ape2,
                        tipo_funcionario2
          from personal_new) p,
       personal_new je,
       tr_estado_permiso tr,TR_ESTADO_permiso tre,
       (select id_funcionario,
               id_delegado_js,
               id_js,
               ID_DELEGADO_FIRMA,
               id_delegado_js2,
               id_delegado_js3,
               id_delegado_js4
          from funcionario_firma
         where id_funcionario = i_id_funcionario) f
 WHERE  TRE.ID_ESTADO_permiso = pe.ID_ESTADO and ((id_estado  in ('30') and
       firmado_js = i_id_funcionario and
       fecha_js is not null) OR
       (id_estado  in ('30') and firmado_js = f.id_delegado_js AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado  in ('30') and firmado_js = f.id_js AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado  in ('30') and firmado_js = f.id_delegado_js2 AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado  in ('30') and firmado_js = f.id_delegado_js3 AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado  in ('30') and firmado_js = f.id_delegado_js4 AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado  in ('31') and
       firmado_ja = i_id_funcionario and
       fecha_ja is  null))
   and tr.id_tipo_permiso = pe.id_tipo_permiso
   and pe.id_funcionario = p.id_funcionario
   and tr.id_estado_permiso = pe.id_estado
   and pe.firmado_js = je.id_funcionario
   and tr.id_ano = pe.id_ano
   and pe.id_ANO > to_number(to_char(sysdate, 'yyyy')) - 2
 ORDER BY fecha_js desc;

--ausencias autorizada  
  CURSOR Causencias_autorizas is
SELECT distinct 
                                json_object('nombre_apellidos' is
                                initcap(p.Nombre) || ' ' || INITCAP(p.Ape1) || ' ' ||
                                INITCAP(p.Ape2),
                                 'ausencia' is  TRANSLATE(REGEXP_REPLACE(dEsc_tipo_ausencia, '[^A-Za-z0-9¡…Õ”⁄·ÈÌÛ˙ ]', ''), 
                                       'Ò·ÈÌÛ˙‡ËÏÚ˘„ı‚ÍÓÙÙ‰ÎÔˆ¸Á—¡…Õ”⁄¿»Ã“Ÿ√’¬ Œ‘€ƒÀœ÷‹« ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC '),
                                         'estado' is   cambia_acentos(DESC_ESTADO_PERMISO) || DEcode(id_estado_permiso,30,' - Motivo: '|| cambia_acentos(motivo_denega),''),
                                
                                    'id_anio' is pe.ID_ano,
                                'fecha_inicio' is
                                to_char(pe.fecha_inicio,
                                        'dd/mm/yyyy hh24:mi'),
                                'fecha_fin' is
                                to_char(pe.fecha_fin, 'dd/mm/yyyy hh24:mi'),
                              'numero_horas' is
                                trunc(pe.total_horas / 60) || ':' ||
                                lpad(mod(pe.total_horas, 60), 2, '0'),
                                'id_ausencia' is ID_ausencia,
                                 'firma en' is to_char(pe.fecha_js ,'dd/mm/yyyy'), 
                                'observaciones' is''
                                ),pe.fecha_js
  from ausencia pe,
       tr_tipo_ausencia tr,
       personal_new p,
       personal_new je,TR_ESTADO_permiso tre,
       (select id_funcionario,
               id_delegado_js,
               id_js,
               ID_DELEGADO_FIRMA,
               id_delegado_js2,
               id_delegado_js3,
               id_delegado_js4
          from funcionario_firma
         where id_funcionario = i_id_funcionario) f
 WHERE TRE.ID_ESTADO_permiso = pe.ID_ESTADO and ((id_estado not in ('30','40') and
       firmado_js = i_id_funcionario) OR
       (id_estado not in ('30','40') and firmado_js = f.id_delegado_js AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado not in ('30','40') and firmado_js = f.id_js AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado not in ('30','40') and firmado_js = f.id_delegado_js2 AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado not in ('30','40') and firmado_js = f.id_delegado_js3 AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado not in ('30','40') and firmado_js = f.id_delegado_js4 AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado not in ('31') and
       firmado_ja = i_id_funcionario))
   and tr.id_tipo_ausencia = pe.id_tipo_ausencia
   and pe.id_funcionario = p.id_funcionario
   and pe.firmado_js = je.id_funcionario
   and (pe.id_ANO > to_number(to_char(sysdate, 'yyyy')) - 2)
      and (
          
             (operacion || tipo = 'aau' and tr.id_tipo_AUSENCIA <> '998' ) OR
            (operacion || tipo = 'afi' and tr.id_tipo_AUSENCIA = '998')
           )
 ORDER BY pe.fecha_js desc;

--ausencias denegas  
  CURSOR Causencias_denegadas is
SELECT distinct json_object('nombre_apellidos' is
                                initcap(p.Nombre) || ' ' || INITCAP(p.Ape1) || ' ' ||
                                INITCAP(p.Ape2),
                                 'ausencia' is  TRANSLATE(REGEXP_REPLACE(dEsc_tipo_ausencia, '[^A-Za-z0-9¡…Õ”⁄·ÈÌÛ˙ ]', ''), 
                                       'Ò·ÈÌÛ˙‡ËÏÚ˘„ı‚ÍÓÙÙ‰ÎÔˆ¸Á—¡…Õ”⁄¿»Ã“Ÿ√’¬ Œ‘€ƒÀœ÷‹« ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC '),
                                 
                                  'estado' is   cambia_acentos(DESC_ESTADO_PERMISO) || DEcode(id_estado_permiso,30,' - Motivo: '|| cambia_acentos(motivo_denega),''),
                                 
                                 
                                    'id_anio' is pe.ID_ano,
                                'fecha_inicio' is
                                to_char(pe.fecha_inicio,
                                        'dd/mm/yyyy hh24:mi'),
                                'fecha_fin' is
                                to_char(pe.fecha_fin, 'dd/mm/yyyy hh24:mi'),
                              'numero_horas' is
                                trunc(pe.total_horas / 60) || ':' ||
                                lpad(mod(pe.total_horas, 60), 2, '0'),
                                'id_ausencia' is ID_ausencia,
                                 'firma en' is to_char(pe.fecha_js ,'dd/mm/yyyy'), 
                                'observaciones' is MOTIVO_DENEGA
                                ),pe.fecha_js
  from ausencia pe,
       tr_tipo_ausencia tr,
       personal_new p,
       personal_new je,TR_ESTADO_permiso tre,
       (select id_funcionario,
               id_delegado_js,
               id_js,
               ID_DELEGADO_FIRMA,
               id_delegado_js2,
               id_delegado_js3,
               id_delegado_js4
          from funcionario_firma
         where id_funcionario = i_id_funcionario) f
 WHERE  TRE.ID_ESTADO_permiso = pe.ID_ESTADO and ((id_estado in ('30') and
       firmado_js = i_id_funcionario) OR
       (id_estado in ('30') and firmado_js = f.id_delegado_js AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado in ('30') and firmado_js = f.id_js AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado in ('30') and firmado_js = f.id_delegado_js2 AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado in ('30') and firmado_js = f.id_delegado_js3 AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado in ('30') and firmado_js = f.id_delegado_js4 AND
       f.ID_DELEGADO_FIRMA = 1) OR
       (id_estado in ('31') and
       firmado_ja = i_id_funcionario))
   and tr.id_tipo_ausencia = pe.id_tipo_ausencia
   and pe.id_funcionario = p.id_funcionario
   and pe.firmado_js = je.id_funcionario
   and (pe.id_ANO > to_number(to_char(sysdate, 'yyyy')) - 2)
   and (
           
             (operacion || tipo = 'dau' and tr.id_tipo_AUSENCIA <> '998' ) OR
            (operacion || tipo = 'dfi' and tr.id_tipo_AUSENCIA = '998')
           )
 ORDER BY pe.fecha_js desc;
 
 
begin

  datos    := '';
  contador := 0;

  CASE operacion || tipo
  
  --Permisos pendientes
    WHEN 'ppe' THEN
      datos    := '';
      contador := 0;
      OPEN Cpermisos_pendientes;
      LOOP
        FETCH Cpermisos_pendientes
          into datos_tmp, d_fecha;
        EXIT WHEN Cpermisos_pendientes%NOTFOUND;
      
        contador := contador + 1;
      
        if contador = 1 then
          datos := datos_tmp;
        else
          datos := datos || ',' || datos_tmp;
        end if;
      
      END LOOP;
      CLOSE Cpermisos_pendientes;
    
      Resultado := '{"permisos_pendientes": [' || datos || ']}';
    
    WHEN 'pau' THEN
      --ausencias pendientes    
      datos    := '';
      contador := 0;
      OPEN Causencias_pendientes;
      LOOP
        FETCH Causencias_pendientes
          into datos_tmp, d_fecha;
        EXIT WHEN Causencias_pendientes%NOTFOUND;
      
        contador := contador + 1;
      
        if contador = 1 then
          datos := datos_tmp;
        else
          datos := datos || ',' || datos_tmp;
        end if;
      
      END LOOP;
      CLOSE Causencias_pendientes;
    
      Resultado := '{"ausencias_pendientes": [' || datos || ']}';
      
    WHEN 'pfi' THEN
      --fichajes pendientes    
      datos    := '';
      contador := 0;
      OPEN Causencias_pendientes;
      LOOP
        FETCH Causencias_pendientes
          into datos_tmp, d_fecha;
        EXIT WHEN Causencias_pendientes%NOTFOUND;
      
        contador := contador + 1;
      
        if contador = 1 then
          datos := datos_tmp;
        else
          datos := datos || ',' || datos_tmp;
        end if;
      
      END LOOP;
      CLOSE Causencias_pendientes;
    
      Resultado := '{"fichajes_pendientes": [' || datos || ']}';
      
      
      --Permisos autorizados
    WHEN 'ape' THEN
      datos    := '';
      contador := 0;
      OPEN Cpermisos_autorizados;
      LOOP
        FETCH Cpermisos_autorizados
          into datos_tmp, d_fecha;
        EXIT WHEN Cpermisos_autorizados%NOTFOUND;
      
        contador := contador + 1;
      
        if contador = 1 then
          datos := datos_tmp;
        else
          datos := datos || ',' || datos_tmp;
        end if;
      
      END LOOP;
      CLOSE Cpermisos_autorizados;
    
      Resultado := '{"permisos_autorizados": [' || datos || ']}';
     
      --Ausencias autorizados
    WHEN 'aau' THEN
      datos    := '';
      contador := 0;
      OPEN Causencias_autorizas;
      LOOP
        FETCH Causencias_autorizas
          into datos_tmp, d_fecha;
        EXIT WHEN Causencias_autorizas%NOTFOUND;
      
        contador := contador + 1;
      
        if contador = 1 then
          datos := datos_tmp;
        else
          datos := datos || ',' || datos_tmp;
        end if;
      
      END LOOP;
      CLOSE Causencias_autorizas;
    
      Resultado := '{"ausencias_autorizadas": [' || datos || ']}';
      
       --Fichajes autorizados
    WHEN 'afi' THEN
      datos    := '';
      contador := 0;
      OPEN Causencias_autorizas;
      LOOP
        FETCH Causencias_autorizas
          into datos_tmp, d_fecha;
        EXIT WHEN Causencias_autorizas%NOTFOUND;
      
        contador := contador + 1;
      
        if contador = 1 then
          datos := datos_tmp;
        else
          datos := datos || ',' || datos_tmp;
        end if;
      
      END LOOP;
      CLOSE Causencias_autorizas;
    
      Resultado := '{"fichajes_autorizados": [' || datos || ']}'; 
     
         --Permisos denegados
    WHEN 'dpe' THEN
      datos    := '';
      contador := 0;
      OPEN Cpermisos_denegados;
      LOOP
        FETCH Cpermisos_denegados
          into datos_tmp, d_fecha;
        EXIT WHEN Cpermisos_denegados%NOTFOUND;
      
        contador := contador + 1;
      
        if contador = 1 then
          datos := datos_tmp;
        else
          datos := datos || ',' || datos_tmp;
        end if;
      
      END LOOP;
      CLOSE Cpermisos_denegados;
    
      Resultado := '{"permisos_denegados": [' || datos || ']}';
      
    --Ausencias denegadas
    WHEN 'dau' THEN
      datos    := '';
      contador := 0;
      OPEN Causencias_denegadas;
      LOOP
        FETCH Causencias_denegadas
          into datos_tmp, d_fecha;
        EXIT WHEN Causencias_denegadas%NOTFOUND;
      
        contador := contador + 1;
      
        if contador = 1 then
          datos := datos_tmp;
        else
          datos := datos || ',' || datos_tmp;
        end if;
      
      END LOOP;
      CLOSE  Causencias_denegadas;
    
      Resultado := '{"ausencias_denegadas": [' || datos || ']}';
      
       --fichajes denegadas
    WHEN 'dfi' THEN
      datos    := '';
      contador := 0;
      OPEN Causencias_denegadas;
      LOOP
        FETCH Causencias_denegadas
          into datos_tmp, d_fecha;
        EXIT WHEN Causencias_denegadas%NOTFOUND;
      
        contador := contador + 1;
      
        if contador = 1 then
          datos := datos_tmp;
        else
          datos := datos || ',' || datos_tmp;
        end if;
      
      END LOOP;
      CLOSE  Causencias_denegadas;
    
      Resultado := '{"fichajes_denegados": [' || datos || ']}';
    
  END CASE;

  return(Resultado);
end;
/

