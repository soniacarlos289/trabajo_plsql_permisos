CREATE OR REPLACE PROCEDURE RRHH."ENVIO_CORREO"  (
sender IN VARCHAR2,
recipient IN VARCHAR2,
ccrecipient IN VARCHAR2,
subject IN VARCHAR2,
message IN VARCHAR2
) IS

BEGIN
envio_correo_REAL(sender ,
                              recipient ,
                              ccrecipient ,
                              subject ,
                              message);
                               commit;

END ENVIO_CORREO;
/

