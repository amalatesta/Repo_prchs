REM +==========================================================================+
REM |             Copyright (c) 2017 Oracle Argentina, Buenos Aires            |
REM |                         All rights reserved.                             |
REM +==========================================================================+
REM |  FILENAME                                                                |
REM |    XX_AR_RAXINVB_PK.sql                                                  |
REM |                                                                          |
REM |  DESCRIPTION                                                             |
REM |    Crea el cuerpo del paquete XX_AR_RAXINV_PK                            |
REM |    que contiene funciones y procedimientos para el proceso de            |
REM |    impresion de facturas.                                                |
REM |                                                                          |
REM |  LANGUAGE                                                                |
REM |    PL/SQL                                                                |
REM |                                                                          |
REM |  PRODUCT                                                                 |
REM |    Oracle Financials                                                     |
REM |                                                                          |
REM |  HISTORY                                                                 |
REM |    02-ENE-17 - AMalatesta - DSP - Created                                |
REM |                                                                          |
REM | NOTES                                                                    |
REM |                                                                          |
REM +==========================================================================+

SPOOL XX_AR_RAXINVB_PK.log

prompt =========================================================================
prompt script XX_AR_RAXINVB_PK.sql
prompt =========================================================================

prompt creando cuerpo del paquete xx_ar_raxinv_pk
create or replace package body xx_ar_raxinv_pk as
/* $Id: XX_AR_RAXINVB_PK.sql 1.0 2017-01-02 18:04:00 amalatesta@despegar.com $ */

/*+==========================================================================+*/
/*|             Copyright (c) 2017 Oracle Argentina, Buenos Aires            |*/
/*|                         All rights reserved.                             |*/
/*+==========================================================================+*/
/*|  FILENAME                                                                |*/
/*|    XX_AR_RAXINVB_PK.sql                                                  |*/
/*|                                                                          |*/
/*|  DESCRIPTION                                                             |*/
/*|    Crea el cuerpo del paquete XX_AR_RAXINV_PK                            |*/
/*|    que contiene funciones y procedimientos para el proceso de            |*/
/*|    impresion de facturas.                                                |*/
/*|                                                                          |*/
/*|  LANGUAGE                                                                |*/
/*|    PL/SQL                                                                |*/
/*|                                                                          |*/
/*|  PRODUCT                                                                 |*/
/*|    Oracle Financials                                                     |*/
/*|                                                                          |*/
/*|  HISTORY                                                                 |*/
/*|    02-ENE-17 - AMalatesta - DSP - Created                                |*/
/*|                                                                          |*/
/*| NOTES                                                                    |*/
/*|                                                                          |*/
/*+==========================================================================+*/
  /*--Variables globales--*/
  g_eol                varchar2(2)   := chr(10);
  g_func_currency_code varchar2(3)   := 'CLP';
  g_num_format         varchar2(99)  := '9999999999999999999999999999999999999999999999990.99';
  g_vat_tax            varchar2(240) := 'CL IVA AR';
  cursor c_trxs
    (p_customer_id      in number
    ,p_cust_trx_type_id in number
    ,p_trx_number_from  in varchar2
    ,p_trx_number_to    in varchar2
    ,p_date_from        in date
    ,p_date_to          in date
    ,p_draft_mode       in varchar2)
  is
    select rct.customer_trx_id
          ,'XX_AR_FE_CL_OUT_PRC_DIR' tmp_output_directory
          ,lpad(rct.customer_trx_id ,15 ,'0')||'.tmp' tmp_output_file
          ,'XX_AR_FE_CL_OUT_PRC_DIR' output_directory
          ,lpad(rct.customer_trx_id ,15 ,'0')||'.xml' output_file
          ,rct.trx_number trx_number
          ,rct.trx_date trx_date
          ,rct.org_id rct_org_id
          ,rct.invoice_currency_code invoice_currency_code
          ,rct.attribute15 printing_currency_code
          ,hca.orig_system_reference source_system_number
          ,nvl(hca.attribute20 ,'N') generic_customer
          ,hca.global_attribute10 contributor_source
          ,hca.party_id party_id
          ,hca.cust_account_id cust_account_id
          ,rct.attribute1 customer_name
          ,substr (rct.attribute2 ,1 ,instr(rct.attribute2 ,'|' ,1 ,1)-1) customer_doc_type
          ,substr (rct.attribute2 ,instr(rct.attribute2 ,'|' ,1 ,1)+1) customer_doc_number_full
          ,substr (rct.attribute2 ,instr(rct.attribute2 ,'|' ,1 ,1)+1 , (length (rct.attribute2) - instr(rct.attribute2 ,'|' ,1 ,1)) -1) customer_doc_number
          ,substr (substr (rct.attribute2 ,instr(rct.attribute2 ,'|' ,1 ,1)+1) ,-1) customer_doc_digit
          ,substr (rct.attribute12 ,instr(rct.attribute12 ,'|' ,1 ,3)+1) giro_receptor_code
          ,substr (rct.attribute12 ,instr(rct.attribute12 ,'|' ,1 ,1)+1 , instr(rct.attribute12 ,'|' ,1 ,2) - instr(rct.attribute12 ,'|' ,1 ,1)-1) province_receptor_code
          ,substr (rct.attribute12 ,instr(rct.attribute12 ,'|' ,1 ,2)+1 , instr(rct.attribute12 ,'|' ,1 ,3) - instr(rct.attribute12 ,'|' ,1 ,2)-1) city_receptor_code
          ,substr (rct.attribute12 ,1 ,instr(rct.attribute12 ,'|' ,1 ,1)-1) pais_receptor_code
            /*-- Inicio de datos que se recalculan posteriormente. Se incluyen solo para la definicion del tipo de dato*/
          ,decode (xarir.total_amount ,null ,null ,null) net_amount
          ,decode (xarir.total_amount ,null ,null ,null) net_amount_pcc
          ,decode (xarir.total_amount ,null ,null ,null) tax_amount
          ,decode (xarir.total_amount ,null ,null ,null) tax_amount_pcc
          ,decode (xarir.total_amount ,null ,null ,null) total_amount
          ,decode (xarir.total_amount ,null ,null ,null) total_amount_pcc
          ,decode (xarir.total_amount ,null ,null ,null) net_amount_exento
          ,decode (xarir.total_amount ,null ,null ,null) net_amount_exento_pcc
          ,decode (xarir.total_amount ,null ,null ,null) net_amount_gravado
          ,decode (xarir.total_amount ,null ,null ,null) net_amount_gravado_pcc
          ,decode (xarir.total_amount ,null ,null ,null) tax_amount_iva
          ,decode (xarir.total_amount ,null ,null ,null) tax_amount_iva_pcc
          ,decode (xarir.total_amount ,null ,null ,null) vat_percentage
          ,decode (flv_giro_emisor.meaning ,null ,null ,null) giro_receptor_meaning
          ,decode (geo.geography_name ,null ,null ,null) province_receptor_name
          ,decode (geo.geography_name ,null ,null ,null) city_receptor_name
          ,decode (geo.geography_name ,null ,null ,null) pais_receptor_name
          ,decode (rct.attribute11 ,null ,null ,null) customer_address
          ,decode (hl_org.country ,null ,null ,null) collection_country
          ,decode (rct.customer_trx_id ,null ,null ,null) ref_customer_trx_id
          ,decode (rctt.attribute11 ,null ,null ,null) ref_electr_doc_type
          ,decode (rct.trx_number ,null ,null ,null) ref_trx_number
          ,decode (rct.trx_date ,null ,null ,null) ref_trx_date
          ,decode (rct.attribute9 ,null ,null ,null) ref_procesado_fc_electronica
            /*--  Fin de datos que se recalculan posteriormente*/
          ,rct.attribute11 customer_base_address
          ,rct.attribute3 customer_email
          ,rct.attribute4 request_number
          ,rct.attribute13 purchase_order
          ,rbs.batch_source_type batch_source_type
          ,rct.purchase_order hotel_stmt_trx_number
          ,rct.comments comments
          ,rct.doc_sequence_value doc_sequence_value
          ,nvl(rct.exchange_rate ,1) exchange_rate
          ,rct.bill_to_site_use_id bill_to_site_use_id
          ,rctt.type document_type
          ,rctt.name cust_trx_type_name
          ,rctt.attribute11 electr_doc_type
          ,rctt.attribute13 electr_serv_type
          ,rctt.attribute1 cust_trx_concept
          ,rctt.attribute2 collection_type
          ,nvl(rctt.attribute13 ,'N') print_address_flag
          ,rct.legal_entity_id legal_entity_id
          ,xep.name legal_entity_name
          ,xep.legal_entity_identifier legal_entity_identifier
          ,flv_giro_emisor.description giro_emisor_meaning
          ,xep.attribute1 acteco_code
          ,hl_org.address_line_1 expedition_address
          ,hl_org.town_or_city expedition_place
          ,hl_org.country org_country
          ,get_receipt_method(rct.receipt_method_id ,rctt.type ,rct.previous_customer_trx_id ,rctt.attribute2) receipt_method_name
          ,xarir.status status
          ,xarir.error_code error_code
          ,xarir.error_messages error_messages
          ,nvl(flv_status.attribute1 ,'N') resend_status_flag
          ,rct.status_trx status_trx
          ,empty_clob() send_file
    from   ra_customer_trx           rct
          ,ra_cust_trx_types         rctt
          ,ra_batch_sources          rbs
          ,xx_ar_reg_invoice_request xarir
          ,hz_cust_accounts          hca
          ,xle_entity_profiles       xep
          ,hr_organization_units     hou
          ,hr_locations              hl_org
          ,fnd_lookup_values_vl      flv_status
          ,fnd_lookup_values_vl      flv_giro_emisor
          ,hz_geographies            geo
    where 1 = 1
    and rct.trx_date between nvl(trunc(p_date_from) ,rct.trx_date) and nvl(trunc(p_date_to + 1) - 1/24/60/60 ,rct.trx_date)
    and rct.trx_number between nvl(p_trx_number_from ,rct.trx_number) and nvl(p_trx_number_to ,rct.trx_number)
    and rct.cust_trx_type_id     = nvl(p_cust_trx_type_id ,rct.cust_trx_type_id)
    and rct.bill_to_customer_id  = nvl(p_customer_id ,rct.bill_to_customer_id)
    and rct.complete_flag        = 'Y'
    --and nvl(rct.attribute9 ,'N') = 'N' --PAM PD Procesado
    and p_draft_mode             = 'N'
    and rct.batch_source_id      = rbs.batch_source_id
    --and rbs.attribute3           = 'Y' --Fact. Elec: Origen de Comprobante Electronico
    and rct.customer_trx_id      = xarir.customer_trx_id (+)
    and nvl(xarir.status ,'@')  in ('@' ,'PROCESSING_ERROR_ORACLE' ,'ERROR_OAS')
    and rct.cust_trx_type_id     = rctt.cust_trx_type_id
    --and rctt.attribute12         = 'Y' --Fact. Elec: Comprobante Electronico
    and rct.org_id               = hou.organization_id
    and hou.location_id          = hl_org.location_id
    and rct.bill_to_customer_id  = hca.cust_account_id
    and rct.legal_entity_id      = xep.legal_entity_id
    and 'INVOICE_TRX_STATUS'     = flv_status.lookup_type (+)
    and rct.status_trx           = flv_status.lookup_code (+)
    and 'XX_GIROS_COMERCIALES'   = flv_giro_emisor.lookup_type (+)
    and xep.attribute1           = flv_giro_emisor.lookup_code (+)
    and xep.geography_id         = geo.geography_id
    union all
    select rct.customer_trx_id
          ,'XX_AR_FE_CL_OUT_PRC_DIR' tmp_output_directory
          ,lpad(rct.customer_trx_id ,15 ,'0')||'.tmp' tmp_output_file
          ,'XX_AR_FE_CL_OUT_PRC_DIR' output_directory
          ,lpad(rct.customer_trx_id ,15 ,'0')||'.xml' output_file
          ,rct.trx_number trx_number
          ,rct.trx_date trx_date
          ,rct.org_id rct_org_id
          ,rct.invoice_currency_code invoice_currency_code
          ,rct.attribute15 printing_currency_code
          ,hca.orig_system_reference source_system_number
          ,nvl(hca.attribute20 ,'N') generic_customer
          ,hca.global_attribute10 contributor_source
          ,hca.party_id party_id
          ,hca.cust_account_id cust_account_id
          ,rct.attribute1 customer_name
          ,substr (rct.attribute2 ,1 ,instr(rct.attribute2 ,'|' ,1 ,1)-1) customer_doc_type
          ,substr (rct.attribute2 ,instr(rct.attribute2 ,'|' ,1 ,1)+1) customer_doc_number_full
          ,substr (rct.attribute2 ,instr(rct.attribute2 ,'|' ,1 ,1)+1 , (length (rct.attribute2) - instr(rct.attribute2 ,'|' ,1 ,1)) -1) customer_doc_number
          ,substr (substr (rct.attribute2 ,instr(rct.attribute2 ,'|' ,1 ,1)+1) ,-1) customer_doc_digit
          ,substr (rct.attribute12 ,instr(rct.attribute12 ,'|' ,1 ,3)+1) giro_receptor_code
          ,substr (rct.attribute12 ,instr(rct.attribute12 ,'|' ,1 ,1)+1 , instr(rct.attribute12 ,'|' ,1 ,2) - instr(rct.attribute12 ,'|' ,1 ,1)-1) province_receptor_code
          ,substr (rct.attribute12 ,instr(rct.attribute12 ,'|' ,1 ,2)+1 , instr(rct.attribute12 ,'|' ,1 ,3) - instr(rct.attribute12 ,'|' ,1 ,2)-1) city_receptor_code
          ,substr (rct.attribute12 ,1 ,instr(rct.attribute12 ,'|' ,1 ,1)-1) pais_receptor_code
            /*-- Inicio de datos que se recalculan posteriormente. Se incluyen solo para la definicion del tipo de dato*/
          ,decode (xarir.total_amount ,null ,null ,null) net_amount
          ,decode (xarir.total_amount ,null ,null ,null) net_amount_pcc
          ,decode (xarir.total_amount ,null ,null ,null) tax_amount
          ,decode (xarir.total_amount ,null ,null ,null) tax_amount_pcc
          ,decode (xarir.total_amount ,null ,null ,null) total_amount
          ,decode (xarir.total_amount ,null ,null ,null) total_amount_pcc
          ,decode (xarir.total_amount ,null ,null ,null) net_amount_exento
          ,decode (xarir.total_amount ,null ,null ,null) net_amount_exento_pcc
          ,decode (xarir.total_amount ,null ,null ,null) net_amount_gravado
          ,decode (xarir.total_amount ,null ,null ,null) net_amount_gravado_pcc
          ,decode (xarir.total_amount ,null ,null ,null) tax_amount_iva
          ,decode (xarir.total_amount ,null ,null ,null) tax_amount_iva_pcc
          ,decode (xarir.total_amount ,null ,null ,null) vat_percentage
          ,decode (flv_giro_emisor.meaning ,null ,null ,null) giro_receptor_meaning
          ,decode (geo.geography_name ,null ,null ,null) province_receptor_name
          ,decode (geo.geography_name ,null ,null ,null) city_receptor_name
          ,decode (geo.geography_name ,null ,null ,null) pais_receptor_name
          ,decode (rct.attribute11 ,null ,null ,null) customer_address
          ,decode (hl_org.country ,null ,null ,null) collection_country
          ,decode (rct.customer_trx_id ,null ,null ,null) ref_customer_trx_id
          ,decode (rctt.attribute11 ,null ,null ,null) ref_electr_doc_type
          ,decode (rct.trx_number ,null ,null ,null) ref_trx_number
          ,decode (rct.trx_date ,null ,null ,null) ref_trx_date
          ,decode (rct.attribute9 ,null ,null ,null) ref_procesado_fc_electronica
            /*--  Fin de datos que se recalculan posteriormente*/
          ,rct.attribute11 customer_base_address
          ,rct.attribute3 customer_email
          ,rct.attribute4 request_number
          ,rct.attribute13 purchase_order
          ,rbs.batch_source_type batch_source_type
          ,rct.purchase_order hotel_stmt_trx_number
          ,rct.comments comments
          ,rct.doc_sequence_value doc_sequence_value
          ,nvl(rct.exchange_rate ,1) exchange_rate
          ,rct.bill_to_site_use_id bill_to_site_use_id
          ,rctt.type document_type
          ,rctt.name cust_trx_type_name
          ,rctt.attribute11 electr_doc_type
          ,rctt.attribute13 electr_serv_type
          ,rctt.attribute1 cust_trx_concept
          ,rctt.attribute2 collection_type
          ,nvl(rctt.attribute13 ,'N') print_address_flag
          ,rct.legal_entity_id legal_entity_id
          ,xep.name legal_entity_name
          ,xep.legal_entity_identifier legal_entity_identifier
          ,flv_giro_emisor.description giro_emisor_meaning
          ,xep.attribute1 acteco_code
          ,hl_org.address_line_1 expedition_address
          ,hl_org.town_or_city expedition_place
          ,hl_org.country org_country
          ,get_receipt_method(rct.receipt_method_id ,rctt.type ,rct.previous_customer_trx_id ,rctt.attribute2) receipt_method_name
          ,xarir.status status
          ,xarir.error_code error_code
          ,xarir.error_messages error_messages
          ,nvl(flv_status.attribute1 ,'N') resend_status_flag
          ,rct.status_trx status_trx
          ,empty_clob() send_file
    from   ra_customer_trx           rct
          ,ra_cust_trx_types         rctt
          ,ra_batch_sources          rbs
          ,xx_ar_reg_invoice_request xarir
          ,hz_cust_accounts          hca
          ,xle_entity_profiles       xep
          ,hr_organization_units     hou
          ,hr_locations              hl_org
          ,fnd_lookup_values_vl      flv_status
          ,fnd_lookup_values_vl      flv_giro_emisor
          ,hz_geographies            geo
    where 1 = 1
    and rct.trx_date between nvl(trunc(p_date_from) ,rct.trx_date) and nvl(trunc(p_date_to + 1) - 1/24/60/60 ,rct.trx_date)
    and rct.trx_number between p_trx_number_from and p_trx_number_to
    and rct.cust_trx_type_id    = nvl(p_cust_trx_type_id ,rct.cust_trx_type_id)
    and rct.bill_to_customer_id = nvl(p_customer_id ,rct.bill_to_customer_id)
    and rct.complete_flag       = 'Y'
    and p_draft_mode            = 'Y'
    and rct.batch_source_id     = rbs.batch_source_id
    --and rbs.attribute3          = 'Y' --Fact. Elec: Origen de Comprobante Electronico
    and rct.customer_trx_id     = xarir.customer_trx_id (+)
    and rct.cust_trx_type_id    = rctt.cust_trx_type_id
    --and rctt.attribute12        = 'Y' --Fact. Elec: Comprobante Electronico
    and rct.org_id              = hou.organization_id
    and hou.location_id         = hl_org.location_id
    and rct.bill_to_customer_id = hca.cust_account_id
    and rct.legal_entity_id     = xep.legal_entity_id
    and 'INVOICE_TRX_STATUS'    = flv_status.lookup_type (+)
    and rct.status_trx          = flv_status.lookup_code (+)
    and 'XX_GIROS_COMERCIALES'  = flv_giro_emisor.lookup_type (+)
    and xep.attribute1          = flv_giro_emisor.lookup_code (+)
    and xep.geography_id        = geo.geography_id;
  cursor c_trx_lines
    (p_customer_trx_id        in number
    ,p_vat_tax                in varchar2
    ,p_printing_currency_code in varchar2
    ,p_invoice_currency_code  in varchar2
    ,p_exchange_rate          in number
    ,p_cust_trx_concept       in varchar2)
  is
    select abs(nvl(rctll.quantity_invoiced ,rctll.quantity_credited)) quantity
          ,get_inventory_item_desc(nvl(rctll.warehouse_id ,osp.master_organization_id) , rctll.inventory_item_id ,p_cust_trx_concept ,xaea.attribute50) item_description
          ,max(rctll.inventory_item_id) inventory_item_id
          ,max(nvl(rctll.warehouse_id ,osp.master_organization_id)) organization_id
          ,sum(nvl(taxes.tax_amt ,0) + nvl (rctll.extended_amount ,0)) total_amount /*-- Monto Total*/
          ,sum(decode (p_printing_currency_code ,p_invoice_currency_code , (nvl(taxes.tax_amt ,0) + nvl (rctll.extended_amount ,0)) , (round (nvl(taxes.tax_amt ,0) * nvl(p_exchange_rate ,1) ,2) + nvl (rctlgd.acctd_amount ,0)))) total_amount_pcc /*-- Monto Total en PCC*/
          ,sum( nvl (rctll.extended_amount ,0)) net_amount /*-- Monto Neto (Sin Impuestos)*/
          ,sum(decode (p_printing_currency_code ,p_invoice_currency_code , nvl (rctll.extended_amount ,0) ,nvl (rctlgd.acctd_amount ,0) )) net_amount_pcc /*-- Monto Neto (Sin Impuestos) en PCC*/
          ,sum(nvl(taxes.tax_amt ,0)) tax_amount /*-- Monto Impuestos*/
          ,sum(decode (p_printing_currency_code ,p_invoice_currency_code , nvl(taxes.tax_amt ,0) ,round (nvl(taxes.tax_amt ,0) * nvl(p_exchange_rate ,1) ,2))) tax_amount_pcc /*-- Monto Impuestos en PCC*/
          ,sum(nvl(taxes.tax_amt_iva ,0)) tax_amount_iva /*-- Monto Impuestos Solo IVA*/
          ,sum(decode (p_printing_currency_code ,p_invoice_currency_code , nvl(taxes.tax_amt_iva ,0) ,round (nvl(taxes.tax_amt_iva ,0) * nvl(p_exchange_rate ,1) ,2))) tax_amount_iva_pcc /*-- Monto Impuestos Solo IVA en PCC*/
    from   ra_customer_trx_lines rctll
          ,oe_order_lines ool
          ,ra_cust_trx_line_gl_dist rctlgd
          ,oe_system_parameters osp
          ,xx_all_extra_attributes xaea
          ,(select sum(nvl(zx_line.tax_amt ,0)) tax_amt
                  ,sum(decode (zx_rate.tax ,p_vat_tax ,nvl(zx_line.tax_amt ,0) ,0)) tax_amt_iva
                  ,rctlt.customer_trx_id
                  ,rctlt.link_to_cust_trx_line_id
            from   ra_customer_trx_lines rctlt
                  ,zx_lines              zx_line
                  ,zx_taxes_b            zx_tax
                  ,zx_rates_vl           zx_rate
            where  1=1
            and rctlt.line_type(+)     = 'TAX'
            and zx_tax.tax_id(+)       = zx_line.tax_id
            and zx_rate.tax_rate_id(+) = zx_line.tax_rate_id
            and zx_line.tax_line_id(+) = rctlt.tax_line_id
            and zx_line.entity_code    = 'TRANSACTIONS'
            and zx_line.application_id = 222
            group by rctlt.customer_trx_id
            ,rctlt.link_to_cust_trx_line_id) taxes
    where  1=1
    and rctll.customer_trx_id                                  = p_customer_trx_id
    and rctll.line_type                                        = 'LINE'
    and rctll.interface_line_attribute6                        = ool.line_id(+)
    and xaea.source_table(+)                                   = 'OE_ORDER_LINES'
    and to_char(ool.line_id)                                   = xaea.source_id_char1(+)
    and rctll.customer_trx_id                                  = rctlgd.customer_trx_id
    and rctll.customer_trx_line_id                             = rctlgd.customer_trx_line_id
    and rctll.customer_trx_id                                  = taxes.customer_trx_id(+)
    and rctll.customer_trx_line_id                             = taxes.link_to_cust_trx_line_id(+)
    and nvl(rctll.quantity_invoiced ,rctll.quantity_credited) != 0
    group by abs(nvl(rctll.quantity_invoiced,rctll.quantity_credited))
         ,get_inventory_item_desc(nvl(rctll.warehouse_id,osp.master_organization_id),rctll.inventory_item_id,p_cust_trx_concept,xaea.attribute50);
  cursor c_trx_lines_terceros
    (p_customer_trx_id        in number
    ,p_printing_currency_code in varchar2
    ,p_invoice_currency_code  in varchar2
    ,p_exchange_rate          in number)
  is
    select get_desc_tercero(osp.master_organization_id,rctll.inventory_item_id,xaea.attribute50,xaea.attribute46,rctll.org_id,rctll.attribute6) tercero_description
          ,sum(decode(p_printing_currency_code,p_invoice_currency_code,nvl(fnd_number.canonical_to_number(replace(xaea.attribute45,',','.')),0),round(nvl(fnd_number.canonical_to_number(replace(xaea.attribute45,',','.')),0) * nvl(p_exchange_rate,1),2))) tercero_amount
    from   ra_customer_trx_lines rctll
          ,oe_system_parameters osp
          ,oe_order_lines ool
          ,xx_all_extra_attributes xaea
    where  1=1
    and rctll.customer_trx_id                                  = p_customer_trx_id
    and rctll.line_type                                        = 'LINE'
    and rctll.interface_line_attribute6                        = ool.line_id(+)
    and xaea.source_table(+)                                   = 'OE_ORDER_LINES'
    and to_char(ool.line_id)                                   = xaea.source_id_char1(+)
    and nvl(rctll.quantity_invoiced ,rctll.quantity_credited) != 0
    group by get_desc_tercero(osp.master_organization_id,rctll.inventory_item_id,xaea.attribute50,xaea.attribute46,rctll.org_id,rctll.attribute6);
  cursor c_trx_lines_inf_adic
    (p_customer_trx_id       in number
    ,p_collection_type       in varchar2
    ,p_hotel_stmt_trx_number in varchar2)
  is
    select distinct 'Extracto: '||p_hotel_stmt_trx_number info_adic
    from   dual
    where  1=1
    and    p_collection_type      = 'PD'
    and    p_hotel_stmt_trx_number is not null
    union all /*-- Transacciones con Prepago*/
    select distinct 'Reserva '
          ||rctl.interface_line_attribute15
          ||' - '
          ||flv2.meaning
          ||' - '
          || nvl (rctd.xx_ar_passenger_name ,nvl (rct_dfv.xx_ar_customer ,ac.customer_name))
          ||' - '
          || decode (rctl.attribute_category ,'0001' ,flv2.description , substr (rctd.xx_ar_provider ,instr (rctd.xx_ar_provider ,'_') + 1 ,length(rctd.xx_ar_provider)))
          || ' '
          || decode (rctl.attribute_category ,'0001' ,' - #Tkt '
          || rctd.xx_ar_ticket_number ,null) info_adic
    from   ra_customer_trx_lines         rctl
          ,ra_customer_trx_lines_all_dfv rctd
          ,fnd_lookup_values_vl          flv
          ,ra_customer_trx               rct
          ,ra_customer_trx_all_dfv       rct_dfv
          ,fnd_lookup_values_vl          flv2
          ,ar_customers                  ac
    where  1=1
    and p_collection_type                  = 'PP'
    and rct.customer_trx_id                = p_customer_trx_id
    and rctl.customer_trx_id               = rct.customer_trx_id
    and nvl(rctl.attribute_category ,'@') != '0008' /*-- No se muestran datos de FEE*/
    and rctl.line_type                     = 'LINE'
    and rct.rowid                          = rct_dfv.row_id
    and rct.bill_to_customer_id            = ac.customer_id(+)
    and rctl.rowid                         = rctd.row_id
    and rctd.xx_ar_provider                = flv.lookup_code(+)
    and flv.lookup_type(+)                 = 'XX_AP_CARRIER_CODES'
    and rctl.attribute_category            = flv2.lookup_code(+)
    and flv2.lookup_type(+)                = 'XX_OE_TIPO_PRODUCTO';
  type trx_table_type is table of c_trxs%rowtype index by binary_integer;
  v_trxs_tbl trx_table_type;
  v_trxs_aux_tbl trx_table_type;
