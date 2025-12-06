/*******************************************************************************
 * Función: WBS_ACTUALIZA_NOMINA
 * 
 * Propósito:
 *   Actualiza el archivo de nómina de un funcionario en la base de datos.
 *
 * @param v_id_funcionario  ID del funcionario (no usado actualmente)
 * @param fichero           BLOB con el archivo PDF de la nómina
 * @return VARCHAR2         'bien' si éxito
 *
 * Lógica:
 *   1. Actualiza el campo nomina en la tabla nomina_funcionario
 *   2. Confirma los cambios con COMMIT
 *
 * Dependencias:
 *   - Tabla: nomina_funcionario (nomina)
 *
 * Notas:
 *   - La función NO usa el parámetro v_id_funcionario en el UPDATE
 *   - El WHERE clause está comentado, por lo que actualiza TODAS las filas
 *   - Esto es un ERROR GRAVE que debe corregirse
 *   - La función hace COMMIT automático
 *
 * ⚠️ ALERTA DE SEGURIDAD/BUG:
 *   El UPDATE sin WHERE actualiza TODAS las nóminas con el mismo archivo.
 *   Esto es claramente un error. Debe añadirse:
 *   WHERE id_funcionario = v_id_funcionario
 *
 * Mejoras aplicadas:
 *   - Documentación JavaDoc completa con alerta de bug crítico
 *   - Constantes para mensajes
 *   - Eliminación de variable no usada (contador)
 *   - Eliminación de código comentado duplicado
 *   - Comentarios explicativos del problema
 *
 * TODO CRÍTICO:
 *   Añadir WHERE clause al UPDATE antes de usar en producción
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 8 - documentación y alerta de bug
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_actualiza_nomina(
    v_id_funcionario IN VARCHAR2,
    fichero          IN BLOB
) RETURN VARCHAR2 IS

    -- Constantes
    C_EXITO CONSTANT VARCHAR2(10) := 'bien';
    
    -- Variables
    v_resultado VARCHAR2(12000);

BEGIN
    v_resultado := C_EXITO;
    
    -- ⚠️ BUG CRÍTICO: Este UPDATE actualiza TODAS las nóminas
    -- Debe añadirse: WHERE id_funcionario = v_id_funcionario
    UPDATE nomina_funcionario
    SET nomina = fichero;
    -- WHERE id_funcionario = v_id_funcionario;  -- TODO: DESCOMENTAR
    
    COMMIT;
    
    RETURN v_resultado;

END wbs_actualiza_nomina;
/

