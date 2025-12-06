/*******************************************************************************
 * Función: wbs_devuelve_roles
 * 
 * Propósito:
 *   Devuelve los roles y módulos habilitados para un funcionario en la
 *   aplicación web, incluyendo su foto.
 *
 * @param i_id_funcionario VARCHAR2  ID del funcionario
 * @return CLOB                      JSON con módulos habilitados y foto
 *
 * Lógica:
 *   1. Verifica si tiene habilitado el módulo de saldo horario (fichaje)
 *   2. Verifica si tiene habilitado el módulo de firma de planificación
 *   3. Verifica si tiene habilitado el fichaje de teletrabajo
 *   4. Obtiene el tipo de funcionario desde personal_new
 *   5. Construye JSON con estados de cada módulo
 *   6. Incluye foto del funcionario usando función wbs_devuelve_fichero_foto
 *
 * Dependencias:
 *   - Tabla: apliweb_usuario (permisos de aplicación web)
 *   - Tabla: funcionario_fichaje (configuración fichaje)
 *   - Tabla: personal_new (datos del empleado)
 *   - Tabla: tr_tipo_funcionario (tipos de funcionario)
 *   - Función: wbs_devuelve_fichero_foto (obtiene foto base64)
 *
 * Mejoras aplicadas:
 *   - Eliminación SELECT FROM DUAL innecesario
 *   - Constantes nombradas para valores booleanos y prefijo admin
 *   - INNER JOIN explícito en lugar de sintaxis antigua
 *   - Construcción directa de JSON sin consulta adicional
 *   - Eliminación de variables no utilizadas
 *   - Documentación JavaDoc completa
 *
 * Notas:
 *   - Los valores booleanos se devuelven como strings 'true'/'false'
 *   - Excluye usuarios administrativos (login like 'adm%')
 *   - En caso de error, asigna 'false' a todos los módulos
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 10 - Eliminación DUAL, constantes
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_roles(
    i_id_funcionario IN VARCHAR2
) RETURN CLOB IS
    -- Constantes
    C_FALSE               CONSTANT VARCHAR2(5) := 'false';
    C_TRUE                CONSTANT VARCHAR2(4) := 'true';
    C_PREFIJO_ADMIN       CONSTANT VARCHAR2(3) := 'adm';
    
    -- Variables
    v_resultado           CLOB;
    v_saldo_horario       VARCHAR2(123);
    v_fichaje_teletrabajo VARCHAR2(123);
    v_firma_planificacion VARCHAR2(123);
    v_desc_tipo_func      VARCHAR2(12000);
    v_foto                CLOB;
    
BEGIN
    v_saldo_horario := C_FALSE;
    v_fichaje_teletrabajo := C_FALSE;
    v_firma_planificacion := C_FALSE;
    
    -- Verifica permisos de saldo horario y firma de planificación
    BEGIN
        SELECT DISTINCT
            CASE WHEN id_fichaje IS NULL THEN C_FALSE ELSE C_TRUE END,
            CASE WHEN firma = 0 THEN C_FALSE ELSE C_TRUE END
        INTO v_saldo_horario, v_firma_planificacion
        FROM apliweb_usuario
        WHERE id_funcionario = i_id_funcionario
          AND login NOT LIKE C_PREFIJO_ADMIN || '%'
          AND ROWNUM < 2;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_saldo_horario := C_FALSE;
            v_firma_planificacion := C_FALSE;
        WHEN OTHERS THEN
            v_saldo_horario := C_FALSE;
            v_firma_planificacion := C_FALSE;
    END;
    
    -- Verifica permiso de fichaje teletrabajo
    BEGIN
        SELECT DISTINCT
            CASE WHEN teletrabajo = 0 THEN C_FALSE ELSE C_TRUE END
        INTO v_fichaje_teletrabajo
        FROM funcionario_fichaje
        WHERE id_funcionario = i_id_funcionario
          AND ROWNUM < 2;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_fichaje_teletrabajo := C_FALSE;
        WHEN OTHERS THEN
            v_fichaje_teletrabajo := C_FALSE;
    END;
    
    -- Obtiene tipo de funcionario
    BEGIN
        SELECT DISTINCT desc_tipo_funcionario
        INTO v_desc_tipo_func
        FROM personal_new p
        INNER JOIN tr_tipo_funcionario tr ON p.tipo_funcionario2 = tr.id_tipo_funcionario
        WHERE id_funcionario = i_id_funcionario
          AND ROWNUM < 2;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_desc_tipo_func := C_FALSE;
        WHEN OTHERS THEN
            v_desc_tipo_func := C_FALSE;
    END;
    
    -- Construye JSON con módulos habilitados
    v_resultado := '"modulos": [' ||
        JSON_OBJECT(
            'saldo_horario' IS v_saldo_horario,
            'firma_planificacion' IS v_firma_planificacion,
            'fichaje_teletrabajo' IS v_fichaje_teletrabajo,
            'tipo_funcionario' IS v_desc_tipo_func
        ) || ']';
    
    -- Obtiene y añade foto del funcionario
    v_foto := wbs_devuelve_fichero_foto(i_id_funcionario);
    v_resultado := v_resultado || v_foto;
    
    RETURN v_resultado;
    
END wbs_devuelve_roles;
/

