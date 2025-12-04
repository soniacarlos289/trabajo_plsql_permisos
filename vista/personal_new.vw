CREATE OR REPLACE FORCE VIEW RRHH.PERSONAL_NEW AS
SELECT
codienti,
versempl,
DECODE(to_char(id_funcionario),'962055','962588','962057','10013','962058','101167','962500','962016','962576','962362',
'962577','600127','962578','962578',to_char(id_funcionario)) as id_funcionario,
categoria,
puesto,
fecha_nacimiento,
DECODE(id_funcionario,'962342',10,'39161',50,'201337',10,decode(tipo_funcionario2,0,10, tipo_funcionario2)) as TIpo_funcionario2,
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
PERSONAL_HISTORICO;

