# Análisis de Relaciones entre Procedimientos y Funciones PL/SQL

## Repositorio: soniacarlos289/trabajo_plsql_permisos

**Fecha de análisis:** 10/12/2025 22:09

---

## 1. Resumen Ejecutivo

Este documento presenta un análisis exhaustivo de las relaciones entre procedimientos y funciones
del sistema PL/SQL de gestión de recursos humanos del Ayuntamiento de Salamanca.

### Estadísticas Generales

- **Total de Procedimientos:** 96
- **Total de Funciones:** 93
- **Total de Objetos:** 189
- **Objetos con Relaciones:** 32

### Objetos Más Conectados

| Objeto | Tipo | Llama a | Llamado por | Total |
|--------|------|---------|-------------|-------|
| ANULA_FICHAJE_FINGER_15000 | PROCEDURE | 0 | 4 | 4 |
| PERMISOS_EDITA_RRHH_NEW | PROCEDURE | 3 | 0 | 3 |
| CHEQUEA_ENLACE_FICHERO_JUSTI | FUNCTION | 0 | 3 | 3 |
| VALIDANIF | FUNCTION | 0 | 2 | 2 |
| PERMISOS_ALTA_RRHH_NEW | PROCEDURE | 2 | 0 | 2 |
| ACTUALIZAR_UNICO_NEW | PROCEDURE | 0 | 2 | 2 |
| MOV_BOLSA_DESCUENTO_ENFERME | PROCEDURE | 0 | 2 | 2 |
| CALCULA_DIAS_VACACIONES | FUNCTION | 1 | 1 | 2 |
| CALCULA_DIAS | FUNCTION | 0 | 2 | 2 |
| WBS_DEVUELVE_CONSULTA_PERMISOS | FUNCTION | 2 | 0 | 2 |

---

## 2. Clasificación por Funcionalidad

### Actualización de datos

**Total:** 13 objetos (9 procedimientos, 4 funciones)

### Carga de datos

**Total:** 2 objetos (2 procedimientos, 0 funciones)

### Consulta y devolución de información

**Total:** 36 objetos (0 procedimientos, 36 funciones)

### Cálculo de valores

**Total:** 14 objetos (8 procedimientos, 6 funciones)

### Envío de notificaciones

**Total:** 4 objetos (4 procedimientos, 0 funciones)

### Gestión de ausencias

**Total:** 4 objetos (4 procedimientos, 0 funciones)

### Gestión de bolsa de horas

**Total:** 5 objetos (5 procedimientos, 0 funciones)

### Gestión de fichajes y control de asistencia

**Total:** 18 objetos (17 procedimientos, 1 funciones)

### Gestión de permisos

**Total:** 8 objetos (5 procedimientos, 3 funciones)

### Inserción de datos

**Total:** 10 objetos (9 procedimientos, 1 funciones)

### Operación general del sistema

**Total:** 43 objetos (17 procedimientos, 26 funciones)

### Procesamiento por lotes

**Total:** 3 objetos (1 procedimientos, 2 funciones)

### Proceso de aprobación y firma

**Total:** 8 objetos (8 procedimientos, 0 funciones)

### Servicio web para portal de empleados

**Total:** 3 objetos (0 procedimientos, 3 funciones)

### Validación o verificación

**Total:** 18 objetos (7 procedimientos, 11 funciones)

---

## 3. Análisis Detallado de Procedimientos y Funciones

### ACTUALIZA_APLICACIONES_DA

**Tipo:** FUNCTION

**Propósito:** Actualización de datos

**Archivo:** `actualiza_aplicaciones_da.fnc`

**Parámetros:**

```sql
V_aplicaciones IN VARCHAR2
```

---

### BASE64ENCODE

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `base64encode.fnc`

**Parámetros:**

```sql
p_blob IN BLOB
```

---

### CALCULAR_LETRA_NIF

**Tipo:** FUNCTION

**Propósito:** Cálculo de valores

**Archivo:** `calcular_letra_nif.fnc`

**Parámetros:**

```sql
p_dni NUMBER
```

---

### CALCULA_ANT_POST

**Tipo:** FUNCTION

**Propósito:** Cálculo de valores

**Archivo:** `calcula_ant_post.fnc`

**Parámetros:**

```sql
v_FECHA IN DATE
TIPO    IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### CALCULA_BOMBEROS_OPCION

**Tipo:** FUNCTION

**Propósito:** Cálculo de valores

**Archivo:** `calcula_bomberos_opcion.fnc`

**Parámetros:**

```sql
v_ID_ANO          IN VARCHAR2
V_ID_FUNCIONARIO  IN VARCHAR2
v_id_tipo_permiso IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### CALCULA_CHECKSUM

**Tipo:** FUNCTION

**Propósito:** Validación o verificación

**Archivo:** `calcula_checksum.fnc`

**Parámetros:**

```sql
V_CADENA IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### CALCULA_DIAS

**Tipo:** FUNCTION

**Propósito:** Cálculo de valores

**Archivo:** `calcula_dias.fnc`

**Parámetros:**

```sql
D_FECHA_INICIO IN DATE
D_FECHA_FIN    IN DATE
V_CADENA       IN VARCHAR2
```

**Operaciones SQL:** SELECT

**Llamado por:**

- `CALCULA_DIAS_VACACIONES` (FUNCTION)
- `CALCULA_LABORALES_VACA` (FUNCTION)

---

### CALCULA_DIAS_VACACIONES

**Tipo:** FUNCTION

**Propósito:** Cálculo de valores

**Archivo:** `calcula_dias_vacaciones.fnc`

**Parámetros:**

```sql
D_FECHA_INICIO IN DATE
D_FECHA_FIN    IN DATE
V_TIPO_DIA     IN VARCHAR2
D_INICIO       IN DATE
D_FIN          IN DATE
```

**Llama a:**

- `CALCULA_DIAS` (FUNCTION)

**Llamado por:**

- `TRASPASA_SALDO_BOLSA` (PROCEDURE)

---

### CALCULA_LABORALES_VACA

**Tipo:** FUNCTION

**Propósito:** Cálculo de valores

**Archivo:** `calcula_laborales_vaca.fnc`

**Parámetros:**

```sql
D_FECHA_INICIO   IN DATE
D_FECHA_FIN      IN DATE
V_TIPO_DIA       IN VARCHAR2
V_ID_FUNCIONARIO IN NUMBER
V_ID_ANO         IN NUMBER
```

**Operaciones SQL:** SELECT

**Llama a:**

- `CALCULA_DIAS` (FUNCTION)

---

### CAMBIA_ACENTOS

**Tipo:** FUNCTION

**Propósito:** Actualización de datos

**Archivo:** `cambia_acentos.fnc`

**Parámetros:**

```sql
v_valor IN VARCHAR2
```

---

### CHEQUEA_CHECKIBAN

**Tipo:** FUNCTION

**Propósito:** Validación o verificación

**Archivo:** `chequea_checkiban.fnc`

**Parámetros:**

```sql
pIBAN IN VARCHAR2
```

---

### CHEQUEA_ENLACE_FICHERO_JUS

**Tipo:** FUNCTION

**Propósito:** Validación o verificación

**Archivo:** `chequea_enlace_fichero_jus.fnc`

**Parámetros:**

```sql
V_ANNO            IN VARCHAR2
V_ID_FUNCIONARIO  IN VARCHAR2
v_ID_PERMISO      IN VARCHAR2
V_ID_ESTADO       IN NUMBER
V_ID_TIPO_PERMISO IN VARCHAR2
V_ID_APLICACION   IN VARCHAR2
```

**Operaciones SQL:** SELECT

**Llamado por:**

- `WBS_DEVUELVE_CONSULTA_PERMISOS` (FUNCTION)

---

### CHEQUEA_ENLACE_FICHERO_JUSTI

**Tipo:** FUNCTION

**Propósito:** Validación o verificación

**Archivo:** `chequea_enlace_fichero_justi.fnc`

**Parámetros:**

```sql
V_ANNO           IN VARCHAR2
V_ID_FUNCIONARIO IN VARCHAR2
v_ID_PERMISO     IN VARCHAR2
```

**Operaciones SQL:** SELECT

**Llamado por:**

- `WBS_DEVUELVE_CONSULTA_AUSENCIAS` (FUNCTION)
- `WBS_DEVUELVE_CONSULTA_PERMISOS` (FUNCTION)
- `WBS_DEVUELVE_FIRMA` (FUNCTION)

---

### CHEQUEA_FORMULA

**Tipo:** FUNCTION

**Propósito:** Validación o verificación

**Archivo:** `chequea_formula.fnc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO      IN VARCHAR2
V_ID_TIPO_PERMISO     IN VARCHAR2
V_ID_TIPO_FUNCIONARIO IN VARCHAR2
v_FECHA_INICIO        IN DATE
v_FECHA_FIN           IN DATE
```

**Operaciones SQL:** SELECT

---

### CHEQUEA_INTERVALO_PERMISO

**Tipo:** FUNCTION

**Propósito:** Validación o verificación

**Archivo:** `chequea_intervalo_permiso.fnc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO IN VARCHAR2
v_DIA_CALENDARIO IN DATE
```

**Operaciones SQL:** SELECT

---

### CHEQUEA_INTER_PERMISO_FICHAJE

**Tipo:** FUNCTION

**Propósito:** Validación o verificación

**Archivo:** `chequea_inter_permiso_fichaje.fnc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO IN VARCHAR2
v_DIA_CALENDARIO IN DATE
v_posicion       IN NUMBER
```

**Operaciones SQL:** SELECT

---

### CHEQUEA_INT_PERMISO_BOMBE

**Tipo:** FUNCTION

**Propósito:** Validación o verificación

**Archivo:** `chequea_int_permiso_bombe.fnc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO IN VARCHAR2
v_DIA_CALENDARIO IN DATE
TRAMO1           IN NUMBER
TRAMO2           IN NUMBER
TRAMO3           IN NUMBER
```

**Operaciones SQL:** SELECT

---

### CHEQUEA_SOLAPAMIENTOS

**Tipo:** FUNCTION

**Propósito:** Validación o verificación

**Archivo:** `chequea_solapamientos.fnc`

**Parámetros:**

```sql
V_ID_ANO          IN NUMBER
V_ID_FUNCIONARIO  IN VARCHAR2
V_ID_TIPO_PERMISO IN VARCHAR2
V_FECHA_INICIO    IN DATE
v_FECHA_FIN       IN DATE
V_HORA_INICIO     VARCHAR2
V_HORA_FIN        VARCHAR2
```

**Operaciones SQL:** SELECT

---

### CHEQUEA_VACACIONES_JS

**Tipo:** FUNCTION

**Propósito:** Validación o verificación

**Archivo:** `chequea_vacaciones_js.fnc`

**Parámetros:**

```sql
V_ID_JS IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### CHEQUEO_ENTRA_DELEGADO

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `chequeo_entra_delegado.fnc`

