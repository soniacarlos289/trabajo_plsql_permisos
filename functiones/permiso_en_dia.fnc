/*******************************************************************************
 * Función: PERMISO_EN_DIA
 * 
 * Propósito:
 *   Verifica si un funcionario tiene un permiso aprobado en una fecha específica
 *   y retorna el ID del permiso si existe y está justificado correctamente.
 *
 * @param V_ID_FUNCIONARIO  ID del funcionario
 * @param v_DIA             Fecha del día a consultar
 * @return VARCHAR2         ID del permiso (como string) o '0' si no hay permiso
 *
 * Lógica:
 *   1. Busca permiso aprobado (estado 80) que cubra la fecha
 *   2. Verifica si el tipo de permiso requiere justificación
 *   3. Si requiere justificación y no la tiene, retorna 0
 *   4. Si el permiso es válido, retorna su ID
 *
 * Dependencias:
 *   - Tabla: permiso
 *   - Tabla: tr_tipo_permiso
 *
 * Consideraciones:
 *   - Solo permisos en estado aprobado (80)
 *   - Excluye permisos tipo 15000
 *   - Permisos no anulados
 *
 * Mejoras aplicadas:
 *   - Constantes para estados y tipos
 *   - INNER JOIN explícito
 *   - Variables inicializadas
 *   - Documentación JavaDoc completa
 *   - Simplificación de lógica
 *   - Comentarios explicativos
 *
 * Historial:
 *   - 2025-12-06: Optimización y documentación (Grupo 7)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.PERMISO_EN_DIA(
    V_ID_FUNCIONARIO IN VARCHAR2,
    v_DIA            IN DATE
) RETURN VARCHAR2 IS

    -- Constantes
    C_ESTADO_APROBADO CONSTANT VARCHAR2(2) := '80';
    C_TIPO_EXCLUIDO   CONSTANT NUMBER := 15000;
    C_RESPUESTA_SI    CONSTANT VARCHAR2(2) := 'SI';
    C_RESPUESTA_NO    CONSTANT VARCHAR2(2) := 'NO';
    
    -- Variables
    Result              VARCHAR2(512);
    v_id_permiso        NUMBER := 0;
    i_TIPO_justifica    VARCHAR2(2);
    i_permiso_justifica VARCHAR2(2);

BEGIN

    -- Buscar permiso aprobado para el día
    BEGIN
        SELECT 
            p.id_permiso,
            tc.JUSTIFICACION,
            NVL(p.justificacion, C_RESPUESTA_NO)
        INTO 
            v_id_permiso,
            i_TIPO_justifica,
            i_permiso_justifica
        FROM permiso p
        INNER JOIN tr_tipo_permiso tc 
            ON p.id_tipo_permiso = tc.id_tipo_permiso 
           AND p.id_ano = tc.id_ano
        WHERE p.id_funcionario = V_ID_FUNCIONARIO
          AND v_DIA BETWEEN p.fecha_inicio AND NVL(p.fecha_fin, SYSDATE + 1)
          AND (p.anulado = C_RESPUESTA_NO OR p.anulado IS NULL)
          AND p.id_estado = C_ESTADO_APROBADO
          AND p.id_tipo_permiso <> C_TIPO_EXCLUIDO
          AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_id_permiso := 0;
    END;
    
    -- Validar si el permiso requiere justificación y no la tiene
    IF v_id_permiso <> 0 
       AND i_TIPO_justifica = C_RESPUESTA_SI 
       AND i_permiso_justifica = C_RESPUESTA_NO THEN
        v_id_permiso := 0;
    END IF;
    
    Result := TO_CHAR(v_id_permiso);
    
    RETURN Result;

END PERMISO_EN_DIA;
/

