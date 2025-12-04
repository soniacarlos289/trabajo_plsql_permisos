CREATE OR REPLACE PROCEDURE RRHH."FINGER_PLANIFICA_INFORME" (
          V_ID_FUNCIONARIO in number,
          V_CAMPOS_INFORME in varchar2) is

  i_id_tipo_ausencia number;
  V_INFORME_SEC       varchar2(100);
  V_ID_TIPO_INFORME   varchar2(100);
  V_TITULO_INFORME    varchar2(100);
  V_FILTRO_1          varchar2(100);
  V_FILTRO_1_TXT      varchar2(100);
  V_FILTRO_1_PARA     varchar2(100);
  V_FILTRO_2          varchar2(100);
  V_FILTRO_2_TXT      varchar2(100);
  V_FILTRO_2_PARA_1   varchar2(100);
  V_FILTRO_2_PARA_2   varchar2(100);


begin

  ---Parametros V_CAMPOS_INFORME
  -- id_secuencia_informe -- S
  -- id_tipo_informe,     -- TI
  -- titulo,              -- T
  -- valido,              -- F1
  -- filtro_1 ,           -- F2
  -- filtro_1_para        -- FP
  -- filtro_2 ,           -- F2
  -- filtro_2_para        --FI FF




  V_ID_TIPO_INFORME:= devuelve_valor_campo(V_CAMPOS_INFORME ,'TIPOZ');
  V_TITULO_INFORME:= devuelve_valor_campo(V_CAMPOS_INFORME ,'TITULOZ');
  V_FILTRO_1:= devuelve_valor_campo(V_CAMPOS_INFORME ,'FILTRO1Z');
  V_FILTRO_1_TXT:= devuelve_valor_campo(V_CAMPOS_INFORME ,'FILTRO1ZTXT');
  V_FILTRO_1_PARA:= devuelve_valor_campo(V_CAMPOS_INFORME ,'PARA1Z');
  V_FILTRO_2:= devuelve_valor_campo(V_CAMPOS_INFORME ,'FILTRO2Z');
  V_FILTRO_2_TXT:= devuelve_valor_campo(V_CAMPOS_INFORME ,'FILTRO2ZTXT');


  IF V_FILTRO_2 = 'M' THEN
     V_FILTRO_2_PARA_1:= 'FI' || devuelve_valor_campo(V_CAMPOS_INFORME ,'PARA2FIZ') || ';FF' ||devuelve_valor_campo(V_CAMPOS_INFORME ,'PARA2FPZ') || ';';
  ELSE
     V_FILTRO_2_PARA_1:= devuelve_valor_campo(V_CAMPOS_INFORME ,'PARA2FIZ');
  END IF;

  IF V_FILTRO_2_PARA_1 = 'DA' THEN
    V_FILTRO_2_TXT:='Día Anterior';
    ELSE IF V_FILTRO_2_PARA_1 = 'MA' THEN
               V_FILTRO_2_TXT:='Mes Anterior';
         ELSE  IF   V_FILTRO_2_PARA_1 = 'PA' THEN
                    V_FILTRO_2_TXT:='Periodo Anterior';
               END IF;
         END IF;
  END IF;



  --INSERTAMOS EL INFORME
  insert into fichaje_informe
    (id_secuencia_informe, id_tipo_informe, titulo, valido, filtro_1, filtro_2, audit_usuario, audit_fecha, filtro_1_para, filtro_2_para, fecha_ult_ejec
    ,filtro_1_txt,filtro_2_txt
    )
  values
    (sec_fichaje_informe.nextval ,  V_ID_TIPO_INFORME, V_TITULO_INFORME, 1,

     V_FILTRO_1, V_FILTRO_2, V_ID_FUNCIONARIO,sysdate, V_FILTRO_1_PARA,V_FILTRO_2_PARA_1, ''
     ,V_FILTRO_1_TXT,V_FILTRO_2_TXT
     );


COMMIT;

END FINGER_PLANIFICA_INFORME;
/