**Parámetros:**

```sql
V_ID_JS_DELEGADO IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### CHEQUEO_ENTRA_DELEGADO_NEW

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `chequeo_entra_delegado_new.fnc`

**Parámetros:**

```sql
V_ID_JS_DELEGADO IN VARCHAR2
i_ID_FUNCIONARIO IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### CHEQUEO_ENTRA_DELEGADO_TEST

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `chequeo_entra_delegado_test.fnc`

**Parámetros:**

```sql
V_ID_JS_DELEGADO IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### CONEXION_LPAD

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `conexion_lpad.fnc`

**Parámetros:**

```sql
p_username IN VARCHAR2
p_password IN VARCHAR2
```

---

### CUENTA_BANCARIA_IBAN

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `cuenta_bancaria_iban.fnc`

**Parámetros:**

```sql
numCuenta VARCHAR2
```

---

### DEVUELVE_CODIGO_FINGER

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `devuelve_codigo_finger.fnc`

**Parámetros:**

```sql
I_ID_FUNCIONARIO IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### DEVUELVE_DIA_JORNADA

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `devuelve_dia_jornada.fnc`

**Parámetros:**

```sql
V_CADENA VARCHAR2
ID_DIA   DATE
```

**Operaciones SQL:** SELECT

---

### DEVUELVE_HORAS_EXTRAS_MIN

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `devuelve_horas_extras_min.fnc`

**Parámetros:**

```sql
V_HORA_INICIO    IN VARCHAR2
V_HORA_FIN       IN VARCHAR2
v_id_tipo_horas  IN NUMBER
```

**Operaciones SQL:** SELECT

---

### DEVUELVE_LUNES_AGUA

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `devuelve_lunes_agua.fnc`

**Parámetros:**

```sql
V_ANO IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### DEVUELVE_MIN_FTO_HORA

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `devuelve_min_fto_hora.fnc`

**Parámetros:**

```sql
V_CADENA IN VARCHAR2
```

---

### DEVUELVE_OBSERVACIONES_FICHAJE

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `devuelve_observaciones_fichaje.fnc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO       IN VARCHAR2
V_ID_TIPO_FUNCIONARIO  IN VARCHAR2
V_OBSERVACIONES        IN VARCHAR2
V_FICHAJE_ENTRADA      IN DATE
v_HH                   IN NUMBER
V_HR                   IN NUMBER
```

**Operaciones SQL:** SELECT

---

### DEVUELVE_PARAMETRO_FECHA

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `devuelve_parametro_fecha.fnc`

**Parámetros:**

```sql
i_filtro_2 IN VARCHAR2
i_filtro_2_para IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### DEVUELVE_PERIODO

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `devuelve_periodo.fnc`

**Parámetros:**

```sql
v_cadena IN VARCHAR2
```

**Operaciones SQL:** SELECT

**Llamado por:**

- `PERMISOS_EDITA_RRHH_NEW` (PROCEDURE)

---

### DEVUELVE_PERIODO_FICHAJE

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `devuelve_periodo_fichaje.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
v_pin            IN VARCHAR2
d_fecha_fichaje  IN DATE
i_horas_f        IN NUMBER
```

**Operaciones SQL:** SELECT

---

### DEVUELVE_VALOR_CAMPO

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `devuelve_valor_campo.fnc`

**Parámetros:**

```sql
v_cadena IN VARCHAR2
v_campo IN VARCHAR2
```

---

### DEVUELVE_VALOR_CAMPO_AGENDA

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `devuelve_valor_campo_agenda.fnc`

**Parámetros:**

```sql
v_cadena IN VARCHAR2
v_campo IN VARCHAR2
```

---

### DIFERENCIA_SALDO

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `diferencia_saldo.fnc`

**Parámetros:**

```sql
v_id_funcionario IN VARCHAR2
periodo          IN VARCHAR2
id_ano           IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### ENTRADA_SALIDA

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `entrada_salida.fnc`

**Parámetros:**

```sql
vpin VARCHAR2
```

**Operaciones SQL:** SELECT

---

### ES_NUMERO

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `es_numero.fnc`

**Parámetros:**

```sql
v_valor IN VARCHAR2
```

---

### EXTRAE_AGENDA

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `extrae_agenda.fnc`

**Operaciones SQL:** INSERT, SELECT

---

### FECHA_HOY_ENTRE_DOS

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `fecha_hoy_entre_dos.fnc`

**Parámetros:**

```sql
fecha_1 DATE
fecha_2 DATE
```

**Operaciones SQL:** SELECT

---

### FINGER_JORNADA_SOLAPA

**Tipo:** FUNCTION

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_jornada_solapa.fnc`

**Parámetros:**

```sql
V_FECHA_INICIO IN DATE
V_FECHA_FIN IN DATE
V_ID_FUNCIONARIO IN VARCHAR2
```

**Operaciones SQL:** SELECT

**Llamado por:**

- `FICHAJE_GUARDA_CONFIGURACION` (PROCEDURE)

---

### FN_GETIBANDIGITS

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `fn_getibandigits.fnc`

**Parámetros:**

```sql
IBAN IN VARCHAR2
```

---

### FUNCIONARIO_BAJAS

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `funcionario_bajas.fnc`

**Parámetros:**

```sql
V_FECHA_INICIO IN DATE
V_ID_UNIDAD IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### FUNCIONARIO_VACACIONES

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `funcionario_vacaciones.fnc`

**Parámetros:**

```sql
V_FECHA_INICIO IN DATE
V_FECHA_FIN IN DATE
V_ID_FUNCIONARIO IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### FUNCIONARIO_VACACIONES_DETA_NU

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `funcionario_vacaciones_deta_nu.fnc`

**Parámetros:**

```sql
V_FECHA_INICIO IN DATE
V_ID_UNIDAD IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### FUNCIONARIO_VACACIONES_DETA_TO

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `funcionario_vacaciones_deta_to.fnc`

**Parámetros:**

```sql
V_FECHA_INICIO IN DATE
V_ID_UNIDAD IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### GESTIONA_RUTA_LOTES

**Tipo:** FUNCTION

**Propósito:** Procesamiento por lotes

**Archivo:** `gestiona_ruta_lotes.fnc`

**Parámetros:**

```sql
p_accion              IN VARCHAR2
-- CREAR
DUPLICAR
CONSULTAR
CANCELAR
  p_id_lote_origen      IN NUMBER DEFAULT NULL
-- ID del lote origen (para duplicar)
  p_tipo_proceso        IN VARCHAR2 DEFAULT NULL
-- Tipo de proceso
  p_descripcion         IN VARCHAR2 DEFAULT NULL
-- Descripción del lote
  p_id_usuario          IN VARCHAR2
-- Usuario que ejecuta
  p_prioridad           IN NUMBER DEFAULT 5      -- Prioridad (1=Alta, 5=Normal, 10=Baja)
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### GET_APLICACIONES

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `get_aplicaciones.fnc`

**Parámetros:**

```sql
V_PROPIEDAD IN VARCHAR2
V_aplicacion IN VARCHAR2
salida OUT CLOB
```

---

### GET_USERS

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `get_users.fnc`

**Parámetros:**

```sql
V_PROPIEDAD IN VARCHAR2
V_login IN VARCHAR2
salida OUT CLOB
```

**Llamado por:**

- `LDAP_CONNECT` (PROCEDURE)

---

### GET_USERS_TEST

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `get_users_test.fnc`

**Parámetros:**

```sql
V_PROPIEDAD IN VARCHAR2
V_login IN VARCHAR2
salida OUT CLOB
```

---

### HORAS_FICHAES_POLICIA_MES

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `horas_fichaes_policia_mes.fnc`

**Parámetros:**

```sql
i_ID_FUNCIONARIO IN VARCHAR2
i_MES IN NUMBER
i_id_Anno IN NUMBER
```

**Operaciones SQL:** SELECT

---

### HORAS_MIN_ENTRE_DOS_FECHAS

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `horas_min_entre_dos_fechas.fnc`

**Parámetros:**

```sql
fecha1  IN DATE
fecha2  IN DATE
opcion  IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### HORAS_TRAJADAS_MES

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `horas_trajadas_mes.fnc`

**Parámetros:**

```sql
i_ID_FUNCIONARIO     IN VARCHAR2
ID_TIPO_FUNCIONARIO  IN NUMBER
i_MES                IN NUMBER
i_id_Anno            IN NUMBER
```

**Operaciones SQL:** SELECT

---

### LABORAL_DIA

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `laboral_dia.fnc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO IN VARCHAR2
v_ID_DIA         IN DATE
```

**Operaciones SQL:** SELECT

---

### MONITOREA_ITERACIONES_LOTES

**Tipo:** FUNCTION

**Propósito:** Procesamiento por lotes

**Archivo:** `monitorea_iteraciones_lotes.fnc`

**Parámetros:**

```sql
p_id_lote             IN NUMBER
p_formato_salida      IN VARCHAR2 DEFAULT 'JSON'  -- JSON
TEXT
HTML
```

**Operaciones SQL:** SELECT

---

### NUMERO_FICHAJE_PERSONA

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `numero_fichaje_persona.fnc`

**Operaciones SQL:** SELECT

---

### NUMERO_VACACIONES_BOMBERO

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `numero_vacaciones_bombero.fnc`

**Parámetros:**

```sql
D_FECHA_INICIO IN DATE
D_FECHA_FIN    IN DATE
D_FUNCIONARIO  IN VARCHAR2
V_numero       OUT NUMBER
```

**Operaciones SQL:** SELECT

---

### OBSERVACIONES_PERMISO_EN_DIA

**Tipo:** FUNCTION

**Propósito:** Gestión de permisos

**Archivo:** `observaciones_permiso_en_dia.fnc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO IN VARCHAR2
v_DIA            IN DATE
v_HH             IN NUMBER
V_HR             IN NUMBER
V_TURNO          IN NUMBER
```

**Operaciones SQL:** SELECT

---

### OBSERVACIONES_PERMISO_EN_DIA_A

**Tipo:** FUNCTION

**Propósito:** Gestión de permisos

