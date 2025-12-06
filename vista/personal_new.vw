/*
================================================================================
  VISTA: rrhh.personal_new
================================================================================
  PROPÓSITO:
    Proporciona información del personal con correcciones de datos históricos.
    Aplica transformaciones a ciertos identificadores de funcionarios y tipos
    de funcionarios según reglas de negocio específicas.

  CAMPOS RETORNADOS:
    - codienti: Código de entidad
    - versempl: Versión del empleado
    - id_funcionario: ID del funcionario (con correcciones para IDs específicos)
    - categoria: Categoría profesional del empleado
    - puesto: Puesto de trabajo
    - fecha_nacimiento: Fecha de nacimiento del empleado
    - tipo_funcionario2: Tipo de funcionario corregido (con excepciones)
    - nombre: Nombre del empleado
    - ape1: Primer apellido
    - ape2: Segundo apellido
    - tipo_funcionario: Tipo de funcionario original
    - direccion: Dirección del empleado
    - telefono: Teléfono de contacto
    - fecha_ingreso: Fecha de ingreso en la organización
    - fecha_fin_contrato: Fecha de finalización del contrato (si aplica)
    - activo: Indicador de empleado activo
    - jornada: Tipo de jornada laboral
    - numero_ss: Número de Seguridad Social
    - dni: Documento Nacional de Identidad
    - dni_letra: Letra del DNI
    - fecha_antiguedad: Fecha de antigüedad reconocida
    - fecha_baja: Fecha de baja (si aplica)
    - contratacion: Tipo de contratación

  DEPENDENCIAS:
    - Tabla: personal_historico

  TRANSFORMACIONES APLICADAS:
    - id_funcionario: Mapeo de IDs antiguos a nuevos:
      * 962055 -> 962588
      * 962057 -> 10013
      * 962058 -> 101167
      * 962500 -> 962016
      * 962576 -> 962362
      * 962577 -> 600127
      * 962578 -> 962578 (sin cambio)
    - tipo_funcionario2: Excepciones específicas:
      * 962342 -> 10
      * 39161 -> 50
      * 201337 -> 10
      * Si tipo_funcionario2 = 0 -> 10

  NOTAS DE OPTIMIZACIÓN:
    - La vista es una proyección simple de personal_historico
    - Las transformaciones DECODE son evaluadas en tiempo de consulta
    - RECOMENDACIÓN: Considerar materializar estos datos si se consultan frecuentemente

  ÚLTIMA MODIFICACIÓN: 06/12/2025 - Añadida documentación detallada
================================================================================
*/
CREATE OR REPLACE FORCE VIEW rrhh.personal_new AS
SELECT
    codienti,
    versempl,
    -- Corrección de identificadores de funcionarios por mapeo histórico
    DECODE(TO_CHAR(id_funcionario),
        '962055', '962588',
        '962057', '10013',
        '962058', '101167',
        '962500', '962016',
        '962576', '962362',
        '962577', '600127',
        '962578', '962578',
        TO_CHAR(id_funcionario)
    ) AS id_funcionario,
    categoria,
    puesto,
    fecha_nacimiento,
    -- Tipo de funcionario con excepciones específicas y valor por defecto
    DECODE(id_funcionario,
        '962342', 10,
        '39161', 50,
        '201337', 10,
        DECODE(tipo_funcionario2, 0, 10, tipo_funcionario2)
    ) AS tipo_funcionario2,
    nombre,
    ape1,
    ape2,
    tipo_funcionario,
    direccion,
    telefono,
    fecha_ingreso,
    fecha_fin_contrato,
    activo,
    jornada,
    numero_ss,
    dni,
    dni_letra,
    fecha_antiguedad,
    fecha_baja,
    contratacion
FROM
    personal_historico;

