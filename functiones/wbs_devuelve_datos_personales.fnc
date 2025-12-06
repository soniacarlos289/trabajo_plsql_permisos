/*******************************************************************************
 * Función: wbs_devuelve_datos_personales
 * 
 * Propósito:
 *   Devuelve los datos personales de un funcionario en formato JSON,
 *   incluyendo identificación, nombre, apellidos, foto y correo electrónico.
 *
 * @param i_id_funcionario VARCHAR2  ID del funcionario a consultar
 * @return VARCHAR2                  JSON con datos personales o mensaje de error
 *
 * Lógica:
 *   1. Consulta datos del funcionario en personal_new
 *   2. Obtiene login del usuario en apliweb_usuario
 *   3. Construye JSON con información personal
 *   4. Retorna mensaje de error si no se encuentra el usuario
 *
 * Dependencias:
 *   - Tabla: personal_new (datos del personal)
 *   - Tabla: apliweb_usuario (usuarios de aplicación web)
 *
 * Mejoras aplicadas:
 *   - Eliminación DISTINCT innecesario (JOIN por PK)
 *   - Eliminación ORDER BY innecesario (solo 1 registro esperado)
 *   - Constante para mensaje de error
 *   - INNER JOIN explícito en lugar de coma
 *   - Optimización tamaño VARCHAR2
 *   - Documentación JavaDoc completa
 *
 * Ejemplo de uso:
 *   SELECT wbs_devuelve_datos_personales('123456') FROM DUAL;
 *   -- Retorna: "datos": [{"id_funcionario":"123456","nombre":"Juan",...}]
 *
 * Nota:
 *   - La URL de foto está hardcodeada. Considerar parametrizar.
 *   - El dominio de correo está hardcodeado (@aytosalamanca.es)
 *
 * Historial:
 *   - 06/12/2025: Optimización y documentación (Grupo 9)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_datos_personales(
    i_id_funcionario IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constante para mensaje de error
    C_MENSAJE_ERROR CONSTANT VARCHAR2(30) := 'Usuario no encontrado';
    C_DOMINIO_EMAIL CONSTANT VARCHAR2(30) := '@aytosalamanca.es';
    -- ⚠️ TODO: Corregir protocolo HTTP (debe ser http:// o https://)
    C_URL_FOTO CONSTANT VARCHAR2(100) := 'http/probarcelo.aytosa.inet/wbs_pruebas/persona_';
    
    -- Variables
    v_resultado VARCHAR2(4000);
    
BEGIN
    BEGIN
        SELECT '"datos": [' ||
               JSON_OBJECT(
                   'id_funcionario' IS pe.id_funcionario,
                   'nombre' IS nombre,
                   'ape' IS ape1,
                   'ape1' IS ape2,
                   'foto' IS C_URL_FOTO || pe.id_funcionario || '.jpg',
                   'correo' IS login || C_DOMINIO_EMAIL,
                   'nif' IS pe.DNI || DNI_LETRA
               ) || ']'
        INTO v_resultado
        FROM personal_new pe
        INNER JOIN apliweb_usuario u ON pe.id_funcionario = u.id_funcionario
        WHERE pe.id_funcionario = i_id_funcionario;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_resultado := C_MENSAJE_ERROR;
        WHEN OTHERS THEN
            v_resultado := C_MENSAJE_ERROR;
    END;
    
    RETURN v_resultado;
END;
/

