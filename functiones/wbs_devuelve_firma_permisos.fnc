/*******************************************************************************
 * Función: wbs_devuelve_firma_permisos
 * 
 * Propósito:
 *   Devuelve un JSON con los permisos firmados por el funcionario responsable,
 *   limitando opcionalmente el número de permisos devueltos.
 *
 * @param i_id_funcionario VARCHAR2  ID del funcionario que firma permisos
 * @param cuantos_permisos NUMBER    Cantidad de permisos a devolver (0=todos)
 * @return CLOB                      JSON con array de permisos firmados
 *
 * Lógica:
 *   1. Recupera permisos de funcionarios que requieren firma del responsable
 *   2. Filtra por permisos en estado "20" (solicitado) del último año
 *   3. Construye JSON con datos del funcionario y detalles del permiso
 *   4. Limita resultados según parámetro cuantos_permisos
 *
 * Dependencias:
 *   - Tabla: funcionario_firma (relación firmante-funcionario)
 *   - Tabla: personal_new (datos del empleado)
 *   - Tabla: permiso (solicitudes de permiso)
 *   - Tabla: tr_tipo_permiso (tipos de permiso por año)
 *
 * Mejoras aplicadas:
 *   - Conversión cursor manual → FOR LOOP
 *   - Constantes nombradas para estados y días
 *   - INNER JOIN explícito en lugar de sintaxis antigua
 *   - Inicialización explícita de variables
 *   - URL base como constante
 *   - Documentación JavaDoc completa
 *
 * Notas:
 *   - Estado '20' representa permisos solicitados pendientes de aprobación
 *   - Período de búsqueda: 365 días anteriores a la fecha actual
 *   - URL de fotos apunta a servidor de pruebas (TODO: parametrizar)
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 10 - Cursor a FOR LOOP, constantes
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.wbs_devuelve_firma_permisos(
    i_id_funcionario IN VARCHAR2,
    cuantos_permisos IN NUMBER
) RETURN CLOB IS
    -- Constantes
    C_ESTADO_SOLICITADO   CONSTANT VARCHAR2(2) := '20';
    C_DIAS_BUSQUEDA       CONSTANT NUMBER := 365;
    C_URL_FOTO_BASE       CONSTANT VARCHAR2(100) := 'http/probarcelo.aytosa.inet/wbs_pruebas/persona_';
    
    -- Variables
    v_resultado           CLOB;
    v_datos               CLOB;
    v_contador            NUMBER := 0;
    
BEGIN
    v_datos := '';
    
    -- Itera sobre permisos que requieren firma del funcionario especificado
    FOR rec IN (
        SELECT DISTINCT
            JSON_OBJECT(
                'id_funcionario' IS pe.id_funcionario,
                'nombre' IS pe.nombre,
                'ape1' IS pe.ape1,
                'ape2' IS pe.ape2,
                'foto' IS C_URL_FOTO_BASE || pe.id_funcionario || '.jpg',
                'tipo' IS tr.desc_tipo_permiso,
                'num_dias' IS per.num_dias,
                'fecha_inicio' IS per.fecha_inicio,
                'fecha_fin' IS per.fecha_fin
            ) AS datos_json,
            per.id_permiso
        FROM funcionario_firma f
        INNER JOIN personal_new pe ON f.id_funcionario = pe.id_funcionario
        INNER JOIN permiso per ON per.id_funcionario = pe.id_funcionario
        INNER JOIN tr_tipo_permiso tr ON tr.id_tipo_permiso = per.id_tipo_permiso 
                                     AND tr.id_ano = per.id_ano
        WHERE f.id_js = i_id_funcionario
          AND per.fecha_soli > SYSDATE - C_DIAS_BUSQUEDA
          AND per.id_estado = C_ESTADO_SOLICITADO
        ORDER BY per.id_permiso
    ) LOOP
        v_contador := v_contador + 1;
        
        -- Limita el número de permisos si se especificó
        IF cuantos_permisos = 0 OR v_contador <= cuantos_permisos THEN
            IF v_contador = 1 THEN
                v_datos := rec.datos_json;
            ELSE
                v_datos := v_datos || ',' || rec.datos_json;
            END IF;
        END IF;
    END LOOP;
    
    v_resultado := '"firma": [' || v_datos || ']';
    RETURN v_resultado;
    
END wbs_devuelve_firma_permisos;
/