/*=========================================================================+
|                                                                          |
| Private Procedure                                                        |
|    print_output                                                          |
|                                                                          |
| Description                                                              |
|    Procedimiento privado para imprimir                                   |
|                                                                          |
| Parameters                                                               |
|    p_print_output in varchar2                                            |
|                                                                          |
+=========================================================================*/
  procedure print_output
    (p_print_output in varchar2)
  is
  begin
    fnd_file.put_line(fnd_file.output,p_print_output);
  end print_output;
/*=========================================================================+
|                                                                          |
| Private Procedure                                                        |
|    indent                                                                |
|                                                                          |
| Description                                                              |
|    Procedimiento privado que indenta.                                    |
|                                                                          |
| Parameters                                                               |
|    p_type IN     VARCHAR2 Tipo de indentacion (+: agrega indentacion)    |
|                                               (-: elimina indentacion)   |
|                                                                          |
+=========================================================================*/
  procedure indent
    (p_type in varchar2)
  is
    v_calling_sequence varchar2(2000);
    v_indent_length    number(15);
  begin
    v_calling_sequence := 'xx_ar_raxinv_pk.indent';
    v_indent_length    := 3;
    if p_type           = '+' then
      g_indent         := replace(rpad(' ' ,nvl(length(g_indent) ,0 ) + v_indent_length ) ,' ' ,' ' );
    elsif p_type        = '-' then
      g_indent         := replace(rpad(' ' ,nvl(length(g_indent) ,0 ) -
      v_indent_length ) ,' ' ,' ' );
    end if;
  exception
  when others then
    raise_application_error(-20000 ,v_calling_sequence || '. Error general indentando linea. ' || sqlerrm );
  end indent;
/*=========================================================================+
|                                                                          |
| Private Procedure                                                        |
|    display_message_split                                                 |
|                                                                          |
| Description                                                              |
|    Procedimiento que despliega un mensaje en varias lineas, de acuerdo   |
|    al largo a la linea.                                                  |
|                                                                          |
| Parameters                                                               |
|    p_output  IN     VARCHAR2 Tipo de salida para desplegar.              |
|    p_message IN     VARCHAR2 Mensaje.                                    |
|                                                                          |
+=========================================================================*/
  procedure display_message_split(
      p_output in varchar2 ,
      p_message in varchar2 )
  is
    /*-- ---------------------------------------------------------------------------*/
    /*-- Declaracion de Variables.*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence varchar2(2000);
    v_cnt              number(15);
    v_message_length   number(15);
    v_message          varchar2(4000);
    v_mesg_error       varchar2(32767);
  begin
    /*-- ---------------------------------------------------------------------------*/
    /*-- Inicializo variables Grales de Ejecucion.*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence := 'xx_ar_raxinv_pk.display_message_split';
    /*-- ---------------------------------------------------------------------------*/
    /*-- Obtengo la longitud del mensaje.*/
    /*-- ---------------------------------------------------------------------------*/
    v_message_length   := g_message_length;
    if p_output         = 'DBMS' and g_message_length > 255 then
      v_message_length := 255;
    end if;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Despliego el mensaje.*/
    /*-- ---------------------------------------------------------------------------*/
    for v_cnt in 1..40000/v_message_length
    loop
      v_message              := null;
      if v_cnt                = 1 then
        if length(p_message) >= v_cnt * v_message_length then
          v_message          := substr(p_message ,1 ,v_cnt * v_message_length );
        else
          if length(p_message) >= 1 and length(p_message) < v_cnt * v_message_length then
            v_message          := substr(p_message ,1 );
          end if;
        end if;
      else
        if length(p_message) >= v_cnt * v_message_length then
          v_message          := substr(p_message ,((v_cnt-1 ) * v_message_length ) + 1 ,v_message_length );
        else
          if length(p_message) >= ((v_cnt-1) * v_message_length) and length(p_message) < v_cnt * v_message_length then
            v_message          := substr(p_message ,((v_cnt-1 ) * v_message_length ) + 1 );
          end if;
        end if;
      end if;
      v_message    := ltrim(rtrim(v_message));
      if v_message is not null then
        if p_output = 'DBMS' then
          dbms_output.put_line(v_message);
        elsif p_output = 'CONC_LOG' then
          fnd_file.put(fnd_file.log ,v_message );
          fnd_file.new_line(fnd_file.log ,1 );
        end if;
      end if;
    end loop;
  exception
  when others then
    null;
  end display_message_split;
/*=========================================================================+
|                                                                          |
| Private Procedure                                                        |
|    debug                                                                 |
|                                                                          |
| Description                                                              |
|    Procedimiento privado que escribe el debug.                           |
|                                                                          |
| Parameters                                                               |
|    p_message IN      VARCHAR2 Mensaje de Debug.                          |
|    p_type    IN      VARCHAR2 Tipo de Mensaje de Debug.                  |
|                                                                          |
+=========================================================================*/
  procedure debug(
      p_message in varchar2 ,
      p_type in varchar2 default null )
  is
    /*-- ---------------------------------------------------------------------------*/
    /*-- Declaracion de Variables.*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence varchar2(2000);
    v_message          varchar2(32767);
  begin
    /*-- ---------------------------------------------------------------------------*/
    /*-- Inicializo variables Grales de Ejecucion.*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence := 'xx_ar_raxinv_pk.debug';
    /*-- ---------------------------------------------------------------------------*/
    /*-- Realizo el debug.*/
    /*-- ---------------------------------------------------------------------------*/
    if g_debug_flag = 'Y' then
      if p_type    is null then
        v_message  := substr(p_message ,1 ,32767 );
      else
        v_message := substr(to_char(sysdate ,'DD-MM-YYYY HH24:MI:SS' ) || ' - ' || p_message ,1 ,32767 );
      end if;
      display_message_split(p_output => g_debug_mode ,p_message => v_message );
    end if;
  exception
  when others then
    null;
  end debug;
/*=========================================================================+
|                                                                          |
| Private Function                                                         |
|    print_text                                                            |
|                                                                          |
| Description                                                              |
|    Funcion privada que imprime salida de la interface.                   |
|                                                                          |
| Parameters                                                               |
|    p_interface_id IN      NUMBER   Id de la interface.                   |
|    p_request_id   IN      NUMBER   Id del concurrente.                   |
|    p_print_output IN      VARCHAR2 Imprime interface en la salida del    |
|                                    concurrente.                          |
|    p_mesg_error   OUT     VARCHAR2 Mensaje de error.                     |
|                                                                          |
+=========================================================================*/
  function print_text(
      p_print_output in varchar2 ,
      p_mesg_error out varchar2 )
    return boolean
  is
    /*-- ---------------------------------------------------------------------------*/
    /*-- Declaracion de Variables.*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence varchar2(2000);
    v_file utl_file.file_type;
    v_output_directory varchar2(2000);
    v_output_file      varchar2(2000);
    v_text1            varchar2(2000);
    v_text2            varchar2(2000);
    v_text3            varchar2(2000);
    v_amount           number;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Declaracion de Excepciones.*/
    /*-- ---------------------------------------------------------------------------*/
    e_invalid_directory exception;
    e_invalid_file_name exception;
    pragma exception_init(e_invalid_directory ,-29280);
    pragma exception_init(e_invalid_file_name ,-29288);
  begin
    /*-- ---------------------------------------------------------------------------*/
    /*-- Inicializo variables Grales de Ejecucion.*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence := 'xx_ar_raxinv_pk.print_text';
    debug(g_indent || v_calling_sequence ,'1' );
    /*-- ---------------------------------------------------------------------------*/
    /*-- Despliego Parametros.*/
    /*-- ---------------------------------------------------------------------------*/
    debug(g_indent || v_calling_sequence || '. Imprime interface en la salida del concurrente: ' || p_print_output ,'1' );
    /*-- ---------------------------------------------------------------------------*/
    /*-- Recorro la salida de interface.*/
    /*-- ---------------------------------------------------------------------------*/
    debug(g_indent || v_calling_sequence || '. Recorriendo la salida de interface' ,'1' );
    indent('+');
    for i in 1 .. v_trxs_tbl.count
    loop
      v_text1 := null;
      v_text2 := null;
      v_text3 := null;
      /*-- -----------------------------------------------------------------------*/
      /*-- Verifico si estoy imprimiendo la interface en la salida del*/
      /*-- concurrente.*/
      /*-- -----------------------------------------------------------------------*/
      if p_print_output is null then
        /*-- --------------------------------------------------------------------*/
        /*-- Verifico si cambio el directorio o archivo de salida.*/
        /*-- --------------------------------------------------------------------*/
        if nvl(v_trxs_tbl(i).output_directory ,'@') != nvl(v_output_directory ,'@') or nvl(v_trxs_tbl(i).output_file ,'@') != nvl(v_output_file ,'@') then
          /*-- -----------------------------------------------------------------*/
          /*-- Verifico si el archivo de salida anterior esta abierto.*/
          /*-- -----------------------------------------------------------------*/
          if utl_file.is_open(v_file) then
            fnd_file.put(fnd_file.log ,'Se genero el archivo de salida: ' || v_output_file || ' en el directorio: ' || v_output_directory );
            fnd_file.new_line(fnd_file.log ,1);
            debug(g_indent || v_calling_sequence || '. Cerrando archivo de salida: ' || v_output_file || ' en el directorio: ' || v_output_directory ,'1' );
            begin
              utl_file.fclose(v_file);
            exception
            when others then
              p_mesg_error := v_calling_sequence || '. Error cerrando archivo de salida: ' || v_output_file || ' en el directorio: ' || v_output_directory || '. ' || sqlerrm;
              exit;
            end;
          end if;
          /*-- -----------------------------------------------------------------*/
          /*-- Verifico si hay que generar un nuevo archivo de salida.*/
          /*-- -----------------------------------------------------------------*/
          if v_trxs_tbl(i).output_directory is not null and v_trxs_tbl(i).output_file is not null and v_trxs_tbl(i).status = 'NEW' then
            /*-- --------------------------------------------------------------*/
            /*-- Genero el nuevo archivo de salida.*/
            /*-- --------------------------------------------------------------*/
            debug(g_indent || v_calling_sequence || '. Generando archivo de salida: ' || v_trxs_tbl(i).output_file || ' en el directorio: ' || v_trxs_tbl(i).output_directory ,'1' );
            begin
              v_file := utl_file.fopen(v_trxs_tbl(i).output_directory ,v_trxs_tbl(i).output_file ,'w' );
            exception
            when e_invalid_directory then
              p_mesg_error := 'Directorio de salida invalido: ' || v_trxs_tbl(i).output_directory;
              exit;
            when e_invalid_file_name then
              p_mesg_error := 'Archivo de salida invalido: ' || v_trxs_tbl(i).output_file;
              exit;
            when others then
              p_mesg_error := 'Error generando archivo de salida: ' || v_trxs_tbl(i).output_file || ' en el directorio: ' || v_trxs_tbl(i).output_directory || '. ' || sqlerrm;
              exit;
            end;
          end if;
        end if;
        /*-- --------------------------------------------------------------------*/
        /*-- Verifico si hay que imprimir el texto en el archivo de salida.*/
        /*-- --------------------------------------------------------------------*/
        if v_trxs_tbl(i).output_directory is not null and v_trxs_tbl(i).output_file is not null and v_trxs_tbl(i).status = 'NEW' then
          /*-- -----------------------------------------------------------------*/
          /*-- Imprimo el texto en el archivo de salida.*/
          /*-- -----------------------------------------------------------------*/
          begin
            debug(g_indent || v_calling_sequence || '. Leyendo lob' ,'1' );
            v_amount                                        := 2000;
            if (dbms_lob.getlength(v_trxs_tbl(i).send_file) != 0) then
              dbms_lob.read(v_trxs_tbl(i).send_file ,v_amount ,1 ,v_text1);
            end if;
            debug(g_indent || v_calling_sequence || '. v_text1: ' || v_text1 ,'1' );
            if (dbms_lob.getlength(v_trxs_tbl(i).send_file) > 2000) then
              dbms_lob.read(v_trxs_tbl(i).send_file ,v_amount ,2001 ,v_text2);
            end if;
            if (dbms_lob.getlength(v_trxs_tbl(i).send_file) > 4000) then
              dbms_lob.read(v_trxs_tbl(i).send_file ,v_amount ,4001 ,v_text3);
            end if;
            utl_file.put_line(v_file ,v_text1 || v_text2 || v_text3 );
            utl_file.fflush(v_file);
          exception
          when others then
            p_mesg_error := v_calling_sequence || '. Error imprimiendo texto ' || 'en el archivo de salida: ' || v_trxs_tbl(i).output_file || ' en el directorio: ' || v_trxs_tbl(i).output_directory || '. ' || sqlerrm;
            exit;
          end;
        end if;
      else
        /*-- -----------------------------------------------------------------*/
        /*-- Imprimo el texto en la salida del concurrente.*/
        /*-- -----------------------------------------------------------------*/
        begin
          if (v_trxs_tbl(i).status = 'ERROR') then
            fnd_file.put(fnd_file.output ,'Numero Factura: '||v_trxs_tbl(i).trx_number || ' Error: '||v_trxs_tbl(i).error_messages );
            fnd_file.new_line(fnd_file.output ,1 );
            fnd_file.put(fnd_file.output ,'----------------------------------------------------------' );
            fnd_file.new_line(fnd_file.output ,1 );
          else
            v_amount := 2000;
            debug(g_indent || v_calling_sequence || '. Leyendo Lob 2' ,'1' );
            if (dbms_lob.getlength(v_trxs_tbl(i).send_file) > 0) then
              dbms_lob.read(v_trxs_tbl(i).send_file ,v_amount ,1 ,v_text1);
              debug(g_indent || v_calling_sequence || '. v_text1: ' || v_text1 ,'1' );
            end if;
            if (dbms_lob.getlength(v_trxs_tbl(i).send_file) > 2000) then
              dbms_lob.read(v_trxs_tbl(i).send_file ,v_amount ,2001 ,v_text2);
            end if;
            if (dbms_lob.getlength(v_trxs_tbl(i).send_file) > 4000) then
              dbms_lob.read(v_trxs_tbl(i).send_file ,v_amount ,4001 ,v_text3);
            end if;
            --fnd_file.put(fnd_file.output ,'Numero Factura: ' || v_trxs_tbl(i).trx_number );
            --fnd_file.new_line(fnd_file.output ,1 );
            fnd_file.put(fnd_file.output ,v_text1 || v_text2 || v_text3 );
            fnd_file.new_line(fnd_file.output ,1 );
            --fnd_file.put(fnd_file.output ,'----------------------------------------------------------' );
            --fnd_file.new_line(fnd_file.output ,1 );
          end if;
        exception
        when others then
          p_mesg_error := v_calling_sequence || '. Error imprimiendo texto ' || 'en la salida del concurrente. ' || sqlerrm;
          exit;
        end;
      end if;
      v_output_directory := v_trxs_tbl(i).output_directory;
      v_output_file      := v_trxs_tbl(i).output_file;
    end loop;
    indent('-');
    /*-- ---------------------------------------------------------------------------*/
    /*-- Verifico si se produjo algun error.*/
    /*-- ---------------------------------------------------------------------------*/
    if p_mesg_error is not null then
      return (false);
    end if;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Verifico si tengo que cerrar el ultimo archivo de salida generado.*/
    /*-- ---------------------------------------------------------------------------*/
    if p_print_output       is null then
      if v_output_directory is not null and v_output_file is not null and utl_file.is_open(v_file) then
        fnd_file.put(fnd_file.log ,'Se genero el archivo de salida: ' || v_output_file || ' en el directorio: ' || v_output_directory );
        fnd_file.new_line(fnd_file.log ,1);
        debug(g_indent || v_calling_sequence || '. Cerrando archivo de salida: ' || v_output_file || ' en el directorio: ' || v_output_directory ,'1' );
        begin
          utl_file.fclose(v_file);
        exception
        when others then
          p_mesg_error := v_calling_sequence || '. Error cerrando archivo de salida: ' || v_output_file || ' en el directorio: ' || v_output_directory || '. ' || sqlerrm;
          return (false);
        end;
      end if;
    else
      fnd_file.put(fnd_file.log ,'Se genero el archivo de salida ' || 'en la salida del concurrente' );
      fnd_file.new_line(fnd_file.log ,1);
      debug(g_indent || v_calling_sequence || '. Se genero el archivo de salida ' || 'en la salida del concurrente' ,'1' );
    end if;
    debug(g_indent || v_calling_sequence || '. Salida de interface generada' ,'1' );
    return (true);
  exception
  when others then
    p_mesg_error := v_calling_sequence || '. Error general ' || 'imprimiendo salida de la interface. ' || sqlerrm;
    return (false);
  end print_text;
/*=========================================================================+
|                                                                          |
| Public Function                                                          |
|    Get_Inventory_Item_Desc                                               |
|                                                                          |
| Description                                                              |
|    Funcion privada que imprime salida de la interface.                   |
|                                                                          |
| Parameters                                                               |
|    p_organization_id   IN  NUMBER  Id Orgnization de Inventario.         |
|    p_inventory_item_id IN NUMBER   Id de Articulo de Inventario.         |
|                                                                          |
+=========================================================================*/
  function get_inventory_item_desc(
      p_organization_id in number ,
      p_inventory_item_id in number ,
      p_cust_trx_concept in varchar2 ,
      p_rfc in varchar2 )
    return varchar2
  is
    v_item_desc varchar2(2000);
  begin
    begin
      select mc.description
      into v_item_desc
      from mtl_item_categories mic
      ,mtl_category_sets mcs
      ,mtl_categories mc
      where mic.inventory_item_id = p_inventory_item_id
      and mic.organization_id     = p_organization_id
      and mcs.category_set_name   = 'XX_DESCR_ARTICULO'
      and mcs.category_set_id     = mic.category_set_id
      and mc.category_id          = mic.category_id;
    exception
    when no_data_found then
      if (v_item_desc is null) then
        v_item_desc   := p_cust_trx_concept;
      end if;
    end;
    /*-- Si no se obtuvo descripcion, no se concatena RFC*/
    if (v_item_desc is not null) then
      if (p_rfc     is not null) then
        v_item_desc := v_item_desc ||'-'||p_rfc;
      end if;
    end if;
    return v_item_desc;
  exception
  when others then
    return null;
  end get_inventory_item_desc;
/*=========================================================================+
|                                                                          |
| Public Function                                                          |
|    Get_Receipt_Method                                                    |
|                                                                          |
| Description                                                              |
|    Funcion que obtiene el Metodo de Pago.                                |
|                                                                          |
| Parameters                                                               |
|    p_receipt_method_id        IN NUMBER   Id Metodo de Pago.             |
|    p_cust_trx_type            IN VARCHAR2 Id Tipo de Transaccion.        |
|    p_previous_customer_trx_id IN NUMBER   Id Transaccion anterior.       |
|    p_transaction_type         IN VARCHAR2 Tipo de Transaccion: PP, PD.   |
|                                                                          |
+=========================================================================*/
  function get_receipt_method(
      p_receipt_method_id in number ,
      p_cust_trx_type in varchar2 ,
      p_previous_customer_trx_id in number ,
      p_transaction_type in varchar2 )
    return varchar2
  is
    l_receipt_method_id   number;
    l_receipt_method_name varchar2(30);
    l_transaction_type    varchar2(30);
  begin
    l_transaction_type      := p_transaction_type;
    if (p_receipt_method_id is not null) then
      l_receipt_method_id   := p_receipt_method_id;
    elsif (p_cust_trx_type   = 'CM' and p_previous_customer_trx_id is not null) then
      select rct.receipt_method_id
      ,rctt.attribute2
      into l_receipt_method_id
      ,l_transaction_type
      from ra_customer_trx rct
      ,ra_cust_trx_types rctt
      where rct.customer_trx_id = p_previous_customer_trx_id
      and rct.cust_trx_type_id  = rctt.cust_trx_type_id;
    end if;
    /*-- Busco la descripcion del metodo de cobro*/
    if (l_receipt_method_id is not null) then
      select arm.printed_name
      into l_receipt_method_name
      from ar_receipt_methods arm
      where arm.receipt_method_id = l_receipt_method_id;
    else /*-- Busco los Defaults*/
      select arm.printed_name
      into l_receipt_method_name
      from ar_receipt_methods arm
      where arm.name = decode (l_transaction_type ,'PD' ,'01' ,'04');
    end if;
    return l_receipt_method_name;
  exception
  when others then
    return null;
  end get_receipt_method;
/*=========================================================================+
|                                                                          |
| Public Function                                                          |
|    Item_Imprime_Prestador                                                |
|                                                                          |
| Description                                                              |
|    Funcion que indica si el articulo debe imprimir prestador             |
|                                                                          |
| Parameters                                                               |
|    p_organization_id   IN  NUMBER  Id Orgnization de Inventario.         |
|    p_inventory_item_id IN NUMBER   Id de Articulo de Inventario.         |
|                                                                          |
+=========================================================================*/
  function item_imprime_prestador(
      p_organization_id in number ,
      p_inventory_item_id in number )
    return varchar2
  is
    v_item_imprime_prestador varchar2(1) := 'N';
  begin
    select 'Y'
    into v_item_imprime_prestador
    from mtl_category_sets mcs
    ,mtl_item_categories mic
    ,mtl_categories mc
    where mcs.category_set_name = 'XX_ITEM_DESPEGAR'
    and mcs.category_set_id     = mic.category_set_id
    and mc.category_id          = mic.category_id
    and mc.segment1            in ('Hotel')
    and mic.organization_id     = p_organization_id
    and mic.inventory_item_id   = p_inventory_item_id;
    return v_item_imprime_prestador;
  exception
  when others then
    return 'N';
  end item_imprime_prestador;
