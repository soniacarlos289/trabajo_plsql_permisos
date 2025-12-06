/*******************************************************************************
 * Función: NUMERO_FICHAJE_PERSONA
 * 
 * Propósito:
 *   Busca el primer número de fichaje disponible dentro de un rango específico
 *   que no esté asignado a ninguna persona (ni como código ni como tarjeta).
 *
 * @return NUMBER  Primer número disponible entre 3300 y 20000, o 0 si no hay
 *
 * Lógica:
 *   1. Itera desde 3300 hasta 20000
 *   2. Para cada número, verifica si existe en tabla persona:
 *      - Como código
 *      - Como numtarjeta
 *      - Como numtarjeta+1 (cheque adyacente)
 *   3. Retorna el primer número no encontrado
 *
 * Dependencias:
 *   - Tabla: persona
 *
 * Consideraciones:
 *   - Rango hardcodeado: 3300-20000 (considerar parametrizar)
 *   - Búsqueda lineal puede ser lenta con muchos registros
 *   - Considera numtarjeta+1 para evitar conflictos
 *
 * Mejoras aplicadas:
 *   - Constantes nombradas para límites del rango
 *   - Variables inicializadas explícitamente
 *   - Comentarios explicativos de la lógica
 *   - Documentación JavaDoc completa
 *   - Nombre de variable más descriptivo
 *   - Uso consistente de := para asignaciones
 *
 * Historial:
 *   - 2025-12-06: Optimización y documentación (Grupo 7)
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.NUMERO_FICHAJE_PERSONA RETURN NUMBER IS

    -- Constantes para rango de búsqueda
    C_NUM_INICIO CONSTANT NUMBER := 3300;
    C_NUM_FIN    CONSTANT NUMBER := 20000;
    
    -- Variables
    Result          NUMBER := 0;
    i_contador      NUMBER := C_NUM_INICIO;
    v_codigo        VARCHAR2(6);
    v_encontrado    NUMBER := 0;

BEGIN

    -- Buscar primer número disponible
    WHILE i_contador <= C_NUM_FIN AND v_encontrado = 0 LOOP
        
        BEGIN
            -- Verificar si el número ya está asignado
            SELECT codigo
            INTO v_codigo
            FROM persona
            WHERE (TO_NUMBER(codigo) = i_contador 
                   OR TO_NUMBER(numtarjeta) = i_contador 
                   OR TO_NUMBER(numtarjeta) = i_contador + 1)
              AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                -- Número no encontrado, está disponible
                v_encontrado := i_contador;
        END;
        
        i_contador := i_contador + 1;
        
    END LOOP;
    
    Result := v_encontrado;
    
    RETURN Result;

END NUMERO_FICHAJE_PERSONA;
/