**Archivo:** `observaciones_permiso_en_dia_a.fnc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO IN VARCHAR2
v_DIA            IN DATE
v_HH             IN NUMBER
V_HR             IN NUMBER
V_TURNO          IN NUMBER
V_ENTRADA        IN VARCHAR2
V_SALIDA         IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### PERMISO_EN_DIA

**Tipo:** FUNCTION

**Propósito:** Gestión de permisos

**Archivo:** `permiso_en_dia.fnc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO IN VARCHAR2
v_DIA            IN DATE
```

**Operaciones SQL:** SELECT

**Llamado por:**

- `FINGER_CALCULA_SALDO_RESUMEN` (PROCEDURE)

---

### PERSONAS_SINRPT

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `personas_sinrpt.fnc`

**Parámetros:**

```sql
V_FECHA_INICIO         IN DATE
V_FECHA_FIN            IN DATE
V_ID_FUNCIONARIO_FIRMA IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### PING

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `ping.fnc`

**Parámetros:**

```sql
p_HOST_NAME VARCHAR2
p_PORT      NUMBER DEFAULT 1000
```

**Operaciones SQL:** SELECT

---

### TEST_ENCRIPTA

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `test_encripta.fnc`

**Parámetros:**

```sql
v_valor IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### TURNOS_FICHAES_POLICIA_MES

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `turnos_fichaes_policia_mes.fnc`

**Parámetros:**

```sql
i_ID_FUNCIONARIO IN VARCHAR2
i_MES            IN NUMBER
i_id_Anno        IN NUMBER
```

**Operaciones SQL:** SELECT

---

### TURNOS_TRABAJOS_MES

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `turnos_trabajos_mes.fnc`

**Parámetros:**

```sql
i_ID_FUNCIONARIO      IN VARCHAR2
ID_TIPO_FUNCIONARIO   IN NUMBER
i_MES                 IN NUMBER
i_id_Anno             IN NUMBER
```

**Operaciones SQL:** SELECT

---

### TURNO_POLICIA

**Tipo:** FUNCTION

**Propósito:** Operación general del sistema

**Archivo:** `turno_policia.fnc`

**Parámetros:**

```sql
V_claveomesa IN VARCHAR2
i_pin        IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### VALIDANIF

**Tipo:** FUNCTION

**Propósito:** Validación o verificación

**Archivo:** `validanif.fnc`

**Parámetros:**

```sql
DNI IN VARCHAR2
```

**Operaciones SQL:** SELECT

**Llamado por:**

- `CHEQUEA_DA_FINAL` (PROCEDURE)
- `CHEQUEA_DA_FINAL_FALTAN` (PROCEDURE)

---

### WBS_ACTUALIZA_FOTO

**Tipo:** FUNCTION

**Propósito:** Actualización de datos

**Archivo:** `wbs_actualiza_foto.fnc`

**Parámetros:**

```sql
v_id_funcionario IN VARCHAR2
fichero          IN BLOB
```

**Operaciones SQL:** DELETE, INSERT

---

### WBS_ACTUALIZA_NOMINA

**Tipo:** FUNCTION

**Propósito:** Actualización de datos

**Archivo:** `wbs_actualiza_nomina.fnc`

**Parámetros:**

```sql
v_id_funcionario IN VARCHAR2
fichero          IN BLOB
```

**Operaciones SQL:** UPDATE

---

### WBS_A_DEVUELVE_FICHAJE_PERMISO

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_a_devuelve_fichaje_permiso.fnc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO IN VARCHAR2
v_DIA_CALENDARIO IN DATE
```

**Operaciones SQL:** SELECT

---

### WBS_BORRA_REPETIDOS

**Tipo:** FUNCTION

**Propósito:** Servicio web para portal de empleados

**Archivo:** `wbs_borra_repetidos.fnc`

**Operaciones SQL:** DELETE, SELECT

---

### WBS_DEVUELVE_CONSULTA_AUSENCIAS

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_consulta_ausencias.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
opcion IN VARCHAR2
anio IN NUMBER
```

**Operaciones SQL:** SELECT

**Llama a:**

- `CHEQUEA_ENLACE_FICHERO_JUSTI` (FUNCTION)

---

### WBS_DEVUELVE_CONSULTA_PERMISOS

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_consulta_permisos.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
opcion           in varchar2
anio             in number
```

**Operaciones SQL:** SELECT

**Llama a:**

- `CHEQUEA_ENLACE_FICHERO_JUS` (FUNCTION)
- `CHEQUEA_ENLACE_FICHERO_JUSTI` (FUNCTION)

---

### WBS_DEVUELVE_CURSOS

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_cursos.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
v_opcion IN NUMBER
v_id_año IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_DATOS_NOMINAS

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_datos_nominas.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
cuantas_nominas IN NUMBER
v_id_nomina IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_DATOS_OPERACION

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_datos_operacion.fnc`

**Parámetros:**

```sql
v_resultado IN VARCHAR2
v_observaciones IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_DATOS_PERSONALES

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_datos_personales.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_FICHERO_FOTO

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_fichero_foto.fnc`

**Parámetros:**

```sql
v_id_funcionario IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_FICHERO_JUSTIFICANTE_PER_AU

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_fichero_justificante_per_au.fnc`

**Parámetros:**

```sql
v_id_enlace IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_FIRMA

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_firma.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
operacion        in varchar2
tipo             in varchar2
```

**Operaciones SQL:** SELECT

**Llama a:**

- `CHEQUEA_ENLACE_FICHERO_JUSTI` (FUNCTION)

---

### WBS_DEVUELVE_FIRMA_PERMISOS

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_firma_permisos.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
cuantos_permisos IN NUMBER
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_MENSAJES

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_mensajes.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_PERMISOS_BOMBEROS

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_permisos_bomberos.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
v_opcion         IN NUMBER
v_fecha          IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_PERMISOS_COMPAS

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_permisos_compas.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
cuantos_permisos IN NUMBER
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_PERMISOS_FICHAJES_SERV

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_permisos_fichajes_serv.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
v_opcion         IN NUMBER
v_fecha          IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_PERMISOS_FICHAJES_SERV_OLD

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_permisos_fichajes_serv_old.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
v_opcion         IN NUMBER
v_fecha          IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_ROLES

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_roles.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_SALDO_BOLSAS

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_saldo_bolsas.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
opcion           IN VARCHAR2
anio             IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_SALDO_HORARIO

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_saldo_horario.fnc`

**Parámetros:**

```sql
i_id_funcionario IN VARCHAR2
opcion           IN VARCHAR2
anio             IN VARCHAR2
v_mes            IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### WBS_DEVUELVE_TR_ESTADOS

**Tipo:** FUNCTION

**Propósito:** Consulta y devolución de información

**Archivo:** `wbs_devuelve_tr_estados.fnc`

**Parámetros:**

```sql
opcion IN VARCHAR2
anio   IN NUMBER
```

**Operaciones SQL:** SELECT

---

### WBS_INSERTA_CURSO

**Tipo:** FUNCTION

**Propósito:** Inserción de datos

**Archivo:** `wbs_inserta_curso.fnc`

**Parámetros:**

```sql
v_id_funcionario IN VARCHAR2
v_id_curso       IN VARCHAR2
v_opcion         IN VARCHAR2
```

**Operaciones SQL:** DELETE, INSERT, SELECT

---

### WBS_JUSTIFICA_FICHERO

**Tipo:** FUNCTION

**Propósito:** Servicio web para portal de empleados

**Archivo:** `wbs_justifica_fichero.fnc`

**Parámetros:**

```sql
enlace_fichero IN VARCHAR2
fichero        IN BLOB
```

**Operaciones SQL:** INSERT

---

### WBS_JUSTIFICA_FICHERO_SIN

**Tipo:** FUNCTION

**Propósito:** Servicio web para portal de empleados

**Archivo:** `wbs_justifica_fichero_sin.fnc`

**Parámetros:**

```sql
v_id_permiso  IN VARCHAR2
v_id_ausencia IN VARCHAR2
fichero       IN BLOB
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### ACTUALIZAR_REFERENCIAS_FALTANTES

**Tipo:** PROCEDURE

**Propósito:** Actualización de datos

**Archivo:** `actualizar_referencias_faltantes.prc`

**Operaciones SQL:** SELECT, UPDATE

---

### ACTUALIZAR_UNICO_NEW

**Tipo:** PROCEDURE

**Propósito:** Actualización de datos

**Archivo:** `actualizar_unico_new.prc`

**Parámetros:**

```sql
V_ID_ANO in number
V_ID_FUNCIONARIO in number
V_ID_TIPO_FUNCIONARIO in number
V_ID_TIPO_PERMISO in varchar2
V_ID_TIPO_DIAS in  VARCHAR2
V_ID_TIPO_DIAS_PER in  VARCHAR2
V_FECHA_INICIO in date
V_FECHA_FIN in date
V_NUM_DIAS in number
v_num_dias_tiene_per in number
```

**Operaciones SQL:** SELECT, UPDATE

**Llamado por:**

- `PERMISOS_ALTA_RRHH_NEW` (PROCEDURE)
- `PERMISOS_NEW` (PROCEDURE)

---

### ACTUALIZA_APLICACIONES_DA_P

**Tipo:** PROCEDURE

**Propósito:** Actualización de datos

**Archivo:** `actualiza_aplicaciones_da_p.prc`

**Parámetros:**

```sql
V_aplicaciones in varchar2
v_login        in varchar2
```

**Operaciones SQL:** INSERT

---

### ACTUALIZA_CURSOS

**Tipo:** PROCEDURE

**Propósito:** Actualización de datos

**Archivo:** `actualiza_cursos.prc`

**Parámetros:**

```sql
v_id_curso              in varchar2
V_desc_curso            in varchar2
v_desc_materia          in varchar2
v_num_horas             in varchar2
V_horas_presencial      in varchar2
V_horas_distancia       in varchar2
V_contenido             in varchar2
V_objetivo              in varchar2
V_requisitos            in varchar2
v_observaciones         in varchar2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### ACTUALIZA_FINGER

**Tipo:** PROCEDURE

**Propósito:** Actualización de datos

**Archivo:** `actualiza_finger.prc`

**Parámetros:**

```sql
V_ID_ANO            in number
V_ID_FUNCIONARIO    in number
V_ID_TIPO_PERMISO   in varchar2
V_FECHA_INICIO      in DATE
V_FECHA_FIN         in DATE
v_codpers           in varchar2
V_ID_ESTADO_PERMISO in number
todo_ok_Basico      out integer
msgBasico           out varchar2
```

**Operaciones SQL:** SELECT, UPDATE

---

### ACTUALIZA_PERSONAL_SAVIA

**Tipo:** PROCEDURE

**Propósito:** Actualización de datos

**Archivo:** `actualiza_personal_savia.prc`

**Parámetros:**

