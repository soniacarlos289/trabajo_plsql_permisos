create or replace procedure rrhh.envia_correo_informa(

        V_TIPO_PETICION  in number,
        V_ID_TIPO_PERMISO in varchar2,
        V_nombre_peticion  in  varchar2,
        V_DES_TIPo_PERMISO_larga in  varchar2,
         v_id_motivo  in  varchar2,
        V_FECHA_INICIO in DATE,
        V_FECHA_FIN in DATE,
        V_HORA_INICIO  in varchar2,
        V_HORA_FIN  in varchar2,
        V_ID_GRADO in varchar2,
        V_ID_TIPO_DIAS in  varchar2,
        V_NUM_DIAS in number,
        v_mensaje out varchar2

          ) is

i_todo_ok_B number;
v_cabecera_tipo varchar2(5000);
v_pie_tipo varchar2(5000);
i_desc_mensaje  varchar2(25000);

begin

i_todo_ok_B:=0;

--PERMISO_DENEGADO 0
--Permiso_JEFE GUARDIA BOMBEROS 1
--PETICION PERMISO 2
--PERMISO CONCEDIDO VO RHHH 3
IF V_TIPO_PETICION = 0 THEN
   v_cabecera_tipo:='Permiso denegado por ' || V_ID_MOTIVO;
   v_pie_tipo:='Este Permiso ha sido denegado';
   ELSE IF V_TIPO_PETICION = 1 THEN --AUTORIZADO JS INFORMA JA solo 2 nivel.
           v_cabecera_tipo:='INFORMACION DE PERMISO AUTORIZADO POR EL JEFE DE GUARDIA.';
           v_pie_tipo:='Permiso autorizado.';
          ELSE IF V_TIPO_PETICION = 2 THEN --FIRMA
                 v_cabecera_tipo:='Petición Autorización de Permiso';
                 v_pie_tipo:='El permiso requiere de su autorización para ser concedido';
                  ELSE IF V_TIPO_PETICION = 3 THEN --Permiso concedido
                       v_cabecera_tipo:='El permiso ha sido Concedido';
                       v_pie_tipo:='Permiso Concedido';
                       end if;
                END IF;
        END IF;
END IF;

BEGIN
 select CABECERA || ' '||
           v_cabecera_tipo ||' '||
           SOLICITADO || ' '||
           v_nombre_peticion ||' '||
           TIPO_PERMISO ||' '||
           v_DES_TIPo_PERMISO_larga ||' '||
           FECHA_INICIO  ||' '||
           to_char(V_FECHA_INICIO,'DD-MON-YY')  ||' '||
           FECHA_FIN     ||' '||
           to_char(V_FECHA_FIN,'DD-MON-YY') ||' '||
           DECODE(ID_TIPO_PERMISO, '15000',             -- DECODE 15000
           HORA_INICIO ||' '|| V_HORA_INICIO   ||' '||  --
           HORA_FIN    ||' '|| V_HORA_FIN      || ' '|| --
           TOTAL_HORAS ||' ' ,                       --
           NUMERO_DIAS ||' '||                         -- DISTINTO 15000
           V_NUM_DIAS ||' '||                          --  DISTINTO 15000
           DECODE(V_ID_TIPO_DIAS,'L','Laboral/es','N','Natural/es') --
             ) ||' '||
           DECODE(ID_TIPO_PERMISO
                    ,'04500',GRADO ||' '|| V_ID_GRADO  ||' ' -- DECODE 45000 o 40000
                     ,   '') ||' '||
           CABECERA_FI ||' '||
           v_pie_tipo ||' '||
           CABECERA_FIN_1
           ||
           CABECERA_FIN_1_1

     into  i_desc_mensaje
     from  FORMATO_CORREO
     where DECODE(V_ID_TIPO_PERMISO,
                     '15000' , '15000' ,
                     '04000' , '04500' ,
                     '04500' , '04500' ,
                     '06100' , '06100' ,
                     '00000'
             )=ID_TIPO_PERMISO and rownum<2;
EXCEPTION
     WHEN NO_DATA_FOUND THEN
     i_desc_mensaje:='';
END;


 v_mensaje:=i_desc_mensaje;

end envia_correo_informa;
/

