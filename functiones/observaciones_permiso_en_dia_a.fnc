create or replace function rrhh.
OBSERVACIONES_PERMISO_EN_DIA_A(V_ID_FUNCIONARIO in varchar2,
v_DIA in DATE,v_HH in number,V_HR in number,V_TURNO in number,
V_ENTRADA in varchar2,V_SALIDA in varchar2

) return varchar2 is

Result varchar2(1512);


i_encontrado number;
v_id_permiso number;

i_TIPO_justifica varchar2(2);
i_permiso_justifica varchar2(2);
v_descr varchar2(89);
V_observaciones varchar2(10000);
i_id_hora number;
i_id_ano  number;

begin

    i_encontrado:=1;
    v_id_permiso:=1;

    BEGIN
         select id_permiso ,tc.JUSTIFICACION,nvl(p.justificacion,'NO'), DESC_PERMISO_CORTA
         into v_id_permiso,i_TIPO_justifica, i_permiso_justifica,v_descr
           from permiso  p,  tr_tipo_permiso tc
          where id_funcionario=V_id_funcionario  and
                p.id_tipo_permiso = tc.id_tipo_permiso and
                p.id_ano = tc.id_ano and
                v_DIA between p.fecha_inicio and nvl(p.fecha_fin,sysdate+1)   and
                (anulado='NO' OR ANULADO IS NULL) and id_estado  in ('80')
                and p.id_tipo_permiso not in (15000)
                and rownum<2;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN

                  i_encontrado:=0;
                  v_id_permiso:=0;
    END;


    --PERMISO NO JUSTIFICADO
    if  v_id_permiso<> 0  AND i_TIPO_justifica='SI' AND i_permiso_justifica='NO' then
        v_id_permiso:=0;
    END IF;

     --Buscamos permisos
     IF v_id_permiso <>0  THEN
         result:= '<a href="../Permisos/ver.jsp?ID_PERMISO=' ||v_id_permiso || '" >' ||  v_descr || '</a>  '|| 'Justificado:' || i_permiso_justifica ;
     ELSE

         i_encontrado:=1;

         BEGIN
            SELECT    distinct DECODE(observaciones,null,
                      DECODE(DESC_TIPO_INCIDENCIA,'Sin fichajes en día laborable.',
                      'Sin fichajes en día laborable.<img src="../../imagen/icono_advertencia.jpg" alt="INCIDENCIA"  width="22" height="22" border="0" >',DESC_TIPO_INCIDENCIA)
                  ,observaciones)
                into Result
               FROM FICHAJE_INCIDENCIA f, personal_new pe, tr_tipo_incidencia tr
           where (fecha_baja is null or fecha_baja > sysdate - 1)
             and f.id_funcionario = pe.id_funcionario
             and f.id_tipo_incidencia = tr.id_tipo_incidencia
             and f.id_funcionario=V_ID_FUNCIONARIO
             and f.fecha_incidencia=v_DIA
             and id_Estado_inc = 0 and rownum<2;
              EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                            i_encontrado:=0;
              END;


          IF i_encontrado = 0 THEN
             IF V_TURNO = 1 THEN
               Result:='Turno Mañana';
             ELSE  IF V_TURNO = 2 THEN
                          Result:='Turno Tarde';
                   ELSE  IF V_TURNO = 3 THEN
                               Result:='Turno Noche';
                         ELSE
                                  Result:='';
                         END IF;

                   END IF;

             END IF;

          END IF;

            BEGIN
           select id_hora,id_ano
              into i_id_hora ,i_id_ano
           from  horas_extras
             where        V_ENTRADA=HORA_INICIO
                    and   V_SALIDA=HORA_FIN
                    and  id_funcionario=V_ID_FUNCIONARIO
                    and fecha_horas=v_DIA
              and  (ANULADO='NO' or ANULADO is null);
               EXCEPTION
                   WHEN NO_DATA_FOUND THEN
                          i_id_hora :=0;
              END;
          IF    i_id_hora    > 0 then
             result:= '<a href="../Horas/editar.jsp?ID_HORA=' ||i_id_hora || '&ID_ANO='||i_id_ano  || '" >' ||  'Horas extras' || '</a>  ';

          END IF;


      END IF;



  return(Result);
end OBSERVACIONES_PERMISO_EN_DIA_A;
/

