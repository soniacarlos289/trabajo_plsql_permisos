CREATE OR REPLACE PACKAGE BODY RRHH.WBS_PORTAL_EMPLEADO is

  -- Función valida que el ID_FUNCIONARIO ESTA
  procedure wbs_controlador(parametros_entrada in VARCHAR2,
                            resultado          out clob,
                            p_blob             IN BLOB) is

    v_id_funcionario    varchar2(12500);
    v_pantalla          varchar2(12500);
    v_id_anio           varchar2(120);
    v_id_mes            varchar2(120);
    resultado_ope       varchar2(12500);
    observaciones       varchar2(12500);
    v_latitud           varchar2(12500);
    v_longitud          varchar2(12500);
    v_msgsalida         varchar2(12500);
    v_todook            varchar2(12500);
    v_n_fichaje         varchar2(12500);
    v_id_permiso        varchar2(12500);
    v_tipo_permiso      varchar2(12500);
    v_tipo      varchar2(12500);
    v_tipo_dias         varchar2(12500);
    v_fecha_inicio      varchar2(12500);
    v_fecha_fin         varchar2(12500);
    v_grado             varchar2(12500);
    v_dp                varchar2(12500);
    v_t1                varchar2(12500);
    v_t2                varchar2(12500);
    v_t3                varchar2(12500);
    v_hora_inicio       varchar2(12500);
    v_hora_fin          varchar2(12500);
    v_id_ausencia       varchar2(12500);
    v_tipo_ausencia     varchar2(12500);
    v_tipo_funcionario  varchar2(12500);
    v_tipo_firma        varchar2(12500); --0 autoriza 1 deniega
    v_tipo_denegacion   varchar2(12500);
    v_clave_firma       varchar2(12500);
    v_id_nomina         varchar2(12500);
     v_id_unico         varchar2(12500);
    datos               clob;
    datos_tmp           clob;
    operacion           varchar2(12500);
    cabecera_pet        varchar2(12500);
    fin_pet             varchar2(12500);
    saldo_horario       varchar2(12500);
    firma_planificacion varchar2(12500);
    v_enlace_fichero    varchar2(12500);
     v_id_curso varchar2(12500);
   v_id_periodo varchar2(12500);
   v_id_justificacion varchar2(12500);
