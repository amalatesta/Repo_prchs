REM +=======================================================================+
REM |    Copyright (c) 1997 Oracle Argentina, Buenos Aires                  |
REM |                         All rights reserved.                          |
REM +=======================================================================+
REM | FILENAME                                                              |
REM |    XXDIR_XX_AR_TRX_PE_OUT_PRC_DIR.sql                                 |
REM |                                                                       |
REM | DESCRIPTION                                                           |
REM |    Crea los directorios.                                              |
REM |                                                                       |
REM | LANGUAGE                                                              |
REM |    PL/SQL                                                             |
REM |                                                                       |
REM | PRODUCT                                                               |
REM |    Oracle Financials                                                  |
REM |                                                                       |
REM | HISTORY                                                               |
REM |    26-MAY-17  DSP-AMalatesta        Created                           |
REM |                                                                       |
REM | NOTES                                                                 |
REM |                                                                       |
REM +=======================================================================+

spool xxdir_xx_ar_trx_pe_out_prc_dir.log

prompt =====================================================================    
prompt SCRIPT XXDIR_XX_AR_TRX_PE_OUT_PRC_DIR.sql
prompt =====================================================================    

prompt Creando directorio XX_AR_TRX_PE_OUT_PRC_DIR
create or replace directory xx_ar_trx_pe_out_prc_dir as '/utldir/fact_elec/OU_301/out_etkt';

prompt Asignando permisos del directorio XX_AR_TRX_PE_OUT_PRC_DIR a BOLINF
grant all on directory xx_ar_trx_pe_out_prc_dir to bolinf;

prompt Asignando permisos java sobre los directorios
set serveroutput on size 1000000
declare
  cursor dir_customs
  is
    select directory_name
          ,directory_path
    from   dba_directories
    where  upper(directory_name) like 'XX_AR_TRX_PE_OUT_%DIR'
    order by directory_name;
begin
  for cdc in dir_customs
  loop
    dbms_output.put_line('Asignando permisos java sobre el directorio: ' || cdc.directory_path);
    begin
      dbms_java.grant_permission('APPS','SYS:java.io.FilePermission',cdc.directory_path||'/','read ,write, execute, delete');
    exception
      when others then
        dbms_output.put_line(substr(sqlerrm,1,250));
    end;
    begin
      dbms_java.grant_permission('APPS','SYS:java.io.FilePermission',cdc.directory_path||'/*','read ,write, execute, delete');
    exception
      when others then
        dbms_output.put_line(substr(sqlerrm,1,250));
    end;
  end loop;
end;
/

spool off

exit;
