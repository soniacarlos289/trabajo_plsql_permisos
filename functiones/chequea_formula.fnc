create or replace function rrhh.CHEQUEA_FORMULA(V_ID_FUNCIONARIO in varchar2,
V_ID_TIPO_PERMISO in varchar2,V_ID_TIPO_FUNCIONARIO in varchar2,
v_FECHA_INICIO in DATE,v_FECHA_FIN in DATE) return number is

Result number;
i_fecha_inicio date;
i_fecha_fin date;
i_num_anterior number;
i_num_posterior number;
i_permiso_ant_encontrado varchar2(5);
i_permiso_post_encontrado varchar2(5);

i_id_tipo_permiso varchar2(5);
i_id_dia_anterior date;
i_id_dia_posterior date;
 i_permiso_solicitado varchar2(5);
begin

i_fecha_inicio:=v_fecha_inicio;
i_fecha_fin:=v_fecha_fin;

i_permiso_ant_encontrado:='';
i_permiso_post_encontrado:='';
i_permiso_solicitado:='';



--Permiso solicitado
 IF (V_ID_TIPO_PERMISO='01000' or
      SUBSTR(V_ID_TIPO_PERMISO,1,3)='030'  OR
       V_ID_TIPO_PERMISO='01015' OR
        V_ID_TIPO_PERMISO='15000') THEN

      i_permiso_solicitado:='VA';
      else if (V_ID_TIPO_PERMISO='02000' or
               V_ID_TIPO_PERMISO='02015' or
               V_ID_TIPO_PERMISO='02081' or
               V_ID_TIPO_PERMISO='02082' or
               V_ID_TIPO_PERMISO='02162' or
               V_ID_TIPO_PERMISO='02241' or
               V_ID_TIPO_PERMISO='02242') then
             i_permiso_solicitado:='AP';
            else
             i_permiso_solicitado:='OTRO';
            end if;
 end if;


--ANTERIOR
   --Para funcionarios SNP
   IF V_ID_TIPO_FUNCIONARIO = 10 THEN
      --Busco el dia anterior para saber si es laboral.
    i_id_dia_anterior:= calcula_ant_post(i_fecha_inicio,'A');
   ELSE
    i_id_dia_anterior:= i_fecha_inicio-1;
   END IF;

   i_num_anterior:=1;
   --PARA EL ANTERIOR,OBTENGO SI HAY ALGUN PERMISO
    BEGIN
         select fecha_inicio,substr(id_tipo_permiso,1,3)
           into i_fecha_inicio,i_id_tipo_permiso
           from permiso
          where id_funcionario=V_id_funcionario and
                (id_tipo_permiso in ('01000','02000','02015',
                                    '02081','02082' ,'02162' ,'02241','02242','01015') OR
                id_tipo_permiso like ('030%')    OR ( id_tipo_permiso='15000' and total_horas>240 )     )
                                     and
                i_id_dia_anterior between fecha_inicio and fecha_fin   and
                (anulado='NO' OR ANULADO IS NULL) and id_estado not in ('30','31','32','40','41') and rownum<2;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
                   i_num_anterior:=0;
                   i_permiso_ant_encontrado:='';
    END;

   IF i_num_anterior = 1 then
     IF i_id_tipo_permiso='010' THEN
        i_permiso_ant_encontrado:='VA';
     END IF;
     IF i_id_tipo_permiso='020' THEN
        i_permiso_ant_encontrado:='AP';
     END IF;
     IF i_id_tipo_permiso='021' THEN
        i_permiso_ant_encontrado:='AP';
     END IF;
     IF  i_id_tipo_permiso='022' THEN
        i_permiso_ant_encontrado:='AP';
     END IF;
     IF i_id_tipo_permiso='150' THEN
        i_permiso_ant_encontrado:='VA';
     END IF;
     IF i_id_tipo_permiso='030' THEN
       i_permiso_ant_encontrado:='VA';
     END IF;

  END IF;





--POSTERIOR

   --Para funcionarios SNP
   IF V_ID_TIPO_FUNCIONARIO = 10 THEN
      --Busco el dia POSTERIOR para saber si es laboral.
    i_id_dia_POSTERIOR:= calcula_ant_post(i_fecha_fin,'P');
   ELSE
    i_id_dia_POSTERIOR:= i_fecha_fin+1;
   END IF;

   i_num_POSTERIOR:=1;
   i_permiso_post_encontrado:='';
   --PARA EL POSTERIOR,OBTENGO SI HAY ALGUN PERMISO
    BEGIN
         select fecha_fin,substr(id_tipo_permiso,1,3)
           into i_fecha_fin,i_id_tipo_permiso
           from permiso
         where id_funcionario=V_id_funcionario and
                (id_tipo_permiso in ('01000','02000','02015',
                                    '02081','02082' ,'02162' ,'02241','02242','01015') OR
                id_tipo_permiso like ('030%')    OR ( id_tipo_permiso='15000' and total_horas>240 )     )
                                     and
                i_id_dia_POSTERIOR between fecha_inicio and fecha_fin   and
                (anulado='NO' OR ANULADO IS NULL) and id_estado not in ('30','31','32','40','41') and rownum<2;
    EXCEPTION
         WHEN NO_DATA_FOUND THEN
                   i_num_POSTERIOR:=0;
                     i_permiso_post_encontrado:='';
    END;

   IF i_num_POSTERIOR = 1 then
     IF i_id_tipo_permiso='010' THEN
        i_permiso_post_encontrado:='VA';
     END IF;
     IF i_id_tipo_permiso='020' THEN
        i_permiso_post_encontrado:='AP';
     END IF;
     IF  i_id_tipo_permiso='021' THEN
        i_permiso_post_encontrado:='AP';
     END IF;
     IF i_id_tipo_permiso='022' THEN
        i_permiso_post_encontrado:='AP';
     END IF;
     IF i_id_tipo_permiso='150' THEN
        i_permiso_post_encontrado:='VA';
     END IF;
     IF i_id_tipo_permiso='030' THEN
       i_permiso_post_encontrado:='VA';
     END IF;

  END IF;



--FORMULA  AP  + VA
--FORMULA  Asuntos Propios  + COMPENSATORIOS + Vacaciones

IF  (i_permiso_ant_encontrado='AP' and  i_permiso_solicitado='VA') OR
    (i_permiso_ant_encontrado='VA' and  i_permiso_solicitado='AP') OR
     (i_permiso_solicitado='OTRO' and  i_permiso_ant_encontrado='AP') OR

    (i_permiso_post_encontrado='AP' and  i_permiso_solicitado='VA') OR
    (i_permiso_post_encontrado='VA' and  i_permiso_solicitado='AP') OR
     (i_permiso_solicitado='OTRO' and  i_permiso_post_encontrado='AP')

            THEN
    result:=1;
ELSE
    result:=0;
END IF;
result:=0;  
  return(Result);

end CHEQUEA_FORMULA;
/

