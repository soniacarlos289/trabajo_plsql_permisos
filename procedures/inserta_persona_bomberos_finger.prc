create or replace procedure rrhh.INSERTA_PERSONA_BOMBEROS_FINGER is

  i_id_funcionario     number;
  i_id_funcionario2    number;
  i_puesto             varchar2(3000);
  i_tipo_funcionario2  number;
  i_nombre             varchar2(3000);
  i_ape1               varchar2(3000);
  i_ape2               varchar2(3000);
  i_dni                varchar2(30);
  i_fecha_baja         DATE;
  i_ficha              number;
  i_codpers            varchar(6);
  v_codigo             varchar(5);
  i_inserta            number;
  i_cuerpo             varchar2(30000);
  v_fecha_ingreso      date;
  v_fecha_fin_contrato date;
  v_tarjeta            varchar2(40);
  v_fecha_nacimiento   varchar2(40);
  pin1                 number;
  pin2                 number;

  --Funcionarios en activo
  CURSOR C1 is
    select distinct p.id_funcionario,
                    puesto,
                    nvl(tipo_funcionario2, 0),
                    nombre,
                    ape1,
                    ape2,
                    nvl(fecha_baja, to_Date('01/01/2050', 'dd/mm/yyyy')),
                    dni,
                    fecha_ingreso,
                    fecha_fin_contrato,
                    '' as tarjeta,to_char(p.fecha_nacimiento,'DD/MM/YYYY')
      from personal_new p--, temp_bomberos_tar t
     where
    --  and tipo_funcionario2=10
     p.ID_FUNCIONARIO IN (963047

)


     order by 1 desc;

