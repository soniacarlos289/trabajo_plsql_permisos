# 📊 Métricas de Optimización - Vistas RRHH

## 🎯 Resumen Ejecutivo

Se han optimizado y documentado **31 vistas** en el directorio `vista/`. Las optimizaciones se centran en:
- Eliminación de UNIONs redundantes
- Conversión a sintaxis JOIN estándar ANSI
- Documentación detallada para mantenimiento

---

## 📈 Métricas de Rendimiento Estimadas

### Vistas con Mayor Impacto de Optimización

| Vista | Optimización | Mejora Estimada | Detalle |
|-------|--------------|-----------------|---------|
| `personal_anno_bajas.vw` | 4 UNIONs → 1 SELECT | **~75%** | 1 scan de tabla vs 4 |
| `personal_anno_ingreso.vw` | 4 UNIONs → 1 SELECT | **~75%** | 1 scan de tabla vs 4 |
| `personal_anno_ingresos.vw` | 4 UNIONs → 1 SELECT | **~75%** | 1 scan de tabla vs 4 |
| `personal_edad_tramos.vw` | 5 UNIONs → 1 SELECT | **~80%** | 1 scan de tabla vs 5 |
| `fichaje_diarios.vw` | UNION → UNION ALL | **~20-30%** | Evita ordenamiento y eliminación de duplicados |
| `v_bolsa_movimiento.vw` | Eliminado DISTINCT | **~10-20%** | Evita ordenamiento |

### Vistas Ya Optimizadas (Sin Cambios de Rendimiento)

Las siguientes vistas ya estaban optimizadas en iteraciones anteriores:
- `area.vw`
- `bajas_ilt.vw`
- `bolsa_saldo.vw`
- `bolsa_saldo_periodo.vw` (eliminados 13 UNIONs previamente)
- `bolsa_saldo_periodo_resumen.vw` (eliminados 12 UNIONs previamente)

---

## 🔄 Tipos de Optimizaciones Aplicadas

### 1. Eliminación de UNIONs Redundantes
```
ANTES (4 scans de tabla):
SELECT ... FROM personal WHERE fecha_baja BETWEEN '01/01/2018' AND '31/12/2018'
UNION
SELECT ... FROM personal WHERE fecha_baja BETWEEN '01/01/2019' AND '31/12/2019'
UNION
SELECT ... FROM personal WHERE fecha_baja BETWEEN '01/01/2020' AND '31/12/2020'
UNION
SELECT ... FROM personal WHERE fecha_baja BETWEEN '01/01/2021' AND '31/12/2021'

DESPUÉS (1 scan de tabla):
SELECT EXTRACT(YEAR FROM fecha_baja), id_funcionario
FROM personal
WHERE fecha_baja >= '01/01/2018' AND fecha_baja < '01/01/2022'
```

**Impacto**: Reduce el número de accesos a la tabla de N (número de UNIONs) a 1.

### 2. UNION → UNION ALL
```
ANTES:
SELECT ... FROM tabla1 UNION SELECT ... FROM tabla2

DESPUÉS:
SELECT ... FROM tabla1 UNION ALL SELECT ... FROM tabla2
```

**Impacto**: UNION ALL evita la operación de ordenamiento y eliminación de duplicados.
Solo aplicable cuando se garantiza que no hay duplicados entre las consultas.

### 3. Sintaxis (+) → LEFT OUTER JOIN
```
ANTES (Oracle antiguo):
SELECT ... FROM a, b WHERE a.id = b.id(+)

DESPUÉS (ANSI estándar):
SELECT ... FROM a LEFT OUTER JOIN b ON a.id = b.id
```

**Impacto**: Mejor legibilidad y optimización potencial del motor SQL.

### 4. Eliminación de DISTINCT Innecesario
```
ANTES:
SELECT DISTINCT col1, col2 FROM tabla

DESPUÉS:
SELECT col1, col2 FROM tabla
```

**Impacto**: Evita ordenamiento cuando los datos ya son únicos.

---

## 📋 Índices Recomendados

Para maximizar el rendimiento, se recomienda crear los siguientes índices:

### Tablas de Personal
```sql
CREATE INDEX idx_personal_fecha_baja ON personal(fecha_baja);
CREATE INDEX idx_personal_fecha_ingreso ON personal(fecha_ingreso);
CREATE INDEX idx_personal_activo ON personal(fecha_baja, fecha_nacimiento);
```

### Tablas de Fichaje
```sql
CREATE INDEX idx_fich_func_fecha ON fichaje_funcionario(fecha_fichaje_entrada);
CREATE INDEX idx_cal_lab_dia ON calendario_laboral(id_dia);
CREATE INDEX idx_webperiodo_fechas ON webperiodo(inicio, fin);
```

