CREATE OR REPLACE FUNCTION RRHH.VALIDANIF(DNI   IN VARCHAR2  ) RETURN varchar2 AS
  letrasValidas CHAR(23) := 'TRWAGMYFPDXBNJZSQVHLCKE';
  letraCorrecta CHAR;
  letraLeida    CHAR ;
  resto         INTEGER;
  NIF           varchar2(10);
BEGIN
  IF es_NUMERO(DNI) = 0 THEN

  resto         := DNI MOD 23;
  letraCorrecta := SUBSTR(letrasValidas, resto + 1, 1);
  NIF           := letraCorrecta;

   NIF := lpad(DNI,8,'0') || letraCorrecta;
   return nif;
   ELSE
     return 0;
   END IF;
END VALIDANIF;
/