parametros varchar2(12500);
  begin

    cabecera_pet  := '[{';
    fin_pet       := '}]';
    resultado     := '';
    datos         := '';
    datos_tmp     := '';
    operacion     := '';
    observaciones := '';
    --Recuperamos parametros de la pantalla
    
      parametros:=replace(parametros_entrada,'%3A',':');
    parametros:=replace(parametros_entrada,'%3B',';');   
    
  /*  v_pantalla       := DEVUELVE_VALOR_CAMPO(parametros_entrada, 'Pant=');
    v_id_funcionario := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                             'ID_FUNCIONARIO=');
    v_id_anio        := DEVUELVE_VALOR_CAMPO(parametros_entrada, 'anio=');
    v_id_mes         := DEVUELVE_VALOR_CAMPO(parametros_entrada, 'mes=');
    v_latitud        := DEVUELVE_VALOR_CAMPO(parametros_entrada, 'lat=');
    v_longitud       := DEVUELVE_VALOR_CAMPO(parametros_entrada, 'long=');
    v_id_permiso     := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                             'id_permiso=');
    v_tipo_permiso   := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                             'tipo_permiso=');
    v_tipo   := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                             'tipo=');
    v_tipo_dias      := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                             'tipo_dias=');

    IF    v_tipo_dias = 'LABORAL' THEN
      v_tipo_dias := 'L';
    ELSE
            v_tipo_dias := 'N';
    END IF;
    v_fecha_inicio   := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                             'fecha_inicio=');
    v_fecha_fin      := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                             'fecha_fin=');
    v_grado          := DEVUELVE_VALOR_CAMPO(parametros_entrada, 'grado=');
    v_dp             := DEVUELVE_VALOR_CAMPO(parametros_entrada, 'dp=');
    v_t1             := DEVUELVE_VALOR_CAMPO(parametros_entrada, 't1=');
    v_t2             := DEVUELVE_VALOR_CAMPO(parametros_entrada, 't2=');
    v_t3             := DEVUELVE_VALOR_CAMPO(parametros_entrada, 't3=');
    v_hora_inicio    := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                             'hora_inicio=');
    v_hora_fin       := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                             'hora_fin=');
    v_id_ausencia    := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                             'id_ausencia=');
    v_tipo_ausencia  := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                             'tipo_ausencia=');

    v_tipo_firma := DEVUELVE_VALOR_CAMPO(parametros_entrada, 'firma=');

    v_tipo_denegacion := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                              'denegacion=');

    v_id_nomina := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                              'id_nomina=');
    v_enlace_fichero  := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                              'enlace_fichero=');
    v_id_curso  := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                              'id_curso=');


       v_id_periodo  := DEVUELVE_VALOR_CAMPO(parametros_entrada,
                                              'idPeriodo=');*/


 v_pantalla       := DEVUELVE_VALOR_CAMPO(parametros, 'Pant=');
    v_id_funcionario := DEVUELVE_VALOR_CAMPO(parametros,
                                             'ID_FUNCIONARIO=');
    v_id_anio        := DEVUELVE_VALOR_CAMPO(parametros, 'anio=');
    v_id_mes         := DEVUELVE_VALOR_CAMPO(parametros, 'mes=');
    v_latitud        := DEVUELVE_VALOR_CAMPO(parametros, 'lat=');
    v_longitud       := DEVUELVE_VALOR_CAMPO(parametros, 'long=');
    v_id_permiso     := DEVUELVE_VALOR_CAMPO(parametros,
                                             'id_permiso=');
    v_tipo_permiso   := DEVUELVE_VALOR_CAMPO(parametros,
                                             'tipo_permiso=');
    v_tipo   := DEVUELVE_VALOR_CAMPO(parametros,
                                             'tipo=');
    v_tipo_dias      := DEVUELVE_VALOR_CAMPO(parametros,
                                             'tipo_dias=');

    IF    v_tipo_dias = 'LABORAL' THEN
      v_tipo_dias := 'L';
    ELSE
            v_tipo_dias := 'N';
    END IF;
    v_fecha_inicio   := DEVUELVE_VALOR_CAMPO(parametros,
                                             'fecha_inicio=');
    v_fecha_fin      := DEVUELVE_VALOR_CAMPO(parametros,
                                             'fecha_fin=');
    v_grado          := DEVUELVE_VALOR_CAMPO(parametros, 'grado=');
    v_dp             := DEVUELVE_VALOR_CAMPO(parametros, 'dp=');
    v_t1             := DEVUELVE_VALOR_CAMPO(parametros, 't1=');
    v_t2             := DEVUELVE_VALOR_CAMPO(parametros, 't2=');
    v_t3             := DEVUELVE_VALOR_CAMPO(parametros, 't3=');
    v_hora_inicio    := DEVUELVE_VALOR_CAMPO(parametros,
                                             'hora_inicio=');
    v_hora_fin       := DEVUELVE_VALOR_CAMPO(parametros,
                                             'hora_fin=');
    v_id_ausencia    := DEVUELVE_VALOR_CAMPO(parametros,
                                             'id_ausencia=');
    v_tipo_ausencia  := DEVUELVE_VALOR_CAMPO(parametros,
                                             'tipo_ausencia=');

    v_tipo_firma := DEVUELVE_VALOR_CAMPO(parametros, 'firma=');

    v_tipo_denegacion := DEVUELVE_VALOR_CAMPO(parametros,
                                              'denegacion=');

    v_id_nomina := DEVUELVE_VALOR_CAMPO(parametros,
                                              'id_nomina=');
    v_enlace_fichero  := DEVUELVE_VALOR_CAMPO(parametros,
                                              'enlace_fichero=');
    v_id_curso  := DEVUELVE_VALOR_CAMPO(parametros,
                                              'id_curso=');
    /*v_id_curso  := DEVUELVE_VALOR_CAMPO(parametros,
                                              'idcurso=');       */

       v_id_periodo  := DEVUELVE_VALOR_CAMPO(parametros,
                                              'idPeriodo=');


    if v_id_mes= '' or v_id_mes is null or v_id_mes=0 then
      v_id_mes:=to_char(sysdate,'MM');
    end if;

   if v_id_anio= '' or v_id_anio is null or v_id_anio=0 then
      v_id_anio:=to_char(sysdate,'YYYY');
    end if;

   if  length(v_id_periodo) = 5  then
       v_id_mes:=substr(v_id_periodo,1,1);
        v_id_anio:=substr(v_id_periodo,2,4);
   else if length(v_id_periodo) = 6  then
          v_id_mes:=substr(v_id_periodo,1,2);
          v_id_anio:=substr(v_id_periodo,3,4);
         end if;
   end if;

    -- v_id_funcionario:=substr(v_id_funcionario, 5,6);
    resultado_ope := 'OK';
    observaciones := 'Usuario encontrado ' ||  v_id_periodo;
    --Recuperamos los datos personales
    datos := wbs_devuelve_datos_personales(v_id_funcionario);

    IF datos = 'Usuario no encontrado' then
      resultado_ope := 'ERROR';
      observaciones := 'Usuario no encontrado ' || parametros_entrada;
      datos         := '0';
    ELSE
      CASE v_pantalla

      --Pantalla de Roles
      --Fichaje teletrabajo, firma y Saldo horario
        WHEN 'ROLE' THEN
          resultado_ope := 'OK';
          observaciones := 'Todo bien';
          --roles
          datos := wbs_devuelve_roles(v_id_funcionario);

        WHEN 'DPER' THEN
          resultado_ope := 'OK';
          observaciones := 'Usuario encontrado';

      --Pantalla de Principal
      -- Datos personales + 2 nominas + saldo_horario + permiso_compañeros + firma_permisos
        WHEN 'PPAL' THEN
          resultado_ope := 'OK';
          observaciones := 'Usuario encontrado';

          BEGIN
            select distinct decode(id_fichaje, null, 'false', 'true') as fichaje,
                            decode(firma, 0, 'false', 'true') firma
              into saldo_horario, firma_planificacion
              from apliweb_usuario
             where id_funcionario = v_id_funcionario
               and login not like 'adm%'
               and rownum < 2;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              saldo_horario       := 'false';
              firma_planificacion := 'false';
            WHEN OTHERS THEN
              saldo_horario       := 'false';
              firma_planificacion := 'false';
          END;

          --devuelve nominas
          datos_tmp := wbs_devuelve_datos_nominas(v_id_funcionario, 3, 0);
          datos     := datos || ',' || datos_tmp;

          if saldo_horario = 'true' then
            --devuelve saldo_horario
            datos_tmp := wbs_devuelve_saldo_horario(v_id_funcionario,
                                                    'r',
                                                    v_id_anio,
                                                    v_id_mes);
            datos     := datos || ',' || datos_tmp;
          end if;

          --devuelve fuera oficina;
          datos_tmp := wbs_devuelve_permisos_compas(v_id_funcionario, 3);
          datos     := datos || ',' || datos_tmp;

          if firma_planificacion = 'true' then
            --devuelve firma;
            datos_tmp := wbs_devuelve_firma_permisos(v_id_funcionario, 3);
            datos     := datos || ',' || datos_tmp;
          end if;

          --devuelve resumen datos bolsas;
          datos_tmp := wbs_devuelve_saldo_bolsas(v_id_funcionario,
                                                 'r',
                                                 v_id_anio);
          datos     := datos || ',' || datos_tmp;

          --devuelve notificaciones.
       -- datos := datos || ',' || '"notificaciones": [{"notificacion":"Nomima de Septiembre Cargada"},{"notificacion":"Saldo horario mes septiembre incompleto"}]';



       datos_tmp := wbs_devuelve_mensajes(v_id_funcionario);
      datos     := datos || ',' || datos_tmp;

      -------------------BOLSAS--------------------------------
      --Detalle bolsa productividad
        WHEN 'DBPR' THEN
          --devuelve  datos bolsas productividad;
          datos_tmp := wbs_devuelve_saldo_bolsas(v_id_funcionario,
                                                 'p',
                                                 v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';

      --Detalle bolsa horas_extras
        WHEN 'DBHE' THEN
          --devuelve resumenn datos bolsas;
          datos_tmp := wbs_devuelve_saldo_bolsas(v_id_funcionario,
                                                 'e',
                                                 v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';

      --Detalle bolsa horas_conciliacion
        WHEN 'DBHC' THEN
          --devuelve datos bolsas;
          datos_tmp := wbs_devuelve_saldo_bolsas(v_id_funcionario,
                                                 'c',
                                                 v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';

      --Detalle saldo_horario
        WHEN 'SHOR' THEN
          --devuelve  datos bolsas;
          datos_tmp := wbs_devuelve_saldo_horario(v_id_funcionario,
                                                  'd',
                                                --  v_id_periodo,
                                                  v_id_anio,
                                                  v_id_mes);
          datos     := '"datos": [' || datos_tmp || ']';

      ----------------------------PERMISOS--------------------------------------------------
        WHEN 'CPER' THEN
          --devuelve  permisos;
          datos_tmp := wbs_devuelve_consulta_permisos(v_id_funcionario,
                                                      '0',
                                                      v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';

        WHEN 'DDPR' THEN
          --devuelve detalle  permisos;
          datos_tmp := wbs_devuelve_consulta_permisos(v_id_funcionario,
                                                      v_id_permiso,
                                                      v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';

        WHEN 'APPR' THEN
          --Anula permiso;
          permisos_anula_usuario(v_id_permiso,
                                 v_id_funcionario,
                                 v_todook,
                                 v_msgsalida);
          if v_todook = 1 THEN
            resultado_ope := 'ERROR';
          end if;
          observaciones := v_msgsalida;
          --Recuperamos los datos personales
          datos_tmp := wbs_devuelve_datos_personales(v_id_funcionario);
          datos     := datos_tmp;

      ----------------------------PERMISOS SOLICITUD--------------------------------------------------
        WHEN 'SPER_PREV' THEN
          --devuelve  permisos;
          datos_tmp := wbs_devuelve_consulta_permisos(v_id_funcionario,
                                                      'sp',
                                                      v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';
          -------------------------------------------------------

        WHEN 'SPER' THEN

          v_tipo_funcionario := '10';
          v_id_unico:='SI';

          v_id_justificacion:='NO';
         if p_blob is not null then
             v_id_justificacion:='SI';
          end if;
          permisos_new(v_id_anio,
                       v_id_funcionario,
                       v_tipo_funcionario, --tipo_funcionario
                       v_tipo,
                       20, --v_id_estado_permiso => v_v_id_estado_permiso,
                       v_tipo_dias,
                       v_fecha_inicio,
                       v_fecha_fin,
                       v_hora_inicio,
                       v_hora_fin,
                       v_grado,
                       v_dp,
                       v_id_justificacion , --justificacion
                       v_t1,
                       v_t2,
                       v_t3,
                       v_id_unico,
                       '',
                       v_msgsalida,
                       v_todook,
                       v_enlace_fichero);

          if v_todook = 1 THEN
            resultado_ope := 'ERROR.' ||  v_tipo_dias || ' '||v_id_anio ;
             observaciones :=v_msgsalida;
          else
            if v_enlace_fichero is not null and v_enlace_fichero > 0 then
              --justificar permiso.
              observaciones := wbs_justifica_fichero(v_enlace_fichero,p_blob);
              observaciones := observaciones || ' ' || v_msgsalida;
            end if;
          end if;
          --observaciones := v_msgsalida;
          --Recuperamos los datos personales
          datos_tmp := wbs_devuelve_datos_personales(v_id_funcionario);
          datos     := datos_tmp;
          ---------------SUBIDA JUSTIFICAR_FICHERO------------------
        WHEN 'JPER' THEN
          --justifica_fichero;
          observaciones := wbs_justifica_fichero_sin(v_id_permiso,v_id_ausencia, p_blob);

          --Recuperamos los datos personales
          datos_tmp := wbs_devuelve_datos_personales(v_id_funcionario);
          datos     := datos_tmp;

         ---------------ACTUALIZA  FOTO _FICHERO------------------
        WHEN 'FOAC' THEN
          --justifica_fichero;
          observaciones := wbs_actualiza_foto(v_id_funcionario, p_blob);

          --Recuperamos los datos personales
          datos_tmp := wbs_devuelve_datos_personales(v_id_funcionario);
          datos     := datos_tmp;


        ---------------DESCAGA JUSTIFICAR_FICHERO------------------
         WHEN 'JPAF' THEN

           if v_enlace_fichero is null or v_enlace_fichero='' or v_enlace_fichero = 0 then
             v_enlace_fichero:=v_id_permiso;
           end if;

         datos_tmp := wbs_devuelve_fichero_justificante_per_au(v_enlace_fichero);
         datos     := datos_tmp;

      ------AUSENCIAS------------------------------------
        WHEN 'CAUS' THEN
          --devuelve  permisos;
          datos_tmp := wbs_devuelve_consulta_ausencias(v_id_funcionario,
                                                       '0',
                                                       v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';

        WHEN 'DAUS' THEN
          --devuelve detalle  permisos;
          datos_tmp := wbs_devuelve_consulta_ausencias(v_id_funcionario,
                                                       v_id_ausencia,
                                                       v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';

        WHEN 'AAUS' THEN
          --Anula permiso;
          ausencias_anula_usuario(v_id_ausencia,
                                  v_id_funcionario,
                                  v_todook,
                                  v_msgsalida);

          if v_todook = 1 THEN
            resultado_ope := 'ERROR';
          end if;
          observaciones := v_msgsalida;
          --Recuperamos los datos personales
          datos_tmp := wbs_devuelve_datos_personales(v_id_funcionario);
          datos     := datos_tmp;

        WHEN 'SAUS_PREV' THEN
          --devuelve  permisos;
          datos_tmp := wbs_devuelve_consulta_ausencias(v_id_funcionario,
                                                       '1',
                                                       v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';
        WHEN 'SAUS' THEN

          v_tipo_funcionario := '10';
          ausencias_new(v_id_anio,
                    v_id_funcionario,
                    v_tipo_funcionario, --tipo_funcionario
                    v_tipo_ausencia,
                    20,
                    v_fecha_inicio,
                    v_fecha_fin,
                    v_hora_inicio,
                    v_hora_fin,
                    'NO', --justificacion
                    '',
                    v_msgsalida,
                    v_todook);

          if v_todook = 1 THEN
            resultado_ope := 'ERROR';
          end if;
          observaciones := v_msgsalida;
          --Recuperamos los datos personales
          datos_tmp := wbs_devuelve_datos_personales(v_id_funcionario);
          datos     := datos_tmp;
          --incidencias de fichaje
          WHEN 'INCF' THEN
          v_tipo_funcionario := '10';
          ausencias_new(v_id_anio,
                    v_id_funcionario,
                    v_tipo_funcionario, --tipo_funcionario
                    '998',
                    20,
                    v_fecha_inicio,
                    v_fecha_fin,
                    v_hora_inicio,
                    v_hora_fin,
                    'NO', --justificacion
                    '',
                    v_msgsalida,
                    v_todook);

          if v_todook = 1 THEN
            resultado_ope := 'ERROR';
          end if;
          observaciones := replace(v_msgsalida,'ausencia','fichaje');
          --Recuperamos los datos personales
          datos_tmp := wbs_devuelve_datos_personales(v_id_funcionario);
          datos     := datos_tmp;
          ------------------FIRMA Y PLANIFICACION-----------------------------------------------
        WHEN 'FTEL' THEN
          --Fichar teletrabajo; 08/07/2025
         fichaje_por_intranet(v_id_funcionario,
                               1,
                               v_msgsalida,
                               v_todook,
                               v_n_fichaje);
                               
          observaciones := v_todook;

      ---FIRMA Autorizados, pendientes, denegados.
        WHEN 'FPEP' THEN
          --devuelve Permisos pendientes firma
          datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'p', 'pe');
          datos     := '"datos": [' || datos_tmp || ']';

        WHEN 'FAUP' THEN
          --devuelve ausencias pendientes firma
          datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'p', 'au');
          datos     := '"datos": [' || datos_tmp || ']';

        WHEN 'FFIP' THEN
          --devuelve fichajes pendientes firma
          datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'p', 'fi');
          datos     := '"datos": [' || datos_tmp || ']';

        WHEN 'FPEA' THEN
          --devuelve Permisos autorizados firma
          datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'a', 'pe');
          datos     := '"datos": [' || datos_tmp || ']';

        WHEN 'FAUA' THEN
          --devuelve ausencias autorizados firma
          datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'a', 'au');
          datos     := '"datos": [' || datos_tmp || ']';

        WHEN 'FFIA' THEN
          --devuelve fichajes autorizados firma
          datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'a', 'fi');
          datos     := '"datos": [' || datos_tmp || ']';

        WHEN 'FPED' THEN
          --devuelve Permisos denegados firma
          datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'd', 'pe');
          datos     := '"datos": [' || datos_tmp || ']';

        WHEN 'FAUD' THEN
          --devuelve ausencias denegados firma
          datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'd', 'au');
          datos     := '"datos": [' || datos_tmp || ']';

        WHEN 'FFID' THEN
          --devuelve fichajes denegados firma
          datos_tmp := wbs_devuelve_firma(v_id_funcionario, 'd', 'fi');
          datos     := '"datos": [' || datos_tmp || ']';

        WHEN 'FPES' THEN
          --devuelve permiso Servicio firma
          datos_tmp := wbs_devuelve_permisos_fichajes_serv(v_id_funcionario,
                                                           0,
                                                           v_fecha_inicio);

          datos := '"datos": [' || datos_tmp || ']';

        WHEN 'FFIS' THEN
          --devuelve fichajes Servicio firma
          datos_tmp := wbs_devuelve_permisos_fichajes_serv(v_id_funcionario,
                                                           2,
                                                           v_fecha_inicio);

          datos := '"datos": [' || datos_tmp || ']';

        WHEN 'FPET' THEN
          --devuelve permisos pendientes Servicio firma
          datos_tmp := wbs_devuelve_permisos_fichajes_serv(v_id_funcionario,
                                                           1,
                                                           v_fecha_inicio);

          datos := '"datos": [' || datos_tmp || ']';

        WHEN 'FAUS' THEN
          --Firma ausencia;
          select sec_permiso_vali_todos.nextval
            into v_clave_firma
            from dual;

          firma_jsa_varios_webs('A', --'A',
                           v_id_funcionario,
                           ';' || v_id_permiso ||';', --v_id_todos_permisos => v_v_id_todos_permisos,
                           v_tipo_firma, --v_id_tipo_firma => v_v_id_tipo_firma,
                           v_tipo_denegacion, --v_id_motivo_deniega => v_v_id_motivo_deniega,
                           v_clave_firma,observaciones,v_todook);
         if v_todook = '1' THEN
            resultado_ope := 'ERROR';
         else
             resultado_ope := 'OK' || v_tipo_firma;
         end if;

        --  observaciones := 'Firmado correctamente';

        WHEN 'FPER' THEN
          --Firma permiso;

          select sec_permiso_vali_todos.nextval
            into v_clave_firma
            from dual;

          firma_jsa_varios_webs('P', --'P',
                           v_id_funcionario,
                           ';' || v_id_permiso ||';', --v_id_todos_permisos => v_v_id_todos_permisos,
                           v_tipo_firma, --v_id_tipo_firma => v_v_id_tipo_firma,
                           v_tipo_denegacion, --v_id_motivo_deniega => v_v_id_motivo_deniega,
                           v_clave_firma,observaciones,v_todook);
        if v_todook = 1 THEN
            resultado_ope := 'ERROR' ;
         else
             resultado_ope := 'OK' ||';' || v_id_permiso ||';';
         end if;
         -- observaciones := 'Firmado correctamente';

        WHEN 'FFIC' THEN
          --Firma fichaje;
          select sec_permiso_vali_todos.nextval
            into v_clave_firma
            from dual;

          firma_jsa_varios_webs('F', --'F',
                           v_id_funcionario,
                           ';' || v_id_permiso ||';', --v_id_todos_permisos => v_v_id_todos_permisos,
                           v_tipo_firma, --v_id_tipo_firma => v_v_id_tipo_firma,
                           v_tipo_denegacion, --v_id_motivo_deniega => v_v_id_motivo_deniega,
                           v_clave_firma,observaciones,v_todook);
        if v_todook = 1 THEN
            resultado_ope := 'ERROR';
         else
             resultado_ope := 'OK';
         end if;


      --devuelve nominas
        WHEN 'NFUN' THEN

          datos_tmp := wbs_devuelve_datos_nominas(v_id_funcionario, 24, 0);
          datos     := '"datos": [' || datos_tmp || ']';

      --devuelve fichero nominas
        WHEN 'NFUF' THEN

          datos_tmp := wbs_devuelve_datos_nominas(v_id_funcionario,
                                                  1,
                                                  v_id_nomina);
          datos     := datos_tmp;

       --devuelve catalogo cursos
        WHEN 'CCAT' THEN
          datos_tmp := wbs_devuelve_cursos( v_id_funcionario, 0, v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';

       --devuelve detalle curso
        WHEN 'CDET' THEN
          datos_tmp := wbs_devuelve_cursos( v_id_funcionario, v_id_curso,  v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';
        --devuelve cursos realizados
           WHEN 'CREA' THEN
          datos_tmp := wbs_devuelve_cursos( v_id_funcionario, 3,  v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';
        ---------------Inscripcio a cursos------------------
        WHEN 'CINS' THEN
          --justifica_fichero;
          observaciones := wbs_inserta_curso(v_id_funcionario, v_id_curso,0);

          --Recuperamos los datos personales
          datos_tmp := wbs_devuelve_datos_personales(v_id_funcionario);
          datos     := datos_tmp;

        ---------------Anula a cursos------------------
        WHEN 'CANU' THEN
          --justifica_fichero;
          observaciones := wbs_inserta_curso(v_id_funcionario, v_id_curso,1);

          --Recuperamos los datos personales
          datos_tmp := wbs_devuelve_datos_personales(v_id_funcionario);
          datos     := datos_tmp;


        ----------------------Planificacion-------------------------------------
        --devuelve calendario permisos
           WHEN 'PPES' THEN
          datos_tmp := wbs_devuelve_permisos_fichajes_serv( v_id_funcionario,0,  v_fecha_inicio);
          datos     := '"datos": [' || datos_tmp || ']';

           WHEN 'PPES_B' THEN
          datos_tmp := wbs_devuelve_permisos_bomberos( v_id_funcionario,0,  v_fecha_inicio);
          datos     := '"datos": [' || datos_tmp || ']';
            
            --devuelve calendario permisos-fichaje la ultima semana
           WHEN 'PPFS' THEN
          datos_tmp := wbs_devuelve_permisos_fichajes_serv( v_id_funcionario,3,  v_fecha_inicio);
          datos     := '"datos": [' || datos_tmp || ']';


          --devuelve fichajes servicio
           WHEN 'PFIS' THEN
          datos_tmp := wbs_devuelve_permisos_fichajes_serv( v_id_funcionario,2,  v_fecha_inicio);
          datos     := '"datos": [' || datos_tmp || ']';

           --devuelve permisos_pendientes
           WHEN 'PPEP' THEN
          datos_tmp := wbs_devuelve_permisos_fichajes_serv( v_id_funcionario,1,  v_fecha_inicio);
          datos     := '"datos": [' || datos_tmp || ']';

           WHEN 'XXNO' THEN
          datos_tmp :=wbs_actualiza_nomina( v_id_funcionario, p_blob);
             --Recuperamos los datos personales
          datos_tmp := wbs_devuelve_datos_personales(v_id_funcionario);
          datos     := datos_tmp;


           --devuelve tr_estados 1 TRES
           WHEN 'TRES' THEN
          datos_tmp :=  wbs_devuelve_tr_estados(1,  v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';
          WHEN 'TRPE' THEN
          datos_tmp :=  wbs_devuelve_tr_estados(2,  v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';
          WHEN 'TRAU' THEN
          datos_tmp :=  wbs_devuelve_tr_estados(3,  v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';
            WHEN 'TRCU' THEN
          datos_tmp :=  wbs_devuelve_tr_estados(4,  v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';
           WHEN 'TRIN' THEN
          datos_tmp :=  wbs_devuelve_tr_estados(5,  v_id_anio);
          datos     := '"datos": [' || datos_tmp || ']';
        ELSE
          resultado_ope := 'ERROR';
          observaciones := 'Pantalla Incorrecta';
      END CASE;

    END IF;

    operacion := wbs_devuelve_datos_operacion(resultado_ope, observaciones);
    if datos = '0' then
      resultado := cabecera_pet || operacion || chr(13) || fin_pet;
    else
      resultado := cabecera_pet || operacion || ',' || datos || chr(13) ||
                   fin_pet;
    end if;

    --  resultado := replace(resultado,'ü','&uuml;');
  end; --PROCEDURE TOKKEN_IS_VALIDO

end WBS_PORTAL_EMPLEADO;
/

