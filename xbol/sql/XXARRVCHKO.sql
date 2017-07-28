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
-- 26-JUN-2017 AMALATESTA [Despegar]              Modified - Adding gateway and logical by hotel for Flag Not Reimbursement
-- 21-JUL-2017 AMALATESTA [Despegar]              Modified - Adding logical conditions for segments accounts
-- 28-JUL-2017 AMALATESTA [Despegar]              Modified - Adding new parameters for creation date field
-- *****************************************************************************
set serveroutput on size 1000000
whenever sqlerror exit failure
whenever oserror exit failure rollback
set verify off

declare
  cursor c_data_print (cp_org_id             ar.ra_customer_trx_all.org_id%type
                      ,cp_creation_date_from ar.ra_customer_trx_all.creation_date%type
                      ,cp_creation_date_to   ar.ra_customer_trx_all.creation_date%type
                      ,cp_attribute8         ar.ra_customer_trx_lines_all.attribute8%type
                      ,cp_prod_excl_code     applsys.fnd_descr_flex_contexts.descriptive_flex_context_code%type)
  is
    select rct.purchase_order
          ,rctl.attribute9
          ,rctl.attribute8
          ,nvl((select max(pl.attribute12)
                from   po.po_headers_all ph
                      ,po.po_lines_all   pl
                where  ph.po_header_id       = pl.po_header_id
                and    ph.reference_num      = rct.purchase_order
                and    pl.attribute_category = '0002'),
               (select max(pl.attribute12)
                from   po.po_headers_all ph
                      ,po.po_lines_all   pl
                where  ph.po_header_id       = pl.po_header_id
                and    ph.reference_num      = rct.purchase_order)) attribute12
          ,rctl.attribute11
          ,rct.invoice_currency_code
          ,sum(rctl.extended_amount) extended_amount
          ,rct.attribute7
          ,gcc.segment1
          ,gcc.segment2
          ,gcc.segment3
          ,gcc.segment4
          ,gcc.segment5
          ,gcc.segment6
          ,gcc.segment7
          ,gcc.segment8
          ,gcc.segment9
          ,gcc.segment10
          ,gcc.segment11
    from   gl.gl_code_combinations         gcc
          ,ar.ra_cust_trx_line_gl_dist_all rctlgd
          ,ar.ra_cust_trx_types_all        rctt
          ,ar.ra_customer_trx_all          rct
          ,ar.ra_customer_trx_lines_all    rctl
    where  rctl.customer_trx_id       = rct.customer_trx_id
    and    rct.cust_trx_type_id       = rctt.cust_trx_type_id
    and    rctl.customer_trx_line_id  = rctlgd.customer_trx_line_id
    and    rctlgd.code_combination_id = gcc.code_combination_id
    and    rctl.org_id                = rct.org_id
    and    rctl.org_id                = rctl.org_id
    and    rctl.org_id                = rctt.org_id
    and    rctl.org_id                = nvl(cp_org_id,rctl.org_id)
    and    exists                      (select 1
                                        from   applsys.fnd_descr_flex_contexts fdfc
                                        where  fdfc.descriptive_flexfield_name    = 'RA_CUSTOMER_TRX'
                                        and    fdfc.application_id                = 222
                                        and    nvl(fdfc.global_flag,'N')          = 'N'
                                        and    fdfc.descriptive_flex_context_code != nvl(cp_prod_excl_code,fdfc.descriptive_flex_context_code)
                                        and    fdfc.descriptive_flex_context_code = rct.attribute_category)
    and    exists                      (select 1
                                        from   applsys.fnd_descr_flex_contexts fdfc
                                        where  fdfc.descriptive_flexfield_name    = 'RA_CUSTOMER_TRX_LINES'
                                        and    fdfc.application_id                = 222
                                        and    nvl(fdfc.global_flag,'N')          = 'N'
                                        and    fdfc.descriptive_flex_context_code != nvl(cp_prod_excl_code,fdfc.descriptive_flex_context_code)
                                        and    fdfc.descriptive_flex_context_code = rctl.attribute_category)
    and    gcc.segment2               in ('41100'
                                         ,'44010'
                                         ,'44090'
                                         ,'41500'
                                         ,'41103'
                                         ,'44011')
    and    gcc.segment9               in ('20','30')
    and    gcc.segment5               != '101'
    and    gcc.segment5               != '102'
    and    rctl.attribute8            > nvl(cp_attribute8,rctl.attribute8)
    and    rct.creation_date          > nvl(cp_creation_date_from,(rct.creation_date-(1/86400)))
    and    rct.creation_date          < nvl(cp_creation_date_to,(rct.creation_date+1))
    group by rct.org_id
            ,rct.purchase_order
            ,rctl.attribute11
            ,rct.invoice_currency_code
            ,rct.attribute7
            ,rctl.attribute9
            ,rctl.attribute8
            ,gcc.segment1
            ,gcc.segment2
            ,gcc.segment3
            ,gcc.segment4
            ,gcc.segment5
            ,gcc.segment6
            ,gcc.segment7
            ,gcc.segment8
            ,gcc.segment9
            ,gcc.segment10
            ,gcc.segment11;
  -- ---------------------------------------------------------------------------
  -- Parametros de programa.
  -- ---------------------------------------------------------------------------
  p_op_unit        number          := '&&1';
  p_date_from      date            := to_date('&&2','YYYY/MM/DD HH24:MI:SS');
  p_date_to        date            := to_date('&&3','YYYY/MM/DD HH24:MI:SS');
  p_date_chk_out   varchar2(32767) := '&&4';
  p_prod_excl_code varchar2(32767) := '&&5';
  p_debug_flag     varchar2(32767) := '&&6';
  p_char_delim     varchar2(32767) := '&&7';
  -- ---------------------------------------------------------------------------
  -- Definicion de variables.
  -- ---------------------------------------------------------------------------
  v_dummy      boolean;
  /*--------------------------------------------------------------------------*/
  /*print_trace                                                               */
  /*--------------------------------------------------------------------------*/
  procedure print_trace
    (p_debug in varchar2
    ,p_str   in varchar2)
  is
  begin
    if p_debug='Y' then
      fnd_file.put_line(fnd_file.log,to_char(sysdate,'"["dd/mm/yyyy" - "HH24:MI:SS"] - ') || p_str);
    end if;
  end print_trace;
  /*--------------------------------------------------------------------------*/
  /*print_output                                                              */
  /*--------------------------------------------------------------------------*/
  procedure print_output
    (p_debug in varchar2
    ,p_str   in varchar2)
  is
  begin
    fnd_file.put_line(fnd_file.output,p_str);
  end print_output;
  /*--------------------------------------------------------------------------*/
  /*print_header                                                              */
  /*--------------------------------------------------------------------------*/
  procedure print_header
    (p_debug     in varchar2
    ,p_chardelim in varchar2)
  is
  begin
    print_output(p_debug=>p_debug_flag
                ,p_str=>'Reserva'
                ||p_chardelim||'Fecha Emision'
                ||p_chardelim||'Fecha Checkout'
                ||p_chardelim||'Reembolsable'
                ||p_chardelim||'Gateway'
                ||p_chardelim||'Moneda'
                ||p_chardelim||'Total'
                ||p_chardelim||'Tasa a Dolar'
                ||p_chardelim||'Entidad legal'
                ||p_chardelim||'Cuenta'
                ||p_chardelim||'Subcuenta'
                ||p_chardelim||'Responsable del Cargo'
                ||p_chardelim||'Producto'
                ||p_chardelim||'Departamento'
                ||p_chardelim||'Canal'
                ||p_chardelim||'Tipo de Cliente'
                ||p_chardelim||'Tipo de Cobro'
                ||p_chardelim||'Negocio'
                ||p_chardelim||'Futuro 2');
  end print_header;
