-- 
--  Copyright (c) 2017 Despegar.com
--  This program contains proprietary and confidential information. 
--  All rights reserved except as may be permitted by prior 
--  written consent. 
-- 
--  File Name:   XXAPINVREG.sql
--  Attribute Label: XXAP
-- 
--  Description:  Carga la intefaz de facturas de AP. Tabla XX_AP_INV_INT
-- 
--  Modification History:
--     26-MAY-2014 - Amalatesta - Created
--     29-JUN-2016 - Amalatesta - Created - Nueva version en copia para incluir MEX
--     25-ENE-2017 - Amalatesta - Created - Nueva version en copia para adaptarlo a nivel regional
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
-- 26-MAY-2014 AMalatesta [Despegar]             Created -
-- 17-JUN-2014 AMalatesta [Despegar]             Modified - Se agrega UY
-- 29-JUN-2016 AMalatesta [Despegar]             Created - Se crea una copia para MX
-- 26-DIC-2016 NCano      [Despegar]             Modified - SOE-11285
-- 25-ENE-2017 AMalatesta [Despegar]             Created - Se crea una copia para adaptarlo a nivel regional
-- *****************************************************************************
set serveroutput on size 1000000 
whenever sqlerror exit failure 
whenever oserror exit failure rollback
set verify off

