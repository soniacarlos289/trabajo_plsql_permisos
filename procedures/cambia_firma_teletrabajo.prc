CREATE OR REPLACE PROCEDURE RRHH.CAMBIA_FIRMA_TELETRABAJO
       (
        V_ID_FUNCIONARIO in number
        ) is

v_teletrabajo varchar2(12);

begin


BEGIN
select teletrabajo as teletrabajo
into v_teletrabajo
from FUNCIONARIO_FICHAJE
where id_funcionario=  V_ID_FUNCIONARIO and rownum<2;


EXCEPTION
    WHEN NO_DATA_FOUND THEN
       v_teletrabajo:=0;
END;

CASE v_teletrabajo
    WHEN '1' THEN
         UPDATE FUNCIONARIO_FICHAJE   SET  teletrabajo = 0
         WHERE
           ID_FUNCIONARIO= V_ID_FUNCIONARIO AND ROWNUM <2;

     WHEN '0' THEN

         UPDATE FUNCIONARIO_FICHAJE   SET  teletrabajo = 1
         WHERE
           ID_FUNCIONARIO= V_ID_FUNCIONARIO AND ROWNUM <2;


END CASE;

commit;

end CAMBIA_FIRMA_TELETRABAJO;
/

