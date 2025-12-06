/*******************************************************************************
 * Función: OBSERVACIONES_PERMISO_EN_DIA_A
 * 
 * Propósito:
 *   Versión ampliada de OBSERVACIONES_PERMISO_EN_DIA que también busca horas
 *   extras registradas para el funcionario en la fecha indicada.
 *
 * @param V_ID_FUNCIONARIO  ID del funcionario
 * @param v_DIA             Fecha del día a consultar
 * @param v_HH              Horas trabajadas (no utilizado)
 * @param V_HR              Horas reales (no utilizado)
 * @param V_TURNO           Turno (1=Mañana, 2=Tarde, 3=Noche)
 * @param V_ENTRADA         Hora de entrada para buscar horas extras
 * @param V_SALIDA          Hora de salida para buscar horas extras
 * @return VARCHAR2         HTML con enlace a permiso, incidencia, turno o horas extras
 *
 * Lógica:
 *   1. Busca permiso aprobado (estado 80) en la fecha
 *   2. Valida si el permiso requiere justificación
 *   3. Si no hay permiso, busca incidencias
 *   4. Si no hay incidencias, muestra turno
 *   5. Adicionalmente, busca horas extras con entrada/salida coincidentes
 *
 * Dependencias:
 *   - Tabla: permiso
 *   - Tabla: tr_tipo_permiso
 *   - Tabla: FICHAJE_INCIDENCIA
 *   - Tabla: personal_new
 *   - Tabla: tr_tipo_incidencia
 *   - Tabla: horas_extras
 *
 * Consideraciones:
 *   - Genera HTML inline (considerar separar presentación)
 *   - Encoding corrupto en texto (Ma�ana, d�a)
 *   - Similar a OBSERVACIONES_PERMISO_EN_DIA pero añade horas extras
 *
 * Mejoras aplicadas:
 *   - Constantes para estados y tipos
 *   - CHR() para caracteres especiales
 *   - INNER JOIN explícito
 *   - Estructura IF simplificada
 *   - Variables inicializadas
 *   - Documentación JavaDoc completa
 *
 * Historial:
 *   - 2025-12-06: Optimización y documentación (Grupo 7)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.OBSERVACIONES_PERMISO_EN_DIA_A(
    V_ID_FUNCIONARIO IN VARCHAR2,
    v_DIA            IN DATE,
    v_HH             IN NUMBER,
    V_HR             IN NUMBER,
    V_TURNO          IN NUMBER,
    V_ENTRADA        IN VARCHAR2,
    V_SALIDA         IN VARCHAR2
) RETURN VARCHAR2 IS

    -- Constantes
    C_ESTADO_APROBADO   CONSTANT VARCHAR2(2) := '80';
    C_ESTADO_INCIDENCIA CONSTANT NUMBER := 0;
    C_TIPO_EXCLUIDO     CONSTANT NUMBER := 15000;
    C_RESPUESTA_SI      CONSTANT VARCHAR2(2) := 'SI';
    C_RESPUESTA_NO      CONSTANT VARCHAR2(2) := 'NO';
    
    -- Variables
    Result              VARCHAR2(1512);
    i_encontrado        NUMBER := 0;
    v_id_permiso        NUMBER := 0;
    i_TIPO_justifica    VARCHAR2(2);
    i_permiso_justifica VARCHAR2(2);
    v_descr             VARCHAR2(89);
    i_id_hora           NUMBER := 0;
    i_id_ano            NUMBER;

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
                    WHEN DESC_TIPO_INCIDENCIA = 'Sin fichajes en d' || CHR(237) || 'a laborable.' THEN
                        'Sin fichajes en d' || CHR(237) || 'a laborable.' ||
                        '<img src="../../imagen/icono_advertencia.jpg" ' ||
                        'alt="INCIDENCIA" width="22" height="22" border="0" >'
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
                WHEN 1 THEN 'Turno Ma' || CHR(241) || 'ana'  -- Mañana
                WHEN 2 THEN 'Turno Tarde'
                WHEN 3 THEN 'Turno Noche'
                ELSE ''
            END;
        END IF;
        
        -- Buscar horas extras con coincidencia de horario
        BEGIN
            SELECT id_hora, id_ano
            INTO i_id_hora, i_id_ano
            FROM horas_extras
            WHERE V_ENTRADA = HORA_INICIO
              AND V_SALIDA = HORA_FIN
              AND id_funcionario = V_ID_FUNCIONARIO
              AND fecha_horas = v_DIA
              AND (ANULADO = C_RESPUESTA_NO OR ANULADO IS NULL);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                i_id_hora := 0;
        END;
        
        -- Si hay horas extras, agregar enlace
        IF i_id_hora > 0 THEN
            Result := '<a href="../Horas/editar.jsp?ID_HORA=' || i_id_hora || 
                      '&ID_ANO=' || i_id_ano || '" >Horas extras</a>  ';
        END IF;
    END IF;
    
    RETURN Result;

END OBSERVACIONES_PERMISO_EN_DIA_A;
/

