/**
 * ==============================================================================
 * Funcion: CHEQUEA_INTERVALO_PERMISO
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Obtiene el HTML de estado de un funcionario para una fecha especifica
 *   del calendario, verificando si tiene permiso activo o baja. Utilizada
 *   para mostrar el estado en calendarios de visualizacion.
 *
 * PARAMETROS:
 *   @param V_ID_FUNCIONARIO (VARCHAR2) - Identificador del funcionario
 *   @param v_DIA_CALENDARIO (DATE) - Fecha a consultar
 *
 * RETORNO:
 *   @return VARCHAR2 - HTML de celda con color segun estado:
 *                      - Celda coloreada segun tipo de permiso/estado
 *                      - '<td bgcolor=FFFFFF> </td>' si sin permiso ni baja
 *
 * LOGICA:
 *   1. Busca permiso activo para la fecha
 *   2. Si no hay permiso, busca baja activa
 *   3. Retorna HTML segun configuracion de colores
 *
 * DEPENDENCIAS:
 *   - Tabla PERMISO: Permisos de funcionarios
 *   - Tabla BAJAS_ILT: Bajas por incapacidad
 *   - Tabla TR_TIPO_COLUMNA_CALENDARIO: Configuracion de colores por tipo
 *
 * ESTADOS EXCLUIDOS EN PERMISOS:
 *   - 30: Rechazado
 *   - 31: Rechazado por superior
 *   - 32: Rechazado por RRHH
 *   - 40: Cancelado
 *
 * DIFERENCIA CON CHEQUEA_INTER_PERMISO_FICHAJE:
 *   - Esta funcion solo retorna estado visual (mas simple)
 *   - No incluye informacion de fichajes
 *   - Util para calendarios de permisos sin fichaje
 *
 * MEJORAS v2.0:
 *   - Constantes para estados y tipos
 *   - Documentacion completa
 *   - Estructura simplificada
 *   - Variables descriptivas
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION RRHH.CHEQUEA_INTERVALO_PERMISO(
    V_ID_FUNCIONARIO IN VARCHAR2,
    v_DIA_CALENDARIO IN DATE
) RETURN VARCHAR2 IS
    -- Constantes
    C_CELDA_BLANCA  CONSTANT VARCHAR2(50) := '<td bgcolor=FFFFFF> </td>';
    C_TIPO_BAJA     CONSTANT VARCHAR2(5) := '88888';
    C_ESTADO_BAJA   CONSTANT VARCHAR2(2) := '80';
    
    -- Variables de trabajo
    v_resultado     VARCHAR2(512);
    v_html_estado   VARCHAR2(512);
    v_tiene_permiso NUMBER := 0;
    
BEGIN
    -- Inicializar con celda blanca
    v_html_estado := C_CELDA_BLANCA;
    
    -- 1. Buscar permiso activo
    BEGIN
        SELECT tc.desc_tipo_columna
          INTO v_html_estado
          FROM permiso p, rrhh.tr_tipo_columna_calendario tc
         WHERE p.id_funcionario = V_ID_FUNCIONARIO
           AND p.id_tipo_permiso = tc.id_tipo_permiso
           AND p.id_estado = tc.id_tipo_estado
           AND v_DIA_CALENDARIO BETWEEN p.fecha_inicio AND p.fecha_fin
           AND (p.anulado = 'NO' OR p.anulado IS NULL)
           AND p.id_estado NOT IN ('30', '31', '32', '40')
           AND ROWNUM < 2;
        
        v_tiene_permiso := 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_html_estado := C_CELDA_BLANCA;
            v_tiene_permiso := 0;
    END;
    
    -- 2. Si no hay permiso, buscar baja
    IF v_tiene_permiso = 0 THEN
        BEGIN
            SELECT DISTINCT tc.desc_tipo_columna
              INTO v_html_estado
              FROM bajas_ilt b, rrhh.tr_tipo_columna_calendario tc
             WHERE b.id_funcionario = V_ID_FUNCIONARIO
               AND C_TIPO_BAJA = tc.id_tipo_permiso
               AND C_ESTADO_BAJA = tc.id_tipo_estado
               AND v_DIA_CALENDARIO BETWEEN b.fecha_inicio AND b.fecha_fin
               AND (b.anulada = 'NO' OR b.anulada IS NULL)
               AND ROWNUM < 2;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_html_estado := C_CELDA_BLANCA;
        END;
    END IF;
    
    v_resultado := v_html_estado;
    
    RETURN v_resultado;
END CHEQUEA_INTERVALO_PERMISO;
/
