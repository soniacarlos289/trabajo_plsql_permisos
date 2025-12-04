create or replace procedure rrhh.ACTUALIZA_PERSONAL_SAVIA(v_codienti           in varchar2,--1
                                                     v_versempl           in varchar2,--2
                                                     v_id_funcionario     in varchar2,--3                                                     
                                                     v_categoria          in varchar2,--4
                                                     v_puesto             in varchar2,--5
                                                     v_fecha_nacimiento    in varchar2,--6
                                                     v_tipo_funcionario2   in varchar2,--7                                                     
                                                     v_nombre             in varchar2,--8
                                                     v_ape1               in varchar2,--9
                                                     v_ape2               in varchar2,--10
                                                     v_tipo_funcionario   in varchar2,--11
                                                     v_direccion          in varchar2,--12
                                                     v_telefono           in varchar2,--13
                                                     d_fecha_ingreso      in varchar2,--14
                                                     d_fecha_fin_contrato  in varchar2,--15
                                                     v_activo             in varchar2,--16
                                                     v_jornada            in varchar2,--17
                                                     v_numero_ss          in varchar2,--18
                                                     v_dni                in varchar2,--19
                                                     v_dni_letra          in varchar2,--20
                                                     d_fecha_antiguedad     in varchar2,--21
                                                     d_fecha_baja           in varchar2,--22
                                                     v_contratacion       in varchar2,--23
                                                     v_codicoti     in varchar2 --24
                                                    
                                                     ) is

  pos integer;
  i_id_funcionario number;
begin

  pos := 1;


 Begin
    select  id_funcionario
      into  i_id_funcionario
      from  personal_historico where dni=v_dni and rownum<2;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        pos := 0;
   End;

 

 if pos=1 then
    update  personal_historico
       set codienti           = v_codienti,
           versempl           = v_versempl,
        --  id_funcionario     = v_id_funcionario,
         --  categoria          = v_categoria,
         --  puesto             = v_puesto,
          -- fecha_nacimiento   = to_Date(v_fecha_nacimiento,'DD/mm/yyyy'),
          -- tipo_funcionario2  = v_tipo_funcionario2,
          -- nombre             = v_nombre,
           ---ape1               = v_ape1,
           --ape2               = v_ape2,
        --   tipo_funcionario   = 'N',
           --direccion          = v_direccion,
           --telefono           = v_telefono,
           fecha_ingreso      = to_Date(d_fecha_ingreso,'DD/mm/yyyy'),
           fecha_fin_contrato = to_Date(d_fecha_fin_contrato,'DD/mm/yyyy'),
           activo             = v_activo,
           --jornada            = v_jornada,
           --numero_ss          = v_numero_ss,
           --dni                = v_dni,
           --dni_letra          = v_dni_letra,
           fecha_antiguedad   = to_Date(d_fecha_antiguedad,'DD/mm/yyyy'),
           fecha_baja         = to_Date(d_fecha_baja,'DD/mm/yyyy'),
           contratacion       = v_contratacion,
           codicoti           = v_codicoti
           
     where dni                = v_dni
      -- and   (fecha_baja <   to_Date(d_fecha_baja,'DD/mm/yyyy')  OR d_fecha_baja=null or d_fecha_fin_contrato=null)
       
     --  and (id_funcionario > v_id_funcionario)

       and rownum < 2 and id_funcionario not in (1790,101049);

  /*  update personal_historico
       set id_funcionario     = v_id_funcionario

     where dni                = v_dni
       and         (id_funcionario > v_id_funcionario);*/



   else
     Begin
   insert into personal_historico
        (codienti,
         versempl,
         id_funcionario,
         categoria,
         puesto,
         fecha_nacimiento,
         tipo_funcionario2,
         nombre,
         ape1,
         ape2,
         tipo_funcionario,
         direccion,
         telefono,
         fecha_ingreso,
         fecha_fin_contrato,
         activo,
         jornada,
         numero_ss,
         dni,
         dni_letra,
         fecha_antiguedad,
         fecha_baja,
         contratacion,codicoti)
      values
        (v_codienti,
         v_versempl,
         v_id_funcionario,
         v_categoria,
         v_puesto,
         to_date(v_fecha_nacimiento,'DD/mm/yyyy'),
         v_tipo_funcionario2,
         v_nombre,
         v_ape1,
         v_ape2,
         v_tipo_funcionario,
         v_direccion,
         v_telefono,
         to_date(d_fecha_ingreso,'DD/mm/yyyy'),
         to_date(d_fecha_fin_contrato,'DD/mm/yyyy'),
         v_activo,
         v_jornada,
         v_numero_ss,
         v_dni,
         v_dni_letra,
          to_date(d_fecha_antiguedad,'DD/mm/yyyy'),
          to_date(d_fecha_baja,'DD/mm/yyyy'),
         v_contratacion,  v_codicoti);
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        pos := 0;
    END;
    
    
   


   end if;
 /* insert into personal_historico
        (codienti,
         versempl,
         id_funcionario,
         categoria,
         puesto,
         fecha_nacimiento,
         tipo_funcionario2,
         nombre,
         ape1,
         ape2,
         tipo_funcionario,
         direccion,
         telefono,
         fecha_ingreso,
         fecha_fin_contrato,
         activo,
         jornada,
         numero_ss,
         dni,
         dni_letra,
         fecha_antiguedad,
         fecha_baja,
         contratacion,codicoti)
      values
        (v_codienti,
         v_versempl,
         v_id_funcionario,
         v_categoria,
         v_puesto,
         to_date(v_fecha_nacimiento,'DD/mm/yyyy'),
         v_tipo_funcionario2,
         v_nombre,
         v_ape1,
         v_ape2,
         v_tipo_funcionario,
         v_direccion,
         v_telefono,
         to_date(d_fecha_ingreso,'DD/mm/yyyy'),
         to_date(d_fecha_fin_contrato,'DD/mm/yyyy'),
         v_activo,
         v_jornada,
         v_numero_ss,
         v_dni,
         v_dni_letra,
          to_date(d_fecha_antiguedad,'DD/mm/yyyy'),
          to_date(d_fecha_baja,'DD/mm/yyyy'),
         v_contratacion,  v_codicoti);*/


  commit;
  
  
END ACTUALIZA_PERSONAL_SAVIA;
/

