create or replace procedure rrhh.ACTUALIZA_CURSOS(v_id_curso              in varchar2,
                                             V_desc_curso            in varchar2,
                                             v_desc_materia          in varchar2,
                                             v_num_horas             in varchar2,
                                             V_horas_presencial      in varchar2,
                                             V_horas_distancia       in varchar2,
                                             V_contenido             in varchar2,
                                             V_objetivo              in varchar2,
                                             V_requisitos            in varchar2,
                                             v_observaciones         in varchar2,
                                             v_solicitudes           in varchar2,
                                             v_num_convocatorias     in varchar2,
                                             v_version_convocatorias in varchar2,
                                             v_plazas_curso          in varchar2,
                                             V_calendario            in varchar2,
                                             V_estado_convocatoria in varchar2 ) is

  pos        integer;
  i_id_curso varchar2(15);

vv_num_horas              varchar2(15);
vv_horas_presencial       varchar2(15);
vv_horas_distancia      varchar2(15);
vv_num_convocatorias      varchar2(15);
vv_version_convocatorias  varchar2(15);
vv_plazas_curso           varchar2(15);


begin
  
vv_num_horas:=replace(replace(v_num_horas,'.00',''),'.',',');           
vv_horas_presencial:=replace(v_horas_presencial,'.00','');        
vv_horas_distancia:=replace(v_horas_distancia,'.00','');          
vv_num_convocatorias:=replace(v_num_convocatorias,'.00','');   
vv_version_convocatorias:=replace(v_version_convocatorias,'.00',''); 
vv_plazas_curso:=replace(v_plazas_curso,'.00','');        


if vV_num_horas = 'null' then vv_num_horas:=0; end if;
if   vv_horas_presencial = 'null' then vv_horas_presencial:=0; end if;
if   vv_horas_distancia  = 'null' then  vv_horas_distancia:=0; end if;
 if  vv_num_convocatorias  = 'null' then vv_num_convocatorias:=0; end if;
 if  vv_version_convocatorias  = 'null' then vv_version_convocatorias:= 0; end if;
 if vv_plazas_curso  = 'null' then vv_plazas_curso:=0;  end if;
   


  pos := 1;

  Begin
    select id_curso
      into  i_id_curso
      from CURSO_SAVIA C
     where c.id_curso = V_id_curso
       and rownum < 2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      pos := 0;
  End;
  insert into curso_actualizacion
    (id_curso, actualizado)
  values
    (v_id_curso, sysdate);
  

  if pos = 1 then
    update curso_savia
       set id_curso              = v_id_curso,
           desc_curso            = v_desc_curso,
           desc_materia          = v_desc_materia,
           num_horas             = vv_num_horas,
           horas_presencial      = vv_horas_presencial,
           horas_distancia       = vv_horas_distancia,
           contenido             = v_contenido,
           objetivo              = v_objetivo,
           requisitos            = v_requisitos,
           observaciones         = v_observaciones,
           solicitudes           = v_solicitudes,
           num_convocatorias     = vv_num_convocatorias,
           version_convocatorias = vv_version_convocatorias,
           plazas_curso          = vv_plazas_curso,
           calendario            = v_calendario,
           estado_convocatoria   = replace(v_estado_convocatoria,'ó','o')
     where id_curso = v_id_curso and id_curso >0
       and version_convocatorias = v_version_convocatorias
       and rownum < 2;
  
  else
    Begin
      insert into curso_savia
        (id_curso,
         desc_curso,
         desc_materia,
         num_horas,
         horas_presencial,
         horas_distancia,
         contenido,
         objetivo,
         requisitos,
         observaciones,
         solicitudes,
         num_convocatorias,
         version_convocatorias,
         plazas_curso,
         calendario,
         estado_convocatoria)
      values
        (v_id_curso,
         v_desc_curso,
         v_desc_materia,
         vv_num_horas,
         vv_horas_presencial,
         vv_horas_distancia,
         v_contenido,
         v_objetivo,
         v_requisitos,
         v_observaciones,
         v_solicitudes,
         vv_num_convocatorias,
         vv_version_convocatorias,
         vv_plazas_curso,
         v_calendario,
         replace(v_estado_convocatoria,'ó','o'));
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        pos := 0;
    END;
  
  end if;

  commit;
END ACTUALIZA_CURSOS;
/

