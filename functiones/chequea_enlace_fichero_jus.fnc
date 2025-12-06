/**
 * ==============================================================================
 * Funcion: CHEQUEA_ENLACE_FICHERO_JUS
 * ==============================================================================
 * 
 * PROPOSITO:
 *   Genera el codigo HTML para mostrar enlaces a ficheros justificantes de
 *   permisos. Dependiendo de si existe el fichero y del estado del permiso,
 *   genera enlaces para ver, subir o eliminar documentos.
 *
 * PARAMETROS:
 *   @param V_ANNO (VARCHAR2) - Anio del permiso
 *   @param V_ID_FUNCIONARIO (VARCHAR2) - Identificador del funcionario
 *   @param v_ID_PERMISO (VARCHAR2) - Identificador del permiso
 *   @param V_ID_ESTADO (NUMBER) - Estado actual del permiso
 *   @param V_ID_TIPO_PERMISO (VARCHAR2) - Tipo de permiso ('P'=Permiso, 'A'=Ausencia)
 *   @param V_ID_APLICACION (VARCHAR2) - Aplicacion origen:
 *                                       1 = Portal del Empleado
 *                                       2 = Administracion de Permisos
 *
 * RETORNO:
 *   @return VARCHAR2 - Codigo HTML con los enlaces correspondientes:
 *                      - Enlace para ver PDF si existe fichero
 *                      - Enlace para subir si no existe fichero
 *                      - Enlace para eliminar (solo en app administracion)
 *                      - Vacio si permiso rechazado/cancelado o muy antiguo
 *
 * LOGICA DE NEGOCIO:
 *   1. Verifica si existe fichero justificante
 *   2. Genera HTML segun aplicacion y existencia de fichero
 *   3. Excluye permisos antiguos (P<470600, A<210071)
 *   4. Excluye estados rechazados/cancelados (30,31,32,40,41)
 *
 * ESTADOS EXCLUIDOS:
 *   - 30: Rechazado
 *   - 31: Rechazado por superior
 *   - 32: Rechazado por RRHH
 *   - 40: Cancelado
 *   - 41: Cancelado automaticamente
 *
 * DEPENDENCIAS:
 *   - Tabla FICHEROS_JUSTIFICANTES: Almacen de documentos
 *
 * CONSIDERACIONES:
 *   - El ID del fichero se forma concatenando: ANNO + ID_FUNCIONARIO + ID_PERMISO
 *   - Las rutas de imagenes varian segun la aplicacion
 *   - El boton eliminar solo aparece si estado != 80 (finalizado)
 *
 * MEJORAS v2.0:
 *   - Constantes para estados y limites
 *   - Documentacion completa
 *   - Codigo mas legible y estructurado
 *   - Variables con nombres descriptivos
 *
 * AUTOR: Sistema RRHH
 * FECHA: 2025
 * VERSION: 2.0
 * ==============================================================================
 */
CREATE OR REPLACE FUNCTION RRHH.CHEQUEA_ENLACE_FICHERO_JUS(
    V_ANNO            IN VARCHAR2,
    V_ID_FUNCIONARIO  IN VARCHAR2,
    v_ID_PERMISO      IN VARCHAR2,
    V_ID_ESTADO       IN NUMBER,
    V_ID_TIPO_PERMISO IN VARCHAR2,
    V_ID_APLICACION   IN VARCHAR2
) RETURN VARCHAR2 IS
    -- Constantes de aplicacion
    C_APP_PORTAL          CONSTANT NUMBER := 1;
    C_ESTADO_FINALIZADO   CONSTANT NUMBER := 80;
    
    -- Constantes de limites de permisos antiguos
    C_LIMITE_PERMISO_P    CONSTANT NUMBER := 470600;
    C_LIMITE_PERMISO_A    CONSTANT NUMBER := 210071;
    
    -- Constantes de tipos
    C_TIPO_PERMISO        CONSTANT VARCHAR2(1) := 'P';
    C_TIPO_AUSENCIA       CONSTANT VARCHAR2(1) := 'A';
    
    -- Variables de trabajo
    v_resultado           VARCHAR2(5012);
    v_id_fichero          VARCHAR2(100);
    v_fichero_existe      NUMBER := 0;
    v_html_contenido      VARCHAR2(4024);
    
