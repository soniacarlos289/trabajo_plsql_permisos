/*******************************************************************************
 * Función: wbs_devuelve_fichero_justificante_per_au
 * 
 * Propósito:
 *   Devuelve un fichero justificante (permisos o ausencias) en formato Base64
 *   dentro de un JSON. Utilizada para descargar justificantes desde el portal web.
 *
 * @param v_id_enlace VARCHAR2  ID del enlace del fichero justificante
 * @return CLOB                 JSON con fichero PDF en Base64 o cadena vacía
 *
 * Lógica:
 *   1. Valida que v_id_enlace sea mayor que 0
 *   2. Consulta el fichero en ficheros_justificantes
 *   3. Codifica el fichero en Base64 usando base64encode
 *   4. Construye JSON con formato MIME application/pdf
 *   5. Retorna cadena vacía si no se encuentra o ID inválido
 *
 * Dependencias:
 *   - Tabla: ficheros_justificantes (almacenamiento de justificantes)
 *   - Función: base64encode (codificación Base64)
 *
 * Mejoras aplicadas:
 *   - Eliminación de variables no utilizadas (7 variables eliminadas)
 *   - Constante para tipo MIME PDF
 *   - Eliminación DISTINCT innecesario (consulta por PK)
 *   - Simplificación de estructura
 *   - Documentación JavaDoc completa
 *
 * Formato de salida:
 *   "file": [ {"mime": "application/pdf","data": "base64_encoded_data"}]
 *
 * Ejemplo de uso:
 *   SELECT wbs_devuelve_fichero_justificante_per_au('12345') FROM DUAL;
 *
 * Historial:
 *   - 06/12/2025: Optimización y documentación (Grupo 9)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_fichero_justificante_per_au(
    v_id_enlace IN VARCHAR2
) RETURN CLOB IS
    -- Constante para tipo MIME
    C_MIME_PDF CONSTANT VARCHAR2(30) := 'application/pdf';
    
    -- Variables
    v_resultado CLOB;
    
BEGIN
    v_resultado := '';
    
    IF v_id_enlace > 0 THEN
        BEGIN     
            SELECT '"file": [ {"mime": "' || C_MIME_PDF || '","data": "' || 
                   base64encode(fichero) || '"}]'
            INTO v_resultado   
            FROM ficheros_justificantes                 
            WHERE id = v_id_enlace;
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_resultado := '';
        END;
    END IF;
    
    RETURN v_resultado;
END;
/

