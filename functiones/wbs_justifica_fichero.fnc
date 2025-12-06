/*******************************************************************************
 * Función: wbs_justifica_fichero
 * 
 * Propósito:
 *   Inserta un archivo justificante (imagen, PDF, etc.) asociado a un
 *   enlace/permiso/ausencia en la tabla de ficheros justificantes.
 *
 * @param enlace_fichero VARCHAR2  ID o enlace del justificante
 * @param fichero        BLOB      Contenido binario del archivo
 * @return VARCHAR2                Mensaje con resultado de la operación
 *
 * Lógica:
 *   1. Valida que enlace_fichero y fichero no sean NULL
 *   2. Intenta insertar el fichero en la tabla
 *   3. Captura errores de duplicado o inserción
 *   4. Retorna mensaje informativo del resultado
 *
 * Dependencias:
 *   - Tabla: ficheros_justificantes (almacén de archivos)
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para mensajes
 *   - Corrección condición: enlace_fichero > 0 no aplica a VARCHAR2
 *   - Documentación de falta de COMMIT (requiere confirmación externa)
 *   - Inicialización explícita de variables
 *   - Documentación JavaDoc completa
 *
 * Notas:
 *   ⚠️ NO realiza COMMIT - La transacción debe confirmarse externamente
 *   ⚠️ Condición original "enlace_fichero > 0" eliminada (inválida para VARCHAR2)
 *   - Requiere que ficheros_justificantes tenga PK en enlace_fichero
 *   - Segundo parámetro INSERT ('') probablemente sea un campo descripción
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 10 - Constantes, corrección condición
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_justifica_fichero(
    enlace_fichero IN VARCHAR2,
    fichero        IN BLOB
) RETURN VARCHAR2 IS
    -- Constantes
    C_MSG_NULO            CONSTANT VARCHAR2(20) := 'nulo';
    C_MSG_INSERTADO       CONSTANT VARCHAR2(20) := 'insertado ';
    C_MSG_ERROR_INSERT    CONSTANT VARCHAR2(30) := 'Error insercion';
    C_MSG_ERROR_DUPLICADO CONSTANT VARCHAR2(50) := 'Error insercion fichero ya existe';
    
    -- Variables
    v_resultado           VARCHAR2(12000);
    
BEGIN
    v_resultado := C_MSG_NULO || enlace_fichero;
    
    -- Valida que ambos parámetros tengan valor
    IF enlace_fichero IS NOT NULL AND fichero IS NOT NULL THEN
        v_resultado := C_MSG_INSERTADO;
        
        BEGIN
            -- Inserta el fichero justificante
            -- Nota: segundo parámetro '' probablemente sea campo descripción
            INSERT INTO ficheros_justificantes VALUES (enlace_fichero, '', fichero);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_resultado := C_MSG_ERROR_INSERT;
            WHEN DUP_VAL_ON_INDEX THEN
                v_resultado := C_MSG_ERROR_DUPLICADO;
        END;
    END IF;
    
    -- ⚠️ NOTA: Esta función NO realiza COMMIT
    -- La transacción debe ser confirmada por el código que la invoca
    
    RETURN v_resultado;
    
END wbs_justifica_fichero;
/

