create or replace force view rrhh.personal_anno_ingreso as
select 2018 as id_ano,count(*) as num_funcionario from personal where fecha_ingreso between to_date('01/01/2018','dd/mm/yyyy') and to_date('31/12/2018','dd/mm/yyyy')
union
select 2019 as id_ano,count(*) as num_funcionario from personal where fecha_ingreso between to_date('01/01/2019','dd/mm/yyyy') and to_date('31/12/2019','dd/mm/yyyy')
union
select 2020 as id_ano,count(*) as num_funcionario from personal where fecha_ingreso between to_date('01/01/2020','dd/mm/yyyy') and to_date('31/12/2020','dd/mm/yyyy')
union
select 2021 as id_ano,count(*) as num_funcionario from personal where fecha_ingreso between to_date('01/01/2021','dd/mm/yyyy') and to_date('31/12/2021','dd/mm/yyyy');

