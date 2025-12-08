/**
 * INSERTA_AUSENCIAS_RRHH
 *
 * @description
 * Procedimiento para que RRHH inserte ausencias directamente con estado 80 (Concedido).
 * No requiere proceso de aprobación de JS/JA ya que es creada directamente por RRHH.
 *
 * @details
 * Operaciones principales:
 * - Validar fechas y formatear horas (completar con ceros a la izquierda)
 * - Generar secuencias para id_ausencia y id_operacion
 * - Insertar ausencia con estado 80 (Concedido) directamente
 * - Actualizar bolsa de horas sindicales (tipos > 500)
 * - Actualizar bolsa_concilia para ausencias tipo 50
 * - Registrar en histórico_operaciones
 *
 * Estados:
 * - 80: Concedido (estado directo sin workflow de aprobación)
 *
 * @param V_ID_ANO                Año de la ausencia
 * @param V_ID_FUNCIONARIO        ID del funcionario
 * @param V_ID_TIPO_FUNCIONARIO   Tipo de funcionario (10=Admin, 21=Policía, 23=Bombero)
 * @param V_ID_TIPO_AUSENCIA      Código tipo ausencia (50=Concilia, >500=Sindicales)
 * @param V_FECHA_INICIO          Fecha inicio de la ausencia
 * @param V_FECHA_FIN             Fecha fin de la ausencia
 * @param V_HORA_INICIO           Hora inicio (formato HH:MI)
 * @param V_HORA_FIN              Hora fin (formato HH:MI)
 * @param V_JUSTIFICACION         SI/NO si está justificada
 * @param V_OBSERVACIONES         Texto libre con observaciones
 * @param v_total_horas           Total de horas de la ausencia (en minutos)
 * @param todo_ok_Basico          OUT 0=Éxito, 1=Error
 * @param msgBasico               OUT Mensaje resultado
 *
 * @notes
 * - Ausencias tipo > 500: descuenta de HORA_SINDICAL (por mes)
 * - Ausencias tipo 50: descuenta de BOLSA_CONCILIA (por año)
 * - No envía notificaciones (creación directa por RRHH)
 * - Fechas firmado_js/firmado_ja se asignan con fecha actual aunque no hay firma real
 *
 * @author Sistema Ausencias RRHH
 * @date   Actualizado 13/02/2020 (bolsa concilia)
 * @version 2.0
 */
CREATE OR REPLACE PROCEDURE RRHH.INSERTA_AUSENCIAS_RRHH (
  V_ID_ANO            IN NUMBER,
  V_ID_FUNCIONARIO    IN NUMBER,
  V_ID_TIPO_FUNCIONARIO IN NUMBER,
  V_ID_TIPO_AUSENCIA  IN VARCHAR2,
  V_FECHA_INICIO      IN DATE,
  V_FECHA_FIN         IN DATE,
  V_HORA_INICIO       IN VARCHAR2,
  V_HORA_FIN          IN VARCHAR2,
  V_JUSTIFICACION     IN VARCHAR2,
  V_OBSERVACIONES     IN VARCHAR2,
  v_total_horas       IN NUMBER,
  todo_ok_Basico      OUT INTEGER,
  msgBasico           OUT VARCHAR2
) IS

  -- Constantes
  C_ESTADO_CONCEDIDO        CONSTANT VARCHAR2(2) := '80';
  C_ESTADO_SOLICITADO       CONSTANT VARCHAR2(2) := '10';
  C_TIPO_AUSENCIA_CONCILIA  CONSTANT VARCHAR2(3) := '50';
  C_TIPO_AUSENCIA_SINDICAL  CONSTANT NUMBER := 500;
  
  -- Variables estado y fechas
  i_Estado_permiso        NUMBER;
  i_fecha_js              DATE;
  i_fecha_ja              DATE;
  i_formato_fecha_inicio  DATE;
  i_formato_fecha_fin     DATE;
  
  -- Variables secuencias y fecha/hora
  i_secuencia_operacion   NUMBER;
  i_secuencia_ausencia    NUMBER;
  i_fecha                 VARCHAR2(10);
  i_hora                  VARCHAR2(10);
  i_id_ano                VARCHAR2(4);
  
  -- Variables control fechas
  i_mes_inicio            NUMBER;
  i_mes_fin               NUMBER;
  i_año_inicio            NUMBER;