BEGIN
    -- Construir ID del fichero
    v_id_fichero := V_ANNO || V_ID_FUNCIONARIO || v_ID_PERMISO;
    v_html_contenido := '';
    
    -- Verificar si existe el fichero justificante
    BEGIN
        SELECT 1
          INTO v_fichero_existe
          FROM ficheros_justificantes
         WHERE id = v_id_fichero
           AND ROWNUM = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_fichero_existe := 0;
    END;
    
    -- Generar HTML segun exista fichero y tipo de aplicacion
    IF v_fichero_existe = 1 THEN
        -- Fichero existe: mostrar enlace para ver
        IF V_ID_APLICACION = C_APP_PORTAL THEN
            v_html_contenido := '<a target="_blank" href="../fichero/verDoc.jsp?PERMISO=' || 
                               V_ID_TIPO_PERMISO || '&ID=' || v_id_fichero ||
                               '" target="mainFrame"><img src="../imagen/pdf.png" alt="Ver" width="20" height="20" border="0"></a>';
        ELSE
            -- Aplicacion de Administracion
            v_html_contenido := '<a href="#" onClick="javascript:window.open(''' || 
                               '../fichero/verDoc.jsp?PERMISO=' || V_ID_TIPO_PERMISO || 
                               '&ID=' || v_id_fichero ||
                               ''',null,''top=0,left=100,height=600,width=940,scrollbars=yes,status=no,toolbar=no,menubar=no,location=0,directories=no'');"><img src="../../imagen/pdf.png" alt="Ver" width="20" height="20" border="0"></a>';
            
            -- Agregar boton eliminar si no esta finalizado
            IF V_ID_ESTADO <> C_ESTADO_FINALIZADO THEN
                v_html_contenido := v_html_contenido || ' ' ||
                                   '<a href="javascript:show_confirmar(' || v_id_fichero || 
                                   ');"><img src="../../imagen/delete.png" alt="Eliminar" width="15" height="15" border="0"></a>';
            END IF;
        END IF;
    ELSE
        -- Fichero no existe: mostrar enlace para subir
        IF V_ID_APLICACION = C_APP_PORTAL THEN
            v_html_contenido := '<a href="../fichero/ficheroDoc.jsp?PERMISO=' || 
                               V_ID_TIPO_PERMISO || '&ID=' || v_id_fichero ||
                               '"><img src="../imagen/new.png" alt="Subir" width="20" height="20" border="0"></a>';
        ELSE
            v_html_contenido := '<a href="#" onClick="javascript:window.open(''' ||
                               '../fichero/ficheroDoc.jsp?PERMISO=' || V_ID_TIPO_PERMISO ||
                               '&ID=' || v_id_fichero ||
                               ''',null,''top=0,left=100,height=600,width=940,scrollbars=yes,status=no,toolbar=no,menubar=no,location=0,directories=no'');"><img src="../../imagen/new.png" alt="Subir" width="20" height="20" border="0"></a>';
        END IF;
    END IF;
    
    v_resultado := v_html_contenido;
    
    -- Excluir permisos antiguos
    IF V_ID_TIPO_PERMISO = C_TIPO_PERMISO AND v_ID_PERMISO < C_LIMITE_PERMISO_P THEN
        v_resultado := '';
    END IF;
    
    IF V_ID_TIPO_PERMISO = C_TIPO_AUSENCIA AND v_ID_PERMISO < C_LIMITE_PERMISO_A THEN
        v_resultado := '';
    END IF;
    
    -- Excluir estados rechazados y cancelados
    IF V_ID_ESTADO IN (30, 31, 32, 40, 41) THEN
        v_resultado := '';
    END IF;
    
    RETURN v_resultado;
END CHEQUEA_ENLACE_FICHERO_JUS;
/
