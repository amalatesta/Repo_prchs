-- 
--  Copyright (c) 2016 Despegar.com
--  This program contains proprietary and confidential information. 
--  All rights reserved except as may be permitted by prior 
--  written consent. 
-- 
--  File Name: XXGLMYPN.sql
--  Attribute Label: XXGL
-- 
--  Description: XX GL Reporte Mayor con cuenta PUC detalle NIT
-- 
--  Modification History:
--     15-NOV-2016 - AMalatesta - Created
-- 
-- parameters : p_date_from  : Fecha desde
--              p_date_to    : Fecha hasta
--              p_ext_debug  : Generar seguimiento de los cambios
--              p_char_delim : Caracter delimitador de la salida
--
-- inputs     : p_date_from  : Fecha desde
--              p_date_to    : Fecha hasta
--              p_ext_debug  : Generar seguimiento de los cambios
--              p_char_delim : Caracter delimitador de la salida
-- 
-- outputs    : <output1> : <description1> 
--              <output2> : <description2> 
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
-- 15-NOV-2016 AMalatesta [Despegar]             Created -  
-- *****************************************************************************
set serveroutput on size 1000000 
whenever sqlerror exit failure 
whenever oserror exit failure rollback
set verify off

declare
  cursor c_ar_data_print
    (c_ledger_id              gl_ledgers.ledger_id%type
    ,c_period_name            cll_f041_party_balances.period_name%type
    ,c_cta_flex_value_set_id  fnd_flex_values_vl.flex_value_set_id%type
    ,c_scta_flex_value_set_id fnd_flex_values_vl.flex_value_set_id%type
    ,c_coa_mpping_id          gl_cons_flexfield_map.coa_mapping_id%type
    ,c_puc_flex_value_set_id  fnd_flex_values_vl.flex_value_set_id%type)
  is
    select gl.name                   libro
          ,gcc_corp.segment2         cuenta
          ,ffv_ctacorp.description   desc_cuenta
          ,gcc_corp.segment3         subcuenta
          ,ffv_sctacorp.description  desc_subcuenta
          ,third_party_nit           nit_tercero
          ,third_party_name          nombre_tercero
          ,sum(begin_balance)        saldo_inicial
          ,sum(accounted_dr)         debitos
          ,sum(accounted_cr)         creditos
          ,sum(end_balance)          saldo_final
          ,min((select gcc_puc.segment2||' - '||ffv_ctapuc.description
                from   gl_cons_flexfield_map gcfm
                      ,gl_code_combinations  gcc_puc
                      ,fnd_flex_values_vl    ffv_ctapuc
                where  1=1
                and    gcfm.coa_mapping_id          = c_coa_mpping_id
                and    gcfm.to_code_combination_id  = gcc_puc.code_combination_id
                and    ffv_ctapuc.flex_value_set_id = c_puc_flex_value_set_id
                and    ffv_ctapuc.flex_value        = gcc_puc.segment2
                and    gcc_corp.segment1 between gcfm.segment1_low and gcfm.segment1_high
                and    gcc_corp.segment2 between gcfm.segment2_low and gcfm.segment2_high
                and    gcc_corp.segment3 between gcfm.segment3_low and gcfm.segment3_high
                and    gcc_corp.segment4 between gcfm.segment4_low and gcfm.segment4_high
                and    gcc_corp.segment5 between gcfm.segment5_low and gcfm.segment5_high
                and    gcc_corp.segment6 between gcfm.segment6_low and gcfm.segment6_high
                and    gcc_corp.segment7 between gcfm.segment7_low and gcfm.segment7_high
                and    gcc_corp.segment8 between gcfm.segment8_low and gcfm.segment8_high
                and    gcc_corp.segment9 between gcfm.segment9_low and gcfm.segment9_high
                and    gcc_corp.segment10 between gcfm.segment10_low and gcfm.segment10_high
                and    gcc_corp.segment11 between gcfm.segment11_low and gcfm.segment11_high)) cta_puc
    from   cll_f041_party_balances cfpb
          ,gl_ledgers              gl
          ,gl_code_combinations    gcc_corp
          ,fnd_flex_values_vl      ffv_ctacorp
          ,fnd_flex_values_vl      ffv_sctacorp
    where  1=1
    and    cfpb.code_combination_id           = gcc_corp.code_combination_id
    and    cfpb.ledger_id                     = gl.ledger_id
    and    ffv_ctacorp.flex_value_set_id      = c_cta_flex_value_set_id
    and    ffv_ctacorp.flex_value             = gcc_corp.segment2
    and    ffv_sctacorp.flex_value_set_id     = c_scta_flex_value_set_id
    and    ffv_sctacorp.flex_value            = gcc_corp.segment3
    and    ffv_sctacorp.parent_flex_value_low = gcc_corp.segment2
    and    gl.ledger_id                       = c_ledger_id
    and    cfpb.period_name                   = c_period_name
    group by gl.name
            ,gcc_corp.segment2
            ,ffv_ctacorp.description
            ,gcc_corp.segment3
            ,ffv_sctacorp.description
            ,third_party_nit
            ,third_party_name
    order by gcc_corp.segment2
            ,gcc_corp.segment3;
  /*--Parametros--*/
  p_ledger_id              gl_ledgers.ledger_id%type                 := '&&1';
  p_period_name            cll_f041_party_balances.period_name%type  := '&&2';
  p_cta_flex_value_set_id  fnd_flex_values_vl.flex_value_set_id%type := '&&3';
  p_scta_flex_value_set_id fnd_flex_values_vl.flex_value_set_id%type := '&&4';
  p_coa_mpping_id          gl_cons_flexfield_map.coa_mapping_id%type := '&&5';
  p_puc_flex_value_set_id  fnd_flex_values_vl.flex_value_set_id%type := '&&6';
  p_ext_debug              varchar2(3)                               := '&&7';
  p_char_delim             varchar2(3)                               := '&&8';
  /*--Variables--*/
  v_dummy            boolean;
  procedure print_trace
    (p_debug in varchar2
    ,p_str   in varchar2)
  is
  begin
    if p_debug='Y' then
      fnd_file.put_line(fnd_file.log,to_char(sysdate,'"["dd/mm/yyyy" - "HH24:MI:SS"] - ') || p_str);
    end if;
  end print_trace;
  procedure print_output
    (p_debug in varchar2
    ,p_str   in varchar2)
  is
  begin
    fnd_file.put_line(fnd_file.output,p_str);
  end print_output;
  procedure print_header
    (p_debug     in varchar2
    ,p_chardelim in varchar2)
  is
  begin
    print_output(p_debug=>p_ext_debug
                ,p_str=>'LIBRO'
                        ||p_chardelim||'CUENTA CORPORATIVA'
                        ||p_chardelim||'DESCRIPCION CUENTA'
                        ||p_chardelim||'SUBCUENTA'
                        ||p_chardelim||'DESCRIPCION SUBCUENTA'
                        ||p_chardelim||'NIT DE TERCERO'
                        ||p_chardelim||'NOMBRE DE TERCERO'
                        ||p_chardelim||'SALDO INICIAL'
                        ||p_chardelim||'DEBITOS'
                        ||p_chardelim||'CREDITOS'
                        ||p_chardelim||'SALDO FINAL'
                        ||p_chardelim||'CUENTA PUC');
  end print_header;
