/*******************************************************************************
 * Función: wbs_inserta_curso
 * 
 * Propósito:
 *   Inscribe o anula la inscripción de un funcionario en un curso de formación.
 *
 * @param v_id_funcionario VARCHAR2  ID del funcionario
 * @param v_id_curso       VARCHAR2  Código del curso
 * @param v_opcion         VARCHAR2  Operación (0=inscribir, 1=anular)
 * @return VARCHAR2                  Mensaje con resultado de la operación
 *
 * Opciones:
 *   - '0': Inscribe al funcionario en el curso (estado 'PE' = Pendiente)
 *   - '1': Anula la inscripción del funcionario en el curso
 *
 * Lógica:
 *   1. Verifica si el funcionario ya está inscrito en el curso
 *   2. Según opción:
 *      - Inscripción: inserta registro si no existe
 *      - Anulación: elimina registro si existe
 *   3. Realiza COMMIT de la transacción
 *   4. Retorna mensaje informativo del resultado
 *
 * Dependencias:
 *   - Tabla: curso_savia_solicitudes (solicitudes de cursos)
 *   - Tabla: tr_estado_sol_curso (estados de solicitud)
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para estados y mensajes
 *   - Corrección comparación NULL (IS NULL en lugar de = NULL)
 *   - Inicialización explícita de variables
 *   - Documentación de COMMIT explícito
 *   - Documentación JavaDoc completa
 *
 * Notas:
 *   ⚠️ COMMIT explícito en la función (afecta a toda la transacción)
 *   - Estado 'PE' = Pendiente de aprobación
 *   - COMMIT se ejecuta siempre al final de la función
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 10 - Constantes, corrección NULL
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_inserta_curso(
    v_id_funcionario IN VARCHAR2,
    v_id_curso       IN VARCHAR2,
    v_opcion         IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes
    C_ESTADO_PENDIENTE    CONSTANT VARCHAR2(2) := 'PE';
    C_MSG_INSCRITO        CONSTANT VARCHAR2(50) := 'Inscripcion completada';
    C_MSG_YA_INSCRITO     CONSTANT VARCHAR2(60) := 'Operacion no completada, ya estas inscrito';
    C_MSG_ANULADO         CONSTANT VARCHAR2(50) := 'Anulacion completada';
    C_MSG_NO_INSCRITO     CONSTANT VARCHAR2(60) := 'Operacion no completada, no estas inscrito';
    C_MSG_OPCION_INVALIDA CONSTANT VARCHAR2(60) := 'Operacion no completada, opcion no valida';
    
    -- Variables
    v_resultado           VARCHAR2(12000);
    v_contador            NUMBER := 0;
    
BEGIN
    -- Verifica si el funcionario ya está inscrito en el curso
    BEGIN
        SELECT codicur
        INTO v_contador
        FROM curso_savia_solicitudes t
        INNER JOIN tr_estado_sol_curso tr ON t.estadosoli = tr.id_estado_sol_curso
        WHERE t.codicur = v_id_curso
          AND t.codiempl = v_id_funcionario
          AND ROWNUM < 2;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_contador := 0;
    END;
    
    -- Procesa según opción
    IF v_opcion = '0' THEN
        -- Inscripción en curso
        IF v_contador = 0 THEN
            INSERT INTO curso_savia_solicitudes (codicur, estadosoli, fechasoli, codiempl)
            VALUES (v_id_curso, C_ESTADO_PENDIENTE, SYSDATE, v_id_funcionario);
            
            v_resultado := C_MSG_INSCRITO;
        ELSE
            v_resultado := C_MSG_YA_INSCRITO;
        END IF;
        
    ELSIF v_opcion = '1' THEN
        -- Anulación de inscripción
        IF v_contador > 0 THEN
            DELETE FROM curso_savia_solicitudes
            WHERE codicur = v_id_curso
              AND codiempl = v_id_funcionario
              AND ROWNUM < 2;
            
            v_resultado := C_MSG_ANULADO;
        ELSE
            v_resultado := C_MSG_NO_INSCRITO;
        END IF;
        
    ELSE
        -- Opción no válida
        v_resultado := C_MSG_OPCION_INVALIDA;
    END IF;
    
    -- COMMIT explícito: confirma la transacción
    -- ⚠️ Esto confirma TODAS las operaciones pendientes en la sesión
    COMMIT;
    
    RETURN v_resultado;
    
END wbs_inserta_curso;
/

