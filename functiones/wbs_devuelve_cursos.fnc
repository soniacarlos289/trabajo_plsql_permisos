create or replace function rrhh.wbs_devuelve_cursos(i_id_funcionario IN VARCHAR2,
                                               v_opcion         in number,
                                               v_id_año            in varchar2)
return clob is
  -- devuelve permiso y fichajes del servicio
  --v_opcion 0 ---> catalogo
  --v_opcion XXXXXX ---> Detalle curso
  --v_opcion 3 ---> cursos usuario
  --
 Resultado clob;
  observaciones varchar2(12000);

  saldo_horario       varchar2(123);
  fichaje_teletrabajo varchar2(123);
  firma_planificacion varchar2(123);
   datos    clob;
      datos_tmp    clob;
     
  contador            number;
  i_mes               number;
  i_anio              number;

  d_id_dia            date;
  v_id_funcionario_tt varchar2(123);
  v_desc_permiso_tt   varchar2(123);
  v_nombres_tt        varchar2(123);
  v_anio              varchar2(123);
  v_id_curso          varchar2(123);
opciones_menu_curso  varchar2(12311);
  d_datos_fecha_entrada date;
  --Catalogo de cursos   
  CURSOR Ccursos_catalogo is
    select  distinct json_object('id_anio' is substr(id_curso, 1, 4),
                       'id_curso' is id_curso,
                        'desc_curso' is cambia_acentos(desc_curso),
                        'desc_materia' is cambia_acentos(desc_materia),
                       'horas' is num_horas,
                      /* 'horas_presencial' is horas_presencial,
                       'horas_distancia' is horas_distancia,
                        'requisitos' is TRANSLATE(REGEXP_REPLACE(requisitos, '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''), 
                                       'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC '),
                       'contenido' is TRANSLATE(REGEXP_REPLACE(contenido, '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''), 
                                       'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC '),
                       'objetivo' is  TRANSLATE(REGEXP_REPLACE(objetivo, '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''), 
                                       'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC '),
                       'observaciones' is TRANSLATE(REGEXP_REPLACE(observaciones, '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''), 
                                       'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC '),
                       'solicitudes' is solicitudes,
                       'num_convocatorias' is num_convocatorias,
                       'version_convocatorias' is version_convocatorias,
                       'plazas_curso' is plazas_curso,*/
                       'calendario' is calendario,
                      /* 'estado_convocatoria' is estado_convocatoria,*/
                       'inscrito' is decode(t.estadosoli,null,0,1),
                       'estado_solicitud' is decode(t.estadosoli,null,null,tr.desc_estado_sol_curso)
                         ),
           id_curso
      from CURSO_SAVIA c, CURSO_SAVIA_SOLICITUDES t ,tr_Estado_sol_curso tr
     where --c.id_curso = v_opcion and
           c.id_curso=t.codicur(+) and 
           estadosoli=tr.id_estado_sol_curso(+) and UPPER(replace(c.estado_convocatoria,'ó','o'))='SELECCION' and
           substr(id_curso, 1, 4)=v_id_año and t.codiempl(+)=i_id_funcionario
           order by id_curso;
           

  --Detalle de un curso
  CURSOR CDetalle_curso is
    select  distinct json_object('id_anio' is substr(id_curso, 1, 4),
                       'id_curso' is id_curso,
                       'desc_curso' is cambia_acentos(desc_curso),
                       'desc_materia' is cambia_acentos(desc_materia),
                       'horas' is num_horas,
                       'horas_presencial' is horas_presencial,
                       'horas_distancia' is horas_distancia,
                       'requisitos' is cambia_acentos(requisitos),
                  --     'contenido' is cambia_acentos(replace(contenido,'"','')),
                         'contenido' is TRANSLATE(REGEXP_REPLACE(cambia_acentos(contenido), '[^A-Za-z0-9;.ÁÉÍÓÚáéíóú ]', ''), 
                                       'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC '),
                       
                       
                       'objetivo' is   TRANSLATE(REGEXP_REPLACE(cambia_acentos(objetivo), '[^A-Za-z0-9;.ÁÉÍÓÚáéíóú ]', ''), 
                                       'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ ', 
                                       'naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC '),
                       'observaciones' is cambia_acentos(observaciones),
                       'solicitudes' is cambia_acentos(solicitudes),
                       'num_convocatorias' is num_convocatorias,
                       'version_convocatorias' is version_convocatorias,
                       'plazas_curso' is plazas_curso,
                       'calendario' is cambia_acentos(calendario),
                       'estado_convocatoria' is estado_convocatoria,
                       'inscrito' is decode(t.estadosoli,null,0,1),
                       'estado_solicitud' is decode(t.estadosoli,null,null,tr.desc_estado_sol_curso)
                         ),
           id_curso
      from CURSO_SAVIA c, CURSO_SAVIA_SOLICITUDES t ,tr_Estado_sol_curso tr
     where c.id_curso = v_opcion and
           c.id_curso=t.codicur(+) and 
           estadosoli=tr.id_estado_sol_curso(+) and
           --substr(id_curso, 1, 4)=v_id_año and
           t.codiempl(+)=i_id_funcionario
           order by id_curso;
   

  CURSOR Ccursos_funcionario is
    select distinct json_object('id_anio' is substr(tc.id_curso, 1, 4),
                                'id_curso' is tc.id_curso,
                                'desc_curso' is  cambia_acentos(desc_curso),
                                'fecha_solicitud' is
                                to_char(fechasoli, 'DD/MM/YYYY'),
                                'estado solicitud' is
                                decode(estadosoli,
                                       'AP',
                                       'Aprobada',
                                       'RE',
                                       'Registrada',
                                       'PE',
                                       'Pendiente',
                                       'DE',
                                       'Denegada'),
                                'convocatoria' is versconv,
                                'horas' is horasist,
                                'diploma' is diploma,
                                'acto' is apto),
                    id_curso
    
      from CURSO_SAVIA_SOLICITUDES ts, CURSO_SAVIA  tc, personal_new p
     where p.id_funcionario = i_id_funcionario
       and lpad(ts.ndnisol, 9, '0') = lpad(p.dni, 9, '0')
       and ts.codiplan = v_id_año
       and horasist > 0
       and estadosoli <> 'OT'
       and ts.codicur = tc.id_curso(+);