/*=========================================================================+
|                                                                          |
| Private Function                                                         |
|    Get_supplier_name                                                     |
|                                                                          |
| Description                                                              |
|    Funcion privada que busca nombre de proveedor                         |
|                                                                          |
| Parameters                                                               |
|    p_taxpayer_id        IN  VARCHAR2                                     |
|    p_taxpayer_doc_type  IN  VARCHAR2                                     |
|    p_org_id             IN  NUMBER                                       |
|                                                                          |
+=========================================================================*/
  function get_supplier_name(
      p_taxpayer_id in varchar2 ,
      p_taxpayer_doc_type in varchar2 ,
      p_org_id in number)
    return varchar2
  is
    v_supp_name ap_suppliers.vendor_name%type;
    v_count number := 0;
  begin
    if (p_taxpayer_id is null) then
      return null;
    end if;
    begin
      select vendor_name
      into v_supp_name
      from ap_suppliers ap
      ,ap_supplier_sites_all aps
      ,hz_parties hzp
      where ap.num_1099 like substr(p_taxpayer_id ,1 ,length(p_taxpayer_id) - 1)
        ||'%'
      and (p_taxpayer_id = trim(ap.num_1099
        || nvl(ap.global_attribute12 ,' '))
      or p_taxpayer_id          = ap.num_1099)
      and ap.vendor_id          = aps.vendor_id
      and ap.party_id           = hzp.party_id
      and (p_taxpayer_doc_type is null
      or (p_taxpayer_doc_type   = hzp.attribute3))
      and aps.org_id            = p_org_id
      and rownum                = 1;
      return(v_supp_name);
    exception
    when others then
      return null;
    end;
  exception
  when others then
    return null;
  end get_supplier_name;
/*=========================================================================+
|                                                                          |
| Public Function                                                          |
|    Get_Desc_Tercero                                                      |
|                                                                          |
| Description                                                              |
|    Funcion que devuelve la descripcion del Tercero                       |
|                                                                          |
| Parameters                                                               |
|    p_organization_id    IN NUMBER   Id Orgnization de Inventario.        |
|    p_inventory_item_id  IN NUMBER   Id de Articulo de Inventario.        |
|    p_taxpayer_id        IN VARCHAR2 Taxpayer_Id del Proveedor            |
|    p_taxpayer_doc_type  IN VARCHAR2 Tipo de Documento del Proveedor      |
|    p_org_id             IN NUMBER   Org_Id                               |
|    p_prestador          IN VARCHAR2 Nombre del Prestador                 |
|                                                                          |
+=========================================================================*/
  function get_desc_tercero(
      p_organization_id in number ,
      p_inventory_item_id in number ,
      p_taxpayer_id in varchar2 ,
      p_taxpayer_doc_type in varchar2 ,
      p_org_id in number ,
      p_prestador in varchar2)
    return varchar2
  is
  begin
    /*-- Si imprime el prestador, devuelvo esa descripcion*/
    if (item_imprime_prestador (p_organization_id ,p_inventory_item_id) = 'Y') then
      return p_prestador;
    end if;
    /*-- Devuelvo la razon social del proveedor*/
    return get_supplier_name(p_taxpayer_id ,p_taxpayer_doc_type ,p_org_id);
  exception
  when others then
    return null;
  end get_desc_tercero;
/*=========================================================================+
|                                                                          |
| Public Procedure                                                         |
|    Get_Datos_Trx                                                         |
|                                                                          |
| Description                                                              |
|    Funcion que devuelve los datos de un comprobante                      |
|                                                                          |
| Parameters                                                               |
|    p_customer_trx_id    IN NUMBER   Id del comprobante                   |
|                                                                          |
+=========================================================================*/
  procedure get_datos_trx(
      p_customer_trx_id in number ,
      x_trx_number out varchar2 ,
      x_trx_date out date ,
      x_electr_doc_type out varchar2 ,
      x_procesado_fc_electronica out varchar2)
  is
  begin
    select rct.trx_number
    ,rct.trx_date
    ,rctt.attribute11
    ,nvl (rct.attribute9 ,'N')
    into x_trx_number
    ,x_trx_date
    ,x_electr_doc_type
    ,x_procesado_fc_electronica
    from ra_customer_trx rct
    ,ra_cust_trx_types rctt
    where rct.customer_trx_id = p_customer_trx_id
    and rct.cust_trx_type_id  = rctt.cust_trx_type_id;
    return;
  exception
  when others then
    x_trx_number               := null;
    x_electr_doc_type          := null;
    x_procesado_fc_electronica := null;
    return;
  end get_datos_trx;
