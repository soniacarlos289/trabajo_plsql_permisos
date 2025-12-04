create or replace function rrhh.wbs_devuelve_roles(i_id_funcionario IN VARCHAR2) return clob is
  Resultado clob;
    observaciones varchar2(12000);
      foto clob;
      saldo_horario varchar2(123);
      fichaje_teletrabajo varchar2(123);
      firma_planificacion varchar2(123);
      datos    varchar2(12000);
      v_desc_tipo_funcionario  varchar2(12000);
   begin   
      saldo_horario:='false';
      fichaje_teletrabajo:='false';
      firma_planificacion:='false';
   
     BEGIN
      select distinct decode(id_fichaje,null,'false','true') as fichaje,decode(firma,0,'false','true') firma  
      into saldo_horario, firma_planificacion
      from apliweb_usuario 
      where id_funcionario=i_id_funcionario
        and login not like 'adm%' and rownum < 2;   
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
          saldo_horario:='false';
          firma_planificacion:='false';
     WHEN OTHERS THEN                        
          saldo_horario:='false';
          firma_planificacion:='false';
     END;
     
     BEGIN
      select distinct  decode(teletrabajo,0,'false','true')  
      into fichaje_teletrabajo
      from funcionario_fichaje 
      where id_funcionario=i_id_funcionario
        and rownum < 2;   
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
          fichaje_teletrabajo:='false';
     WHEN OTHERS THEN                        
          fichaje_teletrabajo:='false';
     END;

     BEGIN
      select distinct desc_tipo_funcionario 
      into v_desc_tipo_funcionario
      from personal_new p, tr_tipo_funcionario tr
      where id_funcionario=i_id_funcionario and p.tipo_funcionario2=tr.id_tipo_funcionario
        and rownum < 2;   
     EXCEPTION
     WHEN NO_DATA_FOUND THEN
         v_desc_tipo_funcionario:='false';
     WHEN OTHERS THEN                        
          v_desc_tipo_funcionario:='false';
     END;

     select 
         distinct '"modulos": [' ||
         json_object('saldo_horario' is  saldo_horario,'firma_planificacion' is firma_planificacion,'fichaje_teletrabajo' is fichaje_teletrabajo
         ,'tipo_funcionario' is v_desc_tipo_funcionario
         )
         || ']'
         into datos         
     from dual;
       foto:= wbs_devuelve_fichero_foto(i_id_funcionario);
           
        resultado:=  datos ||  foto;    

   return(Resultado);
  end;
/

