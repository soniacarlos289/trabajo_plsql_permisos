create or replace function rrhh.
CHEQUEA_ENLACE_FICHERO_JUS(V_ANNO in varchar2,V_ID_FUNCIONARIO in varchar2,
                           v_ID_PERMISO in varchar2,V_ID_ESTADO in number,
                           V_ID_TIPO_PERMISO in varchar2,V_ID_APLICACION in varchar2) return varchar2 is

--V_ID_APLICACION 1 Portal del Empleado
--V_ID_APLICACION 2 Administración  de Permisos

Result varchar2(5012);

  i_encontrado number;
  v_desc_tipo_columna varchar2(4024);


begin

    i_encontrado:=1;
    v_desc_tipo_columna :='';





--buscamos el enlace
      BEGIN
           select id
             into i_encontrado
             from ficheros_justificantes
            where id=V_ANNO || V_ID_FUNCIONARIO ||v_ID_PERMISO;
      EXCEPTION
           WHEN NO_DATA_FOUND THEN
                    v_desc_tipo_columna :='<td bgcolor=FFFFFF align="center"></td>';
                    i_encontrado:=0;
      END;



 IF    V_ID_APLICACION = 1 THEN
    v_desc_tipo_columna := '<a target="_blank"  href="../fichero/verDoc.jsp?PERMISO=' || V_ID_TIPO_PERMISO ||  '&ID='
    || V_ANNO || V_ID_FUNCIONARIO ||v_ID_PERMISO ||
    ' "target="mainFrame"><img src="../imagen/pdf.png" alt="Ver" width="20" height="20" border="0"></a>';
 else
     v_desc_tipo_columna := '<a  href="#"  onClick="javascript:window.open(''' || '../fichero/verDoc.jsp?PERMISO=' ||
     V_ID_TIPO_PERMISO ||  '&ID='
    || V_ANNO || V_ID_FUNCIONARIO ||v_ID_PERMISO ||
    ''',null,'||'''top=0,left=100,height=600,width=940,scrollbars=yes,status=no,toolbar=no ,menubar=no,location=0,directories=no''' ||
    ');"><img src="../../imagen/pdf.png" alt="Ver" width="20" height="20" border="0"></a>';

     if V_ID_ESTADO <>80 THEN
          /* v_desc_tipo_columna := v_desc_tipo_columna || ' ' || '<a  href="#"  onClick="javascript:window.open(''' || '../fichero/eliminarDoc.jsp?PERMISO=' ||
            V_ID_TIPO_PERMISO ||  '&ID='
            || V_ANNO || V_ID_FUNCIONARIO ||v_ID_PERMISO ||
    ''',null,'||'''top=0,left=100,height=600,width=940,scrollbars=yes,status=no,toolbar=no ,menubar=no,location=0,directories=no''' ||
    ');"><img src="../../imagen/delete.png" alt="Eliminar" width="15" height="15" border="0"></a>'; */
     v_desc_tipo_columna := v_desc_tipo_columna || ' ' ||  '<a href="javascript:show_confirmar(' || V_ANNO || V_ID_FUNCIONARIO ||v_ID_PERMISO || ');"><img src="../../imagen/delete.png" alt="Eliminar" width="15" height="15" border="0"></a>';

    END IF;

 END IF;

if  i_encontrado= 0 then
   IF    V_ID_APLICACION = 1 THEN
      v_desc_tipo_columna := '<a   href="../fichero/ficheroDoc.jsp?PERMISO=' || V_ID_TIPO_PERMISO ||  '&ID='
    || V_ANNO || V_ID_FUNCIONARIO ||v_ID_PERMISO ||
    '"><img src="../imagen/new.png" alt="Subir" width="20" height="20" border="0"></a>';
--<a href="#" onClick="javascript:window.open('../bolsa_concilia/index.jsp' ,null,'top=0,left=100,height=600,width=940,scrollbars=yes,status=no,toolbar=no ,menubar=no,location=0,directories=no');">ENLACE BOLSA CONCILIA </a>
                  --<%     }   %>
   else
      v_desc_tipo_columna := '<a  href="#"
     onClick="javascript:window.open(''' || '../fichero/ficheroDoc.jsp?PERMISO=' || V_ID_TIPO_PERMISO ||  '&ID='
    || V_ANNO || V_ID_FUNCIONARIO ||v_ID_PERMISO ||
    ''',null,'||'''top=0,left=100,height=600,width=940,scrollbars=yes,status=no,toolbar=no ,menubar=no,location=0,directories=no''' ||
    ');"><img src="../../imagen/new.png" alt="Subir" width="20" height="20" border="0"></a>';

   end if;

END IF;

         result:= v_desc_tipo_columna;

    IF   V_ID_TIPO_PERMISO ='P'  AND    v_ID_PERMISO  < 470600 then
       result:= '';

    end if;


      IF   V_ID_TIPO_PERMISO ='A'  AND    v_ID_PERMISO  < 210071 then
       result:= '';

    end if;
    IF (V_ID_ESTADO =30 OR  V_ID_ESTADO= 40 OR  V_ID_ESTADO= 31 OR  V_ID_ESTADO= 32 OR  V_ID_ESTADO= 41) THEN
      result:= '';

    END IF;

  return(Result);
end CHEQUEA_ENLACE_FICHERO_JUS;
/

