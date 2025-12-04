CREATE OR REPLACE FORCE VIEW RRHH.PERSONAL_PLAZA_V AS
(
select DISTINCT  n.GRUPO,t.ID_PLAZA,N.NUM_PLAZA,
          OCUPADAS,
          LIBRES,
          TOTAL_PLAZAS,
          n.ID_ESCALA,
          n.DESC_ESCALA      ,
          n.ID_SUBESCALA ,
     n.DESC_SUBESCALA     ,
     n.ID_CLASE  ,
     n.DESC_CLASE,
     n.DESC_PLAZA   ,
     ID_FUNCIONARIO,
     NOMBRE, t.natuplaz as contratacion
  FROM (
   select    pe.natuplaz,
             sum(DECODE(decode(FFINPLAZ,NULL,ID_FUNCIONARIO,NULL),NULL,0,1 )) OCUPADAS,
             sum(DECODE(decode(FFINPLAZ,NULL,ID_FUNCIONARIO,NULL),NULL,1,0 )) LIBRES,
             SUM(1) as TOTAL_PLAZAS,
     PE.ID_PLAZA
   from      personal_plaza pe ,
       (SELECT natuplaz,id_plaza,num_plaza,max(versfase) as versfase from personal_plaza group by natuplaz,id_plaza,num_plaza) pma
  where  pe.id_plaza=pma.id_plaza and pe.num_plaza=pma.num_plaza and pe.versfase=pma.versfase and
            pe.natuplaz=pma.natuplaz and (pe.fechaeli > sysdate OR pe.fechaeli is null )
  group by   pe.natuplaz,PE.ID_PLAZA
      ) T,
  ( select distinct pe.codigrup as GRUPO ,
             p.ID_FUNCIONARIO,
     DECODE(NOMBRE,NULL,'VACANTE',NOMBRE) as NOMBRE,PE.NUM_PLAZA,
     PE.ID_ESCALA,
     DESC_ESCALA      ,
     PE.ID_SUBESCALA as ID_SUBESCALA,
     DESC_SUBESCALA     ,
     PE.ID_CLASE   as ID_CLASE,
     DESC_CLASE,
     PA.ID_PLAZA as ID_PLAZA  ,
     PA.DESC_PLAZA,pe.natuplaz
   from      personal_plaza pe ,
     plaza_escala e,
     plaza_subescala se ,
     plaza_clase c,PLAZA_PLAZA pa,
          (SELECT DISTINCT ID_FUNCIONARIO, APE1 || ' ' || APE2 || ' ' || NOMBRE AS NOMBRE, CONTRATACION, FECHA_BAJA FROM PERSONAL WHERE      CONTRATACION IS         NOT NULL AND (FECHA_BAJA IS NULL  OR FECHA_BAJA>SYSDATE)) P,
       (SELECT natuplaz,id_plaza,num_plaza,max(versfase) as versfase from personal_plaza group by natuplaz,id_plaza,num_plaza) pma
 where  pe.id_escala=e.id_Escala and
         pe.id_subescala=se.id_subescala(+) and
         pe.id_clase=c.id_clase(+)  and
         pe.id_plaza=pa.id_plaza and
         pe.id_plaza=pma.id_plaza and pe.num_plaza=pma.num_plaza and pe.versfase=pma.versfase and
         pe.natuplaz=pma.natuplaz and
         pe.id_funcionario=p.id_funcionario(+) and (pe.fechaeli > sysdate OR pe.fechaeli is null ) ) N
  where  t.id_plaza=n.id_plaza and n.natuplaz=t.natuplaz
);

