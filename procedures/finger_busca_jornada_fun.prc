CREATE OR REPLACE PROCEDURE RRHH.FINGER_BUSCA_JORNADA_FUN (
  i_id_funcionario     IN     VARCHAR2,
  v_fecha_p            IN     DATE,
  v_p1d                IN OUT NUMBER,
  v_p1h                IN OUT NUMBER,
  v_p2d                IN OUT NUMBER,
  v_p2h                IN OUT NUMBER,
  v_p3d                IN OUT NUMBER,
  v_p3h                IN OUT NUMBER,
  v_po1d               IN OUT NUMBER,
  v_po1h               IN OUT NUMBER,
  v_po2d               IN OUT NUMBER,
  v_po2h               IN OUT NUMBER,
  v_po3d               IN OUT NUMBER,
  v_po3h               IN OUT NUMBER,
  v_contar_comida      IN OUT NUMBER,
  v_libre              IN OUT NUMBER,
  v_turnos             IN OUT NUMBER,
  v_sin_calendario     IN OUT NUMBER
) IS
  /**
   * @description Busca y devuelve la configuración de jornada laboral del funcionario para fecha específica
   * @details Consulta calendario de jornada del funcionario para fecha determinada y retorna configuración completa:
   *          - 3 periodos flexibles (desde/hasta) - P1, P2, P3
   *          - 3 periodos obligatorios (desde/hasta) - PO1, PO2, PO3
   *          - Flags: contar_comida, libre, turnos
   *          Realiza ajuste de día de semana según origen ejecución (web=1, pl/sql=2).
   *          Domingo se considera día 8 para búsqueda en calendario.
   * @param i_id_funcionario ID del funcionario
   * @param v_fecha_p Fecha para la que se consulta la jornada
   * @param v_p1d OUT Periodo 1 flexible desde (HHMM)
   * @param v_p1h OUT Periodo 1 flexible hasta (HHMM)
   * @param v_p2d OUT Periodo 2 flexible desde (HHMM)
   * @param v_p2h OUT Periodo 2 flexible hasta (HHMM)
   * @param v_p3d OUT Periodo 3 flexible desde (HHMM)
   * @param v_p3h OUT Periodo 3 flexible hasta (HHMM)
   * @param v_po1d OUT Periodo 1 obligatorio desde (HHMM)
   * @param v_po1h OUT Periodo 1 obligatorio hasta (HHMM)
   * @param v_po2d OUT Periodo 2 obligatorio desde (HHMM)
   * @param v_po2h OUT Periodo 2 obligatorio hasta (HHMM)
   * @param v_po3d OUT Periodo 3 obligatorio desde (HHMM)
   * @param v_po3h OUT Periodo 3 obligatorio hasta (HHMM)
   * @param v_contar_comida OUT 1=contar tiempo comida, 0=no contar
   * @param v_libre OUT 1=día libre, 0=laborable
   * @param v_turnos OUT 1=trabajo por turnos, 0=jornada normal
   * @param v_sin_calendario OUT 0=sin calendario (asignado en excepciones)
   * @notes 
   *   - Ajuste día semana: si resultado TO_CHAR(fecha,'D')=1 → dia_semana=1, sino dia_semana=0
   *   - Domingo tratado como día 8 en calendario: DECODE(dia+ajuste,1,8,dia+ajuste)
   *   - Join: fichaje_calendario_jornada + fichaje_funcionario_jornada + fichaje_calendario
   *   - Validación rangos: v_fecha_p entre fecha_inicio y fecha_fin (funcionario y calendario)
   *   - Excepciones: NO_DATA_FOUND o TOO_MANY_ROWS → v_sin_calendario=0
   */

  -- Constantes
  C_DIA_DOMINGO         CONSTANT NUMBER := 1;
  C_DIA_AJUSTADO_DOM    CONSTANT NUMBER := 8;
  C_AJUSTE_WEB          CONSTANT NUMBER := 1;
  C_AJUSTE_PLSQL        CONSTANT NUMBER := 0;
  C_SIN_CALENDARIO      CONSTANT NUMBER := 0;
  C_FECHA_REFERENCIA    CONSTANT DATE := TO_DATE('07/01/2019', 'DD/MM/YYYY');

  -- Variables
  dia_semana        NUMBER;

