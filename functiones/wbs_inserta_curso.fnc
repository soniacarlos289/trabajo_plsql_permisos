create or replace function rrhh.wbs_inserta_curso(v_id_funcionario IN VARCHAR2,v_id_curso in VARCHAR2,
                                              v_opcion          in VARCHAR2)
  return varchar2 is
  Resultado     varchar2(12000);
  observaciones varchar2(12000);
  contador      number;
--v_opcion 0 inscribe curso
--v_opcion 1 anula curso
begin
  observaciones := 'nulo'; 
  contador := 1;

  --Buscamoe el curso
  BEGIN
     Select            codicur
     into contador
      from  CURSO_SAVIA_SOLICITUDES t ,tr_Estado_sol_curso tr
     where v_id_curso=t.codicur and 
           estadosoli=tr.id_estado_sol_curso and
           codiempl=v_id_funcionario and rownum <2;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
        contador := 0;
  END;

  If v_opcion = 0 then
    if contador =0 then
  
       insert into CURSO_SAVIA_SOLICITUDES
         (codicur,  estadosoli, fechasoli,codiempl)
       values
         ( v_id_curso,  'PE', sysdate,v_id_funcionario);
             observaciones := 'Inscripcion completada';        
      else 
                 observaciones := 'Operacion no completada, ya estas inscrito';
      end if;
  end if; 
  If v_opcion = 1 then
    if contador >0 then
  
       delete CURSO_SAVIA_SOLICITUDES where
       v_id_curso=codicur and     codiempl=v_id_funcionario and rownum <2; 
         
             observaciones := 'Anulacion completada';        
      else 
                 observaciones := 'Operacion no completada, no estas inscrito';
      end if;
  end if;  
  
 if V_opcion = null then
          observaciones := 'Operacion no completada, curso no existe';
 
 end if; 
  commit;
  resultado := observaciones;
  return(Resultado);
end;
/