Begin
  i_cuerpo  := '';
  i_inserta := 0;
  --abrimos cursor.
  OPEN C1;

  LOOP
    FETCH C1
      into i_id_funcionario,
           i_puesto,
           i_tipo_funcionario2,
           i_nombre,
           i_ape1,
           i_ape2,
           i_fecha_baja,
           i_dni,
           v_fecha_ingreso,
           v_fecha_fin_contrato,
           v_tarjeta,v_fecha_nacimiento;
    EXIT WHEN C1%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE(i_ID_FUNCIONARIO);

    numero_fichaje_persona_n(v_codigo, pin1, pin2);

 DBMS_OUTPUT.PUT_LINE('Codigo' || v_codigo || ' pin1:'|| pin1|| ' pin2:'|| pin2);
    --FICHAJES
    --Comprobamos esta en la tabla funcionario_fichaje
    i_id_funcionario2 := 1;
    BEGIN
      SELECT distinct id_funcionario
        into i_id_funcionario2
        FROM funcionario_fichaje
       WHERE id_funcionario = I_ID_FUNCIONARIO
         and rownum < 2;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_id_funcionario2 := 0;
    END;

    --insertamos en la tabla si no esta.
    IF i_id_funcionario2 = 0 THEN
      Begin
        insert into funcionario_fichaje
          (id_funcionario,
           id_tipo_fichaje,
           id_usuario,
           fecha_modi,
           pin,
           codpers,
           pin2)
        values
          (i_id_funcionario,
           0,
           '101217',
           sysdate,
            pin1,
           lpad(v_codigo, 5, '0'), pin2);
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          i_inserta := 0;
      END;
     else

     BEGIN
        update funcionario_fichaje
           set codpers = lpad(v_codigo, 5, '0'),
            pin=PIN1,PIN2=PIN2
         where id_funcionario = I_ID_FUNCIONARIO
           and rownum < 2;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_id_funcionario2 := 0;
      END;
    END IF;

    --FICHAJES ALERTAS
    --Comprobamos esta en la tabla fichaje_funcionario_alertas
    i_id_funcionario2 := 1;
    BEGIN
      SELECT distinct id_funcionario
        into i_id_funcionario2
        FROM fichaje_funcionario_alerta
       WHERE id_funcionario = I_ID_FUNCIONARIO
         and rownum < 2;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_id_funcionario2 := 0;
    END;
    --insertamos en la tabla si no esta.
    IF i_id_funcionario2 = 0 THEN
      dbms_OUTPUT.PUT_LINE('Funcionario sin alertas ' || I_ID_FUNCIONARIO);
      Begin
        insert into fichaje_funcionario_alerta
          (id_funcionario,
           sin_alertas,
           alerta_0,
           alerta_1,
           alerta_2,
           alerta_3,
           alerta_4,
           alerta_5,
           alerta_6,
           alerta_7,
           alerta_8,
           alerta_9,
           alerta_10,
           alerta_11,
           alerta_12,
           alerta_13,
           alerta_14,
           alerta_15,
           audit_usuario,
           audit_fecha)
        values
          (I_ID_FUNCIONARIO,
           1,
           1,
           1,
           1,
           1,
           1,
           1,
           1,
           1,
           1,
           1,
           1,
           1,
           1,
           1,
           1,
           1

          ,
           101217,
           sysdate);

      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          i_inserta := 0;
      END;
    END IF;

    --FICHAJES JORNADA
    --Comprobamos esta en la tabla funcionario_fichaje
    i_id_funcionario2 := 1;
    BEGIN
      select distinct id_funcionario
        into i_id_funcionario2
        from FICHAJE_FUNCIONARIO_JORNADA
       where sysdate between fecha_inicio and nvl(fecha_fin, sysdate + 5)
         and id_funcionario = I_ID_FUNCIONARIO
         and rownum < 2;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_id_funcionario2 := 0;
    END;
    --insertamos en la tabla si no esta.
    IF i_id_funcionario2 = 0 THEN
      Begin
        dbms_OUTPUT.PUT_LINE('Funcionario sin jornada ' ||
                             I_ID_FUNCIONARIO);
        insert into fichaje_funcionario_jornada
          (id_funcionario,
           id_calendario,
           fecha_inicio,
           fecha_fin,
           horas_semanales,
           reduccion,
           horas_jornada,
           dias,
           contar_comida,
           libre,
           audit_usuario,
           audit_fecha,
           bolsa)
        values
          (I_id_funcionario,
           1,
           v_fecha_ingreso,
           V_fecha_fin_contrato,
           37,
           0,
           to_date('01/01/1900 7:00:00', 'dd/mm/yyyy hh24:mi:ss'),
          7,
           'NO',
           'SI',
           101217,
           sysdate,
           1);

      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          i_inserta := 0;
      END;
    END IF;

    --FICHAJE_FUNCIONARIO_RELOJ
    --Comprobamos esta en la tabla funcionario_fichaje
    i_id_funcionario2 := 1;
    BEGIN
      select distinct id_funcionario
        into i_id_funcionario2
        from FICHAJE_FUNCIONARIO_RELOJ
       where id_funcionario = I_ID_FUNCIONARIO
         and rownum < 2;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        i_id_funcionario2 := 0;
    END;
    --insertamos en la tabla si no esta.


    i_id_funcionario2 := 1;



        --INSERTAMOS EN LA TABLA DE OMESA
        BEGIN
          insert into persona
            (codigo,
             apellidos,
             nombre,
             dni,
             nss,
             telefono,
             domicilio,
             codpostal,
             poblacion,
             provincia,
             lugarnac,
             sexo,
             empresa,
             departamento,
             seccion,
             categoria,
             centro,
             situacion,
             altasn,
             horflex,
             calendario,
             semana,
             fechainicio,
             numtarjeta,
             ajustecierreautfich,
             fechabaja,
             vissalacu,
             cierrefich,
             incdiaact,
             cambioturno,
             tipofich,
             fechacambio,
             fechatomapos,
             numope,
             passwd,
             taqsn,
             trabsn,
             admsn,
             tag,
             tipcard,
             foto,
             ctacont,
             prefijo1,
             prefijo2,
             perfcal,
             perffes,
             saltargenpres,
             obsweb,
             facvalinci,
             huella,
             gesemp,
             resemp,
             usuemp,
             gesdep,
             resdep,
             usudep,
             gessec,
             ressec,
             ususec,
             gesneg,
             resneg,
             usuneg,
             gescen,
             rescen,
             usucen,
             telmovil,
             email,
             topeañoccursos,
             topeañocdedicacion,
             topeañochextra,
             topeañocotros1,
             topeañocotros2,
             obsgen,
             fecmod,
             sitant,
             sitnue,
             calidadpatron,
             numtarjeta2)
          values
            (lpad(v_codigo, 5, '0'),
             i_ape1 || ' ' || i_ape2,
             i_nombre,
             i_dni,
             '',
             '',
             '',
             '',
             '',
             '',
             '',
             'V',
             '000001',
             '000002',
             '000001',
             '00000000',
             '0000000000',
             '000001',
             '-1',
             '-1',
             '002',
             '1',
             to_date(to_char(sysdate + 1, 'dd/mm/yyyy'), 'dd/mm/yyyy'),
             PIN1,
             'O',
             i_fecha_baja,
             'S',
             'N',
             '',
             '0',
             '',
             '',
             '',
             '',
             v_fecha_nacimiento,--PASSWORD
             '0',
             '0',
             '0',
             '0',
             '',
             '',
             '',
             '',
             '',
             '',
             '',
             '0',
             '',
             '',
             '',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '',
             '',
             '0',
             '0',
             '0',
             '0',
             '0',
             '',
             '',
             '',
             '',
             '0',
             '');
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            i_inserta := 0;
        END;

         BEGIN
          insert into persona
            (codigo,
             apellidos,
             nombre,
             dni,
             nss,
             telefono,
             domicilio,
             codpostal,
             poblacion,
             provincia,
             lugarnac,
             sexo,
             empresa,
             departamento,
             seccion,
             categoria,
             centro,
             situacion,
             altasn,
             horflex,
             calendario,
             semana,
             fechainicio,
             numtarjeta,
             ajustecierreautfich,
             fechabaja,
             vissalacu,
             cierrefich,
             incdiaact,
             cambioturno,
             tipofich,
             fechacambio,
             fechatomapos,
             numope,
             passwd,
             taqsn,
             trabsn,
             admsn,
             tag,
             tipcard,
             foto,
             ctacont,
             prefijo1,
             prefijo2,
             perfcal,
             perffes,
             saltargenpres,
             obsweb,
             facvalinci,
             huella,
             gesemp,
             resemp,
             usuemp,
             gesdep,
             resdep,
             usudep,
             gessec,
             ressec,
             ususec,
             gesneg,
             resneg,
             usuneg,
             gescen,
             rescen,
             usucen,
             telmovil,
             email,
             topeañoccursos,
             topeañocdedicacion,
             topeañochextra,
             topeañocotros1,
             topeañocotros2,
             obsgen,
             fecmod,
             sitant,
             sitnue,
             calidadpatron,
             numtarjeta2)
          values
            ( '2' || SUBSTR(lpad(v_codigo, 5, '0'),2,4),
             i_ape1 || ' ' || i_ape2,
             i_nombre,
             i_dni,
             '',
             '',
             '',
             '',
             '',
             '',
             '',
             'V',
             '000001',
             '000002',
             '000001',
             '00000000',
             '0000000000',
             '000001',
             '-1',
             '-1',
             '002',
             '1',
             to_date(to_char(sysdate + 1, 'dd/mm/yyyy'), 'dd/mm/yyyy'),
             PIN2,
             'O',
             i_fecha_baja,
             'S',
             'N',
             '',
             '0',
             '',
             '',
             '',
             '',
             '',--PASSWORD
             '0',
             '0',
             '0',
             '0',
             '',
             '',
             '',
             '',
             '',
             '',
             '',
             '0',
             '',
             '',
             '',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '0',
             '',
             '',
             '0',
             '0',
             '0',
             '0',
             '0',
             '',
             '',
             '',
             '',
             '0',
             V_TARJETA);
        EXCEPTION
          WHEN DUP_VAL_ON_INDEX THEN
            i_inserta := 0;
        END;

        COMMIT;


      --POR SI ACASO ES NULO
      BEGIN
        update apliweb_usuario
           set id_fichaje = lpad(v_codigo, 5, '0')
         where id_funcionario = I_ID_FUNCIONARIO
           and rownum < 2
           and id_fichaje is null;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          i_id_funcionario2 := 0;
      END;

MERGE INTO horas_extras_ausencias h
USING (SELECT 2003 AS id_ano, i_id_funcionario AS id_funcionario FROM dual) src
ON (h.id_ano = src.id_ano AND h.id_funcionario = src.id_funcionario)
WHEN MATCHED THEN
  UPDATE SET h.total = 0, h.utilizadas = 0
WHEN NOT MATCHED THEN
  INSERT (id_ano, id_funcionario, total, utilizadas)
  VALUES (src.id_ano, src.id_funcionario, 0, 0);


commit;
END LOOP;
CLOSE C1;


end INSERTA_PERSONA_BOMBEROS_FINGER;
/

