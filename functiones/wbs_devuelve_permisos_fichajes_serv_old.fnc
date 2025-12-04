create or replace function rrhh.wbs_devuelve_permisos_fichajes_serv_OLD(i_id_funcionario IN VARCHAR2,
                                                               v_opcion         in number,
                                                               v_fecha          in varchar2)
  return clob is
  -- devuelve permiso y fichajes del servicio
  --v_opcion 0 ---> permisos servicio disfrutados
  --v_opcion 1 ---> permisos servicio pendientes
  --v_opcion 2 ---> fichajes
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
    SELECT DISTINCT json_object('nombre' is SUBSTR(iNITCAP(Nombre) || ' ' ||
                                                   iNITcAP(ape1) || ' ' ||
                                                   initcap(ape2),
                                                   1,
                                                   22),
                                                   
                                'id_funcionario' is p.id_funcionario,
                                 'id_dia' is to_char(cl.id_dia,'dd/mm/yyyy'),
                                'id_tipo_permiso' is pes.id_tipo_permiso,
                                'desc_tipo_permiso' is (select distinct desc_tipo_permiso from    tr_tipo_permiso   where id_tipo_permiso = pes.id_tipo_permiso and rownum<2) 
                                ),
                    id_dia,
                   
                
                    SUBSTR(iNITCAP(Nombre) || ' ' || iNITcAP(ape1) || ' ' ||
                           initcap(ape2),
                           1,
                           22) as nombres
    
      FROM personal_new           p,
           permiso            pes,
     
           calendario_laboral cl
     where  
       cl.id_dia between fecha_entrada and fecha_entrada+30           
       and cl.id_dia between pes.fecha_inicio(+) and pes.fecha_fin(+)
       and p.id_funcionario = pes.id_funcionario(+)
     --  and tr_p.id_tipo_permiso = pes.id_tipo_permiso
       and
          
           p.id_funcionario in
          
           (select distinct p.id_funcionario
              from (select id_js
                      from funcionario_firma
                     where id_funcionario = 101217) ff,
                   personal_new p,
                   funcionario_firma ff2
             where (id_delegado_ja = ff.id_js or ff2.id_js = ff.id_js or
                   id_delegado_js = ff.id_js or id_delegado_js2 = ff.id_js or
                   id_delegado_js3 = ff.id_js or id_delegado_js4 = ff.id_js or
                   id_ja = ff.id_js or id_ver_plani_1 = ff.id_js or
                   id_ver_plani_2 = ff.id_js or id_ver_plani_3 = ff.id_js)
               and ff2.id_funcionario = p.id_funcionario
               and (p.fecha_fin_contrato is null or
                   p.fecha_fin_contrato > sysdate))
    
     order by nombres, id_dia;

  --Fichajes servicio
  CURSOR Cfichajes_Servicio(fecha_entrada date) is
    
    SELECT DISTINCT json_object(   
    
    
    'nombre' is SUBSTR(iNITCAP(Nombre) || ' ' ||
                                                   iNITcAP(ape1) || ' ' ||
                                                   initcap(ape2),
                                                   1,
                                                   22),
                                'id_funcionario' is p.id_funcionario,
                                'id_dia' is to_char(id_dia, 'dd/mm/yyyy'),
                                 'fecha_entrada' is to_char(ff.fecha_fichaje_entrada,'hh24:mi'),
                                 'fecha_salida' is to_char(ff.fecha_fichaje_salida,'hh24:mi')),
                                 --||  wbs_a_devuelve_fichaje_permiso(p.id_funcionario,id_dia)
                              ff.fecha_fichaje_entrada,SUBSTR(iNITCAP(Nombre) || ' ' ||
                                                   iNITcAP(ape1) || ' ' ||
                                                   initcap(ape2),
                                                   1,
                                                   22) as nombres
      FROM personal_new p,
           calendario_laboral cl,fichaje_funcionario ff
           
     where cl.id_dia    between to_date('04/05/2024','dd/mm/yyyy')-7 and to_date('04/05/2024','dd/mm/yyyy') and 
           ff.id_funcionario=p.id_funcionario and to_Date(to_char( ff.fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy')=cl.id_dia and         
           p.id_funcionario in
          
           (select distinct p.id_funcionario
              from (select id_js
                      from funcionario_firma
                     where id_funcionario = 101217) ff,
                   personal_new p,
                   funcionario_firma ff2
             where (id_delegado_ja = ff.id_js or ff2.id_js = ff.id_js or
                   id_delegado_js = ff.id_js or id_delegado_js2 = ff.id_js or
                   id_delegado_js3 = ff.id_js or id_delegado_js4 = ff.id_js or
                   id_ja = ff.id_js or id_ver_plani_1 = ff.id_js or
                   id_ver_plani_2 = ff.id_js or id_ver_plani_3 = ff.id_js)
               and ff2.id_funcionario = p.id_funcionario
               and (p.fecha_fin_contrato is null or
                   p.fecha_fin_contrato > sysdate))
    
     order by nombres,ff.fecha_fichaje_entrada;
   
  CURSOR Cpermisos_pend_Servicio(anio varchar2) is
      SELECT DISTINCT json_object('nombre' is SUBSTR(iNITCAP(Nombre) || ' ' ||
                                                   iNITcAP(ape1) || ' ' ||
                                                   initcap(ape2),
                                                   1,
                                                   22),
                                                   
                                'id_funcionario' is p.id_funcionario,
                                 'id tipo permiso' is ff.id_tipo_permiso,
                                 'desc permiso' is desc_tipo_permiso,
                                 'numero dias' is ff.num_dias)
                             --   'id_tipo_permiso' is pes.id_tipo_permiso,
                             --   'desc_tipo_permiso' is (select distinct desc_tipo_permiso from    tr_tipo_permiso   where id_tipo_permiso = pes.id_tipo_permiso and rownum<2) 
                            ,
                    ff.id_tipo_permiso,
                
                    SUBSTR(iNITCAP(Nombre) || ' ' || iNITcAP(ape1) || ' ' ||
                           initcap(ape2),
                           1,
                           22) as nombres
    
      FROM personal_new           p,
         --  permiso            pes,
           permiso_funcionario ff,
           tr_tipo_permiso tr
           
     where  
           p.id_funcionario = ff.id_funcionario and ff.unico='SI' and ff.num_dias>0
          and ff.id_ano=2024 and 
          ff.id_ano=tr.id_ano and
           tr.id_tipo_permiso=ff.id_tipo_permiso
          
     --  and tr_p.id_tipo_permiso = pes.id_tipo_permiso
       and  
           p.id_funcionario in 
           (select distinct p.id_funcionario
              from (select id_js
                      from funcionario_firma
                     where id_funcionario = 101217) ff,
                   personal_new p,
                   funcionario_firma ff2
             where (id_delegado_ja = ff.id_js or ff2.id_js = ff.id_js or
                   id_delegado_js = ff.id_js or id_delegado_js2 = ff.id_js or
                   id_delegado_js3 = ff.id_js or id_delegado_js4 = ff.id_js or
                   id_ja = ff.id_js or id_ver_plani_1 = ff.id_js or
                   id_ver_plani_2 = ff.id_js or id_ver_plani_3 = ff.id_js)
               and ff2.id_funcionario = p.id_funcionario
               and (p.fecha_fin_contrato is null or
                   p.fecha_fin_contrato > sysdate))
    
     order by nombres, ff.id_tipo_permiso; --, 
    
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
  
     --v_opcion 2 ---> fichajes servicio 
        WHEN '2' THEN
  

  
    --abrimos cursor.    
    OPEN Cfichajes_servicio(d_datos_fecha_entrada);
    LOOP
      FETCH Cfichajes_servicio
        into datos_tmp,
             d_id_dia,
             v_nombres_tt;
      EXIT WHEN Cfichajes_servicio%NOTFOUND;
    
      contador := contador + 1;
    
      if contador = 1 then
        datos := datos_tmp;
      else
        datos := datos || ',' || datos_tmp;
      end if;
    
    END LOOP;
    CLOSE Cfichajes_servicio;
  
    resultado := '{"fichajes_servicio": [' || datos || ']}';
  
    --v_opcion 0 ---> permisos pendientes servicio 
     WHEN '1' THEN
          v_anio:=substr( v_fecha,7,4);
  OPEN Cpermisos_pend_Servicio(v_anio);
 
    LOOP
      FETCH Cpermisos_pend_Servicio
        into datos_tmp,
             i_mes   ,
                          v_nombres_tt;

          
      EXIT WHEN Cpermisos_pend_Servicio%NOTFOUND;
    
      contador := contador + 1;
    
      if contador = 1 then
        datos := datos_tmp;
      else
        datos := datos || ',' || datos_tmp;
      end if;
    
    END LOOP;
    CLOSE Cpermisos_pend_Servicio;
  
    resultado := '{"permisos_pendientes_disfrutar_servicio": [' || datos || ']}';

  end case;

  return(Resultado);

end;
/

