CREATE OR REPLACE PROCEDURE RRHH.FINGER_PLANIFICA_INFORME (
  v_id_funcionario IN NUMBER,
  v_campos_informe IN VARCHAR2
) IS
  /**
   * @description Planifica y crea la configuración de un nuevo informe de fichaje personalizado
   * @details Proceso que extrae parámetros de configuración del informe desde cadena codificada,
   *          interpreta filtros y parámetros, y registra nueva planificación en fichaje_informe.
   *          Soporta dos tipos de filtros:
   *          - Filtro 1: Criterio general con parámetro texto
   *          - Filtro 2: Criterio temporal (M=manual con rango FI/FF, otros valores predefinidos)
   *          Valores predefinidos Filtro 2: DA=Día Anterior, MA=Mes Anterior, PA=Periodo Anterior
   * @param v_id_funcionario ID del funcionario que solicita el informe (para auditoría)
   * @param v_campos_informe Cadena codificada con parámetros separados por delimitador
   *                         Campos esperados:
   *                         - TIPOZ: Tipo de informe
   *                         - TITULOZ: Título del informe
   *                         - FILTRO1Z: Código filtro 1
   *                         - FILTRO1ZTXT: Texto descriptivo filtro 1
   *                         - PARA1Z: Parámetro filtro 1
   *                         - FILTRO2Z: Código filtro 2 (M=manual, DA/MA/PA=predefinido)
   *                         - FILTRO2ZTXT: Texto descriptivo filtro 2
   *                         - PARA2FIZ: Fecha inicio (si filtro 2 = M)
   *                         - PARA2FPZ: Fecha fin (si filtro 2 = M)
   * @notes 
   *   - Utiliza función devuelve_valor_campo() para extraer valores de cadena codificada
   *   - Genera secuencia automática con sec_fichaje_informe.nextval
   *   - Campo valido siempre = 1 (informe activo)
   *   - fecha_ult_ejec se inicializa vacío ('')
   *   - Filtro 2 tipo M: formato 'FI<fecha_inicio>;FF<fecha_fin>;'
   */

  -- Constantes
  C_VALIDO_ACTIVO       CONSTANT NUMBER := 1;
  C_FILTRO2_MANUAL      CONSTANT VARCHAR2(1) := 'M';
  C_FILTRO2_DIA_ANT     CONSTANT VARCHAR2(2) := 'DA';
  C_FILTRO2_MES_ANT     CONSTANT VARCHAR2(2) := 'MA';
  C_FILTRO2_PER_ANT     CONSTANT VARCHAR2(2) := 'PA';
  C_TXT_DIA_ANTERIOR    CONSTANT VARCHAR2(20) := 'Día Anterior';
  C_TXT_MES_ANTERIOR    CONSTANT VARCHAR2(20) := 'Mes Anterior';
  C_TXT_PERIODO_ANT     CONSTANT VARCHAR2(20) := 'Periodo Anterior';

  -- Variables configuración informe
  v_id_tipo_informe   VARCHAR2(100);
  v_titulo_informe    VARCHAR2(100);
  v_filtro_1          VARCHAR2(100);
  v_filtro_1_txt      VARCHAR2(100);
  v_filtro_1_para     VARCHAR2(100);
  v_filtro_2          VARCHAR2(100);
  v_filtro_2_txt      VARCHAR2(100);
  v_filtro_2_para_1   VARCHAR2(100);

BEGIN

  -- **********************************
  -- FASE 1: Extraer parámetros de configuración desde cadena codificada
  -- **********************************
  v_id_tipo_informe := devuelve_valor_campo(v_campos_informe, 'TIPOZ');
  v_titulo_informe  := devuelve_valor_campo(v_campos_informe, 'TITULOZ');
  v_filtro_1        := devuelve_valor_campo(v_campos_informe, 'FILTRO1Z');
  v_filtro_1_txt    := devuelve_valor_campo(v_campos_informe, 'FILTRO1ZTXT');
  v_filtro_1_para   := devuelve_valor_campo(v_campos_informe, 'PARA1Z');
  v_filtro_2        := devuelve_valor_campo(v_campos_informe, 'FILTRO2Z');
  v_filtro_2_txt    := devuelve_valor_campo(v_campos_informe, 'FILTRO2ZTXT');

  -- **********************************
  -- FASE 2: Construir parámetro Filtro 2 según tipo
  -- **********************************
  IF v_filtro_2 = C_FILTRO2_MANUAL THEN
    -- Filtro manual: construir rango con FI (fecha inicio) y FF (fecha fin)
    v_filtro_2_para_1 := 'FI' || devuelve_valor_campo(v_campos_informe, 'PARA2FIZ') || 
                         ';FF' || devuelve_valor_campo(v_campos_informe, 'PARA2FPZ') || ';';
  ELSE
    -- Filtro predefinido: usar código directamente
    v_filtro_2_para_1 := devuelve_valor_campo(v_campos_informe, 'PARA2FIZ');
  END IF;

  -- **********************************
  -- FASE 3: Interpretar códigos predefinidos para texto descriptivo Filtro 2
  -- **********************************
  IF v_filtro_2_para_1 = C_FILTRO2_DIA_ANT THEN
    v_filtro_2_txt := C_TXT_DIA_ANTERIOR;
  ELSIF v_filtro_2_para_1 = C_FILTRO2_MES_ANT THEN
    v_filtro_2_txt := C_TXT_MES_ANTERIOR;
  ELSIF v_filtro_2_para_1 = C_FILTRO2_PER_ANT THEN
    v_filtro_2_txt := C_TXT_PERIODO_ANT;
  END IF;
  -- Si no coincide con predefinidos, mantiene v_filtro_2_txt extraído en FASE 1

  -- **********************************
  -- FASE 4: Insertar planificación del informe
  -- **********************************
  INSERT INTO fichaje_informe (
    id_secuencia_informe,
    id_tipo_informe,
    titulo,
    valido,
    filtro_1,
    filtro_2,
    audit_usuario,
    audit_fecha,
    filtro_1_para,
    filtro_2_para,
    fecha_ult_ejec,
    filtro_1_txt,
    filtro_2_txt
  ) VALUES (
    sec_fichaje_informe.NEXTVAL,
    v_id_tipo_informe,
    v_titulo_informe,
    C_VALIDO_ACTIVO,
    v_filtro_1,
    v_filtro_2,
    v_id_funcionario,
    SYSDATE,
    v_filtro_1_para,
    v_filtro_2_para_1,
    '',
    v_filtro_1_txt,
    v_filtro_2_txt
  );

  -- **********************************
  -- FASE 5: Confirmar transacción
  -- **********************************
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;

END FINGER_PLANIFICA_INFORME;
/

