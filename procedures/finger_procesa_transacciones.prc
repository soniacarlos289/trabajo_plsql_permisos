CREATE OR REPLACE PROCEDURE RRHH.FINGER_PROCESA_TRANSACCIONES (
  i_id_funcionario        IN     VARCHAR2,
  v_fecha_p               IN     VARCHAR2,
  i_cadena_fichaje        IN     VARCHAR2,
  i_cadena_computa        IN     VARCHAR2,
  i_cadena_observaciones  OUT    VARCHAR2
) IS
  /**
   * @description Procesa y valida modificaciones masivas de fichajes y transacciones de funcionario
   * @details Procedimiento complejo que gestiona actualizaciones web de fichajes y transacciones:
   *          1. Procesa cadena de fichajes (i_cadena_fichaje) con operaciones: 0=sin cambio, 1=modificado, 2=nuevo, 3=eliminar
   *          2. Procesa cadena de cómputos (i_cadena_computa) con tipos horas: 1/2=horas extras, 0=computa saldo
   *          3. Valida que transacciones con horas extras NO puedan eliminarse
   *          4. Ejecuta chequeos de horas extras antes de actualizar transacciones
   *          5. Recalcula saldo finger tras procesar cambios (diferenciado por tipo funcionario)
   *          
   *          Formato cadenas:
   *          - i_cadena_fichaje: CLAVE + número + ; + FICHAJE + HH:MM + ; + VALOR + número + ; + *
   *          - i_cadena_computa: CLAVE_FICHAJE + número + ; + VALOR + número + ; + TIPO_HORAS + número + ; + *
   * @param i_id_funcionario ID del funcionario cuyas transacciones se procesan
   * @param v_fecha_p Fecha de las transacciones formato 'DD/MM/YYYY'
   * @param i_cadena_fichaje Cadena codificada con transacciones y operaciones
   * @param i_cadena_computa Cadena codificada con cómputos de fichajes y tipos horas
   * @param i_cadena_observaciones OUT Mensaje resultado: 'Todo es correcto' o error
   * @notes 
   *   - PIN funcionario: busca en funcionario_fichaje con contrato vigente, pin > 0
   *   - Si PIN = 0 o funcionario sin datos → no procesa nada
   *   - Tipo horas: 1=horas extras compensadas, 2=horas extras pagadas, 0 o 4=especial dedicación
   *   - Validación doble: fichaje_chequea_hextras (fichajes) + fichaje_chequea_hextras_tran (transacciones)
   *   - Se aplica a pin y pin2 (funcionarios con doble tarjeta)
   *   - Tipo 21 (Policía): usa finger_calcula_saldo_policia, otros finger_calcula_saldo
   *   - Código comentado histórico: consulta antigua a omesa.persona
   */

  -- Constantes
  C_TIPO_FUNC_POLICIA      CONSTANT NUMBER := 21;
  C_TIPO_HORAS_ESPECIAL    CONSTANT NUMBER := 4;
  C_TIPO_HORAS_DEFAULT     CONSTANT NUMBER := 0;
  C_OPERACION_HEXTRAS_1    CONSTANT NUMBER := 1;
  C_OPERACION_HEXTRAS_2    CONSTANT NUMBER := 2;
  C_OPERACION_SIN_CAMBIO   CONSTANT NUMBER := 0;
  C_OPERACION_MODIFICADO   CONSTANT NUMBER := 1;
  C_OPERACION_NUEVO        CONSTANT NUMBER := 2;
  C_OPERACION_ELIMINAR     CONSTANT NUMBER := 3;
  C_LONGITUD_BUFFER        CONSTANT NUMBER := 200;
  C_DELIMITADOR_REG        CONSTANT VARCHAR2(1) := '*';
  C_PIN_INVALIDO           CONSTANT NUMBER := 0;
  C_FECHA_FORMATO          CONSTANT VARCHAR2(10) := 'DD/MM/YYYY';
  C_MSG_CORRECTO           CONSTANT VARCHAR2(50) := 'Todo es correcto';
  C_MSG_ERROR_HEXTRAS      CONSTANT VARCHAR2(100) := 'No se pueden eliminar transacciones que afectan a horas extras.';

  -- Variables PIN y funcionario
  i_pin                VARCHAR2(4);
  i_pin2               VARCHAR2(4);
  i_codigo_pers_c1     VARCHAR2(5);
  i_tipo_funcionario2  NUMBER;
  i_fecha_p            DATE;

  -- Variables procesamiento cadenas
  i_longitud           NUMBER;
  i_longitud_fichajes  NUMBER;
  i_longitud_computa   NUMBER;
  i_longitud_actualiza NUMBER;
  i_cadena_computa_tmp VARCHAR2(1000);
  i_cadena_fichaje_tmp VARCHAR2(1000);
  lista_no_actualiza   VARCHAR2(1000);

  -- Variables operaciones
  i_fichaje            VARCHAR2(30);
  i_clave              VARCHAR2(40);
  i_operacion          NUMBER;
  i_tipo_horas         NUMBER;

