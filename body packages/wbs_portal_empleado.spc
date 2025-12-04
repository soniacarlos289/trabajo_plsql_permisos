CREATE OR REPLACE PACKAGE RRHH.WBS_PORTAL_EMPLEADO AS

  -- Author  : CARLOS
  -- Created : 31/07/2024 10:47:53
  -- Purpose : WebServices
  -- Public function and procedure declarations







  -- Controlador
  procedure wbs_controlador(parametros_entrada  in VARCHAR2,resultado out clob,p_blob IN BLOB);



END  WBS_PORTAL_EMPLEADO;
/