declare
  cursor c_fact_int_hdr
    (c_group_id xx_ap_inv_int.group_id%type
    ,c_status   xx_ap_inv_int.status%type)
  is
    select xaii.status                         --status
          ,xaii.invoice_num                    --invoice_num
          ,xaii.invoice_type_lookup_code       --invoice_type_lookup_code
          ,xaii.invoice_date                   --invoice_date
          ,xaii.gl_date                        --gl_date
          ,xaii.terms_date                     --terms_date
          ,xaii.vendor_num                     --vendor_num
          ,xaii.vendor_site_code               --vendor_site_code
          ,xaii.invoice_amount                 --invoice_amount
          ,xaii.invoice_currency_code          --invoice_currency_code
          ,xaii.terms_name                     --terms_name
          ,xaii.description                    --description
          ,xaii.source                         --source
          ,xaii.group_id                       --group_id
          ,xaii.payment_cross_rate_date        --payment_cross_rate_date
          ,xaii.payment_cross_rate             --payment_cross_rate
          ,xaii.payment_currency_code          --payment_currency_code
          ,xaii.pay_group_lookup_code          --pay_group_lookup_code
          ,xaii.exclusive_payment_flag         --exclusive_payment_flag
          ,xaii.calc_tax_during_import_flag    --calc_tax_during_import_flag
          ,xaii.add_tax_to_inv_amt_flag        --add_tax_to_inv_amt_flag
          ,xaii.taxation_country               --taxation_country
          ,xaii.legal_entity_id                --legal_entity_id
          ,xaii.operating_unit                 --operating_unit
          ,xaii.payment_method_code            --payment_method_code
          ,xaii.accts_pay_code_combination     --accts_pay_code_combination
          ,xaii.global_attribute_category      --global_attribute_category
          ,xaii.global_attribute1              --global_attribute1
          ,xaii.global_attribute2              --global_attribute2
          ,xaii.global_attribute3              --global_attribute3
          ,xaii.global_attribute4              --global_attribute4
          ,xaii.global_attribute5              --global_attribute5
          ,xaii.global_attribute6              --global_attribute6
          ,xaii.global_attribute7              --global_attribute7
          ,xaii.global_attribute8              --global_attribute8
          ,xaii.global_attribute9              --global_attribute9
          ,xaii.global_attribute10             --global_attribute10
          ,xaii.global_attribute11             --global_attribute11
          ,xaii.global_attribute12             --global_attribute12
          ,xaii.global_attribute13             --global_attribute13
          ,xaii.global_attribute14             --global_attribute14
          ,xaii.global_attribute15             --global_attribute15
          ,xaii.global_attribute16             --global_attribute16
          ,xaii.global_attribute17             --global_attribute17
          ,xaii.global_attribute18             --global_attribute18
          ,xaii.global_attribute19             --global_attribute19
          ,xaii.global_attribute20             --global_attribute20
          ,xaii.attribute_category             --attribute_category
          ,xaii.attribute1                     --attribute1
          ,xaii.attribute2                     --attribute2
          ,xaii.attribute3                     --attribute3
          ,xaii.attribute4                     --attribute4
          ,xaii.attribute5                     --attribute5
          ,xaii.attribute6                     --attribute6
          ,xaii.attribute7                     --attribute7
          ,xaii.attribute8                     --attribute8
          ,xaii.attribute9                     --attribute9
          ,xaii.attribute10                    --attribute10
          ,xaii.attribute11                    --attribute11
          ,xaii.attribute12                    --attribute12
          ,xaii.attribute13                    --attribute13
          ,xaii.attribute14                    --attribute14
          ,xaii.attribute15                    --attribute15
    from   xx_ap_inv_int xaii
    where  1=1
    and    xaii.group_id = c_group_id
    and    xaii.status   = c_status
    group by xaii.status                         --status
            ,xaii.invoice_num                    --invoice_num
            ,xaii.invoice_type_lookup_code       --invoice_type_lookup_code
            ,xaii.invoice_date                   --invoice_date
            ,xaii.gl_date                        --gl_date
            ,xaii.terms_date                     --terms_date
            ,xaii.vendor_num                     --vendor_num
            ,xaii.vendor_site_code               --vendor_site_code
            ,xaii.invoice_amount                 --invoice_amount
            ,xaii.invoice_currency_code          --invoice_currency_code
            ,xaii.terms_name                     --terms_name
            ,xaii.description                    --description
            ,xaii.source                         --source
            ,xaii.group_id                       --group_id
            ,xaii.payment_cross_rate_date        --payment_cross_rate_date
            ,xaii.payment_cross_rate             --payment_cross_rate
            ,xaii.payment_currency_code          --payment_currency_code
            ,xaii.pay_group_lookup_code          --pay_group_lookup_code
            ,xaii.exclusive_payment_flag         --exclusive_payment_flag
            ,xaii.calc_tax_during_import_flag    --calc_tax_during_import_flag
            ,xaii.add_tax_to_inv_amt_flag        --add_tax_to_inv_amt_flag
            ,xaii.taxation_country               --taxation_country
            ,xaii.legal_entity_id                --legal_entity_id
            ,xaii.operating_unit                 --operating_unit
            ,xaii.payment_method_code            --payment_method_code
            ,xaii.accts_pay_code_combination     --accts_pay_code_combination
            ,xaii.global_attribute_category      --global_attribute_category
            ,xaii.global_attribute1              --global_attribute1
            ,xaii.global_attribute2              --global_attribute2
            ,xaii.global_attribute3              --global_attribute3
            ,xaii.global_attribute4              --global_attribute4
            ,xaii.global_attribute5              --global_attribute5
            ,xaii.global_attribute6              --global_attribute6
            ,xaii.global_attribute7              --global_attribute7
            ,xaii.global_attribute8              --global_attribute8
            ,xaii.global_attribute9              --global_attribute9
            ,xaii.global_attribute10             --global_attribute10
            ,xaii.global_attribute11             --global_attribute11
            ,xaii.global_attribute12             --global_attribute12
            ,xaii.global_attribute13             --global_attribute13
            ,xaii.global_attribute14             --global_attribute14
            ,xaii.global_attribute15             --global_attribute15
            ,xaii.global_attribute16             --global_attribute16
            ,xaii.global_attribute17             --global_attribute17
            ,xaii.global_attribute18             --global_attribute18
            ,xaii.global_attribute19             --global_attribute19
            ,xaii.global_attribute20             --global_attribute20
            ,xaii.attribute_category             --attribute_category
            ,xaii.attribute1                     --attribute1
            ,xaii.attribute2                     --attribute2
            ,xaii.attribute3                     --attribute3
            ,xaii.attribute4                     --attribute4
            ,xaii.attribute5                     --attribute5
            ,xaii.attribute6                     --attribute6
            ,xaii.attribute7                     --attribute7
            ,xaii.attribute8                     --attribute8
            ,xaii.attribute9                     --attribute9
            ,xaii.attribute10                    --attribute10
            ,xaii.attribute11                    --attribute11
            ,xaii.attribute12                    --attribute12
            ,xaii.attribute13                    --attribute13
            ,xaii.attribute14                    --attribute14
            ,xaii.attribute15;                   --attribute15
  cursor c_fact_int_lns
    (c_group_id         xx_ap_inv_int.group_id%type
    ,c_status           xx_ap_inv_int.status%type
    ,c_vendor_num       xx_ap_inv_int.vendor_num%type
    ,c_vendor_site_code xx_ap_inv_int.vendor_site_code%type
    ,c_invoice_num      xx_ap_inv_int.invoice_num%type)
  is
    select *
    from   xx_ap_inv_int xaii
    where  1=1
    and    xaii.group_id         = c_group_id
    and    xaii.status           = c_status
    and    xaii.vendor_num       = c_vendor_num
    and    xaii.vendor_site_code = c_vendor_site_code
    and    xaii.invoice_num      = c_invoice_num;
  /*--Parametros--*/
  p_group_id               xx_ap_inv_int.group_id%type                   := '&&1';
  p_draft                  varchar2(3)                                   := '&&2';
  p_status                 xx_ap_inv_int.status%type                     := '&&3';
  p_exchange_rate_type     ap_invoices_interface.exchange_rate_type%type := '&&4';
  p_ext_debug              varchar2(3)                                   := '&&5';
  p_char_delim             varchar2(3)                                   := '&&6';
  /*--Variables--*/
  v_dummy                  boolean;
  v_org_id                 hr_operating_units.organization_id%type;
  v_accts_pay_code_comb    gl_code_combinations.code_combination_id%type;
  v_dist_code_comb         gl_code_combinations.code_combination_id%type;
  v_error_text             varchar2(4000);
  v_invoice_id             ap_invoices_interface.invoice_id%type;
  v_invoice_line_id        ap_invoice_lines_interface.invoice_line_id%type;
  v_count                  number;
  v_control                number;
  vn_percentage_rate       zx_rates_b.percentage_rate%type :=0;
  vn_amount_tax            number :=0;
  vc_tax_regime_code       zx_rates_b.tax_regime_code%type := null;
  vc_tax                   zx_rates_b.tax%type := null;
  vc_tax_jurisdiction_code zx_rates_b.tax_jurisdiction_code%type := null;
  vc_tax_status_code       zx_rates_b.tax_status_code%type := null;
  vn_tax_rate_id           zx_rates_b.tax_rate_id%type := 0;
  vc_tax_rate_code         zx_rates_b.tax_rate_code%type := null;
  function get_org_id
  (p_ou_name in hr_operating_units.name%type)
  return hr_operating_units.organization_id%type
  is
    v_org_id hr_operating_units.organization_id%type;
  begin
    select organization_id
    into   v_org_id
    from   hr_operating_units hou
    where  1=1
    and    hou.name = p_ou_name;
    return v_org_id;
  exception
    when others then
      v_error_text := v_error_text ||'Get_org_id. Parametro: '||p_ou_name||'. Error: '||sqlerrm;
      return -1;
  end get_org_id;
  function get_gl_comb_id
    (p_code_combinations in varchar2)
  return gl_code_combinations.code_combination_id%type
  is
    v_code_combination_id gl_code_combinations.code_combination_id%type;
  begin
    select gcc.code_combination_id
    into   v_code_combination_id
    from   gl_code_combinations gcc
    where  1=1
    and    gcc.segment1
    ||'.'||gcc.segment2
    ||'.'||gcc.segment3
    ||'.'||gcc.segment4
    ||'.'||gcc.segment5
    ||'.'||gcc.segment6
    ||'.'||gcc.segment7
    ||'.'||gcc.segment8
    ||'.'||gcc.segment9
    ||'.'||gcc.segment10
    ||'.'||gcc.segment11 = p_code_combinations;
    return v_code_combination_id;
  exception
    when others then
      v_error_text := v_error_text ||'Get_gl_comb_id. Parametro: '||p_code_combinations||'. Error: '||sqlerrm;
      return -1;
  end get_gl_comb_id;
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
                ,p_str=>'INV_INT_ID'
                  ||p_chardelim||'ORG_ID'
                  ||p_chardelim||'OPERATING_UNIT'
                  ||p_chardelim||'LEGAL_ENTITY_ID'
                  ||p_chardelim||'INVOICE_ID'
                  ||p_chardelim||'INVOICE_LINE_ID'
                  ||p_chardelim||'STATUS'
                  ||p_chardelim||'ERROR_MESSAGES'
                  ||p_chardelim||'VENDOR_NUM'
                  ||p_chardelim||'VENDOR_SITE_CODE'
                  ||p_chardelim||'GROUP_ID'
                  ||p_chardelim||'INVOICE_TYPE_LOOKUP_CODE'
                  ||p_chardelim||'INVOICE_NUM'
                  ||p_chardelim||'DESCRIPTION'
                  ||p_chardelim||'INVOICE_DATE'
                  ||p_chardelim||'TERMS_DATE'
                  ||p_chardelim||'GL_DATE'
                  ||p_chardelim||'INVOICE_CURRENCY_CODE'
                  ||p_chardelim||'INVOICE_AMOUNT'
                  ||p_chardelim||'SOURCE'
                  ||p_chardelim||'CALC_TAX_DURING_IMPORT_FLAG'
                  ||p_chardelim||'ADD_TAX_TO_INV_AMT_FLAG'
                  ||p_chardelim||'TAXATION_COUNTRY'
                  ||p_chardelim||'PAYMENT_METHOD_CODE'
                  ||p_chardelim||'PAYMENT_CURRENCY_CODE'
                  ||p_chardelim||'TERMS_NAME'
                  ||p_chardelim||'PAYMENT_CROSS_RATE'
                  ||p_chardelim||'PAYMENT_CROSS_RATE_DATE'
                  ||p_chardelim||'PAY_GROUP_LOOKUP_CODE'
                  ||p_chardelim||'ACCTS_PAY_CODE_COMBINATION_ID'
                  ||p_chardelim||'ACCTS_PAY_CODE_COMBINATION'
                  ||p_chardelim||'EXCLUSIVE_PAYMENT_FLAG'
                  ||p_chardelim||'LINE_NUMBER'
                  ||p_chardelim||'LINE_TYPE_LOOKUP_CODE'
                  ||p_chardelim||'AMOUNT'
                  ||p_chardelim||'TAX_CLASSIFICATION_CODE'
                  ||p_chardelim||'DIST_CODE_COMBINATION_ID'
                  ||p_chardelim||'DIST_CODE_COMBINATION'
                  ||p_chardelim||'SHIP_TO_LOCATION_ID'
                  ||p_chardelim||'SHIP_TO_LOCATION'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE_CATEGORY'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE1'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE2'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE3'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE4'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE5'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE6'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE7'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE8'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE9'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE10'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE11'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE12'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE13'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE14'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE15'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE16'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE17'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE18'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE19'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE20'
                  ||p_chardelim||'ATTRIBUTE_CATEGORY'
                  ||p_chardelim||'ATTRIBUTE1'
                  ||p_chardelim||'ATTRIBUTE2'
                  ||p_chardelim||'ATTRIBUTE3'
                  ||p_chardelim||'ATTRIBUTE4'
                  ||p_chardelim||'ATTRIBUTE5'
                  ||p_chardelim||'ATTRIBUTE6'
                  ||p_chardelim||'ATTRIBUTE7'
                  ||p_chardelim||'ATTRIBUTE8'
                  ||p_chardelim||'ATTRIBUTE9'
                  ||p_chardelim||'ATTRIBUTE10'
                  ||p_chardelim||'ATTRIBUTE11'
                  ||p_chardelim||'ATTRIBUTE12'
                  ||p_chardelim||'ATTRIBUTE13'
                  ||p_chardelim||'ATTRIBUTE14'
                  ||p_chardelim||'ATTRIBUTE15'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE_CATEGORY_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE1_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE2_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE3_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE4_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE5_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE6_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE7_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE8_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE9_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE10_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE11_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE12_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE13_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE14_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE15_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE16_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE17_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE18_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE19_L'
                  ||p_chardelim||'GLOBAL_ATTRIBUTE20_L'
                  ||p_chardelim||'ATTRIBUTE_CATEGORY_L'
                  ||p_chardelim||'ATTRIBUTE1_L'
                  ||p_chardelim||'ATTRIBUTE2_L'
                  ||p_chardelim||'ATTRIBUTE3_L'
                  ||p_chardelim||'ATTRIBUTE4_L'
                  ||p_chardelim||'ATTRIBUTE5_L'
                  ||p_chardelim||'ATTRIBUTE6_L'
                  ||p_chardelim||'ATTRIBUTE7_L'
                  ||p_chardelim||'ATTRIBUTE8_L'
                  ||p_chardelim||'ATTRIBUTE9_L'
                  ||p_chardelim||'ATTRIBUTE10_L'
                  ||p_chardelim||'ATTRIBUTE11_L'
                  ||p_chardelim||'ATTRIBUTE12_L'
                  ||p_chardelim||'ATTRIBUTE13_L'
                  ||p_chardelim||'ATTRIBUTE14_L'
                  ||p_chardelim||'ATTRIBUTE15_L'
                  ||p_chardelim||'CREATION_DATE'
                  ||p_chardelim||'CREATED_BY'
                  ||p_chardelim||'LAST_UPDATE_DATE'
                  ||p_chardelim||'LAST_UPDATED_BY'
                  ||p_chardelim||'LAST_UPDATE_LOGIN');
  end print_header;
  procedure print_lines
    (p_inv_int_id in xx_ap_inv_int.inv_int_id%type
    ,p_debug      in varchar2
    ,p_chardelim  in varchar2)
  is
    cursor c_fact_lines
      (c_inv_int_id xx_ap_inv_int.inv_int_id%type)
    is
      select *
      from   xx_ap_inv_int xaii
      where  1=1
      and    xaii.inv_int_id = c_inv_int_id;
  begin
    for i_fact in c_fact_lines(c_inv_int_id => p_inv_int_id)
    loop
      print_output(p_debug=>p_ext_debug
                  ,p_str=>i_fact.inv_int_id
                  ||p_chardelim||i_fact.org_id
                  ||p_chardelim||i_fact.operating_unit
                  ||p_chardelim||i_fact.legal_entity_id
                  ||p_chardelim||i_fact.invoice_id
                  ||p_chardelim||i_fact.invoice_line_id
                  ||p_chardelim||i_fact.status
                  ||p_chardelim||i_fact.error_messages
                  ||p_chardelim||i_fact.vendor_num
                  ||p_chardelim||i_fact.vendor_site_code
                  ||p_chardelim||i_fact.group_id
                  ||p_chardelim||i_fact.invoice_type_lookup_code
                  ||p_chardelim||i_fact.invoice_num
                  ||p_chardelim||i_fact.description
                  ||p_chardelim||i_fact.invoice_date
                  ||p_chardelim||i_fact.terms_date
                  ||p_chardelim||i_fact.gl_date
                  ||p_chardelim||i_fact.invoice_currency_code
                  ||p_chardelim||i_fact.invoice_amount
                  ||p_chardelim||i_fact.source
                  ||p_chardelim||i_fact.calc_tax_during_import_flag
                  ||p_chardelim||i_fact.add_tax_to_inv_amt_flag
                  ||p_chardelim||i_fact.taxation_country
                  ||p_chardelim||i_fact.payment_method_code
                  ||p_chardelim||i_fact.payment_currency_code
                  ||p_chardelim||i_fact.terms_name
                  ||p_chardelim||i_fact.payment_cross_rate
                  ||p_chardelim||i_fact.payment_cross_rate_date
                  ||p_chardelim||i_fact.pay_group_lookup_code
                  ||p_chardelim||i_fact.accts_pay_code_combination_id
                  ||p_chardelim||i_fact.accts_pay_code_combination
                  ||p_chardelim||i_fact.exclusive_payment_flag
                  ||p_chardelim||i_fact.line_number
                  ||p_chardelim||i_fact.line_type_lookup_code
                  ||p_chardelim||i_fact.amount
                  ||p_chardelim||i_fact.tax_classification_code
                  ||p_chardelim||i_fact.dist_code_combination_id
                  ||p_chardelim||i_fact.dist_code_combination
                  ||p_chardelim||i_fact.ship_to_location_id
                  ||p_chardelim||i_fact.ship_to_location
                  ||p_chardelim||i_fact.global_attribute_category
                  ||p_chardelim||i_fact.global_attribute1
                  ||p_chardelim||i_fact.global_attribute2
                  ||p_chardelim||i_fact.global_attribute3
                  ||p_chardelim||i_fact.global_attribute4
                  ||p_chardelim||i_fact.global_attribute5
                  ||p_chardelim||i_fact.global_attribute6
                  ||p_chardelim||i_fact.global_attribute7
                  ||p_chardelim||i_fact.global_attribute8
                  ||p_chardelim||i_fact.global_attribute9
                  ||p_chardelim||i_fact.global_attribute10
                  ||p_chardelim||i_fact.global_attribute11
                  ||p_chardelim||i_fact.global_attribute12
                  ||p_chardelim||i_fact.global_attribute13
                  ||p_chardelim||i_fact.global_attribute14
                  ||p_chardelim||i_fact.global_attribute15
                  ||p_chardelim||i_fact.global_attribute16
                  ||p_chardelim||i_fact.global_attribute17
                  ||p_chardelim||i_fact.global_attribute18
                  ||p_chardelim||i_fact.global_attribute19
                  ||p_chardelim||i_fact.global_attribute20
                  ||p_chardelim||i_fact.attribute_category
                  ||p_chardelim||i_fact.attribute1
                  ||p_chardelim||i_fact.attribute2
                  ||p_chardelim||i_fact.attribute3
                  ||p_chardelim||i_fact.attribute4
                  ||p_chardelim||i_fact.attribute5
                  ||p_chardelim||i_fact.attribute6
                  ||p_chardelim||i_fact.attribute7
                  ||p_chardelim||i_fact.attribute8
                  ||p_chardelim||i_fact.attribute9
                  ||p_chardelim||i_fact.attribute10
                  ||p_chardelim||i_fact.attribute11
                  ||p_chardelim||i_fact.attribute12
                  ||p_chardelim||i_fact.attribute13
                  ||p_chardelim||i_fact.attribute14
                  ||p_chardelim||i_fact.attribute15
                  ||p_chardelim||i_fact.global_attribute_category_l
                  ||p_chardelim||i_fact.global_attribute1_l
                  ||p_chardelim||i_fact.global_attribute2_l
                  ||p_chardelim||i_fact.global_attribute3_l
                  ||p_chardelim||i_fact.global_attribute4_l
                  ||p_chardelim||i_fact.global_attribute5_l
                  ||p_chardelim||i_fact.global_attribute6_l
                  ||p_chardelim||i_fact.global_attribute7_l
                  ||p_chardelim||i_fact.global_attribute8_l
                  ||p_chardelim||i_fact.global_attribute9_l
                  ||p_chardelim||i_fact.global_attribute10_l
                  ||p_chardelim||i_fact.global_attribute11_l
                  ||p_chardelim||i_fact.global_attribute12_l
                  ||p_chardelim||i_fact.global_attribute13_l
                  ||p_chardelim||i_fact.global_attribute14_l
                  ||p_chardelim||i_fact.global_attribute15_l
                  ||p_chardelim||i_fact.global_attribute16_l
                  ||p_chardelim||i_fact.global_attribute17_l
                  ||p_chardelim||i_fact.global_attribute18_l
                  ||p_chardelim||i_fact.global_attribute19_l
                  ||p_chardelim||i_fact.global_attribute20_l
                  ||p_chardelim||i_fact.attribute_category_l
                  ||p_chardelim||i_fact.attribute1_l
                  ||p_chardelim||i_fact.attribute2_l
                  ||p_chardelim||i_fact.attribute3_l
                  ||p_chardelim||i_fact.attribute4_l
                  ||p_chardelim||i_fact.attribute5_l
                  ||p_chardelim||i_fact.attribute6_l
                  ||p_chardelim||i_fact.attribute7_l
                  ||p_chardelim||i_fact.attribute8_l
                  ||p_chardelim||i_fact.attribute9_l
                  ||p_chardelim||i_fact.attribute10_l
                  ||p_chardelim||i_fact.attribute11_l
                  ||p_chardelim||i_fact.attribute12_l
                  ||p_chardelim||i_fact.attribute13_l
                  ||p_chardelim||i_fact.attribute14_l
                  ||p_chardelim||i_fact.attribute15_l
                  ||p_chardelim||i_fact.creation_date
                  ||p_chardelim||i_fact.created_by
                  ||p_chardelim||i_fact.last_update_date
                  ||p_chardelim||i_fact.last_updated_by
                  ||p_chardelim||i_fact.last_update_login);
    end loop;
  exception
    when others then
      print_trace(p_debug=>p_ext_debug,p_str=>'Print_Lines.Error: '||sqlerrm);
  end print_lines;
