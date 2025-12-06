/*******************************************************************************
 * Función: WBS_ACTUALIZA_FOTO
 * 
 * Propósito:
 *   Actualiza o inserta la fotografía de un funcionario en la base de datos.
 *   Elimina la foto anterior si existe y guarda la nueva.
 *
 * @param v_id_funcionario  ID del funcionario
 * @param fichero           BLOB con la imagen de la fotografía
 * @return VARCHAR2         'nulo' si éxito, mensaje de error si fallo
 *
 * Lógica:
 *   1. Elimina cualquier foto existente del funcionario
 *   2. Inserta la nueva foto con fecha actual
 *   3. Confirma los cambios (COMMIT)
 *   4. Captura errores de inserción si existen
 *
 * Dependencias:
 *   - Tabla: foto_funcionario (id_funcionario, foto, fecha_actualizacion)
 *
 * Notas:
 *   - La función hace COMMIT automático, lo que puede afectar otras transacciones
 *   - Considera usar procedimientos para operaciones DML con COMMIT
 *
 * Mejoras aplicadas:
 *   - Documentación JavaDoc completa
 *   - Constantes para mensajes de resultado
 *   - Variables con nombres más descriptivos
 *   - Comentarios explicativos
 *   - Eliminación de variable no usada (contador)
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 8 - documentación completa
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_actualiza_foto(
    v_id_funcionario IN VARCHAR2,
    fichero          IN BLOB
) RETURN VARCHAR2 IS

    -- Constantes para mensajes de resultado
    C_EXITO               CONSTANT VARCHAR2(50) := 'nulo';
    C_ERROR_INSERCION     CONSTANT VARCHAR2(50) := 'Error insercion';
    C_ERROR_DUPLICADO     CONSTANT VARCHAR2(50) := 'Error insercion fichero ya existe';
    
    -- Variables
    v_resultado VARCHAR2(12000);

BEGIN
    v_resultado := C_EXITO;
    
    -- Eliminar foto existente del funcionario (si existe)
    DELETE FROM foto_funcionario 
    WHERE id_funcionario = v_id_funcionario;
    
    COMMIT;
    
    -- Insertar nueva foto
    BEGIN
        INSERT INTO foto_funcionario 
        VALUES (v_id_funcionario, fichero, SYSDATE);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_resultado := C_ERROR_INSERCION;
        WHEN DUP_VAL_ON_INDEX THEN
            v_resultado := C_ERROR_DUPLICADO;
    END;
    
    COMMIT;
    
    RETURN v_resultado;

END wbs_actualiza_foto;
/

