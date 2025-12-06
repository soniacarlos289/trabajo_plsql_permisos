/**
 * ==============================================================================
 * Funcion: CALCULAR_LETRA_NIF
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Calcula la letra de verificacion del NIF (Numero de Identificacion Fiscal)
 *   espanol a partir del numero de DNI, siguiendo el algoritmo oficial.
 *
 * PARAMETROS:
 *   @param p_dni (NUMBER) - Numero del DNI sin la letra (8 digitos)
 *                           Ejemplo: 12345678
 *
 * RETORNO:
 *   @return CHAR - Letra de verificacion correspondiente al DNI.
 *                  Una de las 23 letras validas: TRWAGMYFPDXBNJZSQVHLCKE
 *
 * ALGORITMO OFICIAL:
 *   1. Se divide el numero del DNI entre 23
 *   2. El resto de la division (0-22) determina la letra
 *   3. Mapeo: 0=T, 1=R, 2=W, 3=A, 4=G, 5=M, 6=Y, 7=F, 8=P, 9=D,
 *            10=X, 11=B, 12=N, 13=J, 14=Z, 15=S, 16=Q, 17=V, 18=H,
 *            19=L, 20=C, 21=K, 22=E
 *
 * NOTA:
 *   Las letras I, O y U no se utilizan para evitar confusion con
 *   los numeros 1, 0 y V respectivamente.
 *
 * EJEMPLO:
 *   DNI: 12345678
 *   Calculo: MOD(12345678, 23) = 14
 *   Letra: Z (posicion 15, indice 14)
 *   NIF completo: 12345678Z
 *
 * VALIDACION:
 *   Para validar un NIF existente, comparar la letra calculada
 *   con la letra proporcionada.
 *
 * MEJORAS v2.0:
 *   - Documentacion completa del algoritmo oficial
 *   - Ejemplos de uso
 *   - Sin cambios funcionales (funcion ya optimizada)
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION RRHH.CALCULAR_LETRA_NIF(
    p_dni NUMBER
) RETURN CHAR IS
    -- Constante con las letras validas del NIF en orden
    C_LETRAS_NIF CONSTANT VARCHAR2(23) := 'TRWAGMYFPDXBNJZSQVHLCKE';
    C_DIVISOR    CONSTANT NUMBER := 23;
    
BEGIN
    -- Calcular y retornar la letra correspondiente
    RETURN SUBSTR(C_LETRAS_NIF, MOD(p_dni, C_DIVISOR) + 1, 1);
END CALCULAR_LETRA_NIF;
/

