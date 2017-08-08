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
REM |     06-ENE-2017 - 1.0 - AMalatesta - DSP - Created                    |
REM |                                                                       |
REM +=======================================================================|

SPOOL xxuninstall_db_v1.log

PROMPT  '====================================================================='
PROMPT  'Script xxuninstall_db_v1.sql'
PROMPT  '====================================================================='

ACCEPT base PROMPT 'Ingrese el nombre de la base de datos: '
ACCEPT apps_pwd PROMPT 'Ingrese la clave del usuario APPS: ' HIDE

CONNECT apps/&apps_pwd@&base
SHOW USER

SELECT name base_de_datos FROM v$database;

SELECT TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS') Inicio FROM dual;

ACCEPT p_draft_mode PROMPT 'Modo Draft (Default Y): '
ACCEPT p_cnc PROMPT 'Elimina Concurrentes (Default N): '
ACCEPT p_exe PROMPT 'Elimina Ejecutables (Default N): '

SET FEED OFF
SET VERIFY OFF

PROMPT Eliminando los Concurrentes
SET SERVEROUTPUT ON SIZE 1000000
DECLARE
  CURSOR del IS
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
    and    fcp.concurrent_program_name = 'XXZXCLRSLL'
    and    upper(nvl('&p_cnc','N'))    = 'Y'
    order by fcp.concurrent_program_name;
BEGIN
  FOR cd IN del LOOP
    dbms_output.put_line('Eliminando abreviatura de concurrente: ' || cd.concurrent_program_name);
    dbms_output.put_line('Con nombre de programa: ' || cd.user_concurrent_program_name);
    BEGIN
      fnd_program.delete_program
         (program_short_name => cd.concurrent_program_name
         ,application        => cd.application_short_name
         );
    EXCEPTION
      WHEN others THEN
        RAISE_APPLICATION_ERROR(-20000,NVL(fnd_program.message,SQLERRM));
    END;
  END LOOP;
END;
/


PROMPT Eliminando los Ejecutables
SET SERVEROUTPUT ON SIZE 1000000
DECLARE
  CURSOR del IS
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
    and    fe.executable_name = 'XXZXARRECV'
    and    upper(nvl('&p_exe','N')) = 'Y'
    order by fe.executable_name;
BEGIN
  FOR cd IN del LOOP
    dbms_output.put_line('Eliminando abreviatura de ejecutable: ' || cd.executable_name);
    dbms_output.put_line('Con nombre de programa: ' || cd.user_executable_name);
    BEGIN
      fnd_program.delete_executable
         (executable_short_name => cd.executable_name
         ,application           => cd.application_short_name
         );
    EXCEPTION
      WHEN others THEN
        RAISE_APPLICATION_ERROR(-20000,NVL(fnd_program.message,SQLERRM));
    END;
  END LOOP;
END;
/

PROMPT Confirmando o cancelando los cambios
BEGIN
  IF UPPER(NVL('&p_draft_mode','Y')) = 'N' THEN
    dbms_output.put_line('Confirmando cambios');
    COMMIT;
  ELSE
    dbms_output.put_line('Cancelando cambios');
    ROLLBACK;
  END IF;
EXCEPTION
  WHEN others THEN
    RAISE_APPLICATION_ERROR(-20000,NVL(fnd_program.message,SQLERRM));
END;
/

SET FEED ON
SET VERIFY ON

SELECT TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS') Fin FROM dual;

SPOOL OFF

EXIT