begin
  print_trace(p_debug=>p_ext_debug,p_str=>'--Begin (+)');
  print_trace(p_debug=>p_ext_debug,p_str=>'--  Parametros(+)');
  print_trace(p_debug=>p_ext_debug,p_str=>'--    1-p_group_id...: '||p_group_id||'.');
  print_trace(p_debug=>p_ext_debug,p_str=>'--    2-p_status.....: '||p_status||'.');
  print_trace(p_debug=>p_ext_debug,p_str=>'--    3-p_debug......: '||p_ext_debug||'.');
  print_trace(p_debug=>p_ext_debug,p_str=>'--    4-p_char_delim.: '||p_char_delim||'.');
  print_trace(p_debug=>p_ext_debug,p_str=>'--  Parametros(-)');
  print_trace(p_debug=>p_ext_debug,p_str=>'--  print_header(+)');
  print_header(p_debug=>p_ext_debug,p_chardelim=>p_char_delim);
  print_trace(p_debug=>p_ext_debug,p_str=>'--  print_header(-)');
  print_trace(p_debug=>p_ext_debug,p_str=>'--  Loop_HDR (+)');
  if p_draft = 'Y' then
    savepoint rstrpnt;
  end if;
  v_count   := 0;
  v_control := 0;
  for i_fact_int in c_fact_int_hdr(c_group_id => p_group_id
                                  ,c_status   => p_status)
  loop
    v_count               := v_count + 1;
    v_error_text          := '';
    v_org_id              := get_org_id(p_ou_name => i_fact_int.operating_unit);
    v_accts_pay_code_comb := get_gl_comb_id(p_code_combinations => i_fact_int.accts_pay_code_combination);
    v_control             := 0;
    begin
      select ap_invoices_interface_s.nextval
      into   v_invoice_id
      from   dual;
    exception
      when others then
        v_error_text := v_error_text ||'Get_Invoice_id.Error: '||sqlerrm;
        v_invoice_id := -1;
    end;
    begin
      select ap_invoice_lines_interface_s.nextval
      into   v_invoice_line_id
      from   dual;
    exception
      when others then
        v_error_text := v_error_text ||'Get_Invoice_Line_id.Error: '||sqlerrm;
        v_invoice_line_id := -1;
    end;
    if   v_org_id = -1
      or v_accts_pay_code_comb = -1
      or v_invoice_id = -1
      or v_invoice_line_id = -1 then
      v_dummy := fnd_concurrent.set_completion_status('WARNING','Error en los registros. Verifique la salida. Contador: '||v_count);
      begin
        update xx_ap_inv_int xaii
        set    xaii.status = 'ERROR'
              ,xaii.error_messages = v_error_text
        where  1=1
        and    xaii.group_id         = i_fact_int.group_id
        and    xaii.status           = i_fact_int.status
        and    xaii.vendor_num       = i_fact_int.vendor_num
        and    xaii.vendor_site_code = i_fact_int.vendor_site_code
        and    xaii.invoice_num      = i_fact_int.invoice_num;
      exception
        when others then
          v_error_text := v_error_text ||'Update.xx_ap_inv_int.Error: '||sqlerrm;
      end;
    else
      for i_fact_int_lns in c_fact_int_lns(c_group_id         => i_fact_int.group_id
                                          ,c_status           => i_fact_int.status
                                          ,c_vendor_num       => i_fact_int.vendor_num
                                          ,c_vendor_site_code => i_fact_int.vendor_site_code
                                          ,c_invoice_num      => i_fact_int.invoice_num)
      loop
        if v_control = 0 then
          v_dist_code_comb := get_gl_comb_id(p_code_combinations => i_fact_int_lns.dist_code_combination);
          if v_dist_code_comb = -1 then
            v_control := -1;
            v_dummy := fnd_concurrent.set_completion_status('WARNING','Error en los registros. Verifique la salida. Contador: '||v_count);
            update xx_ap_inv_int xaii
            set    xaii.status = 'ERROR'
                  ,xaii.error_messages = v_error_text
            where  1=1
            and    xaii.group_id         = i_fact_int.group_id
            and    xaii.status           = i_fact_int.status
            and    xaii.vendor_num       = i_fact_int.vendor_num
            and    xaii.vendor_site_code = i_fact_int.vendor_site_code
            and    xaii.invoice_num      = i_fact_int.invoice_num;
          else
            begin
              insert into ap_invoices_interface
                (invoice_id
                ,invoice_num
                ,invoice_type_lookup_code
                ,invoice_date
                ,gl_date
                ,terms_date
                ,vendor_num
                ,vendor_site_code
                ,invoice_amount
                ,invoice_currency_code
                ,terms_name
                ,description
                ,source
                ,group_id
                ,payment_cross_rate_date
                ,payment_cross_rate
                ,payment_currency_code
                ,pay_group_lookup_code
                ,accts_pay_code_combination_id
                ,exclusive_payment_flag
                ,org_id
                ,calc_tax_during_import_flag
                ,add_tax_to_inv_amt_flag
                ,taxation_country
                ,legal_entity_id
                ,operating_unit
                ,payment_method_code
                ,exchange_rate_type
                ,exchange_date
                ,global_attribute_category
                ,global_attribute1
                ,global_attribute2
                ,global_attribute3
                ,global_attribute4
                ,global_attribute5
                ,global_attribute6
                ,global_attribute7
                ,global_attribute8
                ,global_attribute9
                ,global_attribute10
                ,global_attribute11
                ,global_attribute12
                ,global_attribute13
                ,global_attribute14
                ,global_attribute15
                ,global_attribute16
                ,global_attribute17
                ,global_attribute18
                ,global_attribute19
                ,global_attribute20
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                ,creation_date
                ,created_by
                ,last_update_date
                ,last_updated_by
                ,last_update_login)
              values
                (v_invoice_id                              --invoice_id
                ,i_fact_int.invoice_num                    --invoice_num
                ,i_fact_int.invoice_type_lookup_code       --invoice_type_lookup_code
                ,i_fact_int.invoice_date                   --invoice_date
                ,i_fact_int.gl_date                        --gl_date
                ,i_fact_int.terms_date                     --terms_date
                ,i_fact_int.vendor_num                     --vendor_num
                ,i_fact_int.vendor_site_code               --vendor_site_code
                ,i_fact_int.invoice_amount                 --invoice_amount
                ,i_fact_int.invoice_currency_code          --invoice_currency_code
                ,i_fact_int.terms_name                     --terms_name
                ,i_fact_int.description                    --description
                ,i_fact_int.source                         --source
                ,i_fact_int.group_id                       --group_id
                ,i_fact_int.payment_cross_rate_date        --payment_cross_rate_date
                ,i_fact_int.payment_cross_rate             --payment_cross_rate
                ,i_fact_int.payment_currency_code          --payment_currency_code
                ,i_fact_int.pay_group_lookup_code          --pay_group_lookup_code
                ,v_accts_pay_code_comb                     --accts_pay_code_combination_id
                ,i_fact_int.exclusive_payment_flag         --exclusive_payment_flag
                ,v_org_id                                  --org_id
                ,i_fact_int.calc_tax_during_import_flag    --calc_tax_during_import_flag
                ,i_fact_int.add_tax_to_inv_amt_flag        --add_tax_to_inv_amt_flag
                ,i_fact_int.taxation_country               --taxation_country
                ,i_fact_int.legal_entity_id                --legal_entity_id
                ,i_fact_int.operating_unit                 --operating_unit
                ,i_fact_int.payment_method_code            --payment_method_code
                ,p_exchange_rate_type                      --exchange_rate_type
                ,i_fact_int.invoice_date                   --exchange_date
                ,i_fact_int.global_attribute_category      --global_attribute_category
                ,i_fact_int.global_attribute1              --global_attribute1
                ,i_fact_int.global_attribute2              --global_attribute2
                ,i_fact_int.global_attribute3              --global_attribute3
                ,i_fact_int.global_attribute4              --global_attribute4
                ,i_fact_int.global_attribute5              --global_attribute5
                ,i_fact_int.global_attribute6              --global_attribute6
                ,i_fact_int.global_attribute7              --global_attribute7
                ,i_fact_int.global_attribute8              --global_attribute8
                ,i_fact_int.global_attribute9              --global_attribute9
                ,i_fact_int.global_attribute10             --global_attribute10
                ,i_fact_int.global_attribute11             --global_attribute11
                ,i_fact_int.global_attribute12             --global_attribute12
                ,i_fact_int.global_attribute13             --global_attribute13
                ,i_fact_int.global_attribute14             --global_attribute14
                ,i_fact_int.global_attribute15             --global_attribute15
                ,i_fact_int.global_attribute16             --global_attribute16
                ,i_fact_int.global_attribute17             --global_attribute17
                ,i_fact_int.global_attribute18             --global_attribute18
                ,i_fact_int.global_attribute19             --global_attribute19
                ,i_fact_int.global_attribute20             --global_attribute20
                ,i_fact_int.attribute_category             --attribute_category
                ,i_fact_int.attribute1                     --attribute1
                ,i_fact_int.attribute2                     --attribute2
                ,i_fact_int.attribute3                     --attribute3
                ,i_fact_int.attribute4                     --attribute4
                ,i_fact_int.attribute5                     --attribute5
                ,i_fact_int.attribute6                     --attribute6
                ,i_fact_int.attribute7                     --attribute7
                ,i_fact_int.attribute8                     --attribute8
                ,i_fact_int.attribute9                     --attribute9
                ,i_fact_int.attribute10                    --attribute10
                ,i_fact_int.attribute11                    --attribute11
                ,i_fact_int.attribute12                    --attribute12
                ,i_fact_int.attribute13                    --attribute13
                ,i_fact_int.attribute14                    --attribute14
                ,i_fact_int.attribute15                    --attribute15
                ,sysdate                                   --creation_date
                ,to_number(fnd_profile.value('USER_ID'))   --created_by
                ,sysdate                                   --last_update_date
                ,to_number(fnd_profile.value('USER_ID'))   --last_updated_by
                ,to_number(fnd_profile.value('LOGIN_ID')));--last_update_login
              insert into ap_invoice_lines_interface
                (invoice_id
                ,invoice_line_id
                ,line_number
                ,line_type_lookup_code
                ,amount
                ,dist_code_combination_id
                ,org_id
                ,ship_to_location_id
                ,tax_classification_code
                ,global_attribute_category
                ,global_attribute1
                ,global_attribute2
                ,global_attribute3
                ,global_attribute4
                ,global_attribute5
                ,global_attribute6
                ,global_attribute7
                ,global_attribute8
                ,global_attribute9
                ,global_attribute10
                ,global_attribute11
                ,global_attribute12
                ,global_attribute13
                ,global_attribute14
                ,global_attribute15
                ,global_attribute16
                ,global_attribute17
                ,global_attribute18
                ,global_attribute19
                ,global_attribute20
                ,attribute_category
                ,attribute1
                ,attribute2
                ,attribute3
                ,attribute4
                ,attribute5
                ,attribute6
                ,attribute7
                ,attribute8
                ,attribute9
                ,attribute10
                ,attribute11
                ,attribute12
                ,attribute13
                ,attribute14
                ,attribute15
                ,creation_date
                ,created_by
                ,last_update_date
                ,last_updated_by
                ,last_update_login)
              values
                (v_invoice_id                               --invoice_id
                ,v_invoice_line_id                          --invoice_line_id
                ,i_fact_int_lns.line_number                 --line_number
                ,i_fact_int_lns.line_type_lookup_code       --line_type_lookup_code
                ,i_fact_int_lns.amount                      --amount
                ,v_dist_code_comb                           --dist_code_combination_id
                ,v_org_id                                   --org_id
                ,i_fact_int_lns.ship_to_location_id         --ship_to_location_id
                ,i_fact_int_lns.tax_classification_code     --tax_classification_code
                ,i_fact_int_lns.global_attribute_category_l --global_attribute_category
                ,i_fact_int_lns.global_attribute1_l         --global_attribute1
                ,i_fact_int_lns.global_attribute2_l         --global_attribute2
                ,i_fact_int_lns.global_attribute3_l         --global_attribute3
                ,i_fact_int_lns.global_attribute4_l         --global_attribute4
                ,i_fact_int_lns.global_attribute5_l         --global_attribute5
                ,i_fact_int_lns.global_attribute6_l         --global_attribute6
                ,i_fact_int_lns.global_attribute7_l         --global_attribute7
                ,i_fact_int_lns.global_attribute8_l         --global_attribute8
                ,i_fact_int_lns.global_attribute9_l         --global_attribute9
                ,i_fact_int_lns.global_attribute10_l        --global_attribute10
                ,i_fact_int_lns.global_attribute11_l        --global_attribute11
                ,i_fact_int_lns.global_attribute12_l        --global_attribute12
                ,i_fact_int_lns.global_attribute13_l        --global_attribute13
                ,i_fact_int_lns.global_attribute14_l        --global_attribute14
                ,i_fact_int_lns.global_attribute15_l        --global_attribute15
                ,i_fact_int_lns.global_attribute16_l        --global_attribute16
                ,i_fact_int_lns.global_attribute17_l        --global_attribute17
                ,i_fact_int_lns.global_attribute18_l        --global_attribute18
                ,i_fact_int_lns.global_attribute19_l        --global_attribute19
                ,i_fact_int_lns.global_attribute20_l        --global_attribute20
                ,i_fact_int_lns.attribute_category_l        --attribute_category
                ,i_fact_int_lns.attribute1_l                --attribute1
                ,i_fact_int_lns.attribute2_l                --attribute2
                ,i_fact_int_lns.attribute3_l                --attribute3
                ,i_fact_int_lns.attribute4_l                --attribute4
                ,i_fact_int_lns.attribute5_l                --attribute5
                ,i_fact_int_lns.attribute6_l                --attribute6
                ,i_fact_int_lns.attribute7_l                --attribute7
                ,i_fact_int_lns.attribute8_l                --attribute8
                ,i_fact_int_lns.attribute9_l                --attribute9
                ,i_fact_int_lns.attribute10_l               --attribute10
                ,i_fact_int_lns.attribute11_l               --attribute11
                ,i_fact_int_lns.attribute12_l               --attribute12
                ,i_fact_int_lns.attribute13_l               --attribute13
                ,i_fact_int_lns.attribute14_l               --attribute14
                ,i_fact_int_lns.attribute15_l               --attribute15
                ,sysdate                                    --creation_date
                ,to_number(fnd_profile.value('USER_ID'))    --created_by
                ,sysdate                                    --last_update_date
                ,to_number(fnd_profile.value('USER_ID'))    --last_updated_by
                ,to_number(fnd_profile.value('LOGIN_ID'))); --last_update_login
              begin
                select percentage_rate
                      ,tax_regime_code
                      ,tax
                      ,tax_jurisdiction_code
                      ,tax_status_code
                      ,tax_rate_id
                      ,tax_rate_code
                into   vn_percentage_rate
                      ,vc_tax_regime_code
                      ,vc_tax
                      ,vc_tax_jurisdiction_code
                      ,vc_tax_status_code
                      ,vn_tax_rate_id
                      ,vc_tax_rate_code
                from   zx_rates_b
                where  1=1
                and    rate_type_code = 'PERCENTAGE'
                and    tax_rate_code  = i_fact_int_lns.tax_classification_code;
              exception when no_data_found then
                vn_percentage_rate := -1;
                print_trace(p_debug=>p_ext_debug,p_str=>'--  No se encontre el codigo '||i_fact_int_lns.tax_classification_code||
                                                        ' en la tabla zx_rates_b');
              end;
              if vn_percentage_rate <> -1 then
                vn_amount_tax := round(i_fact_int_lns.amount * vn_percentage_rate / 100,2);
                begin
                  select ap_invoice_lines_interface_s.nextval
                  into   v_invoice_line_id
                  from   dual;
                exception
                  when others then
                    v_error_text := v_error_text ||'Get_Invoice_Line_id.Error: '||sqlerrm;
                    v_invoice_line_id := -1;
                end;
                insert into ap_invoice_lines_interface
                  (invoice_id
                  ,invoice_line_id
                  ,line_number
                  ,line_type_lookup_code
                  ,tax_regime_code
                  ,tax
                  ,tax_jurisdiction_code
                  ,tax_status_code
                  ,tax_rate_id
                  ,tax_rate_code
                  ,tax_rate
                  ,amount
                  ,org_id
                  ,creation_date
                  ,created_by
                  ,last_update_date
                  ,last_updated_by
                  ,last_update_login)
                values
                  (v_invoice_id                              --invoice_id
                  ,v_invoice_line_id                         --invoice_line_id
                  ,i_fact_int_lns.line_number+1              --line_number del ITEM + 1
                  ,'TAX'                                     --line_type_lookup_code
                  ,vc_tax_regime_code                        --tax_regime_code
                  ,vc_tax                                    --tax
                  ,vc_tax_jurisdiction_code                  --tax_jurisdiction_code
                  ,vc_tax_status_code                        --tax_status_code
                  ,vn_tax_rate_id                            --tax_rate_id
                  ,vc_tax_rate_code                          --tax_rate_code
                  ,vn_percentage_rate                        --tax_rate
                  ,vn_amount_tax                             --amount
                  ,v_org_id                                  --org_id
                  ,sysdate                                   --creation_date
                  ,to_number(fnd_profile.value('USER_ID'))   --created_by
                  ,sysdate                                   --last_update_date
                  ,to_number(fnd_profile.value('USER_ID'))   --last_updated_by
                  ,to_number(fnd_profile.value('LOGIN_ID')));--last_update_login
              end if;
              update xx_ap_inv_int xaii
              set    xaii.status                        = 'PROCESSED'
                    ,xaii.error_messages                = null
                    ,xaii.org_id                        = v_org_id
                    ,xaii.invoice_id                    = v_invoice_id
                    ,xaii.invoice_line_id               = v_invoice_line_id
                    ,xaii.accts_pay_code_combination_id = v_accts_pay_code_comb
                    ,xaii.dist_code_combination_id      = v_dist_code_comb
                    ,xaii.last_update_date              = sysdate
                    ,xaii.last_update_login             = to_number(fnd_profile.value('LOGIN_ID'))
                    ,xaii.last_updated_by               = to_number(fnd_profile.value('USER_ID'))
              where  1=1
              and    xaii.inv_int_id = i_fact_int_lns.inv_int_id;
              print_trace(p_debug=>p_ext_debug,p_str=>'--  print_lines(+)');
              print_lines(p_inv_int_id=>i_fact_int_lns.inv_int_id,p_debug=>p_ext_debug,p_chardelim=>p_char_delim);
              print_trace(p_debug=>p_ext_debug,p_str=>'--  print_lines(-)');
            exception
              when others then
                v_error_text := v_error_text ||'INS_UPD_ap_invoices_interface_ap_invoice_lines_interface_xx_ap_inv_int.Error: '||sqlerrm;
            end;
          end if;
        end if;
      end loop;
    end if;
  end loop;
  print_trace(p_debug=>p_ext_debug,p_str=>'--  Loop_HDR (-)');
  if p_draft = 'Y' then
    rollback to rstrpnt;
  end if;
  if v_count = 0 then
    v_dummy := fnd_concurrent.set_completion_status('WARNING','No se encontraron registros del lote. Contador: '||v_count);
  end if;
exception
  when others then
    fnd_file.put_line(fnd_file.output,'Error.: '||sqlerrm);
    fnd_file.put_line(fnd_file.log,'Error.: '||sqlerrm);
    v_dummy := fnd_concurrent.set_completion_status('ERROR','Unknown error, please check the log...');
end;
/