```sql
v_codienti           in varchar2
--1
                                                     v_versempl           in varchar2
--2
                                                     v_id_funcionario     in varchar2
--3                                                     
                                                     v_categoria          in varchar2
--4
                                                     v_puesto             in varchar2
--5
                                                     v_fecha_nacimiento    in varchar2
--6
                                                     v_tipo_funcionario2   in varchar2
--7                                                     
                                                     v_nombre             in varchar2
--8
                                                     v_ape1               in varchar2
--9
                                                     v_ape2               in varchar2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### ANULA_FICHAJE_FINGER_15000

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `anula_fichaje_finger_15000.prc`

**Parámetros:**

```sql
V_ID_ANO           IN  NUMBER
V_ID_FUNCIONARIO   IN  NUMBER
V_FECHA_INICIO     IN  DATE
V_HORA_INICIO      IN  VARCHAR2
V_HORA_FIN         IN  VARCHAR2
v_codpers          IN  VARCHAR2
v_total_horas      IN  VARCHAR2
V_ID_TIPO_PERMISO  IN  VARCHAR2
todo_ok_Basico     OUT INTEGER
msgBasico          OUT VARCHAR2
```

**Operaciones SQL:** DELETE, SELECT

**Llamado por:**

- `AUSENCIAS_ANULA_USUARIO` (PROCEDURE)
- `AUSENCIAS_EDITA_RRHH` (PROCEDURE)
- `PERMISOS_ANULA_USUARIO` (PROCEDURE)
- `PERMISOS_EDITA_RRHH_NEW` (PROCEDURE)

---

### AUSENCIAS_ALTA_RRHH

**Tipo:** PROCEDURE

**Propósito:** Gestión de ausencias

**Archivo:** `ausencias_alta_rrhh.prc`

**Parámetros:**

```sql
V_ID_ANO          IN NUMBER
V_ID_FUNCIONARIO  IN NUMBER
V_ID_TIPO_AUSENCIA IN VARCHAR2
V_FECHA_INICIO    IN DATE
V_FECHA_FIN       IN DATE
V_HORA_INICIO     IN VARCHAR2
V_HORA_FIN        IN VARCHAR2
V_JUSTIFICACION   IN VARCHAR2
V_TOTAL_HORAS     IN NUMBER
V_IP              IN VARCHAR2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### AUSENCIAS_ANULA_USUARIO

**Tipo:** PROCEDURE

**Propósito:** Gestión de ausencias

**Archivo:** `ausencias_anula_usuario.prc`

**Parámetros:**

```sql
V_ID_AUSENCIA    IN NUMBER
V_ID_FUNCIONARIO IN NUMBER
todo_ok_Basico   OUT INTEGER
msgBasico        OUT VARCHAR2
```

**Operaciones SQL:** SELECT, UPDATE

**Llama a:**

- `ANULA_FICHAJE_FINGER_15000` (PROCEDURE)

---

### AUSENCIAS_EDITA_RRHH

**Tipo:** PROCEDURE

**Propósito:** Gestión de ausencias

**Archivo:** `ausencias_edita_rrhh.prc`

**Parámetros:**

```sql
V_ID_AUSENCIA      IN NUMBER
V_ID_ANO           IN NUMBER
V_ID_FUNCIONARIO   IN NUMBER
V_ID_TIPO_AUSENCIA IN VARCHAR2
V_FECHA_INICIO     IN DATE
V_FECHA_FIN        IN DATE
V_HORA_INICIO      IN VARCHAR2
V_HORA_FIN         IN VARCHAR2
V_JUSTIFICACION    IN VARCHAR2
V_TOTAL_HORAS      IN NUMBER
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

**Llama a:**

- `ANULA_FICHAJE_FINGER_15000` (PROCEDURE)

---

### AUSENCIAS_NEW

**Tipo:** PROCEDURE

**Propósito:** Gestión de ausencias

**Archivo:** `ausencias_new.prc`

**Parámetros:**

```sql
V_ID_ANO               IN OUT NUMBER
V_ID_FUNCIONARIO       IN NUMBER
V_ID_TIPO_FUNCIONARIO2 OUT VARCHAR2
V_ID_TIPO_AUSENCIA     IN VARCHAR2
V_ID_ESTADO_AUSENCIA   IN VARCHAR2
V_FECHA_INICIO         IN DATE
V_FECHA_FIN            IN OUT DATE
V_HORA_INICIO          IN OUT VARCHAR2
V_HORA_FIN             IN OUT VARCHAR2
V_JUSTIFICACION        IN VARCHAR2
```

**Operaciones SQL:** SELECT

**Llama a:**

- `CHEQUEO_HSINDICAL` (PROCEDURE)

---

### AVISO_LEGAL_FUNCIONARIOS

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `aviso_legal_funcionarios.prc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO in number
```

**Operaciones SQL:** INSERT

---

### A_ACTUALIZAR_REFENCIA_CATASTRAL

**Tipo:** PROCEDURE

**Propósito:** Actualización de datos

**Archivo:** `a_actualizar_refencia_catastral.prc`

**Operaciones SQL:** INSERT, SELECT

---

### A_BUSCAR_REFENCIA_CATASTRAL

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `a_buscar_refencia_catastral.prc`

**Operaciones SQL:** INSERT, SELECT

---

### A_REFENCIA_CATASTRAL

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `a_refencia_catastral.prc`

**Operaciones SQL:** INSERT, SELECT

---

### BOMBEROS_GUARDIA_P

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `bomberos_guardia_p.prc`

**Operaciones SQL:** DELETE, INSERT, SELECT

---

### CALCULA_PERMISOS_LOS_ANIOS

**Tipo:** PROCEDURE

**Propósito:** Cálculo de valores

**Archivo:** `calcula_permisos_los_anios.prc`

**Descripción:**

> PROCEDURE: CALCULA_PERMISOS_LOS_ANIOS
> Propósito: Calcular y asignar permisos anuales a funcionarios
> Autor: RRHH / Optimizado por Carlos (04/12/2025)
> Versión: 2.0.0
> Descripción:
> Calcula automáticamente los permisos que corresponden a cada funcionario
> para un año específico basándose en:
> - Antigüedad del funcionario
> - Tipo de funcionario (bomberos, policías, administrativos)
> - Tipo de contratación (funcionario, laboral)

**Parámetros:**

```sql
V_ID_FUNCIONARIO IN NUMBER
V_ID_ANO         IN VARCHAR
```

**Operaciones SQL:** INSERT, SELECT

---

### CAMBIA_FIRMA

**Tipo:** PROCEDURE

**Propósito:** Actualización de datos

**Archivo:** `cambia_firma.prc`

**Parámetros:**

```sql
V_ID_CAMBIA_FIRMA in varchar2
V_ID_FUNCIONARIO_FIRMA_ANT in number
V_ID_FUNCIONARIO_FIRMA_NEW in number
V_ID_FUNCIONARIO in number
V_UNICO in  VARCHAR2
-- 1 PARA TODOS
0 SOLO PARA UN FUNCIONARIO
        V_DELEGA in  VARCHAR2
todo_ok_Basico out integer
msgBasico out varchar2
```

**Operaciones SQL:** INSERT, UPDATE

---

### CAMBIA_FIRMA_TELETRABAJO

**Tipo:** PROCEDURE

**Propósito:** Actualización de datos

**Archivo:** `cambia_firma_teletrabajo.prc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO in number
```

**Operaciones SQL:** SELECT, UPDATE

---

### CARGA_ATM_FICHERO

**Tipo:** PROCEDURE

**Propósito:** Carga de datos

**Archivo:** `carga_atm_fichero.prc`

**Parámetros:**

```sql
p_nombre_fichero    IN VARCHAR2
p_usuario_windows   IN VARCHAR2
p_fichero_zip       IN BLOB
p_tipo_facturacion  IN VARCHAR2
p_tipo_deuda        IN VARCHAR2
p_id_out            OUT NUMBER
```

**Operaciones SQL:** DELETE, INSERT, SELECT

---

### CARGA_ATM_FICHERO_INGRESOS

**Tipo:** PROCEDURE

**Propósito:** Carga de datos

**Archivo:** `carga_atm_fichero_ingresos.prc`

**Parámetros:**

```sql
p_id_descarga        IN  ATM_FICHERO_INGRESOS.id_descarga%TYPE
p_nombre_archivo     IN  ATM_FICHERO_INGRESOS.nombre_archivo%TYPE
p_tipo_archivo       IN  ATM_FICHERO_INGRESOS.tipo_archivo%TYPE
p_contenido_blob     IN  ATM_FICHERO_INGRESOS.contenido_blob%TYPE
p_identificador      IN  ATM_FICHERO_INGRESOS.identificador_fichero%TYPE
p_ejercicio          IN  ATM_FICHERO_INGRESOS.ejercicio%TYPE
p_entidad            IN  ATM_FICHERO_INGRESOS.entidad%TYPE
p_codigo             IN  ATM_FICHERO_INGRESOS.codigo%TYPE
p_tipo_deuda         IN  ATM_FICHERO_INGRESOS.tipo_deuda%TYPE
p_tipo_fact_contab   IN  ATM_FICHERO_INGRESOS.tipo_facturacion_contabilidad%TYPE
```

**Operaciones SQL:** INSERT, SELECT

---

### CHEQUEA_DA_FINAL

**Tipo:** PROCEDURE

**Propósito:** Validación o verificación

**Archivo:** `chequea_da_final.prc`

**Operaciones SQL:** DELETE, INSERT, SELECT, UPDATE

**Llama a:**

- `VALIDANIF` (FUNCTION)

---

### CHEQUEA_DA_FINAL_FALTAN

**Tipo:** PROCEDURE

**Propósito:** Validación o verificación

**Archivo:** `chequea_da_final_faltan.prc`

**Operaciones SQL:** INSERT, SELECT, UPDATE

**Llama a:**

- `VALIDANIF` (FUNCTION)

---

### CHEQUEA_FUNCIONARIO_DIARIO

**Tipo:** PROCEDURE

**Propósito:** Validación o verificación

**Archivo:** `chequea_funcionario_diario.prc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO in varchar2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### CHEQUEA_FUNCIONARIO_DIARIO_SOLO_1

**Tipo:** PROCEDURE

**Propósito:** Validación o verificación

