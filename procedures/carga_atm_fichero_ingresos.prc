CREATE OR REPLACE PROCEDURE RRHH.CARGA_ATM_FICHERO_INGRESOS (
    p_id_descarga        IN  ATM_FICHERO_INGRESOS.id_descarga%TYPE,
    p_nombre_archivo     IN  ATM_FICHERO_INGRESOS.nombre_archivo%TYPE,
    p_tipo_archivo       IN  ATM_FICHERO_INGRESOS.tipo_archivo%TYPE,
    p_contenido_blob     IN  ATM_FICHERO_INGRESOS.contenido_blob%TYPE,
    p_identificador      IN  ATM_FICHERO_INGRESOS.identificador_fichero%TYPE,
    p_ejercicio          IN  ATM_FICHERO_INGRESOS.ejercicio%TYPE,
    p_entidad            IN  ATM_FICHERO_INGRESOS.entidad%TYPE,
    p_codigo             IN  ATM_FICHERO_INGRESOS.codigo%TYPE,
    p_tipo_deuda         IN  ATM_FICHERO_INGRESOS.tipo_deuda%TYPE,
    p_tipo_fact_contab   IN  ATM_FICHERO_INGRESOS.tipo_facturacion_contabilidad%TYPE,
    p_id_fichero         OUT ATM_FICHERO_INGRESOS.id%TYPE
) AS

   v_tipo_facturacion number;
   v_tipo_deuda number;
   v_codigo varchar2(25);
   
BEGIN
    v_tipo_facturacion:=p_tipo_fact_contab;
   v_tipo_deuda:=p_tipo_deuda;   
   v_codigo:= p_codigo ;

   if  p_codigo is null then
   select tipo_facturacion,tipo_deuda,
         substr(nombre_fichero,instr(nombre_fichero,'Nº',1,1)+3,instr(nombre_fichero,' ',instr(nombre_fichero,'Nº ',1,1)+3,1)   -( instr(nombre_fichero,'Nº',1,1)+3)) as codigo
      into   v_tipo_facturacion, v_tipo_deuda,v_codigo 
     from  atm_fichero_carga where id =p_id_descarga;
   end if;

    INSERT INTO ATM_FICHERO_INGRESOS (
        id_descarga,
        nombre_archivo,
        tipo_archivo,
        contenido_blob,
        fecha_registro,
        identificador_fichero,
        ejercicio,
        entidad,
        codigo,
        tipo_deuda,
        tipo_facturacion_contabilidad
    ) VALUES (
        p_id_descarga,
        p_nombre_archivo,
        p_tipo_archivo,
        p_contenido_blob,
        SYSTIMESTAMP,
        p_identificador,
        p_ejercicio,
        p_entidad,
        v_codigo,
       v_tipo_deuda,
        v_tipo_facturacion
    ) RETURNING ID INTO p_id_fichero;

    -- Opcional: confirmaciones de logging o auditoría aquí

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END CARGA_ATM_FICHERO_INGRESOS;
/

