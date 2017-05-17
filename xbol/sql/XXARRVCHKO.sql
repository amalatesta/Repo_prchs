-- 
--  Copyright (c) 2017 Despegar.com
--  This program contains proprietary and confidential information.
--  All rights reserved except as may be permitted by prior
--  written consent.
-- 
--  File Name: XXARRVCHKO.sql
--  Attribute Label: XXAR
-- 
--  Description: 
-- 
--  Modification History:
--     17-MAY-2017 - Amalatesta - Created
-- 
-- parameters :
--
-- inputs     :
-- 
-- outputs    :
-- 
--  platform   os  : Red Hat Enterprise Linux Server release 6.2 (Santiago) x86_64
--  platform - h/w : AMD Opteron(tm) Processor 6376 x 8
-- 
--  database      : Oracle Database 11g Enterprise Edition Release 11.2.0.3.0 - 64bit Production
--  apps. Release : Oracle Applications (module name) 12.1.3
-- 
--------------------------------------------------------------------------------
-- date        author                            description 
-- ----------- --------------------------------- -------------------------------
-- 17-MAY-2017 AMALATESTA [Despegar]              Created - 
-- *****************************************************************************
set serveroutput on size 1000000
whenever sqlerror exit failure
whenever oserror exit failure rollback
set verify off

declare
  cursor c_data
  -- ---------------------------------------------------------------------------
  -- Parametros de programa.
  -- ---------------------------------------------------------------------------
  p_calling_sequence varchar2(32767) := '&&1';
  p_message_length   number          := '&&2';
  p_debug_mode       varchar2(32767) := '&&3';
  p_debug_flag       varchar2(32767) := '&&4';
  p_char_delim       varchar2(32767) := '&&5';
  -- ---------------------------------------------------------------------------
  -- Definicion de variables.
  -- ---------------------------------------------------------------------------
  v_calling_sequence   varchar2(32767);
  v_debug_mode         varchar2(32767);
  v_debug_flag         varchar2(32767);
  v_request_id         number;
  v_mesg_error         varchar2(32767);
  v_indent             varchar2(32767) := '';
  /*--------------------------------------------------------------------------*/
  /*indent                                                                    */
  /*--------------------------------------------------------------------------*/
  procedure indent
    (p_type in varchar2)
  is
    v_calling_sequence varchar2(32767);
    v_indent_length    number;
  begin
    v_calling_sequence := 'XXARRVCHKO.INDENT_PRC';
    v_indent_length := 3;
    if p_type = '+' then
       v_indent := replace(rpad(' ',nvl(length(v_indent),0)+v_indent_length),' ',' ');
    elsif p_type = '-' then
       v_indent := replace(rpad(' ',nvl(length(v_indent),0)-v_indent_length),' ',' ');
    end if;
  exception
    when others then
      raise_application_error(-20000,v_calling_sequence||'. Error general indentando linea. '||sqlerrm);
  end indent;
  /*--------------------------------------------------------------------------*/
  /*display_message_split                                                     */
  /*--------------------------------------------------------------------------*/
  procedure display_message_split
    (p_output  in      varchar2
    ,p_message in      varchar2)
  is
    v_calling_sequence varchar2(32767);
    v_cnt              number;
    v_message_length   number;
    v_message          varchar2(32767);
  begin
    v_calling_sequence := 'XXARRVCHKO.DISPLAY_MESSAGE_SPLIT';
    v_message_length   := p_message_length;
    if p_output         = 'DBMS' and
       g_message_length > 255    then
       v_message_length := 255;
    end if;
    for v_cnt in 1..40000/v_message_length loop
        v_message := null;
        if v_cnt = 1 then
           if length(p_message) >= v_cnt * v_message_length then
              v_message := substr(p_message,1,v_cnt * v_message_length);
           else
              if length(p_message) >= 1                        and
                 length(p_message) <  v_cnt * v_message_length then
                 v_message := substr(p_message,1);
              end if;
           end if;
        else
           if length(p_message) >= v_cnt * v_message_length then
              v_message := substr(p_message,((v_cnt-1) * v_message_length) + 1,v_message_length);
           else
              if length(p_message) >= ((v_cnt-1) * v_message_length) and
                 length(p_message) <    v_cnt    * v_message_length  then
                 v_message := substr(p_message,((v_cnt-1) * v_message_length) + 1);
              end if;
           end if;
        end if;
        v_message := ltrim(rtrim(v_message));
        if v_message is not null then
           if p_output = 'DBMS' then
              dbms_output.put_line(v_message);
           elsif p_output = 'CONC_LOG' then
              fnd_file.put(fnd_file.log,v_message);
              fnd_file.new_line(fnd_file.log,1);
           end if;
        end if;
    end loop;
  exception
    when others then
      raise_application_error(-20000,v_calling_sequence||'. Error general indentando linea. '||sqlerrm);
  end display_message_split;
  /*--------------------------------------------------------------------------*/
  /*debug                                                                     */
  /*--------------------------------------------------------------------------*/
  procedure debug
    (p_message in      varchar2
    ,p_type    in      varchar2 default null)
  is
    v_calling_sequence varchar2(32767);
    v_message          varchar2(32767);
  begin
    v_calling_sequence := 'XXARRVCHKO.DEBUG';
    if v_debug_flag = 'Y' then
       if p_type is null then
          v_message := substr(p_message,1,32767);
       else
          v_message := substr(to_char(sysdate,'DD-MM-YYYY HH24:MI:SS')||' - '||p_message,1,32767);
       end if;
       display_message_split(p_output=>v_debug_mode,p_message=>v_message);
    end if;
  exception
    when others then
      null;
  end debug;
begin
  -- ---------------------------------------------------------------------------
  -- Inicializo variables Grales de Ejecucion.
  -- ---------------------------------------------------------------------------
  v_calling_sequence   := p_calling_sequence; --'XXARRVCHKO.REV_X_CHECKOUT';
  v_request_id         := fnd_global.conc_request_id;
  -- ---------------------------------------------------------------------------
  -- Inicializo el debug.
  -- ---------------------------------------------------------------------------
  v_debug_flag     := upper(nvl(p_debug_flag,'N'));
  v_debug_mode     := p_debug_mode; --'CONC_LOG';
  debug(v_indent||v_calling_sequence,'1');
  -- ---------------------------------------------------------------------------
  -- Despliego Parametros.
  -- ---------------------------------------------------------------------------
  debug(v_indent||v_calling_sequence||'. Identificacion programa: '||p_calling_sequence,'1');
  debug(v_indent||v_calling_sequence||'. Ancho de mensajes: '||p_message_length,'1');
  debug(v_indent||v_calling_sequence||'. Modo de Debug: '||p_debug_mode,'1');
  debug(v_indent||v_calling_sequence||'. Flag de Debug: '||p_debug_flag,'1');
  debug(v_indent||v_calling_sequence||'. Inicio de proceso','1');
  debug(v_indent||v_calling_sequence||'. Fin de proceso','1');
exception
  when others then
    v_mesg_error := 'Error general generando la salida. '||sqlerrm;
    debug(v_calling_sequence||'. '||v_mesg_error,'1');
    fnd_file.put(fnd_file.log,v_indent||v_calling_sequence||'. '||v_mesg_error);
    fnd_file.new_line(fnd_file.log,1);
end;
/