BEGIN

  -- **********************************
  -- FASE 1: Convertir fecha parámetro
  -- **********************************
  i_fecha_p := TO_DATE(v_fecha_p, C_FECHA_FORMATO);

  -- **********************************
  -- FASE 2: Obtener PIN y datos funcionario
  -- **********************************
  BEGIN
    /* Consulta antigua comentada - mantener por referencia histórica
    SELECT numtarjeta, codigo, tipo_funcionario2 
    INTO i_pin, i_codigo_pers_c1, i_tipo_funcionario2
    FROM rrhh.personal_new p
    INNER JOIN omesa.persona pr ON u.id_fichaje = pr.codigo
    INNER JOIN apliweb.usuario u ON lpad(p.id_funcionario, 6, 0) = lpad(u.id_funcionario, 6, 0)
    WHERE p.id_funcionario = i_id_funcionario
      AND u.id_fichaje IS NOT NULL
      AND rownum < 2;
    */
    
    SELECT DISTINCT 
           LPAD(pin, 4, '0'),
           codpers,
           tipo_funcionario2,
           LPAD(pin2, 4, '0')
    INTO i_pin, i_codigo_pers_c1, i_tipo_funcionario2, i_pin2
    FROM funcionario_fichaje f
    INNER JOIN personal_new p ON LPAD(p.id_funcionario, 6, 0) = LPAD(f.id_funcionario, 6, 0)
    WHERE p.id_funcionario = i_id_funcionario
      AND (p.fecha_fin_contrato IS NULL OR p.fecha_fin_contrato > SYSDATE)
      AND pin > 0
    ORDER BY 1;
    
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      i_pin := C_PIN_INVALIDO;
  END;

  -- **********************************
  -- FASE 3: Validar PIN y procesar si válido
  -- **********************************
  IF i_pin > C_PIN_INVALIDO THEN

    -- **********************************
    -- FASE 4: Procesar cadena de cómputos (validar horas extras en fichajes)
    -- **********************************
    -- Formato: CLAVE_FICHAJE + número + ; + VALOR + número + ; + TIPO_HORAS + número + ; + *
    -- VALOR: 0=computa saldo, 1=horas extras compensadas, 2=horas extras pagadas
    
    i_cadena_computa_tmp := '';
    i_longitud_computa := LENGTH(i_cadena_computa);
    i_longitud := 1;

    WHILE i_longitud_computa > i_longitud LOOP
      
      i_cadena_computa_tmp := SUBSTR(i_cadena_computa, i_longitud, C_LONGITUD_BUFFER);
      i_clave := devuelve_valor_campo(i_cadena_computa_tmp, 'CLAVE_FICHAJE');
      i_operacion := devuelve_valor_campo(i_cadena_computa_tmp, 'VALOR');
      i_tipo_horas := devuelve_valor_campo(i_cadena_computa_tmp, 'TIPO_HORAS');

      -- Si no se especifica tipo horas → tipo 4 (especial dedicación)
      IF i_tipo_horas = C_TIPO_HORAS_DEFAULT THEN
        i_tipo_horas := C_TIPO_HORAS_ESPECIAL;
      END IF;

      -- Si el fichaje son horas extras (no computa saldo) → incluir en lista protegida
      IF i_operacion = C_OPERACION_HEXTRAS_1 OR 
         i_operacion = C_OPERACION_HEXTRAS_2 OR 
         i_operacion = C_OPERACION_SIN_CAMBIO THEN
        
        fichaje_chequea_hextras(i_id_funcionario, i_clave, i_operacion, lista_no_actualiza, i_tipo_horas);
        
      END IF;

      i_longitud := INSTR(i_cadena_computa, C_DELIMITADOR_REG, i_longitud) + 1;
      
    END LOOP;

    -- **********************************
    -- FASE 5: Procesar cadena de transacciones (validar y actualizar)
    -- **********************************
    -- Formato: CLAVE + número + ; + FICHAJE + HH:MM + ; + VALOR + número + ; + *
    -- VALOR: 0=sin cambio, 1=modificado, 2=nuevo, 3=eliminar
    
    i_longitud := 1;
    i_cadena_fichaje_tmp := '';
    i_longitud_fichajes := LENGTH(i_cadena_fichaje);
    i_fichaje := '';
    i_clave := '';
    i_operacion := '';

    WHILE i_longitud_fichajes > i_longitud LOOP
      
      i_cadena_fichaje_tmp := SUBSTR(i_cadena_fichaje, i_longitud, C_LONGITUD_BUFFER);
      
      i_fichaje := devuelve_valor_campo(i_cadena_fichaje_tmp, 'FICHAJE');
      i_clave := devuelve_valor_campo(i_cadena_fichaje_tmp, 'CLAVE');
      i_operacion := devuelve_valor_campo(i_cadena_fichaje_tmp, 'VALOR');

      -- Verificar si transacción está en lista protegida (horas extras)
      i_longitud_actualiza := INSTR(i_cadena_fichaje, lista_no_actualiza, 1);

      IF i_longitud_actualiza = 0 AND 
         (i_operacion = C_OPERACION_MODIFICADO OR 
          i_operacion = C_OPERACION_NUEVO OR 
          i_operacion = C_OPERACION_ELIMINAR) THEN
        
        -- ERROR: Intentar modificar/eliminar transacción con horas extras
        i_cadena_observaciones := C_MSG_ERROR_HEXTRAS;
        RETURN;
        
      ELSE
        IF i_operacion = C_OPERACION_MODIFICADO OR 
           i_operacion = C_OPERACION_NUEVO OR 
           i_operacion = C_OPERACION_ELIMINAR THEN
          
          -- Validar horas extras en transacciones para ambos PINs
          fichaje_chequea_hextras_tran(i_pin, i_fecha_p, i_fichaje, i_clave, i_operacion);
          fichaje_chequea_hextras_tran(i_pin2, i_fecha_p, i_fichaje, i_clave, i_operacion);
          
        END IF;
      END IF;

      i_longitud := INSTR(i_cadena_fichaje, C_DELIMITADOR_REG, i_longitud) + 1;
      
    END LOOP;

    -- **********************************
    -- FASE 6: Confirmar cambios
    -- **********************************
    COMMIT;

  END IF; -- Fin IF i_pin > 0

  -- **********************************
  -- FASE 7: Recalcular saldo finger según tipo funcionario
  -- **********************************
  IF i_tipo_funcionario2 <> C_TIPO_FUNC_POLICIA THEN
    -- Cálculo estándar para no-policías
    finger_calcula_saldo(i_id_funcionario, i_fecha_p);
  ELSE
    -- Cálculo especializado para policías
    finger_calcula_saldo_policia(i_id_funcionario, i_fecha_p);
  END IF;

  -- **********************************
  -- FASE 8: Retornar confirmación
  -- **********************************
  i_cadena_observaciones := C_MSG_CORRECTO;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    i_cadena_observaciones := 'Error: ' || SQLERRM;
    RAISE;

END FINGER_PROCESA_TRANSACCIONES;
/

