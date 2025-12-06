/**
 * ==============================================================================
 * Funcion: CALCULA_BOMBEROS_OPCION
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Determina si un funcionario bombero puede solicitar un tipo de permiso
 *   especifico, basandose en las reglas de compatibilidad entre permisos
 *   de compensacion de bomberos.
 *
 * PARAMETROS:
 *   @param v_ID_ANO (VARCHAR2) - Anio del ejercicio de permisos (formato YYYY)
 *   @param V_ID_FUNCIONARIO (VARCHAR2) - Identificador unico del funcionario
 *   @param v_id_tipo_permiso (VARCHAR2) - Codigo del tipo de permiso a solicitar
 *
 * RETORNO:
 *   @return VARCHAR2 - Resultado de la validacion:
 *                      - Codigo del permiso: El funcionario puede solicitarlo
 *                      - '0': No puede solicitar por conflicto de reglas
 *                      - '' (vacio): No tiene permisos previos, puede solicitar
 *
 * TIPOS DE PERMISOS BOMBEROS:
 *   - 02081: Compensacion tipo 1
 *   - 02082: Compensacion tipo 2
 *   - 02162: Compensacion especial (limite 2 dias)
 *   - 02241: Compensacion adicional tipo 1
 *   - 02242: Compensacion adicional tipo 2
 *
 * LOGICA DE NEGOCIO:
 *   1. Verifica si el funcionario tiene permisos previos de compensacion
 *   2. Evalua condiciones especiales:
 *      - Permiso 02162 con dias != 2
 *      - Permisos 02241/02081 con dias = 0
 *   3. Aplica matriz de compatibilidad:
 *      - 02162 bloquea solicitud de 02081/02241
 *      - 02241/02081 bloquea solicitud de 02082/02162/02242
 *
 * DEPENDENCIAS:
 *   - Tabla PERMISO_FUNCIONARIO: Registro de permisos solicitados
 *
 * MEJORAS v2.0:
 *   - Constantes para codigos de permisos
 *   - Uso de coleccion para lista de permisos
 *   - Documentacion detallada de reglas de negocio
 *   - Estructura de codigo mas clara
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION rrhh.CALCULA_BOMBEROS_OPCION(
    v_ID_ANO          IN VARCHAR2,
    V_ID_FUNCIONARIO  IN VARCHAR2,
    v_id_tipo_permiso IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes de tipos de permiso bomberos
    C_PERM_COMP_1        CONSTANT VARCHAR2(5) := '02081';
    C_PERM_COMP_2        CONSTANT VARCHAR2(5) := '02082';
    C_PERM_ESPECIAL      CONSTANT VARCHAR2(5) := '02162';
    C_PERM_ADICIONAL_1   CONSTANT VARCHAR2(5) := '02241';
    C_PERM_ADICIONAL_2   CONSTANT VARCHAR2(5) := '02242';
    C_DIAS_ESPECIAL      CONSTANT NUMBER := 2;
    
    -- Variables de trabajo
    v_result          VARCHAR2(250);
    v_id_permiso_min  VARCHAR2(259);
    v_count_permisos  NUMBER := 0;
    
BEGIN
    -- Inicializar resultado
    -- v_id_permiso_min se inicializa a NULL para consistencia con la logica de comparacion
    v_result := '';
    v_id_permiso_min := NULL;
    
    -- Verificar si el funcionario tiene permisos de compensacion
    SELECT COUNT(*)
      INTO v_count_permisos
      FROM permiso_funcionario a
     WHERE a.id_ano = v_ID_ANO
       AND a.id_funcionario = V_ID_FUNCIONARIO
       AND a.id_tipo_permiso IN (C_PERM_COMP_1, C_PERM_COMP_2, C_PERM_ESPECIAL, 
                                  C_PERM_ADICIONAL_1, C_PERM_ADICIONAL_2);
    
    -- Si no tiene permisos previos, retornar vacio
    IF v_count_permisos = 0 THEN
        RETURN v_result;
    END IF;
    
    -- Buscar el permiso minimo con condiciones especiales
    BEGIN
        SELECT MIN(id_tipo_permiso)
          INTO v_id_permiso_min
          FROM permiso_funcionario a
         WHERE a.id_ano = v_ID_ANO
           AND a.id_funcionario = V_ID_FUNCIONARIO
           AND a.id_tipo_permiso IN (C_PERM_COMP_1, C_PERM_COMP_2, C_PERM_ESPECIAL, 
                                      C_PERM_ADICIONAL_1, C_PERM_ADICIONAL_2)
           AND (
               (a.id_tipo_permiso = C_PERM_ESPECIAL AND num_dias <> C_DIAS_ESPECIAL) OR
               (a.id_tipo_permiso = C_PERM_ADICIONAL_1 AND num_dias = 0) OR
               (a.id_tipo_permiso = C_PERM_COMP_1 AND num_dias = 0)
           );
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_id_permiso_min := NULL;
    END;
    
    -- Aplicar reglas de compatibilidad
    IF v_id_permiso_min IS NULL THEN
        v_result := v_id_tipo_permiso;
    ELSIF v_id_permiso_min = C_PERM_ESPECIAL AND
          v_id_tipo_permiso IN (C_PERM_COMP_1, C_PERM_ADICIONAL_1) THEN
        -- Permiso especial bloquea comp_1 y adicional_1
        v_result := '0';
    ELSIF v_id_permiso_min IN (C_PERM_ADICIONAL_1, C_PERM_COMP_1) AND
          v_id_tipo_permiso IN (C_PERM_COMP_2, C_PERM_ESPECIAL, C_PERM_ADICIONAL_2) THEN
        -- Adicional_1/Comp_1 bloquean comp_2, especial y adicional_2
        v_result := '0';
    ELSE
        v_result := v_id_tipo_permiso;
    END IF;
    
    RETURN v_result;
END CALCULA_BOMBEROS_OPCION;
/

