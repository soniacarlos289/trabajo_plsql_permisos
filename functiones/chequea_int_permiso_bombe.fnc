create or replace function rrhh.
CHEQUEA_INT_PERMISO_BOMBE(V_ID_FUNCIONARIO in varchar2,
v_DIA_CALENDARIO in DATE,TRAMO1 IN NUMBER,TRAMO2 IN NUMBER,TRAMO3 IN NUMBER) return varchar2 is

Result varchar2(512);

v_desc_tipo_columna_1 varchar2(512);
v_desc_tipo_columna_2 varchar2(512);
v_desc_tipo_columna_3 varchar2(512);
i_encontrado number;
i_ordena number;
 I_ID_FUNCIONARIO varchar2(512);
 i_dotacion number;

begin
   i_encontrado:=1;
   i_ordena:=2;--no trabaja
   i_dotacion:=0;
--LE TOCA GUARDIA.
--chm cambio de turnos 21/05/2022
-- empieza la guradias en esotos turnos.
--•	TRAMO 1: 14:00-22:00 pasa a 08:00 a 16:00
--•	TRAMO 2: 22:00-06:00 para a 16:00 a 24:00
--•	TRAMO 3: 06:00-14:00 pasa a 00:00 a 08:00

IF  v_DIA_CALENDARIO< to_Date('21/05/2022') then

   begin
       select FUNCIONARIO ,decode(dotacion,'#BA',1,0)
       into I_ID_FUNCIONARIO, i_dotacion from Bomberos_guardias_plani --cambiado por esta tabla que se refresca cada día
       --sige.GUARDIAS@lsige
       where
          to_date(to_char(v_DIA_CALENDARIO,'dd/mm/yyyy') || ' 14:00','dd/mm/yyyy hh24:mi')= desde --and HAsta
                    and funcionario=V_ID_FUNCIONARIO
                    AND SUBSTR(guardia,1,4) > 2018 ;
      EXCEPTION
           WHEN NO_DATA_FOUND THEN
                    i_encontrado:=0;
                    I_ID_FUNCIONARIO:=  null;
                    i_dotacion:=0;


   END;
 ELSE

   begin
       select FUNCIONARIO ,decode(dotacion,'#BA',1,0)
       into I_ID_FUNCIONARIO, i_dotacion from Bomberos_guardias_plani --cambiado por esta tabla que se refresca cada día
       --sige.GUARDIAS@lsige
       where
          to_date(to_char(v_DIA_CALENDARIO,'dd/mm/yyyy') || ' 08:00','dd/mm/yyyy hh24:mi')= desde --and HAsta
                    and funcionario=V_ID_FUNCIONARIO
                    AND SUBSTR(guardia,1,4) > 2018 ;
      EXCEPTION
           WHEN NO_DATA_FOUND THEN
                    i_encontrado:=0;
                    I_ID_FUNCIONARIO:=  null;
                    i_dotacion:=0;


   END;


END IF ;


 if I_ID_FUNCIONARIO is null then

    v_desc_tipo_columna_1 :='<td bgcolor=FFFFFF> </td>';
    v_desc_tipo_columna_2 :='<td bgcolor=FFFFFF> </td>';
   v_desc_tipo_columna_3 :='<td bgcolor=FFFFFF> </td>';
 ELSE
    v_desc_tipo_columna_1 :='<td bgcolor=E6E6E6> </td>';
    v_desc_tipo_columna_2 :='<td bgcolor=E6E6E6> </td>';
    v_desc_tipo_columna_3 :='<td bgcolor=E6E6E6> </td>';
     i_encontrado:=1;
     i_ordena:=0; --trabaja
 END IF;