begin

  datos                 := '';
  contador              := 0;
-- d_datos_fecha_entrada := to_date(v_fecha, 'DD/mm/yyyy');

  CASE v_opcion
  --v_opcion 0 --->catalogo
    WHEN '0' THEN
    
      --abrimos cursor.    
      OPEN Ccursos_catalogo;
      LOOP
        FETCH Ccursos_catalogo
          into datos_tmp, v_id_curso;
        EXIT WHEN Ccursos_catalogo%NOTFOUND;
      
        contador := contador + 1;
      
        if contador = 1 then
          datos := datos_tmp;
        else
          datos := datos || ',' || datos_tmp;
        end if;
      
      END LOOP;
      CLOSE Ccursos_catalogo;
    
      resultado := '{"catalogo_cursos": [' || datos || ']}';
    
  --v_opcion 2 ---> Cursos Usuario.
    WHEN '3' THEN
    
      --abrimos cursor.    
      OPEN Ccursos_funcionario;
      LOOP
        FETCH Ccursos_funcionario
          into datos_tmp,
              v_id_curso;
        EXIT WHEN Ccursos_funcionario%NOTFOUND;
      
        contador := contador + 1;
      
        if contador = 1 then
          datos := datos_tmp;
        else
          datos := datos || ',' || datos_tmp;
        end if;
      
      END LOOP;
      CLOSE Ccursos_funcionario;
      
      resultado := '{"curso_usuario": [' || datos || ']}';
      opciones_menu_curso:= '{"selector_id_ano": [{"id": 2025,"opcion_menu": "2025"},
                                                {"id": 2024,"opcion_menu": "2024"},
                                                {"id": 2023,"opcion_menu": "2023"},
                                                {"id": 2022,"opcion_menu": "2022"},
                                                {"id": 2021,"opcion_menu": "2021"},
                                                {"id": 2020,"opcion_menu": "2020"}]},';
          
        Resultado :=  opciones_menu_curso || Resultado ;
    
    ELSE
    
      --abrimos cursor.    
      OPEN CDetalle_curso;
      LOOP
        FETCH CDetalle_curso
          into datos_tmp, v_id_curso;
        EXIT WHEN CDetalle_curso%NOTFOUND;
      
        contador := contador + 1;
      
        if contador = 1 then
          datos := datos_tmp;
        else
          datos := datos || ',' || datos_tmp;
        end if;
      
      END LOOP;
      CLOSE CDetalle_curso;
  
      resultado := '{"detalle_curso": [' || datos || ']}';
    
  end case;
  

  return(Resultado);

end;
/

