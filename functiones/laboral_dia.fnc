create or replace function rrhh.
LABORAL_DIA(V_ID_FUNCIONARIO in varchar2,
v_ID_DIA in DATE) return varchar2 is

Result varchar2(512);


i_encontrado number;
v_id_permiso number;

i_TIPO_justifica varchar2(2);
i_permiso_justifica varchar2(2);
id_tipo_dia number;

V_LABORAL varchar2(2);
i_contador number;
ID_TIPO_FUNCIONARIO number;
V_DESC_COL varchar2(200);
v_desc_columna varchar2(20);
i_turno number;
begin

    i_encontrado:=1;
    V_LABORAL:='NO';
    i_contador:=0;
     i_turno:=0;
    BEGIN
         select TIPO_FUNCIONARIO2
         into ID_TIPO_FUNCIONARIO
           from personal_new p
          where id_funcionario=V_id_funcionario and rownum<2;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
                  i_encontrado:=0;
    END;

     BEGIN
         select DECODE(to_char(id_dia,'d'),7,'FE',6,'FE',

         DECODE(LABORAL,'NO','FE','SI')) as LAB , '<a href=../Finger/detalle_dia.jsp?ID_DIA=' || to_char(id_dia,'dd/mm/yyyy')
         ||'><div align=center>' ||to_char(id_dia,'dd') || '</a></td>'
         into V_LABORAL,V_DESC_COL
           from calendario_laboral ca
          where id_dia=V_id_dia and rownum<2;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
               V_LABORAL:='NO';
               V_DESC_COL:='';
    END;
    v_desc_columna:='CCCCCC';
    --COLUMNA
    BEGIN
     select substr(DESC_TIPO_COLUMNA,1,19) as DESC_COLUMNA
            into v_desc_columna
     from RRHH.TR_TIPO_COLUMNA_CALENDARIO t, permiso p
     where p.id_tipo_permiso=t.id_tipo_permiso and
           p.id_estado=t.id_tipo_estado and id_ano > 2015 and id_funcionario=V_id_funcionario
           and V_ID_DIA between fecha_inicio and fecha_fin and rownum<2;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
               v_desc_columna:='FFFFFF';
    END;



    --sera laboral si tiene fichajes ese dia
    IF ID_TIPO_FUNCIONARIO=21 THEN
      i_contador :=0;

       BEGIN
         select turno
         into  i_turno
           from fichaje_funcionario
          where id_funcionario=V_id_funcionario and
                to_date(to_char(fecha_fichaje_entrada,'dd/mm/yyyy'),'dd/mm/yyyy')=
                 to_date(to_char(V_id_dia ,'dd/mm/yyyy'),'dd/mm/yyyy')
                 and     rownum<2;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
                  i_contador:=-1;
       END;

       IF i_contador > -1 then
            BEGIN
                select DECODE(to_char(id_dia,'d'),7,'FE',6,'FE',laboral) as LAB , '<a href=../Finger/detalle_dia.jsp?ID_DIA=' || to_char(id_dia,'dd/mm/yyyy')
                 ||'><div align=center>' || DECODE(i_turno,1,'M',2,'T',3,'N',0,'?')
                || '</a></td>'
                into V_LABORAL,V_DESC_COL
                 from calendario_laboral ca
                where id_dia=V_id_dia and rownum<2;
           EXCEPTION
               WHEN NO_DATA_FOUND THEN
               V_LABORAL:='NO';
               V_DESC_COL:='';
           END;
             --V_LABORAL:='SI';
       ELsE
         V_LABORAL:='NO';
       END IF;


    END IF;

     IF ID_TIPO_FUNCIONARIO=23 THEN
      i_contador :=0;

       BEGIN
         select count(*)
         into i_contador
         from Bomberos_guardias_plani
         where to_date(to_char(desde,'DD/mm/yyyy'),'DD/mm/yyyy') =
               to_date(to_char(V_ID_DIA,'DD/mm/yyyy'),'DD/mm/yyyy')
          and funcionario=V_id_funcionario;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
                  i_contador:=0;
       END;

       IF i_contador > 0 then
         V_LABORAL:='SI';
       ELsE
         V_LABORAL:='NO';
       END IF;


    END IF;


    IF    v_desc_columna<>'FFFFFF' THEN

        V_DESC_COL:= v_desc_columna|| V_DESC_COL;

    ELSE IF    V_LABORAL='NO'  THEN
              V_DESC_COL:= '<td bgcolor=#bfc1be>'|| V_DESC_COL; --bfc1be
         ELSE IF V_LABORAL='FE' THEN
               V_DESC_COL:= '<td bgcolor=#FA5858>'|| V_DESC_COL;
              ELSE
               V_DESC_COL:= '<td bgcolor=#FFFFFF>'|| V_DESC_COL;
              END IF;
         END IF;

    END IF;


    result:=V_DESC_COL;



  return(Result);
end LABORAL_DIA;
/

