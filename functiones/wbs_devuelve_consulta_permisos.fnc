create or replace function rrhh.wbs_devuelve_consulta_permisos(i_id_funcionario IN VARCHAR2,
                                                          opcion           in varchar2,
                                                          anio             in number)
  return clob is
  --opcion
  --121312 id_permiso
  -- 0 per_solicitados permisos_solicitados.
  -- 1 per_pendientes permisos pendientes.
  -- sp solo pendiente de disfrutar
  Resultado clob;

  datos_permisos_solicitados   clob;
  datos_permisos_sin_disfrutar clob;
  saldo_horario                varchar2(123);
  cabecera_periodos_consulta   varchar2(12300);
  d_fecha                      date;
  datos                        clob;
  datos_tmp                    clob;
  contador                     number;
  i_permiso                    number;
opciones_menu_permisos varchar2(12300);
v_id_Ano  varchar2(123);
v_id_tipo_permiso  varchar2(123);
v_id_ordenar varchar2(123);
  Cursor Cgrado is
    select distinct json_object('id' is t.id_grado,
                                'opcion_menu' is cambia_Acentos(t.desc_grado)),id_grado
      FROM tr_grado t
     order by 2;

  --permisos solicitados   
  CURSOR Cpermisos_solicitados is
    SELECT distinct decode(opcion,
                           0,
                           json_object('id_anio' is a.ID_ano,
                                       'id_permiso' is ID_PERMISO,
                                       'tipo_permiso' is
                                       
                                                                                                        cambia_acentos(B.DESC_TIPO_PERMISO),
                                       
                                       'id_tipo_permiso' is a.id_tipo_permiso,
                                       'estado' is  cambia_acentos(DESC_ESTADO_PERMISO) || DEcode(id_estado_permiso,30,' - Motivo: '|| cambia_acentos(motivo_denega),''),
                                       'id_estado_permiso' is t.id_estado_permiso ,
                                       'fecha_inicio' is
                                       to_char(a.FECHA_INICIO, 'dd/mm/yyyy') || 
                                       DECODE(a.ID_TIPO_PERMISO,
                                              '15000',
                                              ' ' || hora_inicio,
                                              ''),
                                       'fecha_fin' is
                                       to_char(A.FECHA_FIN, 'dd/mm/yyyy') || 
                                       DECODE(a.ID_TIPO_PERMISO,
                                              '15000',
                                              ' ' || hora_fin,
                                              ''),
                                       'justificado' is
                                       DECODE(a.JUSTIFICACION,
                                              '--',
                                              '',
                                              CHEQUEA_ENLACE_FICHERO_JUSTI(a.ID_ANO,
                                                                         a.ID_FUNCIONARIO,
                                                                         ID_PERMISO
                                                                         ))),
                           
                           json_object('id_anio' is a.ID_ano,
                                       'id_permiso' is ID_PERMISO,
                                       'tipo_permiso' is
                                                                  cambia_acentos(B.DESC_TIPO_PERMISO),
                                        'id_tipo_permiso' is a.id_tipo_permiso,
                                       
                                         'estado' is  cambia_acentos(DESC_ESTADO_PERMISO) || DEcode(id_estado_permiso,30,' - Motivo: '|| cambia_acentos(motivo_denega),''),
                                    
                                       
                                       'id_estado_permiso' is t.id_estado_permiso,
                                       'motivo_denega' is
                                       DECODE(motivo_denega, null, ''),
                                       'fecha_inicio' is
                                       to_char(a.FECHA_INICIO, 'dd/mm/yyyy') || 
                                       DECODE(a.ID_TIPO_PERMISO,
                                              '15000',
                                              ' ' || hora_inicio,
                                              ''),
                                       'fecha_fin' is
                                       to_char(A.FECHA_FIN, 'dd/mm/yyyy') || 
                                       DECODE(a.ID_TIPO_PERMISO,
                                              '15000',
                                              ' ' || hora_fin,
                                              ''),
                                       'justificado' is
                                       DECODE(a.JUSTIFICACION,
                                              '--',
                                              '',
                                              CHEQUEA_ENLACE_FICHERO_JUS(a.ID_ANO,
                                                                         a.ID_FUNCIONARIO,
                                                                         ID_PERMISO,
                                                                         a.id_estado,
                                                                         'P',
                                                                         1)),
                                       'grado' is desc_grado,
                                       'turno_1' is tu1_14_22,
                                       'turno_2' is tu2_22_06,
                                       'turno_3' is tu3_04_14,
                                       'num_dias' is A.NUM_DIAS,
                                       'distinca_provincia' is
                                       DECODE(DPROVINCIA, 'NO', ''),
                                       'hora_inicial' is
                                       DECODE(a.ID_TIPO_PERMISO,
                                              '15000',
                                              hora_inicio,
                                              ''),
                                       'hora_fin' is DECODE(a.ID_TIPO_PERMISO,
                                                            '15000',
                                                            hora_fin,
                                                            ''),
                                       'total_horas' is
                                       DECODE(a.ID_TIPO_PERMISO,
                                              '15000',
                                              total_horas,
                                              ''),
                                       'firma_jefe_servicio_firmado' is
                                       decode(nvl(a.firmado_js, ''),
                                              '',
                                              'Pendiente firma',
                                              TO_CHAR(a.fecha_js, 'DD/MM/YYYY')),
                                       'firma_jefe_area_firmado' is
                                       DECODE(pe.tipo_funcionario2,
                                              23,
                                              decode(nvl(a.firmado_ja, ''),
                                                     '',
                                                     'Pendiente firma Jefe Area',
                                                     TO_CHAR(a.fecha_ja,
                                                             'DD/MM/YYYY')),
                                              'Solo firma Jefe de Servicio'),
                                       'visto_bueno_rrhh' is
                                       decode(nvl(a.firmado_rrhh, ''),
                                              '',
                                              'Pendiente VB RRHH',
                                              TO_CHAR(a.fecha_rrhh,
                                                      'DD/MM/YYYY'))))
                    
                   ,
                    a.FECHA_INICIO
      FROM PERMISO           A,
           TR_TIPO_PERMISO   B,
           TR_ESTADO_PERMISO T,
           tr_grado          G,
           personal_new          pe
     WHERE A.ID_FUNCIONARIO = i_id_funcionario
       and (A.ID_PERMISO = opcion or opcion = '0')
       AND (A.ID_ANO >= anio )
       and a.id_funcionario = pe.id_funcionario
       and a.id_grado = g.id_Grado(+)
       AND (A.ANULADO = 'NO' OR a.ANULADO IS NULL)
       and t.id_ESTADO_permiso = a.id_EStado
       AND A.ID_TIPO_PERMISO = B.ID_TIPO_PERMISO
       AND A.ID_ANO = B.ID_ANO
     ORDER BY a.FECHA_INICIO DESC;
  --         ORDER BY a.FECHA_INICIO DESC;

  CURSOR Cpermisos_pendientes is
    SELECT /*+ ORDERED*/
    distinct A.ID_TIPO_PERMISO,
             json_object('id_anio' is a.id_ano,
                         'id_tipo_permiso' is A.ID_TIPO_PERMISO,
                         'desc_permiso' is   'Permisos del ' || a.id_ano  || '-' ||
                                cambia_acentos(B.DESC_TIPO_PERMISO)
                         
                         ,
                         'num_dias' is A.NUM_DIAS,
                         'seccion_tipo_dias' is  decode( a.id_tipo_permiso,'01000', decode(   A.NUM_DIAS ,31,'true','false'),'false'),
                        'seccion_grado' is  decode( a.id_tipo_permiso,'04000', 'true','04500', 'true','false'),
                       'seccion_distinta_provincia' is  decode( a.id_tipo_permiso,'04000', 'true','04500', 'true','06100', 'true','false'),
                       'seccion_hora' is  decode( a.id_tipo_permiso,'02031', 'true','15000', 'true','false'),
                       'seccion_turnos' is DECODE(tipo_funcionario2,'23',DECODE(a.id_tipo_permiso,'01000','false',
                                '15000','false',
                                '02031','false',
                                'true'),'false'),
 
                        'seccion_justificacion' is DECODE(b.justificacion,'--','false','true')),a.id_Ano,a.id_tipo_permiso as tipo_permiso,0 as ordenar
      FROM PERMISO_FUNCIONARIO A,personal_new p,
           TR_TIPO_PERMISO     B,
           
           (select distinct id_permiso,
                            id_ano,
                            id_funcionario,
                            id_tipo_permiso,
                            id_estado,
                            fecha_soli,
                            firmado_js,
                            fecha_js,
                            firmado_ja,
                            fecha_ja,
                            firmado_rrhh,
                            fecha_rrhh,
                            fecha_inicio,
                            fecha_fin,
                            num_dias,
                            hora_inicio,
                            hora_fin,
                            id_tipo_dias,
                            dprovincia,
                            id_grado,
                            justificacion,
                            observaciones,
                            anulado,
                            fecha_anulacion,
                            id_usuario,
                            fecha_modi,
                            motivo_denega,
                            total_horas,
                            tu1_14_22,
                            tu2_22_06,
                            tu3_04_14,
                            tipo_baja,
                            descuento_bajas,
                            descuento_dias
              FROM PERMISO
             where id_estado not in ('30', '31', '32', '40', '41')) C
     WHERE 
           ((A.ID_ANO = to_char(sysdate+25,'yyyy') AND A.UNICO = 'SI') OR
           (opcion = 'sp' and A.ID_ANO = to_char(sysdate+25,'yyyy')) OR
           ((A.ID_ANO = to_char(sysdate+25,'yyyy') - 1 AND A.UNICO = 'SI')))
       AND A.ID_FUNCIONARIO = i_id_funcionario
       AND A.NUM_DIAS > 0
       AND p.id_funcionario = a.id_funcionario
       AND A.ID_TIPO_PERMISO = B.ID_TIPO_PERMISO
       AND A.ID_ANO = B.ID_ANO
       AND a.ID_ANO = C.id_ano(+)
       AND A.ID_FUNCIONARIO = C.id_FUNCIONARIO(+)
       AND A.ID_TIPO_PERMISO = C.id_TIPO_PERMISO(+)
       AND UPPER(DESC_TIPO_PERMISO) NOT LIKE '%ANTERIOR%'
       and a.id_tipo_permiso not in ('01500', '01500')
       and ((a.id_tipo_permiso not in ('15001', '03000') and
           a.ID_funcionario not like '203%') OR
           (a.id_tipo_permiso not in ('15001', '03000') and
           a.ID_funcionario not like '201%') OR
           (a.id_tipo_permiso in ('15001', '03000') and
           a.id_funcionario not like '203%' and
           a.id_funcionario not like '201%'))
    
    union      
    SELECT  distinct ID_TIPO_AUSENCIA as  ID_TIPO_PERMISO,                 
 json_object(
             'id_anio' is id_ano,
                         'id_tipo_permiso' is id_tipo_ausencia,
                         'desc_permiso' is   'Ausencias -' ||
                         cambia_acentos(desc_tipo_ausencia),
                         
                         
                         'num_dias' is 0,
                         'seccion_tipo_dias' is  'false',
                        'seccion_grado' is  'false',
                       'seccion_distinta_provincia' is  'false',
                       'seccion_hora' is   'true',
                       'seccion_turnos' is 'false',
                       'seccion_justificacion' is DECODE(justificacion,'--','false','true')),id_Ano as id_anos,id_tipo_ausencia as tipo_permiso,1 as ordenar
             
             
             from
   
