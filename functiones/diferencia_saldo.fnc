create or replace function rrhh.DIFERENCIA_SALDO(V_ID_FUNCIONARIO IN varchar2, PERIODO IN varchar2,ID_ANO IN VARCHAR2) return varchar2 is
  Result number;
  i_diferencia_Saldo number;

BEGIN

   BEGIN
         select sum(campo9)
                into i_diferencia_Saldo
          from (
                 select
                       NVL(sum((to_char(B.HCOMPUTABLEF,'hh24')*60+to_char(B.HCOMPUTABLEF,'mi'))),50000) AS CAMPO9
                 from
                       temp_persfich_proceso B,webperiodo c
                 where
                       b.NPERSONAL=V_ID_FUNCIONARIO and
                       b.FECHA between to_Date(sysdate-365,'dd/mm/yy') and
                                       to_Date(sysdate-1,'dd/mm/yy') and
                       c.ano = ID_ANO and
                       c.mes = PERIODO and
                       b.fecha between c.inicio and c.fin
                union
                select
                      ( NVL(sum((to_char(B.HCOMPUTABLEF,'hh24')*60+to_char(B.HCOMPUTABLEF,'mi'))),40000))*-1 AS CAMPO9
                from
                       persfich B,webperiodo c
                where
                       b.NPERSONAL=V_ID_FUNCIONARIO and
                       b.FECHA between to_Date(sysdate-365,'dd/mm/yy') and
                                       to_Date(sysdate-1,'dd/mm/yy') and
                       c.ano = ID_ANO and
                       c.mes = PERIODO and
                       b.fecha between c.inicio and c.fin);
    EXCEPTION
            WHEN NO_DATA_FOUND THEN

          i_diferencia_Saldo:=-500000;
    END;

Result:=i_diferencia_Saldo;
return(Result);
end  DIFERENCIA_SALDO;
/

