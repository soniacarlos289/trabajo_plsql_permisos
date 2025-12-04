CREATE OR REPLACE PROCEDURE RRHH.actualizar_referencias_faltantes IS
BEGIN
 UPDATE TEMP_VIVIENDA_CATASTRO_COM d1
    SET rc = (
        SELECT substr(d2.rc
        FROM TEMP_VIVIENDA_CATASTRO_COM d2
     WHERE d2.via_sigla = d1.via_sigla
        AND d2.via_nombre = d1.via_nombre
        AND d2.via_numero = d1.via_numero
        AND d2.rc IS NOT NULL
        AND ROWNUM = 1
    )
    WHERE d1.rc IS NULL
    AND dboid= (
        SELECT d2.dboid
        FROM TEMP_VIVIENDA_CATASTRO_COM d2
        WHERE d2.via_sigla = d1.via_sigla
        AND d2.via_nombre = d1.via_nombre
        AND d2.via_numero = d1.via_numero
        AND d2.referencia_catastral IS NULL );
/

