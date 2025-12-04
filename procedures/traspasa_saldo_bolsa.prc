CREATE OR REPLACE PROCEDURE RRHH."TRASPASA_SALDO_BOLSA" (
          V_ID_FUNCIONARIO in number,
          V_PERIODO in varchar2,--ID_REGISTRO, ACTUALIZAR Y BORRAR
          V_ID_USUARIO in  varchar2
          ) is

  v_id_dni_trabajador    varchar2(9);
  v_nombre               varchar2(267);
  v_id_fichaje             varchar2(5);
  i_id_ano               number;
  i_id_mes               number;
  i_id_ano_ant           number;
  i_id_mes_ant           number;
  i_saldo                number;
  i_id_funcionario       number;
  i_exceso_en_horas      number;
  i_excesos_en_minutos   number;
  i_exceso_en_horas_r    number;
  i_excesos_en_minutos_r number;
  i_penal_enero          number;
  i_penal_febrero        number;
  i_penal_marzo          number;
  i_penal_abril          number;
  i_penal_mayo           number;
  i_penal_junio          number;
  i_penal_julio          number;
  i_penal_agosto         number;
  i_penal_septiembre     number;
  i_penal_octubre        number;
  i_penal_noviembre      number;
  i_penal_diciembre      number;
  i_penal_enero_mas      number;
  v_cadena               varchar2(32267);
  v_Cadena2              varchar2(32267);
  v_Cadena3              varchar2(32267);
  v_Cadena4              varchar2(32267);
  v_Cadena5              varchar2(32267);
  v_cadena_cabecera      varchar2(32267);
  permisos_sin_justificar number;
   i_horas_fichadas_teletrabajo number;
  i_estado_baja number;
  i_incidencias number;
  i_horas_concilia number;
  i_saldo_final number;

  ca1  varchar2(2322);
  c2  varchar2(2322);
  c3  varchar2(2322);
  c4  varchar2(2322);
  c5 varchar2(2322);
  c55 varchar2(2322);
  c6 varchar2(2322);

  v_cadena_pie           varchar2(322);
  i_saldo_real           number;
  i_negativo             varchar2(1);
  i_vuelta               number;
  i_MAX_DEFICIT          number;
  i_MAX_DEFICIT_40       number;
  i_MAX_DEFICIT_37       number;
  i_DIAS_DEFICIT         number;
  i_horario              number;
  i_TOPE_HORAS           number;
  I_maximo_alcanzado     NUMBER;
  jornada_37             number;
  i_dias_trabajados      number;
  i_dias_trabajados_2      number;
  v_desc_jornada         varchar2(100);
  v_desc_jornada_2       varchar2(100);
  v_desc_jornada_3       varchar2(100);
  i_fecha_ini_ver          date;
  i_fecha_fin_ver date;
  i_fecha_ini_inv date;
  i_fecha_fin_inv date;
  i_fecha_ini_otro date;
  i_fecha_fin_otro date;
  i_correos number;

  periodo_mes number;
  periodo_ano number;
  I_ID_USUARIO number;
  i_movimientos_ini NUMBER;
  sin_movimiento number;
  no_hay_reduccion  number;

  id_funcionario_correo number;
  v_direccion_correo varchar2(322);
  id_tipo_correo  number;

  i_fecha_numero number;
  i_texto_carga     varchar2(322);
  i_prueba   number;
  total_correos number;
  I_POSICION NUMBER;
  i_id number;
  i_horas_conexion_teletrabajo number;

  CURSOR C1(i_ano number, i_mes number,i_funcionario number,i_ano_ant number) is
   select nvl(sum(horas_saldo - horas_hacer),0) as saldo,t.id_funcionario
  from fichaje_funcionario_resu_dia t, webperiodo ow, bolsa_funcionario bf,personal_new p
 where
       mes || ano = LPAD(i_mes ,2,'0')  ||  i_ano
   and t.id_dia <> to_Date('20/04/2020', 'dd/mm/yyyy') and t.id_dia <> to_Date('22/05/2020', 'dd/mm/yyyy')
   and t.id_dia between ow.inicio and ow.fin and t.id_dia < sysdate-1
   and bf.id_funcionario=t.id_funcionario and t.id_funcionario=p.id_funcionario and p.activo='SI' and p.tipo_funcionario2 not in (21,23)
    and ('0'=i_funcionario OR t.id_funcionario=i_funcionario)
      and bf.id_acumulador=1     and bf.id_ano=i_ano_ant
   group by t.id_funcionario
   order by 1 asc;


 --Añadido para los correos.
 Cursor Manda_correos  is
  select id_funcionario,direccion,  id_tipo from BOLSA_CORREO;


