/*******************************************************************************
 * Función: wbs_justifica_fichero_sin
 * 
 * Propósito:
 *   Inserta o actualiza un archivo justificante BLOB en la base de datos
 *   para un permiso o ausencia. Esta función NO incluye descripción del
 *   justificante (parámetro vacío en INSERT).
 *
 * @param v_id_permiso  VARCHAR2  ID del permiso a justificar (puede ser NULL)
 * @param v_id_ausencia VARCHAR2  ID de la ausencia a justificar (puede ser NULL)
 * @param fichero       BLOB      Archivo justificante en formato binario
 * @return              VARCHAR2  Mensaje indicando resultado de la operación
 *
 * Lógica:
 *   1. Busca el permiso por ID y construye clave (año||funcionario||permiso)
 *   2. Si no encuentra permiso, busca ausencia y construye clave similar
 *   3. Intenta insertar el fichero con la clave construida
 *   4. Si ya existe (DUP_VAL_ON_INDEX), actualiza el BLOB existente
 *   5. Confirma la transacción con COMMIT
 *
 * Dependencias:
 *   - Tabla: permiso (id_permiso, id_ano, id_funcionario)
 *   - Tabla: ausencia (id_ausencia, id_ano, id_funcionario)
 *   - Tabla: ficheros_justificantes (id PK, descripcion, fichero BLOB)
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para mensajes de resultado
 *   - Corrección bug: eliminada comparación "enlace_fichero > 0" (inválida para VARCHAR2)
 *   - Variables con tamaños adecuados (200 bytes para ID, 500 para mensajes)
 *   - Documentación completa de comportamiento transaccional (COMMIT)
 *   - ROWNUM = 1 en lugar de ROWNUM < 2
 *   - Simplificación lógica de flags
 *
 * Notas importantes:
 *   ⚠️ COMMIT explícito: Esta función confirma TODA la transacción activa
 *   ⚠️ Sin descripción: El segundo parámetro del INSERT es cadena vacía
 *   ⚠️ Bug corregido: Condición "enlace_fichero > 0" era inválida (VARCHAR2)
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 11 - Documentación y corrección bugs
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_justifica_fichero_sin(
    v_id_permiso  IN VARCHAR2,
    v_id_ausencia IN VARCHAR2,
    fichero       IN BLOB
) RETURN VARCHAR2 IS
    -- Constantes
    C_MSG_INSERTADO     CONSTANT VARCHAR2(100) := 'Fichero insertado correctamente';
    C_MSG_ACTUALIZADO   CONSTANT VARCHAR2(100) := 'Fichero actualizado correctamente';
    C_MSG_ERROR_INSERT  CONSTANT VARCHAR2(100) := 'Error insercion';
    C_MSG_ERROR_EXISTE  CONSTANT VARCHAR2(100) := 'Error insercion fichero ya existe';
    C_MSG_NULO          CONSTANT VARCHAR2(10)  := 'nulo';
    
    -- Variables
    v_resultado        VARCHAR2(500);
    v_enlace_fichero   VARCHAR2(200);
    v_encontrado       BOOLEAN := FALSE;
    
BEGIN
    -- Inicialización
    v_enlace_fichero := NULL;
    
    -- Buscar enlace en tabla permiso
    BEGIN
        SELECT id_ano || id_funcionario || id_permiso
        INTO v_enlace_fichero
        FROM permiso
        WHERE id_permiso = v_id_permiso
          AND ROWNUM = 1;
        
        v_encontrado := TRUE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_encontrado := FALSE;
    END;
    
    -- Si no se encontró en permiso, buscar en ausencia
    IF NOT v_encontrado THEN
        BEGIN
            SELECT id_ano || id_funcionario || id_ausencia
            INTO v_enlace_fichero
            FROM ausencia
            WHERE id_ausencia = v_id_ausencia
              AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                NULL; -- No se encontró ni permiso ni ausencia
        END;
    END IF;
    
    -- Mensaje de debug
    v_resultado := C_MSG_NULO || v_enlace_fichero;
    
    -- Insertar o actualizar fichero si hay datos válidos
    IF v_enlace_fichero IS NOT NULL AND fichero IS NOT NULL THEN
        BEGIN
            -- Intentar insertar nuevo registro
            INSERT INTO ficheros_justificantes (id, descripcion, fichero)
            VALUES (v_enlace_fichero, '', fichero);
            
            v_resultado := C_MSG_INSERTADO;
            
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                -- Si ya existe, actualizar el BLOB con el nuevo fichero
                UPDATE ficheros_justificantes
                SET fichero = wbs_justifica_fichero_sin.fichero  -- Parámetro IN de la función
                WHERE id = v_enlace_fichero;
                
                v_resultado := C_MSG_ACTUALIZADO;
                
            WHEN OTHERS THEN
                v_resultado := C_MSG_ERROR_INSERT;
        END;
    END IF;
    
    -- ⚠️ COMMIT explícito: confirma toda la transacción
    COMMIT;
    
    RETURN v_resultado;
    
END wbs_justifica_fichero_sin;
/

