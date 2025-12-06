/*******************************************************************************
 * Función: OBSERVACIONES_PERMISO_EN_DIA
 * 
 * Propósito:
 *   Retorna las observaciones de un funcionario para un día específico,
 *   incluyendo permisos aprobados, incidencias o información del turno.
 *
 * @param V_ID_FUNCIONARIO  ID del funcionario
 * @param v_DIA             Fecha del día a consultar
 * @param v_HH              Horas trabajadas (no utilizado actualmente)
 * @param V_HR              Horas reales (no utilizado actualmente)
 * @param V_TURNO           Turno del funcionario (1=Mañana, 2=Tarde, 3=Noche)
 * @return VARCHAR2         HTML con enlace a permiso, incidencia o turno
 *
 * Lógica:
 *   1. Busca permiso aprobado (estado 80) en la fecha
 *   2. Valida si el permiso requiere justificación
 *   3. Si hay permiso justificado, retorna enlace HTML
 *   4. Si no hay permiso, busca incidencias registradas
 *   5. Si no hay incidencias, retorna descripción del turno
 *
 * Dependencias:
 *   - Tabla: permiso
 *   - Tabla: tr_tipo_permiso
 *   - Tabla: FICHAJE_INCIDENCIA
 *   - Tabla: personal_new
 *   - Tabla: tr_tipo_incidencia
 *
 * Consideraciones:
 *   - Genera HTML inline (considerar separar presentación)
 *   - Parámetros v_HH y V_HR no se utilizan
 *   - Encoding corrupto en texto (Ma�ana, d�a)
 *   - Excluye permisos tipo 15000
 *
 * Mejoras aplicadas:
 *   - Constantes para estados y tipos
 *   - CHR() para caracteres especiales
 *   - INNER JOIN explícito
 *   - Estructura IF simplificada
 *   - Variables inicializadas
 *   - Documentación JavaDoc completa
 *   - Comentarios explicativos
 *
 * Historial:
 *   - 2025-12-06: Optimización y documentación (Grupo 7)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.OBSERVACIONES_PERMISO_EN_DIA(
    V_ID_FUNCIONARIO IN VARCHAR2,
    v_DIA            IN DATE,
    v_HH             IN NUMBER,
    V_HR             IN NUMBER,
    V_TURNO          IN NUMBER
) RETURN VARCHAR2 IS

    -- Constantes
    C_ESTADO_APROBADO   CONSTANT VARCHAR2(2) := '80';
    C_ESTADO_INCIDENCIA CONSTANT NUMBER := 0;
    C_TIPO_EXCLUIDO     CONSTANT NUMBER := 15000;
    C_RESPUESTA_SI      CONSTANT VARCHAR2(2) := 'SI';
    C_RESPUESTA_NO      CONSTANT VARCHAR2(2) := 'NO';
    
    -- Constantes para mensajes de incidencia
    C_MSG_SIN_FICHAJES CONSTANT VARCHAR2(200) := 'Sin fichajes en d' || CHR(237) || 'a laborable.';
    C_IMG_INCIDENCIA   CONSTANT VARCHAR2(200) := '<img src="../../imagen/icono_advertencia.jpg" ' ||
                                                  'alt="INCIDENCIA" width="22" height="22" border="0" >';
    
    -- Constantes para descripción de turnos
    C_TURNO_MANANA CONSTANT VARCHAR2(20) := 'Turno Ma' || CHR(241) || 'ana';
    C_TURNO_TARDE  CONSTANT VARCHAR2(20) := 'Turno Tarde';
    C_TURNO_NOCHE  CONSTANT VARCHAR2(20) := 'Turno Noche';
    
    -- Variables
    Result              VARCHAR2(1512);
    i_encontrado        NUMBER := 0;
    v_id_permiso        NUMBER := 0;
    i_TIPO_justifica    VARCHAR2(2);
    i_permiso_justifica VARCHAR2(2);
    v_descr             VARCHAR2(89);

BEGIN

    -- Buscar permiso aprobado para el día
    BEGIN
        SELECT 
            p.id_permiso,
            tc.JUSTIFICACION,
            NVL(p.justificacion, C_RESPUESTA_NO),
            tc.DESC_PERMISO_CORTA
        INTO 
            v_id_permiso,
            i_TIPO_justifica,
            i_permiso_justifica,
            v_descr
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

    -- Si hay permiso válido, retornar enlace HTML
    IF v_id_permiso <> 0 THEN
        Result := '<a href="../Permisos/ver.jsp?ID_PERMISO=' || v_id_permiso || 
                  '" >' || v_descr || '</a>  Justificado:' || i_permiso_justifica;
    ELSE
        -- No hay permiso: buscar incidencias
        i_encontrado := 1;
        
        BEGIN
            SELECT DISTINCT 
                CASE 
                    WHEN observaciones IS NOT NULL THEN observaciones
                    WHEN DESC_TIPO_INCIDENCIA = C_MSG_SIN_FICHAJES THEN
                        C_MSG_SIN_FICHAJES || C_IMG_INCIDENCIA
                    ELSE DESC_TIPO_INCIDENCIA
                END
            INTO Result
            FROM FICHAJE_INCIDENCIA f
            INNER JOIN personal_new pe 
                ON f.id_funcionario = pe.id_funcionario
            INNER JOIN tr_tipo_incidencia tr 
                ON f.id_tipo_incidencia = tr.id_tipo_incidencia
            WHERE (pe.fecha_baja IS NULL OR pe.fecha_baja > SYSDATE - 1)
              AND f.id_funcionario = V_ID_FUNCIONARIO
              AND f.fecha_incidencia = v_DIA
              AND f.id_Estado_inc = C_ESTADO_INCIDENCIA
              AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                i_encontrado := 0;
        END;
        
        -- Si no hay incidencias, mostrar turno
        IF i_encontrado = 0 THEN
            Result := CASE V_TURNO
                WHEN 1 THEN C_TURNO_MANANA
                WHEN 2 THEN C_TURNO_TARDE
                WHEN 3 THEN C_TURNO_NOCHE
                ELSE ''
            END;
        END IF;
    END IF;
    
    RETURN Result;

END OBSERVACIONES_PERMISO_EN_DIA;
/

