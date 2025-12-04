----------------------------------------------
-- Export file for user RRHH@N_AYTOPROD     --
-- Created by carlos on 04/12/2025, 9:53:08 --
----------------------------------------------

set define off
spool rrhh.log

prompt
prompt Creating view AREA
prompt ==================
prompt
@@area.vw
prompt
prompt Creating view BAJAS_ILT
prompt =======================
prompt
@@bajas_ilt.vw
prompt
prompt Creating view BOLSA_SALDO_PERIODO
prompt =================================
prompt
@@bolsa_saldo_periodo.vw
prompt
prompt Creating view BOLSA_SALDO
prompt =========================
prompt
@@bolsa_saldo.vw
prompt
prompt Creating view BOLSA_SALDO_PERIODO_RESUMEN
prompt =========================================
prompt
@@bolsa_saldo_periodo_resumen.vw
prompt
prompt Creating view CALENDARIO_FICHAJE
prompt ================================
prompt
@@calendario_fichaje.vw
prompt
prompt Creating view CALENDARIO_COLUMNA_FICHAJE
prompt ========================================
prompt
@@calendario_columna_fichaje.vw
prompt
prompt Creating view PERSONAL_NEW
prompt ==========================
prompt
@@personal_new.vw
prompt
prompt Creating function LABORAL_DIA
prompt =============================
prompt
@@laboral_dia.fnc
prompt
prompt Creating view CALENDARIO_COLUMNA_FICHAJE_NEW
prompt ============================================
prompt
@@calendario_columna_fichaje_new.vw
prompt
prompt Creating view CALENDARIO_FINAL
prompt ==============================
prompt
@@calendario_final.vw
prompt
prompt Creating view CONFLICTO_PERMISO_BAJA
prompt ====================================
prompt
@@conflicto_permiso_baja.vw
prompt
prompt Creating view FICHAJE_DIARIOS
prompt =============================
prompt
@@fichaje_diarios.vw
prompt
prompt Creating view FICHAJE_PERIODO
prompt =============================
prompt
@@fichaje_periodo.vw
prompt
prompt Creating function OBSERVACIONES_PERMISO_EN_DIA_A
prompt ================================================
prompt
@@observaciones_permiso_en_dia_a.fnc
prompt
prompt Creating function PERMISO_EN_DIA
prompt ================================
prompt
@@permiso_en_dia.fnc
prompt
prompt Creating view FICHAJE_SALDO_COMPLETA_FIN
prompt ========================================
prompt
@@fichaje_saldo_completa_fin.vw
prompt
prompt Creating function ES_NUMERO
prompt ===========================
prompt
@@es_numero.fnc
prompt
prompt Creating function DEVUELVE_DIA_JORNADA
prompt ======================================
prompt
@@devuelve_dia_jornada.fnc
prompt
prompt Creating view FICHAJE_SALDO_FICHADO
prompt ===================================
prompt
@@fichaje_saldo_fichado.vw
prompt
prompt Creating view FICHAJE_SALDO_HACER
prompt =================================
prompt
@@fichaje_saldo_hacer.vw
prompt
prompt Creating view RESUMEN_SALDO
prompt ===========================
prompt
@@resumen_saldo.vw
prompt
prompt Creating function DEVUELVE_OBSERVACIONES_FICHAJE
prompt ================================================
prompt
@@devuelve_observaciones_fichaje.fnc
prompt
prompt Creating view FICHAJE_SALDO_COMPLETA_NEW
prompt ========================================
prompt
@@fichaje_saldo_completa_new.vw
prompt
prompt Creating view FICHAJE_SALDO_COMPLETA_T
prompt ======================================
prompt
@@fichaje_saldo_completa_t.vw
prompt
prompt Creating view FICHAJE_TEST_BORRA
prompt ================================
prompt
@@fichaje_test_borra.vw
prompt
prompt Creating view HORAS_SINDICALES_TOTALES
prompt ======================================
prompt
@@horas_sindicales_totales.vw
prompt
prompt Creating view PERMISOS_EN_DIA
prompt =============================
prompt
@@permisos_en_dia.vw
prompt
prompt Creating view PERMISOS_PENDIENTES
prompt =================================
prompt
@@permisos_pendientes.vw
prompt
prompt Creating view PERSONAL_ANNO_BAJAS
prompt =================================
prompt
@@personal_anno_bajas.vw
prompt
prompt Creating view PERSONAL_ANNO_INGRESO
prompt ===================================
prompt
@@personal_anno_ingreso.vw
prompt
prompt Creating view PERSONAL_ANNO_INGRESOS
prompt ====================================
prompt
@@personal_anno_ingresos.vw
prompt
prompt Creating view PERSONAL_CODICONV
prompt ===============================
prompt
@@personal_codiconv.vw
prompt
prompt Creating view PERSONAL_CONVENIO
prompt ===============================
prompt
@@personal_convenio.vw
prompt
prompt Creating view PERSONAL_EDAD_TRAMOS
prompt ==================================
prompt
@@personal_edad_tramos.vw
prompt
prompt Creating view PERSONAL_PLAZA_V
prompt ==============================
prompt
@@personal_plaza_v.vw
prompt
prompt Creating view PERSONAL_PRUEBAS
prompt ==============================
prompt
@@personal_pruebas.vw
prompt
prompt Creating view RESUMEN_SALDO_BOLSA
prompt =================================
prompt
@@resumen_saldo_bolsa.vw
prompt
prompt Creating view V_BOLSA_MOVIMIENTO
prompt ================================
prompt
@@v_bolsa_movimiento.vw
prompt
prompt Creating view V_BOLSA_SALDO
prompt ===========================
prompt
@@v_bolsa_saldo.vw
prompt
prompt Creating view VISTA_PERMISO_BOMBEROS
prompt ====================================
prompt
@@vista_permiso_bomberos.vw
prompt
prompt Creating view WEBFINGER
prompt =======================
prompt
@@webfinger.vw
prompt
prompt Creating package MAUSENCIAS
prompt ===========================
prompt
@@mausencias.spc
prompt
prompt Creating package PKG_EMAILS
prompt ===========================
prompt
@@pkg_emails.spc
prompt
prompt Creating package PKG_MAIL_BASE
prompt ==============================
prompt
@@pkg_mail_base.spc
prompt
prompt Creating package WBS_PORTAL_EMPLEADO
prompt ====================================
prompt
@@wbs_portal_empleado.spc
prompt
prompt Creating function ACTUALIZA_APLICACIONES_DA
prompt ===========================================
prompt
@@actualiza_aplicaciones_da.fnc
prompt
prompt Creating function BASE64ENCODE
prompt ==============================
prompt
@@base64encode.fnc
prompt
prompt Creating function CALCULA_ANT_POST
prompt ==================================
prompt
@@calcula_ant_post.fnc
prompt
prompt Creating function CALCULA_BOMBEROS_OPCION
prompt =========================================
prompt
@@calcula_bomberos_opcion.fnc
prompt
prompt Creating function CALCULA_CHECKSUM
prompt ==================================
prompt
@@calcula_checksum.fnc
prompt
prompt Creating function CALCULA_DIAS
prompt ==============================
prompt
@@calcula_dias.fnc
prompt
prompt Creating function CALCULA_DIAS_VACACIONES
prompt =========================================
prompt
@@calcula_dias_vacaciones.fnc
prompt
prompt Creating function CALCULA_LABORALES_VACA
prompt ========================================
prompt
@@calcula_laborales_vaca.fnc
prompt
prompt Creating function CALCULAR_LETRA_NIF
prompt ====================================
prompt
@@calcular_letra_nif.fnc
prompt
prompt Creating function CAMBIA_ACENTOS
prompt ================================
prompt
@@cambia_acentos.fnc
prompt
prompt Creating function FN_GETIBANDIGITS
prompt ==================================
prompt
@@fn_getibandigits.fnc
prompt
prompt Creating function CHEQUEA_CHECKIBAN
prompt ===================================
prompt
@@chequea_checkiban.fnc
prompt
prompt Creating function CHEQUEA_ENLACE_FICHERO_JUS
prompt ============================================
prompt
@@chequea_enlace_fichero_jus.fnc
prompt
prompt Creating function CHEQUEA_ENLACE_FICHERO_JUSTI
prompt ==============================================
prompt
@@chequea_enlace_fichero_justi.fnc
prompt
prompt Creating function CHEQUEA_FORMULA
prompt =================================
prompt
@@chequea_formula.fnc
prompt
prompt Creating function CHEQUEA_INTER_PERMISO_FICHAJE
prompt ===============================================
prompt
@@chequea_inter_permiso_fichaje.fnc
prompt
prompt Creating function CHEQUEA_INTERVALO_PERMISO
prompt ===========================================
prompt
@@chequea_intervalo_permiso.fnc
prompt
prompt Creating function CHEQUEA_INT_PERMISO_BOMBE
prompt ===========================================
prompt
@@chequea_int_permiso_bombe.fnc
prompt
prompt Creating function CHEQUEA_SOLAPAMIENTOS
prompt =======================================
prompt
@@chequea_solapamientos.fnc
prompt
prompt Creating function CHEQUEA_VACACIONES_JS
prompt =======================================
prompt
@@chequea_vacaciones_js.fnc
prompt
prompt Creating function CHEQUEO_ENTRA_DELEGADO
prompt ========================================
prompt
@@chequeo_entra_delegado.fnc
prompt
prompt Creating function CHEQUEO_ENTRA_DELEGADO_NEW
prompt ============================================
prompt
@@chequeo_entra_delegado_new.fnc
prompt
prompt Creating function CHEQUEO_ENTRA_DELEGADO_TEST
prompt =============================================
prompt
@@chequeo_entra_delegado_test.fnc
prompt
prompt Creating function CONEXION_LPAD
prompt ===============================
prompt
@@conexion_lpad.fnc
prompt
prompt Creating function CUENTA_BANCARIA_IBAN
prompt ======================================
prompt
@@cuenta_bancaria_iban.fnc
prompt
prompt Creating function DEVUELVE_CODIGO_FINGER
prompt ========================================
prompt
@@devuelve_codigo_finger.fnc
prompt
prompt Creating function DEVUELVE_HORAS_EXTRAS_MIN
prompt ===========================================
prompt
@@devuelve_horas_extras_min.fnc
prompt
prompt Creating function DEVUELVE_LUNES_AGUA
prompt =====================================
prompt
@@devuelve_lunes_agua.fnc
prompt
prompt Creating function DEVUELVE_MIN_FTO_HORA
prompt =======================================
prompt
@@devuelve_min_fto_hora.fnc
prompt
prompt Creating function DEVUELVE_PARAMETRO_FECHA
prompt ==========================================
prompt
@@devuelve_parametro_fecha.fnc
prompt
prompt Creating function DEVUELVE_PERIODO
prompt ==================================
prompt
@@devuelve_periodo.fnc
prompt
prompt Creating procedure FINGER_BUSCA_JORNADA_FUN
prompt ===========================================
prompt
@@finger_busca_jornada_fun.prc
prompt
prompt Creating function DEVUELVE_PERIODO_FICHAJE
prompt ==========================================
prompt
@@devuelve_periodo_fichaje.fnc
prompt
prompt Creating function DEVUELVE_VALOR_CAMPO
prompt ======================================
prompt
@@devuelve_valor_campo.fnc
prompt
prompt Creating function DEVUELVE_VALOR_CAMPO_AGENDA
prompt =============================================
prompt
@@devuelve_valor_campo_agenda.fnc
prompt
prompt Creating function DIFERENCIA_SALDO
prompt ==================================
prompt
@@diferencia_saldo.fnc
prompt
prompt Creating function ENTRADA_SALIDA
prompt ================================
prompt
@@entrada_salida.fnc
prompt
prompt Creating function EXTRAE_AGENDA
prompt ===============================
prompt
@@extrae_agenda.fnc
prompt
prompt Creating function FECHA_HOY_ENTRE_DOS
prompt =====================================
prompt
@@fecha_hoy_entre_dos.fnc
prompt
prompt Creating function FINGER_JORNADA_SOLAPA
prompt =======================================
prompt
@@finger_jornada_solapa.fnc
prompt
prompt Creating function FUNCIONARIO_BAJAS
prompt ===================================
prompt
@@funcionario_bajas.fnc
prompt
prompt Creating function FUNCIONARIO_VACACIONES
prompt ========================================
prompt
@@funcionario_vacaciones.fnc
prompt
prompt Creating function FUNCIONARIO_VACACIONES_DETA_NU
prompt ================================================
prompt
@@funcionario_vacaciones_deta_nu.fnc
prompt
prompt Creating function FUNCIONARIO_VACACIONES_DETA_TO
prompt ================================================
prompt
@@funcionario_vacaciones_deta_to.fnc
prompt
prompt Creating function GET_APLICACIONES
prompt ==================================
prompt
@@get_aplicaciones.fnc
prompt
prompt Creating function GET_USERS
prompt ===========================
prompt
@@get_users.fnc
prompt
prompt Creating function GET_USERS_TEST
prompt ================================
prompt
@@get_users_test.fnc
prompt
prompt Creating function HORAS_FICHAES_POLICIA_MES
prompt ===========================================
prompt
@@horas_fichaes_policia_mes.fnc
prompt
prompt Creating function HORAS_MIN_ENTRE_DOS_FECHAS
prompt ============================================
prompt
@@horas_min_entre_dos_fechas.fnc
prompt
prompt Creating function HORAS_TRAJADAS_MES
prompt ====================================
prompt
@@horas_trajadas_mes.fnc
prompt
prompt Creating function NUMERO_FICHAJE_PERSONA
prompt ========================================
prompt
@@numero_fichaje_persona.fnc
prompt
prompt Creating function NUMERO_VACACIONES_BOMBERO
prompt ===========================================
prompt
@@numero_vacaciones_bombero.fnc
prompt
prompt Creating function OBSERVACIONES_PERMISO_EN_DIA
prompt ==============================================
prompt
@@observaciones_permiso_en_dia.fnc
prompt
prompt Creating function PERSONAS_SINRPT
prompt =================================
prompt
@@personas_sinrpt.fnc
prompt
prompt Creating function PING
prompt ======================
prompt
@@ping.fnc
prompt
prompt Creating function TEST_ENCRIPTA
prompt ===============================
prompt
@@test_encripta.fnc
prompt
prompt Creating function TURNO_POLICIA
prompt ===============================
prompt
@@turno_policia.fnc
prompt
prompt Creating function TURNOS_FICHAES_POLICIA_MES
prompt ============================================
prompt
@@turnos_fichaes_policia_mes.fnc
prompt
prompt Creating function TURNOS_TRABAJOS_MES
prompt =====================================
prompt
@@turnos_trabajos_mes.fnc
prompt
prompt Creating function VALIDANIF
prompt ===========================
prompt
@@validanif.fnc
prompt
prompt Creating function WBS_ACTUALIZA_FOTO
prompt ====================================
prompt
@@wbs_actualiza_foto.fnc
prompt
prompt Creating function WBS_ACTUALIZA_NOMINA
prompt ======================================
prompt
@@wbs_actualiza_nomina.fnc
prompt
prompt Creating function WBS_A_DEVUELVE_FICHAJE_PERMISO
prompt ================================================
prompt
@@wbs_a_devuelve_fichaje_permiso.fnc
prompt
prompt Creating function WBS_BORRA_REPETIDOS
prompt =====================================
prompt
@@wbs_borra_repetidos.fnc
prompt
prompt Creating function WBS_DEVUELVE_CONSULTA_AUSENCIAS
prompt =================================================
prompt
@@wbs_devuelve_consulta_ausencias.fnc
prompt
prompt Creating function WBS_DEVUELVE_CONSULTA_PERMISOS
prompt ================================================
prompt
@@wbs_devuelve_consulta_permisos.fnc
prompt
prompt Creating function WBS_DEVUELVE_CURSOS
prompt =====================================
prompt
@@wbs_devuelve_cursos.fnc
prompt
prompt Creating function WBS_DEVUELVE_DATOS_NOMINAS
prompt ============================================
prompt
@@wbs_devuelve_datos_nominas.fnc
prompt
prompt Creating function WBS_DEVUELVE_DATOS_OPERACION
prompt ==============================================
prompt
@@wbs_devuelve_datos_operacion.fnc
prompt
prompt Creating function WBS_DEVUELVE_DATOS_PERSONALES
prompt ===============================================
prompt
@@wbs_devuelve_datos_personales.fnc
prompt
prompt Creating function WBS_DEVUELVE_FICHERO_FOTO
prompt ===========================================
prompt
@@wbs_devuelve_fichero_foto.fnc
prompt
prompt Creating function WBS_DEVUELVE_FICHERO_JUSTIFICANTE_PER_AU
prompt ==========================================================
prompt
@@wbs_devuelve_fichero_justificante_per_au.fnc
prompt
prompt Creating function WBS_DEVUELVE_FIRMA
prompt ====================================
prompt
@@wbs_devuelve_firma.fnc
prompt
prompt Creating function WBS_DEVUELVE_FIRMA_PERMISOS
prompt =============================================
prompt
@@wbs_devuelve_firma_permisos.fnc
prompt
prompt Creating function WBS_DEVUELVE_MENSAJES
prompt =======================================
prompt
@@wbs_devuelve_mensajes.fnc
prompt
prompt Creating function WBS_DEVUELVE_PERMISOS_BOMBEROS
prompt ================================================
prompt
@@wbs_devuelve_permisos_bomberos.fnc
prompt
prompt Creating function WBS_DEVUELVE_PERMISOS_COMPAS
prompt ==============================================
prompt
@@wbs_devuelve_permisos_compas.fnc
prompt
prompt Creating function WBS_DEVUELVE_PERMISOS_FICHAJES_SERV
prompt =====================================================
prompt
@@wbs_devuelve_permisos_fichajes_serv.fnc
prompt
prompt Creating function WBS_DEVUELVE_PERMISOS_FICHAJES_SERV_OLD
prompt =========================================================
prompt
@@wbs_devuelve_permisos_fichajes_serv_old.fnc
prompt
prompt Creating function WBS_DEVUELVE_ROLES
prompt ====================================
prompt
@@wbs_devuelve_roles.fnc
prompt
prompt Creating function WBS_DEVUELVE_SALDO_BOLSAS
prompt ===========================================
prompt
@@wbs_devuelve_saldo_bolsas.fnc
prompt
prompt Creating function WBS_DEVUELVE_SALDO_HORARIO
prompt ============================================
prompt
@@wbs_devuelve_saldo_horario.fnc
prompt
prompt Creating function WBS_DEVUELVE_TR_ESTADOS
prompt =========================================
prompt
@@wbs_devuelve_tr_estados.fnc
prompt
prompt Creating function WBS_INSERTA_CURSO
prompt ===================================
prompt
@@wbs_inserta_curso.fnc
prompt
prompt Creating function WBS_JUSTIFICA_FICHERO
prompt =======================================
prompt
@@wbs_justifica_fichero.fnc
prompt
prompt Creating function WBS_JUSTIFICA_FICHERO_SIN
prompt ===========================================
prompt
@@wbs_justifica_fichero_sin.fnc
prompt
prompt Creating procedure A_ACTUALIZAR_REFENCIA_CATASTRAL
prompt ==================================================
prompt
@@a_actualizar_refencia_catastral.prc
prompt
prompt Creating procedure A_BUSCAR_REFENCIA_CATASTRAL
prompt ==============================================
prompt
@@a_buscar_refencia_catastral.prc
prompt
prompt Creating procedure ACTUALIZA_APLICACIONES_DA_P
prompt ==============================================
prompt
@@actualiza_aplicaciones_da_p.prc
prompt
prompt Creating procedure ACTUALIZA_CURSOS
prompt ===================================
prompt
@@actualiza_cursos.prc
prompt
prompt Creating procedure FINGER_CALCULA_SALDO_RESUMEN
prompt ===============================================
prompt
@@finger_calcula_saldo_resumen.prc
prompt
prompt Creating procedure FINGER_LEE_TRANS
prompt ===================================
prompt
@@finger_lee_trans.prc
prompt
prompt Creating procedure FINGER_LIMPIA_TRANS
prompt ======================================
prompt
@@finger_limpia_trans.prc
prompt
prompt Creating procedure FICHAJE_CALCULA_SALDO_REGE
prompt =============================================
prompt
@@fichaje_calcula_saldo_rege.prc
prompt
prompt Creating procedure FINGER_CALCULA_SALDO
prompt =======================================
prompt
@@finger_calcula_saldo.prc
prompt
prompt Creating procedure FINGER_CALCULA_SALDO_POLICIA
prompt ===============================================
prompt
@@finger_calcula_saldo_policia.prc
prompt
prompt Creating procedure FINGER_REGENERA_SALDO
prompt ========================================
prompt
@@finger_regenera_saldo.prc
prompt
prompt Creating procedure ACTUALIZA_FINGER
prompt ===================================
prompt
@@actualiza_finger.prc
prompt
prompt Creating procedure ACTUALIZA_PERSONAL_SAVIA
prompt ===========================================
prompt
@@actualiza_personal_savia.prc
prompt
prompt Creating procedure ACTUALIZAR_REFERENCIAS_FALTANTES
prompt ===================================================
prompt
@@actualizar_referencias_faltantes.prc
prompt
prompt Creating procedure ACTUALIZAR_UNICO_NEW
prompt =======================================
prompt
@@actualizar_unico_new.prc
prompt
prompt Creating procedure ANULA_FICHAJE_FINGER_15000
prompt =============================================
prompt
@@anula_fichaje_finger_15000.prc
prompt
prompt Creating procedure A_REFENCIA_CATASTRAL
prompt =======================================
prompt
@@a_refencia_catastral.prc
prompt
prompt Creating procedure CHEQUEO_HSINDICAL
prompt ====================================
prompt
@@chequeo_hsindical.prc
prompt
prompt Creating procedure INSERTA_AUSENCIAS_RRHH
prompt =========================================
prompt
@@inserta_ausencias_rrhh.prc
prompt
prompt Creating procedure METE_FICHAJE_FINGER_NEW
prompt ==========================================
prompt
@@mete_fichaje_finger_new.prc
prompt
prompt Creating procedure AUSENCIAS_ALTA_RRHH
prompt ======================================
prompt
@@ausencias_alta_rrhh.prc
prompt
prompt Creating procedure ENVIO_CORREO_REAL
prompt ====================================
prompt
@@envio_correo_real.prc
prompt
prompt Creating procedure ENVIO_CORREO
prompt ===============================
prompt
@@envio_correo.prc
prompt
prompt Creating procedure AUSENCIAS_ANULA_USUARIO
prompt ==========================================
prompt
@@ausencias_anula_usuario.prc
prompt
prompt Creating procedure AUSENCIAS_EDITA_RRHH
prompt =======================================
prompt
@@ausencias_edita_rrhh.prc
prompt
prompt Creating procedure INSERTA_AUSENCIAS
prompt ====================================
prompt
@@inserta_ausencias.prc
prompt
prompt Creating procedure AUSENCIAS_NEW
prompt ================================
prompt
@@ausencias_new.prc
prompt
prompt Creating procedure AVISO_LEGAL_FUNCIONARIOS
prompt ===========================================
prompt
@@aviso_legal_funcionarios.prc
prompt
prompt Creating procedure BOMBEROS_GUARDIA_P
prompt =====================================
prompt
@@bomberos_guardia_p.prc
prompt
prompt Creating procedure CALCULA_PERMISOS_LOS_ANIOS
prompt =============================================
prompt
@@calcula_permisos_los_anios.prc
prompt
prompt Creating procedure CAMBIA_FIRMA
prompt ===============================
prompt
@@cambia_firma.prc
prompt
prompt Creating procedure CAMBIA_FIRMA_TELETRABAJO
prompt ===========================================
prompt
@@cambia_firma_teletrabajo.prc
prompt
prompt Creating procedure CARGA_ATM_FICHERO
prompt ====================================
prompt
@@carga_atm_fichero.prc
prompt
prompt Creating procedure CARGA_ATM_FICHERO_INGRESOS
prompt =============================================
prompt
@@carga_atm_fichero_ingresos.prc
prompt
prompt Creating procedure CHEQUEA_DA_FINAL
prompt ===================================
prompt
@@chequea_da_final.prc
prompt
prompt Creating procedure CHEQUEA_DA_FINAL_FALTAN
prompt ==========================================
prompt
@@chequea_da_final_faltan.prc
prompt
prompt Creating procedure CHEQUEA_FUNCIONARIO_DIARIO
prompt =============================================
prompt
@@chequea_funcionario_diario.prc
prompt
prompt Creating procedure CHEQUEA_FUNCIONARIO_DIARIO_SOLO_1
prompt ====================================================
prompt
@@chequea_funcionario_diario_solo_1.prc
prompt
prompt Creating procedure CHEQUEO_BASICO_NEW
prompt =====================================
prompt
@@chequeo_basico_new.prc
prompt
prompt Creating procedure CHEQUEO_BOLSA_CONCILIA
prompt =========================================
prompt
@@chequeo_bolsa_concilia.prc
prompt
prompt Creating procedure CHEQUEO_COMPENSATORIO
prompt ========================================
prompt
@@chequeo_compensatorio.prc
prompt
prompt Creating procedure CHEQUEO_VACACIONES_BOMBEROS
prompt ==============================================
prompt
@@chequeo_vacaciones_bomberos.prc
prompt
prompt Creating procedure CHEQUEO_VACACIONES_NEW
prompt =========================================
prompt
@@chequeo_vacaciones_new.prc
prompt
prompt Creating procedure ENVIA_CORREO_INFORMA
prompt =======================================
prompt
@@envia_correo_informa.prc
prompt
prompt Creating procedure ENVIA_CORREO_INFORMA_NEW
prompt ===========================================
prompt
@@envia_correo_informa_new.prc
prompt
prompt Creating procedure EXPE_ACTUA_TRANSCURRIDO
prompt ==========================================
prompt
@@expe_actua_transcurrido.prc
prompt
prompt Creating procedure EXPE_ACTUA_TRANSCURRIDO_TODO
prompt ===============================================
prompt
@@expe_actua_transcurrido_todo.prc
prompt
prompt Creating procedure FICHAJE_CALCULA_SALDO_REGE_ANT
prompt =================================================
prompt
@@fichaje_calcula_saldo_rege_ant.prc
prompt
prompt Creating procedure FICHAJE_CHEQUEA_HEXTRAS_TRAN
prompt ===============================================
prompt
@@fichaje_chequea_hextras_tran.prc
prompt
prompt Creating procedure FICHAJE_INSERTA_TRAN_HEXTRAS
prompt ===============================================
prompt
@@fichaje_inserta_tran_hextras.prc
prompt
prompt Creating procedure FICHAJE_INSERTA_HEXTRAS
prompt ==========================================
prompt
@@fichaje_inserta_hextras.prc
prompt
prompt Creating procedure FICHAJE_CHEQUEA_HEXTRAS
prompt ==========================================
prompt
@@fichaje_chequea_hextras.prc
prompt
prompt Creating procedure FICHAJE_GUARDA_CALENDARIO
prompt ============================================
prompt
@@fichaje_guarda_calendario.prc
prompt
prompt Creating procedure FICHAJE_GUARDA_CONFIGURACION
prompt ===============================================
prompt
@@fichaje_guarda_configuracion.prc
prompt
prompt Creating procedure FICHAJE_POR_INTRANET
prompt =======================================
prompt
@@fichaje_por_intranet.prc
prompt
prompt Creating procedure FINGER_CALCULA_SALDO_HIST
prompt ============================================
prompt
@@finger_calcula_saldo_hist.prc
prompt
prompt Creating procedure FINGER_CALCULA_SALDO_NEW
prompt ===========================================
prompt
@@finger_calcula_saldo_new.prc
prompt
prompt Creating procedure FINGER_GENERA_INFORME
prompt ========================================
prompt
@@finger_genera_informe.prc
prompt
prompt Creating procedure FINGER_LEE_TRANS_HIST
prompt ========================================
prompt
@@finger_lee_trans_hist.prc
prompt
prompt Creating procedure FINGER_LIMPIA_TRANS0
prompt =======================================
prompt
@@finger_limpia_trans0.prc
prompt
prompt Creating procedure FINGER_PLANIFICA_INFORME
prompt ===========================================
prompt
@@finger_planifica_informe.prc
prompt
prompt Creating procedure FINGER_PROCESA_TRANSACCIONES
prompt ===============================================
prompt
@@finger_procesa_transacciones.prc
prompt
prompt Creating procedure FINGER_REGENERA_INCIDENCIAS
prompt ==============================================
prompt
@@finger_regenera_incidencias.prc
prompt
prompt Creating procedure FINGER_REGENERA_SALDO_AÑO
prompt ============================================
prompt
@@finger_regenera_saldo_año.prc
prompt
prompt Creating procedure FINGER_REGENERA_SALDO_DIARIO
prompt ===============================================
prompt
@@finger_regenera_saldo_diario.prc
prompt
prompt Creating procedure FINGER_REGENERA_SALDO_HIST
prompt =============================================
prompt
@@finger_regenera_saldo_hist.prc
prompt
prompt Creating procedure FINGER_REGENERA_SALDO_LISTA
prompt ==============================================
prompt
@@finger_regenera_saldo_lista.prc
prompt
prompt Creating procedure FINGER_REGENERA_SALDO_UN_DIA
prompt ===============================================
prompt
@@finger_regenera_saldo_un_dia.prc
prompt
prompt Creating procedure FINGER_RELOJES_CHEQUEA
prompt =========================================
prompt
@@finger_relojes_chequea.prc
prompt
prompt Creating procedure FIRMA_AUSENCIA_JSA
prompt =====================================
prompt
@@firma_ausencia_jsa.prc
prompt
prompt Creating procedure PERMISO_DENEGADO
prompt ===================================
prompt
@@permiso_denegado.prc
prompt
prompt Creating procedure FIRMA_PERMISO_JSA_NEW
prompt ========================================
prompt
@@firma_permiso_jsa_new.prc
prompt
prompt Creating procedure FIRMA_JSA_VARIOS
prompt ===================================
prompt
@@firma_jsa_varios.prc
prompt
prompt Creating procedure FIRMA_JSA_VARIOS_WEBS
prompt ========================================
prompt
@@firma_jsa_varios_webs.prc
prompt
prompt Creating procedure HORAS_SINDICALES
prompt ===================================
prompt
@@horas_sindicales.prc
prompt
prompt Creating procedure INSERTA_HISTORICO
prompt ====================================
prompt
@@inserta_historico.prc
prompt
prompt Creating procedure INSERTA_PERMISO_NEW
prompt ======================================
prompt
@@inserta_permiso_new.prc
prompt
prompt Creating procedure INSERTA_PERMISO_RRHH
prompt =======================================
prompt
@@inserta_permiso_rrhh.prc
prompt
prompt Creating procedure INSERTA_PERMISO_RRHH_NEW
prompt ===========================================
prompt
@@inserta_permiso_rrhh_new.prc
prompt
prompt Creating procedure NUMERO_FICHAJE_PERSONA_N
prompt ===========================================
prompt
@@numero_fichaje_persona_n.prc
prompt
prompt Creating procedure INSERTA_PERSONA_BOMBEROS_FINGER
prompt ==================================================
prompt
@@inserta_persona_bomberos_finger.prc
prompt
prompt Creating procedure LDAP_CONNECT
prompt ===============================
prompt
@@ldap_connect.prc
prompt
prompt Creating procedure MOV_BOLSA_DESCUENTO_ENFERME
prompt ==============================================
prompt
@@mov_bolsa_descuento_enferme.prc
prompt
prompt Creating procedure PERMISOS_ALTA_RRHH_NEW
prompt =========================================
prompt
@@permisos_alta_rrhh_new.prc
prompt
prompt Creating procedure PERMISOS_ANULA_USUARIO
prompt =========================================
prompt
@@permisos_anula_usuario.prc
prompt
prompt Creating procedure PERMISOS_EDITA_RRHH_NEW
prompt ==========================================
prompt
@@permisos_edita_rrhh_new.prc
prompt
prompt Creating procedure PERMISOS_NEW
prompt ===============================
prompt
@@permisos_new.prc
prompt
prompt Creating procedure PROCESA_MOV_BOLSA_CONCILIA
prompt =============================================
prompt
@@procesa_mov_bolsa_concilia.prc
prompt
prompt Creating procedure PROCESA_MOVIMIENTO_BOLSA
prompt ===========================================
prompt
@@procesa_movimiento_bolsa.prc
prompt
prompt Creating procedure TRASPASA_SALDO_BOLSA
prompt =======================================
prompt
@@traspasa_saldo_bolsa.prc
prompt
prompt Creating procedure VBUENO_AUSENCIA_RRHH
prompt =======================================
prompt
@@vbueno_ausencia_rrhh.prc
prompt
prompt Creating procedure VBUENO_PERMISO_RRHH
prompt ======================================
prompt
@@vbueno_permiso_rrhh.prc
prompt
prompt Creating procedure VBUENO_RRHH
prompt ==============================
prompt
@@vbueno_rrhh.prc
prompt
prompt Creating procedure VBUENO_VARIOS
prompt ================================
prompt
@@vbueno_varios.prc
prompt
prompt Creating package body WBS_PORTAL_EMPLEADO
prompt =========================================
prompt
@@wbs_portal_empleado.bdy

spool off
