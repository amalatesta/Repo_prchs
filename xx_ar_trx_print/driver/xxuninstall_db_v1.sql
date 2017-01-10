REM +=======================================================================+
REM |  Copyright (c) 2017 Oracle Corporation, Buenos Aires, Argentina       |
REM |                         ALL rights reserved.                          |
REM +=======================================================================+
REM |                                                                       |
REM | FILENAME                                                              |
REM |     xxuninstall_db_v1.sql                                             |
REM |                                                                       |
REM | DESCRIPTION                                                           |
REM |     Script de desinstalacion de customizacion.                        |
REM |                                                                       |
REM | HISTORY                                                               |
REM |     03-ENE-2017 - 1.0 - AMalatesta - DSP - Created                    |
REM |                                                                       |
REM +=======================================================================|

spool xxuninstall_db_v1.log

prompt  '====================================================================='
prompt  'Script xxuninstall_db_v1.sql'
prompt  '====================================================================='

accept base prompt 'Ingrese el nombre de la base de datos: '
accept apps_pwd prompt 'Ingrese la clave del usuario APPS: ' hide

connect apps/&apps_pwd@&base
show user

select name base_de_datos from v$database;

select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') inicio from dual;

accept p_draft_mode prompt 'Modo Draft (Default Y): '
accept p_xml_template prompt 'Elimina plantillas XML (Default N): '
accept p_xml_data prompt 'Elimina definiciones de datos XML (Default N): '
accept p_cnc prompt 'Elimina Concurrentes (Default N): '
accept p_exe prompt 'Elimina Ejecutables (Default N): '

set feed off
set verify off

prompt Eliminando plantilla xml
set serveroutput on size 1000000
declare
  cursor del is
    select xtb.application_short_name
          ,xtb.template_code
          ,xtb.template_name
    from   xdo_templates_tl xtt
          ,xdo_templates_b  xtb
    where  1=1
    and    xtb.template_code                 = xtt.template_code
    and    xtb.template_code                 = 'XXRAXINV_CL_RN'
    and    xtb.language                      = 'ESA'
    and    upper(nvl('&p_xml_template','N')) = 'Y'
    order by xtb.template_code;
begin
  for i in del loop
    dbms_output.put_line('Eliminando plantilla XML: ' || i.template_code);
    dbms_output.put_line('Con nombre de programa: ' || i.template_name);
    begin
      xdo_templates_pkg.delete_row(x_application_short_name => i.application_short_name
                                  ,x_template_code          => i.template_code);
    exception
      when others then
        raise_application_error(-20000,nvl(fnd_program.message,sqlerrm));
    end;
  end loop;
end;
/











prompt Eliminando los concurrentes
set serveroutput on size 1000000
declare
  cursor del is
    select fa.application_short_name
          ,fcp.concurrent_program_name
          ,fcpt.user_concurrent_program_name
    from   fnd_concurrent_programs_tl fcpt
          ,fnd_concurrent_programs    fcp
          ,fnd_application            fa
    where  1 = 1
    and    fa.application_id           = fcp.application_id
    and    fcp.concurrent_program_id   = fcpt.concurrent_program_id
    and    fcpt.language               = 'ESA'
    and    fcp.concurrent_program_name = 'XXRAXINV_CL_RN'
    and    upper(nvl('&p_cnc','N'))    = 'Y'
    order by fcp.concurrent_program_name;
begin
  for cd in del loop
    dbms_output.put_line('Eliminando abreviatura de concurrente: ' || cd.concurrent_program_name);
    dbms_output.put_line('Con nombre de programa: ' || cd.user_concurrent_program_name);
    begin
      fnd_program.delete_program
         (program_short_name => cd.concurrent_program_name
         ,application        => cd.application_short_name
         );
    exception
      when others then
        raise_application_error(-20000,nvl(fnd_program.message,sqlerrm));
    end;
  end loop;
end;
/

prompt Eliminando los ejecutables
set serveroutput on size 1000000
declare
  cursor del is
    select fa.application_short_name
          ,fe.executable_name
          ,fet.user_executable_name
    from   fnd_executables_tl fet
          ,fnd_executables    fe
          ,fnd_application    fa
    where  1 = 1
    and    fa.application_id  = fe.application_id
    and    fe.executable_id   = fet.executable_id
    and    fet.language       = 'ESA'
    and    fe.executable_name = 'XXRAXINV_CL_RN'
    and    upper(nvl('&p_exe','N')) = 'Y'
    order by fe.executable_name;
begin
  for cd in del loop
    dbms_output.put_line('Eliminando abreviatura de ejecutable: ' || cd.executable_name);
    dbms_output.put_line('Con nombre de programa: ' || cd.user_executable_name);
    begin
      fnd_program.delete_executable
         (executable_short_name => cd.executable_name
         ,application           => cd.application_short_name
         );
    exception
      when others then
        raise_application_error(-20000,nvl(fnd_program.message,sqlerrm));
    end;
  end loop;
end;
/

prompt Confirmando o cancelando los cambios
begin
  if upper(nvl('&p_draft_mode','Y')) = 'N' then
    dbms_output.put_line('Confirmando cambios');
    commit;
  else
    dbms_output.put_line('Cancelando cambios');
    rollback;
  end if;
exception
  when others then
    raise_application_error(-20000,nvl(fnd_program.message,sqlerrm));
end;
/

set feed on
set verify on

select to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') fin from dual;

spool off

exit
