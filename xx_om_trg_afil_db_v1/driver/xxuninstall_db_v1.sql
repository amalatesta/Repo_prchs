REM +=======================================================================+
REM |  Copyright (c) 2016 Oracle Corporation, Buenos Aires, Argentina       |
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
REM |     09-NOV-2016    AMalatesta         Created                         |
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
ACCEPT p_cnc PROMPT 'Elimina triggers (Default N): '

SET FEED OFF
SET VERIFY OFF

PROMPT Eliminando los triggers
SET SERVEROUTPUT ON SIZE 1000000

declare 
  l_count integer;
begin
  select count(*)
  into   l_count
  from   all_triggers
  where  1=1
  and    owner            = 'APPS'
  and    table_owner      = 'BOLINF'
  and    table_name       = 'XX_OM_SALES'
  and    triggering_event = 'INSERT'
  and    trigger_name     = 'TRG_EXPEDIA_PAY';
  if l_count > 0 then
    if upper(nvl('&p_draft_mode','Y')) = 'N' then
      dbms_output.put_line('Se elimina el trigger TRG_EXPEDIA_PAY');
      execute immediate 'DROP TRIGGER APPS.TRG_EXPEDIA_PAY';
    else
      dbms_output.put_line('Ejecucion en modo draft. No se elimina el trigger TRG_EXPEDIA_PAY');
    end if;
  else
    dbms_output.put_line('No se encontro el trigger TRG_EXPEDIA_PAY');
  end if;
exception
  when others then
    raise_application_error(-20000,nvl(fnd_program.message,sqlerrm));
end;
/
declare 
  l_count integer;
begin
  select count(*)
  into   l_count
  from   all_triggers
  where  1=1
  and    owner            = 'APPS'
  and    table_owner      = 'BOLINF'
  and    table_name       = 'XX_OM_SALES'
  and    triggering_event = 'INSERT'
  and    trigger_name     = 'TRG_AVANTRIP';
  if l_count > 0 then
    if upper(nvl('&p_draft_mode','Y')) = 'N' then
      dbms_output.put_line('Se elimina el trigger TRG_AVANTRIP');
      execute immediate 'DROP TRIGGER APPS.TRG_AVANTRIP';
    else
      dbms_output.put_line('Ejecucion en modo draft. No se elimina el trigger TRG_AVANTRIP');
    end if;
  else
    dbms_output.put_line('No se encontro el trigger TRG_AVANTRIP');
  end if;
exception
  when others then
    raise_application_error(-20000,nvl(fnd_program.message,sqlerrm));
end;
/
declare 
  l_count integer;
begin
  select count(*)
  into   l_count
  from   all_triggers
  where  1=1
  and    owner            = 'APPS'
  and    table_owner      = 'BOLINF'
  and    table_name       = 'XX_OM_SALES'
  and    triggering_event = 'INSERT'
  and    trigger_name     = 'TRG_HOTUSA';
  if l_count > 0 then
    if upper(nvl('&p_draft_mode','Y')) = 'N' then
      dbms_output.put_line('Se elimina el trigger TRG_HOTUSA');
      execute immediate 'DROP TRIGGER APPS.TRG_HOTUSA';
    else
      dbms_output.put_line('Ejecucion en modo draft. No se elimina el trigger TRG_HOTUSA');
    end if;
  else
    dbms_output.put_line('No se encontro el trigger TRG_HOTUSA');
  end if;
exception
  when others then
    raise_application_error(-20000,nvl(fnd_program.message,sqlerrm));
end;
/
declare 
  l_count integer;
begin
  select count(*)
  into   l_count
  from   all_triggers
  where  1=1
  and    owner            = 'APPS'
  and    table_owner      = 'BOLINF'
  and    table_name       = 'XX_OM_SALES'
  and    triggering_event = 'INSERT'
  and    trigger_name     = 'TRG_GARBARINO';
  if l_count > 0 then
    if upper(nvl('&p_draft_mode','Y')) = 'N' then
      dbms_output.put_line('Se elimina el trigger TRG_GARBARINO');
      execute immediate 'DROP TRIGGER APPS.TRG_GARBARINO';
    else
      dbms_output.put_line('Ejecucion en modo draft. No se elimina el trigger TRG_GARBARINO');
    end if;
  else
    dbms_output.put_line('No se encontro el trigger TRG_GARBARINO');
  end if;
exception
  when others then
    raise_application_error(-20000,nvl(fnd_program.message,sqlerrm));
end;
/

SET FEED ON
SET VERIFY ON

SELECT TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS') Fin FROM dual;

SPOOL OFF

EXIT