Begin
  -- para hacer prueba a 0 . 1 REAL
  i_prueba:=1;--pruebas
  i_correos:=0;-- 0 no manda
--  i_prueba:=1;--REAL

  I_POSICION:=0;
  periodo_mes:=substr(V_PERIODO,1,2);
  periodo_ano:=substr(V_PERIODO,3,4);
  I_ID_USUARIO:=V_ID_USUARIO;

  IF  V_ID_USUARIO = 0 then
     I_ID_USUARIO:=101217;
  END IF;




--raise_application_error(-20005,'*Operacion no realizada');
--return;
-- dbms_OUTPUT.PUT_LINE(i_id_funcionario ||'*' || v_nombre || ' *' || v_id_dni_trabajador || '*' || i_saldo );

  dbms_OUTPUT.PUT_LINE('Empieza el PL/SQL ');



  /* ENVIO CABECERA CORREO SALDOS*/
  v_Cadena  := '';
  v_Cadena2 := '';
  v_Cadena3 := '';
  v_Cadena4 := '';
  v_Cadena5 := '';

  v_cadena_cabecera := '<table width="661" border="1" cellspacing="1" cellpadding="2">' ||
                       chr(10);
  v_cadena_cabecera := v_cadena_cabecera ||
                       '<td width="81" valign="middle" bgcolor="#003366"><span class="Estilo1">Funcionario</span></td>' ||
                       chr(10);
  v_cadena_cabecera := v_cadena_cabecera ||
                       '<td width="351" valign="middle" bgcolor="#003366"><span class="Estilo1">Nombre y Apellidos </span></td> ' ||
                       chr(10);
  v_cadena_cabecera := v_cadena_cabecera ||
                       '<td width="76" valign="middle" bgcolor="#003366"><p class="Estilo1">Saldo Real</p>' ||
                       chr(10);
  v_cadena_cabecera := v_cadena_cabecera || '</td>' || chr(10);
  v_cadena_cabecera := v_cadena_cabecera ||
                       '<td width="122" valign="middle" bgcolor="#003366"><span class="Estilo1">Saldo a Bolsa</span></td> ' ||
                       chr(10);
  v_cadena_cabecera := v_cadena_cabecera ||
                       '<td width="190" valign="middle" bgcolor="#003366"><span class="Estilo1">Días trabajados de bolsa/horas</span></td> ' ||
                       chr(10);
  v_cadena_cabecera := v_cadena_cabecera ||
                     '<td width="122" valign="middle" bgcolor="#003366"><span class="Estilo1">Permiso/Ausencias sin Justificar</span></td> ' ||
                   chr(10);
  v_cadena_cabecera := v_cadena_cabecera ||
                       '<td width="122" valign="middle" bgcolor="#003366"><span class="Estilo1">Incidencía</span></td> ' ||
                       chr(10);
  v_cadena_cabecera := v_cadena_cabecera || '</tr>' || chr(10);

  i_id_ano     := 0;
  i_id_mes     := 0;
  i_saldo_real := 0;
  i_vuelta     := 0;

  periodo_mes:=substr(V_PERIODO,1,2);
  periodo_ano:=substr(V_PERIODO,3,4);

  i_id_mes:=periodo_mes;
  i_id_ano:=periodo_ano;

  --Mes Anterior
  IF  V_PERIODO =0 THEN

  /*obtenemos el mes anterior*/
  select ano, mes
    into i_id_ano, i_id_mes
    from webperiodo
   where (ano = to_char(sysdate+2, 'YYYY') and
         mes = to_char(sysdate+2, 'mm') - 1)
      OR (ano = to_char(sysdate+2, 'YYYY') - 1 and
         0 = to_char(sysdate+2, 'mm') - 1 and mes = 12);

  END IF;

  i_id_mes_ant := i_id_mes;
  i_id_ano_ant :=i_id_ano;

  --El proceso es para todo tengo que cambiar el año
  IF V_PERIODO = 0 and i_id_mes=1 then
    i_id_ano_ant:=i_id_ano-1;
    i_id_mes_ant:=13;
  END IF;

  IF i_id_mes  =13 then
     i_id_mes:=1;
     i_id_ano:=i_id_ano+1;
  END IF;

  --Borramos los registros del periodo
  delete from   bolsa_CARGA_MENSUAL
  where (id_funcionario=V_ID_FUNCIONARIO OR V_ID_FUNCIONARIO='0') and Periodo=periodo_mes and i_id_ano=periodo_ano;

 commit;

   --V_ID_FUNCIONARIO:=101216;

  OPEN C1(i_id_ano, i_id_mes,V_ID_FUNCIONARIO,i_id_ano_ant);

  LOOP
    FETCH C1
      into i_saldo, v_id_dni_trabajador;
    EXIT WHEN C1%NOTFOUND;

    I_POSICION:=I_POSICION+1;
    i_exceso_en_horas    := 0;
    i_excesos_en_minutos := 0;

    if i_saldo <> -99999 and i_saldo is not null then

      /* Busco funcionario */
      Begin
        select id_funcionario,
               UPPER(substr(dist_name,
                      INSTR(dist_name, 'CN=', 1) + 3,
                      INSTR(dist_name, ',OU', 1)-4 )) as nombre
                      ,id_fichaje
          into i_id_funcionario, v_nombre,v_id_fichaje
          from apliweb_usuario
         where id_funcionario = v_id_dni_trabajador
           and rownum < 2;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_id_funcionario := 0;
      END;

      IF i_id_funcionario = 0 THEN
        dbms_OUTPUT.PUT_LINE('Usuario no existe en apliweb_usuario ID_FUNCIONARIO:' || v_id_dni_trabajador);
      END IF;



      i_saldo_real := i_saldo;
      i_negativo   := '';

      --No se puede acumular en bolsa2019
      --chm 10/04/2019
      If i_saldo > 0 then
        i_saldo := 0;
      eND IF;

      i_TOPE_HORAS := 0;
      --Añadido el 25 de Marzo 2013
      --chm
      --Maximo alcanzado.
       sin_movimiento:=0;



      --- PARTIR 2019 en la bolsa no se puede añadir.
      IF  i_id_ano_ant> 2018 THEN
          I_maximo_alcanzado := 1;
      END IF;



      --añadido a petición de chema
      --controla el check de penalizacion no puede acumular saldo
      --05 agosto
      Begin
        select penal_enero,
               penal_febrero,
               penal_marzo,
               penal_abril,
               penal_mayo,
               penal_junio,
               penal_julio,
               penal_agosto,
               penal_septiembre,
               penal_octubre,
               penal_noviembre,
               penal_diciembre,
               penal_enero_mas
          into i_penal_enero,
               i_penal_febrero,
               i_penal_marzo,
               i_penal_abril,
               i_penal_mayo,
               i_penal_junio,
               i_penal_julio,
               i_penal_agosto,
               i_penal_septiembre,
               i_penal_octubre,
               i_penal_noviembre,
               i_penal_diciembre,
               i_penal_enero_mas
          from BOLSA_FUNCIONARIO
         where id_funcionario = v_id_dni_trabajador  and
               id_ano=i_id_ano_ant;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_penal_enero      := 0;
          i_penal_febrero    := 0;
          i_penal_marzo      := 0;
          i_penal_abril      := 0;
          i_penal_mayo       := 0;
          i_penal_junio      := 0;
          i_penal_julio      := 0;
          i_penal_agosto     := 0;
          i_penal_septiembre := 0;
          i_penal_octubre    := 0;
          i_penal_noviembre  := 0;
          i_penal_diciembre  := 0;
      END;

      --Penalizaciones por meses.
      IF i_saldo > 0 then
        if i_id_mes_ant = 1 and i_penal_enero = 1 then
          i_saldo := 0;
        end if;
        if i_id_mes_ant = 2 and i_penal_febrero = 1 then
          i_saldo := 0;
        end if;
        if i_id_mes_ant = 3 and i_penal_marzo = 1 then
          i_saldo := 0;
        end if;
        if i_id_mes_ant = 4 and i_penal_abril = 1 then
          i_saldo := 0;
        end if;
        if i_id_mes_ant = 5 and i_penal_mayo = 1 then
          i_saldo := 0;
        end if;
        if i_id_mes_ant = 6 and i_penal_junio = 1 then
          i_saldo := 0;
        end if;
        if i_id_mes_ant = 7 and i_penal_julio = 1 then
          i_saldo := 0;
        end if;
        if i_id_mes_ant = 8 and i_penal_agosto = 1 then
          i_saldo := 0;
        end if;
        if i_id_mes_ant = 9 and i_penal_septiembre = 1 then
          i_saldo := 0;
        end if;

        if i_id_mes_ant = 10 and i_penal_octubre = 1 then
          i_saldo := 0;
        end if;

        if i_id_mes_ant = 11 and i_penal_noviembre = 1 then
          i_saldo := 0;
        end if;

        if i_id_mes_ant = 12 and i_penal_diciembre = 1 then
          i_saldo := 0;
        end if;

       if i_id_mes_ant = 13 and i_penal_enero_mas = 1 then
          i_saldo := 0;
        end if;

      end if;

      --obtengo lo salgo negativos maximo permitidos.
      Begin
        select MAX_DEFICIT_40, MAX_DEFICIT_37, DIAS_DEFICIT
          into i_MAX_DEFICIT_40, i_MAX_DEFICIT_37, i_DIAS_DEFICIT
          from BOLSA_PERIODO
         where id_ano = i_id_ano_ant
           and periodo = i_id_mes_ant;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_MAX_DEFICIT_40 := 0;
          i_MAX_DEFICIT_37 := 0;
          i_DIAS_DEFICIT   := 0;
      END;

      --Primero buscamos que jornada tiene 40 horas o 37,5
      BEGIN
        select count(*)
          into i_horario
          from jornada_funcionario
         where lpad(id_funcionario, 6, '0') =
               lpad(i_ID_FUNCIONARIO, 6, '0');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_horario := 0; --37,5 horas
      END;

      i_estado_baja:=1;
      --EL funcionario esta de baja
      BEGIN
      select count(*)
          into i_estado_baja
        from rrhh.personal_new
      where
          ( fecha_baja is null    or fecha_baja > sysdate
             ) and
         (id_funcionario=i_ID_FUNCIONARIO);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
           i_estado_baja:=0;
      END;


      --Peticion de chema, maria tio y san berna
      IF lpad(i_ID_FUNCIONARIO, 6, '0')='001741' OR lpad(i_ID_FUNCIONARIO, 6, '0')='001740' then
         i_horario :=1;--40 horas
      END IF;

      if i_horario = 0 then
        i_MAX_DEFICIT := i_MAX_DEFICIT_37;
        jornada_37    := 1; --Añadido para saber la jornada.
      else
        i_MAX_DEFICIT := i_MAX_DEFICIT_40;
        jornada_37    := 0;
      end if;
      v_desc_jornada_2 := 'NO';
      If i_saldo < i_MAX_DEFICIT then
        i_saldo          := i_MAX_DEFICIT;
        i_negativo       := '-';
        v_desc_jornada_2 := 'Sí';
      eND IF;
      no_hay_reduccion :=1;
       BEGIN
      select fecha_ini_ver,
             fecha_fin_ver,
             fecha_ini_inv,
             fecha_fin_inv,
             fecha_ini_otro,
             fecha_fin_otro
        into i_fecha_ini_ver,
             i_fecha_fin_ver,
             i_fecha_ini_inv,
             i_fecha_fin_inv,
             i_fecha_ini_otro,
             i_fecha_fin_otro
        from BOLSA_REDUCCION t
        where ID_ANO=i_id_ano_ant;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          no_hay_reduccion := 0;
      END;


       -- 1 de julio 2015 chm
      --hay que completar el permiso 15000 compensatorio de horas.
      i_dias_trabajados_2 := 0;

      --esta mal cuando coincide
      --con otro mes
      --añadido chm  14 julio 2019
      --calcula_dia_vacaciones

      BEGIN
       select nvl(sum( CALCULA_DIAS_VACACIONES(fecha_inicio,fecha_fin, id_tipo_dias,inicio,fin)),0)
          into i_dias_trabajados_2
          from permiso p,  webperiodo w
           where
            (p.fecha_inicio between inicio and fin OR
             p.fecha_fin between inicio and fin )
            and w.mes = i_id_mes
           and w.ano = i_id_ano
            and p.id_funcionario= v_id_dni_trabajador
           and p.id_ESTADO=80
             and ( (id_tipo_permiso=15000 and total_horas> 301)  OR  id_tipo_permiso<>15000)
          and (
           (p.fecha_inicio between i_fecha_ini_ver and  i_fecha_fin_ver) OR
           (p.fecha_fin between i_fecha_ini_ver and  i_fecha_fin_ver) OR

           (p.fecha_inicio between i_fecha_ini_inv and  i_fecha_fin_inv) OR
           (p.fecha_fin between i_fecha_ini_inv and  i_fecha_fin_inv) OR

           (p.fecha_inicio between i_fecha_ini_otro and  i_fecha_fin_otro) OR
           (p.fecha_fin between i_fecha_ini_otro and  i_fecha_fin_otro)

               );
            EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_dias_trabajados_2 := 0;
        END;
               permisos_sin_justificar := 0;
        /* PERMISOS_AUSENCIAS SIN JUSTIFICAR*/
         BEGIN
         select sum(a1)
              into permisos_sin_justificar
                  from (
            select count(*) as a1
                  from permiso p,  webperiodo w
            where
            (p.fecha_inicio between inicio and fin OR
             p.fecha_fin between inicio and fin )
             and w.mes = i_id_mes
             and w.ano = i_id_ano
             and p.id_funcionario= v_id_dni_trabajador
             and p.id_ESTADO=80
             and ( (id_tipo_permiso=15000 and total_horas> 301)  OR  id_tipo_permiso<>15000)
             and justificacion='NO'
               union
         select nvl(count(*),0) as a1
             from ausencia p,  webperiodo w
             where
             (p.fecha_inicio between inicio and fin OR
             p.fecha_fin between inicio and fin )
            and w.mes = i_id_mes
             and w.ano = i_id_ano
             and p.id_funcionario= v_id_dni_trabajador
             and p.id_ESTADO=80     and id_tipo_ausencia<>'050'
               and justificado='NO');
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
          permisos_sin_justificar := 0;
        END;

         /*Enviamos aviso */

          i_horas_fichadas_teletrabajo:=0;
         /*HOras fichadas TELETRABAJO*/
         BEGIN
         select  nvl(TRUNC(sum(HORAS_FICHADAS)),0)
           into   i_horas_fichadas_teletrabajo
         from FICHAJE_FUNCIONARIO f  ,  webperiodo w
         where
         (f.fecha_fichaje_entrada between inicio and fin ) and
          w.mes = i_id_mes and
          w.ano = i_id_ano and
          f.id_funcionario= v_id_dni_trabajador and
          reloj_entrada=94 and reloj_salida=94
         group by id_funcionario;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
           i_horas_fichadas_teletrabajo := 0;
        END;

         i_horas_conexion_teletrabajo := 0;

          /*HOras CONEXION ARU*/
         BEGIN
         select  nvl(TRUNC(sum(n_horas_conexion)),0)
           into   i_horas_conexion_teletrabajo
         from estadistica_x_mes_covid f
         where
          id_mes_n = i_id_mes and
          f.id_funcionario= v_id_dni_trabajador;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
           i_horas_conexion_teletrabajo := 0;
        END;


        i_incidencias:=0;
        /*incidencias por fichajes  */
        bEGIN
         select  count(*)
           into   i_incidencias
         from FICHAJE_INCIDENCIA f  ,  webperiodo w
         where
         (f.fecha_incidencia between inicio and fin ) and
          id_tipo_incidencia in (4,5) and
          w.mes = i_id_mes and
          w.ano = i_id_ano and
          f.id_funcionario= v_id_dni_trabajador;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
          i_incidencias := 0;
        END;
         i_horas_concilia:='';
        /*HOras concilia*/
          bEGIN
         select sum(total_horas)
           into i_horas_concilia
             from ausencia p,  webperiodo w
             where
             (p.fecha_inicio between inicio and fin OR
             p.fecha_fin between inicio and fin )  and
              w.mes = i_id_mes and
          w.ano = i_id_ano and
          p.id_funcionario= v_id_dni_trabajador
             and p.id_ESTADO=80     and id_tipo_ausencia='050'
               and justificado='NO';
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
             i_horas_concilia := 0;
        END;


          i_dias_trabajados:= i_DIAS_DEFICIT;


         i_dias_trabajados := i_dias_trabajados-i_dias_trabajados_2;
          -- i_dias_trabajados :=13;

       IF i_dias_trabajados<0 THEN
              i_dias_trabajados :=0;
       END IF;


      IF jornada_37 = 1 then
        i_MAX_DEFICIT  := i_dias_trabajados * 60 * -1;
          v_desc_jornada := '';
         -- TODOS SOLO 1 hora chm 01/072/15
         --  v_desc_jornada := '--37,5H';
      else --cambiado a  60 solo diciembre 2014
        if  (i_id_ano_ant=2014 and i_id_mes_ant>=12 )
          OR (i_id_ano_ant>2014 and i_id_mes_ant>=11 ) THEN
                  i_MAX_DEFICIT  := i_dias_trabajados * 60 * -1;
          ELSE
                 i_MAX_DEFICIT  := i_dias_trabajados * 60 * -1;
                  -- TODOS SOLO 1 hora chm 01/072/15
                  --v_desc_jornada := '--40H';
                  v_desc_jornada := '';
        END IF;
      END IF;

      v_desc_jornada_3 := '0';

      If i_saldo < i_MAX_DEFICIT then
        i_saldo          := i_MAX_DEFICIT;
        i_negativo       := '-';
        v_desc_jornada_2 := 'Sí';
      eND IF;

      --Cambiado por que el maximo_alcanzado ha podido variar.

     --Añadido supera las  60:00 no vuelva a sumar.
     --11/11/2013
      IF  i_maximo_alcanzado = 1 and i_saldo> 0 and sin_movimiento=0  THEN
        i_saldo:=0;
      END IF;

      IF       no_hay_reduccion = 0 THEN
        i_MAX_DEFICIT:=0;
      END IF;

      v_desc_jornada_3 := trunc(i_MAX_DEFICIT / 60, 0) || ':' ||
                          lpad(abs(i_MAX_DEFICIT -  trunc(i_MAX_DEFICIT / 60, 0) * 60),2,'0');
      i_saldo_final :=i_saldo_real -i_saldo;
      i_exceso_en_horas      := trunc(i_saldo / 60, 0);
      i_excesos_en_minutos   := i_saldo - trunc(i_saldo / 60, 0) * 60;
      i_exceso_en_horas_r    := trunc(i_saldo_real / 60, 0);
      i_excesos_en_minutos_r := i_saldo_real - trunc(i_saldo_real / 60, 0) * 60;
          i_negativo := '';
     IF   v_desc_jornada_2 = 'Sí'  THEN
      if i_saldo_real >= 0 then
        v_cadena := v_cadena || '<tr>' || chr(10);
      else
        v_cadena   := v_cadena || '<tr bgcolor="#CC6666">' || chr(10);
        i_negativo := '-';
      END IF;
    END IF;
    if i_saldo_real < 0 then
        i_negativo := '-';
    end if;


     ca1:='';
     c2:='';
      c3:='';
       c4:='';
        c5:='';
        c55:='';
         c6:='';
      ca1:=i_id_funcionario;
     c2:=v_nombre;
      c3:=i_negativo || abs(i_exceso_en_horas_r) || ':' || lpad(abs(i_excesos_en_minutos_r), 2, '0');
       c4:= i_negativo ||abs(i_exceso_en_horas) || ':' ||   lpad(abs(i_excesos_en_minutos), 2, '0');
        c5:= i_dias_trabajados || v_desc_jornada;
        c55:= permisos_sin_justificar;
         c6:= v_desc_jornada_2;

     select to_number(to_char(sysdate,'dd')) into i_fecha_numero from dual;

    IF  i_fecha_numero = 3  THEN
            i_texto_carga:='Proceso PRE_CARGA bolsa de horas. No se cargan Saldos en la bolsa.';
    else
            i_texto_carga:='Proceso CARGA bolsa de horas.';
    END IF;
   if  i_id_funcionario > 0 AND  i_estado_baja> 0  then
        select sec_id_bolsa_proceso.nextval into i_id from dual;
        insert into bolsa_CARGA_MENSUAL values(ca1,c2,c3,c4,c5,c6,SYSDATE, LPAD(i_id_mes,2,'0') ,V_id_usuario,SYSDATE,  I_POSICION,  i_id_ano,i_texto_carga,  permisos_sin_justificar, i_horas_fichadas_teletrabajo,i_incidencias,i_horas_concilia, i_horas_conexion_teletrabajo,i_id, i_saldo_final);
   end if;
  COMMIT;

  --Solamente los que tienen incidencia
  IF   v_desc_jornada_2 = 'Sí'  THEN

      v_cadena := v_cadena || '<td>' || i_id_funcionario || '</td>' ||
                  chr(10);
      v_cadena := v_cadena || '<td>' || v_nombre || '</td>' || chr(10);
      v_cadena := v_cadena || '<td><div align="right">' || i_negativo ||
                  abs(i_exceso_en_horas_r) || ':' ||
                  lpad(abs(i_excesos_en_minutos_r), 2, '0') ||
                  '</div></td>' || chr(10);
      v_cadena := v_cadena || '<td><div align="right">' ||i_negativo ||
                  abs(i_exceso_en_horas) || ':' ||
                  lpad(abs(i_excesos_en_minutos), 2, '0') || '</div></td>' ||
                  chr(10);
      v_cadena := v_cadena || '<td><div align="right">' ||
                  i_dias_trabajados || v_desc_jornada || '</div></td>' ||
                  chr(10);
      v_cadena := v_cadena || '<td><div align="right">' || permisos_sin_justificar ||
                 '</div></td>' || chr(10);
      v_cadena := v_cadena || '<td><div align="right">' || v_desc_jornada_2 ||
                  '</div></td>' || chr(10);
      v_cadena := v_cadena || '</tr>' || chr(10);

      if length(v_cadena) > 29000 then
        if i_vuelta = 0 then
          v_cadena2 := v_Cadena;
          v_Cadena  := '';
        end if;
        if i_vuelta = 1 then
          v_cadena3 := v_Cadena2;
          v_cadena2 := v_Cadena;
          v_Cadena  := '';
        end if;
        if i_vuelta = 2 then
          v_cadena4 := v_Cadena3;
          v_cadena3 := v_Cadena2;
          v_cadena2 := v_Cadena;
          v_Cadena  := '';
        end if;
        if i_vuelta = 3 then
          v_cadena5 := v_Cadena4;
          v_cadena4 := v_Cadena3;
          v_cadena3 := v_Cadena2;
          v_cadena2 := v_Cadena;
          v_Cadena  := '';
        end if;
        i_vuelta := i_vuelta + 1;
      end if;
    END IF;
      --IF  i_saldo <= 0 THEN
      --   dbms_OUTPUT.PUT_LINE(i_id_funcionario ||'*' || v_nombre || ' *' || v_id_dni_trabajador || '*' || i_saldo );
      -- END IF;

      --sI EL MOVIMIENTO EXISTE ACTUALIZO.
      i_movimientos_ini:=0;

      Begin
           select count(*) into i_movimientos_ini
           from BOLSA_MOVIMIENTO t
           where id_ANO=i_id_ano_ant AND
                 PERIODO=i_id_mes_ant and
                 id_funcionario= v_id_dni_trabajador and
                 id_tipo_movimiento = 1 and anulado=0;
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
                    i_movimientos_ini  := 0;
             WHEN OTHERS THEN
                    i_movimientos_ini := 0;
      end;

      IF i_movimientos_ini > 0 THEN
                UPDATE  bolsa_movimiento
                  SET exceso_en_horas=i_exceso_en_horas,
                      excesos_en_minutos=i_excesos_en_minutos,
                      id_usuario= I_ID_USUARIO     ,
                       fecha_modi= sysdate
                WHERE id_ANO=i_id_ano_ant AND
                      PERIODO=i_id_mes_ant and
                      id_funcionario= v_id_dni_trabajador and
                      id_tipo_movimiento =1  and anulado=0;
      ELSE
               insert into bolsa_movimiento values
                (to_number(i_ID_FUNCIONARIO),
                i_id_ano_ant,
                i_id_mes_ant,
                1,--tipo movimeinto
                to_Date(to_char(sysdate, 'dd/mm/yyyy'),'dd/mm/yyyy'),
                0,--ANULADO
                0,
                'Movimiento generado automaticamente por Proceso',
                  i_exceso_en_horas,
                i_excesos_en_minutos,
                I_ID_USUARIO ,
                sysdate,
                sec_id_bolsa_mov.nextval
                );

                 IF    i_prueba = 0      THEN
                      ROLLBACK;
                 end IF;

      END IF;
    end if; --saldo

  END LOOP;
  CLOSE C1;


  v_cadena_pie := v_cadena_pie || '</table>' || chr(10);