**Archivo:** `chequea_funcionario_diario_solo_1.prc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO in varchar2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### CHEQUEO_BASICO_NEW

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `chequeo_basico_new.prc`

**Parámetros:**

```sql
V_ID_ANO in number
V_ID_FUNCIONARIO in number
V_ID_TIPO_FUNCIONARIO in number
V_ID_TIPO_PERMISO in varchar2
V_ID_TIPO_DIAS in out VARCHAR2
V_FECHA_INICIO in DATE
V_FECHA_FIN in out DATE
V_HORA_INICIO  in varchar2
V_HORA_FIN  in varchar2
V_UNICO in varchar2
```

**Operaciones SQL:** SELECT

---

### CHEQUEO_BOLSA_CONCILIA

**Tipo:** PROCEDURE

**Propósito:** Gestión de bolsa de horas

**Archivo:** `chequeo_bolsa_concilia.prc`

**Parámetros:**

```sql
V_ID_ANO in number
V_ID_FUNCIONARIO in number
V_FECHA_INICIO in DATE
V_FECHA_FIN in DATE
V_HORA_INICIO  in varchar2
V_HORA_FIN  in varchar2
V_TOTAL_HORAS out number
todo_ok_Basico out integer
msgBasico out varchar2
```

**Operaciones SQL:** UPDATE

---

### CHEQUEO_COMPENSATORIO

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `chequeo_compensatorio.prc`

**Parámetros:**

```sql
V_ID_ANO in number
V_ID_FUNCIONARIO in number
V_FECHA_INICIO in DATE
V_FECHA_FIN in DATE
V_HORA_INICIO  in varchar2
V_HORA_FIN  in varchar2
V_TOTAL_HORAS out number
todo_ok_Basico out integer
msgBasico out varchar2
```

**Operaciones SQL:** UPDATE

---

### CHEQUEO_HSINDICAL

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `chequeo_hsindical.prc`

**Parámetros:**

```sql
V_ID_ANO in number
V_ID_FUNCIONARIO in number
V_ID_TIPO_FUNCIONARIO in number
V_ID_TIPO_AUSENCIA in varchar2
V_FECHA_INICIO in DATE
V_FECHA_FIN in DATE
V_HORA_INICIO  in varchar2
V_HORA_FIN  in varchar2
v_total_horas in number
todo_ok_Basico out integer
```

**Operaciones SQL:** SELECT

**Llamado por:**

- `AUSENCIAS_NEW` (PROCEDURE)

---

### CHEQUEO_VACACIONES_BOMBEROS

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `chequeo_vacaciones_bomberos.prc`

**Parámetros:**

```sql
V_ID_ANO in number
V_ID_FUNCIONARIO in number
V_ID_TIPO_FUNCIONARIO in number
V_ID_TIPO_PERMISO in varchar2
V_ID_TIPO_DIAS in out VARCHAR2
V_FECHA_INICIO in date
V_FECHA_FIN in date
V_NUM_DIAS in out  number
V_GUARDIAS OUT varchar2
todo_ok_Basico out integer
```

**Operaciones SQL:** SELECT

---

### CHEQUEO_VACACIONES_NEW

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `chequeo_vacaciones_new.prc`

**Parámetros:**

```sql
V_ID_ANO in number
V_ID_FUNCIONARIO in number
V_ID_TIPO_FUNCIONARIO in number
V_ID_TIPO_PERMISO in varchar2
V_ID_TIPO_DIAS in out VARCHAR2
V_FECHA_INICIO in date
V_FECHA_FIN in date
V_NUM_DIAS in number
todo_ok_Basico out integer
msgBasico out varchar2
```

**Operaciones SQL:** SELECT

---

### ENVIA_CORREO_INFORMA

**Tipo:** PROCEDURE

**Propósito:** Envío de notificaciones

**Archivo:** `envia_correo_informa.prc`

**Parámetros:**

```sql
V_TIPO_PETICION  in number
V_ID_TIPO_PERMISO in varchar2
V_nombre_peticion  in  varchar2
V_DES_TIPo_PERMISO_larga in  varchar2
v_id_motivo  in  varchar2
V_FECHA_INICIO in DATE
V_FECHA_FIN in DATE
V_HORA_INICIO  in varchar2
V_HORA_FIN  in varchar2
V_ID_GRADO in varchar2
```

**Operaciones SQL:** SELECT

---

### ENVIA_CORREO_INFORMA_NEW

**Tipo:** PROCEDURE

**Propósito:** Envío de notificaciones

**Archivo:** `envia_correo_informa_new.prc`

**Parámetros:**

```sql
V_TIPO_PETICION  in number
V_ID_TIPO_PERMISO in varchar2
V_nombre_peticion  in  varchar2
V_DES_TIPo_PERMISO_larga in  varchar2
v_id_motivo  in  varchar2
V_FECHA_INICIO in DATE
V_FECHA_FIN in DATE
V_HORA_INICIO  in varchar2
V_HORA_FIN  in varchar2
V_ID_GRADO in varchar2
```

**Operaciones SQL:** SELECT

---

### ENVIO_CORREO

**Tipo:** PROCEDURE

**Propósito:** Envío de notificaciones

**Archivo:** `envio_correo.prc`

**Parámetros:**

```sql
sender IN VARCHAR2
recipient IN VARCHAR2
ccrecipient IN VARCHAR2
subject IN VARCHAR2
message IN VARCHAR2
```

---

### ENVIO_CORREO_REAL

**Tipo:** PROCEDURE

**Propósito:** Envío de notificaciones

**Archivo:** `envio_correo_real.prc`

**Parámetros:**

```sql
sender IN VARCHAR2
recipient IN VARCHAR2
ccrecipient IN VARCHAR2
subject IN VARCHAR2
message IN VARCHAR2
```

---

### EXPE_ACTUA_TRANSCURRIDO

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `expe_actua_transcurrido.prc`

**Parámetros:**

```sql
V_ID_INDICADOR  in varchar2
V_TIPO_REGISTRO in varchar2
```

**Operaciones SQL:** UPDATE

---

### EXPE_ACTUA_TRANSCURRIDO_TODO

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `expe_actua_transcurrido_todo.prc`

**Operaciones SQL:** UPDATE

---

### FICHAJE_CALCULA_SALDO_REGE

**Tipo:** PROCEDURE

**Propósito:** Cálculo de valores

**Archivo:** `fichaje_calcula_saldo_rege.prc`

**Parámetros:**

```sql
V_ID_PRIMER_FICHAJE in varchar2
V_ID_SEGUNDO_FICHAJE in varchar2
V_ID_FUNCIONARIO in number
V_ID_TIPO_FUNCIONARIO number
v_pin     in number
msgsalida out varchar2
todook out varchar2
```

**Operaciones SQL:** INSERT, SELECT

---

### FICHAJE_CALCULA_SALDO_REGE_ANT

**Tipo:** PROCEDURE

**Propósito:** Cálculo de valores

**Archivo:** `fichaje_calcula_saldo_rege_ant.prc`

**Parámetros:**

```sql
V_ID_PRIMER_FICHAJE in varchar2
V_ID_SEGUNDO_FICHAJE in varchar2
V_ID_FUNCIONARIO in number
v_codpers     in number
msgsalida out varchar2
todook out varchar2
primero_f in number
```

**Operaciones SQL:** INSERT, SELECT

---

### FICHAJE_CHEQUEA_HEXTRAS

**Tipo:** PROCEDURE

**Propósito:** Validación o verificación

**Archivo:** `fichaje_chequea_hextras.prc`

**Parámetros:**

```sql
I_FUNCIONARIO in varchar2
i_clave in varchar2
i_operacion in varchar2
i_lista_no_actualiza in out varchar2
i_tipo_horas in varchar2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### FICHAJE_CHEQUEA_HEXTRAS_TRAN

**Tipo:** PROCEDURE

**Propósito:** Validación o verificación

**Archivo:** `fichaje_chequea_hextras_tran.prc`

**Parámetros:**

```sql
I_PIN in varchar2
i_fecha_p in date
i_fichaje in varchar2
i_clave in varchar2
i_operacion in varchar2
```

**Operaciones SQL:** DELETE, INSERT, SELECT, UPDATE

---

### FICHAJE_GUARDA_CALENDARIO

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `fichaje_guarda_calendario.prc`

**Parámetros:**

```sql
V_ID_CALENDARIO in number
V_DESC_CALENDARIO in varchar2
v_audit_usuario in varchar2
V_TURNO in varchar2
v_horas_semanales in number
V_ID_TODO in varchar2
msgsalida out varchar2
todook out varchar2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### FICHAJE_GUARDA_CONFIGURACION

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `fichaje_guarda_configuracion.prc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO in number
V_RELOJ_FICHAJE in varchar2
V_CAMPO_ALERT in varchar2
V_CAMPO_JORNADA in varchar2
V_CAMPO_PTO_FICHAJE in varchar2
V_CAMPO_CALENDARIO in varchar2
v_audit_usuario in varchar2
msgsalida out varchar2
todook out varchar2
```

**Operaciones SQL:** DELETE, INSERT, SELECT, UPDATE

**Llama a:**

- `FINGER_JORNADA_SOLAPA` (FUNCTION)

---

### FICHAJE_INSERTA_HEXTRAS

**Tipo:** PROCEDURE

**Propósito:** Inserción de datos

**Archivo:** `fichaje_inserta_hextras.prc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO in number
V_ID_ANO in number
V_ID_TIPO_OPERACION in  varchar2
--1 ALTA -- 0 BAJA -2 ACTUALZACION
          v_ID_TIPO_HORAS in number
--FACTOR
          V_ID_TRP_NOMINA in out varchar2
V_FECHA_HORAS in DATE
V_HORA_INICIO  in varchar2
V_HORA_FIN  in varchar2
v_phe IN out VARCHAR2
--FICHAJE
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

**Llama a:**

- `FICHAJE_INSERTA_TRAN_HEXTRAS` (PROCEDURE)

---

### FICHAJE_INSERTA_TRAN_HEXTRAS

**Tipo:** PROCEDURE

**Propósito:** Inserción de datos

**Archivo:** `fichaje_inserta_tran_hextras.prc`

**Parámetros:**

```sql
I_FUNCIONARIO in varchar2
V_PHE in out number
v_Fechas_horas in date
v_hora_inicio in varchar2
v_hora_fin in varchar2
TRP_NOMINA in number
```

**Operaciones SQL:** SELECT, UPDATE

**Llamado por:**

- `FICHAJE_INSERTA_HEXTRAS` (PROCEDURE)

---

### FICHAJE_POR_INTRANET

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `fichaje_por_intranet.prc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO in number
id_teletrajo in number
msgsalida out varchar2
todook out varchar2
n_fichaje out varchar2
```

**Operaciones SQL:** INSERT, SELECT

---

