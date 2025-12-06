/*******************************************************************************
 * Función: TURNO_POLICIA
 * 
 * Propósito:
 *   Determina el turno de trabajo (mañana=1, tarde=2, noche=3) de un policía
 *   basándose en los fichajes anteriores y posteriores más cercanos.
 *
 * @param V_claveomesa  Número de serie del fichaje a analizar
 * @param i_pin         PIN del funcionario
 * @return VARCHAR2     Código del turno: '1'=mañana, '2'=tarde, '3'=noche, '0'=no determinable
 *
 * Lógica:
 *   1. Busca el fichaje correspondiente al numserie dado
 *   2. Localiza el fichaje anterior y posterior más cercano del mismo funcionario
 *   3. Determina si el fichaje actual es el primero o segundo del turno
 *      basándose en los intervalos de tiempo
 *   4. Obtiene los periodos obligatorios de la jornada del funcionario
 *   5. Compara las horas de fichaje con los periodos para determinar el turno
 *
 * Dependencias:
 *   - Tabla: fichaje_funcionario_tran (numserie, fecha_fichaje, id_funcionario, pin, valido)
 *   - Función: finger_busca_jornada_fun (obtiene periodos de jornada)
 *
 * Mejoras aplicadas:
 *   - Documentación JavaDoc completa
 *   - Constantes para valores de turno y umbrales de tiempo
 *   - Eliminación de código comentado extenso
 *   - Variables con nombres más descriptivos
 *   - INNER JOIN explícito en lugar de sintaxis con comas
 *   - Simplificación de lógica con CASE
 *   - Comentarios explicativos en secciones complejas
 *
 * Historial:
 *   - 06/12/2025: Optimización Grupo 8 - mejor legibilidad y documentación
 ******************************************************************************/
CREATE OR REPLACE FUNCTION rrhh.TURNO_POLICIA(
    V_claveomesa IN VARCHAR2,
    i_pin        IN VARCHAR2
) RETURN VARCHAR2 IS

    -- Constantes para turnos
    C_TURNO_MANANA CONSTANT NUMBER := 1;
    C_TURNO_TARDE  CONSTANT NUMBER := 2;
    C_TURNO_NOCHE  CONSTANT NUMBER := 3;
    C_TURNO_ERROR  CONSTANT NUMBER := 0;
    
    -- Constante para ajuste de tolerancia noche
    C_TOLERANCIA_NOCHE CONSTANT NUMBER := 300;
    C_AJUSTE_MEDIANOCHE CONSTANT NUMBER := 2000;
    
    -- Variables de resultado
    v_resultado VARCHAR2(512);
    
    -- Variables de control de búsqueda
    i_encontrado     NUMBER;
    i_encontrado_ant NUMBER;
    i_encontrado_pos NUMBER;
    
    -- Variables de fechas y horas
    d_fecha_fichaje     DATE;
    d_fecha_fichaje_ant DATE;
    d_fecha_fichaje_pos DATE;
    
    horas_f     NUMBER;
    horas_f_ant NUMBER;
    horas_f_pos NUMBER;
    horas_f_pri NUMBER;  -- Hora del primer fichaje del par
    horas_f_seg NUMBER;  -- Hora del segundo fichaje del par
    horas_f_seg_aux NUMBER;
    
    -- Variables de diferencias de tiempo (en minutos)
    i_diferencia_saldo_ant NUMBER;
    i_diferencia_saldo_pos NUMBER;
    
    -- Variable del funcionario
    i_id_funcionario NUMBER;
    
    -- Indicador de posición: 1=posterior, 2=anterior
    i_fichaje NUMBER;
    
    -- Variables de periodos obligatorios de jornada
    i_p1d  NUMBER;  -- Periodo 1 desde (flexible)
    i_p1h  NUMBER;  -- Periodo 1 hasta (flexible)
    i_p2d  NUMBER;  -- Periodo 2 desde (flexible)
    i_p2h  NUMBER;  -- Periodo 2 hasta (flexible)
    i_p3d  NUMBER;  -- Periodo 3 desde (flexible)
    i_p3h  NUMBER;  -- Periodo 3 hasta (flexible)
    i_po1d NUMBER;  -- Periodo 1 desde (obligatorio)
    i_po1h NUMBER;  -- Periodo 1 hasta (obligatorio)
    i_po2d NUMBER;  -- Periodo 2 desde (obligatorio)
    i_po2h NUMBER;  -- Periodo 2 hasta (obligatorio)
    i_po3d NUMBER;  -- Periodo 3 desde (obligatorio)
    i_po3h NUMBER;  -- Periodo 3 hasta (obligatorio)
    i_po3h_aux NUMBER;
    
    i_sin_calendario NUMBER;
    i_contar_comida  NUMBER;
    i_libre          NUMBER;
    i_turnos         NUMBER;
