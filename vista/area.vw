create or replace force view rrhh.area as
select id_unidad as id_area, desc_unidad as desc_area from unidad where length(id_unidad) = 5;

