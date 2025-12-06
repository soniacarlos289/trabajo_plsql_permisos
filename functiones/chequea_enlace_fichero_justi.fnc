/**
 * ==============================================================================
 * Funcion: CHEQUEA_ENLACE_FICHERO_JUSTI
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Verifica si existe un fichero justificante para un permiso especifico
 *   y retorna el identificador del fichero o un mensaje indicando que no
 *   esta justificado.
 *
 * PARAMETROS:
 *   @param V_ANNO (VARCHAR2) - Anio del permiso
 *   @param V_ID_FUNCIONARIO (VARCHAR2) - Identificador del funcionario
 *   @param v_ID_PERMISO (VARCHAR2) - Identificador del permiso
 *
 * RETORNO:
 *   @return VARCHAR2 - Resultado de la verificacion:
 *                      - ID del fichero (ANNO+FUNCIONARIO+PERMISO) si existe
 *                      - 'Sin Justificar' si no existe fichero
 *
 * LOGICA:
 *   1. Construye el ID del fichero concatenando los parametros
 *   2. Busca en la tabla FICHEROS_JUSTIFICANTES
 *   3. Retorna el ID si existe, mensaje si no existe
 *
 * DEPENDENCIAS:
 *   - Tabla FICHEROS_JUSTIFICANTES: Almacen de documentos justificantes
 *
 * DIFERENCIA CON CHEQUEA_ENLACE_FICHERO_JUS:
 *   - Esta funcion solo verifica existencia (mas simple)
 *   - No genera HTML, solo retorna texto plano
 *   - Util para validaciones y reportes
 *
 * MEJORAS v2.0:
 *   - Eliminacion de DISTINCT innecesario (id es PK)
 *   - Variable con nombre descriptivo
 *   - Documentacion completa
 *   - Codigo simplificado
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION RRHH.CHEQUEA_ENLACE_FICHERO_JUSTI(
    V_ANNO           IN VARCHAR2,
    V_ID_FUNCIONARIO IN VARCHAR2,
    v_ID_PERMISO     IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constante para mensaje sin justificar
    C_SIN_JUSTIFICAR CONSTANT VARCHAR2(20) := 'Sin Justificar';
    
    -- Variables de trabajo
    v_id_fichero     VARCHAR2(100);
    v_fichero_existe NUMBER := 0;
    v_resultado      VARCHAR2(5012);
    
BEGIN
    -- Construir ID del fichero
    v_id_fichero := V_ANNO || V_ID_FUNCIONARIO || v_ID_PERMISO;
    
    -- Verificar si existe el fichero justificante
    BEGIN
        SELECT 1
          INTO v_fichero_existe
          FROM ficheros_justificantes
         WHERE id = v_id_fichero
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_fichero_existe := 0;
    END;
    
    -- Retornar resultado segun existencia
    IF v_fichero_existe > 0 THEN
        v_resultado := v_id_fichero;
    ELSE
        v_resultado := C_SIN_JUSTIFICAR;
    END IF;
    
    RETURN v_resultado;
END CHEQUEA_ENLACE_FICHERO_JUSTI;
/
