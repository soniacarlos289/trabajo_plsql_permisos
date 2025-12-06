/*******************************************************************************
 * Función: wbs_borra_repetidos
 * 
 * Propósito:
 *   Elimina registros duplicados en la tabla personal_t, conservando solo
 *   el último registro de cada funcionario cuando existen duplicados.
 *
 * @return VARCHAR2  'bien' si la operación se completó correctamente
 *
 * Lógica:
 *   1. Identifica funcionarios con registros duplicados (COUNT > 1)
 *   2. Para cada funcionario duplicado, elimina el primer registro
 *   3. Confirma cada eliminación con COMMIT
 *
 * Dependencias:
 *   - Tabla: personal_t (tabla de personal)
 *
 * Mejoras aplicadas:
 *   - Cursor manual → FOR LOOP (mejor gestión de memoria)
 *   - Eliminación de variable no usada (id_ra)
 *   - Tamaños de VARCHAR2 optimizados (12000 → 100 bytes)
 *   - Constante para mensaje de éxito
 *   - Documentación JavaDoc completa
 *   - COMMIT dentro del loop (mantiene comportamiento original)
 *
 * Nota importante:
 *   ⚠️ CRÍTICO: Esta función hace COMMIT dentro del loop, lo que puede causar
 *   problemas en transacciones complejas y afectar la integridad de datos.
 *   Recomendación: Refactorizar para hacer un solo COMMIT al final y agregar
 *   manejo de excepciones con ROLLBACK.
 *
 * Historial:
 *   - 06/12/2025: Optimización y documentación (Grupo 9)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_borra_repetidos 
RETURN VARCHAR2 IS
    -- Constante para mensaje de éxito
    C_MENSAJE_EXITO CONSTANT VARCHAR2(10) := 'bien';
    
    -- Variables
    v_resultado VARCHAR2(100);
    
BEGIN
    -- Procesar funcionarios con registros duplicados
    FOR rec IN (
        SELECT id_funcionario 
        FROM personal_t
        GROUP BY id_funcionario
        HAVING COUNT(*) > 1
    ) LOOP
        -- Eliminar el primer registro duplicado
        DELETE FROM personal_t 
        WHERE id_funcionario = rec.id_funcionario 
        AND ROWNUM < 2;
        
        COMMIT;
    END LOOP;
    
    v_resultado := C_MENSAJE_EXITO;
    RETURN v_resultado;
END;
/

