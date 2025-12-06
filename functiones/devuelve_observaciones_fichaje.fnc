/*******************************************************************************
 * Función: DEVUELVE_OBSERVACIONES_FICHAJE
 * 
 * Propósito:
 *   Genera mensajes de observación para fichajes según reglas de negocio
 *   relacionadas con días laborables, sábados, y tipos de funcionario.
 *
 * @param V_ID_FUNCIONARIO       ID del funcionario
 * @param V_ID_TIPO_FUNCIONARIO  Tipo de funcionario (21=caso especial)
 * @param V_OBSERVACIONES        Observaciones existentes
 * @param V_FICHAJE_ENTRADA      Fecha/hora del fichaje de entrada
 * @param v_HH                   Indicador de horas realizadas
 * @param V_HR                   Indicador de horas restantes
 * @return VARCHAR2              Observación generada según reglas de negocio
 *
 * Lógica:
 *   1. Si tipo funcionario = 21, retorna observaciones sin procesar
 *   2. Para sábados: verifica si fichaje después 14:15 no computa para saldo
 *   3. Verifica fichajes sin entrada/salida en día laborable
 *   4. Busca incidencias registradas en el sistema
 *   5. Retorna la observación más relevante
 *
 * Dependencias:
 *   - Tabla: calendario_laboral
 *   - Tabla: FICHAJE_INCIDENCIA
 *   - Tabla: personal_new
 *   - Tabla: tr_tipo_incidencia
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para valores especiales
 *   - TRUNC para comparaciones de fecha consistentes
 *   - Eliminación de SELECT FROM DUAL
 *   - Uso de CHR() para caracteres especiales HTML
 *   - Variables con nombres descriptivos
 *   - ROWNUM para limitar resultados
 *   - Documentación completa de reglas de negocio
 *
 * Reglas de negocio:
 *   - Tipo 21: Sin validaciones especiales
 *   - Sábados: Fichajes después de 14:15 no computan para saldo
 *   - Laborables: Fichajes incompletos generan advertencia
 *   - No laborables con solo salida: No genera observación (eliminado 14/03/2019)
 *
 * Historial:
 *   - 14/03/2019: Eliminada advertencia para no laborables con solo salida
 *   - 2025: Optimización y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.DEVUELVE_OBSERVACIONES_FICHAJE(
    V_ID_FUNCIONARIO       IN VARCHAR2,
    V_ID_TIPO_FUNCIONARIO  IN VARCHAR2,
    V_OBSERVACIONES        IN VARCHAR2,
    V_FICHAJE_ENTRADA      IN DATE,
    v_HH                   IN NUMBER,
    V_HR                   IN NUMBER
) RETURN VARCHAR2 IS
    -- Constantes
    C_TIPO_ESPECIAL        CONSTANT NUMBER := 21;
    C_DIA_SABADO           CONSTANT NUMBER := 7;
    C_HORA_LIMITE_SABADO   CONSTANT NUMBER := 1415; -- 14:15
    C_FECHA_REFERENCIA     CONSTANT DATE   := TO_DATE('07/01/2019', 'DD/MM/YYYY');
    C_DIA_LUNES_WEB        CONSTANT NUMBER := 1;
    C_NO_LABORAL           CONSTANT VARCHAR2(2) := 'NO';
    C_ESTADO_PENDIENTE     CONSTANT NUMBER := 0;
    
    C_MSG_NO_COMPUTA       CONSTANT VARCHAR2(50) := 'NO COMPUTA PARA SALDO.';
    C_MSG_SIN_FICHAJE      CONSTANT VARCHAR2(200) := 
        'SIN FICHAJE EN EL D' || CHR(205) || 'A   <img src="../../imagen/icono_advertencia.jpg" ' ||
        'alt="INCIDENCIA"  width="22" height="22" border="0" >';
    
    -- Variables
    v_laborable             VARCHAR2(2);
    v_dia_semana            NUMBER;
    v_ajuste_dia            NUMBER;
    v_dia_ajustado          NUMBER;
    v_hora_fichaje          NUMBER;
    v_observacion_incidencia VARCHAR2(1000);
    v_resultado             VARCHAR2(522);
    
BEGIN
    -- Caso especial: tipo funcionario 21
    IF V_ID_TIPO_FUNCIONARIO = C_TIPO_ESPECIAL THEN
        RETURN V_OBSERVACIONES;
    END IF;
    
    -- Obtener si el día es laborable
    SELECT laboral
    INTO v_laborable
    FROM calendario_laboral
    WHERE id_dia = TRUNC(V_FICHAJE_ENTRADA);
    
    -- Detectar contexto de ejecución (web vs PL/SQL)
    v_dia_semana := TO_NUMBER(TO_CHAR(C_FECHA_REFERENCIA, 'D'));
    
    IF v_dia_semana = C_DIA_LUNES_WEB THEN
        v_ajuste_dia := 1;
    ELSE
        v_ajuste_dia := 0;
    END IF;
    
    -- Calcular día de la semana ajustado
    v_dia_ajustado := TO_NUMBER(TO_CHAR(V_FICHAJE_ENTRADA, 'D')) + v_ajuste_dia;
    
    -- Verificar si es sábado
    IF v_dia_ajustado = C_DIA_SABADO THEN
        -- Obtener hora del fichaje (formato HHMM)
        v_hora_fichaje := TO_NUMBER(TO_CHAR(V_FICHAJE_ENTRADA, 'HH24MI'));
        
        -- Si fichaje después de 14:15, no computa para saldo
        IF C_HORA_LIMITE_SABADO - v_hora_fichaje < 0 THEN
            RETURN C_MSG_NO_COMPUTA;
        END IF;
        
    ELSE
        -- No es sábado: verificar fichajes incompletos
        IF v_HH <> 0 AND V_HR = 0 THEN
            -- Tiene entrada pero no salida
            RETURN C_MSG_SIN_FICHAJE;
            
        ELSIF v_HH = 0 AND V_HR <> 0 AND v_laborable = C_NO_LABORAL THEN
            -- Tiene salida pero no entrada en día no laborable
            -- Eliminado: antes retornaba 'NO COMPUTA PARA SALDO'
            RETURN '';
        END IF;
    END IF;
    
    -- Buscar incidencias registradas para este fichaje
    BEGIN
        SELECT DISTINCT observaciones
        INTO v_observacion_incidencia
        FROM FICHAJE_INCIDENCIA f
        INNER JOIN personal_new pe ON f.id_funcionario = pe.id_funcionario
        INNER JOIN tr_tipo_incidencia tr ON f.id_tipo_incidencia = tr.id_tipo_incidencia
        WHERE (pe.fecha_baja IS NULL OR pe.fecha_baja > SYSDATE - 1)
          AND f.id_funcionario = V_ID_FUNCIONARIO
          AND f.fecha_incidencia = TRUNC(V_FICHAJE_ENTRADA)
          AND f.id_estado_inc = C_ESTADO_PENDIENTE
          AND ROWNUM = 1;
          
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_observacion_incidencia := '';
    END;
    
    RETURN v_observacion_incidencia;
    
END DEVUELVE_OBSERVACIONES_FICHAJE;
/