/*=========================================================================+
|                                                                          |
| Public Procedure                                                         |
|    generate_files                                                        |
|                                                                          |
| Description                                                              |
|    Procedimiento que genera los archivos de factura electronica.         |
|                                                                          |
| Parameters                                                               |
|    errbuf            OUT VARCHAR2 Uso interno del concurrente.           |
|    retcode           OUT VARCHAR2 Uso interno del concurrente.           |
|    p_draft_mode      IN  VARCHAR2 Modo draft (Y/N).                      |
|    p_debug_flag      IN  VARCHAR2 Flag de debug.                         |
|    p_cust_trx_type   IN  NUMBER   Tipo de Transaccion.                   |
|    p_batch_source    IN  VARCHAR2 Origen.                                |
|    p_trx_number_from IN  VARCHAR2 Numero de Transaccion desde.           |
|    p_trx_number_to   IN  VARCHAR2 Numero de Transaccion hasta.           |
|    p_date_from       IN  DATE     Fecha desde.                           |
|    p_date_to         IN  DATE     Fecha hasta.                           |
|    p_customer_id     IN  NUMBER   Cliente.                               |
|    p_territory_code  IN  VARCHAR2 Pais.                                  |
|                                                                          |
+=========================================================================*/
  procedure generate_files(
      errbuf out varchar2 ,
      retcode out number ,
      p_draft_mode in varchar2 ,
      p_debug_flag in varchar2 ,
      p_batch_source in varchar2 ,
      p_cust_trx_type in number ,
      p_trx_number_from in varchar2 ,
      p_trx_number_to in varchar2 ,
      p_date_from in varchar2 ,
      p_date_to in varchar2 ,
      p_customer_id in number ,
      p_territory_code in varchar2 )
  is
    /*-- ---------------------------------------------------------------------------*/
    /*-- Definicion de Variables*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence varchar2(2000);
    v_request_id       number(15);
    v_mesg_error       varchar2(32767);
    v_mesg_api_error   varchar2(32767);
    v_return_status    varchar2(1);
    v_msg_count        number;
    v_msg_data         varchar2(2000);
    v_msg_index_out    number;
    v_order_source oe_order_sources.name%type;
    v_orig_sys_document_ref oe_order_headers.orig_sys_document_ref%type;
    v_stmt_source xx_ap_hotel_statements_hdr.stmt_source%type;
    v_hotel_stmt_trx_number xx_ap_hotel_statements_hdr.hotel_stmt_trx_number%type;
    v_month_billed xx_ap_hotel_statements_hdr.period_name%type;
    v_amount_in_words varchar2(4000);
    v_send_file clob;
    v_send_line   varchar2(4000);
    v_nro_lin_det number;
    v_success_qty number  := 0;
    v_error_qty   number  := 0;
    v_is_prod_env boolean := false;
    v_is_test_env boolean := false;
  begin
    /*-- ---------------------------------------------------------------------------*/
    /*-- Inicializo variables Grales de Ejecucion.*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence := 'xx_ar_raxinv_pk.generate_files';
    v_request_id       := fnd_global.conc_request_id;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Inicializo el debug.*/
    /*-- ---------------------------------------------------------------------------*/
    g_debug_flag     := upper(nvl(p_debug_flag ,'N'));
    g_debug_mode     := 'CONC_LOG';
    g_message_length := 4000;
    debug(g_indent || v_calling_sequence ,'1' );
    /*-- ---------------------------------------------------------------------------*/
    /*-- Despliego Parametros.*/
    /*-- ---------------------------------------------------------------------------*/
    debug(g_indent || v_calling_sequence || '. Modo draft: ' || p_draft_mode ,'1' );
    debug(g_indent || v_calling_sequence || '. Origen: ' || p_batch_source ,'1' );
    debug(g_indent || v_calling_sequence || '. Tipo de Transaccion: ' || p_cust_trx_type ,'1' );
    debug(g_indent || v_calling_sequence || '. Numero Transaccion desde: ' || p_trx_number_from ,'1' );
    debug(g_indent || v_calling_sequence || '. Numero Transaccion hasta: ' || p_trx_number_from ,'1' );
    debug(g_indent || v_calling_sequence || '. Fecha desde: ' || p_date_from ,'1' );
    debug(g_indent || v_calling_sequence || '. Fecha hasta: ' || p_date_to ,'1' );
    debug(g_indent || v_calling_sequence || '. Cliente: ' || p_customer_id ,'1' );
    debug(g_indent || v_calling_sequence || '. Pais: ' || p_territory_code ,'1' );
    debug(g_indent || v_calling_sequence || '. Flag de debug: ' || p_debug_flag ,'1' );
    debug(g_indent || v_calling_sequence || '. Obtiene facturas a procesar' ,'1' );
    /*-- Verifica si se ejecuta en entorno de produccion*/
    if (fnd_profile.value('TWO_TASK') = 'EBSP') then
      v_is_prod_env                  := true;
    else
      v_is_test_env := true;
    end if;
    /*-- Para modo draft se debe informar Transaccion Desde y Hasta*/
    if (nvl(p_draft_mode ,'N') = 'Y' and (p_trx_number_from is null or p_trx_number_to is null)) then
      v_mesg_error            := 'Para Modo Draft informar Transaccions Desde y Hasta';
      debug(v_calling_sequence || '. ' || v_mesg_error ,'1' );
      fnd_file.put(fnd_file.log ,g_indent || v_calling_sequence || '. ' || v_mesg_error );
      fnd_file.new_line(fnd_file.log ,1);
      retcode := '1';
      errbuf  := substr(v_mesg_error ,1 ,2000);
      return;
    end if;
    open c_trxs(p_customer_id => p_customer_id , p_cust_trx_type_id => p_cust_trx_type , p_trx_number_from => p_trx_number_from , p_trx_number_to => p_trx_number_to , p_date_from => fnd_date.canonical_to_date(p_date_from) , p_date_to => fnd_date.canonical_to_date(p_date_to) , p_draft_mode => nvl(p_draft_mode ,'N'));
    loop
      fetch c_trxs bulk collect into v_trxs_aux_tbl limit 5000;
      exit
    when v_trxs_aux_tbl.count = 0;
      /*-- Completa estructura v_trxs_tbl*/
      for i in 1..v_trxs_aux_tbl.count
      loop
        v_trxs_aux_tbl(i).status         := 'NEW';
        v_trxs_aux_tbl(i).error_code     := null;
        v_trxs_aux_tbl(i).error_messages := null;
        v_trxs_tbl(v_trxs_tbl.count+1)   := v_trxs_aux_tbl(i);
      end loop;
    end loop;
    close c_trxs;
    debug(g_indent || v_calling_sequence || '. Obtuvo ' || v_trxs_tbl.count || ' facturas a procesar' ,'1' );
    if (v_trxs_tbl.count = 0) then
      v_mesg_error      := 'NO_DATA_FOUND';
    end if;
    /*-- Completa detalles a imprimir*/
    if (v_mesg_error is null) then
      for i in 1..v_trxs_tbl.count
      loop
        dbms_lob.createtemporary(v_send_file ,false);
        debug(g_indent || v_calling_sequence || '. Customer_Trx_ID: '|| v_trxs_tbl(i).customer_trx_id || ' Generic Customer ? ' || v_trxs_tbl(i).generic_customer ,'1' );
        /*-- Verifico que los Extra-Attributes se encuentran creados para la factura*/
        if (not xx_ar_reg_send_invoices_pk.extra_attributes_exists(p_customer_trx_id => v_trxs_tbl(i).customer_trx_id)) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages := 'No existen los registros de extra-attributes para las lineas de pedidos de ventas';
          debug(g_indent || v_calling_sequence || ' No existen los registros de extra-attributes de las lineas de pedidos de ventas para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        end if;
        /*-- Verifico que la moneda de impresion informada sea correcta*/
        if (not xx_ar_reg_send_invoices_pk.printing_currency_is_valid (p_printing_currency_code =>v_trxs_tbl(i).printing_currency_code ,p_functional_currency_code =>g_func_currency_code ,p_document_currency_code =>v_trxs_tbl(i).invoice_currency_code)) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '020_INVALID_CONFIGURATION';
          v_trxs_tbl(i).error_messages := 'La moneda de impresion de factura('||v_trxs_tbl(i).printing_currency_code||')'|| ' solo puede ser igual a la moneda de la transaccion('||v_trxs_tbl(i).invoice_currency_code||')'|| ' o la moneda funcional del pais ('||g_func_currency_code||')';
          debug(g_indent || v_calling_sequence || ' La moneda de impresion de factura es diferente a la moneda de la transaccion y a la moneda funcional para customer_trx_id:'||' ' ||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        end if;
        /*-- Verifica si es un cliente generico o no para obtener los datos*/
        if (v_trxs_tbl(i).generic_customer = 'N') then
          begin
            select replace(hp.party_name ,'('
              ||v_trxs_tbl(i).org_country
              ||')' ,'')
            ,hp.attribute3
            ,hp.jgzz_fiscal_code
              || hca.global_attribute12
            ,hp.jgzz_fiscal_code
            ,hca.global_attribute12
            ,ac.email_address
            ,substr(hl_cusb.address1
              ||decode(hl_cusb.address2 ,null ,null ,','
              ||hl_cusb.address2)
              || decode(hl_cusb.address3 ,null ,null ,','
              ||hl_cusb.address3)
              || decode(hl_cusb.address4 ,null ,null ,','
              ||hl_cusb.address4) ,1 ,150) customer_base_address
            ,hcasb.attribute1
            ,hl_cusb.province
            ,hl_cusb.city
            ,hl_cusb.country
            into v_trxs_tbl(i).customer_name
            ,v_trxs_tbl(i).customer_doc_type
            ,v_trxs_tbl(i).customer_doc_number_full
            ,v_trxs_tbl(i).customer_doc_number
            ,v_trxs_tbl(i).customer_doc_digit
            ,v_trxs_tbl(i).customer_email
            ,v_trxs_tbl(i).customer_base_address
            ,v_trxs_tbl(i).giro_receptor_code
            ,v_trxs_tbl(i).province_receptor_name
            ,v_trxs_tbl(i).city_receptor_name
            ,v_trxs_tbl(i).pais_receptor_code
            from hz_party_sites hpsb
            ,hz_cust_acct_sites hcasb
            ,hz_cust_site_uses hcsub
            ,hz_locations hl_cusb
            ,hz_parties hp
            ,ar_contacts_v ac
            ,hz_cust_accounts hca
            where v_trxs_tbl(i).party_id          = hp.party_id
            and v_trxs_tbl(i).cust_account_id     = hca.cust_account_id
            and hca.cust_account_id               = ac.customer_id(+)
            and v_trxs_tbl(i).bill_to_site_use_id = hcsub.site_use_id
            and hcsub.cust_acct_site_id           = hcasb.cust_acct_site_id
            and hcasb.party_site_id               = hpsb.party_site_id
            and hpsb.location_id                  = hl_cusb.location_id
            and rownum                           <= 1;
          exception
          when others then
            v_trxs_tbl(i).status         := 'ERROR';
            v_trxs_tbl(i).error_code     := '030_UNEXPECTED_ERROR';
            v_trxs_tbl(i).error_messages := 'Error inesperado obteniendo datos de cliente :'||sqlerrm;
            v_trxs_tbl(i).customer_name  := 'ERROR OBTENIENDO DATOS CLIENTE';
            debug(g_indent || v_calling_sequence || ' Error inesperado obteniendo datos de cliente particular '||v_trxs_tbl(i).cust_account_id||' '||sqlerrm ,'1' );
            continue;
          end;
        end if;
        /*-- Obtengo la descripcion para el giro comercial del cliente*/
        if (v_trxs_tbl(i).pais_receptor_name is null) then
          begin
            select flv.description
            into v_trxs_tbl(i).giro_receptor_meaning
            from fnd_lookup_values_vl flv
            where flv.lookup_type = 'XX_GIROS_COMERCIALES'
            and flv.lookup_code   = v_trxs_tbl(i).giro_receptor_code;
          exception
          when others then
            null;
          end;
        end if;
        /*-- Obtengo la descripcion para las geografias*/
        /*-- Pais*/
        if (v_trxs_tbl(i).pais_receptor_name is null) then
          begin
            select hg.geography_name
            into v_trxs_tbl(i).pais_receptor_name
            from hz_geographies hg
            where country_code = v_trxs_tbl(i).pais_receptor_code
            and geography_type = 'COUNTRY'
            and rownum         = 1;
          exception
          when others then
            null;
          end;
        end if;
        /*-- Province*/
        if (v_trxs_tbl(i).province_receptor_name is null) then
          begin
            select hg.geography_name
            into v_trxs_tbl(i).province_receptor_name
            from hz_geographies hg
            where country_code    = v_trxs_tbl(i).pais_receptor_code
            and hg.geography_code = v_trxs_tbl(i).province_receptor_code
            and hg.geography_type = 'PROVINCE'
            and hg.geography_use  = 'MASTER_REF'
            and rownum            = 1;
          exception
          when others then
            null;
          end;
        end if;
        /*-- City (Comuna)*/
        if (v_trxs_tbl(i).city_receptor_name is null) then
          begin
            select hg.geography_name
            into v_trxs_tbl(i).city_receptor_name
            from hz_geographies hg
            where country_code             = v_trxs_tbl(i).pais_receptor_code
            and hg.geography_element2_code = v_trxs_tbl(i).province_receptor_code
            and hg.geography_code          = v_trxs_tbl(i).city_receptor_code
            and hg.geography_type          = 'CITY'
            and hg.geography_use           = 'MASTER_REF'
            and rownum                     = 1;
          exception
          when others then
            null;
          end;
        end if;
        /*-- Armo la direccion final del cliente*/
        begin
          select substr(v_trxs_tbl(i).customer_base_address
            || decode(v_trxs_tbl(i).province_receptor_name ,null ,null ,','
            ||v_trxs_tbl(i).province_receptor_name)
            || decode(v_trxs_tbl(i).city_receptor_name ,null ,null ,','
            ||v_trxs_tbl(i).city_receptor_name)
            || decode(v_trxs_tbl(i).pais_receptor_name ,null ,null ,','
            ||v_trxs_tbl(i).pais_receptor_name) ,1 ,150) customer_address
          into v_trxs_tbl(i).customer_address
          from dual;
        exception
        when others then
          null;
        end;
        /*-- Llamo a la funcion que calcula los totales del Comprobante*/
        begin
          v_mesg_api_error := null;
          xx_ar_reg_send_invoices_pk.get_invoice_values_vat_details (p_customer_trx_id => v_trxs_tbl(i).customer_trx_id ,p_country => 'CL' ,p_vat_tax => g_vat_tax ,x_net_amount => v_trxs_tbl(i).net_amount ,x_net_amount_pcc => v_trxs_tbl(i).net_amount_pcc ,x_tax_amount => v_trxs_tbl(i).tax_amount ,x_tax_amount_pcc => v_trxs_tbl(i).tax_amount_pcc ,x_total_amount => v_trxs_tbl(i).total_amount ,x_total_amount_pcc => v_trxs_tbl(i).total_amount_pcc ,x_net_amount_exento => v_trxs_tbl(i).net_amount_exento ,x_net_amount_exento_pcc => v_trxs_tbl(i).net_amount_exento_pcc ,x_net_amount_gravado => v_trxs_tbl(i).net_amount_gravado ,x_net_amount_gravado_pcc => v_trxs_tbl(i).net_amount_gravado_pcc ,x_tax_amount_iva => v_trxs_tbl(i).tax_amount_iva ,x_tax_amount_iva_pcc => v_trxs_tbl(i).tax_amount_iva_pcc ,x_collection_country => v_trxs_tbl(i).collection_country ,x_invoice_currency_code => v_trxs_tbl(i).invoice_currency_code ,x_printing_currency_code => v_trxs_tbl(i).printing_currency_code ,
          x_return_status => v_return_status ,x_msg_count => v_msg_count ,x_msg_data => v_msg_data);
          if (v_return_status != fnd_api.g_ret_sts_success) then
            for cnt in 1..v_msg_count
            loop
              fnd_msg_pub.get(p_msg_index => cnt ,p_encoded => fnd_api.g_false ,p_data => v_msg_data ,p_msg_index_out => v_msg_index_out);
              v_mesg_api_error := v_mesg_api_error || v_msg_data;
            end loop;
            v_mesg_api_error := 'Get_Invoice_Values_Tax_Details: '||v_mesg_api_error;
          end if;
        exception
        when others then
          v_mesg_api_error := 'Get_Invoice_Values_Tax_Details: '||sqlerrm;
        end;
        /*-- Valido que se hayan podido obtener los importes en la API*/
        if (v_mesg_api_error           is not null) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '030_UNEXPECTED_ERROR';
          v_trxs_tbl(i).error_messages := 'Error inesperado obteniendo Valores del Comprobante '|| v_mesg_api_error;
          debug(g_indent || v_calling_sequence || ' Error inesperado obteniendo valores para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        end if;
        /*-- Obtengo la Tasa de Iva de la Factura, No puede haber mas de un porcentaje.*/
        begin
          select zx_rate.percentage_rate
          into v_trxs_tbl(i).vat_percentage
          from ra_customer_trx_lines_all rctlt
          ,zx_lines zx_line
          ,zx_rates_vl zx_rate
          where rctlt.line_type(+)                 = 'TAX'
          and zx_rate.tax_rate_id(+)               = zx_line.tax_rate_id
          and zx_line.tax_line_id(+)               = rctlt.tax_line_id
          and zx_line.entity_code                  = 'TRANSACTIONS'
          and zx_rate.tax                          = g_vat_tax
          and zx_line.application_id               = 222
          and ((v_trxs_tbl(i).electr_doc_type not in ('110' ,'112')
          and nvl (zx_rate.percentage_rate ,0)    != 0)
          or /*-- Fac Nacional, solo me interesan las lineas != 0*/
            (v_trxs_tbl(i).electr_doc_type in ('110' ,'112'))) /*-- Fac Exportacion*/
          and rctlt.customer_trx_id         = v_trxs_tbl(i).customer_trx_id
          group by zx_rate.percentage_rate;
          /*-- Para la Factura de Exportacion la tasa siempre debe ser 0*/
          if (v_trxs_tbl(i).electr_doc_type in ('110' ,'112') and v_trxs_tbl(i).vat_percentage != 0) then
            v_trxs_tbl(i).status                                                               := 'ERROR';
            v_trxs_tbl(i).error_code                                                           := '030_UNEXPECTED_ERROR';
            v_trxs_tbl(i).error_messages                                                       := 'La Tasa de Iva para el comprobante de exportacion debe ser siempre 0.';
            debug(g_indent || v_calling_sequence || '  La Tasa de Iva para el comprobante de exportacion debe ser siempre 0 para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
            continue;
          end if;
        exception
        when others then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '030_UNEXPECTED_ERROR';
          v_trxs_tbl(i).error_messages := 'No se pudo obtener la Tasa de Iva para el comprobante. Debe existir una tasa unica de iva.'||sqlerrm;
          debug(g_indent || v_calling_sequence || '  No se pudo obtener una Tasa de Iva unica para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id||' '||sqlerrm ,'1' );
          continue;
        end;
        /*-- Llamo a la funcion que calcula el monto en letras*/
        v_amount_in_words := xx_ar_reg_send_invoices_pk.get_amount_in_words (p_amount => v_trxs_tbl(i).total_amount_pcc ,p_country_currency_code => g_func_currency_code ,p_amount_currency_code => v_trxs_tbl(i).printing_currency_code ,p_country_code => 'CL');
        /*-- Si es una NC, llamo a la funcion que obtiene la referencia a la FC original*/
        if (v_trxs_tbl(i).document_type      = 'CM') then
          v_trxs_tbl(i).ref_customer_trx_id := xx_ar_utilities_pk.get_related_invoice_id (p_customer_trx_id => v_trxs_tbl(i).customer_trx_id);
          /*-- Obtengo los datos del comprobante relacionado*/
          get_datos_trx (p_customer_trx_id => v_trxs_tbl(i).ref_customer_trx_id ,x_trx_number => v_trxs_tbl(i).ref_trx_number ,x_trx_date => v_trxs_tbl(i).ref_trx_date ,x_electr_doc_type => v_trxs_tbl(i).ref_electr_doc_type ,x_procesado_fc_electronica => v_trxs_tbl(i).ref_procesado_fc_electronica);
        end if;
        /*-- Valida datos obligatorios*/
        if (v_trxs_tbl(i).customer_name is null) then
          v_trxs_tbl(i).status          := 'ERROR';
          v_trxs_tbl(i).error_code      := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages  := 'No se informo nombre del cliente';
          v_trxs_tbl(i).customer_name   := 'NO INFORMADO';
          debug(g_indent || v_calling_sequence || ' No se informo nombre del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).customer_doc_number is null) then
          v_trxs_tbl(i).status                   := 'ERROR';
          v_trxs_tbl(i).error_code               := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages           := 'No se informo Nro Documento del cliente';
          v_trxs_tbl(i).customer_doc_number      := '0';
          debug(g_indent || v_calling_sequence || ' No se informo Nro Documento del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).pais_receptor_name is null) then
          v_trxs_tbl(i).status                  := 'ERROR';
          v_trxs_tbl(i).error_code              := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages          := 'No se informo Pais del cliente';
          v_trxs_tbl(i).pais_receptor_name      := 'X';
          debug(g_indent || v_calling_sequence || ' No se informo Pais del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).contributor_source is null) then
          v_trxs_tbl(i).status                  := 'ERROR';
          v_trxs_tbl(i).error_code              := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages          := 'El cliente no tiene informado el contributor source en el maestro';
          debug(g_indent || v_calling_sequence || ' No se informo contributor_source del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).customer_doc_type not in ('RUT' ,'RUN' ,'PASS')) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '020_INVALID_CONFIGURATION';
          v_trxs_tbl(i).error_messages := 'Tipo de Documento de Cliente Invalido o Nulo: '||v_trxs_tbl(i).customer_doc_type;
          debug(g_indent || v_calling_sequence || ' Se informo un tipo de documento de Cliente nulo o invalido para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).giro_emisor_meaning is null or v_trxs_tbl(i).acteco_code is null) then
          v_trxs_tbl(i).status                   := 'ERROR';
          v_trxs_tbl(i).error_code               := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages           := 'La entidad legal no tiene informado el giro comercial y/o la actividad economica';
          debug(g_indent || v_calling_sequence || ' No se informo el giro/comercial y/o la actividad economica de la Entidad Legal para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).expedition_address is null or v_trxs_tbl(i).expedition_place is null) then
          v_trxs_tbl(i).status                  := 'ERROR';
          v_trxs_tbl(i).error_code              := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages          := 'La entidad legal no tiene informado el domicilio y/o la ciudad';
          debug(g_indent || v_calling_sequence || ' No se informo el domicilio y/o la ciudad de la Entidad Legal para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).contributor_source = 'DOMESTIC_ORIGIN' and v_trxs_tbl(i).giro_receptor_meaning is null) then
          v_trxs_tbl(i).status                 := 'ERROR';
          v_trxs_tbl(i).error_code             := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages         := 'No se pudo obtener el giro comercial del cliente';
          debug(g_indent || v_calling_sequence || ' No se informo el giro comercial del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).contributor_source = 'DOMESTIC_ORIGIN' and (v_trxs_tbl(i).province_receptor_name is null or v_trxs_tbl(i).city_receptor_name is null)) then
          v_trxs_tbl(i).status                 := 'ERROR';
          v_trxs_tbl(i).error_code             := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages         := 'No se pudo obtener la provincia y/o comuna del cliente';
          debug(g_indent || v_calling_sequence || ' No se informo la provincia y/o comuna del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_amount_in_words       is null) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages := 'No se pudo calcular el monto en letras';
          debug(g_indent || v_calling_sequence || ' No se pudo calcular el monto en letras para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
          /*-- Valido que el tipo de documento sea uno de los esperados*/
        elsif (v_trxs_tbl(i).electr_doc_type not in ('39' ,'33' ,'61' ,'110' ,'112')) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '020_INVALID_CONFIGURATION';
          v_trxs_tbl(i).error_messages := 'Tipo de Doc de Fc Electronica Invalido: '||v_trxs_tbl(i).electr_doc_type;
          debug(g_indent || v_calling_sequence || ' Tipo de Doc invalido para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
          /*-- Valido la informacion del comprobante referenciado para las NC*/
        elsif (v_trxs_tbl(i).document_type = 'CM') then
          /*-- Valido que exista la Referencia*/
          if (v_trxs_tbl(i).ref_trx_number is null) then
            v_trxs_tbl(i).status           := 'ERROR';
            v_trxs_tbl(i).error_code       := '010_MISSING_VALUE';
            v_trxs_tbl(i).error_messages   := 'No se pudo obtener la referencia a la FC: ';
            debug(g_indent || v_calling_sequence || ' No se pudo obtener la referencia a la factura para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
            continue;
          end if;
          /*-- Valido que se haya obtenido la informacion del tipo de trx de la referencia*/
          if (v_trxs_tbl(i).ref_electr_doc_type is null) then
            v_trxs_tbl(i).status                := 'ERROR';
            v_trxs_tbl(i).error_code            := '010_MISSING_VALUE';
            v_trxs_tbl(i).error_messages        := 'No se pudo obtener el tipo de documento electronico para la FC referenciada('||v_trxs_tbl(i).ref_trx_number||')';
            debug(g_indent || v_calling_sequence || ' No se pudo obtener el tipo de documento electronico para la FC referenciada para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
            continue;
          end if;
          /*-- Valido que la factura referenciada haya vuelto de factura electronica*/
          if (nvl (v_trxs_tbl(i).ref_procesado_fc_electronica ,'N') = 'N') then
            v_trxs_tbl(i).status                                   := 'ERROR';
            v_trxs_tbl(i).error_code                               := '010_MISSING_VALUE';
            v_trxs_tbl(i).error_messages                           := 'La factura referenciada ('|| v_trxs_tbl(i).ref_trx_number||') aun no fue procesada por fc electronica';
            debug(g_indent || v_calling_sequence || 'La factura referenciada aun no fue procesada por fc electronica para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
            continue;
          end if;
          /*-- Valido que los tipos de documentos relacionados esten Ok*/
          if (v_trxs_tbl(i).electr_doc_type not in ('61' ,'112') or /*-- Nc*/
            (v_trxs_tbl(i).electr_doc_type = '61' and v_trxs_tbl(i).ref_electr_doc_type not in ('33' ,'39')) or /*-- Fc Nacional*/
            (v_trxs_tbl(i).electr_doc_type = '112' and v_trxs_tbl(i).ref_electr_doc_type not in ('110'))) then /*-- Fc Exportacion*/
            v_trxs_tbl(i).status          := 'ERROR';
            v_trxs_tbl(i).error_code      := '020_INVALID_CONFIGURATION';
            v_trxs_tbl(i).error_messages  := 'Tipo de Doc Invalido de Fc Electr para combinacion NC('||v_trxs_tbl(i).electr_doc_type||') '|| 'y Ref de Fc('||v_trxs_tbl(i).ref_electr_doc_type||')';
            debug(g_indent || v_calling_sequence || ' Combinacion Invalida de Tipos de Doc de Fc Electr para NC/FC para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
            continue;
          end if;
        end if;
        begin
          v_send_line := '<DTE>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          if (v_trxs_tbl(i).electr_doc_type = '39') then
            v_send_line                    := '<Boleta>'||g_eol;
          elsif (v_trxs_tbl(i).electr_doc_type in ('110' ,'112')) then /*-- Fc Exportacion*/
            v_send_line := '<Exportaciones>'||g_eol;
          else
            v_send_line := '<Documento>'||g_eol;
          end if;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*----------------------- Inicio de Seccion Encabezado -----------------------------*/
          v_send_line := '<Encabezado>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*----------------------- Inicio de Seccion IDoc ----------------------------------*/
          v_send_line := '<IdDoc>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<TipoDTE>'||v_trxs_tbl(i).electr_doc_type||'</TipoDTE>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<Folio>'||v_trxs_tbl(i).trx_number||'</Folio>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<FchEmis>'||to_char(v_trxs_tbl(i).trx_date ,'YYYY-MM-DD')||'</FchEmis>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          if (v_trxs_tbl(i).electr_doc_type in ('39' ,'61')) then
            v_send_line := '<IndServicio>'||v_trxs_tbl(i).electr_serv_type||'</IndServicio>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          v_send_line := '</IdDoc>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion IDoc --------------------------------------*/
          /*-------------------------- Inicio de Seccion Emisor ----------------------------------*/
          v_send_line := '<Emisor>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<RUTEmisor>'||v_trxs_tbl(i).legal_entity_identifier||'</RUTEmisor>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          if (v_trxs_tbl(i).electr_doc_type = '39') then
            v_send_line                    := '<RznSocEmisor>'||v_trxs_tbl(i).legal_entity_name||'</RznSocEmisor>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          else
            v_send_line := '<RznSoc>'||v_trxs_tbl(i).legal_entity_name||'</RznSoc>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          if (v_trxs_tbl(i).electr_doc_type = '39') then
            v_send_line                    := '<GiroEmisor>'||v_trxs_tbl(i).giro_emisor_meaning||'</GiroEmisor>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          else
            v_send_line := '<GiroEmis>'||v_trxs_tbl(i).giro_emisor_meaning||'</GiroEmis>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          if (v_trxs_tbl(i).electr_doc_type != '39') then
            v_send_line                     := '<Acteco>'||v_trxs_tbl(i).acteco_code||'</Acteco>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          v_send_line := '<DirOrigen>'||v_trxs_tbl(i).expedition_address||'</DirOrigen>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<CmnaOrigen>'||v_trxs_tbl(i).expedition_place||'</CmnaOrigen>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</Emisor>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Emisor --------------------------------------*/
          /*-------------------------- Inicio de Seccion Receptor -----------------------------------*/
          v_send_line := '<Receptor>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          if (v_trxs_tbl(i).customer_doc_type in ('RUT' ,'RUN' ,'PASS')) then
            v_send_line := '<RUTRecep>'||v_trxs_tbl(i).customer_doc_number || '-'||v_trxs_tbl(i).customer_doc_digit||'</RUTRecep>'||g_eol;
          else
            v_send_line := '<RUTRecep>'||v_trxs_tbl(i).customer_doc_number_full||'</RUTRecep>'||g_eol;
          end if;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<RznSocRecep>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).customer_name)||'</RznSocRecep>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          if (v_trxs_tbl(i).electr_doc_type in ('33' ,'110')) then
            v_send_line := '<GiroRecep>'||v_trxs_tbl(i).giro_receptor_meaning||'</GiroRecep>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          v_send_line := '<DirRecep>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).customer_address)||'</DirRecep>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-- Comprobante de Exportacion*/
          if (v_trxs_tbl(i).electr_doc_type in ('110' ,'112')) then
            v_send_line := '<CmnaRecep>'||'</CmnaRecep>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<CiudadRecep>'||v_trxs_tbl(i).city_receptor_name||'</CiudadRecep>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          else /*-- Comprobante Nacional*/
            v_send_line := '<CmnaRecep>'||v_trxs_tbl(i).city_receptor_name||'</CmnaRecep>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<CiudadRecep>'||v_trxs_tbl(i).province_receptor_name||'</CiudadRecep>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          v_send_line := '</Receptor>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Receptor --------------------------------------*/
          /*-------------------------- Inicio de Seccion Transporte -----------------------------------*/
          /*-- Solo se imprime para comprobantes de exportacion*/
          if (v_trxs_tbl(i).electr_doc_type in ('110' ,'112')) then
            v_send_line := '<Transporte>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<Aduana>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<CodePaisDestin>'||v_trxs_tbl(i).pais_receptor_code||'</CodePaisDestin>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</Aduana>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</Transporte>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          /*-------------------------- Fin de Seccion Transporte --------------------------------------*/
          /*-------------------------- Inicio de Seccion Totales --------------------------------------*/
          v_send_line := '<Totales>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-- Solo se imprime para comprobantes que no son boleta  (Si es una Nc, su referencia no tiene que ser Boleta)*/
          if (v_trxs_tbl(i).electr_doc_type != '39' and nvl (v_trxs_tbl(i).ref_electr_doc_type ,'X') != '39') then
            /*-- Solo se imprime para comprobantes de exportacion*/
            if (v_trxs_tbl(i).electr_doc_type in ('110' ,'112')) then
              v_send_line := '<TpoMoneda>'||v_trxs_tbl(i).printing_currency_code||'</TpoMoneda>'||g_eol;
              dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
              v_send_line := '<MntExe>'||v_trxs_tbl(i).net_amount_exento_pcc||'</MntExe>'||g_eol;
              dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            else /*-- Solo se imprime para comprobantes Nacionales*/
              v_send_line := '<MntNeto>'||v_trxs_tbl(i).net_amount_gravado_pcc||'</MntNeto>'||g_eol;
              dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
              v_send_line := '<TasaIVA>'||v_trxs_tbl(i).vat_percentage||'</TasaIVA>'||g_eol;
              dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
              v_send_line := '<IVA>'||v_trxs_tbl(i).tax_amount_iva_pcc||'</IVA>'||g_eol;
              dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            end if;
          end if;
          v_send_line := '<MntTotal>'||v_trxs_tbl(i).total_amount_pcc||'</MntTotal>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</Totales>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Totales --------------------------------------------*/
          /*----------------------- Fin de Seccion Encabezado -----------------------------*/
          v_send_line := '</Encabezado>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_nro_lin_det := 0;
          /*-------------------------- Inicio de Seccion Detalles ----------------------------------------*/
          v_send_line := '<Detalle>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          for r_trxs_lines in c_trx_lines (p_customer_trx_id =>v_trxs_tbl(i).customer_trx_id ,p_vat_tax => g_vat_tax ,p_printing_currency_code => v_trxs_tbl(i).printing_currency_code ,p_invoice_currency_code => v_trxs_tbl(i).invoice_currency_code ,p_exchange_rate => v_trxs_tbl(i).exchange_rate ,p_cust_trx_concept =>v_trxs_tbl(i).cust_trx_concept)
          loop
            if (r_trxs_lines.item_description is null) then
              v_trxs_tbl(i).status            := 'ERROR';
              v_trxs_tbl(i).error_code        := '020_INVALID_CONFIGURATION';
              select 'No se pudo obtener descripcion para articulo '
                ||msib.segment1
                ||' y '
                ||v_trxs_tbl(i).cust_trx_type_name
              into v_trxs_tbl(i).error_messages
              from mtl_system_items_b msib
              where msib.inventory_item_id = r_trxs_lines.inventory_item_id
              and msib.organization_id     = r_trxs_lines.organization_id;
              debug(g_indent || v_calling_sequence || v_trxs_tbl(i).error_messages ,'1' );
              continue;
            end if;
            v_nro_lin_det := v_nro_lin_det + 1;
            v_send_line   := '<NroLinDet>'||v_nro_lin_det||'</NroLinDet>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<NmbItem>'||psp_xmlgen.convert_xml_controls(r_trxs_lines.item_description)||'</NmbItem>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<QtyItem>'||r_trxs_lines.quantity||'</QtyItem>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<UnmdItem>'||'UNID'||'</UnmdItem>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<PrcItem>'||r_trxs_lines.net_amount_pcc||'</PrcItem>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<MontoItem>'||r_trxs_lines.net_amount_pcc||'</MontoItem>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end loop;
          v_send_line := '</Detalle>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Detalle --------------------------------------------*/
          /*---------------------- Solo se completa para Notas de Credito ----------------------------------*/
          /*-------------------------- Inicio de Seccion Referencias  --------------------------------------*/
          if (v_trxs_tbl(i).electr_doc_type in ('61' ,'112')) then
            v_send_line := '<Referencias>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<TpoDocRef>'||v_trxs_tbl(i).ref_electr_doc_type||'</TpoDocRef>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<FolioRef>'||v_trxs_tbl(i).ref_trx_number||'</FolioRef>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<FchRef>'||v_trxs_tbl(i).ref_trx_date||'</FchRef>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<CodRef>'||'3'||'</CodRef>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</Referencias>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          /*-------------------------- Fin de Seccion Referencias  ------------------------------------------*/
          /*---- Monto en Letras*/
          /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
          v_send_line := '<DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<NombreDA>'||'Observacion'||'</NombreDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<ValorDA>'||v_amount_in_words||'</ValorDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
          /*---- Informacion de Terceros*/
          for r_trxs_lines_terceros in c_trx_lines_terceros (p_customer_trx_id =>v_trxs_tbl(i).customer_trx_id ,p_printing_currency_code => v_trxs_tbl(i).printing_currency_code ,p_invoice_currency_code => v_trxs_tbl(i).invoice_currency_code ,p_exchange_rate => v_trxs_tbl(i).exchange_rate)
          loop
            /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
            v_send_line := '<DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<NombreDA>'||'gastos_terceros'||'</NombreDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<ValorDA>'||r_trxs_lines_terceros.tercero_amount||'</ValorDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
            /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
            v_send_line := '<DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<NombreDA>'||'nom_terceros'||'</NombreDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<ValorDA>'||r_trxs_lines_terceros.tercero_description||'</ValorDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
          end loop;
          /*---- Informacion Adicional*/
          for r_trx_lines_inf_adic in c_trx_lines_inf_adic (p_customer_trx_id => v_trxs_tbl(i).customer_trx_id ,p_collection_type => v_trxs_tbl(i).collection_type ,p_hotel_stmt_trx_number => v_trxs_tbl(i).hotel_stmt_trx_number)
          loop
            v_send_line := '<DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<NombreDA>'||'Observacion'||'</NombreDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<ValorDA>'||r_trx_lines_inf_adic.info_adic||'</ValorDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end loop;
          /*---- Leyendas para Transacciones Manuales*/
          /*-- Verifica si el origen es manual y es cuenta corriente*/
          /*-- Imprime domicilio*/
          if (v_trxs_tbl(i).batch_source_type = 'INV' and v_trxs_tbl(i).generic_customer = 'N' and v_trxs_tbl(i).print_address_flag = 'Y') then
            v_send_line                      := '<DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<NombreDA>'||'Observacion'||'</NombreDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<ValorDA>'||v_trxs_tbl(i).customer_address||'</ValorDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          /*-- Leyenda Adicional*/
          /*-- Imprime Extracto/Reserva*/
          v_send_line := '<DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<NombreDA>'||'Observacion'||'</NombreDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          if (nvl(v_trxs_tbl(i).collection_type ,'XX') = 'PD') then
            v_send_line                               := '<ValorDA>'||v_trxs_tbl(i).hotel_stmt_trx_number||'</ValorDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          else
            v_send_line := '<ValorDA>'||v_trxs_tbl(i).purchase_order||'</ValorDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          v_send_line := '</DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-- Leyenda Adicional*/
          /*-- Imprime Comentarios*/
          v_send_line := '<DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<NombreDA>'||'Observacion'||'</NombreDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<ValorDA>'||v_trxs_tbl(i).comments||'</ValorDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*---- Agencia*/
          /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
          v_send_line := '<DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<NombreDA>'||'Agencia_SII'||'</NombreDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<ValorDA>'||'SUCURSAL SII'||'</ValorDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
          /*---- Numero de Resolucion*/
          /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
          v_send_line := '<DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<NombreDA>'||'NumRes_SII'||'</NombreDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<ValorDA>'||'118'||'</ValorDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
          /*---- Fecha de Resolucion*/
          /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
          v_send_line := '<DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<NombreDA>'||'FechaRes_SII'||'</NombreDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<ValorDA>'||'30-09-2008'||'</ValorDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
          /*---- Condicion de Pago*/
          /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
          v_send_line := '<DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<NombreDA>'||'FORMAPAGO'||'</NombreDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<ValorDA>'||v_trxs_tbl(i).receipt_method_name||'</ValorDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
          /*-------------------------- Fin de Seccion Boleta/DTE --------------------------------------*/
          if (v_trxs_tbl(i).electr_doc_type = '39') then
            v_send_line                    := '</Boleta>'||g_eol;
          elsif (v_trxs_tbl(i).electr_doc_type in ('110' ,'112')) then /*-- Fc Exportacion*/
            v_send_line := '</Exportaciones>'||g_eol;
          else
            v_send_line := '</Documento>'||g_eol;
          end if;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</DTE>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
        exception
        when others then
          v_mesg_error := 'Error cargando el contenido del archivo en la tabla de Envios de Transacciones ' || '(xx_ar_raxinv_pk). Texto: ' || v_send_line || '. ' || sqlerrm;
        end;
        if (v_mesg_error is null and v_trxs_tbl(i).status != 'ERROR') then
          debug(g_indent || v_calling_sequence || ' Copiando lob' ,'1' );
          dbms_lob.createtemporary(v_trxs_tbl(i).send_file ,false);
          dbms_lob.copy(v_trxs_tbl(i).send_file ,v_send_file ,dbms_lob.getlength(v_send_file));
          dbms_lob.freetemporary(v_send_file);
          debug(g_indent || v_calling_sequence || ' Copiado de lob finalizado' ,'1' );
        end if;
      end loop; /*--  Loop Principal*/
    end if; /*--  Fin Completa detalles a imprimir*/
    /*-- Genera los archivos*/
    if (v_mesg_error is null) then
      debug(g_indent || v_calling_sequence || ' Generando archivos' ,'1' );
      begin
        if not print_text(p_print_output => null ,p_mesg_error => v_mesg_error ) then
          v_mesg_error := 'Error generando archivos: '||v_mesg_error;
        end if;
        if not print_text(p_print_output => 'Y' ,p_mesg_error => v_mesg_error ) then
          v_mesg_error := 'Error generando archivos: '||v_mesg_error;
        end if;
      exception
      when others then
        v_mesg_error := v_calling_sequence || '. Error llamando a la funcion ' || 'PRINT_TEXT. ' || sqlerrm;
      end;
    end if; /*-- Genera los archivos*/
    /*-- Inserta registros en tabla de intercambio*/
    if (v_mesg_error is null) then
      for i in 1..v_trxs_tbl.count
      loop
        if v_trxs_tbl(i).status = 'ERROR' then
          v_error_qty          := v_error_qty + 1;
        else
          v_success_qty := v_success_qty + 1;
        end if;
        begin
          /*-- Se obtiene extracto del comprobante relacionado cuando corresponde*/
          v_hotel_stmt_trx_number := xx_ar_utilities_pk.get_hotel_stmt_trx_number(v_trxs_tbl(i).customer_trx_id);
          /*-- Se obtiene el periodo del extracto*/
          xx_ar_utilities_pk.get_hotel_stmt_info(p_hotel_stmt_trx_number => v_hotel_stmt_trx_number ,x_period_name => v_month_billed);
          select
            case
              when nvl(v_trxs_tbl(i).collection_type ,'XX') = 'PD'
              then null
              else decode(rctl.interface_line_context ,'ORDER ENTRY' ,oos.name ,'XX_MANUAL' )
            end
          ,ooh.orig_sys_document_ref
          ,xahsh.stmt_source
          into v_order_source
          ,v_orig_sys_document_ref
          ,v_stmt_source
          from oe_order_sources oos
          ,oe_order_headers ooh
          ,oe_order_lines ool
          ,ra_customer_trx rct
          ,ra_customer_trx_lines rctl
          ,xx_ap_hotel_statements_hdr xahsh
          where 1                                                                                     = 1
          and v_trxs_tbl(i).customer_trx_id                                                           = rct.customer_trx_id
          and rct.customer_trx_id                                                                     = rctl.customer_trx_id
          and rctl.line_type                                                                          = 'LINE'
          and rctl.interface_line_attribute6                                                          = ool.line_id(+)
          and ool.header_id                                                                           = ooh.header_id(+)
          and xx_ar_utilities_pk.get_hotel_stmt_trx_number(rct.customer_trx_id)                       = xahsh.hotel_stmt_trx_number(+)
          and decode(rctl.interface_line_context ,'ORDER ENTRY' ,rctl.interface_line_attribute1 ,-1 ) = decode(rctl.interface_line_context ,'ORDER ENTRY' ,ooh.order_number ,-1 )
          and ooh.order_source_id                                                                     = oos.order_source_id(+)
          and rownum                                                                                  = 1;
        exception
        when others then
          v_order_source          := null;
          v_orig_sys_document_ref := null;
          v_stmt_source           := null;
        end;
        /*----------------------------*/
        /*-- Calcula datos adicionales*/
        /*----------------------------*/
        begin
          insert
          into xx_ar_reg_invoice_request
            (
              customer_trx_id
            ,trx_number_ori
            ,reference
            ,receive_date
            ,trx_number_new
            ,link
            ,cae
            ,fecha_cae
            ,file_name
            ,status
            ,error_code
            ,error_messages
            ,created_by
            ,creation_date
            ,last_updated_by
            ,last_update_date
            ,last_update_login
            ,purchase_order
            ,request_number
            ,order_source
            ,orig_sys_document_ref
            ,collection_type
            ,document_type
            ,email
            ,source_system_number
            ,legal_entity
            ,legal_entity_code
            ,request_id
            ,stmt_source
            ,hotel_stmt_trx_number
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
            ,net_amount
            ,net_amount_pcc
            ,tax_amount
            ,tax_amount_pcc
            ,total_amount
            ,total_amount_pcc
            ,trx_date
            ,collection_country
            ,month_billed
            ,invoice_currency_code
            ,printing_currency_code
            )
            values
            (
              v_trxs_tbl(i).customer_trx_id /*-- CUSTOMER_TRX_ID*/
            ,v_trxs_tbl(i).trx_number /*-- TRX_NUMBER_ORI*/
            ,v_trxs_tbl(i).customer_name /*-- REFERENCE*/
            ,null /*-- RECEIVE_DATE*/
            ,null /*-- TRX_NUMBER_NEW*/
            ,null /*-- LINK*/
            ,null /*-- CAE*/
            ,null /*-- FECHA_CAE*/
            ,v_trxs_tbl(i).output_file /*-- FILE_NAME*/
            ,decode(v_trxs_tbl(i).status , 'ERROR' ,'PROCESSING_ERROR_ORACLE' ,'NEW') /*-- STATUS*/
            ,v_trxs_tbl(i).error_code /*-- ERROR_CODE*/
            ,v_trxs_tbl(i).error_messages /*-- ERROR_MESSAGES*/
            ,fnd_global.user_id /*-- CREATED_BY*/
            ,sysdate /*-- CREATION_DATE*/
            ,fnd_global.user_id /*-- LAST_UPDATED_BY*/
            ,sysdate /*-- LAST_UPDATE_DATE*/
            ,fnd_global.login_id /*-- LAST_UPDATE_LOGIN*/
            ,v_trxs_tbl(i).purchase_order /*-- PURCHASE_ORDER*/
            ,v_trxs_tbl(i).request_number /*-- REQUEST_NUMBER*/
            ,v_order_source /*-- ORDER_SOURCE*/
            ,v_orig_sys_document_ref /*-- ORIG_SYS_DOCUMENT_REF*/
            ,v_trxs_tbl(i).collection_type /*-- COLLECTION_TYPE*/
            ,v_trxs_tbl(i).document_type /*-- DOCUMENT_TYPE*/
            ,v_trxs_tbl(i).customer_email /*-- EMAIL*/
            ,v_trxs_tbl(i).source_system_number /*-- SOURCE_SYSTEM_NUMBER*/
            ,v_trxs_tbl(i).legal_entity_name /*-- LEGAL_ENTITY*/
            ,v_trxs_tbl(i).legal_entity_id /*-- LEGAL_ENTITY_CODE*/
            ,fnd_global.conc_request_id /*-- REQUEST_ID*/
            ,v_stmt_source /*-- STMT_SOURCE*/
            ,v_hotel_stmt_trx_number /*-- HOTEL_STMT_TRX_NUMBER*/
            ,p_territory_code /*-- ATTRIBUTE_CATEGORY*/
            ,v_trxs_tbl(i).electr_doc_type /*-- ATTRIBUTE1*/
            ,v_trxs_tbl(i).legal_entity_identifier /*-- ATTRIBUTE2*/
            ,null /*-- ATTRIBUTE3*/
            ,null /*-- ATTRIBUTE4*/
            ,null /*-- ATTRIBUTE5*/
            ,null /*-- ATTRIBUTE6*/
            ,null /*-- ATTRIBUTE7*/
            ,null /*-- ATTRIBUTE8*/
            ,null /*-- ATTRIBUTE9*/
            ,null /*-- ATTRIBUTE10*/
            ,v_trxs_tbl(i).net_amount /*-- NET_AMOUNT*/
            ,v_trxs_tbl(i).net_amount_pcc /*-- NET_AMOUNT_PCC*/
            ,v_trxs_tbl(i).tax_amount /*-- TAX_AMOUNT*/
            ,v_trxs_tbl(i).tax_amount_pcc /*-- TAX_AMOUNT_PCC*/
            ,v_trxs_tbl(i).total_amount /*-- TOTAL_AMOUNT*/
            ,v_trxs_tbl(i).total_amount_pcc /*-- TOTAL_AMOUNT_PCC*/
            ,v_trxs_tbl(i).trx_date /*-- TRX_DATE*/
            ,v_trxs_tbl(i).collection_country /*-- COLLECTION_COUNTRY*/
            ,v_month_billed /*-- MONTH_BILLED*/
            ,v_trxs_tbl(i).invoice_currency_code /*-- INVOICE_CURRENCY_CODE*/
            ,v_trxs_tbl(i).printing_currency_code/*-- PRINTING_CURRENCY_CODE*/
            );
        exception
        when dup_val_on_index then
          update xx_ar_reg_invoice_request
          set trx_number_ori                  = v_trxs_tbl(i).trx_number
          ,reference                          = v_trxs_tbl(i).customer_name
          ,receive_date                       = null
          ,trx_number_new                     = null
          ,link                               = null
          ,cae                                = null
          ,fecha_cae                          = null
          ,file_name                          = v_trxs_tbl(i).output_file
          ,status                             = decode(v_trxs_tbl(i).status , 'ERROR' ,'PROCESSING_ERROR_ORACLE' ,'NEW')
          ,error_code                         = v_trxs_tbl(i).error_code
          ,error_messages                     = v_trxs_tbl(i).error_messages
          ,last_updated_by                    = fnd_global.user_id
          ,last_update_date                   = sysdate
          ,last_update_login                  = fnd_global.login_id
          ,purchase_order                     = v_trxs_tbl(i).purchase_order
          ,request_number                     = v_trxs_tbl(i).request_number
          ,order_source                       = v_order_source
          ,orig_sys_document_ref              = v_orig_sys_document_ref
          ,collection_type                    = v_trxs_tbl(i).collection_type
          ,document_type                      = v_trxs_tbl(i).document_type
          ,email                              = v_trxs_tbl(i).customer_email
          ,source_system_number               = v_trxs_tbl(i).source_system_number
          ,legal_entity                       = v_trxs_tbl(i).legal_entity_name
          ,legal_entity_code                  = v_trxs_tbl(i).legal_entity_id
          ,request_id                         = fnd_global.conc_request_id
          ,stmt_source                        = v_stmt_source
          ,hotel_stmt_trx_number              = v_hotel_stmt_trx_number
          ,attribute_category                 = p_territory_code
          ,attribute1                         = v_trxs_tbl(i).electr_doc_type
          ,attribute2                         = v_trxs_tbl(i).legal_entity_identifier
          ,attribute3                         = null
          ,attribute4                         = null
          ,attribute5                         = null
          ,attribute6                         = null
          ,attribute7                         = null
          ,attribute8                         = null
          ,attribute9                         = null
          ,attribute10                        = null
          ,net_amount                         = v_trxs_tbl(i).net_amount
          ,net_amount_pcc                     =v_trxs_tbl(i).net_amount_pcc
          ,tax_amount                         = v_trxs_tbl(i).tax_amount
          ,tax_amount_pcc                     = v_trxs_tbl(i).tax_amount_pcc
          ,total_amount                       = v_trxs_tbl(i).total_amount
          ,total_amount_pcc                   = v_trxs_tbl(i).total_amount_pcc
          ,trx_date                           = v_trxs_tbl(i).trx_date
          ,collection_country                 = v_trxs_tbl(i).collection_country
          ,month_billed                       = v_month_billed
          ,invoice_currency_code              = v_trxs_tbl(i).invoice_currency_code
          ,printing_currency_code             = v_trxs_tbl(i).printing_currency_code
          where v_trxs_tbl(i).customer_trx_id = customer_trx_id;
        end;
      end loop;
    end if;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Verifico si se produjo un error.*/
    /*-- ---------------------------------------------------------------------------*/
    if v_mesg_error is not null and v_mesg_error != 'NO_DATA_FOUND' then
      debug(g_indent || v_calling_sequence || '. ' || v_mesg_error ,'1' );
      fnd_file.put(fnd_file.log ,g_indent || v_calling_sequence || '. ' || v_mesg_error );
      fnd_file.new_line(fnd_file.log ,1);
      debug(g_indent || v_calling_sequence || '. Realizando rollback' ,'1' );
      rollback;
      retcode := '2';
      errbuf  := substr(v_mesg_error ,1 ,2000);
    else
      if upper(nvl(p_draft_mode ,'N')) = 'N' then
        debug(g_indent || v_calling_sequence || '. Realizando commit' ,'1' );
        commit;
      else
        debug(g_indent || v_calling_sequence || '. Realizando rollback' ,'1' );
        rollback;
      end if;
      retcode := '0';
    end if;
    fnd_file.put(fnd_file.log ,'---------------------------------------------------------------------');
    fnd_file.new_line(fnd_file.log ,1);
    fnd_file.put(fnd_file.log ,' Registros procesados exitosamente: '||v_success_qty);
    fnd_file.new_line(fnd_file.log ,1);
    fnd_file.put(fnd_file.log ,' Registros procesados con error   : '||v_error_qty);
    fnd_file.new_line(fnd_file.log ,1);
    fnd_file.put(fnd_file.log ,'---------------------------------------------------------------------');
    fnd_file.new_line(fnd_file.log ,1);
    debug(g_indent || v_calling_sequence || '. Fin de proceso' ,'1' );
  exception
  when others then
    v_mesg_error := 'Error general generando factura electronica. ' || sqlerrm;
    debug(v_calling_sequence || '. ' || v_mesg_error ,'1' );
    fnd_file.put(fnd_file.log ,g_indent || v_calling_sequence || '. ' || v_mesg_error );
    fnd_file.new_line(fnd_file.log ,1);
    retcode := '2';
    errbuf  := substr(v_mesg_error ,1 ,2000);
  end generate_files;
/*=========================================================================+
|                                                                          |
| Public Procedure                                                         |
|    upload_files                                                          |
|                                                                          |
| Description                                                              |
|    Procedimiento que carga el contenido de los archivos a la tabla de    |
|    envios.                                                               |
|                                                                          |
| Parameters                                                               |
|    p_interface_id IN      NUMBER   Id de la interface.                   |
|    p_request_id   IN      NUMBER   Id de concurrente de generacion de    |
|                                    la interface.                         |
|    p_debug_flag   IN      VARCHAR2 Flag de debug.                        |
|                                                                          |
+=========================================================================*/
  procedure upload_files(
      p_interface_id in number ,
      p_request_id in number ,
      p_debug_flag in varchar2 )
  is
    /*-- ---------------------------------------------------------------------------*/
    /*-- Declaracion de Variables.*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence varchar2(2000);
    v_conc_request_id  number(15);
    v_send_file_data clob;
    v_send_file_length number(15);
    v_mesg_error       varchar2(32767);
    e_exit_fail        exception;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Declaracion de Cursores.*/
    /*-- ---------------------------------------------------------------------------*/
    /*-- ---------------------------------------------------------------------------*/
    /*-- Cursor de los comprobantes.*/
    /*-- ---------------------------------------------------------------------------*/
    cursor trxs
    is
      select xafut.rowid row_id
      ,xafut.customer_trx_id
      ,xafut.trx_number_ori
      ,xafut.reference
      ,xitt.column3 send_file_name
      from xx_ar_fe_uy_trx xafut
      ,xx_intout_trxs_temp xitt
      where xitt.interface_id     = p_interface_id
      and xitt.request_id         = p_request_id
      and xitt.record_code        = 'MAIN'
      and xitt.record_type        = 'S'
      and to_number(xitt.column6) = xafut.customer_trx_id
      and xitt.request_id         = xafut.send_request_id
      order by xafut.customer_trx_id;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Cursor del contenido del archivo.*/
    /*-- ---------------------------------------------------------------------------*/
    cursor file_data (p_file_name in varchar2)
    is
      select xitt.text1
      ,xitt.text2
      ,xitt.text3
      from xx_ar_fe_uy_trx xafut
      ,xx_intout_trxs_temp xitt
      where xitt.interface_id     = p_interface_id
      and xitt.request_id         = p_request_id
      and xitt.output_file        = p_file_name
      and xitt.output_directory  is not null
      and xitt.output_file       is not null
      and (xitt.text1            is not null
      or xitt.text2              is not null
      or xitt.text3              is not null )
      and to_number(xitt.column6) = xafut.customer_trx_id
      and xitt.request_id         = xafut.send_request_id
      order by xitt.order_by_value;
  begin
    /*-- ---------------------------------------------------------------------------*/
    /*-- Inicializo variables Grales de Ejecucion.*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence := 'xx_ar_raxinv_pk.upload_files';
    v_conc_request_id  := fnd_global.conc_request_id;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Inicializo el debug.*/
    /*-- ---------------------------------------------------------------------------*/
    g_debug_flag     := upper(nvl(p_debug_flag ,'N'));
    g_debug_mode     := 'CONC_LOG';
    g_message_length := 4000;
    debug(g_indent || v_calling_sequence ,'1' );
    /*-- ---------------------------------------------------------------------------*/
    /*-- Despliego Parametros.*/
    /*-- ---------------------------------------------------------------------------*/
    debug(g_indent || v_calling_sequence || '. Id de la interface: ' || to_char(p_interface_id) ,'1' );
    debug(g_indent || v_calling_sequence || '. Id de concurrente: ' || to_char(p_request_id) ,'1' );
    debug(g_indent || v_calling_sequence || '. Flag de debug: ' || p_debug_flag ,'1' );
    /*-- ---------------------------------------------------------------------------*/
    /*-- Recorro los comprobantes.*/
    /*-- ---------------------------------------------------------------------------*/
    if v_mesg_error is null then
      debug(g_indent || v_calling_sequence || '. Recorriendo los comprobantes.' ,'1' );
      indent('+');
      for ct in trxs
      loop
        v_send_file_length := null;
        v_mesg_error       := null;
        debug(g_indent || v_calling_sequence || '. Id de comprobante: ' || to_char(ct.customer_trx_id) || '. Nro. de comprobante: ' || ct.trx_number_ori || '. Archivo de envio: ' || ct.send_file_name ,'1' );
        /*-- --------------------------------------------------------------------*/
        /*-- Actualizo la columna del contenido del archivo del comprobante en*/
        /*-- la tabla de Envios de Transacciones.*/
        /*-- --------------------------------------------------------------------*/
        begin
          update xx_ar_fe_uy_trx xafut
          set send_file_data                                                                                                                                                       = empty_clob()
          ,(purchase_order ,request_number ,order_source ,orig_sys_document_ref ,collection_type ,document_type ,source_system_number ,email ,stmt_source ,hotel_stmt_trx_number ) =
            (select ooh.cust_po_number
            ,rct.attribute4
            ,case
                when nvl(rctt.attribute2 ,'XX') = 'PD'
                then null
                else decode(rctl.interface_line_context ,'ORDER ENTRY' ,oos.name ,'XX_MANUAL' )
              end
            ,ooh.orig_sys_document_ref
            ,rctt.attribute2
            ,rctt.type
            ,hca.orig_system_reference
            ,decode(hca.attribute20 ,'Y' ,rct.attribute3 ,ac.email_address)
            ,xahsh.stmt_source
            ,rct.purchase_order
            from dual
            ,oe_order_sources oos
            ,oe_order_headers ooh
            ,oe_order_lines ool
            ,ra_customer_trx_lines rctl
            ,ar_contacts_v ac
            ,hz_cust_accounts hca
            ,ra_cust_trx_types rctt
            ,ra_customer_trx rct
            ,xx_ap_hotel_statements_hdr xahsh
            where 1                                                                                     = 1
            and xafut.customer_trx_id                                                                   = rct.customer_trx_id
            and rct.cust_trx_type_id                                                                    = rctt.cust_trx_type_id
            and rct.bill_to_customer_id                                                                 = hca.cust_account_id
            and hca.cust_account_id                                                                     = ac.customer_id(+)
            and rct.customer_trx_id                                                                     = rctl.customer_trx_id
            and rctl.line_type                                                                          = 'LINE'
            and rctl.interface_line_attribute6                                                          = ool.line_id(+)
            and ool.header_id                                                                           = ooh.header_id(+)
            and rct.purchase_order                                                                      = xahsh.hotel_stmt_trx_number(+)
            and decode(rctl.interface_line_context ,'ORDER ENTRY' ,rctl.interface_line_attribute1 ,-1 ) = decode(rctl.interface_line_context ,'ORDER ENTRY' ,ooh.order_number ,-1 )
            and ooh.order_source_id                                                                     = oos.order_source_id(+)
            and rownum                                                                                  = 1
            )
          ,last_update_date  = sysdate
          ,last_updated_by   = fnd_global.user_id
          ,last_update_login = fnd_global.login_id
          where xafut.rowid  = ct.row_id returning send_file_data
          into v_send_file_data;
        exception
        when others then
          v_mesg_error := 'Error actualizando ' || 'la columna del contenido del ' || 'archivo  ' || 'en la tabla de ' || 'Envios de Transacciones ' || '(xx_ar_raxinv_pk). ' || sqlerrm;
          exit;
        end;
        debug(g_indent || v_calling_sequence || '. Se actualizaron: ' || nvl(sql%rowcount ,0) || ' registros con ' || 'la columna del contenido del ' || 'archivo ' || 'en la tabla de ' || 'Envios de Transacciones ' || '(xx_ar_raxinv_pk)' ,'1' );
        /*-- --------------------------------------------------------------------*/
        /*-- Recorro el contenido del archivo.*/
        /*-- --------------------------------------------------------------------*/
        debug(g_indent || v_calling_sequence || '. Recorriendo el contenido del archivo.' ,'1' );
        indent('+');
        for cfd in file_data (ct.send_file_name)
        loop
          v_send_file_length := nvl(v_send_file_length ,0)+ nvl(length(cfd.text1) ,0)+ nvl(length(cfd.text2) ,0)+ nvl(length(cfd.text3) ,0);
          debug(g_indent || v_calling_sequence || '. Long. de la linea: ' || to_char(nvl(length(cfd.text1) ,0)+ nvl(length(cfd.text2) ,0)+ nvl(length(cfd.text3) ,0) ) ,'1' );
          /*-- ----------------------------------------------------------------*/
          /*-- Cargo el contenido del archivo.*/
          /*-- ----------------------------------------------------------------*/
          if nvl(length(cfd.text1) ,0) > 0 then
            begin
              dbms_lob.writeappend(v_send_file_data ,length(cfd.text1) ,cfd.text1);
            exception
            when others then
              v_mesg_error := 'Error cargando el ' || 'contenido del archivo ' || 'en la tabla de ' || 'Envios de Transacciones ' || '(xx_ar_raxinv_pk). ' || 'Texto: ' || cfd.text1 || '. ' || sqlerrm;
              exit;
            end;
          end if;
          if nvl(length(cfd.text2) ,0) > 0 then
            begin
              dbms_lob.writeappend(v_send_file_data ,length(cfd.text2) ,cfd.text2);
            exception
            when others then
              v_mesg_error := 'Error cargando el ' || 'contenido del archivo ' || 'en la tabla de ' || 'Envios de Transacciones ' || '(xx_ar_raxinv_pk). ' || 'Texto: ' || cfd.text2 || '. ' || sqlerrm;
              exit;
            end;
          end if;
          if nvl(length(cfd.text3) ,0) > 0 then
            begin
              dbms_lob.writeappend(v_send_file_data ,length(cfd.text3) ,cfd.text3);
            exception
            when others then
              v_mesg_error := 'Error cargando el ' || 'contenido del archivo ' || 'en la tabla de ' || 'Envios de Transacciones ' || '(xx_ar_raxinv_pk). ' || 'Texto: ' || cfd.text3 || '. ' || sqlerrm;
              exit;
            end;
          end if;
        end loop;
        indent('-');
        /*-- --------------------------------------------------------------------*/
        /*-- Verifico si se produjo un error.*/
        /*-- --------------------------------------------------------------------*/
        if v_mesg_error is not null then
          exit;
        end if;
        /*-- --------------------------------------------------------------------*/
        /*-- Actualizo la columna de longitud del archivo del comprobante en*/
        /*-- la tabla de Envios de Transacciones.*/
        /*-- --------------------------------------------------------------------*/
        begin
          update xx_ar_fe_uy_trx xafut
          set send_file_length = v_send_file_length
          ,last_update_date    = sysdate
          ,last_updated_by     = fnd_global.user_id
          ,last_update_login   = fnd_global.login_id
          where xafut.rowid    = ct.row_id;
        exception
        when others then
          v_mesg_error := 'Error actualizando ' || 'la columna de longitud del ' || 'archivo ' || 'en la tabla de ' || 'Envios de Transacciones ' || '(xx_ar_raxinv_pk). ' || sqlerrm;
          exit;
        end;
        debug(g_indent || v_calling_sequence || '. Se actualizaron: ' || nvl(sql%rowcount ,0) || ' registros con ' || 'la columna de longitud del ' || 'archivo ' || 'en la tabla de ' || 'Envios de Transacciones ' || '(xx_ar_raxinv_pk)' ,'1' );
      end loop;
      indent('-');
    end if;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Verifico si se produjo un error.*/
    /*-- ---------------------------------------------------------------------------*/
    if v_mesg_error is not null then
      raise e_exit_fail;
    end if;
    debug(g_indent || v_calling_sequence || '. Fin.' ,'1' );
  exception
  when e_exit_fail then
    debug(g_indent || v_calling_sequence || '. ' || v_mesg_error ,'1' );
    fnd_file.put(fnd_file.log ,v_mesg_error );
    fnd_file.new_line(fnd_file.log ,1);
    raise_application_error(-20000 ,substr(v_mesg_error ,1 ,250));
  when others then
    v_mesg_error := 'Error general ' || 'cargando el contenido de los archivos ' || 'a la tabla de envios. ' || sqlerrm;
    debug(v_calling_sequence || '. ' || v_mesg_error ,'1' );
    fnd_file.put(fnd_file.log ,v_mesg_error );
    fnd_file.new_line(fnd_file.log ,1);
    raise_application_error(-20000 ,substr(v_mesg_error ,1 ,250));
  end upload_files;
/*=========================================================================+
|                                                                          |
| Public Procedure                                                         |
|    report                                                                |
|                                                                          |
| Description                                                              |
|    Procedimiento del concurrente que genera el reporte respaldatorio.    |
|                                                                          |
| Parameters                                                               |
|    errbuf           OUT     VARCHAR2 Uso interno del concurrent.         |
|    retcode          OUT     NUMBER   Uso interno del concurrent.         |
|    p_interface_name IN      VARCHAR2 Nombre de la interface.             |
|    p_request_id     IN      NUMBER   Id de concurrente de generacion de  |
|                                      la interface.                       |
|    p_delete_flag    IN      VARCHAR2 Flag de eliminar registros de la    |
|                                      tabla de mensajes y reportes.       |
|    p_debug_flag     IN      VARCHAR2 Flag de debug.                      |
|                                                                          |
+=========================================================================*/
  procedure report(
      errbuf out varchar2 ,
      retcode out number ,
      p_interface_name in varchar2 ,
      p_request_id in number ,
      p_delete_flag in varchar2 ,
      p_debug_flag in varchar2 )
  is
    /*-- ---------------------------------------------------------------------------*/
    /*-- Declaracion de Variables.*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence    varchar2(2000);
    v_conc_request_id     number(15);
    v_length_line         number(15);
    v_line_single         varchar2(2000);
    v_cnt_process         number(15);
    v_directory_sep       varchar2(1);
    v_found_error         varchar2(1);
    v_line_separator      varchar2(2000);
    v_header              varchar2(2000);
    v_header_separator    varchar2(2000);
    v_path_tmp_len        number(15);
    v_file_name_tmp_len   number(15);
    v_path_prc_len        number(15);
    v_file_name_prc_len   number(15);
    v_reference_len       number(15);
    v_line                varchar2(2000);
    v_file_return         varchar2(32767);
    v_file_full_name_from varchar2(4000);
    v_file_full_name_to   varchar2(4000);
    v_file_name_prv       varchar2(255);
    v_path_tmp_prv        varchar2(4000);
    v_path_prc_prv        varchar2(4000);
    v_file_name_tmp_prv   varchar2(4000);
    v_mesg_error          varchar2(32767);
    /*-- ---------------------------------------------------------------------------*/
    /*-- Declaracion de Cursores.*/
    /*-- ---------------------------------------------------------------------------*/
    /*-- ---------------------------------------------------------------------------*/
    /*-- Cursor de los datos.*/
    /*-- ---------------------------------------------------------------------------*/
    cursor data
    is
      select nvl(ad_tmp.directory_path ,xitr.column2 ) path_tmp
      ,xitr.column3 file_name_tmp
      ,nvl(ad_prc.directory_path ,xitr.column4 ) path_prc
      ,xitr.column5 file_name_prc
      ,xitr.column1 reference
      from all_directories ad_prc
      ,all_directories ad_tmp
      ,xx_intout_trx_reports xitr
      where xitr.request_id = p_request_id
      and xitr.record_code  = 'MAIN'
      and xitr.record_type  = 'S'
      and xitr.column2      = ad_tmp.directory_name(+)
      and xitr.column4      = ad_prc.directory_name(+)
      order by nvl(ad_tmp.directory_path ,xitr.column2 )
      ,xitr.column3
      ,nvl(ad_prc.directory_path ,xitr.column4 )
      ,xitr.column5
      ,xitr.column1;
  begin
    /*-- ---------------------------------------------------------------------------*/
    /*-- Inicializo variables Grales de Ejecucion.*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence := 'xx_ar_raxinv_pk.report';
    v_conc_request_id  := fnd_global.conc_request_id;
    v_length_line      := 227;
    v_line_single      := replace(rpad(' ' ,40) ,' ' ,'-');
    v_cnt_process      := 0;
    v_directory_sep    := '/';
    v_found_error      := 'N';
    /*-- ---------------------------------------------------------------------------*/
    /*-- Inicializo el debug.*/
    /*-- ---------------------------------------------------------------------------*/
    g_debug_flag     := upper(nvl(p_debug_flag ,'N'));
    g_debug_mode     := 'CONC_LOG';
    g_message_length := 4000;
    debug(g_indent || v_calling_sequence ,'1' );
    /*-- ---------------------------------------------------------------------------*/
    /*-- Despliego Parametros.*/
    /*-- ---------------------------------------------------------------------------*/
    debug(g_indent || v_calling_sequence || '. Nombre de la interface: ' || p_interface_name ,'1' );
    debug(g_indent || v_calling_sequence || '. Id de concurrente de generacion de la interface: ' || to_char(p_request_id) ,'1' );
    debug(g_indent || v_calling_sequence || '. Flag de eliminar registros de la tabla de mensajes y reportes: ' || p_delete_flag ,'1' );
    debug(g_indent || v_calling_sequence || '. Flag de debug: ' || p_debug_flag ,'1' );
    /*-- ---------------------------------------------------------------------------*/
    /*-- Obtengo la longitud de columnas variables.*/
    /*-- ---------------------------------------------------------------------------*/
    begin
      select max(length(nvl(ad_tmp.directory_path ,xitr.column2 ) ) ) path_tmp_len
      ,max(length(xitr.column3)) file_name_tmp_len
      ,max(length(nvl(ad_prc.directory_path ,xitr.column4 ) ) ) path_prc_len
      ,max(length(xitr.column5)) file_name_prc_len
      ,max(length(xitr.column1)) reference_len
      into v_path_tmp_len
      ,v_file_name_tmp_len
      ,v_path_prc_len
      ,v_file_name_prc_len
      ,v_reference_len
      from all_directories ad_prc
      ,all_directories ad_tmp
      ,xx_intout_trx_reports xitr
      where xitr.request_id = p_request_id
      and xitr.record_code  = 'MAIN'
      and xitr.record_type  = 'S'
      and xitr.column2      = ad_tmp.directory_name(+)
      and xitr.column4      = ad_prc.directory_name(+);
    exception
    when others then
      v_path_tmp_len      := 60;
      v_file_name_tmp_len := 30;
      v_path_prc_len      := 60;
      v_file_name_prc_len := 30;
      v_reference_len     := 30;
    end;
    if v_path_tmp_len is null then
      v_path_tmp_len  := 60;
    end if;
    if v_file_name_tmp_len is null then
      v_file_name_tmp_len  := 30;
    end if;
    if v_path_prc_len is null then
      v_path_prc_len  := 60;
    end if;
    if v_file_name_prc_len is null then
      v_file_name_prc_len  := 30;
    end if;
    if v_file_name_prc_len is null then
      v_file_name_prc_len  := 30;
    end if;
    if v_reference_len is null then
      v_reference_len  := 30;
    end if;
    debug(g_indent || v_calling_sequence || '. Long. maxima de directorio temporal: ' || to_char(v_path_tmp_len) ,'1' );
    debug(g_indent || v_calling_sequence || '. Long. maxima de archivo temporal: ' || to_char(v_file_name_tmp_len) ,'1' );
    debug(g_indent || v_calling_sequence || '. Long. maxima de directorio procesado: ' || to_char(v_path_prc_len) ,'1' );
    debug(g_indent || v_calling_sequence || '. Long. maxima de archivo procesado: ' || to_char(v_file_name_prc_len) ,'1' );
    debug(g_indent || v_calling_sequence || '. Long. maxima de referencia: ' || to_char(v_reference_len) ,'1' );
    v_length_line := (v_length_line) -
    (60 + 30 + 60 + 30 + 30) + (v_path_tmp_len + v_file_name_tmp_len + v_path_prc_len + v_file_name_prc_len + v_reference_len );
    /*-- ---------------------------------------------------------------------------*/
    /*-- Inicializo variables de la salida.*/
    /*-- ---------------------------------------------------------------------------*/
    v_line_separator   := replace(rpad(' ' ,v_length_line-1) ,' ' ,'-');
    v_header           := '|'|| ' '||rpad('Directorio Temporal' ,v_path_tmp_len ,' ')||' |' || ' '||rpad('Archivo Temporal' ,v_file_name_tmp_len ,' ')||' |' || ' '||rpad('Directorio Procesados' ,v_path_prc_len ,' ')||' |' || ' '||rpad('Archivo Procesados' ,v_file_name_prc_len ,' ')||' |' || ' '||rpad('Referencia' ,v_reference_len ,' ')||' |' || '';
    v_header_separator := '|' || rpad('-' ,v_path_tmp_len+2 ,'-') || '+' || rpad('-' ,v_file_name_tmp_len+2 ,'-') || '+' || rpad('-' ,v_path_prc_len+2 ,'-') || '+' || rpad('-' ,v_file_name_prc_len+2 ,'-') || '+' || rpad('-' ,v_reference_len+2 ,'-') || '|';
    /*-- ---------------------------------------------------------------------------*/
    /*-- Despliego el titulo y cabecera.*/
    /*-- ---------------------------------------------------------------------------*/
    if v_mesg_error is null then
      fnd_file.put(fnd_file.output ,v_line_separator );
      fnd_file.new_line(fnd_file.output ,1);
      fnd_file.put(fnd_file.output ,v_header );
      fnd_file.new_line(fnd_file.output ,1);
      fnd_file.put(fnd_file.output ,v_header_separator );
      fnd_file.new_line(fnd_file.output ,1);
    end if;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Recorro los datos.*/
    /*-- ---------------------------------------------------------------------------*/
    if v_mesg_error is null then
      debug(g_indent || v_calling_sequence || '. Recorriendo los datos.' ,'1' );
      indent('+');
      for cd in data
      loop
        v_mesg_error := null;
        /*-- --------------------------------------------------------------------*/
        /*-- Asigno permisos a los directorios.*/
        /*-- --------------------------------------------------------------------*/
        if cd.path_tmp != nvl(v_path_tmp_prv ,'X') then
          debug(g_indent || v_calling_sequence || '. Asignando permisos al directorio: ' || cd.path_tmp ,'1' );
          begin
            dbms_java.grant_permission('APPS' ,'SYS:java.io.FilePermission' ,cd.path_tmp ,'read ,write, execute, delete' );
          exception
          when others then
            v_mesg_error := 'Error asignando permisos al directorio: ' || cd.path_tmp;
            exit;
          end;
          debug(g_indent || v_calling_sequence || '. Asignando permisos a los archivos del directorio: ' || cd.path_tmp ,'1' );
          begin
            dbms_java.grant_permission('APPS' ,'SYS:java.io.FilePermission' ,cd.path_tmp||v_directory_sep||'*' ,'read ,write, execute, delete' );
          exception
          when others then
            v_mesg_error := 'Error asignando permisos a ' || 'los archivos del directorio: ' || cd.path_tmp;
            exit;
          end;
        end if;
        if cd.path_prc != nvl(v_path_prc_prv ,'X') then
          debug(g_indent || v_calling_sequence || '. Asignando permisos al directorio: ' || cd.path_prc ,'1' );
          begin
            dbms_java.grant_permission('APPS' ,'SYS:java.io.FilePermission' ,cd.path_prc ,'read ,write, execute, delete' );
          exception
          when others then
            v_mesg_error := 'Error asignando permisos al directorio: ' || cd.path_prc;
            exit;
          end;
          debug(g_indent || v_calling_sequence || '. Asignando permisos a los archivos del directorio: ' || cd.path_prc ,'1' );
          begin
            dbms_java.grant_permission('APPS' ,'SYS:java.io.FilePermission' ,cd.path_prc||v_directory_sep||'*' ,'read ,write, execute, delete' );
          exception
          when others then
            v_mesg_error := 'Error asignando permisos a ' || 'los archivos del directorio: ' || cd.path_prc;
            exit;
          end;
        end if;
        debug(g_indent || v_calling_sequence || '. ' || v_line_single ,'1' );
        debug(g_indent || v_calling_sequence || '. Referencia: ' || cd.reference ,'1' );
        /*-- --------------------------------------------------------------------*/
        /*-- Despliego la linea.*/
        /*-- --------------------------------------------------------------------*/
        v_line := '|' || ' '||rpad(nvl(cd.path_tmp ,' ') ,v_path_tmp_len ,' ') || ' |' || ' '||rpad(nvl(cd.file_name_tmp ,' ') ,v_file_name_tmp_len ,' ') || ' |' || ' '||rpad(nvl(cd.path_prc ,' ') ,v_path_prc_len ,' ') || ' |' || ' '||rpad(nvl(cd.file_name_prc ,' ') ,v_file_name_prc_len ,' ') || ' |' || ' '||rpad(nvl(cd.reference ,' ') ,v_reference_len ,' ') || ' |' || '';
        fnd_file.put(fnd_file.output ,v_line );
        fnd_file.new_line(fnd_file.output ,1);
        /*-- --------------------------------------------------------------------*/
        /*-- Muevo el archivo a procesados.*/
        /*-- --------------------------------------------------------------------*/
        if v_mesg_error         is null and (cd.path_tmp != nvl(v_path_tmp_prv ,'X') or cd.file_name_tmp != nvl(v_file_name_tmp_prv ,'X') ) then
          v_file_full_name_from := cd.path_tmp || v_directory_sep || cd.file_name_tmp;
          v_file_full_name_to   := cd.path_prc || v_directory_sep || cd.file_name_prc;
          fnd_file.put(fnd_file.log ,'Moviendo el archivo: ' || v_file_full_name_from || ' a: ' || v_file_full_name_to );
          fnd_file.new_line(fnd_file.log ,1);
          v_file_return := null;
          begin
            v_file_return := xx_ar_fe_file_manager_pk.renameto (p_from_path => v_file_full_name_from ,p_to_path => v_file_full_name_to );
          exception
          when others then
            v_mesg_error := 'Error moviendo el archivo: ' || v_file_full_name_from || ' a: ' || v_file_full_name_to || '. ' || sqlerrm;
          end;
          if v_mesg_error is null and nvl(v_file_return ,'X') != 'SUCCESS' then
            v_mesg_error  := 'No se pudo mover el archivo: ' || v_file_full_name_from || ' a: ' || v_file_full_name_to || '. ' || v_file_return;
          end if;
          /*-- -----------------------------------------------------------------*/
          /*-- Verifico si se produjo un error.*/
          /*-- -----------------------------------------------------------------*/
          if v_mesg_error is not null then
            v_found_error := 'Y';
            debug(g_indent || v_calling_sequence || '. ' || v_mesg_error ,'1' );
            fnd_file.put(fnd_file.log ,v_mesg_error );
            fnd_file.new_line(fnd_file.log ,1);
            v_mesg_error := null;
          else
            v_cnt_process := nvl(v_cnt_process ,0) + 1;
          end if;
        end if;
        v_path_tmp_prv      := cd.path_tmp;
        v_path_prc_prv      := cd.path_prc;
        v_file_name_tmp_prv := cd.file_name_tmp;
      end loop;
      indent('-');
    end if;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Despliego el pie.*/
    /*-- ---------------------------------------------------------------------------*/
    if v_mesg_error is null then
      fnd_file.put(fnd_file.output ,v_line_separator );
      fnd_file.new_line(fnd_file.output ,1);
    end if;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Despliego contadores de ejecucion.*/
    /*-- ---------------------------------------------------------------------------*/
    if v_mesg_error is null then
      debug(g_indent || v_calling_sequence || '. ' || v_line_single ,'1' );
      v_mesg_error := 'Se procesaron ' || to_char(nvl(v_cnt_process ,0)) || ' registros';
      debug(g_indent || v_calling_sequence || '. ' || v_mesg_error ,'1' );
      fnd_file.put(fnd_file.output ,v_mesg_error );
      fnd_file.new_line(fnd_file.output ,1);
      v_mesg_error := null;
    end if;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Elimino los registros de la tabla de reportes.*/
    /*-- ---------------------------------------------------------------------------*/
    if v_mesg_error is null and p_delete_flag = 'Y' then
      begin
        delete from xx_intout_trx_reports xitr where xitr.request_id = p_request_id;
      exception
      when others then
        v_mesg_error := 'Error eliminando ' || 'los registros ' || 'de la tabla de ' || 'reportes. ' || sqlerrm;
      end;
    end if;
    if v_mesg_error is null then
      debug(g_indent || v_calling_sequence || '. Se eliminaron: ' || to_char(nvl(sql%rowcount ,0)) || ' registros ' || 'de la tabla de ' || 'reportes' ,'1' );
    end if;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Verifico si se produjo un error.*/
    /*-- ---------------------------------------------------------------------------*/
    if v_mesg_error is not null then
      debug(g_indent || v_calling_sequence || '. ' || v_mesg_error ,'1' );
      fnd_file.put(fnd_file.log ,v_mesg_error );
      fnd_file.new_line(fnd_file.log ,1);
      retcode := '2';
      errbuf  := substr(v_mesg_error ,1 ,250);
    else
      if v_found_error = 'Y' then
        v_mesg_error  := 'Existen errores, verificar log.';
        debug(g_indent || v_calling_sequence || '. ' || v_mesg_error ,'1' );
        fnd_file.put(fnd_file.output ,v_mesg_error );
        fnd_file.new_line(fnd_file.output ,1);
        v_mesg_error := null;
        retcode      := '1';
      else
        retcode := '0';
      end if;
    end if;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Fin de proceso.*/
    /*-- ---------------------------------------------------------------------------*/
    debug(g_indent || v_calling_sequence || '. Fin de proceso' ,'1' );
  exception
  when others then
    v_mesg_error := 'Error general ' || 'generando el reporte respaldatorio. ' || sqlerrm;
    debug(v_calling_sequence || '. ' || v_mesg_error ,'1' );
    retcode := '2';
    errbuf  := substr(v_mesg_error ,1 ,250);
    rollback;
  end report;
/*=========================================================================+
|                                                                          |
| Public Procedure                                                         |
|    main_cl_rn                                                            |
|                                                                          |
| Description                                                              |
|    Procedimiento que genera los archivos de nota de cobro para Chile     |
|                                                                          |
| Parameters                                                               |
|    errbuf            OUT VARCHAR2 Uso interno del concurrente.           |
|    retcode           OUT VARCHAR2 Uso interno del concurrente.           |
|    p_draft_mode      IN  VARCHAR2 Modo draft (Y/N).                      |
|    p_debug_flag      IN  VARCHAR2 Flag de debug.                         |
|    p_cust_trx_type   IN  NUMBER   Tipo de Transaccion.                   |
|    p_batch_source    IN  VARCHAR2 Origen.                                |
|    p_trx_number_from IN  VARCHAR2 Numero de Transaccion desde.           |
|    p_trx_number_to   IN  VARCHAR2 Numero de Transaccion hasta.           |
|    p_date_from       IN  DATE     Fecha desde.                           |
|    p_date_to         IN  DATE     Fecha hasta.                           |
|    p_customer_id     IN  NUMBER   Cliente.                               |
|    p_territory_code  IN  VARCHAR2 Pais.                                  |
|                                                                          |
+=========================================================================*/
  procedure main_cl_rn
    (errbuf            out varchar2
    ,retcode           out number
    ,p_draft_mode      in varchar2
    ,p_debug_flag      in varchar2
    ,p_batch_source    in varchar2
    ,p_cust_trx_type   in number
    ,p_trx_number_from in varchar2
    ,p_trx_number_to   in varchar2
    ,p_date_from       in varchar2
    ,p_date_to         in varchar2
    ,p_customer_id     in number
    ,p_territory_code  in varchar2 )
  is
    /*-- ---------------------------------------------------------------------------*/
    /*-- Definicion de Variables*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence      varchar2(2000);
    v_request_id            number(15);
    v_mesg_error            varchar2(32767);
    v_mesg_api_error        varchar2(32767);
    v_return_status         varchar2(1);
    v_msg_count             number;
    v_msg_data              varchar2(2000);
    v_msg_index_out         number;
    v_order_source          oe_order_sources.name%type;
    v_orig_sys_document_ref oe_order_headers.orig_sys_document_ref%type;
    v_stmt_source           xx_ap_hotel_statements_hdr.stmt_source%type;
    v_hotel_stmt_trx_number xx_ap_hotel_statements_hdr.hotel_stmt_trx_number%type;
    v_month_billed          xx_ap_hotel_statements_hdr.period_name%type;
    v_amount_in_words       varchar2(4000);
    v_send_file             clob;
    v_send_line             varchar2(4000);
    v_nro_lin_det           number;
    v_success_qty           number  := 0;
    v_error_qty             number  := 0;
    v_is_prod_env           boolean := false;
    v_is_test_env           boolean := false;
  begin
    /*-- ---------------------------------------------------------------------------*/
    /*-- Inicializo variables Grales de Ejecucion.*/
    /*-- ---------------------------------------------------------------------------*/
    v_calling_sequence := 'xx_ar_raxinv_pk.main_cl_rn';
    v_request_id       := fnd_global.conc_request_id;
    /*-- ---------------------------------------------------------------------------*/
    /*-- Inicializo el debug.*/
    /*-- ---------------------------------------------------------------------------*/
    g_debug_flag     := upper(nvl(p_debug_flag,'N'));
    g_debug_mode     := 'CONC_LOG';
    g_message_length := 4000;
    debug(g_indent || v_calling_sequence ,'1' );
    /*-- ---------------------------------------------------------------------------*/
    /*-- Despliego Parametros.*/
    /*-- ---------------------------------------------------------------------------*/
    debug(g_indent || v_calling_sequence || '. Modo draft: ' || p_draft_mode ,'1' );
    debug(g_indent || v_calling_sequence || '. Origen: ' || p_batch_source ,'1' );
    debug(g_indent || v_calling_sequence || '. Tipo de Transaccion: ' || p_cust_trx_type ,'1' );
    debug(g_indent || v_calling_sequence || '. Numero Transaccion desde: ' || p_trx_number_from ,'1' );
    debug(g_indent || v_calling_sequence || '. Numero Transaccion hasta: ' || p_trx_number_from ,'1' );
    debug(g_indent || v_calling_sequence || '. Fecha desde: ' || p_date_from ,'1' );
    debug(g_indent || v_calling_sequence || '. Fecha hasta: ' || p_date_to ,'1' );
    debug(g_indent || v_calling_sequence || '. Cliente: ' || p_customer_id ,'1' );
    debug(g_indent || v_calling_sequence || '. Pais: ' || p_territory_code ,'1' );
    debug(g_indent || v_calling_sequence || '. Flag de debug: ' || p_debug_flag ,'1' );
    debug(g_indent || v_calling_sequence || '. Obtiene facturas a procesar' ,'1' );
    /*-- Verifica si se ejecuta en entorno de produccion*/
    if (fnd_profile.value('TWO_TASK') = 'EBSP') then
      v_is_prod_env := true;
    else
      v_is_test_env := true;
    end if;
    /*-- Para modo draft se debe informar Transaccion Desde y Hasta*/
    if (nvl(p_draft_mode,'N') = 'Y' and (p_trx_number_from is null or p_trx_number_to is null)) then
      v_mesg_error := 'Para Modo Draft informar Transaccions Desde y Hasta';
      debug(v_calling_sequence || '. ' || v_mesg_error ,'1' );
      fnd_file.put(fnd_file.log ,g_indent || v_calling_sequence || '. ' || v_mesg_error );
      fnd_file.new_line(fnd_file.log ,1);
      retcode := '1';
      errbuf  := substr(v_mesg_error ,1 ,2000);
      return;
    end if;
    open c_trxs(p_customer_id      => p_customer_id
               ,p_cust_trx_type_id => p_cust_trx_type
               ,p_trx_number_from  => p_trx_number_from
               ,p_trx_number_to    => p_trx_number_to
               ,p_date_from        => fnd_date.canonical_to_date(p_date_from)
               ,p_date_to          => fnd_date.canonical_to_date(p_date_to)
               ,p_draft_mode       => nvl(p_draft_mode,'N'));
    loop
      fetch c_trxs bulk collect into v_trxs_aux_tbl limit 5000;
      exit
    when v_trxs_aux_tbl.count = 0;
      /*-- Completa estructura v_trxs_tbl*/
      for i in 1..v_trxs_aux_tbl.count
      loop
        v_trxs_aux_tbl(i).status         := 'NEW';
        v_trxs_aux_tbl(i).error_code     := null;
        v_trxs_aux_tbl(i).error_messages := null;
        v_trxs_tbl(v_trxs_tbl.count+1)   := v_trxs_aux_tbl(i);
      end loop;
    end loop;
    close c_trxs;
    debug(g_indent||v_calling_sequence||'. Obtuvo '||v_trxs_tbl.count||' facturas a procesar','1');
    if (v_trxs_tbl.count = 0) then
      v_mesg_error      := 'NO_DATA_FOUND';
    end if;
    /*-- Completa detalles a imprimir*/
    if (v_mesg_error is null) then
      for i in 1..v_trxs_tbl.count
      loop
        dbms_lob.createtemporary(v_send_file,false);
        debug(g_indent||v_calling_sequence||'. Customer_Trx_ID: '||v_trxs_tbl(i).customer_trx_id||' Generic Customer ? '||v_trxs_tbl(i).generic_customer,'1');
        /*-- Verifico que los Extra-Attributes se encuentran creados para la factura*/
        if (not xx_ar_reg_send_invoices_pk.extra_attributes_exists(p_customer_trx_id => v_trxs_tbl(i).customer_trx_id)) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages := 'No existen los registros de extra-attributes para las lineas de pedidos de ventas';
          debug(g_indent || v_calling_sequence || ' No existen los registros de extra-attributes de las lineas de pedidos de ventas para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        end if;
        /*-- Verifico que la moneda de impresion informada sea correcta*/
        if (not xx_ar_reg_send_invoices_pk.printing_currency_is_valid (p_printing_currency_code =>v_trxs_tbl(i).printing_currency_code ,p_functional_currency_code =>g_func_currency_code ,p_document_currency_code =>v_trxs_tbl(i).invoice_currency_code)) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '020_INVALID_CONFIGURATION';
          v_trxs_tbl(i).error_messages := 'La moneda de impresion de factura('||v_trxs_tbl(i).printing_currency_code||')'|| ' solo puede ser igual a la moneda de la transaccion('||v_trxs_tbl(i).invoice_currency_code||')'|| ' o la moneda funcional del pais ('||g_func_currency_code||')';
          debug(g_indent || v_calling_sequence || ' La moneda de impresion de factura es diferente a la moneda de la transaccion y a la moneda funcional para customer_trx_id:'||' ' ||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        end if;
        /*-- Verifica si es un cliente generico o no para obtener los datos*/
        if (v_trxs_tbl(i).generic_customer = 'N') then
          begin
            select replace(hp.party_name,'('||v_trxs_tbl(i).org_country||')','')
                  ,hp.attribute3
                  ,hp.jgzz_fiscal_code||hca.global_attribute12
                  ,hp.jgzz_fiscal_code
                  ,hca.global_attribute12
                  ,ac.email_address
                  ,substr(hl_cusb.address1||decode(hl_cusb.address2 ,null ,null ,','||hl_cusb.address2)||decode(hl_cusb.address3 ,null ,null ,','||hl_cusb.address3)||decode(hl_cusb.address4 ,null ,null ,','||hl_cusb.address4) ,1 ,150) customer_base_address
                  ,hcasb.attribute1
                  ,hl_cusb.province
                  ,hl_cusb.city
                  ,hl_cusb.country
            into   v_trxs_tbl(i).customer_name
                  ,v_trxs_tbl(i).customer_doc_type
                  ,v_trxs_tbl(i).customer_doc_number_full
                  ,v_trxs_tbl(i).customer_doc_number
                  ,v_trxs_tbl(i).customer_doc_digit
                  ,v_trxs_tbl(i).customer_email
                  ,v_trxs_tbl(i).customer_base_address
                  ,v_trxs_tbl(i).giro_receptor_code
                  ,v_trxs_tbl(i).province_receptor_name
                  ,v_trxs_tbl(i).city_receptor_name
                  ,v_trxs_tbl(i).pais_receptor_code
            from   hz_party_sites     hpsb
                  ,hz_cust_acct_sites hcasb
                  ,hz_cust_site_uses  hcsub
                  ,hz_locations       hl_cusb
                  ,hz_parties         hp
                  ,ar_contacts_v      ac
                  ,hz_cust_accounts   hca
            where  1=1
            and v_trxs_tbl(i).party_id            = hp.party_id
            and v_trxs_tbl(i).cust_account_id     = hca.cust_account_id
            and hca.cust_account_id               = ac.customer_id(+)
            and v_trxs_tbl(i).bill_to_site_use_id = hcsub.site_use_id
            and hcsub.cust_acct_site_id           = hcasb.cust_acct_site_id
            and hcasb.party_site_id               = hpsb.party_site_id
            and hpsb.location_id                  = hl_cusb.location_id
            and rownum                           <= 1;
          exception
            when others then
              v_trxs_tbl(i).status         := 'ERROR';
              v_trxs_tbl(i).error_code     := '030_UNEXPECTED_ERROR';
              v_trxs_tbl(i).error_messages := 'Error inesperado obteniendo datos de cliente :'||sqlerrm;
              v_trxs_tbl(i).customer_name  := 'ERROR OBTENIENDO DATOS CLIENTE';
              debug(g_indent||v_calling_sequence||' Error inesperado obteniendo datos de cliente particular '||v_trxs_tbl(i).cust_account_id||' '||sqlerrm ,'1');
              continue;
          end;
        end if;
        /*-- Obtengo la descripcion para el giro comercial del cliente*/
        if (v_trxs_tbl(i).pais_receptor_name is null) then
          begin
            select flv.description
            into   v_trxs_tbl(i).giro_receptor_meaning
            from   fnd_lookup_values_vl flv
            where  1=1
            and    flv.lookup_type = 'XX_GIROS_COMERCIALES'
            and    flv.lookup_code = v_trxs_tbl(i).giro_receptor_code;
          exception
            when others then
              null;
          end;
        end if;
        /*-- Obtengo la descripcion para las geografias*/
        /*-- Pais*/
        if (v_trxs_tbl(i).pais_receptor_name is null) then
          begin
            select hg.geography_name
            into   v_trxs_tbl(i).pais_receptor_name
            from   hz_geographies hg
            where  1=1
            and    country_code   = v_trxs_tbl(i).pais_receptor_code
            and    geography_type = 'COUNTRY'
            and    rownum         = 1;
          exception
            when others then
              null;
          end;
        end if;
        /*-- Province*/
        if (v_trxs_tbl(i).province_receptor_name is null) then
          begin
            select hg.geography_name
            into   v_trxs_tbl(i).province_receptor_name
            from   hz_geographies hg
            where  1=1
            and    country_code      = v_trxs_tbl(i).pais_receptor_code
            and    hg.geography_code = v_trxs_tbl(i).province_receptor_code
            and    hg.geography_type = 'PROVINCE'
            and    hg.geography_use  = 'MASTER_REF'
            and    rownum            = 1;
          exception
            when others then
              null;
          end;
        end if;
        /*-- City (Comuna)*/
        if (v_trxs_tbl(i).city_receptor_name is null) then
          begin
            select hg.geography_name
            into   v_trxs_tbl(i).city_receptor_name
            from   hz_geographies hg
            where  1=1
            and    country_code               = v_trxs_tbl(i).pais_receptor_code
            and    hg.geography_element2_code = v_trxs_tbl(i).province_receptor_code
            and    hg.geography_code          = v_trxs_tbl(i).city_receptor_code
            and    hg.geography_type          = 'CITY'
            and    hg.geography_use           = 'MASTER_REF'
            and    rownum                     = 1;
          exception
            when others then
              null;
          end;
        end if;
        /*-- Armo la direccion final del cliente*/
        begin
          select substr(v_trxs_tbl(i).customer_base_address
                 ||decode(v_trxs_tbl(i).province_receptor_name ,null ,null ,','
                 ||v_trxs_tbl(i).province_receptor_name)
                 ||decode(v_trxs_tbl(i).city_receptor_name ,null ,null ,','
                 ||v_trxs_tbl(i).city_receptor_name)
                 ||decode(v_trxs_tbl(i).pais_receptor_name ,null ,null ,','
                 ||v_trxs_tbl(i).pais_receptor_name) ,1 ,150) customer_address
          into   v_trxs_tbl(i).customer_address
          from   dual;
        exception
          when others then
            null;
        end;
        /*-- Llamo a la funcion que calcula los totales del Comprobante*/
        begin
          v_mesg_api_error := null;
          xx_ar_reg_send_invoices_pk.get_invoice_values_vat_details(p_customer_trx_id        => v_trxs_tbl(i).customer_trx_id
                                                                   ,p_country                => 'CL'
                                                                   ,p_vat_tax                => g_vat_tax
                                                                   ,x_net_amount             => v_trxs_tbl(i).net_amount
                                                                   ,x_net_amount_pcc         => v_trxs_tbl(i).net_amount_pcc
                                                                   ,x_tax_amount             => v_trxs_tbl(i).tax_amount
                                                                   ,x_tax_amount_pcc         => v_trxs_tbl(i).tax_amount_pcc
                                                                   ,x_total_amount           => v_trxs_tbl(i).total_amount
                                                                   ,x_total_amount_pcc       => v_trxs_tbl(i).total_amount_pcc
                                                                   ,x_net_amount_exento      => v_trxs_tbl(i).net_amount_exento
                                                                   ,x_net_amount_exento_pcc  => v_trxs_tbl(i).net_amount_exento_pcc
                                                                   ,x_net_amount_gravado     => v_trxs_tbl(i).net_amount_gravado
                                                                   ,x_net_amount_gravado_pcc => v_trxs_tbl(i).net_amount_gravado_pcc
                                                                   ,x_tax_amount_iva         => v_trxs_tbl(i).tax_amount_iva
                                                                   ,x_tax_amount_iva_pcc     => v_trxs_tbl(i).tax_amount_iva_pcc
                                                                   ,x_collection_country     => v_trxs_tbl(i).collection_country
                                                                   ,x_invoice_currency_code  => v_trxs_tbl(i).invoice_currency_code
                                                                   ,x_printing_currency_code => v_trxs_tbl(i).printing_currency_code
                                                                   ,x_return_status          => v_return_status
                                                                   ,x_msg_count              => v_msg_count
                                                                   ,x_msg_data               => v_msg_data);
          if (v_return_status != fnd_api.g_ret_sts_success) then
            for cnt in 1..v_msg_count
            loop
              fnd_msg_pub.get(p_msg_index     => cnt
                             ,p_encoded       => fnd_api.g_false
                             ,p_data          => v_msg_data
                             ,p_msg_index_out => v_msg_index_out);
              v_mesg_api_error := v_mesg_api_error || v_msg_data;
            end loop;
            v_mesg_api_error := 'Get_Invoice_Values_Tax_Details: '||v_mesg_api_error;
          end if;
        exception
          when others then
            v_mesg_api_error := 'Get_Invoice_Values_Tax_Details: '||sqlerrm;
        end;
        /*-- Valido que se hayan podido obtener los importes en la API*/
        if (v_mesg_api_error           is not null) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '030_UNEXPECTED_ERROR';
          v_trxs_tbl(i).error_messages := 'Error inesperado obteniendo Valores del Comprobante '|| v_mesg_api_error;
          debug(g_indent||v_calling_sequence||' Error inesperado obteniendo valores para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        end if;
--      /*No hay impuestos en la nota de cobro*/
--        /*-- Obtengo la Tasa de Iva de la Factura, No puede haber mas de un porcentaje.*/
--        begin
--          select zx_rate.percentage_rate
--          into   v_trxs_tbl(i).vat_percentage
--          from   ra_customer_trx_lines_all rctlt
--                ,zx_lines zx_line
--                ,zx_rates_vl zx_rate
--          where  1=1
--          and    rctlt.line_type(+)                   = 'TAX'
--          and    zx_rate.tax_rate_id(+)               = zx_line.tax_rate_id
--          and    zx_line.tax_line_id(+)               = rctlt.tax_line_id
--          and    zx_line.entity_code                  = 'TRANSACTIONS'
--          and    zx_rate.tax                          = g_vat_tax
--          and    zx_line.application_id               = 222
--          and    rctlt.customer_trx_id                = v_trxs_tbl(i).customer_trx_id
--          and    (    (    v_trxs_tbl(i).electr_doc_type not in ('110' ,'112')
--                      and nvl (zx_rate.percentage_rate ,0)    != 0)
--                   or /*-- Fac Nacional, solo me interesan las lineas != 0*/
--                     (v_trxs_tbl(i).electr_doc_type in ('110' ,'112'))) /*-- Fac Exportacion*/
--          group by zx_rate.percentage_rate;
--          /*-- Para la Factura de Exportacion la tasa siempre debe ser 0*/
--          if (v_trxs_tbl(i).electr_doc_type in ('110' ,'112') and v_trxs_tbl(i).vat_percentage != 0) then
--            v_trxs_tbl(i).status         := 'ERROR';
--            v_trxs_tbl(i).error_code     := '030_UNEXPECTED_ERROR';
--            v_trxs_tbl(i).error_messages := 'La Tasa de Iva para el comprobante de exportacion debe ser siempre 0.';
--            debug(g_indent||v_calling_sequence||'  La Tasa de Iva para el comprobante de exportacion debe ser siempre 0 para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
--            continue;
--          end if;
--        exception
--          when others then
--            v_trxs_tbl(i).status         := 'ERROR';
--            v_trxs_tbl(i).error_code     := '030_UNEXPECTED_ERROR';
--            v_trxs_tbl(i).error_messages := 'No se pudo obtener la Tasa de Iva para el comprobante. Debe existir una tasa unica de iva.'||sqlerrm;
--            debug(g_indent || v_calling_sequence || '  No se pudo obtener una Tasa de Iva unica para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id||' '||sqlerrm ,'1' );
--            continue;
--        end;
        /*-- Llamo a la funcion que calcula el monto en letras*/
        v_amount_in_words := xx_ar_reg_send_invoices_pk.get_amount_in_words(p_amount                => v_trxs_tbl(i).total_amount_pcc
                                                                           ,p_country_currency_code => g_func_currency_code
                                                                           ,p_amount_currency_code  => v_trxs_tbl(i).printing_currency_code
                                                                           ,p_country_code          => 'CL');
        /*-- Si es una NC, llamo a la funcion que obtiene la referencia a la FC original*/
        if (v_trxs_tbl(i).document_type      = 'CM') then
          v_trxs_tbl(i).ref_customer_trx_id := xx_ar_utilities_pk.get_related_invoice_id (p_customer_trx_id => v_trxs_tbl(i).customer_trx_id);
          /*-- Obtengo los datos del comprobante relacionado*/
          get_datos_trx(p_customer_trx_id          => v_trxs_tbl(i).ref_customer_trx_id
                       ,x_trx_number               => v_trxs_tbl(i).ref_trx_number
                       ,x_trx_date                 => v_trxs_tbl(i).ref_trx_date
                       ,x_electr_doc_type          => v_trxs_tbl(i).ref_electr_doc_type
                       ,x_procesado_fc_electronica => v_trxs_tbl(i).ref_procesado_fc_electronica);
        end if;
        /*-- Valida datos obligatorios*/
        if (v_trxs_tbl(i).customer_name is null) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages := 'No se informo nombre del cliente';
          v_trxs_tbl(i).customer_name  := 'NO INFORMADO';
          debug(g_indent || v_calling_sequence || ' No se informo nombre del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).customer_doc_number is null) then
          v_trxs_tbl(i).status              := 'ERROR';
          v_trxs_tbl(i).error_code          := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages      := 'No se informo Nro Documento del cliente';
          v_trxs_tbl(i).customer_doc_number := '0';
          debug(g_indent || v_calling_sequence || ' No se informo Nro Documento del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).pais_receptor_name is null) then
          v_trxs_tbl(i).status             := 'ERROR';
          v_trxs_tbl(i).error_code         := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages     := 'No se informo Pais del cliente';
          v_trxs_tbl(i).pais_receptor_name := 'X';
          debug(g_indent || v_calling_sequence || ' No se informo Pais del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).contributor_source is null) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages := 'El cliente no tiene informado el contributor source en el maestro';
          debug(g_indent || v_calling_sequence || ' No se informo contributor_source del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).customer_doc_type not in ('RUT' ,'RUN' ,'PASS')) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '020_INVALID_CONFIGURATION';
          v_trxs_tbl(i).error_messages := 'Tipo de Documento de Cliente Invalido o Nulo: '||v_trxs_tbl(i).customer_doc_type;
          debug(g_indent || v_calling_sequence || ' Se informo un tipo de documento de Cliente nulo o invalido para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).giro_emisor_meaning is null or v_trxs_tbl(i).acteco_code is null) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages := 'La entidad legal no tiene informado el giro comercial y/o la actividad economica';
          debug(g_indent || v_calling_sequence || ' No se informo el giro/comercial y/o la actividad economica de la Entidad Legal para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).expedition_address is null or v_trxs_tbl(i).expedition_place is null) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages := 'La entidad legal no tiene informado el domicilio y/o la ciudad';
          debug(g_indent || v_calling_sequence || ' No se informo el domicilio y/o la ciudad de la Entidad Legal para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).contributor_source = 'DOMESTIC_ORIGIN' and v_trxs_tbl(i).giro_receptor_meaning is null) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages := 'No se pudo obtener el giro comercial del cliente';
          debug(g_indent || v_calling_sequence || ' No se informo el giro comercial del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_trxs_tbl(i).contributor_source = 'DOMESTIC_ORIGIN' and (v_trxs_tbl(i).province_receptor_name is null or v_trxs_tbl(i).city_receptor_name is null)) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages := 'No se pudo obtener la provincia y/o comuna del cliente';
          debug(g_indent || v_calling_sequence || ' No se informo la provincia y/o comuna del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
        elsif (v_amount_in_words is null) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '010_MISSING_VALUE';
          v_trxs_tbl(i).error_messages := 'No se pudo calcular el monto en letras';
          debug(g_indent || v_calling_sequence || ' No se pudo calcular el monto en letras para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
          /*-- Valido que el tipo de documento sea uno de los esperados*/
        elsif (v_trxs_tbl(i).electr_doc_type not in ('39' ,'33' ,'61' ,'110' ,'112')) then
          v_trxs_tbl(i).status         := 'ERROR';
          v_trxs_tbl(i).error_code     := '020_INVALID_CONFIGURATION';
          v_trxs_tbl(i).error_messages := 'Tipo de Doc de Fc Electronica Invalido: '||v_trxs_tbl(i).electr_doc_type;
          debug(g_indent || v_calling_sequence || ' Tipo de Doc invalido para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
          continue;
          /*-- Valido la informacion del comprobante referenciado para las NC*/
        elsif (v_trxs_tbl(i).document_type = 'CM') then
          /*-- Valido que exista la Referencia*/
          if (v_trxs_tbl(i).ref_trx_number is null) then
            v_trxs_tbl(i).status         := 'ERROR';
            v_trxs_tbl(i).error_code     := '010_MISSING_VALUE';
            v_trxs_tbl(i).error_messages := 'No se pudo obtener la referencia a la FC: ';
            debug(g_indent || v_calling_sequence || ' No se pudo obtener la referencia a la factura para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
            continue;
          end if;
          /*-- Valido que se haya obtenido la informacion del tipo de trx de la referencia*/
          if (v_trxs_tbl(i).ref_electr_doc_type is null) then
            v_trxs_tbl(i).status         := 'ERROR';
            v_trxs_tbl(i).error_code     := '010_MISSING_VALUE';
            v_trxs_tbl(i).error_messages := 'No se pudo obtener el tipo de documento electronico para la FC referenciada('||v_trxs_tbl(i).ref_trx_number||')';
            debug(g_indent || v_calling_sequence || ' No se pudo obtener el tipo de documento electronico para la FC referenciada para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
            continue;
          end if;
          /*-- Valido que la factura referenciada haya vuelto de factura electronica*/
          if (nvl (v_trxs_tbl(i).ref_procesado_fc_electronica ,'N') = 'N') then
            v_trxs_tbl(i).status         := 'ERROR';
            v_trxs_tbl(i).error_code     := '010_MISSING_VALUE';
            v_trxs_tbl(i).error_messages := 'La factura referenciada ('|| v_trxs_tbl(i).ref_trx_number||') aun no fue procesada por fc electronica';
            debug(g_indent || v_calling_sequence || 'La factura referenciada aun no fue procesada por fc electronica para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
            continue;
          end if;
          /*-- Valido que los tipos de documentos relacionados esten Ok*/
          if (v_trxs_tbl(i).electr_doc_type not in ('61' ,'112') or /*-- Nc*/
             (v_trxs_tbl(i).electr_doc_type = '61' and v_trxs_tbl(i).ref_electr_doc_type not in ('33' ,'39')) or /*-- Fc Nacional*/
             (v_trxs_tbl(i).electr_doc_type = '112' and v_trxs_tbl(i).ref_electr_doc_type not in ('110'))) then /*-- Fc Exportacion*/
            v_trxs_tbl(i).status         := 'ERROR';
            v_trxs_tbl(i).error_code     := '020_INVALID_CONFIGURATION';
            v_trxs_tbl(i).error_messages := 'Tipo de Doc Invalido de Fc Electr para combinacion NC('||v_trxs_tbl(i).electr_doc_type||') '|| 'y Ref de Fc('||v_trxs_tbl(i).ref_electr_doc_type||')';
            debug(g_indent || v_calling_sequence || ' Combinacion Invalida de Tipos de Doc de Fc Electr para NC/FC para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id ,'1' );
            continue;
          end if;
        end if;
        begin
          v_send_line := '<?xml version="1.0" encoding="UTF-8"?>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<!-- Generated by XX_AR_RAXINV_PK - 20170105 - AMalatesta -->'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<DTE>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          if (v_trxs_tbl(i).electr_doc_type = '39') then
            v_send_line                    := '<Boleta>'||g_eol;
          elsif (v_trxs_tbl(i).electr_doc_type in ('110' ,'112')) then /*-- Fc Exportacion*/
            v_send_line := '<Exportaciones>'||g_eol;
          else
            v_send_line := '<Documento>'||g_eol;
          end if;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*----------------------- Inicio de Seccion Encabezado -----------------------------*/
          v_send_line := '<Encabezado>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*----------------------- Inicio de Seccion IDoc ----------------------------------*/
          v_send_line := '<IdDoc>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<TipoDTE>'||v_trxs_tbl(i).electr_doc_type||'</TipoDTE>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<Folio>'||v_trxs_tbl(i).trx_number||'</Folio>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<FchEmis>'||to_char(v_trxs_tbl(i).trx_date ,'YYYY-MM-DD')||'</FchEmis>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<comments>'||v_trxs_tbl(i).comments||'</comments>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<cust_trx_concept>'||v_trxs_tbl(i).cust_trx_concept||'</cust_trx_concept>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          if (v_trxs_tbl(i).electr_doc_type in ('39' ,'61')) then
            v_send_line := '<IndServicio>'||v_trxs_tbl(i).electr_serv_type||'</IndServicio>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          v_send_line := '</IdDoc>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion IDoc --------------------------------------*/
          /*-------------------------- Inicio de Seccion Emisor ----------------------------------*/
          v_send_line := '<Emisor>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<RUTEmisor>'||v_trxs_tbl(i).legal_entity_identifier||'</RUTEmisor>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          if (v_trxs_tbl(i).electr_doc_type = '39') then
            v_send_line                    := '<RznSocEmisor>'||v_trxs_tbl(i).legal_entity_name||'</RznSocEmisor>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          else
            v_send_line := '<RznSoc>'||v_trxs_tbl(i).legal_entity_name||'</RznSoc>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          if (v_trxs_tbl(i).electr_doc_type = '39') then
            v_send_line                    := '<GiroEmisor>'||v_trxs_tbl(i).giro_emisor_meaning||'</GiroEmisor>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          else
            v_send_line := '<GiroEmis>'||v_trxs_tbl(i).giro_emisor_meaning||'</GiroEmis>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          if (v_trxs_tbl(i).electr_doc_type != '39') then
            v_send_line                     := '<Acteco>'||v_trxs_tbl(i).acteco_code||'</Acteco>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          v_send_line := '<DirOrigen>'||v_trxs_tbl(i).expedition_address||'</DirOrigen>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<CmnaOrigen>'||v_trxs_tbl(i).expedition_place||'</CmnaOrigen>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</Emisor>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Emisor --------------------------------------*/
          /*-------------------------- Inicio de Seccion Receptor -----------------------------------*/
          v_send_line := '<Receptor>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          if (v_trxs_tbl(i).customer_doc_type in ('RUT' ,'RUN' ,'PASS')) then
            v_send_line := '<RUTRecep>'||v_trxs_tbl(i).customer_doc_number || '-'||v_trxs_tbl(i).customer_doc_digit||'</RUTRecep>'||g_eol;
          else
            v_send_line := '<RUTRecep>'||v_trxs_tbl(i).customer_doc_number_full||'</RUTRecep>'||g_eol;
          end if;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<RznSocRecep>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).customer_name)||'</RznSocRecep>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          if (v_trxs_tbl(i).electr_doc_type in ('33' ,'110')) then
            v_send_line := '<GiroRecep>'||v_trxs_tbl(i).giro_receptor_meaning||'</GiroRecep>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          v_send_line := '<DirRecep>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).customer_address)||'</DirRecep>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-- Comprobante de Exportacion*/
          if (v_trxs_tbl(i).electr_doc_type in ('110' ,'112')) then
            v_send_line := '<CmnaRecep>'||'</CmnaRecep>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<CiudadRecep>'||v_trxs_tbl(i).city_receptor_name||'</CiudadRecep>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          else /*-- Comprobante Nacional*/
            v_send_line := '<CmnaRecep>'||v_trxs_tbl(i).city_receptor_name||'</CmnaRecep>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<CiudadRecep>'||v_trxs_tbl(i).province_receptor_name||'</CiudadRecep>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          v_send_line := '</Receptor>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Receptor --------------------------------------*/
          /*-------------------------- Inicio de Seccion Transporte -----------------------------------*/
          /*-- Solo se imprime para comprobantes de exportacion*/
          if (v_trxs_tbl(i).electr_doc_type in ('110' ,'112')) then
            v_send_line := '<Transporte>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<Aduana>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<CodePaisDestin>'||v_trxs_tbl(i).pais_receptor_code||'</CodePaisDestin>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</Aduana>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</Transporte>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          /*-------------------------- Fin de Seccion Transporte --------------------------------------*/
          /*-------------------------- Inicio de Seccion Totales --------------------------------------*/
          v_send_line := '<Totales>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-- Solo se imprime para comprobantes que no son boleta  (Si es una Nc, su referencia no tiene que ser Boleta)*/
          if (v_trxs_tbl(i).electr_doc_type != '39' and nvl (v_trxs_tbl(i).ref_electr_doc_type ,'X') != '39') then
            /*-- Solo se imprime para comprobantes de exportacion*/
            if (v_trxs_tbl(i).electr_doc_type in ('110' ,'112')) then
              v_send_line := '<TpoMoneda>'||v_trxs_tbl(i).printing_currency_code||'</TpoMoneda>'||g_eol;
              dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
              v_send_line := '<MntExe>'||v_trxs_tbl(i).net_amount_exento_pcc||'</MntExe>'||g_eol;
              dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            else /*-- Solo se imprime para comprobantes Nacionales*/
              v_send_line := '<MntNeto>'||v_trxs_tbl(i).net_amount_gravado_pcc||'</MntNeto>'||g_eol;
              dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
              v_send_line := '<TasaIVA>'||v_trxs_tbl(i).vat_percentage||'</TasaIVA>'||g_eol;
              dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
              v_send_line := '<IVA>'||v_trxs_tbl(i).tax_amount_iva_pcc||'</IVA>'||g_eol;
              dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            end if;
          end if;
          v_send_line := '<MntTotal>'||v_trxs_tbl(i).total_amount_pcc||'</MntTotal>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</Totales>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Totales --------------------------------------------*/
          /*----------------------- Fin de Seccion Encabezado -----------------------------*/
          v_send_line := '</Encabezado>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_nro_lin_det := 0;
          /*-------------------------- Inicio de Seccion Detalles ----------------------------------------*/
          v_send_line := '<Detalle>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          for r_trxs_lines in c_trx_lines(p_customer_trx_id        => v_trxs_tbl(i).customer_trx_id
                                         ,p_vat_tax                => g_vat_tax
                                         ,p_printing_currency_code => v_trxs_tbl(i).printing_currency_code
                                         ,p_invoice_currency_code  => v_trxs_tbl(i).invoice_currency_code
                                         ,p_exchange_rate          => v_trxs_tbl(i).exchange_rate
                                         ,p_cust_trx_concept       => v_trxs_tbl(i).cust_trx_concept)
          loop
            if (r_trxs_lines.item_description is null) then
              v_trxs_tbl(i).status     := 'ERROR';
              v_trxs_tbl(i).error_code := '020_INVALID_CONFIGURATION';
              select 'No se pudo obtener descripcion para articulo '
                     ||msib.segment1
                     ||' y '
                     ||v_trxs_tbl(i).cust_trx_type_name
              into   v_trxs_tbl(i).error_messages
              from   mtl_system_items_b msib
              where  1=1
              and    msib.inventory_item_id = r_trxs_lines.inventory_item_id
              and    msib.organization_id   = r_trxs_lines.organization_id;
              debug(g_indent || v_calling_sequence || v_trxs_tbl(i).error_messages ,'1' );
              continue;
            end if;
            v_nro_lin_det := v_nro_lin_det + 1;
            v_send_line   := '<NroLinDet>'||v_nro_lin_det||'</NroLinDet>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<NmbItem>'||psp_xmlgen.convert_xml_controls(r_trxs_lines.item_description)||'</NmbItem>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<QtyItem>'||r_trxs_lines.quantity||'</QtyItem>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<UnmdItem>'||'UNID'||'</UnmdItem>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<PrcItem>'||r_trxs_lines.net_amount_pcc||'</PrcItem>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<MontoItem>'||r_trxs_lines.net_amount_pcc||'</MontoItem>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end loop;
          v_send_line := '</Detalle>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Detalle --------------------------------------------*/
          /*---------------------- Solo se completa para Notas de Credito ----------------------------------*/
          /*-------------------------- Inicio de Seccion Referencias  --------------------------------------*/
          if (v_trxs_tbl(i).electr_doc_type in ('61' ,'112')) then
            v_send_line := '<Referencias>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<TpoDocRef>'||v_trxs_tbl(i).ref_electr_doc_type||'</TpoDocRef>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<FolioRef>'||v_trxs_tbl(i).ref_trx_number||'</FolioRef>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<FchRef>'||v_trxs_tbl(i).ref_trx_date||'</FchRef>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<CodRef>'||'3'||'</CodRef>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</Referencias>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          /*-------------------------- Fin de Seccion Referencias  ------------------------------------------*/
          /*---- Monto en Letras*/
          /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
          v_send_line := '<DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<NombreDA>'||'Observacion'||'</NombreDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<ValorDA>'||v_amount_in_words||'</ValorDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
          /*---- Informacion de Terceros*/
          for r_trxs_lines_terceros in c_trx_lines_terceros(p_customer_trx_id        => v_trxs_tbl(i).customer_trx_id
                                                           ,p_printing_currency_code => v_trxs_tbl(i).printing_currency_code
                                                           ,p_invoice_currency_code  => v_trxs_tbl(i).invoice_currency_code
                                                           ,p_exchange_rate          => v_trxs_tbl(i).exchange_rate)
          loop
            /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
            v_send_line := '<DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<NombreDA>'||'gastos_terceros'||'</NombreDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<ValorDA>'||r_trxs_lines_terceros.tercero_amount||'</ValorDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
            /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
            v_send_line := '<DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<NombreDA>'||'nom_terceros'||'</NombreDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<ValorDA>'||r_trxs_lines_terceros.tercero_description||'</ValorDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
          end loop;
          /*---- Informacion Adicional*/
          for r_trx_lines_inf_adic in c_trx_lines_inf_adic(p_customer_trx_id       => v_trxs_tbl(i).customer_trx_id
                                                          ,p_collection_type       => v_trxs_tbl(i).collection_type
                                                          ,p_hotel_stmt_trx_number => v_trxs_tbl(i).hotel_stmt_trx_number)
          loop
            v_send_line := '<DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<NombreDA>'||'Observacion'||'</NombreDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<ValorDA>'||r_trx_lines_inf_adic.info_adic||'</ValorDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end loop;
          /*---- Leyendas para Transacciones Manuales*/
          /*-- Verifica si el origen es manual y es cuenta corriente*/
          /*-- Imprime domicilio*/
          if (    v_trxs_tbl(i).batch_source_type = 'INV'
              and v_trxs_tbl(i).generic_customer  = 'N'
              and v_trxs_tbl(i).print_address_flag = 'Y') then
            v_send_line := '<DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<NombreDA>'||'Observacion'||'</NombreDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '<ValorDA>'||v_trxs_tbl(i).customer_address||'</ValorDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
            v_send_line := '</DatosAdjuntos>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          /*-- Leyenda Adicional*/
          /*-- Imprime Extracto/Reserva*/
          v_send_line := '<DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<NombreDA>'||'Observacion'||'</NombreDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          if (nvl(v_trxs_tbl(i).collection_type ,'XX') = 'PD') then
            v_send_line := '<ValorDA>'||v_trxs_tbl(i).hotel_stmt_trx_number||'</ValorDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          else
            v_send_line := '<ValorDA>'||v_trxs_tbl(i).purchase_order||'</ValorDA>'||g_eol;
            dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          end if;
          v_send_line := '</DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-- Leyenda Adicional*/
          /*-- Imprime Comentarios*/
          v_send_line := '<DatosAdjuntos_CMNTS>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<NombreDA>'||'Observacion'||'</NombreDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<ValorDA>'||v_trxs_tbl(i).comments||'</ValorDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</DatosAdjuntos_CMNTS>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*---- Agencia*/
          /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
          v_send_line := '<DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<NombreDA>'||'Agencia_SII'||'</NombreDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<ValorDA>'||'SUCURSAL SII'||'</ValorDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
          /*---- Numero de Resolucion*/
          /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
          v_send_line := '<DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<NombreDA>'||'NumRes_SII'||'</NombreDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<ValorDA>'||'118'||'</ValorDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
          /*---- Fecha de Resolucion*/
          /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
          v_send_line := '<DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<NombreDA>'||'FechaRes_SII'||'</NombreDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '<ValorDA>'||'30-09-2008'||'</ValorDA>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</DatosAdjuntos>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
          /*---- Condicion de Pago*/
          /*-------------------------- Inicio de Seccion Datos Adjuntos -------------------------------*/
--          v_send_line := '<DatosAdjuntos>'||g_eol;
--          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
--          v_send_line := '<NombreDA>'||'FORMAPAGO'||'</NombreDA>'||g_eol;
--          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
--          v_send_line := '<ValorDA>'||v_trxs_tbl(i).receipt_method_name||'</ValorDA>'||g_eol;
--          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
--          v_send_line := '</DatosAdjuntos>'||g_eol;
--          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          /*-------------------------- Fin de Seccion Datos Adjuntos ----------------------------------*/
          /*-------------------------- Fin de Seccion Boleta/DTE --------------------------------------*/
          if (v_trxs_tbl(i).electr_doc_type = '39') then
            v_send_line := '</Boleta>'||g_eol;
          elsif (v_trxs_tbl(i).electr_doc_type in ('110' ,'112')) then /*-- Fc Exportacion*/
            v_send_line := '</Exportaciones>'||g_eol;
          else
            v_send_line := '</Documento>'||g_eol;
          end if;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
          v_send_line := '</DTE>'||g_eol;
          dbms_lob.writeappend(v_send_file ,length(v_send_line) ,v_send_line);
        exception
          when others then
            v_mesg_error := 'Error cargando el contenido del archivo en la tabla de Envios de Transacciones ' || '(xx_ar_raxinv_pk). Texto: ' || v_send_line || '. ' || sqlerrm;
        end;
        if (v_mesg_error is null and v_trxs_tbl(i).status != 'ERROR') then
          debug(g_indent || v_calling_sequence || ' Copiando lob' ,'1' );
          dbms_lob.createtemporary(v_trxs_tbl(i).send_file ,false);
          dbms_lob.copy(v_trxs_tbl(i).send_file ,v_send_file ,dbms_lob.getlength(v_send_file));
          dbms_lob.freetemporary(v_send_file);
          debug(g_indent || v_calling_sequence || ' Copiado de lob finalizado' ,'1' );
        end if;
      end loop; /*--  Loop Principal*/
    end if; /*--  Fin Completa detalles a imprimir*/
    /*-- Genera los archivos*/
    if (v_mesg_error is null) then
      debug(g_indent || v_calling_sequence || ' Generando archivos' ,'1' );
      begin
--        /*Comento porque null es para sacarlo a un archivo*/
--        if not print_text(p_print_output => null ,p_mesg_error => v_mesg_error ) then
--          v_mesg_error := 'Error generando archivos: '||v_mesg_error;
--        end if;
        /*Si se le pasa Y lo saca a la salida del concurrente*/
        if not print_text(p_print_output => 'Y' ,p_mesg_error => v_mesg_error ) then
          v_mesg_error := 'Error generando archivos: '||v_mesg_error;
        end if;
      exception
      when others then
        v_mesg_error := v_calling_sequence || '. Error llamando a la funcion ' || 'PRINT_TEXT. ' || sqlerrm;
      end;
    end if; /*-- Genera los archivos*/
--    /*-- Inserta registros en tabla de intercambio*/
--    if (v_mesg_error is null) then
--      for i in 1..v_trxs_tbl.count
--      loop
--        if v_trxs_tbl(i).status = 'ERROR' then
--          v_error_qty          := v_error_qty + 1;
--        else
--          v_success_qty := v_success_qty + 1;
--        end if;
--        begin
--          /*-- Se obtiene extracto del comprobante relacionado cuando corresponde*/
--          v_hotel_stmt_trx_number := xx_ar_utilities_pk.get_hotel_stmt_trx_number(v_trxs_tbl(i).customer_trx_id);
--          /*-- Se obtiene el periodo del extracto*/
--          xx_ar_utilities_pk.get_hotel_stmt_info(p_hotel_stmt_trx_number => v_hotel_stmt_trx_number ,x_period_name => v_month_billed);
--          select
--            case
--              when nvl(v_trxs_tbl(i).collection_type ,'XX') = 'PD'
--              then null
--              else decode(rctl.interface_line_context ,'ORDER ENTRY' ,oos.name ,'XX_MANUAL' )
--            end
--          ,ooh.orig_sys_document_ref
--          ,xahsh.stmt_source
--          into v_order_source
--          ,v_orig_sys_document_ref
--          ,v_stmt_source
--          from oe_order_sources oos
--          ,oe_order_headers ooh
--          ,oe_order_lines ool
--          ,ra_customer_trx rct
--          ,ra_customer_trx_lines rctl
--          ,xx_ap_hotel_statements_hdr xahsh
--          where 1                                                                                     = 1
--          and v_trxs_tbl(i).customer_trx_id                                                           = rct.customer_trx_id
--          and rct.customer_trx_id                                                                     = rctl.customer_trx_id
--          and rctl.line_type                                                                          = 'LINE'
--          and rctl.interface_line_attribute6                                                          = ool.line_id(+)
--          and ool.header_id                                                                           = ooh.header_id(+)
--          and xx_ar_utilities_pk.get_hotel_stmt_trx_number(rct.customer_trx_id)                       = xahsh.hotel_stmt_trx_number(+)
--          and decode(rctl.interface_line_context ,'ORDER ENTRY' ,rctl.interface_line_attribute1 ,-1 ) = decode(rctl.interface_line_context ,'ORDER ENTRY' ,ooh.order_number ,-1 )
--          and ooh.order_source_id                                                                     = oos.order_source_id(+)
--          and rownum                                                                                  = 1;
--        exception
--        when others then
--          v_order_source          := null;
--          v_orig_sys_document_ref := null;
--          v_stmt_source           := null;
--        end;
--        /*----------------------------*/
--        /*-- Calcula datos adicionales*/
--        /*----------------------------*/
--        begin
--          insert
--          into xx_ar_reg_invoice_request
--            (
--              customer_trx_id
--            ,trx_number_ori
--            ,reference
--            ,receive_date
--            ,trx_number_new
--            ,link
--            ,cae
--            ,fecha_cae
--            ,file_name
--            ,status
--            ,error_code
--            ,error_messages
--            ,created_by
--            ,creation_date
--            ,last_updated_by
--            ,last_update_date
--            ,last_update_login
--            ,purchase_order
--            ,request_number
--            ,order_source
--            ,orig_sys_document_ref
--            ,collection_type
--            ,document_type
--            ,email
--            ,source_system_number
--            ,legal_entity
--            ,legal_entity_code
--            ,request_id
--            ,stmt_source
--            ,hotel_stmt_trx_number
--            ,attribute_category
--            ,attribute1
--            ,attribute2
--            ,attribute3
--            ,attribute4
--            ,attribute5
--            ,attribute6
--            ,attribute7
--            ,attribute8
--            ,attribute9
--            ,attribute10
--            ,net_amount
--            ,net_amount_pcc
--            ,tax_amount
--            ,tax_amount_pcc
--            ,total_amount
--            ,total_amount_pcc
--            ,trx_date
--            ,collection_country
--            ,month_billed
--            ,invoice_currency_code
--            ,printing_currency_code
--            )
--            values
--            (
--              v_trxs_tbl(i).customer_trx_id /*-- CUSTOMER_TRX_ID*/
--            ,v_trxs_tbl(i).trx_number /*-- TRX_NUMBER_ORI*/
--            ,v_trxs_tbl(i).customer_name /*-- REFERENCE*/
--            ,null /*-- RECEIVE_DATE*/
--            ,null /*-- TRX_NUMBER_NEW*/
--            ,null /*-- LINK*/
--            ,null /*-- CAE*/
--            ,null /*-- FECHA_CAE*/
--            ,v_trxs_tbl(i).output_file /*-- FILE_NAME*/
--            ,decode(v_trxs_tbl(i).status , 'ERROR' ,'PROCESSING_ERROR_ORACLE' ,'NEW') /*-- STATUS*/
--            ,v_trxs_tbl(i).error_code /*-- ERROR_CODE*/
--            ,v_trxs_tbl(i).error_messages /*-- ERROR_MESSAGES*/
--            ,fnd_global.user_id /*-- CREATED_BY*/
--            ,sysdate /*-- CREATION_DATE*/
--            ,fnd_global.user_id /*-- LAST_UPDATED_BY*/
--            ,sysdate /*-- LAST_UPDATE_DATE*/
--            ,fnd_global.login_id /*-- LAST_UPDATE_LOGIN*/
--            ,v_trxs_tbl(i).purchase_order /*-- PURCHASE_ORDER*/
--            ,v_trxs_tbl(i).request_number /*-- REQUEST_NUMBER*/
--            ,v_order_source /*-- ORDER_SOURCE*/
--            ,v_orig_sys_document_ref /*-- ORIG_SYS_DOCUMENT_REF*/
--            ,v_trxs_tbl(i).collection_type /*-- COLLECTION_TYPE*/
--            ,v_trxs_tbl(i).document_type /*-- DOCUMENT_TYPE*/
--            ,v_trxs_tbl(i).customer_email /*-- EMAIL*/
--            ,v_trxs_tbl(i).source_system_number /*-- SOURCE_SYSTEM_NUMBER*/
--            ,v_trxs_tbl(i).legal_entity_name /*-- LEGAL_ENTITY*/
--            ,v_trxs_tbl(i).legal_entity_id /*-- LEGAL_ENTITY_CODE*/
--            ,fnd_global.conc_request_id /*-- REQUEST_ID*/
--            ,v_stmt_source /*-- STMT_SOURCE*/
--            ,v_hotel_stmt_trx_number /*-- HOTEL_STMT_TRX_NUMBER*/
--            ,p_territory_code /*-- ATTRIBUTE_CATEGORY*/
--            ,v_trxs_tbl(i).electr_doc_type /*-- ATTRIBUTE1*/
--            ,v_trxs_tbl(i).legal_entity_identifier /*-- ATTRIBUTE2*/
--            ,null /*-- ATTRIBUTE3*/
--            ,null /*-- ATTRIBUTE4*/
--            ,null /*-- ATTRIBUTE5*/
--            ,null /*-- ATTRIBUTE6*/
--            ,null /*-- ATTRIBUTE7*/
--            ,null /*-- ATTRIBUTE8*/
--            ,null /*-- ATTRIBUTE9*/
--            ,null /*-- ATTRIBUTE10*/
--            ,v_trxs_tbl(i).net_amount /*-- NET_AMOUNT*/
--            ,v_trxs_tbl(i).net_amount_pcc /*-- NET_AMOUNT_PCC*/
--            ,v_trxs_tbl(i).tax_amount /*-- TAX_AMOUNT*/
--            ,v_trxs_tbl(i).tax_amount_pcc /*-- TAX_AMOUNT_PCC*/
--            ,v_trxs_tbl(i).total_amount /*-- TOTAL_AMOUNT*/
--            ,v_trxs_tbl(i).total_amount_pcc /*-- TOTAL_AMOUNT_PCC*/
--            ,v_trxs_tbl(i).trx_date /*-- TRX_DATE*/
--            ,v_trxs_tbl(i).collection_country /*-- COLLECTION_COUNTRY*/
--            ,v_month_billed /*-- MONTH_BILLED*/
--            ,v_trxs_tbl(i).invoice_currency_code /*-- INVOICE_CURRENCY_CODE*/
--            ,v_trxs_tbl(i).printing_currency_code/*-- PRINTING_CURRENCY_CODE*/
--            );
--        exception
--        when dup_val_on_index then
--          update xx_ar_reg_invoice_request
--          set trx_number_ori                  = v_trxs_tbl(i).trx_number
--          ,reference                          = v_trxs_tbl(i).customer_name
--          ,receive_date                       = null
--          ,trx_number_new                     = null
--          ,link                               = null
--          ,cae                                = null
--          ,fecha_cae                          = null
--          ,file_name                          = v_trxs_tbl(i).output_file
--          ,status                             = decode(v_trxs_tbl(i).status , 'ERROR' ,'PROCESSING_ERROR_ORACLE' ,'NEW')
--          ,error_code                         = v_trxs_tbl(i).error_code
--          ,error_messages                     = v_trxs_tbl(i).error_messages
--          ,last_updated_by                    = fnd_global.user_id
--          ,last_update_date                   = sysdate
--          ,last_update_login                  = fnd_global.login_id
--          ,purchase_order                     = v_trxs_tbl(i).purchase_order
--          ,request_number                     = v_trxs_tbl(i).request_number
--          ,order_source                       = v_order_source
--          ,orig_sys_document_ref              = v_orig_sys_document_ref
--          ,collection_type                    = v_trxs_tbl(i).collection_type
--          ,document_type                      = v_trxs_tbl(i).document_type
--          ,email                              = v_trxs_tbl(i).customer_email
--          ,source_system_number               = v_trxs_tbl(i).source_system_number
--          ,legal_entity                       = v_trxs_tbl(i).legal_entity_name
--          ,legal_entity_code                  = v_trxs_tbl(i).legal_entity_id
--          ,request_id                         = fnd_global.conc_request_id
--          ,stmt_source                        = v_stmt_source
--          ,hotel_stmt_trx_number              = v_hotel_stmt_trx_number
--          ,attribute_category                 = p_territory_code
--          ,attribute1                         = v_trxs_tbl(i).electr_doc_type
--          ,attribute2                         = v_trxs_tbl(i).legal_entity_identifier
--          ,attribute3                         = null
--          ,attribute4                         = null
--          ,attribute5                         = null
--          ,attribute6                         = null
--          ,attribute7                         = null
--          ,attribute8                         = null
--          ,attribute9                         = null
--          ,attribute10                        = null
--          ,net_amount                         = v_trxs_tbl(i).net_amount
--          ,net_amount_pcc                     =v_trxs_tbl(i).net_amount_pcc
--          ,tax_amount                         = v_trxs_tbl(i).tax_amount
--          ,tax_amount_pcc                     = v_trxs_tbl(i).tax_amount_pcc
--          ,total_amount                       = v_trxs_tbl(i).total_amount
--          ,total_amount_pcc                   = v_trxs_tbl(i).total_amount_pcc
--          ,trx_date                           = v_trxs_tbl(i).trx_date
--          ,collection_country                 = v_trxs_tbl(i).collection_country
--          ,month_billed                       = v_month_billed
--          ,invoice_currency_code              = v_trxs_tbl(i).invoice_currency_code
--          ,printing_currency_code             = v_trxs_tbl(i).printing_currency_code
--          where v_trxs_tbl(i).customer_trx_id = customer_trx_id;
--        end;
--      end loop;
--    end if;
--    /*-- ---------------------------------------------------------------------------*/
--    /*-- Verifico si se produjo un error.*/
--    /*-- ---------------------------------------------------------------------------*/
--    if v_mesg_error is not null and v_mesg_error != 'NO_DATA_FOUND' then
--      debug(g_indent || v_calling_sequence || '. ' || v_mesg_error ,'1' );
--      fnd_file.put(fnd_file.log ,g_indent || v_calling_sequence || '. ' || v_mesg_error );
--      fnd_file.new_line(fnd_file.log ,1);
--      debug(g_indent || v_calling_sequence || '. Realizando rollback' ,'1' );
--      rollback;
--      retcode := '2';
--      errbuf  := substr(v_mesg_error ,1 ,2000);
--    else
--      if upper(nvl(p_draft_mode ,'N')) = 'N' then
--        debug(g_indent || v_calling_sequence || '. Realizando commit' ,'1' );
--        commit;
--      else
--        debug(g_indent || v_calling_sequence || '. Realizando rollback' ,'1' );
--        rollback;
--      end if;
--      retcode := '0';
--    end if;
    fnd_file.put(fnd_file.log ,'---------------------------------------------------------------------');
    fnd_file.new_line(fnd_file.log ,1);
    fnd_file.put(fnd_file.log ,' Registros procesados exitosamente: '||v_success_qty);
    fnd_file.new_line(fnd_file.log ,1);
    fnd_file.put(fnd_file.log ,' Registros procesados con error   : '||v_error_qty);
    fnd_file.new_line(fnd_file.log ,1);
    fnd_file.put(fnd_file.log ,'---------------------------------------------------------------------');
    fnd_file.new_line(fnd_file.log ,1);
    debug(g_indent || v_calling_sequence || '. Fin de proceso' ,'1' );
  exception
  when others then
    v_mesg_error := 'Error general generando factura electronica. ' || sqlerrm;
    debug(v_calling_sequence || '. ' || v_mesg_error ,'1' );
    fnd_file.put(fnd_file.log ,g_indent || v_calling_sequence || '. ' || v_mesg_error );
    fnd_file.new_line(fnd_file.log ,1);
    retcode := '2';
    errbuf  := substr(v_mesg_error ,1 ,2000);
  end main_cl_rn;
end xx_ar_raxinv_pk;
/
show errors
spool off
exit
