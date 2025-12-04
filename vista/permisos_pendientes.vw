CREATE OR REPLACE FORCE VIEW RRHH.PERMISOS_PENDIENTES AS
SELECT
    id_funcionario,id_ano,
    SUM(CASE WHEN SUBSTR(id_tipo_permiso,1,3) = '010' THEN num_dias ELSE 0 END) AS VACACIONES,
    SUM(CASE WHEN SUBSTR(id_tipo_permiso,1,3) = '020' THEN num_dias ELSE 0 END) AS ASUNTOS_propios,
    SUM(CASE WHEN SUBSTR(id_tipo_permiso,1,3) = '030' THEN num_dias ELSE 0 END) AS COMPENSATORIOS,
    SUM(CASE WHEN SUBSTR(id_tipo_permiso,1,3) NOT IN ('010','020','030') THEN num_dias ELSE 0 END) AS OTROS,
    SUM(num_dias) AS TOTAL
FROM permiso_funcionario p where id_ano>2024 and p.num_dias>0 and p.unico='SI'
GROUP BY id_funcionario,id_ano;

