CREATE OR REPLACE FUNCTION RRHH.CHEQUEA_CheckIBAN(
      pIBAN IN VARCHAR2
    ) RETURN INTEGER IS
      lResult     INTEGER;
      IBAN        VARCHAR2(256);
      IBAN_Digits VARCHAR2(256);
      l_mod       NUMBER;
      lTmp        VARCHAR2(8);
      lSCnt       INTEGER := 5;
      i           INTEGER := 1;


     BEGIN
      IBAN := SUBSTR(pIBAN, 5) || SUBSTR(pIBAN, 1, 4);

      IBAN_Digits := fn_GetIBANDigits(IBAN);

      LOOP
        lTmp := SUBSTR(IBAN_Digits, i, lSCnt);
        EXIT WHEN lTmp IS NULL;

        IF l_mod IS NULL THEN
          l_mod := MOD( TO_NUMBER(lTmp), 97);
        ELSE
          l_mod := MOD(TO_NUMBER( TO_CHAR(l_mod) || lTmp), 97);
        END IF;

        i := i + lSCnt;
      END LOOP;

      IF l_mod = 1 THEN
        lResult := 1;
      ELSE
        lResult := 0;
      END IF;

      RETURN(lResult);
    END CHEQUEA_CheckIBAN;
/

