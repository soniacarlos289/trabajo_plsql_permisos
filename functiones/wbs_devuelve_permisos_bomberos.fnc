create or replace function rrhh.wbs_devuelve_permisos_bomberos(i_id_funcionario IN VARCHAR2,
                                                               v_opcion         in number,
                                                               v_fecha          in varchar2)
  return clob is
  -- devuelve permiso y fichajes del servicio
  --v_opcion 0 ---> permisos planificador servicio disfrutados
  --v_opcion 1 ---> permisos servicio pendientes
  
  --
  Resultado    clob;
  observaciones varchar2(12000);

  saldo_horario       varchar2(123);
  fichaje_teletrabajo varchar2(123);
  firma_planificacion varchar2(123);
  datos              clob;
  datos_tmp           clob;
  contador            number;
  i_mes               number;
  i_anio              number;

  d_id_dia            date;
  v_id_funcionario_tt varchar2(123);
  v_nombres_tt        varchar2(123);
  v_desc_permiso_tt   varchar2(123);
  v_anio              varchar2(123);
  
  d_datos_fecha_entrada date;
  --Funcionarios en activo   
  CURSOR Cpermisos_servicio(fecha_entrada date) is
    select distinct  json_object('nombre' is SUBSTR(iNITCAP(Nombre) || ' ' ||
                                                   iNITcAP(ape1) || ' ' ||
                                                   initcap(ape2),
                                                   1,
                                                   22),
                                                  
                                'id_funcionario' is p.id_funcionario,
                                'id_dia' is to_char(desde,'dd/mm/yyyy'),
                                'turno_1_id_permiso' is DECODE(pe.id_funcionario,null, '99999', DEcode(pe.tu1_14_22,0,'99999',tr.id_tipo_permiso)),
                                'turno_1_desc_permiso' is DECODE(pe.id_funcionario,null, 'Guardia Bombero', DEcode(pe.tu1_14_22,0,'Guardia Bombero',tr.desc_tipo_permiso)),
                                'turno_2_id_permiso' is DECODE(pe.id_funcionario,null, '99999', DEcode(pe.tu2_22_06,0,'99999',tr.id_tipo_permiso)),
                                'turno_2_desc_permiso' is DECODE(pe.id_funcionario,null, 'Guardia Bombero', DEcode(pe.tu2_22_06,0,'Guardia Bombero',tr.desc_tipo_permiso)),
                                'turno_3_id_permiso' is DECODE(pe.id_funcionario,null, '99999', DEcode(pe.tu3_04_14,0,'99999',tr.id_tipo_permiso)),
                                'turno_3_desc_permiso' is DECODE(pe.id_funcionario,null, 'Guardia Bombero', DEcode(pe.tu3_04_14,0,'Guardia Bombero',tr.desc_tipo_permiso))
                                )
                                , desde,
                   
                
                    SUBSTR(iNITCAP(Nombre) || ' ' || iNITcAP(ape1) || ' ' ||
                           initcap(ape2),
                           1,
                           22) as nombres
    
   --    into I_ID_FUNCIONARIO, i_dotacion 
   from Bomberos_guardias_plani  bP, permiso pe ,(select id_funcionario, ape2, ape1, NOMBRE
          FROM personal_new f
         WHERE tipo_funcionario2 = 23
           and (fecha_baja is null or fecha_baja > sysdate))            p,tr_tipo_permiso tr
       where 
     SUBSTR(guardia,1,4) > 2023 AND TO_NUMBER(FUNCIONARIO) >10000
     and TO_DATE(TO_CHAR(desde,'DD/MM/YYYY'),'DD/MM/YYYY') between pe.fecha_inicio(+) and pe.fecha_fin(+)
     and TO_DATE(TO_CHAR(desde,'DD/MM/YYYY'),'DD/MM/YYYY') between fecha_entrada-1 and fecha_entrada+9
     and TO_NUMBER(FUNCIONARIO)=pe.id_funcionario(+)
     and TO_NUMBER(FUNCIONARIO)=p.id_funcionario
     and tr.id_tipo_permiso(+)=pe.id_tipo_permiso
     and tr.id_ano(+)=pe.id_ano
     order by nombres,desde;

   
    
begin

  datos    := '';
  contador := 0;
  d_datos_fecha_entrada:=to_date( v_fecha ,'DD/mm/yyyy');
  
 CASE v_opcion
        --v_opcion 0 ---> permisos servicio disfrutados
        WHEN '0' THEN
  

    --abrimos cursor.    
    OPEN Cpermisos_servicio(d_datos_fecha_entrada);
    LOOP
      FETCH Cpermisos_servicio
        into datos_tmp,
             d_id_dia,             
             v_nombres_tt;
      EXIT WHEN Cpermisos_servicio%NOTFOUND;
    
      contador := contador + 1;
    
      if contador = 1 then
        datos := datos_tmp;
      else
        datos := datos || ',' || datos_tmp;
      end if;
    
    END LOOP;
    CLOSE Cpermisos_servicio;
  
    resultado := '{"permisos_servicio": [' || datos || ']}';
  
  
  end case;

  return(Resultado);

end;
/

