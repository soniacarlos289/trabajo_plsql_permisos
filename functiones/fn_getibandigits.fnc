CREATE OR REPLACE FUNCTION RRHH.fn_GetIBANDigits(IBAN IN VARCHAR2) RETURN VARCHAR2 AS
        lChar   VARCHAR2(1);
        lNumber INTEGER;
        lString VARCHAR2(255);
      BEGIN
        FOR i IN 1..LENGTH(IBAN) LOOP
          lChar := SUBSTR(IBAN, i, 1);
          BEGIN
            lNumber := ASCII(lChar);
            IF lNumber > 47 AND lNumber < 58 THEN
              -- It's number 0 ... 9
              lString := lString || TO_CHAR(lNumber - 48);
            ELSE
              lString := lString || TO_CHAR(lNumber - 55);
            END IF;
          END;
        END LOOP;
        RETURN lString;
      END fn_GetIBANDigits;
/