BEGIN

  todo_ok_basico := 0;
  msgBasico := '';
  
  --------------------------------------------------------------------------------
  -- FASE 1: VALIDAR Y FORMATEAR FECHAS
  --------------------------------------------------------------------------------
  
  i_mes_inicio := TO_CHAR(V_FECHA_INICIO, 'MM');
  i_mes_fin := TO_CHAR(V_FECHA_FIN, 'MM');
  
  i_año_inicio := TO_CHAR(V_FECHA_INICIO, 'YYYY');
  
  -- Formatear fecha-hora completa
  i_formato_fecha_inicio := TO_DATE(TO_CHAR(V_FECHA_INICIO, 'DD/MM/YYYY') || V_HORA_INICIO, 'DD/MM/YYYY HH24:MI');
  i_formato_fecha_fin := TO_DATE(TO_CHAR(V_FECHA_FIN, 'DD/MM/YYYY') || V_HORA_FIN, 'DD/MM/YYYY HH24:MI');
  
  --------------------------------------------------------------------------------
  -- FASE 2: GENERAR SECUENCIAS Y PREPARAR INSERCIÓN
  --------------------------------------------------------------------------------
  
  SELECT sec_operacion.NEXTVAL,
         sec_ausencia.NEXTVAL,
         TO_CHAR(SYSDATE, 'DD/MM/YYYY'),
         TO_CHAR(SYSDATE, 'HH:MI'),
         TO_CHAR(SYSDATE, 'YYYY')
  INTO   i_secuencia_operacion,
         i_secuencia_ausencia,
         i_fecha,
         i_hora,
         i_id_ano
  FROM   dual;
  
  -- Estado directo a Concedido (RRHH crea con aprobación automática)
  i_Estado_permiso := TO_NUMBER(C_ESTADO_CONCEDIDO);
  i_fecha_js := SYSDATE;
  i_fecha_ja := SYSDATE;
  
  --------------------------------------------------------------------------------
  -- FASE 3: INSERTAR AUSENCIA CON ESTADO CONCEDIDO
  --------------------------------------------------------------------------------
  
  INSERT INTO ausencia (
    id_ausencia,
    id_ano,
    id_funcionario,
    id_tipo_ausencia,
    id_estado,
    firmado_js,
    fecha_js,
    firmado_ja,
    fecha_ja,
    fecha_inicio,
    fecha_fin,
    total_horas,
    id_usuario,
    fecha_modi,
    OBSERVACIONES,
    JUSTIFICADO
  ) VALUES (
    i_secuencia_ausencia,
    V_id_ANO,
    V_ID_FUNCIONARIO,
    V_ID_TIPO_AUSENCIA,
    i_estado_permiso,
    '',
    TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/yy'), 'DD/MM/yy'),
    '',
    TO_DATE(TO_CHAR(i_fecha_ja, 'DD/MM/yy'), 'DD/MM/yy'),
    i_formato_fecha_inicio,
    i_formato_fecha_fin,
    v_total_horas,
    V_ID_FUNCIONARIO,
    TO_DATE(TO_CHAR(SYSDATE, 'DD/MM/yy'), 'DD/MM/yy'),
    V_OBSERVACIONES,
    V_JUSTIFICACION
  );
  
  --------------------------------------------------------------------------------
  -- FASE 4: ACTUALIZAR BOLSA HORAS SINDICALES (tipos > 500)
  --------------------------------------------------------------------------------
  
  IF TO_NUMBER(V_ID_TIPO_AUSENCIA) > C_TIPO_AUSENCIA_SINDICAL THEN
    
    UPDATE HORA_SINDICAL
    SET    TOTAL_UTILIZADAS = TOTAL_UTILIZADAS + v_total_horas
    WHERE  id_ano = i_año_inicio
      AND  id_MES = i_mes_inicio
      AND  id_funcionario = V_ID_FUNCIONARIO
      AND  ID_TIPO_AUSENCIA = V_ID_TIPO_AUSENCIA;
      
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 5: ACTUALIZAR BOLSA CONCILIA (tipo 50)
  --------------------------------------------------------------------------------
  
  IF V_ID_TIPO_AUSENCIA = C_TIPO_AUSENCIA_CONCILIA THEN
    
    UPDATE BOLSA_CONCILIA
    SET    utilizadas = NVL(utilizadas, 0) + v_total_horas,
           pendientes_justificar = NVL(pendientes_justificar, 0) + v_total_horas
    WHERE  id_ano = i_año_inicio
      AND  id_funcionario = V_ID_FUNCIONARIO;
      
  END IF;
  
  --------------------------------------------------------------------------------
  -- FASE 6: REGISTRAR EN HISTÓRICO
  --------------------------------------------------------------------------------
  
  INSERT INTO historico_operaciones
  VALUES (
    i_secuencia_operacion,
    i_secuencia_ausencia,
    TO_NUMBER(C_ESTADO_SOLICITADO),
    V_id_ano,
    V_ID_FUNCIONARIO,
    TO_DATE(i_fecha, 'DD/MM/YYYY'),
    i_hora,
    'INSERTA AUSENCIA',
    V_ID_FUNCIONARIO,
    TO_DATE(i_fecha, 'DD/MM/YYYY')
  );
  
  COMMIT;
  
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error en inserta_ausencias_rrhh: ' || SQLERRM);
    ROLLBACK;
    todo_ok_basico := 1;
    msgBasico := 'Error en inserta_ausencias_rrhh: ' || SQLERRM;
    
END INSERTA_AUSENCIAS_RRHH;
/