(     SELECT id_tipo_ausencia, desc_tipo_ausencia,to_number(to_char(sysdate,'YYYY')) as id_ano,'SI' as justificacion
  from tr_tipo_ausencia 
 where id_tipo_ausencia < 500
   and id_tipo_ausencia <> '050'
   and id_tipo_ausencia > 0 and id_tipo_ausencia <> '998'
union
select t.id_tipo_ausencia,
       desc_tipo_ausencia || '. Horas Disponibles este año: ' ||
       trunc((Total - utILIZADAs) / 60, 2) || ' h.' as desc_tipo_ausencia,to_number(to_char(sysdate,'YYYY')) as id_ano,'SI' as justificacion
  FROM bolsa_concilia h, tr_tipo_ausencia t
 WHERE id_funcionario =i_id_funcionario
   and '050' = t.id_tipo_ausencia 
   and h.ID_ANO=to_char(sysdate,'YYYY') 
   and tr_ANULADO = 'NO'
union
select t.id_tipo_ausencia,
       desc_tipo_ausencia || 'Horas Disponibles este mes: ' ||
       trunc((Total_HORAS - TOTAL_UTILIZADAs) / 60, 2) || 'h.' as desc_tipo_ausencia,to_number(to_char(sysdate,'YYYY')) as id_ano,'--' as justificacion
  FROM hora_sindical h, tr_tipo_ausencia t
 WHERE id_funcionario = i_id_funcionario
   and h.id_tipo_ausencia = t.id_tipo_ausencia
   and id_mes = to_number(to_char(sysdate, 'mm'))
   and h.ID_ANO =to_char(sysdate,'YYYY')
   and tr_ANULADO = 'NO'
)
    
     ORDER BY ordenar,id_ano asc,tipo_permiso;

