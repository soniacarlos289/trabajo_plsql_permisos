CREATE OR REPLACE FUNCTION RRHH.cambia_acentos(v_valor IN VARCHAR2) RETURN varchar2 IS
v_caracter  varchar2(14500);
BEGIN


v_caracter := v_valor;

  v_caracter := replace(v_caracter,'á', ';aacute;');
  v_caracter := replace(v_caracter,'é', ';eacute;');
  v_caracter := replace(v_caracter,'í', ';iacute;');
  v_caracter := replace(v_caracter,'ó', ';oacute;');
  v_caracter := replace(v_caracter,'ú', ';uacute;');
  v_caracter := replace(v_caracter,'ñ', ';ntilde;');
  v_caracter := replace(v_caracter,'ü', ';uuml;');

 v_caracter := replace(v_caracter,'Á', ';Aacute;');
 v_caracter := replace(v_caracter,'É', ';Eacute;');
 v_caracter := replace(v_caracter,'Í', ';Iacute;');
 v_caracter := replace(v_caracter,'Ó', ';Oacute;');
 v_caracter := replace(v_caracter,'Ú', ';Uacute;');
 v_caracter := replace(v_caracter,'Ñ', ';Ntilde;');
 v_caracter := replace(v_caracter,'Ü', ';Uuml;');

  return v_caracter;

END;
/

