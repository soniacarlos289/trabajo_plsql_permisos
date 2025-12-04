create or replace procedure rrhh.BOMBEROS_GUARDIA_P
 is
i_ficha number;
v_num_dias number;
v_id_tipo_dias_per varchar2(1);
v_codpers varchar2(5);
i_todo_ok_B number;
msgBasico  varchar2(256);
v_id_tipo_dias_ent  varchar2(256);
i_codpers varchar(5);
i_id_funcionario number;
v_num_dias_tiene_per number;


BEGIN

--borrado de tabla para que vaya mas rapido
/*delete from Bomberos_guardias_plani;

insert into BOMBEROS_GUARDIAS_PLANI (
select * from sige.GUARDIAS@lsige
where
SUBSTR(guardia,1,4) > 2016 );*/

commit;


END BOMBEROS_GUARDIA_P;
/