### Tablas de Permisos/Ausencias
```sql
CREATE INDEX idx_permiso_estado ON permiso(id_estado, anulado);
CREATE INDEX idx_permiso_tipo_estado ON permiso(id_tipo_permiso, id_estado);
CREATE INDEX idx_ausencia_estado ON ausencia(id_estado, anulado);
```

### Tablas de Bolsa de Horas
```sql
CREATE INDEX idx_bolsa_mov_func ON bolsa_movimiento(id_funcionario, id_ano, periodo, anulado);
CREATE INDEX idx_bolsa_func_acum ON bolsa_funcionario(id_funcionario, id_acumulador, id_ano);
```

---

## ⚠️ Vistas con Advertencias de Rendimiento

Las siguientes vistas tienen estructuras complejas que podrían impactar el rendimiento:

### Alto Impacto Potencial

| Vista | Advertencia | Recomendación |
|-------|-------------|---------------|
| `calendario_final.vw` | Producto cartesiano con personal_new | Filtrar siempre por id_funcionario |
| `calendario_columna_fichaje_new.vw` | Múltiples llamadas a laboral_dia() | Usar solo cuando necesario |
| `fichaje_saldo_completa_new.vw` | 4 UNIONs con múltiples JOINs | Considerar vistas intermedias |
| `resumen_saldo_bolsa.vw` | 15 UNIONs | Candidata a refactorización futura |
| `vista_permiso_bomberos.vw` | Lógica compleja de turnos | Mover datos hardcodeados a tabla |

### Uso de Funciones PL/SQL

Las siguientes vistas utilizan funciones que se ejecutan por cada fila:
- `laboral_dia()` - calendario_final.vw, calendario_columna_fichaje_new.vw
- `permiso_en_dia()` - resumen_saldo.vw, fichaje_saldo_completa_fin.vw
- `devuelve_observaciones_fichaje()` - fichaje_saldo_completa_new.vw
- `devuelve_dia_jornada()` - fichaje_saldo_hacer.vw

**Recomendación**: Considerar cachear resultados o materializar vistas si se consultan frecuentemente.

---

## 📝 Documentación Añadida

Cada vista ahora incluye un bloque de comentarios con:

```sql
/*
================================================================================
  VISTA: rrhh.nombre_vista
================================================================================
  PROPÓSITO:
    Descripción funcional de la vista

  CAMPOS RETORNADOS:
    - campo1: Descripción
    - campo2: Descripción

  JOINS UTILIZADOS:
    - tabla1: Descripción del join
    - tabla2: Descripción del join

  NOTAS DE OPTIMIZACIÓN:
    - Optimizaciones aplicadas
    - Índices recomendados
    - Advertencias de rendimiento

  DEPENDENCIAS:
    - Lista de tablas/vistas/funciones

  ÚLTIMA MODIFICACIÓN: fecha - descripción
================================================================================
*/
```

---

## 🔍 Resumen de Cambios por Vista

### Vistas Optimizadas (con cambios de código)

1. **webfinger.vw** - Sintaxis JOIN moderna, TO_NUMBER para cálculos
2. **fichaje_diarios.vw** - UNION → UNION ALL
3. **personal_plaza_v.vw** - JOINs modernos
4. **conflicto_permiso_baja.vw** - JOINs modernos
5. **resumen_saldo.vw** - JOINs modernos
6. **v_bolsa_movimiento.vw** - Eliminado DISTINCT, JOINs modernos
7. **v_bolsa_saldo.vw** - JOINs modernos
8. **personal_anno_bajas.vw** - Eliminados 4 UNIONs
9. **personal_anno_ingreso.vw** - Eliminados 4 UNIONs
10. **personal_anno_ingresos.vw** - Eliminados 4 UNIONs
11. **personal_edad_tramos.vw** - Eliminados 5 UNIONs

### Vistas Solo Documentadas (sin cambios de código)

Las demás vistas recibieron documentación completa sin modificar la lógica SQL,
ya que su estructura era adecuada o requerían mantener compatibilidad.

---

## 📞 Información de Contacto

**Fecha de Optimización**: 06/12/2025  
**Repositorio**: trabajo_plsql_permisos  
**Directorio**: vista/

---

## 📌 Próximos Pasos Recomendados

1. ✅ Revisar y aplicar índices recomendados
2. ⏳ Ejecutar pruebas de rendimiento en ambiente de QA
3. ⏳ Considerar materializar vistas de uso frecuente
4. ⏳ Refactorizar resumen_saldo_bolsa.vw (15 UNIONs)
5. ⏳ Mover generación de HTML a capa de presentación