### FINGER_BUSCA_JORNADA_FUN

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_busca_jornada_fun.prc`

**Parámetros:**

```sql
i_id_funcionario     IN     VARCHAR2
v_fecha_p            IN     DATE
v_p1d                IN OUT NUMBER
v_p1h                IN OUT NUMBER
v_p2d                IN OUT NUMBER
v_p2h                IN OUT NUMBER
v_p3d                IN OUT NUMBER
v_p3h                IN OUT NUMBER
v_po1d               IN OUT NUMBER
v_po1h               IN OUT NUMBER
```

**Operaciones SQL:** SELECT

---

### FINGER_CALCULA_SALDO

**Tipo:** PROCEDURE

**Propósito:** Cálculo de valores

**Archivo:** `finger_calcula_saldo.prc`

**Parámetros:**

```sql
i_funcionario   in varchar2
v_fecha_p in date
```

**Operaciones SQL:** DELETE, INSERT, SELECT

---

### FINGER_CALCULA_SALDO_HIST

**Tipo:** PROCEDURE

**Propósito:** Cálculo de valores

**Archivo:** `finger_calcula_saldo_hist.prc`

**Parámetros:**

```sql
i_funcionario   in varchar2
v_fecha_p in date
```

**Operaciones SQL:** DELETE, INSERT, SELECT

---

### FINGER_CALCULA_SALDO_NEW

**Tipo:** PROCEDURE

**Propósito:** Cálculo de valores

**Archivo:** `finger_calcula_saldo_new.prc`

**Parámetros:**

```sql
i_funcionario   in varchar2
v_fecha_p in date
```

**Operaciones SQL:** DELETE, INSERT, SELECT

---

### FINGER_CALCULA_SALDO_POLICIA

**Tipo:** PROCEDURE

**Propósito:** Cálculo de valores

**Archivo:** `finger_calcula_saldo_policia.prc`

**Parámetros:**

```sql
i_funcionario   in varchar2
v_fecha_p in date
```

**Operaciones SQL:** DELETE, INSERT, SELECT

---

### FINGER_CALCULA_SALDO_RESUMEN

**Tipo:** PROCEDURE

**Propósito:** Cálculo de valores

**Archivo:** `finger_calcula_saldo_resumen.prc`

**Parámetros:**

```sql
i_funcionario in varchar2
v_fecha_p     in date
```

**Operaciones SQL:** INSERT, SELECT

**Llama a:**

- `PERMISO_EN_DIA` (FUNCTION)

---

### FINGER_GENERA_INFORME

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_genera_informe.prc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO in number
V_ID_INFORME in varchar2
```

**Operaciones SQL:** DELETE, INSERT, SELECT, UPDATE

---

### FINGER_LEE_TRANS

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_lee_trans.prc`

**Parámetros:**

```sql
i_pin     IN VARCHAR2
v_fecha_p IN DATE
```

**Operaciones SQL:** DELETE, INSERT, SELECT

---

### FINGER_LEE_TRANS_HIST

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_lee_trans_hist.prc`

**Operaciones SQL:** INSERT, SELECT

---

### FINGER_LIMPIA_TRANS

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_limpia_trans.prc`

**Parámetros:**

```sql
i_funcionario IN VARCHAR2
v_fecha_p     IN DATE
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### FINGER_LIMPIA_TRANS0

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_limpia_trans0.prc`

**Parámetros:**

```sql
i_funcionario IN VARCHAR2
v_fecha_p     IN DATE
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### FINGER_PLANIFICA_INFORME

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_planifica_informe.prc`

**Parámetros:**

```sql
v_id_funcionario IN NUMBER
v_campos_informe IN VARCHAR2
```

**Operaciones SQL:** INSERT

---

### FINGER_PROCESA_TRANSACCIONES

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_procesa_transacciones.prc`

**Parámetros:**

```sql
i_id_funcionario        IN     VARCHAR2
v_fecha_p               IN     VARCHAR2
i_cadena_fichaje        IN     VARCHAR2
i_cadena_computa        IN     VARCHAR2
i_cadena_observaciones  OUT    VARCHAR2
```

**Operaciones SQL:** SELECT

---

### FINGER_REGENERA_INCIDENCIAS

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_regenera_incidencias.prc`

**Parámetros:**

```sql
i_id_incidencia IN VARCHAR2
i_todos         IN VARCHAR2
```

**Operaciones SQL:** SELECT

---

### FINGER_REGENERA_SALDO

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_regenera_saldo.prc`

**Parámetros:**

```sql
v_id_funcionario IN VARCHAR2
v_periodo        IN VARCHAR2
v_tipo_funci     IN NUMBER
```

**Operaciones SQL:** SELECT

---

### FINGER_REGENERA_SALDO_AÑO

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_regenera_saldo_año.prc`

**Parámetros:**

```sql
v_id_funcionario IN VARCHAR2
v_periodo        IN VARCHAR2
v_tipo_funci     IN NUMBER
```

**Operaciones SQL:** SELECT

---

### FINGER_REGENERA_SALDO_DIARIO

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_regenera_saldo_diario.prc`

**Parámetros:**

```sql
v_id_funcionario IN VARCHAR2
v_tipo_funci     IN NUMBER
i_ayer           IN NUMBER
```

**Operaciones SQL:** DELETE, INSERT, SELECT

---

### FINGER_REGENERA_SALDO_HIST

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_regenera_saldo_hist.prc`

**Parámetros:**

```sql
v_id_funcionario IN VARCHAR2
v_periodo        IN VARCHAR2
v_tipo_funci     IN NUMBER
```

**Operaciones SQL:** SELECT

---

### FINGER_REGENERA_SALDO_LISTA

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_regenera_saldo_lista.prc`

**Parámetros:**

```sql
v_id_funcionario IN VARCHAR2
v_periodo        IN VARCHAR2
v_tipo_funci     IN NUMBER
```

**Operaciones SQL:** SELECT

---

### FINGER_REGENERA_SALDO_UN_DIA

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `finger_regenera_saldo_un_dia.prc`

**Parámetros:**

```sql
v_id_funcionario IN VARCHAR2
v_tipo_funci     IN NUMBER
v_ayer           IN VARCHAR2
```

**Operaciones SQL:** DELETE, INSERT, SELECT

---

### FINGER_RELOJES_CHEQUEA

**Tipo:** PROCEDURE

**Propósito:** Validación o verificación

**Archivo:** `finger_relojes_chequea.prc`

**Operaciones SQL:** DELETE, INSERT, SELECT

---

### FIRMA_AUSENCIA_JSA

**Tipo:** PROCEDURE

**Propósito:** Proceso de aprobación y firma

**Archivo:** `firma_ausencia_jsa.prc`

**Parámetros:**

```sql
V_ID_FIRMA             IN VARCHAR2
V_ID_FUNCIONARIO_FIRMA IN NUMBER
V_ID_AUSENCIA          IN NUMBER
V_ID_MOTIVO            IN VARCHAR2
todo_ok_Basico         OUT INTEGER
msgBasico              OUT VARCHAR2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### FIRMA_JSA_VARIOS

**Tipo:** PROCEDURE

**Propósito:** Proceso de aprobación y firma

**Archivo:** `firma_jsa_varios.prc`

**Parámetros:**

```sql
V_ID_TIPO_PERMISO in varchar2
V_ID_FUNCIONARIO_FIRMA in varchar2
V_ID_TODOS_PERMISOS in varchar2
V_ID_TIPO_FIRMA   in varchar2
V_ID_MOTIVO_DENIEGA   in varchar2
V_CLAVE_FIRMA in varchar2
```

**Operaciones SQL:** INSERT

---

### FIRMA_JSA_VARIOS_WEBS

**Tipo:** PROCEDURE

**Propósito:** Proceso de aprobación y firma

**Archivo:** `firma_jsa_varios_webs.prc`

**Parámetros:**

```sql
V_ID_TIPO_PERMISO in varchar2
V_ID_FUNCIONARIO_FIRMA in varchar2
V_ID_TODOS_PERMISOS in varchar2
V_ID_TIPO_FIRMA   in varchar2
V_ID_MOTIVO_DENIEGA   in varchar2
V_CLAVE_FIRMA in varchar2
v_observaciones in out varchar2
V_operacion_ok out  varchar2
```

**Operaciones SQL:** INSERT

---

### FIRMA_PERMISO_JSA_NEW

**Tipo:** PROCEDURE

**Propósito:** Proceso de aprobación y firma

**Archivo:** `firma_permiso_jsa_new.prc`

**Descripción:**

> PROCEDURE: FIRMA_PERMISO_JSA_NEW
> Propósito: Procesar firma de permiso por Jefe de Sección (JS) o Jefe de Área (JA)
> Autor: RRHH / Optimizado por Carlos (04/12/2025)
> Versión: 2.0.0
> Descripción:
> Gestiona las firmas de autorización o denegación de permisos por parte
> de los responsables jerárquicos (JS/JA).
> Funcionalidades principales:
> - Validación de permisos existentes y estado correcto
> - Verificación de jerarquía de firmas (titular/delegados)

**Parámetros:**

```sql
V_ID_FIRMA             IN VARCHAR2
V_ID_FUNCIONARIO_FIRMA IN NUMBER
V_ID_PERMISO           IN NUMBER
V_ID_MOTIVO            IN VARCHAR2
todo_ok_Basico         OUT INTEGER
msgBasico              OUT VARCHAR2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### HORAS_SINDICALES

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `horas_sindicales.prc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO in number
ID_FUNCIONARIO_NOMBRE in varchar2
V_ID_TIPO_AUSENCIA in varchar2
V_ID_SINDICATO in varchar2
V_ID_HORAS_SINDICALES in varchar2
V_ID_ANO in number
msgsalida out varchar2
todook out varchar2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### INSERTA_AUSENCIAS

**Tipo:** PROCEDURE

**Propósito:** Inserción de datos

**Archivo:** `inserta_ausencias.prc`

**Parámetros:**

```sql
V_ID_ANO              IN NUMBER
V_ID_FUNCIONARIO      IN NUMBER
V_ID_TIPO_FUNCIONARIO IN VARCHAR2
V_ID_TIPO_AUSENCIA    IN VARCHAR2
V_FECHA_INICIO        IN DATE
V_FECHA_FIN           IN DATE
V_HORA_INICIO         IN VARCHAR2
V_HORA_FIN            IN VARCHAR2
V_JUSTIFICACION       IN VARCHAR2
V_TOTAL_HORAS         IN NUMBER
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### INSERTA_AUSENCIAS_RRHH

**Tipo:** PROCEDURE

**Propósito:** Inserción de datos

**Archivo:** `inserta_ausencias_rrhh.prc`

**Parámetros:**