IF  i_encontrado = 1 then

  i_ordena:=1; --con permiso
    BEGIN
           select
        DECODE(p.id_tipo_permiso,'11000', DECODE(tu1_14_22,1,tc.desc_tipo_columna ,''),
                                 '02030', DECODE(tu1_14_22,1,tc.desc_tipo_columna ,''),
                                 '02031', DECODE(tu1_14_22,1,tc.desc_tipo_columna ,''),
                                 '02000', DECODE(tu1_14_22,1,tc.desc_tipo_columna ,''),
                                 '01015', DECODE(tu1_14_22,1,tc.desc_tipo_columna ,''),
                                 '02015', DECODE(tu1_14_22,1,tc.desc_tipo_columna ,''),
                                                     tc.desc_tipo_columna)  as TRAMO_1,
         DECODE(p.id_tipo_permiso,
                                 '11000', DECODE(tu2_22_06,1,tc.desc_tipo_columna ,''),
                                 '02030', DECODE(tu2_22_06,1,tc.desc_tipo_columna ,''),
                                 '02031', DECODE(tu2_22_06,1,tc.desc_tipo_columna ,''),
                                 '02000', DECODE(tu2_22_06,1,tc.desc_tipo_columna ,''),
                                 '01015', DECODE(tu2_22_06,1,tc.desc_tipo_columna ,''),
                                 '02015', DECODE(tu2_22_06,1,tc.desc_tipo_columna ,''),
                                                                  tc.desc_tipo_columna)  as TRAMO_2,
        DECODE(p.id_tipo_permiso,
                                 '11000', DECODE(tu3_04_14,1,tc.desc_tipo_columna ,''),
                                 '02030', DECODE(tu3_04_14,1,tc.desc_tipo_columna ,''),
                                 '02031', DECODE(tu3_04_14,1,tc.desc_tipo_columna ,''),
                                 '02000', DECODE(tu3_04_14,1,tc.desc_tipo_columna ,''),
                                 '01015', DECODE(tu3_04_14,1,tc.desc_tipo_columna ,''),
                                 '02015', DECODE(tu3_04_14,1,tc.desc_tipo_columna ,''),
                                                                  tc.desc_tipo_columna)  as TRAMO_3
           into v_desc_tipo_columna_1,v_desc_tipo_columna_2,v_desc_tipo_columna_3
           from permiso  p,    rrhh.tr_tipo_columna_calendario tc
          where id_funcionario=V_ID_FUNCIONARIO  and
                p.id_tipo_permiso = tc.id_tipo_permiso and
                p.id_ano>2018 and
                p.id_estado = tc.id_tipo_estado   and
                v_DIA_CALENDARIO between fecha_inicio and nvl(fecha_fin,sysdate+1) and
                (anulado='NO' OR ANULADO IS NULL) and id_estado not in ('30','31','32','40') AND ROWNUM <2;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
                  i_encontrado:=0;
                   i_ordena:=0;--sin permiso y trabaja
    END;

 END IF;

   IF v_desc_tipo_columna_1 ='' or  v_desc_tipo_columna_1 is null THEN
         v_desc_tipo_columna_1 :='<td bgcolor=E6E6E6> </td>';
   END IF;

   IF v_desc_tipo_columna_2 ='' or  v_desc_tipo_columna_2 is null  THEN
         v_desc_tipo_columna_2 :='<td bgcolor=E6E6E6> </td>';
   END IF;

   IF v_desc_tipo_columna_3 ='' or  v_desc_tipo_columna_3 is null   THEN
         v_desc_tipo_columna_3 :='<td bgcolor=E6E6E6> </td>';
   END IF;



   if TRAMO1 =1  THEN
     result:=v_desc_tipo_columna_1;
   else if TRAMO2 =1  THEN

         result:=v_desc_tipo_columna_2;
           else if TRAMO3 =1  THEN
             result:=v_desc_tipo_columna_3;
                end if;
        END IF;
   end if;

   --ORDENACION
   if TRAMO1 =1 AND TRAMO2=1 AND TRAMO3 =1    THEN
       result:=i_ordena;
   END IF;

    --baja
   IF i_dotacion = 1  then

    result:='<td bgcolor=CCCC33></td>';

   end if;

  return(Result);
end CHEQUEA_INT_PERMISO_BOMBE;
/