BEGIN

  -- **********************************
  -- FASE 1: Determinar ajuste día semana según origen (web vs pl/sql)
  -- **********************************
  -- Detectar si la ejecución es desde web (día semana = 1) o desde pl/sql (día semana = 0)
  SELECT TO_CHAR(C_FECHA_REFERENCIA, 'D') 
  INTO dia_semana 
  FROM DUAL;

  IF dia_semana = C_DIA_DOMINGO THEN
    dia_semana := C_AJUSTE_WEB;
  ELSE
    dia_semana := C_AJUSTE_PLSQL;
  END IF;

  -- **********************************
  -- FASE 2: Buscar configuración jornada del funcionario para fecha
  -- **********************************
  BEGIN
    SELECT DISTINCT 
           TO_CHAR(p1_fle_desde, 'HH24MI') AS p1d,
           TO_CHAR(p1_fle_hasta, 'HH24MI') AS p1h,
           TO_CHAR(p2_fle_desde, 'HH24MI') AS p2d,
           TO_CHAR(p2_fle_hasta, 'HH24MI') AS p2h,
           TO_CHAR(p3_fle_desde, 'HH24MI') AS p3d,
           TO_CHAR(p3_fle_hasta, 'HH24MI') AS p3h,
           TO_CHAR(p1_obl_desde, 'HH24MI') AS po1d,
           TO_CHAR(p1_obl_hasta, 'HH24MI') AS po1h,
           TO_CHAR(p2_obl_desde, 'HH24MI') AS po2d,
           TO_CHAR(p2_obl_hasta, 'HH24MI') AS po2h,
           TO_CHAR(p3_obl_desde, 'HH24MI') AS po3d,
           TO_CHAR(p3_obl_hasta, 'HH24MI') AS po3h,
           DECODE(contar_comida, 'SI', 1, 0) AS cnt_comida,
           DECODE(libre, 'SI', 1, 0) AS es_libre,
           DECODE(turno, 'SI', 1, 0) AS es_turno
    INTO v_p1d, v_p1h,
         v_p2d, v_p2h,
         v_p3d, v_p3h,
         v_po1d, v_po1h,
         v_po2d, v_po2h,
         v_po3d, v_po3h,
         v_contar_comida,
         v_libre,
         v_turnos
    FROM fichaje_calendario_jornada t
    INNER JOIN fichaje_funcionario_jornada ff ON t.id_calendario = ff.id_calendario
    INNER JOIN fichaje_calendario fc ON t.id_calendario = fc.id_calendario
    WHERE ff.id_funcionario = i_id_funcionario
      -- Ajuste día semana: si domingo (dia=1 con ajuste) → usar día 8
      AND dia = DECODE(TO_NUMBER(TO_CHAR(v_fecha_p, 'D')) + dia_semana, 
                       C_DIA_DOMINGO, 
                       C_DIA_AJUSTADO_DOM, 
                       TO_CHAR(v_fecha_p, 'D') + dia_semana)
      -- Validar vigencia calendario funcionario
      AND v_fecha_p BETWEEN ff.fecha_inicio AND NVL(ff.fecha_fin, SYSDATE + 1)
      -- Validar vigencia jornada calendario
      AND v_fecha_p BETWEEN t.fecha_inicio AND NVL(t.fecha_fin, SYSDATE + 1);

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- No se encontró calendario para funcionario/fecha
      v_sin_calendario := C_SIN_CALENDARIO;
    WHEN TOO_MANY_ROWS THEN
      -- Múltiples calendarios encontrados (conflicto configuración)
      v_sin_calendario := C_SIN_CALENDARIO;
  END;

END FINGER_BUSCA_JORNADA_FUN;
/
