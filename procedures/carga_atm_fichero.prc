CREATE OR REPLACE PROCEDURE RRHH.CARGA_ATM_FICHERO (
    p_nombre_fichero    IN VARCHAR2,
    p_usuario_windows   IN VARCHAR2,
    p_fichero_zip       IN BLOB,
    p_tipo_facturacion  IN VARCHAR2,
    p_tipo_deuda        IN VARCHAR2,
    p_id_out            OUT NUMBER
) AS
BEGIN

delete from  atm_fichero_ing_excel  where
 id_fichero in (select id from  atm_fichero_ingresos where procesado=0 and id_descarga in
                (select id  from  atm_fichero_carga where  nombre_fichero=p_nombre_fichero));

delete from  atm_fichero_ing_pdf  where  id_fichero in (select id from  atm_fichero_ingresos where procesado=0 and id_descarga in
                (select id  from  atm_fichero_carga where  nombre_fichero=p_nombre_fichero));


delete from  atm_fichero_ingresos where procesado=0 and id_descarga in (select id  from  atm_fichero_carga where  nombre_fichero=p_nombre_fichero);
delete from  atm_fichero_carga where  nombre_fichero=p_nombre_fichero;


    INSERT INTO ATM_FICHERO_CARGA (
        nombre_fichero,
        usuario_windows,
        fecha_hora,
        fichero_zip,
        tipo_facturacion,
        tipo_deuda
    )
    VALUES (
        p_nombre_fichero,
        p_usuario_windows,
        SYSTIMESTAMP,
        p_fichero_zip,
        p_tipo_facturacion,
        p_tipo_deuda
    )
    RETURNING id INTO p_id_out;
      COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