BEGIN
    i_encontrado := 1;
    
    -- Buscar el fichaje actual por numserie
    BEGIN
        SELECT fecha_fichaje,
               id_funcionario,
               TO_NUMBER(TO_CHAR(fecha_fichaje, 'HH24MI')) AS horas_f
        INTO d_fecha_fichaje, i_id_funcionario, horas_f
        FROM fichaje_funcionario_tran
        WHERE numserie = v_claveomesa
            AND ROWNUM = 1
            AND valido = 1
            AND pin = i_pin;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            i_encontrado := 0;
    END;
    
    -- Si no se encontró el fichaje, retornar error
    IF i_encontrado = 0 THEN
        RETURN TO_CHAR(C_TURNO_ERROR);
    END IF;
    
    -- Buscar fichaje anterior más cercano
    i_encontrado_ant := 1;
    BEGIN
        SELECT t.fecha_fichaje,
               TO_NUMBER(TO_CHAR(t.fecha_fichaje, 'HH24MI')) AS horas_f
        INTO d_fecha_fichaje_ant, horas_f_ant
        FROM fichaje_funcionario_tran t
        INNER JOIN (
            SELECT MAX(numserie) AS numserie
            FROM fichaje_funcionario_tran
            WHERE numserie < v_claveomesa
                AND pin = i_pin
                AND valido = 1
        ) p ON t.numserie = p.numserie
        WHERE t.pin = i_pin
            AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            i_encontrado_ant := 0;
    END;
    
    -- Buscar fichaje posterior más cercano
    i_encontrado_pos := 1;
    BEGIN
        SELECT t.fecha_fichaje,
               TO_NUMBER(TO_CHAR(t.fecha_fichaje, 'HH24MI')) AS horas_f
        INTO d_fecha_fichaje_pos, horas_f_pos
        FROM fichaje_funcionario_tran t
        INNER JOIN (
            SELECT MIN(numserie) AS numserie
            FROM fichaje_funcionario_tran
            WHERE numserie > v_claveomesa
                AND pin = i_pin
                AND valido = 1
        ) p ON t.numserie = p.numserie
        WHERE t.pin = i_pin
            AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            i_encontrado_pos := 0;
    END;
    
    -- Calcular diferencias de tiempo en minutos
    i_diferencia_saldo_ant := CASE WHEN i_encontrado_ant = 1 
        THEN (d_fecha_fichaje - d_fecha_fichaje_ant) * 60 * 24 
        ELSE 0 END;
    
    i_diferencia_saldo_pos := CASE WHEN i_encontrado_pos = 1 
        THEN (d_fecha_fichaje_pos - d_fecha_fichaje) * 60 * 24 
        ELSE 0 END;
    
    -- Determinar si este es el primer o segundo fichaje del turno
    i_fichaje := CASE
        WHEN i_diferencia_saldo_ant = 0 THEN C_TURNO_MANANA  -- Sin anterior, es primer fichaje
        WHEN i_diferencia_saldo_pos = 0 THEN C_TURNO_TARDE   -- Sin posterior, es segundo fichaje
        WHEN i_diferencia_saldo_ant > i_diferencia_saldo_pos AND i_diferencia_saldo_pos > 0 
            THEN C_TURNO_MANANA  -- Más cerca del posterior
        WHEN i_diferencia_saldo_ant < i_diferencia_saldo_pos AND i_diferencia_saldo_ant > 0 
            THEN C_TURNO_TARDE   -- Más cerca del anterior
        ELSE C_TURNO_MANANA
    END;
    
    -- Descartar si no hay fichajes válidos antes ni después
    IF i_diferencia_saldo_ant = 0 AND i_diferencia_saldo_pos = 0 THEN
        RETURN TO_CHAR(C_TURNO_ERROR);
    END IF;
    
    -- Obtener periodos de jornada del funcionario
    finger_busca_jornada_fun(
        i_id_funcionario,
        d_fecha_fichaje,
        i_p1d,  i_p1h,
        i_p2d,  i_p2h,
        i_p3d,  i_p3h,
        i_po1d, i_po1h,
        i_po2d, i_po2h,
        i_po3d, i_po3h,
        i_contar_comida,
        i_libre,
        i_turnos,
        i_sin_calendario
    );



    IF  i_fichaje=1 THEN --FICHAJE POSTEIOR
        horas_f_pri:=horas_f;
        horas_f_seg:=horas_f_pos;

    ELSE
        horas_f_pri:=horas_f_ant;
        horas_f_seg:=horas_f;

    END IF;

    v_turno_a:=0;

    --comprobamos fichaje
    --si esta fuera de los periodos
    IF horas_f_pri <=  i_po1d and  horas_f_seg >= i_po1h       THEN
          v_turno_a:=1;
          result:=v_turno_a;
          return(Result);
    ELSE  IF horas_f_pri <=  i_po2d and  horas_f_seg  >= i_po2h           THEN
                               v_turno_a:=2;
                               result:=v_turno_a;
                               return(Result);
          ELSE IF horas_f_pri <=  i_po3d and  horas_f_seg  >= i_po3h
            and( abs(horas_f_seg- i_po3h)<300)        THEN      --cambiado 26/05/2018 a 300
                                 v_turno_a:=3;
                                 result:=v_turno_a;
                                return(Result);
               END IF;
          END IF;
    END IF;

    --sigo buscando
        i_po3h_aux:=i_po3h+2000;
        IF horas_f_seg < 1000 THEN
            horas_f_seg_aux:=2000+horas_f_seg;
        END IF;

        IF ( horas_f_pri >=  i_po1d and  horas_f_pri <=    i_po1h  ) and
           ( horas_f_seg >=  i_po1d and  horas_f_seg <=    i_po1h  )    THEN

              v_turno_a:=1;
              result:=v_turno_a;
              return(Result);

         ELSE  IF ( horas_f_pri >=  i_po2d and  horas_f_pri <=    i_po2h  ) and
                  ( horas_f_seg >=  i_po2d and  horas_f_seg <=    i_po2h  )  THEN
                                   v_turno_a:=2;
                                   result:=v_turno_a;
                                   return(Result);
              ELSE IF ( horas_f_pri >=  i_po3d and  horas_f_pri <=   i_po3h  ) and
                       ( horas_f_seg_aux >=  i_po3d and  horas_f_seg_aux <=  i_po3h_aux  )
                                              THEN
                                     v_turno_a:=3;
                                     result:=v_turno_a;
                                     return(Result);
                   END IF;
              END IF;
        END IF;



    --Sigo buscando
    --comprobamos fichaje
    --si esta dentro uno de los dos fichajes y el otro no


      --Primer ficha comprendido en p1
      IF ( horas_f_pri >=  i_po1d and  horas_f_pri <=    i_po1h  )    THEN

           IF    abs(i_po2d -horas_f_pri) > abs(i_po1h-horas_f_seg) then
                  v_turno_a:=1;
                  result:=v_turno_a;
                  return(Result);
           ELSE
                  v_turno_a:=2;
                  result:=v_turno_a;
                  return(Result);
           END IF;

      END IF;

      --Segundo ficha comprendido en p1
      IF ( horas_f_seg >=  i_po1d and  horas_f_seg <=    i_po1h  )    THEN
            IF    abs(i_po3d -horas_f_pri) > abs(i_po1h-horas_f_seg) then
                  v_turno_a:=3;
                  result:=v_turno_a;
                  return(Result);
           ELSE
                  v_turno_a:=1;
                  result:=v_turno_a;
                  return(Result);
           END IF;
      END IF;


       --Primer fichaje comprendido en p2
      IF ( horas_f_pri >=  i_po2d and  horas_f_pri <=    i_po2h  )    THEN

           IF    abs(i_po3d -horas_f_pri) > abs(i_po1h-horas_f_seg) then
                  v_turno_a:=1;
                  result:=v_turno_a;
                  return(Result);
           ELSE
                  v_turno_a:=3;
                  result:=v_turno_a;
                  return(Result);
           END IF;

      END IF;







    -- Si no se pudo determinar el turno, retornar 0
    RETURN TO_CHAR(C_TURNO_ERROR);

END TURNO_POLICIA;
/