```sql
V_ID_ANO            IN NUMBER
V_ID_FUNCIONARIO    IN NUMBER
V_ID_TIPO_FUNCIONARIO IN NUMBER
V_ID_TIPO_AUSENCIA  IN VARCHAR2
V_FECHA_INICIO      IN DATE
V_FECHA_FIN         IN DATE
V_HORA_INICIO       IN VARCHAR2
V_HORA_FIN          IN VARCHAR2
V_JUSTIFICACION     IN VARCHAR2
V_OBSERVACIONES     IN VARCHAR2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### INSERTA_HISTORICO

**Tipo:** PROCEDURE

**Propósito:** Inserción de datos

**Archivo:** `inserta_historico.prc`

**Parámetros:**

```sql
V_ID_ANO in number
V_ID_FUNCIONARIO in number
V_ID_TIPO_FUNCIONARIO in number
V_ID_TIPO_PERMISO in varchar2
V_ID_TIPO_DIAS in out VARCHAR2
V_FECHA_INICIO in DATE
V_FECHA_FIN in DATE
V_HORA_INICIO  in varchar2
V_HORA_FIN  in varchar2
V_UNICO in varchar2
```

**Operaciones SQL:** INSERT, SELECT

---

### INSERTA_PERMISO_NEW

**Tipo:** PROCEDURE

**Propósito:** Inserción de datos

**Archivo:** `inserta_permiso_new.prc`

**Descripción:**

> PROCEDURE: INSERTA_PERMISO_NEW
> Propósito: Insertar solicitud de permiso del funcionario (usuario final)
> Autor: RRHH / Optimizado por Carlos (04/12/2025)
> Versión: 2.0.0
> Descripción:
> Inserta nueva solicitud de permiso iniciada por el funcionario.
> El permiso queda en estado SOLICITADO (10) o PENDIENTE FIRMA (20/21/22)
> según la jerarquía de firmas configurada.
> Funcionalidades especiales:
> - Gestión de firmas para funcionarios normales (JS → JA → RRHH)

**Parámetros:**

```sql
V_ID_ANO IN NUMBER
V_ID_FUNCIONARIO IN NUMBER
V_ID_TIPO_FUNCIONARIO IN NUMBER
V_ID_TIPO_PERMISO IN VARCHAR2
V_ID_TIPO_DIAS IN OUT VARCHAR2
V_FECHA_INICIO IN DATE
V_FECHA_FIN IN DATE
V_HORA_INICIO IN VARCHAR2
V_HORA_FIN IN VARCHAR2
V_UNICO IN OUT VARCHAR2
```

**Operaciones SQL:** INSERT, SELECT

---

### INSERTA_PERMISO_RRHH

**Tipo:** PROCEDURE

**Propósito:** Inserción de datos

**Archivo:** `inserta_permiso_rrhh.prc`

**Descripción:**

> PROCEDURE: INSERTA_PERMISO_RRHH
> Propósito: Insertar permiso concedido directamente por RRHH (versión legacy)
> Autor: RRHH / Optimizado por Carlos (04/12/2025)
> Versión: 2.0.0
> Descripción:
> Inserta un nuevo permiso con estado CONCEDIDO (80) directamente.
> El permiso ya está aprobado por JS, JA y RRHH desde el inicio.
> Usado para altas manuales de permisos retroactivos o especiales.
> Nota: Versión legacy. Para nuevas implementaciones usar INSERTA_PERMISO_RRHH_NEW
> que soporta turnos de bomberos y descuentos de bolsa.

**Parámetros:**

```sql
V_ID_USUARIO IN VARCHAR2
V_ID_ANO IN NUMBER
V_ID_FUNCIONARIO IN NUMBER
V_ID_TIPO_FUNCIONARIO IN NUMBER
V_ID_TIPO_PERMISO IN VARCHAR2
V_ID_TIPO_DIAS IN OUT VARCHAR2
V_FECHA_INICIO IN DATE
V_FECHA_FIN IN DATE
V_HORA_INICIO IN VARCHAR2
V_HORA_FIN IN VARCHAR2
```

**Operaciones SQL:** INSERT, SELECT

---

### INSERTA_PERMISO_RRHH_NEW

**Tipo:** PROCEDURE

**Propósito:** Inserción de datos

**Archivo:** `inserta_permiso_rrhh_new.prc`

**Descripción:**

> PROCEDURE: INSERTA_PERMISO_RRHH_NEW
> Propósito: Insertar permiso concedido directamente por RRHH (versión mejorada)
> Autor: RRHH / Optimizado por Carlos (04/12/2025)
> Versión: 2.0.0
> Descripción:
> Versión mejorada de INSERTA_PERMISO_RRHH con soporte para:
> - Turnos de bomberos (T1, T2, T3)
> - Descuento a bolsa por baja (bajas 11300)
> - Tipo de baja (campo adicional para clasificación)
> - Validación de usuario (usar 101235 si es NULL)

**Parámetros:**

```sql
V_ID_USUARIO IN OUT VARCHAR2
V_ID_ANO IN NUMBER
V_ID_FUNCIONARIO IN NUMBER
V_ID_TIPO_FUNCIONARIO IN NUMBER
V_ID_TIPO_PERMISO IN VARCHAR2
V_ID_TIPO_DIAS IN OUT VARCHAR2
V_FECHA_INICIO IN DATE
V_FECHA_FIN IN DATE
V_HORA_INICIO IN VARCHAR2
V_HORA_FIN IN VARCHAR2
```

**Operaciones SQL:** INSERT, SELECT

---

### INSERTA_PERSONA_BOMBEROS_FINGER

**Tipo:** PROCEDURE

**Propósito:** Inserción de datos

**Archivo:** `inserta_persona_bomberos_finger.prc`

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### LDAP_CONNECT

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `ldap_connect.prc`

**Parámetros:**

```sql
p_sFiltro VARCHAR2
```

**Llama a:**

- `GET_USERS` (FUNCTION)

---

### METE_FICHAJE_FINGER_NEW

**Tipo:** PROCEDURE

**Propósito:** Gestión de fichajes y control de asistencia

**Archivo:** `mete_fichaje_finger_new.prc`

**Parámetros:**

```sql
V_ID_ANO           IN  NUMBER
V_ID_FUNCIONARIO   IN  NUMBER
V_FECHA_INICIO     IN  DATE
V_HORA_INICIO      IN  VARCHAR2
V_HORA_FIN         IN  VARCHAR2
v_codpers          IN  VARCHAR2
v_total_horas      IN  VARCHAR2
V_ID_TIPO_PERMISO  IN  VARCHAR2
todo_ok_Basico     OUT INTEGER
msgBasico          OUT VARCHAR2
```

**Operaciones SQL:** INSERT, SELECT

---

### MOV_BOLSA_DESCUENTO_ENFERME

**Tipo:** PROCEDURE

**Propósito:** Gestión de bolsa de horas

**Archivo:** `mov_bolsa_descuento_enferme.prc`

**Parámetros:**

```sql
V_ID_ANO in number
V_ID_FUNCIONARIO in number
V_ID_TIPO_FUNCIONARIO in number
V_FECHA_INICIO in date
v_num_dias_tiene_per in number
todo_ok_Basico out integer
msgBasico out varchar2
```

**Operaciones SQL:** INSERT, SELECT

**Llamado por:**

- `PERMISOS_ALTA_RRHH_NEW` (PROCEDURE)
- `PERMISOS_EDITA_RRHH_NEW` (PROCEDURE)

---

### NUMERO_FICHAJE_PERSONA_N

**Tipo:** PROCEDURE

**Propósito:** Operación general del sistema

**Archivo:** `numero_fichaje_persona_n.prc`

**Parámetros:**

```sql
v_codigo out number
pin1 out number
pin2 out number
```

**Operaciones SQL:** SELECT

---

### PERMISOS_ALTA_RRHH_NEW

**Tipo:** PROCEDURE

**Propósito:** Gestión de permisos

**Archivo:** `permisos_alta_rrhh_new.prc`

**Descripción:**

> PROCEDURE: PERMISOS_ALTA_RRHH_NEW
> Propósito: Alta de permisos realizada directamente por RRHH
> Autor: RRHH / Optimizado por Carlos (04/12/2025)
> Versión: 2.0.0
> Descripción:
> Permite a RRHH dar de alta permisos directamente con estado concedido (80).
> Realiza todas las validaciones necesarias, actualiza bolsas de días,
> integra con sistema de fichaje biométrico y envía notificaciones.
> Tipos de permiso soportados:
> 01000 - Vacaciones

**Parámetros:**

```sql
V_ID_ANO IN NUMBER
V_ID_FUNCIONARIO IN NUMBER
V_ID_TIPO_FUNCIONARIO IN OUT VARCHAR2
V_ID_TIPO_PERMISO IN VARCHAR2
V_ID_ESTADO_PERMISO IN VARCHAR2
V_ID_TIPO_DIAS IN VARCHAR2
V_FECHA_INICIO IN DATE
V_FECHA_FIN IN OUT DATE
V_HORA_INICIO IN VARCHAR2
V_HORA_FIN IN VARCHAR2
```

**Operaciones SQL:** SELECT

**Llama a:**

- `ACTUALIZAR_UNICO_NEW` (PROCEDURE)
- `MOV_BOLSA_DESCUENTO_ENFERME` (PROCEDURE)

---

### PERMISOS_ANULA_USUARIO

**Tipo:** PROCEDURE

**Propósito:** Gestión de permisos

**Archivo:** `permisos_anula_usuario.prc`

**Descripción:**

> PROCEDURE: PERMISOS_ANULA_USUARIO
> Propósito: Anular permiso solicitado por el usuario antes de su inicio
> Autor: RRHH / Optimizado por Carlos (04/12/2025)
> Versión: 2.0.0
> Descripción:
> Permite al usuario anular su solicitud de permiso siempre que:
> - El permiso aún no haya comenzado (fecha inicio > fecha actual)
> - El permiso no sea de tipo baja por enfermedad (11100, 11300)
> - El usuario sea el propietario de la solicitud
> Estados de permiso:

**Parámetros:**

```sql
V_ID_PERMISO     IN NUMBER
V_ID_FUNCIONARIO IN VARCHAR2
todo_ok_Basico   OUT INTEGER
msgBasico        OUT VARCHAR2
```

**Operaciones SQL:** SELECT, UPDATE

**Llama a:**

- `ANULA_FICHAJE_FINGER_15000` (PROCEDURE)

---

### PERMISOS_EDITA_RRHH_NEW

**Tipo:** PROCEDURE

**Propósito:** Gestión de permisos

**Archivo:** `permisos_edita_rrhh_new.prc`

**Descripción:**

> PROCEDURE: PERMISOS_EDITA_RRHH_NEW
> Propósito: Editar permisos existentes desde RRHH
> Autor: RRHH / Optimizado por Carlos (04/12/2025)
> Versión: 2.0.0
> Descripción:
> Permite a RRHH modificar permisos ya registrados. Soporta:
> - Cambio de estado: Concedido(80) → Anulado(40)
> - Cambio de estado: Pendiente(20/22) → Anulado(40)
> - Cambio de estado: Concedido(80) → Denegado(32)
> - Modificación de justificación (SI/NO)

**Parámetros:**

```sql
V_OBSERVACIONES IN VARCHAR2
V_ID_PERMISO IN NUMBER
V_ID_ESTADO_PERMISO IN NUMBER
V_JUSTIFICACION IN VARCHAR2
V_ID_USUARIO IN VARCHAR2
todo_ok_Basico OUT INTEGER
msgBasico OUT VARCHAR2
V_FECHA_FIN IN DATE
V_DESCUENTO_BAJAS IN VARCHAR2
V_DESCUENTO_DIAS IN VARCHAR2
```

**Operaciones SQL:** SELECT, UPDATE

**Llama a:**

- `ANULA_FICHAJE_FINGER_15000` (PROCEDURE)
- `DEVUELVE_PERIODO` (FUNCTION)
- `MOV_BOLSA_DESCUENTO_ENFERME` (PROCEDURE)

---

### PERMISOS_NEW

**Tipo:** PROCEDURE

**Propósito:** Gestión de permisos

**Archivo:** `permisos_new.prc`

**Descripción:**

> PROCEDURE: PERMISOS_NEW
> Propósito: Crear nueva solicitud de permiso con validaciones completas
> Autor: RRHH / Optimizado por Carlos (04/12/2025)
> Versión: 2.0.0
> Descripción:
> Procedimiento principal para la creación de permisos de empleados.
> Realiza validaciones exhaustivas según tipo de permiso, funcionario y
> reglas de negocio (vacaciones, compensatorios, turnos, etc.)
> Parámetros:
> V_ID_ANO              - Año del permiso

**Parámetros:**

```sql
V_ID_ANO              IN NUMBER
V_ID_FUNCIONARIO      IN NUMBER
V_ID_TIPO_FUNCIONARIO IN OUT VARCHAR2
V_ID_TIPO_PERMISO     IN VARCHAR2
V_ID_ESTADO_PERMISO   IN VARCHAR2
V_ID_TIPO_DIAS        IN VARCHAR2
V_FECHA_INICIO        IN DATE
V_FECHA_FIN           IN OUT DATE
V_HORA_INICIO         IN OUT VARCHAR2
V_HORA_FIN            IN OUT VARCHAR2
```

**Operaciones SQL:** SELECT

**Llama a:**

- `ACTUALIZAR_UNICO_NEW` (PROCEDURE)

---

### PERMISO_DENEGADO

**Tipo:** PROCEDURE

**Propósito:** Gestión de permisos

**Archivo:** `permiso_denegado.prc`

**Descripción:**

> PROCEDURE: PERMISO_DENEGADO
> Propósito: Revertir cambios en bolsas al denegar/anular un permiso
> Autor: RRHH / Optimizado por Carlos (04/12/2025)
> Versión: 2.0.0
> Descripción:
> Revierte los movimientos en bolsas de días/horas cuando un permiso es:
> - Denegado por RRHH (estado 32)
> - Anulado por RRHH (estado 40)
> - Anulado por Usuario (estado 41)
> Tipos de bolsa afectados:

**Parámetros:**

```sql
V_ID_PERMISO IN NUMBER
todo_ok_Basico OUT INTEGER
msgBasico OUT VARCHAR2
```

**Operaciones SQL:** SELECT, UPDATE

---

### PROCESA_LOTES_ITERACIONES

**Tipo:** PROCEDURE

**Propósito:** Procesamiento por lotes

**Archivo:** `procesa_lotes_iteraciones.prc`

**Parámetros:**

```sql
p_tipo_proceso        IN VARCHAR2
-- Tipo de proceso a ejecutar (permisos, ausencias, fichajes, etc.)
  p_id_lote             IN NUMBER
