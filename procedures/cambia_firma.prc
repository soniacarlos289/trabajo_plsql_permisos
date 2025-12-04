CREATE OR REPLACE PROCEDURE RRHH."CAMBIA_FIRMA"
       (V_ID_CAMBIA_FIRMA in varchar2,
        V_ID_FUNCIONARIO_FIRMA_ANT in number,
        V_ID_FUNCIONARIO_FIRMA_NEW in number,
        V_ID_FUNCIONARIO in number,
        V_UNICO in  VARCHAR2,-- 1 PARA TODOS, 0 SOLO PARA UN FUNCIONARIO
        V_DELEGA in  VARCHAR2,
        todo_ok_Basico out integer,msgBasico out varchar2) is

begin

todo_ok_basico:=0;
msgBasico:='';

BEGIN
    insert into funcionario_firma
  (id_funcionario, id_js, id_delegado_js, id_ja, id_delegado_ja)
values
  (V_ID_FUNCIONARIO, V_ID_FUNCIONARIO, V_ID_FUNCIONARIO, V_ID_FUNCIONARIO, V_ID_FUNCIONARIO);

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
       todo_ok_basico:=0;
END;

CASE V_ID_CAMBIA_FIRMA
    WHEN '1' THEN
         UPDATE FUNCIONARIO_FIRMA SET ID_js= V_ID_FUNCIONARIO_FIRMA_NEW
         WHERE
           (ID_FUNCIONARIO= V_ID_FUNCIONARIO OR V_UNICO='1') AND
            ((ID_js= V_ID_FUNCIONARIO_FIRMA_ANT) OR (V_UNICO='0' AND V_ID_FUNCIONARIO_FIRMA_ANT=0))
            ;

     WHEN '2' THEN
         UPDATE FUNCIONARIO_FIRMA
         SET ID_delegado_js= V_ID_FUNCIONARIO_FIRMA_NEW,
             id_delegado_firma= to_number(V_DELEGA)
         WHERE
           (ID_FUNCIONARIO= V_ID_FUNCIONARIO OR V_UNICO='1') AND
            ((ID_delegado_js= V_ID_FUNCIONARIO_FIRMA_ANT) OR (V_UNICO='0' AND V_ID_FUNCIONARIO_FIRMA_ANT=0))
             ;


      WHEN '3' THEN
         UPDATE FUNCIONARIO_FIRMA SET ID_ja= V_ID_FUNCIONARIO_FIRMA_NEW
         WHERE
           (ID_FUNCIONARIO= V_ID_FUNCIONARIO OR V_UNICO='1') AND
            ((ID_ja= V_ID_FUNCIONARIO_FIRMA_ANT) OR (V_UNICO='0' AND V_ID_FUNCIONARIO_FIRMA_ANT=0))
             ;

      WHEN '4' THEN
         UPDATE FUNCIONARIO_FIRMA SET id_ver_plani_1= V_ID_FUNCIONARIO_FIRMA_NEW
         WHERE
           (ID_FUNCIONARIO= V_ID_FUNCIONARIO OR V_UNICO='1') AND
            ((id_ver_plani_1= V_ID_FUNCIONARIO_FIRMA_ANT) OR (V_UNICO='0' AND V_ID_FUNCIONARIO_FIRMA_ANT=0))
             ;
       WHEN '5' THEN
         UPDATE FUNCIONARIO_FIRMA SET id_ver_plani_2= V_ID_FUNCIONARIO_FIRMA_NEW
         WHERE
           (ID_FUNCIONARIO= V_ID_FUNCIONARIO OR V_UNICO='1') AND
            ((id_ver_plani_2= V_ID_FUNCIONARIO_FIRMA_ANT) OR (V_UNICO='0' AND V_ID_FUNCIONARIO_FIRMA_ANT=0))
             ;
        WHEN '6' THEN
         UPDATE FUNCIONARIO_FIRMA SET id_ver_plani_3= V_ID_FUNCIONARIO_FIRMA_NEW
         WHERE
           (ID_FUNCIONARIO= V_ID_FUNCIONARIO OR V_UNICO='1') AND
            ((id_ver_plani_3= V_ID_FUNCIONARIO_FIRMA_ANT) OR (V_UNICO='0' AND V_ID_FUNCIONARIO_FIRMA_ANT=0))
             ;

    ELSE
        NULL;
END CASE;

todo_ok_basico:=0;
msgBasico:= 'CAMBIO: ' || V_ID_CAMBIA_FIRMA ||
            'FUN ANTIGUO: ' ||   V_ID_FUNCIONARIO_FIRMA_ANT ||
            'FUN NUEVO: ' ||   V_ID_FUNCIONARIO_FIRMA_NEW ||
            'FUN CAM: ' ||    V_ID_FUNCIONARIO ||
            'UNICO: '   ||   V_UNICO ||
            'DELEGA: '   ||      V_DELEGA ;

            msgBasico:= 'Cambio aplicado';
commit;

end CAMBIA_FIRMA;
/

