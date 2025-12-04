CREATE OR REPLACE FUNCTION RRHH.CUENTA_BANCARIA_IBAN(numCuenta VARCHAR2) RETURN varchar2 IS
   sIBAN varchar2(24);
   nIBANConversion number;
BEGIN
  IF numCuenta IS NULL THEN
    RETURN '';
  ELSE
    nIBANConversion := TO_NUMBER(concat(numCuenta, '142800'));
    sIBAN := replace(concat('ES',TO_CHAR(98-MOD(nIBANConversion,97),'00')), ' ', '');
    sIBAN := concat(sIBAN, numCuenta);
    RETURN sIBAN;
  END IF;
END;
/