begin
  print_trace(p_debug=>p_ext_debug,p_str=>'--Begin (+)');
  print_trace(p_debug=>p_ext_debug,p_str=>'--  Parametros(+)');
  print_trace(p_debug=>p_ext_debug,p_str=>'--    1-p_ledger_id..............: '||p_ledger_id||'.');
  print_trace(p_debug=>p_ext_debug,p_str=>'--    2-p_period_name............: '||p_period_name||'.');
  print_trace(p_debug=>p_ext_debug,p_str=>'--    3-p_cta_flex_value_set_id..: '||p_cta_flex_value_set_id||'.');
  print_trace(p_debug=>p_ext_debug,p_str=>'--    4-p_scta_flex_value_set_id.: '||p_scta_flex_value_set_id||'.');
  print_trace(p_debug=>p_ext_debug,p_str=>'--    5-p_coa_mpping_id..........: '||p_coa_mpping_id||'.');
  print_trace(p_debug=>p_ext_debug,p_str=>'--    6-p_puc_flex_value_set_id..: '||p_puc_flex_value_set_id||'.');
  print_trace(p_debug=>p_ext_debug,p_str=>'--    7-p_ext_debug..............: '||p_ext_debug||'.');
  print_trace(p_debug=>p_ext_debug,p_str=>'--    8-p_char_delim.............: '||p_char_delim||'.');
  print_trace(p_debug=>p_ext_debug,p_str=>'--  Parametros(-)');
  print_trace(p_debug=>p_ext_debug,p_str=>'--  print_header(+)');
  print_header(p_debug=>p_ext_debug,p_chardelim=>p_char_delim);
  print_trace(p_debug=>p_ext_debug,p_str=>'--  print_header(-)');
  print_trace(p_debug=>p_ext_debug,p_str=>'--  Loop_PRT (+)');
  for c_data in c_ar_data_print(c_ledger_id              => c_ledger_id
                               ,c_period_name            => c_period_name
                               ,c_cta_flex_value_set_id  => c_cta_flex_value_set_id
                               ,c_scta_flex_value_set_id => c_scta_flex_value_set_id
                               ,c_coa_mpping_id          => c_coa_mpping_id
                               ,c_puc_flex_value_set_id  => c_puc_flex_value_set_id)
  loop
    print_output(p_debug=>p_ext_debug
                ,p_str=>c_data.libro
                        ||p_char_delim||c_data.cuenta
                        ||p_char_delim||c_data.desc_cuenta
                        ||p_char_delim||c_data.subcuenta
                        ||p_char_delim||c_data.desc_subcuenta
                        ||p_char_delim||c_data.nit_tercero
                        ||p_char_delim||c_data.nombre_tercero
                        ||p_char_delim||c_data.saldo_inicial
                        ||p_char_delim||c_data.debitos
                        ||p_char_delim||c_data.creditos
                        ||p_char_delim||c_data.saldo_final
                        ||p_char_delim||c_data.cta_puc);
  end loop;
  print_trace(p_debug=>p_ext_debug,p_str=>'--  Loop_PRT (+)');
  print_trace(p_debug=>p_ext_debug,p_str=>'--Begin (-)');
exception
  when others then
    fnd_file.put_line(fnd_file.output,'Error.: '||sqlerrm);
    fnd_file.put_line(fnd_file.log,'Error.: '||sqlerrm);
    v_dummy := fnd_concurrent.set_completion_status('ERROR','Unknown error, please check the log...');
end;
/