--solo manda correos cuando lo hacemos para todo el mundo
 IF V_ID_FUNCIONARIO = 0 THEN
  --Se envian 4 correos para que no falle

--No funciona con CURSOR
/*  OPEN Manda_correos;

  LOOP
    FETCH Manda_correos
      into id_funcionario_correo ,  v_direccion_correo,id_tipo_correo;
    EXIT WHEN Manda_correos%NOTFOUND;
*/
          select to_number(to_char(sysdate,'dd')) into i_fecha_numero from dual;

    --Para el día 3  PRE CARGA no se hace nada en la base de datos solo correos.
    --Para el día 9 Hace la carga en la base de datos. Manda correos a todos.
    --Para cualquier carga otro día no manda correos y hace actualizacion de lo saldos

     if i_vuelta >= 2 then
                 total_correos:=4;
     else
                 total_correos:=3;
     end if;



    IF  i_fecha_numero = 3 and i_correos=1  THEN

           i_texto_carga:='Proceso CARGA SALDOS MENSUALES  bolsa de horas.';
           v_direccion_correo:='soniacarlos28@gmail.com';

               envio_correo('noresponda@aytosalamanca.es',
               v_direccion_correo,
               v_direccion_correo,
               i_texto_carga  || ' Anio:' ||
               to_char(i_id_ano) || ' Periodo: ' || to_char(i_id_mes),
                'Proceso ejecutado correctamente');




       /*  v_direccion_correo:='cpelaez@aytosalamanca.es';

                envio_correo('noresponda@aytosalamanca.es',
               v_direccion_correo,
               v_direccion_correo,
                i_texto_carga  || ' Anio:' ||
               to_char(i_id_ano) || ' Periodo: ' || to_char(i_id_mes),
                'Proceso ejecutado correctamente');*/

   end if;



  IF    i_prueba = 0      THEN
     ROLLBACK;

       v_direccion_correo:='carlos@aytosalamanca.es';



               envio_correo('noresponda@aytosalamanca.es',
               v_direccion_correo,
               v_direccion_correo,
               'Correo 3/4.'  ||  i_texto_carga  || ' Anio:' ||
               i_id_ano || ' Periodo: ' || i_id_mes,
               v_cadena_cabecera || v_cadena2 || v_cadena_pie);

               envio_correo('noresponda@aytosalamanca.es',
               v_direccion_correo,
               v_direccion_correo,
               'Correo 4/4.'  ||  i_texto_carga  || ' Anio:' ||
               i_id_ano || ' Periodo: ' || i_id_mes,
               v_cadena_cabecera || v_cadena || v_cadena_pie);





  END IF;

 END IF;
commit;
--  rollback;
end TRASPASA_SALDO_BOLSA;
/

