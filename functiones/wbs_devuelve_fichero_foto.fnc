/*******************************************************************************
 * Función: wbs_devuelve_fichero_foto
 * 
 * Propósito:
 *   Devuelve la foto de un funcionario en formato Base64 dentro de un JSON.
 *   Utilizada por el portal web de empleados para mostrar fotos.
 *
 * @param v_id_funcionario VARCHAR2  ID del funcionario
 * @return CLOB                      JSON con foto en Base64 o cadena vacía si no existe
 *
 * Lógica:
 *   1. Consulta la foto del funcionario en foto_funcionario
 *   2. Codifica la foto en Base64 usando base64encode
 *   3. Construye JSON con formato MIME application/jpg
 *   4. Retorna cadena vacía si no se encuentra foto
 *
 * Dependencias:
 *   - Tabla: foto_funcionario (almacenamiento de fotos)
 *   - Función: base64encode (codificación Base64)
 *
 * Mejoras aplicadas:
 *   - Eliminación de variables no utilizadas (8 variables eliminadas)
 *   - Constante para tipo MIME
 *   - Simplificación de estructura
 *   - Documentación JavaDoc completa
 *
 * Formato de salida:
 *   ,"foto": [ {"mime": "application/jpg","data": "base64_encoded_data"}]
 *
 * Ejemplo de uso:
 *   SELECT wbs_devuelve_fichero_foto('123456') FROM DUAL;
 *
 * Historial:
 *   - 06/12/2025: Optimización y documentación (Grupo 9)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_fichero_foto(
    v_id_funcionario IN VARCHAR2
) RETURN CLOB IS
    -- Constante para tipo MIME
    C_MIME_JPG CONSTANT VARCHAR2(30) := 'application/jpg';
    
    -- Variables
    v_resultado CLOB;
    
BEGIN
    v_resultado := '';
    
    BEGIN     
        SELECT ',"foto": [ {"mime": "' || C_MIME_JPG || '","data": "' || 
               base64encode(foto) || '"}]'
        INTO v_resultado   
        FROM foto_funcionario                
        WHERE id_funcionario = v_id_funcionario;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_resultado := '';
    END;
    
    RETURN v_resultado;
END;
/