/*----------------------------------------------------------------------------*/
/*Main                                                                        */
/*----------------------------------------------------------------------------*/
begin
  print_trace(p_debug=>p_debug_flag,p_str=>'--Begin');
  print_trace(p_debug=>p_debug_flag,p_str=>'--  Parametros(+)');
  print_trace(p_debug=>p_debug_flag,p_str=>'--    1-p_op_unit........: '||p_op_unit||'.');
  print_trace(p_debug=>p_debug_flag,p_str=>'--    2-p_date_from......: '||p_date_from||'.');
  print_trace(p_debug=>p_debug_flag,p_str=>'--    3-p_date_to........: '||p_date_to||'.');
  print_trace(p_debug=>p_debug_flag,p_str=>'--    4-p_date_chk_out...: '||p_date_chk_out||'.');
  print_trace(p_debug=>p_debug_flag,p_str=>'--    5-p_prod_excl_code.: '||p_prod_excl_code||'.');
  print_trace(p_debug=>p_debug_flag,p_str=>'--    6-p_debug..........: '||p_debug_flag||'.');
  print_trace(p_debug=>p_debug_flag,p_str=>'--    7-p_char_delim.....: '||p_char_delim||'.');
  print_trace(p_debug=>p_debug_flag,p_str=>'--  Parametros(-)');
  print_trace(p_debug=>p_debug_flag,p_str=>'--  print_header(+)');
  print_header(p_debug=>p_debug_flag,p_chardelim=>p_char_delim);
  print_trace(p_debug=>p_debug_flag,p_str=>'--  print_header(-)');
  print_trace(p_debug=>p_debug_flag,p_str=>'--  Loop_OU_PRT (+)');
  for c_data in c_data_print(cp_org_id             => p_op_unit
                            ,cp_creation_date_from => (p_date_from-(1/86400))
                            ,cp_creation_date_to   => (p_date_to+1)
                            ,cp_attribute8         => p_date_chk_out
                            ,cp_prod_excl_code     => p_prod_excl_code)
  loop
    print_output(p_debug=>p_debug_flag
                ,p_str=>c_data.purchase_order
                ||p_char_delim||c_data.attribute9
                ||p_char_delim||c_data.attribute8
                ||p_char_delim||c_data.attribute12
                ||p_char_delim||c_data.attribute11
                ||p_char_delim||c_data.invoice_currency_code
                ||p_char_delim||c_data.extended_amount
                ||p_char_delim||c_data.attribute7
                ||p_char_delim||c_data.segment1
                ||p_char_delim||c_data.segment2
                ||p_char_delim||c_data.segment3
                ||p_char_delim||c_data.segment4
                ||p_char_delim||c_data.segment5
                ||p_char_delim||c_data.segment6
                ||p_char_delim||c_data.segment7
                ||p_char_delim||c_data.segment8
                ||p_char_delim||c_data.segment9
                ||p_char_delim||c_data.segment10
                ||p_char_delim||c_data.segment11);
  end loop;
  print_trace(p_debug=>p_debug_flag,p_str=>'--  Loop_OU_PRT (-)');
  print_trace(p_debug=>p_debug_flag,p_str=>'--End');
exception
  when others then
    fnd_file.put_line(fnd_file.output,'Error.: '||sqlerrm);
    fnd_file.put_line(fnd_file.log,'Error.: '||sqlerrm);
    v_dummy := fnd_concurrent.set_completion_status('ERROR','Unknown error, please check the log...');
end;
/