begin

  datos    := '';
  contador := 0;
  --abrimos cursor.    

  if opcion <> 'sp' then
    OPEN Cpermisos_solicitados;
    LOOP
      FETCH Cpermisos_solicitados
        into datos_tmp, d_fecha;
      EXIT WHEN Cpermisos_solicitados%NOTFOUND;
    
      contador := contador + 1;
    
      if contador = 1 then
        datos := datos_tmp;
      else
        datos := datos || ',' || datos_tmp;
      end if;
    
    END LOOP;
    CLOSE Cpermisos_solicitados;
  end if;
  if opcion = '0' then
    datos_permisos_solicitados := '{"permisos_solicitados": [' || datos || ']}';
    cabecera_periodos_consulta := '{"periodos_consulta_anio":[2025,2024]},';
  else
    datos_permisos_solicitados := datos;
    cabecera_periodos_consulta := '';
  end if;

  datos    := '';
  contador := 0;

  OPEN Cpermisos_pendientes;
  LOOP
    FETCH Cpermisos_pendientes
      into i_permiso, datos_tmp,v_id_Ano,v_id_tipo_permiso,v_id_ordenar;
    EXIT WHEN Cpermisos_pendientes%NOTFOUND;
  
    contador := contador + 1;
  
    if contador <= anio then
      if contador = 1 then
        datos := datos_tmp;
      else
        datos := datos || ',' || datos_tmp;
      end if;
    end if;
  
  END LOOP;
  CLOSE Cpermisos_pendientes;

  if opcion = '0' then
    datos_permisos_sin_disfrutar := '{"permisos_pendientes_disfrutar": [' ||
                                    datos || ']}';
    resultado                    := cabecera_periodos_consulta ||
                                    datos_permisos_solicitados || ',' ||
                                    datos_permisos_sin_disfrutar;
  else
    if opcion = '1' then
      datos_permisos_sin_disfrutar := '{"permisos_disponibles_solicitar": [' ||
                                      datos || ']}';
      resultado                    := datos_permisos_sin_disfrutar;
    
    else
      
    
      if opcion = 'sp' then
       Resultado := '{"permisos_pendientes_disfrutar": [' || datos || ']}'; 
       datos    := '';
       contador := 0; 
        OPEN Cgrado;
        LOOP
          FETCH Cgrado
            into  datos_tmp,i_permiso;
          EXIT WHEN Cgrado%NOTFOUND;
        
          contador := contador + 1;
        
          if contador <= anio then
            if contador = 1 then
              datos :=     '{"selector_grado":[' || datos_tmp ; 
            else
              datos := datos || ',' || datos_tmp;
            end if;
          end if;
        
        END LOOP;
        CLOSE Cgrado;
          datos:= datos  || ']},';
          
        opciones_menu_permisos:= '{"selector_tipo_dias": [{"id": 1,"opcion_menu": "LABORAL"},{"id": 2,"opcion_menu": "NATURAL"}]},' || 
                                 '{"selector_distinta_provincia": [{"id": 1,"opcion_menu": "NO"},{"id": 2,"opcion_menu": "SI"}]},' ||
                                 '{"combo_turno_bomberos": [{"id": 1,"opcion_menu": "turno 1 08:00 a 16:00"},' ||
                               '{"id": 2,"opcion_menu": "turno 2 16:00 a 00:00"},' ||
                               '{"id": 3,"opcion_menu": "turno 3 00:00 a 08:00"}]},';
          
        Resultado :=  opciones_menu_permisos || datos || Resultado ;
      else
        Resultado := '{"permiso_detalle": [' || datos_permisos_solicitados || ']}';
      end if;
    end if;
  end if;

  return(Resultado);
end;
/

