/**
 * ==============================================================================
 * Funcion: CHEQUEA_FORMULA
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Verifica si un permiso solicitado entra en conflicto con permisos
 *   adyacentes segun las reglas de formula de vacaciones/asuntos propios.
 *   Detecta combinaciones no permitidas entre tipos de permisos consecutivos.
 *
 * PARAMETROS:
 *   @param V_ID_FUNCIONARIO (VARCHAR2) - Identificador del funcionario
 *   @param V_ID_TIPO_PERMISO (VARCHAR2) - Codigo del tipo de permiso solicitado
 *   @param V_ID_TIPO_FUNCIONARIO (VARCHAR2) - Tipo de funcionario:
 *                                             10 = SNP (usa calendario laboral)
 *                                             Otros = Usa dias naturales
 *   @param v_FECHA_INICIO (DATE) - Fecha inicio del permiso solicitado
 *   @param v_FECHA_FIN (DATE) - Fecha fin del permiso solicitado
 *
 * RETORNO:
 *   @return NUMBER - Actualmente siempre retorna 0 (validacion deshabilitada)
 *                    Cuando se active la validacion:
 *                    0 = Sin conflicto (permite solicitar)
 *                    1 = Existe conflicto de formula
 *
 * !! BYPASS ACTIVO !!
 *   La validacion de formula esta DESHABILITADA en produccion.
 *   El codigo original incluye "result:=0" al final que sobreescribe
 *   cualquier validacion. Este comportamiento se ha mantenido para
 *   preservar la compatibilidad con el sistema actual.
 *   Para activar la validacion, eliminar la linea "v_resultado := 0"
 *   al final de la funcion.
 *
 * TIPOS DE PERMISOS CLASIFICADOS:
 *   VA (Vacaciones): 01000, 030XX, 01015, 15000 (>240h)
 *   AP (Asuntos Propios): 02000, 02015, 02081, 02082, 02162, 02241, 02242
 *   OTRO: Cualquier otro tipo
 *
 * REGLAS DE FORMULA (cuando activa):
 *   - AP + VA = Conflicto (en cualquier orden)
 *   - OTRO + AP = Conflicto (cuando AP esta adyacente)
 *
 * LOGICA:
 *   1. Clasifica el permiso solicitado (VA/AP/OTRO)
 *   2. Busca permisos en el dia anterior (laboral para SNP)
 *   3. Busca permisos en el dia posterior (laboral para SNP)
 *   4. Aplica matriz de compatibilidad entre tipos
 *
 * DEPENDENCIAS:
 *   - Tabla PERMISO: Registro de permisos
 *   - Funcion CALCULA_ANT_POST: Calculo de dias laborales adyacentes
 *
 * MEJORAS v2.0:
 *   - Uso de CASE en lugar de IF anidados
 *   - Constantes para tipos de permisos
 *   - Eliminacion de codigo duplicado con funcion auxiliar
 *   - Documentacion completa de reglas de negocio
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION RRHH.CHEQUEA_FORMULA(
    V_ID_FUNCIONARIO      IN VARCHAR2,
    V_ID_TIPO_PERMISO     IN VARCHAR2,
    V_ID_TIPO_FUNCIONARIO IN VARCHAR2,
    v_FECHA_INICIO        IN DATE,
    v_FECHA_FIN           IN DATE
) RETURN NUMBER IS
    -- Constantes de tipo de permiso
    C_TIPO_FUNCIONARIO_SNP CONSTANT VARCHAR2(2) := '10';
    C_HORAS_MIN_15000      CONSTANT NUMBER := 240;
    
    -- Constantes de clasificacion
    C_CLASE_VA   CONSTANT VARCHAR2(4) := 'VA';
    C_CLASE_AP   CONSTANT VARCHAR2(4) := 'AP';
    C_CLASE_OTRO CONSTANT VARCHAR2(4) := 'OTRO';
    
    -- Variables de fechas
    v_fecha_ini_trabajo DATE;
    v_fecha_fin_trabajo DATE;
    v_dia_anterior      DATE;
    v_dia_posterior     DATE;
    
    -- Variables de clasificacion
    v_permiso_solicitado     VARCHAR2(5);
    v_permiso_ant_encontrado VARCHAR2(5);
    v_permiso_post_encontrado VARCHAR2(5);
    
    -- Variables de busqueda
    v_fecha_aux       DATE;
    v_tipo_permiso_3  VARCHAR2(3);
    v_tiene_anterior  NUMBER := 0;
    v_tiene_posterior NUMBER := 0;
    
    -- Resultado
    v_resultado NUMBER;
    
    /**
     * Funcion auxiliar para clasificar tipo de permiso
     */
    FUNCTION clasificar_permiso(p_prefijo VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        RETURN CASE p_prefijo
            WHEN '010' THEN C_CLASE_VA
            WHEN '020' THEN C_CLASE_AP
            WHEN '021' THEN C_CLASE_AP
            WHEN '022' THEN C_CLASE_AP
            WHEN '150' THEN C_CLASE_VA
            WHEN '030' THEN C_CLASE_VA
            ELSE NULL
        END;
    END clasificar_permiso;
    
BEGIN
    -- Inicializar
    v_fecha_ini_trabajo := v_FECHA_INICIO;
    v_fecha_fin_trabajo := v_FECHA_FIN;
    v_permiso_ant_encontrado := '';
    v_permiso_post_encontrado := '';
    
    -- Clasificar permiso solicitado
    IF V_ID_TIPO_PERMISO = '01000' OR
       SUBSTR(V_ID_TIPO_PERMISO, 1, 3) = '030' OR
       V_ID_TIPO_PERMISO = '01015' OR
       V_ID_TIPO_PERMISO = '15000' THEN
        v_permiso_solicitado := C_CLASE_VA;
    ELSIF V_ID_TIPO_PERMISO IN ('02000', '02015', '02081', '02082', '02162', '02241', '02242') THEN
        v_permiso_solicitado := C_CLASE_AP;
    ELSE
        v_permiso_solicitado := C_CLASE_OTRO;
    END IF;
    
    -- BUSQUEDA ANTERIOR
    -- Determinar dia anterior (laboral para SNP)
    IF V_ID_TIPO_FUNCIONARIO = C_TIPO_FUNCIONARIO_SNP THEN
        v_dia_anterior := calcula_ant_post(v_fecha_ini_trabajo, 'A');
    ELSE
        v_dia_anterior := v_fecha_ini_trabajo - 1;
    END IF;
    
    -- Buscar permiso en el dia anterior
    BEGIN
        SELECT fecha_inicio, SUBSTR(id_tipo_permiso, 1, 3)
          INTO v_fecha_aux, v_tipo_permiso_3
          FROM permiso
         WHERE id_funcionario = V_ID_FUNCIONARIO
           AND (id_tipo_permiso IN ('01000', '02000', '02015', '02081', '02082', '02162', '02241', '02242', '01015')
                OR id_tipo_permiso LIKE '030%'
                OR (id_tipo_permiso = '15000' AND total_horas > C_HORAS_MIN_15000))
           AND v_dia_anterior BETWEEN fecha_inicio AND fecha_fin
           AND (anulado = 'NO' OR anulado IS NULL)
           AND id_estado NOT IN ('30', '31', '32', '40', '41')
           AND ROWNUM < 2;
        
        v_tiene_anterior := 1;
        v_permiso_ant_encontrado := clasificar_permiso(v_tipo_permiso_3);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_tiene_anterior := 0;
            v_permiso_ant_encontrado := '';
    END;
    
    -- BUSQUEDA POSTERIOR
    -- Determinar dia posterior (laboral para SNP)
    IF V_ID_TIPO_FUNCIONARIO = C_TIPO_FUNCIONARIO_SNP THEN
        v_dia_posterior := calcula_ant_post(v_fecha_fin_trabajo, 'P');
    ELSE
        v_dia_posterior := v_fecha_fin_trabajo + 1;
    END IF;
    
    -- Buscar permiso en el dia posterior
    BEGIN
        SELECT fecha_fin, SUBSTR(id_tipo_permiso, 1, 3)
          INTO v_fecha_aux, v_tipo_permiso_3
          FROM permiso
         WHERE id_funcionario = V_ID_FUNCIONARIO
           AND (id_tipo_permiso IN ('01000', '02000', '02015', '02081', '02082', '02162', '02241', '02242', '01015')
                OR id_tipo_permiso LIKE '030%'
                OR (id_tipo_permiso = '15000' AND total_horas > C_HORAS_MIN_15000))
           AND v_dia_posterior BETWEEN fecha_inicio AND fecha_fin
           AND (anulado = 'NO' OR anulado IS NULL)
           AND id_estado NOT IN ('30', '31', '32', '40', '41')
           AND ROWNUM < 2;
        
        v_tiene_posterior := 1;
        v_permiso_post_encontrado := clasificar_permiso(v_tipo_permiso_3);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_tiene_posterior := 0;
            v_permiso_post_encontrado := '';
    END;
    
    -- APLICAR FORMULA DE COMPATIBILIDAD
    -- Conflicto: AP + VA en cualquier orden, o OTRO con AP adyacente
    IF (v_permiso_ant_encontrado = C_CLASE_AP AND v_permiso_solicitado = C_CLASE_VA) OR
       (v_permiso_ant_encontrado = C_CLASE_VA AND v_permiso_solicitado = C_CLASE_AP) OR
       (v_permiso_solicitado = C_CLASE_OTRO AND v_permiso_ant_encontrado = C_CLASE_AP) OR
       (v_permiso_post_encontrado = C_CLASE_AP AND v_permiso_solicitado = C_CLASE_VA) OR
       (v_permiso_post_encontrado = C_CLASE_VA AND v_permiso_solicitado = C_CLASE_AP) OR
       (v_permiso_solicitado = C_CLASE_OTRO AND v_permiso_post_encontrado = C_CLASE_AP) THEN
        v_resultado := 1;
    ELSE
        v_resultado := 0;
    END IF;
    
    -- !! BYPASS ACTIVO !! (preservado del codigo original)
    -- Esta linea deshabilita la validacion de formula.
    -- Para activar la validacion, comentar o eliminar la siguiente linea:
    v_resultado := 0;
    
    RETURN v_resultado;
END CHEQUEA_FORMULA;
/