-- ID del lote a procesar
  p_tamaño_lote         IN NUMBER DEFAULT 100
-- Número de registros por iteración
  p_max_iteraciones     IN NUMBER DEFAULT 1000
-- Máximo de iteraciones permitidas
  p_modo_ejecucion      IN VARCHAR2 DEFAULT 'NORMAL'
-- NORMAL
DEBUG
VALIDACION
  p_id_usuario          IN VARCHAR2
-- Usuario que ejecuta el proceso
  p_resultado           OUT VARCHAR2
-- Resultado del proceso (OK, ERROR, WARNING)
  p_mensaje_salida      OUT VARCHAR2
```

**Operaciones SQL:** SELECT, UPDATE

---

### PROCESA_MOVIMIENTO_BOLSA

**Tipo:** PROCEDURE

**Propósito:** Gestión de bolsa de horas

**Archivo:** `procesa_movimiento_bolsa.prc`

**Parámetros:**

```sql
V_ID_REGISTRO in number
--ID_REGISTRO
ACTUALIZAR Y BORRAR
          V_ID_FUNCIONARIO in number
V_PERIODO in varchar2
V_ID_TIPO_MOVIMIENTO in  varchar2
V_EXCESOS_EN_HORAS in varchar2
V_EXCESOS_EN_MINUTOS in varchar2
V_FECHA_MOVIMIENTO       in varchar2
V_ID_TIPO_OPERACION in varchar2
V_ID_USUARIO in  varchar2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### PROCESA_MOV_BOLSA_CONCILIA

**Tipo:** PROCEDURE

**Propósito:** Gestión de bolsa de horas

**Archivo:** `procesa_mov_bolsa_concilia.prc`

**Parámetros:**

```sql
V_ID_REGISTRO in number
--ID_REGISTRO
ACTUALIZAR Y BORRAR
          V_ID_FUNCIONARIO in number
V_ID_TIPO_MOVIMIENTO in  varchar2
V_EXCESOS_EN_HORAS in varchar2
V_EXCESOS_EN_MINUTOS in varchar2
V_FECHA_MOVIMIENTO       in varchar2
V_ID_TIPO_OPERACION in out  varchar2
V_ID_USUARIO in  varchar2
V_OBSERVACIONES in  varchar2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### TRASPASA_SALDO_BOLSA

**Tipo:** PROCEDURE

**Propósito:** Gestión de bolsa de horas

**Archivo:** `traspasa_saldo_bolsa.prc`

**Parámetros:**

```sql
V_ID_FUNCIONARIO in number
V_PERIODO in varchar2
--ID_REGISTRO
ACTUALIZAR Y BORRAR
          V_ID_USUARIO in  varchar2
```

**Operaciones SQL:** DELETE, INSERT, SELECT, UPDATE

**Llama a:**

- `CALCULA_DIAS_VACACIONES` (FUNCTION)

---

### VBUENO_AUSENCIA_RRHH

**Tipo:** PROCEDURE

**Propósito:** Proceso de aprobación y firma

**Archivo:** `vbueno_ausencia_rrhh.prc`

**Parámetros:**

```sql
V_ID_FIRMA             IN VARCHAR2
V_ID_FUNCIONARIO_FIRMA IN NUMBER
V_ID_AUSENCIA          IN NUMBER
V_ID_MOTIVO            IN VARCHAR2
todo_ok_Basico         OUT INTEGER
msgBasico              OUT VARCHAR2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### VBUENO_PERMISO_RRHH

**Tipo:** PROCEDURE

**Propósito:** Proceso de aprobación y firma

**Archivo:** `vbueno_permiso_rrhh.prc`

**Parámetros:**

```sql
V_ID_FIRMA             IN VARCHAR2
V_ID_FUNCIONARIO_FIRMA IN NUMBER
V_ID_PERMISO           IN NUMBER
V_ID_MOTIVO            IN VARCHAR2
todo_ok_Basico         OUT INTEGER
msgBasico              OUT VARCHAR2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### VBUENO_RRHH

**Tipo:** PROCEDURE

**Propósito:** Proceso de aprobación y firma

**Archivo:** `vbueno_rrhh.prc`

**Parámetros:**

```sql
V_ID_FIRMA in varchar2
V_ID_FUNCIONARIO_FIRMA in number
V_ID_PERMISO in number
V_ID_MOTIVO in  VARCHAR2
todo_ok_Basico out integer
msgBasico out varchar2
```

**Operaciones SQL:** INSERT, SELECT, UPDATE

---

### VBUENO_VARIOS

**Tipo:** PROCEDURE

**Propósito:** Proceso de aprobación y firma

**Archivo:** `vbueno_varios.prc`

**Parámetros:**

```sql
V_ID_TIPO_PERMISO in varchar2
V_ID_FUNCIONARIO_FIRMA in varchar2
V_ID_TODOS_PERMISOS in varchar2
V_ID_TIPO_FIRMA   in varchar2
V_ID_MOTIVO_DENIEGA   in varchar2
V_CLAVE_FIRMA in varchar2
```

**Operaciones SQL:** INSERT

---

## 4. Diagramas de Relaciones Principales

### 4.1. Flujo de Permisos

```
INSERTA_PERMISO_NEW
  └─> Validaciones y verificaciones
  └─> Envío de notificaciones
       └─> FIRMA_PERMISO_JSA_NEW / VBUENO_RRHH
            └─> Actualización de estado
            └─> Registro en Finger (si aplica)
```

### 4.2. Flujo de Fichajes

```
FINGER_PROCESA_TRANSACCIONES
  └─> FINGER_LEE_TRANS
       └─> FINGER_CALCULA_SALDO_NEW
            └─> FINGER_REGENERA_SALDO
                 └─> Actualización de registros
```

---

## 5. Conclusiones y Recomendaciones

### Hallazgos Principales

1. **Modularidad:** El sistema está bien modularizado con separación clara entre procedimientos
   y funciones según su responsabilidad.

2. **Áreas Funcionales:**
   - **Gestión de Permisos y Ausencias:** Flujo completo desde solicitud hasta aprobación
   - **Control de Fichajes:** Sistema robusto de procesamiento de transacciones Finger
   - **Servicios Web (WBS):** API para portal de empleados
   - **Bolsa de Horas:** Gestión de compensatorios y saldos
   - **Validaciones:** Múltiples funciones de verificación y control

3. **Flujos Principales:**
   - Solicitud → Validación → Firma → Registro
   - Fichaje → Procesamiento → Cálculo → Actualización

### Recomendaciones

1. **Documentación:** Mantener comentarios actualizados en todos los procedimientos
2. **Pruebas:** Implementar pruebas unitarias para funciones críticas de validación
3. **Monitoreo:** Establecer logs para seguimiento de errores en flujos complejos
4. **Optimización:** Revisar procedimientos con múltiples dependencias para mejorar rendimiento

---

## 6. Anexos

### Convenciones de Nomenclatura

- **INSERTA_xxx:** Procedimientos de inserción
- **ACTUALIZA_xxx:** Procedimientos de actualización
- **CHEQUEA_xxx / VALIDA_xxx:** Funciones de validación
- **DEVUELVE_xxx / GET_xxx:** Funciones de consulta
- **FINGER_xxx:** Operaciones de control de asistencia
- **WBS_xxx:** Servicios web para portal
- **CALCULA_xxx:** Funciones de cálculo

---

*Documento generado automáticamente el 10/12/2025 a las 22:09*