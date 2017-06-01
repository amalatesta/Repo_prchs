rem +=======================================================================+
rem |    copyright (c) 2017 despegar.com argentina, buenos aires            |
rem |                         all rights reserved.                          |
rem +=======================================================================+
rem | filename                                                              |
rem |    XX_AR_TRX_PE_SENDSB_PK.sql                                         |
rem |                                                                       |
rem | description                                                           |
rem |    crea el cuerpo del paquete xx_ar_trx_pe_sends_pk                   |
rem |    que contiene funciones y procedimientos para el proceso de         |
rem |    impresion de factura de peru.                                      |
rem |    basado en el paquete xx_ar_fe_pe_sends_pk.                         |
rem |                                                                       |
rem | language                                                              |
rem |    pl/sql                                                             |
rem |                                                                       |
rem | product                                                               |
rem |    Oracle Financials                                                  |
rem |                                                                       |
rem | history                                                               |
rem |    21-MAY-17  DSP-AMalatesta         Created                          |
rem |                                                                       |
rem | notes                                                                 |
rem |                                                                       |
rem +=======================================================================+

spool xx_ar_trx_pe_sendsb_pk.log

prompt =====================================================================
prompt Script XX_AR_TRX_PE_SENDSB_PK.sql
prompt =====================================================================

prompt Creando cuerpo del paquete xx_ar_trx_pe_sends_pk

create or replace package body xx_ar_trx_pe_sends_pk as
/* $Id: XX_AR_TRX_PE_SENDSB_PK.sql 1 2017-05-21 20:46:37 amalatesta@despegar.com $ */
-- Variables globales
g_eol                varchar2(2) := chr(10);
g_func_currency_code varchar2(3) := 'PEN';
g_num_format         varchar2(99):= '9999999999999999999999999999999999999999999999990.99';
g_vat_tax            varchar2(240) := 'PE IVA AR';
g_detraction_amount  number;
    cursor c_trxs (p_customer_id      in number,
                   p_cust_trx_type_id in number,
                   p_trx_number_from  in varchar2,
                   p_trx_number_to    in varchar2,
                   p_date_from        in date,
                   p_date_to          in date,
                   p_draft_mode       in varchar2,
                   p_process_errors   in varchar2) is
      select rct.customer_trx_id
           , 'XX_AR_TRX_PE_OUT_PRC_DIR'                                               tmp_output_directory
           , lpad(rct.customer_trx_id, 15, '0')||'.tmp'                              tmp_output_file
           , 'XX_AR_TRX_PE_OUT_PRC_DIR'                                               output_directory
           , lpad(rct.customer_trx_id, 15, '0')||'.txt'                              output_file
           , rct.trx_number                                                          trx_number
           , rct.trx_date                                                            trx_date
           , rct.org_id                                                              rct_org_id
           , xlol.country                                                            collection_country
           , rct.invoice_currency_code                                               invoice_currency_code
           , nvl(decode(xlol.country, 'AR', gsob.currency_code, rct.attribute15),
                                                 rct.invoice_currency_code)          printing_currency_code
           , hca.orig_system_reference                                               source_system_number
           , nvl(hca.attribute20, 'N')                                               generic_customer
           , hca.party_id                                                            party_id
           , hca.cust_account_id                                                     cust_account_id
           , substr(rct.attribute1, 1, 100)                                          customer_name
           , substr (rct.attribute2, 1, instr(rct.attribute2,'|',1,1)-1)             customer_doc_type
           , decode (rct.attribute2, null, null, null)                               customer_doc_type_code
           , substr (replace(rct.attribute2, '-', ''),
               instr(rct.attribute2,'|',1,1)+1)                                      customer_doc_number_full
           , substr (replace(rct.attribute2, '-', ''),
               instr(rct.attribute2,'|',1,1)+1,
               (length (replace(rct.attribute2, '-', '')) -
                 instr(rct.attribute2,'|',1,1)) -1)                                  customer_doc_number
           , substr (substr (rct.attribute2, instr(rct.attribute2,'|',1,1)+1), -1)   customer_doc_digit
           , rct.attribute12                                                         country_receptor_code
           , rct.reason_code                                                         reason_code
           -- Inicio de datos que se recalculan posteriormente. Se incluyen solo para la definicion del tipo de dato
           , decode (xarir.total_amount, null, null, null)                           net_amount
           , decode (xarir.total_amount, null, null, null)                           net_amount_pcc
           , decode (xarir.total_amount, null, null, null)                           tax_amount
           , decode (xarir.total_amount, null, null, null)                           tax_amount_pcc
           , decode (xarir.total_amount, null, null, null)                           total_amount
           , decode (xarir.total_amount, null, null, null)                           total_amount_pcc
           , decode (xarir.total_amount, null, null, null)                           net_amount_exento
           , decode (xarir.total_amount, null, null, null)                           net_amount_exento_pcc
           , decode (xarir.total_amount, null, null, null)                           net_amount_gravado
           , decode (xarir.total_amount, null, null, null)                           net_amount_gravado_pcc
           , decode (xarir.total_amount, null, null, null)                           tax_amount_iva
           , decode (xarir.total_amount, null, null, null)                           tax_amount_iva_pcc
           , decode (xarir.total_amount, null, null, null)                           vat_percentage
           , decode (geo.geography_name, null, null, null)                           district_receptor_name
           , decode (geo.geography_name, null, null, null)                           department_receptor_name
           , decode (geo.geography_name, null, null, null)                           province_receptor_name
           , decode (geo.geography_name, null, null, null)                           country_receptor_name
           , decode (rct.attribute11, null, null, null)                              customer_address
           , decode (rct.customer_trx_id, null, null, null)                          ref_customer_trx_id
           , decode (cfactte.attribute1, null, null, null)                           ref_electr_doc_type
           , decode (rct.trx_number, null, null, null)                               ref_trx_number
           , decode (rct.trx_date, null, to_date(null), to_date(null))               ref_trx_date
           , decode (rct.attribute9, null, null, null)                               ref_procesado_fc_electronica
           , decode (flv_status.meaning, null, null, null)                           printing_currency_code_fe_code
           , decode (rct.attribute11, null, null, null)                              original_taxpayer_id
           , decode (flv_status.description, null, null, null)                       response_code
           , decode (flv_status.meaning, null, null, null)                           reason_description
           , decode (rctt.attribute11, null, null, null)                             detraction_code
           --  Fin de datos que se recalculan posteriormente
           , rct.attribute11                                                         customer_base_address
           , rct.attribute3                                                          customer_email
           , rct.attribute4                                                          request_number
           , rct.attribute13                                                         purchase_order
           , rbs.batch_source_type                                                   batch_source_type
           , rct.purchase_order                                                      hotel_stmt_trx_number
           , rct.comments                                                            comments
           , fds.attribute1||'-'                                                     doc_sequence_value
           , nvl(rct.exchange_rate, 1)                                               exchange_rate
           , rct.bill_to_site_use_id                                                 bill_to_site_use_id
           , rctt.type                                                               document_type
           , rctt.name                                                               cust_trx_type_name
           , cfactte.attribute1                                                      electr_doc_type
           , rctt.attribute13                                                        electr_serv_type
           , rctt.attribute1                                                         cust_trx_concept
           , rctt.attribute2                                                         collection_type
           , nvl(rctt.attribute13, 'N')                                              print_address_flag
           , nvl(rctt.attribute15, 'N')                                              print_item_line_flag
           , rct.legal_entity_id                                                     legal_entity_id
           , xep.name                                                                legal_entity_name
           , xep.legal_entity_identifier                                             legal_entity_identifier
           , xep.attribute1                                                          geo_code
           , hl_org.address_line_1                                                   expedition_address
           , hl_org.town_or_city                                                     expedition_place
           , hl_org.region_2                                                         expedition_district
           , hl_org.country                                                          org_country
           , get_receipt_method(rct.receipt_method_id
                              , rctt.type
                              , rct.previous_customer_trx_id
                              , rctt.attribute2)                                     receipt_method_name
           , xarir.status                                                            status
           , xarir.error_code                                                        error_code
           , xarir.error_messages                                                    error_messages
           , nvl(flv_status.attribute1, 'N')                                         resend_status_flag
           , rct.status_trx                                                          status_trx
           , rct.attribute1                                                          cliente
           , rct.attribute2                                                          id_cliente
           , rct.attribute3                                                          email_cliente
           , empty_clob()                                                            send_file
        from ra_customer_trx                rct
           , ra_cust_trx_types              rctt
           , ra_batch_sources               rbs
           , xx_ar_reg_invoice_request      xarir
           , hz_cust_accounts               hca
           , xle_entity_profiles            xep
           , hr_organization_units          hou
           , hr_locations                   hl_org
           , fnd_lookup_values_vl           flv_status
           , hz_geographies                 geo
           , hr_operating_units             ou
           , xle_le_ou_ledger_v             xlol
           , gl_sets_of_books               gsob
           , fnd_document_sequences         fds
           , cll_f258_ar_cust_trx_types_ext cfactte
       where 1 = 1
         and rct.trx_date         between nvl(trunc(p_date_from), rct.trx_date)
                                      and nvl(trunc(p_date_to + 1) - 1/24/60/60, rct.trx_date)
         and rct.trx_number       between nvl(p_trx_number_from, rct.trx_number)
                                      and nvl(p_trx_number_to, rct.trx_number)
         and rct.cust_trx_type_id       = nvl(p_cust_trx_type_id, rct.cust_trx_type_id)
         and rct.bill_to_customer_id    = nvl(p_customer_id, rct.bill_to_customer_id)
         and rct.complete_flag          = 'Y'
         and nvl(rct.attribute9, 'N')   = 'N'
         and p_draft_mode               = 'N'
         and rct.batch_source_id        = rbs.batch_source_id
         and rct.doc_sequence_id        = fds.doc_sequence_id
         and ou.organization_id         = rct.org_id
         and ou.set_of_books_id         = gsob.set_of_books_id
         and rct.org_id                 = xlol.operating_unit_id
         and rct.customer_trx_id        = xarir.customer_trx_id (+)
         and ((p_process_errors = 'Y' and  nvl(xarir.status,'@')  in ('@', 'PROCESSING_ERROR_ORACLE', 'ERROR_OAS')) or
              (p_process_errors = 'N' and  xarir.status is null))
         and rct.cust_trx_type_id       = rctt.cust_trx_type_id
         and rctt.cust_trx_type_id      = cfactte.cust_trx_type_id (+)
         and rct.org_id                 = hou.organization_id
         and hou.location_id            = hl_org.location_id
         and rct.bill_to_customer_id    = hca.cust_account_id
         and rct.legal_entity_id        = xep.legal_entity_id
         and 'INVOICE_TRX_STATUS'       = flv_status.lookup_type (+)
         and rct.status_trx             = flv_status.lookup_code (+)
         and xep.geography_id           = geo.geography_id
         --que no es electronico
         and nvl(rbs.attribute3,'N')   = 'N'
         and nvl(rctt.attribute12,'N') = 'N'
         and nvl(rbs.attribute15,'N')  = 'Y'
         and nvl(rctt.attribute13,'N') = 'Y'
    union all
      select rct.customer_trx_id
           , 'XX_AR_TRX_PE_OUT_PRC_DIR'                                               tmp_output_directory
           , lpad(rct.customer_trx_id, 15, '0')||'.tmp'                              tmp_output_file
           , 'XX_AR_TRX_PE_OUT_PRC_DIR'                                               output_directory
           , lpad(rct.customer_trx_id, 15, '0')||'.txt'                              output_file
           , rct.trx_number                                                          trx_number
           , rct.trx_date                                                            trx_date
           , rct.org_id                                                              rct_org_id
           , xlol.country                                                            collection_country
           , rct.invoice_currency_code                                               invoice_currency_code
           , nvl(decode(xlol.country, 'AR', gsob.currency_code, rct.attribute15),
                                                 rct.invoice_currency_code)          printing_currency_code
           , hca.orig_system_reference                                               source_system_number
           , nvl(hca.attribute20, 'N')                                               generic_customer
           , hca.party_id                                                            party_id
           , hca.cust_account_id                                                     cust_account_id
           , substr(rct.attribute1, 1, 100)                                          customer_name
           , substr (rct.attribute2, 1, instr(rct.attribute2,'|',1,1)-1)             customer_doc_type
           , decode (rct.attribute2, null, null, null)                               customer_doc_type_code
           , substr (replace(rct.attribute2, '-', ''),
               instr(rct.attribute2,'|',1,1)+1)                                      customer_doc_number_full
           , substr (replace(rct.attribute2, '-', ''),
               instr(rct.attribute2,'|',1,1)+1,
               (length (replace(rct.attribute2, '-', '')) -
                 instr(rct.attribute2,'|',1,1)) -1)                                  customer_doc_number
           , substr (substr (rct.attribute2, instr(rct.attribute2,'|',1,1)+1), -1)   customer_doc_digit
           , rct.attribute12                                                         country_receptor_code
           , rct.reason_code                                                         reason_code
           -- Inicio de datos que se recalculan posteriormente. Se incluyen solo para la definicion del tipo de dato
           , decode (xarir.total_amount, null, null, null)                           net_amount
           , decode (xarir.total_amount, null, null, null)                           net_amount_pcc
           , decode (xarir.total_amount, null, null, null)                           tax_amount
           , decode (xarir.total_amount, null, null, null)                           tax_amount_pcc
           , decode (xarir.total_amount, null, null, null)                           total_amount
           , decode (xarir.total_amount, null, null, null)                           total_amount_pcc
           , decode (xarir.total_amount, null, null, null)                           net_amount_exento
           , decode (xarir.total_amount, null, null, null)                           net_amount_exento_pcc
           , decode (xarir.total_amount, null, null, null)                           net_amount_gravado
           , decode (xarir.total_amount, null, null, null)                           net_amount_gravado_pcc
           , decode (xarir.total_amount, null, null, null)                           tax_amount_iva
           , decode (xarir.total_amount, null, null, null)                           tax_amount_iva_pcc
           , decode (xarir.total_amount, null, null, null)                           vat_percentage
           , decode (geo.geography_name, null, null, null)                           district_receptor_name
           , decode (geo.geography_name, null, null, null)                           department_receptor_name
           , decode (geo.geography_name, null, null, null)                           province_receptor_name
           , decode (geo.geography_name, null, null, null)                           country_receptor_name
           , decode (rct.attribute11, null, null, null)                              customer_address
           , decode (rct.customer_trx_id, null, null, null)                          ref_customer_trx_id
           , decode (cfactte.attribute1, null, null, null)                           ref_electr_doc_type
           , decode (rct.trx_number, null, null, null)                               ref_trx_number
           , decode (rct.trx_date, null, to_date(null), to_date(null))               ref_trx_date
           , decode (rct.attribute9, null, null, null)                               ref_procesado_fc_electronica
           , decode (flv_status.meaning, null, null, null)                           printing_currency_code_fe_code
           , decode (rct.attribute11, null, null, null)                              original_taxpayer_id
           , decode (flv_status.description, null, null, null)                       response_code
           , decode (flv_status.meaning, null, null, null)                           reason_description
           , decode (rctt.attribute11, null, null, null)                             detraction_code
           --  Fin de datos que se recalculan posteriormente
           , rct.attribute11                                                         customer_base_address
           , rct.attribute3                                                          customer_email
           , rct.attribute4                                                          request_number
           , rct.attribute13                                                         purchase_order
           , rbs.batch_source_type                                                   batch_source_type
           , rct.purchase_order                                                      hotel_stmt_trx_number
           , rct.comments                                                            comments
           , fds.attribute1||'-'                                                     doc_sequence_value
           , nvl(rct.exchange_rate, 1)                                               exchange_rate
           , rct.bill_to_site_use_id                                                 bill_to_site_use_id
           , rctt.type                                                               document_type
           , rctt.name                                                               cust_trx_type_name
           , cfactte.attribute1                                                      electr_doc_type
           , rctt.attribute13                                                        electr_serv_type
           , rctt.attribute1                                                         cust_trx_concept
           , rctt.attribute2                                                         collection_type
           , nvl(rctt.attribute13, 'N')                                              print_address_flag
           , nvl(rctt.attribute15, 'N')                                              print_item_line_flag
           , rct.legal_entity_id                                                     legal_entity_id
           , xep.name                                                                legal_entity_name
           , xep.legal_entity_identifier                                             legal_entity_identifier
           , xep.attribute1                                                          geo_code
           , hl_org.address_line_1                                                   expedition_address
           , hl_org.town_or_city                                                     expedition_place
           , hl_org.region_2                                                         expedition_district
           , hl_org.country                                                          org_country
           , get_receipt_method(rct.receipt_method_id
                              , rctt.type
                              , rct.previous_customer_trx_id
                              , rctt.attribute2)                                     receipt_method_name
           , xarir.status                                                            status
           , xarir.error_code                                                        error_code
           , xarir.error_messages                                                    error_messages
           , nvl(flv_status.attribute1, 'N')                                         resend_status_flag
           , rct.status_trx                                                          status_trx
           , rct.attribute1                                                          cliente
           , rct.attribute2                                                          id_cliente
           , rct.attribute3                                                          email_cliente
           , empty_clob()                                                            send_file
        from ra_customer_trx                rct
           , ra_cust_trx_types              rctt
           , ra_batch_sources               rbs
           , xx_ar_reg_invoice_request      xarir
           , hz_cust_accounts               hca
           , xle_entity_profiles            xep
           , hr_organization_units          hou
           , hr_locations                   hl_org
           , fnd_lookup_values_vl           flv_status
           , hz_geographies                 geo
           , hr_operating_units             ou
           , xle_le_ou_ledger_v             xlol
           , gl_sets_of_books               gsob
           , fnd_document_sequences         fds
           , cll_f258_ar_cust_trx_types_ext cfactte
       where 1 = 1
         and rct.trx_date         between nvl(trunc(p_date_from), rct.trx_date)
                                      and nvl(trunc(p_date_to + 1) - 1/24/60/60, rct.trx_date)
         and rct.trx_number       between p_trx_number_from and p_trx_number_to
         and rct.cust_trx_type_id       = nvl(p_cust_trx_type_id, rct.cust_trx_type_id)
         and rct.bill_to_customer_id    = nvl(p_customer_id, rct.bill_to_customer_id)
         and rct.complete_flag          = 'Y'
         and p_draft_mode               = 'Y'
         and rct.batch_source_id        = rbs.batch_source_id
         and rct.doc_sequence_id        = fds.doc_sequence_id
         and ou.organization_id         = rct.org_id
         and ou.set_of_books_id         = gsob.set_of_books_id
         and rct.org_id                 = xlol.operating_unit_id
         and rct.customer_trx_id        = xarir.customer_trx_id (+)
         and rct.cust_trx_type_id       = rctt.cust_trx_type_id
         and rctt.cust_trx_type_id      = cfactte.cust_trx_type_id (+)
         and rct.org_id                 = hou.organization_id
         and hou.location_id            = hl_org.location_id
         and rct.bill_to_customer_id    = hca.cust_account_id
         and rct.legal_entity_id        = xep.legal_entity_id
         and 'INVOICE_TRX_STATUS'       = flv_status.lookup_type (+)
         and rct.status_trx             = flv_status.lookup_code (+)
         and xep.geography_id           = geo.geography_id
         --que no es electronico
         and nvl(rbs.attribute3,'N')   = 'N'
         and nvl(rctt.attribute12,'N') = 'N'
         and nvl(rbs.attribute15,'N')  = 'Y'
         and nvl(rctt.attribute13,'N') = 'Y';
    cursor c_trx_lines  (p_customer_trx_id        in number,
                         p_vat_tax                in varchar2,
                         p_printing_currency_code in varchar2,
                         p_invoice_currency_code  in varchar2,
                         p_exchange_rate          in number,
                         p_cust_trx_concept       in varchar2,
                         p_print_item_line_flag   in varchar2) is
      select abs(nvl(rctll.quantity_invoiced, rctll.quantity_credited))                                       quantity
           ,get_inventory_item_desc(nvl(rctll.warehouse_id, osp.master_organization_id),
                                        rctll.inventory_item_id, p_cust_trx_concept, xaea.attribute50,
                                        xaea.attribute46,
                                        p_print_item_line_flag,
                                        rctll.description)                                                    item_description
           ,max(rctll.inventory_item_id)                                                                      inventory_item_id
           ,max(nvl(rctll.warehouse_id, osp.master_organization_id))                                          organization_id
           ,sum(nvl(taxes.tax_amt, 0) + nvl (rctlgd.amount, 0))                                               total_amount         -- Monto Total
           ,sum(decode (p_printing_currency_code, p_invoice_currency_code,
              (nvl(taxes.tax_amt, 0) + nvl (rctlgd.amount, 0)),
              (round (nvl(taxes.tax_amt, 0) * nvl(p_exchange_rate, 1), 2) + nvl (rctlgd.acctd_amount, 0))))   total_amount_pcc     -- Monto Total en PCC
           ,sum( nvl (rctlgd.amount, 0))                                                                      net_amount           -- Monto Neto (Sin Impuestos)
           ,sum(decode (p_printing_currency_code, p_invoice_currency_code,
                  nvl (rctlgd.amount, 0), nvl (rctlgd.acctd_amount, 0) ))                                     net_amount_pcc       -- Monto Neto (Sin Impuestos) en PCC
           ,sum(nvl(taxes.tax_amt, 0))                                                                        tax_amount           -- Monto Impuestos
           ,sum(decode (p_printing_currency_code, p_invoice_currency_code,
                  nvl(taxes.tax_amt, 0), round (nvl(taxes.tax_amt, 0) * nvl(p_exchange_rate, 1), 2)))         tax_amount_pcc       -- Monto Impuestos en PCC
           ,sum(nvl(taxes.tax_amt_iva, 0))                                                                    tax_amount_iva       -- Monto Impuestos Solo IVA
           ,sum(decode (p_printing_currency_code, p_invoice_currency_code,
                  nvl(taxes.tax_amt_iva, 0), round (nvl(taxes.tax_amt_iva, 0) * nvl(p_exchange_rate, 1), 2))) tax_amount_iva_pcc   -- Monto Impuestos Solo IVA en PCC
           ,sum(decode (nvl(taxes.tax_amt_iva, 0), 0, 0, nvl(rctlgd.amount, 0)))                              net_amount_gravado   -- Monto Neto Gravado
           ,sum(decode (nvl(taxes.tax_amt_iva, 0), 0, 0,
                        decode (p_printing_currency_code, p_invoice_currency_code,
                                nvl(rctlgd.amount, 0), nvl(rctlgd.acctd_amount, 0))))                         net_amount_gravado_pcc  -- Monto Neto Gravado en PCC
           ,sum(decode (nvl(taxes.tax_amt_iva, 0), 0, nvl(rctlgd.amount, 0), 0))                              net_amount_exento    -- Monto Neto Exento
           ,sum(decode (nvl(taxes.tax_amt_iva, 0), 0,
                        decode (p_printing_currency_code, p_invoice_currency_code,
                                nvl(rctlgd.amount, 0), nvl(rctlgd.acctd_amount, 0)), 0))                      net_amount_exento_pcc  -- Monto Neto Exento en PCC
          ,rctll.attribute2 pnr_number
          ,rctll.attribute3 nro_ticket
          ,rctll.attribute4 pasajero
          ,rctll.attribute5 id_pasajero
          ,rctll.attribute12 tipo_pasajero
       from ra_customer_trx_lines      rctll
           ,oe_order_lines             ool
           ,ra_cust_trx_line_gl_dist   rctlgd
           ,oe_system_parameters       osp
           ,xx_all_extra_attributes    xaea
           , (select sum(nvl(zx_line.tax_amt, 0)) tax_amt
                   , sum(decode (zx_rate.tax, p_vat_tax, nvl(zx_line.tax_amt, 0), 0)) tax_amt_iva
                   , rctlt.customer_trx_id
                   , rctlt.link_to_cust_trx_line_id
                from ra_customer_trx_lines  rctlt
                   , zx_lines               zx_line
                   , zx_taxes_b             zx_tax
                   , zx_rates_vl            zx_rate
               where rctlt.line_type(+)             = 'TAX'
                 and zx_tax.tax_id(+)               = zx_line.tax_id
                 and zx_rate.tax_rate_id(+)         = zx_line.tax_rate_id
                 and zx_line.tax_line_id(+)         = rctlt.tax_line_id
                 and zx_line.entity_code            = 'TRANSACTIONS'
                 and zx_line.application_id         = 222
              group by rctlt.customer_trx_id, rctlt.link_to_cust_trx_line_id) taxes
       where rctll.customer_trx_id           = p_customer_trx_id
       and rctll.line_type                 = 'LINE'
       and rctll.interface_line_attribute6 = ool.line_id(+)
       and xaea.source_table(+)            = 'OE_ORDER_LINES'
       and to_char(ool.line_id)           = xaea.source_id_char1(+)
       and rctll.customer_trx_id          = rctlgd.customer_trx_id
       and rctll.customer_trx_line_id     = rctlgd.customer_trx_line_id
       and rctll.customer_trx_id          = taxes.customer_trx_id(+)
       and rctll.customer_trx_line_id     = taxes.link_to_cust_trx_line_id(+)
       and nvl(rctll.quantity_invoiced, rctll.quantity_credited) != 0
       group by abs(nvl(rctll.quantity_invoiced, rctll.quantity_credited)),
                get_inventory_item_desc(nvl(rctll.warehouse_id, osp.master_organization_id),
                                        rctll.inventory_item_id, p_cust_trx_concept, xaea.attribute50,
                                        xaea.attribute46, p_print_item_line_flag, rctll.description)
                  ,rctll.attribute2
                  ,rctll.attribute3
                  ,rctll.attribute4
                  ,rctll.attribute5
                  ,rctll.attribute12;
    cursor c_trx_lines_terceros (p_customer_trx_id        in number,
                                 p_printing_currency_code in varchar2,
                                 p_invoice_currency_code  in varchar2,
                                 p_exchange_rate          in number) is
      select get_desc_tercero (osp.master_organization_id, rctll.inventory_item_id,
                               xaea.attribute50,
                               xaea.attribute46,
                               rctll.org_id, rctll.attribute6)                                                                      tercero_description
            ,sum (decode (p_printing_currency_code, p_invoice_currency_code,
                  nvl(fnd_number.canonical_to_number(replace(xaea.attribute45, ',', '.')), 0),
                  round (nvl(fnd_number.canonical_to_number(replace(xaea.attribute45, ',', '.')), 0) * nvl(p_exchange_rate, 1), 2))) tercero_amount
       from ra_customer_trx_lines     rctll
           ,oe_system_parameters      osp
           ,oe_order_lines            ool
           ,xx_all_extra_attributes   xaea
       where rctll.customer_trx_id         = p_customer_trx_id
       and rctll.line_type                 = 'LINE'
       and rctll.interface_line_attribute6 = ool.line_id(+)
       and xaea.source_table(+)            = 'OE_ORDER_LINES'
       and to_char(ool.line_id)            = xaea.source_id_char1(+)
       and xaea.attribute50 is not null
       and nvl(rctll.quantity_invoiced, rctll.quantity_credited) != 0
       group by get_desc_tercero (osp.master_organization_id, rctll.inventory_item_id,
                                  xaea.attribute50,
                                  xaea.attribute46,
                                  rctll.org_id, rctll.attribute6);
    cursor c_trx_lines_inf_adic (p_customer_trx_id       in number
                                ,p_collection_type       in varchar2
                                ,p_hotel_stmt_trx_number in varchar2
                                ,p_country_receptor_code in varchar2
                                ,p_original_taxpayer_id  in varchar2) is
       select distinct decode (p_hotel_stmt_trx_number, null, null, 'Extracto: '||p_hotel_stmt_trx_number) ||
                       decode (p_original_taxpayer_id, null, null,
                               decode (p_country_receptor_code, 'PE', null, ' Identificador de Contribuyente: '||p_original_taxpayer_id)) info_adic
       from  dual
       where p_collection_type = 'PD'
       and   (p_hotel_stmt_trx_number is not null or p_original_taxpayer_id is not null)
       union all -- Transacciones con Prepago
       select distinct 'Reserva '||rctl.interface_line_attribute15||
                       decode (rctl.attribute_category, '0008','',' - '||flv2.meaning) ||
                       decode (rctl.attribute_category, '0008','', ' - '||nvl (rctd.xx_ar_passenger_name, nvl (rct_dfv.xx_ar_customer, ac.customer_name)))||
                       decode (rctl.attribute_category, '0008', '',
                               ' - '||substr (rctd.xx_ar_provider,instr (rctd.xx_ar_provider, '_') + 1 , length(rctd.xx_ar_provider)))
                                      info_adic
       from   ra_customer_trx_lines rctl
             ,ra_customer_trx_lines_all_dfv rctd
             ,fnd_lookup_values_vl flv
             ,ra_customer_trx rct
             ,ra_customer_trx_all_dfv rct_dfv
             ,fnd_lookup_values_vl flv2
             ,ar_customers ac
       where  p_collection_type = 'PP'
       and    rct.customer_trx_id = p_customer_trx_id
       and    rctl.customer_trx_id = rct.customer_trx_id
       --AND    NVL(rctl.attribute_category, '@') != '0008' -- No se muestran datos de FEE
       and    rctl.line_type = 'LINE'
       and    rct.rowid = rct_dfv.row_id
       and    rct.bill_to_customer_id = ac.customer_id(+)
       and    rctl.rowid = rctd.row_id
       and    rctd.xx_ar_provider = flv.lookup_code(+)
       and    flv.lookup_type(+) = 'XX_AP_CARRIER_CODES'
       and    rctl.attribute_category = flv2.lookup_code(+)
       and    flv2.lookup_type(+) = 'XX_OE_TIPO_PRODUCTO';
    type trx_table_type is table of c_trxs%rowtype index by binary_integer;
    v_trxs_tbl                trx_table_type;
    v_trxs_aux_tbl            trx_table_type;
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
procedure indent(p_type in     varchar2
                )
is
  v_calling_sequence varchar2(2000);
  v_indent_length    number(15);
begin
  v_calling_sequence := 'xx_ar_trx_pe_sends_pk.indent';
  v_indent_length := 3;
  if p_type = '+' then
     g_indent := replace(rpad(' '
                             ,nvl(length(g_indent)
                                 ,0
                                 ) +
                              v_indent_length
                             )
                        ,' '
                        ,' '
                        );
  elsif p_type = '-' then
     g_indent := replace(rpad(' '
                             ,nvl(length(g_indent)
                                 ,0
                                 ) -
                              v_indent_length
                             )
                        ,' '
                        ,' '
                        );
  end if;
exception
  when others then
    raise_application_error(-20000
                           ,v_calling_sequence                   ||
                            '. Error general indentando linea. ' ||
                            sqlerrm
                           );
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
procedure display_message_split(p_output  in      varchar2
                               ,p_message in      varchar2
                               )
is
  -- ---------------------------------------------------------------------------
  -- Declaracion de Variables.
  -- ---------------------------------------------------------------------------
  v_calling_sequence varchar2(2000);
  v_cnt              number(15);
  v_message_length   number(15);
  v_message          varchar2(4000);
  v_mesg_error       varchar2(32767);
begin
  -- ---------------------------------------------------------------------------
  -- Inicializo variables Grales de Ejecucion.
  -- ---------------------------------------------------------------------------
  v_calling_sequence := 'xx_ar_trx_pe_sends_pk.display_message_split';
  -- ---------------------------------------------------------------------------
  -- Obtengo la longitud del mensaje.
  -- ---------------------------------------------------------------------------
  v_message_length := g_message_length;
  if p_output         = 'DBMS' and
     g_message_length > 255    then
     v_message_length := 255;
  end if;
  -- ---------------------------------------------------------------------------
  -- Despliego el mensaje.
  -- ---------------------------------------------------------------------------
  for v_cnt in 1..40000/v_message_length loop
      v_message := null;
      if v_cnt = 1 then
         if length(p_message) >= v_cnt * v_message_length then
            v_message := substr(p_message
                               ,1
                               ,v_cnt * v_message_length
                               );
         else
            if length(p_message) >= 1                        and
               length(p_message) <  v_cnt * v_message_length then
               v_message := substr(p_message
                                  ,1
                                  );
            end if;
         end if;
      else
         if length(p_message) >= v_cnt * v_message_length then
            v_message := substr(p_message
                               ,((v_cnt-1
                                 ) * v_message_length
                                ) + 1
                               ,v_message_length
                               );
         else
            if length(p_message) >= ((v_cnt-1) * v_message_length) and
               length(p_message) <    v_cnt    * v_message_length  then
               v_message := substr(p_message
                                  ,((v_cnt-1
                                    ) * v_message_length
                                   ) + 1
                                  );
            end if;
         end if;
      end if;
      v_message := ltrim(rtrim(v_message));
      if v_message is not null then
         if p_output = 'DBMS' then
            dbms_output.put_line(v_message);
         elsif p_output = 'CONC_LOG' then
            fnd_file.put(fnd_file.log
                        ,v_message
                        );
            fnd_file.new_line(fnd_file.log
                             ,1
                             );
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
procedure debug(p_message in      varchar2
               ,p_type    in      varchar2 default null
               )
is
  -- ---------------------------------------------------------------------------
  -- Declaracion de Variables.
  -- ---------------------------------------------------------------------------
  v_calling_sequence varchar2(2000);
  v_message          varchar2(32767);
begin
  -- ---------------------------------------------------------------------------
  -- Inicializo variables Grales de Ejecucion.
  -- ---------------------------------------------------------------------------
  v_calling_sequence := 'xx_ar_trx_pe_sends_pk.debug';
  -- ---------------------------------------------------------------------------
  -- Realizo el debug.
  -- ---------------------------------------------------------------------------
  if g_debug_flag = 'Y' then
     if p_type is null then
        v_message := substr(p_message
                           ,1
                           ,32767
                           );
     else
        v_message := substr(to_char(sysdate
                                   ,'DD-MM-YYYY HH24:MI:SS'
                                   )                        ||
                            ' - '                           ||
                            p_message
                           ,1
                           ,32767
                           );
     end if;
     display_message_split(p_output  => g_debug_mode
                          ,p_message => v_message
                          );
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
function print_text(p_print_output in      varchar2
                   ,p_mesg_error   out     varchar2
                   ) return boolean
is
  -- ---------------------------------------------------------------------------
  -- Declaracion de Variables.
  -- ---------------------------------------------------------------------------
  v_calling_sequence  varchar2(2000);
  v_file              utl_file.file_type;
  v_output_directory  varchar2(2000);
  v_output_file       varchar2(2000);
  v_text1             varchar2(2000);
  v_text2             varchar2(2000);
  v_text3             varchar2(2000);
  v_amount            number;
  -- ---------------------------------------------------------------------------
  -- Declaracion de Excepciones.
  -- ---------------------------------------------------------------------------
  e_invalid_directory exception;
  e_invalid_file_name exception;
  pragma exception_init(e_invalid_directory, -29280);
  pragma exception_init(e_invalid_file_name, -29288);
begin
  -- ---------------------------------------------------------------------------
  -- Inicializo variables Grales de Ejecucion.
  -- ---------------------------------------------------------------------------
  v_calling_sequence := 'xx_ar_trx_pe_sendsb_pk.print_text';

  debug(g_indent           ||
        v_calling_sequence
       ,'1'
       );
  -- ---------------------------------------------------------------------------
  -- Despliego Parametros.
  -- ---------------------------------------------------------------------------
   debug(g_indent                                             ||
         v_calling_sequence                                   ||
         '. Imprime interface en la salida del concurrente: ' ||
         p_print_output
        ,'1'
        );
  -- ---------------------------------------------------------------------------
  -- Recorro la salida de interface.
  -- ---------------------------------------------------------------------------
  debug(g_indent                               ||
        v_calling_sequence                     ||
        '. Recorriendo la salida de interface'
       ,'1'
       );
  indent('+');

  for i in 1 .. v_trxs_tbl.count loop

      v_text1 := null;
      v_text2 := null;
      v_text3 := null;

      -- -----------------------------------------------------------------------
      -- Verifico si estoy imprimiendo la interface en la salida del
      -- concurrente.
      -- -----------------------------------------------------------------------
      if p_print_output is null then
         -- --------------------------------------------------------------------
         -- Verifico si cambio el directorio o archivo de salida.
         -- --------------------------------------------------------------------
         if nvl(v_trxs_tbl(i).output_directory,'@') !=
            nvl(v_output_directory ,'@') or
            nvl(v_trxs_tbl(i).output_file ,'@') !=
            nvl(v_output_file      ,'@') then
            -- -----------------------------------------------------------------
            -- Verifico si el archivo de salida anterior esta abierto.
            -- -----------------------------------------------------------------
            if utl_file.is_open(v_file) then
               fnd_file.put(fnd_file.log
                           ,'Se genero el archivo de salida: ' ||
                            v_output_file                      ||
                            ' en el directorio: '              ||
                            v_output_directory
                           );
               fnd_file.new_line(fnd_file.log,1);
               debug(g_indent                         ||
                     v_calling_sequence               ||
                     '. Cerrando archivo de salida: ' ||
                     v_output_file                    ||
                     ' en el directorio: '            ||
                     v_output_directory
                    ,'1'
                    );
               begin
                 utl_file.fclose(v_file);
               exception
                 when others then
                   p_mesg_error := v_calling_sequence                     ||
                                   '. Error cerrando archivo de salida: ' ||
                                   v_output_file                          ||
                                   ' en el directorio: '                  ||
                                   v_output_directory                     ||
                                   '. '                                   ||
                                   sqlerrm;
                   exit;
               end;
            end if;
            -- -----------------------------------------------------------------
            -- Verifico si hay que generar un nuevo archivo de salida.
            -- -----------------------------------------------------------------
            if v_trxs_tbl(i).output_directory is not null and
               v_trxs_tbl(i).output_file is not null and
               v_trxs_tbl(i).status = 'NEW' then
               -- --------------------------------------------------------------
               -- Genero el nuevo archivo de salida.
               -- --------------------------------------------------------------
               debug(g_indent                          ||
                     v_calling_sequence                ||
                     '. Generando archivo de salida: ' ||
                     v_trxs_tbl(i).output_file     ||
                     ' en el directorio: '             ||
                     v_trxs_tbl(i).output_directory
                    ,'1'
                    );
               begin
                 v_file := utl_file.fopen(v_trxs_tbl(i).output_directory
                                         ,v_trxs_tbl(i).output_file
                                         ,'w'
                                         );
               exception
                 when e_invalid_directory then
                   p_mesg_error := 'Directorio de salida invalido: ' ||
                                   v_trxs_tbl(i).output_directory;
                   exit;
                 when e_invalid_file_name then
                   p_mesg_error := 'Archivo de salida invalido: ' ||
                                   v_trxs_tbl(i).output_file;
                   exit;
                 when others then
                   p_mesg_error := 'Error generando archivo de salida: ' ||
                                   v_trxs_tbl(i).output_file             ||
                                   ' en el directorio: '                 ||
                                   v_trxs_tbl(i).output_directory    ||
                                   '. '                                  ||
                                   sqlerrm;
                   exit;
               end;
            end if;
         end if;
         -- --------------------------------------------------------------------
         -- Verifico si hay que imprimir el texto en el archivo de salida.
         -- --------------------------------------------------------------------
         if v_trxs_tbl(i).output_directory is not null and
            v_trxs_tbl(i).output_file is not null and
            v_trxs_tbl(i).status = 'NEW' then
            -- -----------------------------------------------------------------
            -- Imprimo el texto en el archivo de salida.
            -- -----------------------------------------------------------------
            begin
            debug(g_indent                         ||
                     v_calling_sequence               ||
                     '. Leyendo lob'
                    ,'1'
                    );
              v_amount := 2000;
            if (dbms_lob.getlength(v_trxs_tbl(i).send_file) != 0) then
              dbms_lob.read(v_trxs_tbl(i).send_file, v_amount, 1, v_text1);
            end if;
            debug(g_indent                         ||
                     v_calling_sequence               ||
                     '. v_text1: ' || v_text1
                    ,'1'
                    );
              if (dbms_lob.getlength(v_trxs_tbl(i).send_file) > 2000) then
                  dbms_lob.read(v_trxs_tbl(i).send_file, v_amount, 2001, v_text2);
              end if;
              if (dbms_lob.getlength(v_trxs_tbl(i).send_file) > 4000) then
              dbms_lob.read(v_trxs_tbl(i).send_file, v_amount, 4001, v_text3);
              end if;
              utl_file.put_line(v_file
                               ,v_text1 ||
                                v_text2 ||
                                v_text3
                               );
              utl_file.fflush(v_file);
            exception
              when others then
                p_mesg_error := v_calling_sequence                 ||
                                '. Error imprimiendo texto '       ||
                                'en el archivo de salida: '        ||
                                v_trxs_tbl(i).output_file      ||
                                ' en el directorio: '              ||
                                v_trxs_tbl(i).output_directory ||
                                '. '                               ||
                                sqlerrm;
                exit;
            end;

         end if;

      else
         -- -----------------------------------------------------------------
         -- Imprimo el texto en la salida del concurrente.
         -- -----------------------------------------------------------------
         begin
             if (v_trxs_tbl(i).status = 'ERROR') then

                 fnd_file.put(fnd_file.output
                             ,'Numero Factura: '||v_trxs_tbl(i).trx_number || ' Error: '||v_trxs_tbl(i).error_messages
                             );
                 fnd_file.new_line(fnd_file.output
                                  ,1
                                  );
                 fnd_file.put(fnd_file.output
                             ,'----------------------------------------------------------'
                             );
                 fnd_file.new_line(fnd_file.output
                                  ,1
                                  );
             else
                 v_amount := 2000;
                 debug(g_indent                         ||
                       v_calling_sequence               ||
                       '. Leyendo Lob 2'
                      ,'1'
                      );
                 if (dbms_lob.getlength(v_trxs_tbl(i).send_file) > 0) then
                    dbms_lob.read(v_trxs_tbl(i).send_file, v_amount, 1, v_text1);
                    debug(g_indent                         ||
                          v_calling_sequence               ||
                         '. v_text1: ' || v_text1
                         ,'1'
                         );
                 end if;
                 if (dbms_lob.getlength(v_trxs_tbl(i).send_file) > 2000) then
                     dbms_lob.read(v_trxs_tbl(i).send_file, v_amount, 2001, v_text2);
                 end if;
                 if (dbms_lob.getlength(v_trxs_tbl(i).send_file) > 4000) then
                    dbms_lob.read(v_trxs_tbl(i).send_file, v_amount, 4001, v_text3);
                 end if;
                 --fnd_file.put(fnd_file.output
                 --            ,'Numero Factura: ' || v_trxs_tbl(i).trx_number
                 --            );
                 fnd_file.new_line(fnd_file.output
                                  ,1
                                  );
                 fnd_file.put(fnd_file.output
                            ,v_text1 ||
                             v_text2 ||
                             v_text3
                             );
                 fnd_file.new_line(fnd_file.output
                                  ,1
                                  );
                 --fnd_file.put(fnd_file.output
                 --            ,'----------------------------------------------------------'
                 --            );
                 fnd_file.new_line(fnd_file.output
                                  ,1
                                  );
             end if;

         exception
           when others then
             p_mesg_error := v_calling_sequence               ||
                             '. Error imprimiendo texto '     ||
                             'en la salida del concurrente. ' ||
                             sqlerrm;
             exit;
         end;
      end if;
      v_output_directory := v_trxs_tbl(i).output_directory;
      v_output_file      := v_trxs_tbl(i).output_file;
  end loop;
  indent('-');
  -- ---------------------------------------------------------------------------
  -- Verifico si se produjo algun error.
  -- ---------------------------------------------------------------------------
  if p_mesg_error is not null then
     return (false);
  end if;
  -- ---------------------------------------------------------------------------
  -- Verifico si tengo que cerrar el ultimo archivo de salida generado.
  -- ---------------------------------------------------------------------------
  if p_print_output is null then
     if v_output_directory is not null and
        v_output_file      is not null and
        utl_file.is_open(v_file)       then
        fnd_file.put(fnd_file.log
                    ,'Se genero el archivo de salida: ' ||
                     v_output_file                      ||
                     ' en el directorio: '              ||
                     v_output_directory
                    );
        fnd_file.new_line(fnd_file.log,1);
        debug(g_indent                         ||
              v_calling_sequence               ||
              '. Cerrando archivo de salida: ' ||
              v_output_file                    ||
              ' en el directorio: '            ||
              v_output_directory
             ,'1'
             );
        begin
          utl_file.fclose(v_file);
        exception
          when others then
            p_mesg_error := v_calling_sequence                     ||
                            '. Error cerrando archivo de salida: ' ||
                            v_output_file                          ||
                            ' en el directorio: '                  ||
                            v_output_directory                     ||
                            '. '                                   ||
                            sqlerrm;
            return (false);
        end;
     end if;
  else
     fnd_file.put(fnd_file.log
                 ,'Se genero el archivo de salida ' ||
                  'en la salida del concurrente'
                 );
     fnd_file.new_line(fnd_file.log,1);
     debug(g_indent                            ||
           v_calling_sequence                  ||
           '. Se genero el archivo de salida ' ||
           'en la salida del concurrente'
          ,'1'
          );
  end if;
  debug(g_indent                         ||
        v_calling_sequence               ||
        '. Salida de interface generada'
       ,'1'
       );
  return (true);
exception
  when others then
    p_mesg_error := v_calling_sequence                     ||
                    '. Error general '                     ||
                    'imprimiendo salida de la interface. ' ||
                    sqlerrm;
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
|    p_cust_trx_concept  IN VARCHAR2 Descripcion a Nivel Tipo de Trx       |
|    p_taxpayer_id       IN VARCHAR2 Id de Contribuyente                   |
|    p_taxpayer_doc_type IN VARCHAR2 Tipo de Doc de Id de Contribuyente    |
|    p_print_item_line   IN VARCHAR2 Se imprime item de la linea.          |
|    p_line_description  IN VARCHAR2 Descripcion cargada en la linea.      |
|                                                                          |
+=========================================================================*/
function get_inventory_item_desc(p_organization_id   in  number
                                ,p_inventory_item_id in  number
                                ,p_cust_trx_concept  in  varchar2
                                ,p_taxpayer_id       in  varchar2
                                ,p_taxpayer_doc_type in  varchar2
                                ,p_print_item_line   in  varchar2
                                ,p_line_description  in  varchar2
                                ) return varchar2
is
  v_item_desc varchar2(2000);
begin

  if (p_print_item_line = 'Y' and p_line_description is not null) then

      v_item_desc := p_line_description;

  else

      begin
          select mc.description
            into v_item_desc
            from mtl_item_categories     mic
               , mtl_category_sets       mcs
               , mtl_categories          mc
           where mic.inventory_item_id  = p_inventory_item_id
             and mic.organization_id    = p_organization_id
             and mcs.category_set_name  = 'XX_DESCR_ARTICULO'
             and mcs.category_set_id    = mic.category_set_id
             and mc.category_id         = mic.category_id;
       exception
         when no_data_found then
            if (v_item_desc is null) then
                v_item_desc := p_cust_trx_concept;
            end if;
       end;
   end if;

   -- Si no se obtuvo descripcion, no se concatena el Nro de Documento
   if (v_item_desc is not null) then
       if (p_taxpayer_doc_type is not null) then
           v_item_desc := v_item_desc ||'-'||p_taxpayer_doc_type;
       end if;
       if (p_taxpayer_id is not null) then
           v_item_desc := v_item_desc ||'-'||p_taxpayer_id;
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
function get_receipt_method(p_receipt_method_id        in  number
                           ,p_cust_trx_type            in  varchar2
                           ,p_previous_customer_trx_id in  number
                           ,p_transaction_type         in  varchar2
                           ) return varchar2
is
  l_receipt_method_id    number;
  l_receipt_method_name  varchar2(30);
  l_transaction_type     varchar2(30);
begin

  l_transaction_type := p_transaction_type;

  if (p_receipt_method_id is not null) then
      l_receipt_method_id := p_receipt_method_id;
  elsif (p_cust_trx_type in ('CM', 'DM') and p_previous_customer_trx_id is not null) then
      select rct.receipt_method_id
           , rctt.attribute2
        into l_receipt_method_id
           , l_transaction_type
       from ra_customer_trx rct
          , ra_cust_trx_types rctt
      where rct.customer_trx_id = p_previous_customer_trx_id
        and rct.cust_trx_type_id = rctt.cust_trx_type_id;
  end if;

  -- Busco la descripcion del metodo de cobro
  if (l_receipt_method_id is not null) then
      select arm.printed_name
      into   l_receipt_method_name
      from   ar_receipt_methods arm
      where  arm.receipt_method_id = l_receipt_method_id;
  else  -- Busco los Defaults
      select arm.printed_name
      into   l_receipt_method_name
      from   ar_receipt_methods arm
      where  arm.name = decode (l_transaction_type, 'PD', '01', '04');
  end if;

  return  l_receipt_method_name;

exception
when others then
     return null;
end get_receipt_method;

/*=========================================================================+
|                                                                          |
| Public Function                                                          |
|    Set_Detraction_Code                                                   |
|                                                                          |
| Description                                                              |
|    Funcion que indica si el comprobante tiene detraccion.                |
|                                                                          |
| Parameters                                                               |
|    p_organization_id   IN  NUMBER  Id Orgnization de Inventario.         |
|    p_inventory_item_id IN NUMBER   Id de Articulo de Inventario.         |
|                                                                          |
+=========================================================================*/
function set_detraction_code(p_document_type_code in  varchar2
                            ,p_payment_method     in  varchar2
                            ,p_document_amount    in  number
                            ) return varchar2
is
  v_detraction_code varchar2(2);
begin

  if (g_detraction_amount is null) then
    select fnd_number.canonical_to_number(asp.attribute2)
      into g_detraction_amount
      from ar_system_parameters asp;
  end if;

  if p_document_type_code = '01' and
     p_payment_method != 'PP' and
     p_document_amount > g_detraction_amount then
      v_detraction_code := 'SI';
  else
      v_detraction_code := 'NO';
  end if;

  return (v_detraction_code);

exception
  when others then
    return 'NO';
end set_detraction_code;

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
function item_imprime_prestador(p_organization_id   in  number
                      ,p_inventory_item_id in  number
                       ) return varchar2
is

  v_item_imprime_prestador varchar2(1) := 'N';

begin

  select 'Y'
  into v_item_imprime_prestador
  from mtl_category_sets       mcs
     , mtl_item_categories     mic
     , mtl_categories          mc
  where mcs.category_set_name  = 'XX_ITEM_DESPEGAR'
    and mcs.category_set_id    = mic.category_set_id
    and mc.category_id         = mic.category_id
    and mc.segment1 in ('Hotel')
    and mic.organization_id    = p_organization_id
    and mic.inventory_item_id  = p_inventory_item_id;

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
function get_supplier_name(p_taxpayer_id       in varchar2
                         , p_taxpayer_doc_type in varchar2
                         , p_org_id            in number)
return varchar2
is
  v_supp_name ap_suppliers.vendor_name%type;
begin

  if (p_taxpayer_id is null) then
     return null;
  end if;

  select vendor_name
  into   v_supp_name
  from   ap_suppliers          ap
       , ap_supplier_sites_all aps
  where  ap.attribute15 = p_taxpayer_id
    and  ap.vendor_id   = aps.vendor_id
    and  aps.org_id     = p_org_id
    and  p_taxpayer_doc_type is null
    and  rownum = 1
  union all
  select vendor_name
  from   ap_suppliers              ap
       , ap_supplier_sites_all     aps
       , hz_parties                hp
  where  ap.attribute15 = p_taxpayer_id
    and  ap.vendor_id   = aps.vendor_id
    and  aps.org_id     = p_org_id
    and  p_taxpayer_doc_type is not null
    and  hp.party_id    = ap.party_id
    and  hp.attribute3  = p_taxpayer_doc_type
    and  rownum = 1;


  return(v_supp_name);

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
function get_desc_tercero(p_organization_id    in number
                         ,p_inventory_item_id  in number
                         ,p_taxpayer_id        in varchar2
                         ,p_taxpayer_doc_type  in varchar2
                         ,p_org_id             in number
                         ,p_prestador          in varchar2)
return varchar2
is

begin

  -- Si imprime el prestador, devuelvo esa descripcion
  if (item_imprime_prestador (p_organization_id, p_inventory_item_id) = 'Y') then
     return p_prestador;
  end if;

  -- Devuelvo la razon social del proveedor
  return get_supplier_name(p_taxpayer_id, p_taxpayer_doc_type, p_org_id);

exception
  when others then
    return null;
end get_desc_tercero;


/*====================================================================================+
|                                                                                     |
| Public Procedure                                                                    |
|    Get_Datos_Trx                                                                    |
|                                                                                     |
| Description                                                                         |
|    Funcion que devuelve los datos de un comprobante                                 |
|                                                                                     |
| Parameters                                                                          |
|    p_customer_trx_id             IN NUMBER    Id del comprobante                    |
|    x_trx_number                 OUT VARCHAR2  Numero de Trx                         |
|    x_trx_date                   OUT DATE      Fecha de Trx                          |
|    x_electr_doc_type            OUT VARCHAR2  Tipo de Doc de Fc Electronica         |
|    x_electr_doc_type            OUT VARCHAR2  Tipo de Doc de Fc Electronica         |
|    x_procesado_fc_electronica   OUT VARCHAR2  Marca de procesado por Fc Electronica |
|                                                                                     |
+====================================================================================*/
procedure  get_datos_trx (p_customer_trx_id             in number
                         ,x_trx_number                 out varchar2
                         ,x_trx_date                   out date
                         ,x_electr_doc_type            out varchar2
                         ,x_procesado_fc_electronica   out varchar2)
is
begin

  -- Si el tipo de trx va a fc electronica => reviso el attribute9 de la factura.
  -- Si el tipo de trx no va a factura electronica (Carga inicial)=> se asume que fueron procesadas siempre.
  select fds.attribute1||'-'||lpad(rct.trx_number, 13-length(fds.attribute1||'-'), '0')
       , rct.trx_date
       , cfactte.attribute1
       , decode(rctt.attribute12, 'Y', nvl(rct.attribute9, 'N'), 'Y')
   into x_trx_number
      , x_trx_date
      , x_electr_doc_type
      , x_procesado_fc_electronica
  from   ra_customer_trx                rct
        ,ra_cust_trx_types              rctt
        ,fnd_document_sequences         fds
        ,cll_f258_ar_cust_trx_types_ext cfactte
  where  rct.customer_trx_id  = p_customer_trx_id
  and    rct.cust_trx_type_id = rctt.cust_trx_type_id
  and    rct.doc_sequence_id  = fds.doc_sequence_id
  and    rctt.cust_trx_type_id = cfactte.cust_trx_type_id;

  return;

exception
  when others then
    x_trx_number               := null;
    x_electr_doc_type          := null;
    x_procesado_fc_electronica := null;
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
procedure generate_files(errbuf            out varchar2
                        ,retcode           out number
                        ,p_draft_mode      in  varchar2
                        ,p_debug_flag      in  varchar2
                        ,p_batch_source    in  varchar2
                        ,p_cust_trx_type   in  number
                        ,p_trx_number_from in  varchar2
                        ,p_trx_number_to   in  varchar2
                        ,p_date_from       in  varchar2
                        ,p_date_to         in  varchar2
                        ,p_customer_id     in  number
                        ,p_territory_code  in  varchar2
                        ,p_process_errors  in  varchar2
                        )
is

    -- ---------------------------------------------------------------------------
    -- Definicion de Variables
    -- ---------------------------------------------------------------------------
    v_calling_sequence        varchar2(2000);
    v_request_id              number(15);
    v_mesg_error              varchar2(32767);
    v_mesg_api_error          varchar2(32767);
    v_return_status           varchar2(1);
    v_msg_count               number;
    v_msg_data                varchar2(2000);
    v_msg_index_out           number;
    v_order_source            oe_order_sources.name%type;
    v_orig_sys_document_ref   oe_order_headers.orig_sys_document_ref%type;
    v_stmt_source             xx_ap_hotel_statements_hdr.stmt_source%type;
    v_hotel_stmt_trx_number   xx_ap_hotel_statements_hdr.hotel_stmt_trx_number%type;
    v_month_billed            xx_ap_hotel_statements_hdr.period_name%type;
    -- Variables Auxiliares que se usan para el Recalculo el monto de Tax para que el % se calcule sobre el total
    -- (Los clientes quieren el calculo por total, Oracle lo hace por linea)
    v_net_amount_exento_pcc   number;
    v_net_amount_gravado_pcc  number;
    v_net_amount_pcc          number;
    v_tax_amount_iva_pcc      number;
    v_total_amount_pcc        number;
    v_amount_in_words         varchar2(4000);
    v_send_file               clob;
    v_send_line               varchar2(4000);
    v_nro_lin_det             number;
    v_success_qty             number := 0;
    v_error_qty               number := 0;
    v_is_prod_env             boolean := false;
    v_is_test_env             boolean := false;
    l_request_id              number;
    l_result                  boolean;
    v_directory_path          varchar2(100);
begin
    -- ---------------------------------------------------------------------------
    -- Inicializo variables Grales de Ejecucion.
    -- ---------------------------------------------------------------------------
    v_calling_sequence := 'xx_ar_trx_pe_send_pk.generate_files';
    v_request_id       := fnd_global.conc_request_id;
    -- ---------------------------------------------------------------------------
    -- Inicializo el debug.
    -- ---------------------------------------------------------------------------
    g_debug_flag := upper(nvl(p_debug_flag, 'N'));
    g_debug_mode := 'CONC_LOG';
    g_message_length := 4000;
    debug(g_indent           ||
          v_calling_sequence
         ,'1'
         );
    -- ---------------------------------------------------------------------------
    -- Despliego Parametros.
    -- ---------------------------------------------------------------------------
     debug(g_indent           ||
           v_calling_sequence ||
           '. Modo draft: '   ||
           p_draft_mode
          ,'1'
          );
     debug(g_indent                   ||
           v_calling_sequence         ||
           '. Origen: '               ||
           p_batch_source
          ,'1'
          );
     debug(g_indent                   ||
           v_calling_sequence         ||
           '. Tipo de Transaccion: '  ||
           p_cust_trx_type
          ,'1'
          );
     debug(g_indent                       ||
           v_calling_sequence             ||
           '. Numero Transaccion desde: ' ||
           p_trx_number_from
          ,'1'
          );
     debug(g_indent                       ||
           v_calling_sequence             ||
           '. Numero Transaccion hasta: ' ||
           p_trx_number_from
          ,'1'
          );
     debug(g_indent                 ||
           v_calling_sequence       ||
           '. Fecha desde: '        ||
           p_date_from
          ,'1'
          );
     debug(g_indent                 ||
           v_calling_sequence       ||
           '. Fecha hasta: '        ||
           p_date_to
          ,'1'
          );
     debug(g_indent                 ||
           v_calling_sequence       ||
           '. Cliente: '            ||
           p_customer_id
          ,'1'
          );
     debug(g_indent               ||
           v_calling_sequence     ||
           '. Pais: '             ||
           p_territory_code
          ,'1'
          );
     debug(g_indent            ||
           v_calling_sequence  ||
           '. Flag de debug: ' ||
           p_debug_flag
          ,'1'
          );
     debug(g_indent            ||
           v_calling_sequence  ||
           '. Obtiene facturas a procesar'
          ,'1'
          );

    -- Verifica si se ejecuta en entorno de produccion
    if (fnd_profile.value('TWO_TASK') = 'EBSP') then
        v_is_prod_env := true;
    else
        v_is_test_env := true;
    end if;

    -- Para modo draft se debe informar Transaccion Desde y Hasta
    if (nvl(p_draft_mode, 'N') = 'Y' and (p_trx_number_from is null or p_trx_number_to is null)) then

        v_mesg_error := 'Para Modo Draft informar Transaccions Desde y Hasta';
        debug(v_calling_sequence ||
              '. '               ||
              v_mesg_error
             ,'1'
             );
        fnd_file.put(fnd_file.log
                    ,g_indent           ||
                     v_calling_sequence ||
                     '. '               ||
                     v_mesg_error
                     );
        fnd_file.new_line(fnd_file.log, 1);
        retcode := '1';
        errbuf  := substr(v_mesg_error, 1, 2000);
        return;
    end if;
    begin
      select directory_path
      into   v_directory_path
      from   all_directories
      where  directory_name = 'XX_AR_TRX_PE_OUT_PRC_DIR';
      debug(g_indent            ||
      v_calling_sequence  ||
      '.v_directory_path :'||v_directory_path
      ,'1'
      );
    exception
      when others then
        v_mesg_error := 'Se debe establecer y declarar el directorio destino';
        debug(v_calling_sequence ||
              '. '               ||
              v_mesg_error
             ,'1'
             );
        fnd_file.put(fnd_file.log
                    ,g_indent           ||
                     v_calling_sequence ||
                     '. '               ||
                     v_mesg_error
                     );
        fnd_file.new_line(fnd_file.log, 1);
        retcode := '1';
        errbuf  := substr(v_mesg_error, 1, 2000);
        return;
    end;
    open c_trxs(p_customer_id      => p_customer_id,
                p_cust_trx_type_id => p_cust_trx_type,
                p_trx_number_from  => p_trx_number_from,
                p_trx_number_to    => p_trx_number_to,
                p_date_from        => fnd_date.canonical_to_date(p_date_from),
                p_date_to          => fnd_date.canonical_to_date(p_date_to),
                p_draft_mode       => nvl(p_draft_mode, 'N'),
                p_process_errors   => nvl(p_process_errors, 'Y'));

    loop
        fetch c_trxs bulk collect into v_trxs_aux_tbl limit 5000;
        exit when v_trxs_aux_tbl.count = 0;

        -- Completa estructura v_trxs_tbl
        for i in 1..v_trxs_aux_tbl.count loop
            v_trxs_aux_tbl(i).status := 'NEW';
            v_trxs_aux_tbl(i).error_code := null;
            v_trxs_aux_tbl(i).error_messages := null;
            v_trxs_tbl(v_trxs_tbl.count+1) := v_trxs_aux_tbl(i);
        end loop;

    end loop;
    close c_trxs;

    debug(g_indent            ||
          v_calling_sequence  ||
          '. Obtuvo '         ||
          v_trxs_tbl.count    ||
          ' facturas a procesar'
         ,'1'
         );

    if (v_trxs_tbl.count = 0) then
        v_mesg_error := 'NO_DATA_FOUND';
    end if;
    fnd_file.put(fnd_file.output,'<?xml version="1.0" encoding="iso-8859-1"?>');
    fnd_file.put(fnd_file.output,'<XXARPETRXP>');
    fnd_file.put(fnd_file.output,'<LIST_G_INVOICE_HEADER>');
    -- Completa detalles a imprimir
    if (v_mesg_error is null) then
        for i in 1..v_trxs_tbl.count loop

           dbms_lob.createtemporary(v_send_file, false);

           debug(g_indent            ||
                 v_calling_sequence  ||
                 '. Customer_Trx_ID: '||
                 v_trxs_tbl(i).customer_trx_id ||
                 ' Generic Customer ? ' ||
                 v_trxs_tbl(i).generic_customer
                ,'1'
                );

            -- Verifico que los Extra-Attributes se encuentran creados para la factura
            if (not xx_ar_reg_send_invoices_pk.extra_attributes_exists(p_customer_trx_id => v_trxs_tbl(i).customer_trx_id)) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                v_trxs_tbl(i).error_messages := 'No existen los registros de extra-attributes para las lineas de pedidos de ventas';
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' No existen los registros de extra-attributes de las lineas de pedidos de ventas para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;
            end if;

            -- Verifico que la moneda de impresion informada en el ATTRIBUTE15 sea correcta
            if (not xx_ar_reg_send_invoices_pk.printing_currency_is_valid (
                                                p_printing_currency_code   =>v_trxs_tbl(i).printing_currency_code
                                               ,p_functional_currency_code =>g_func_currency_code
                                               ,p_document_currency_code   =>v_trxs_tbl(i).invoice_currency_code)) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '020_INVALID_CONFIGURATION';
                v_trxs_tbl(i).error_messages := 'La moneda de impresion de factura('||v_trxs_tbl(i).printing_currency_code||')'||
                                                ' solo puede ser igual a la moneda de la transaccion('||v_trxs_tbl(i).invoice_currency_code||')'||
                                                ' o la moneda funcional del pais ('||g_func_currency_code||')';
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' La moneda de impresion de factura es diferente a la moneda de la transaccion y a la moneda funcional para customer_trx_id:'||' '
                     ||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;
            end if;


            -- Verifica si es un cliente generico o no para obtener los datos
            if (v_trxs_tbl(i).generic_customer = 'N') then
                begin
                    select substr(replace(hp.party_name,'('||v_trxs_tbl(i).org_country||')',''), 1, 100)
                          ,hp.attribute3
                          ,hp.jgzz_fiscal_code || hca.global_attribute12
                          ,hp.jgzz_fiscal_code
                          ,hca.global_attribute12
                          ,hca.attribute19
                          ,ac.email_address
                          ,substr(hl_cusb.address1 ||decode(hl_cusb.address2, null, null, ','||hl_cusb.address2)||
                            decode(hl_cusb.address3, null, null, ','||hl_cusb.address3)||
                            decode(hl_cusb.address4, null, null, ','||hl_cusb.address4), 1, 150) customer_base_address
                          , hl_cusb.city
                          , hl_cusb.state
                          , hl_cusb.province
                          , hl_cusb.country
                          , cfhpe.attribute2
                      into v_trxs_tbl(i).customer_name
                          ,v_trxs_tbl(i).customer_doc_type
                          ,v_trxs_tbl(i).customer_doc_number_full
                          ,v_trxs_tbl(i).customer_doc_number
                          ,v_trxs_tbl(i).customer_doc_digit
                          ,v_trxs_tbl(i).original_taxpayer_id
                          ,v_trxs_tbl(i).customer_email
                          ,v_trxs_tbl(i).customer_base_address
                          ,v_trxs_tbl(i).district_receptor_name
                          ,v_trxs_tbl(i).department_receptor_name
                          ,v_trxs_tbl(i).province_receptor_name
                          ,v_trxs_tbl(i).country_receptor_code
                          ,v_trxs_tbl(i).customer_doc_type_code
                      from hz_party_sites        hpsb
                          ,hz_cust_acct_sites    hcasb
                          ,hz_cust_site_uses     hcsub
                          ,hz_locations          hl_cusb
                          ,hz_parties            hp
                          ,ar_contacts_v         ac
                          ,hz_cust_accounts      hca
                          ,cll_f258_hz_party_ext cfhpe
                     where v_trxs_tbl(i).party_id            = hp.party_id
                       and v_trxs_tbl(i).cust_account_id     = hca.cust_account_id
                       and hca.cust_account_id               = ac.customer_id(+)
                       and v_trxs_tbl(i).bill_to_site_use_id = hcsub.site_use_id
                       and hcsub.cust_acct_site_id           = hcasb.cust_acct_site_id
                       and hcasb.party_site_id               = hpsb.party_site_id
                       and hpsb.location_id                  = hl_cusb.location_id
                       and hp.party_id                       = cfhpe.party_id
                       and rownum <= 1;
                exception
                    when others then
                        v_trxs_tbl(i).status := 'ERROR';
                        v_trxs_tbl(i).error_code := '030_UNEXPECTED_ERROR';
                        v_trxs_tbl(i).error_messages := 'Error inesperado obteniendo datos de cliente :'||sqlerrm;
                        v_trxs_tbl(i).customer_name := 'ERROR OBTENIENDO DATOS CLIENTE';
                        debug(g_indent            ||
                              v_calling_sequence  ||
                              ' Error inesperado obteniendo datos de cliente particular '||v_trxs_tbl(i).cust_account_id||' '||sqlerrm
                             ,'1'
                             );
                        continue;
                end;
            end if;

            -- Obtengo la descripcion para el motivo de Nota de Credito
            if (v_trxs_tbl(i).reason_code is not null) then
               begin
               select substr(flv.description, 1, 2)
                    , substr(flv.meaning, 1, 250)
                 into v_trxs_tbl(i).response_code
                    , v_trxs_tbl(i).reason_description
                 from fnd_lookup_values_vl flv
                where flv.lookup_type = 'XX_AR_FE_PE_CREDIT_MEMO_REASON'
                  and flv.lookup_code = v_trxs_tbl(i).reason_code;
               exception
                 when others then
                   v_trxs_tbl(i).status := 'ERROR';
                   v_trxs_tbl(i).error_code := '030_UNEXPECTED_ERROR';
                   v_trxs_tbl(i).error_messages := 'Error obteniendo motivo de Nota de Credito/Debito: '||sqlerrm;
                   debug(g_indent            ||
                      v_calling_sequence  ||
                        '  Error obteniendo motivo de Nota de Credito/Debito: '||sqlerrm||' para customer_trx_id: '||v_trxs_tbl(i).customer_trx_id
                        ,'1'
                        );
                   continue;
               end;
            end if;

            -- Obtengo el codigo del tipo de documento
            if (v_trxs_tbl(i).customer_doc_type is not null and v_trxs_tbl(i).customer_doc_type_code is null) then
               begin
               select substr(flv.meaning, 1, 1)
                 into v_trxs_tbl(i).customer_doc_type_code
                 from fnd_lookup_values_vl flv
                where flv.lookup_type = 'XX_PE_TAXPAYER_TYPE'
                  and flv.lookup_code = v_trxs_tbl(i).customer_doc_type;
               exception
                 when others then
                   v_trxs_tbl(i).status := 'ERROR';
                   v_trxs_tbl(i).error_code := '030_UNEXPECTED_ERROR';
                   v_trxs_tbl(i).error_messages := 'Error obteniendo codigo de tipo de documento: '||sqlerrm;
                   debug(g_indent            ||
                         v_calling_sequence  ||
                        '  Error obteniendo codigo de tipo de documento: '||sqlerrm||' para customer_trx_id: '||v_trxs_tbl(i).customer_trx_id
                        ,'1'
                        );
                   continue;
               end;
            else
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '030_UNEXPECTED_ERROR';
                v_trxs_tbl(i).error_messages := 'No se informo codigo de tipo de documento: '||sqlerrm;
                debug(g_indent            ||
                      v_calling_sequence  ||
                        '  No se informo codigo de tipo de documento: '||sqlerrm||' para customer_trx_id: '||v_trxs_tbl(i).customer_trx_id
                        ,'1'
                        );
                continue;
            end if;

            -- Obtengo la descripcion para las geografias
            -- Pais
            if (v_trxs_tbl(i).country_receptor_name is null) then
               begin
               select hg.geography_name
               into   v_trxs_tbl(i).country_receptor_name
               from   hz_geographies hg
               where  country_code = v_trxs_tbl(i).country_receptor_code
               and    geography_type = 'COUNTRY'
               and    rownum = 1;
               exception
               when others then
                   null;
               end;
            end if;

            -- Armo la dirección final del cliente
            begin
            select substr(v_trxs_tbl(i).customer_base_address ||
                          decode(v_trxs_tbl(i).district_receptor_name, null, null, ','||v_trxs_tbl(i).district_receptor_name) ||
                          decode(v_trxs_tbl(i).province_receptor_name, null, null, ','||v_trxs_tbl(i).province_receptor_name) ||
                          decode(v_trxs_tbl(i).department_receptor_name, null, null, ','||v_trxs_tbl(i).department_receptor_name) ||
                          decode(v_trxs_tbl(i).country_receptor_name, null, null, ','||v_trxs_tbl(i).country_receptor_name), 1, 100) customer_address
            into   v_trxs_tbl(i).customer_address
            from   dual;
            exception
            when others then
               null;
            end;


           -- Obtengo la Tasa de Iva de la Factura, No puede haber mas de un porcentaje.
           begin
           select zx_rate.percentage_rate
           into   v_trxs_tbl(i).vat_percentage
           from   ra_customer_trx_lines_all  rctlt
                 ,zx_lines                   zx_line
                 ,zx_rates_vl                zx_rate
           where  rctlt.line_type(+)              = 'TAX'
           and    zx_rate.tax_rate_id(+)          = zx_line.tax_rate_id
           and    zx_line.tax_line_id(+)          = rctlt.tax_line_id
           and    zx_line.entity_code             = 'TRANSACTIONS'
           and    zx_rate.tax                     =  g_vat_tax
           and    zx_line.application_id          = 222
           and    nvl(zx_rate.percentage_rate, 0) = 0
           and    rctlt.customer_trx_id           = v_trxs_tbl(i).customer_trx_id
           group by zx_rate.percentage_rate;
           exception
           when others then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '030_UNEXPECTED_ERROR';
                v_trxs_tbl(i).error_messages := 'No se pudo obtener la Tasa de Iva para el comprobante. Debe existir una tasa unica de iva.'||sqlerrm;
                debug(g_indent            ||
                      v_calling_sequence  ||
                     '  No se pudo obtener una Tasa de Iva unica para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id||' '||sqlerrm
                     ,'1'
                     );
                continue;
           end;

            -- NMuscio
            -- Primer recorrido para calcular los Totales
            v_trxs_tbl(i).net_amount             := 0;
            v_trxs_tbl(i).net_amount_pcc         := 0;
            v_trxs_tbl(i).tax_amount             := 0;
            v_trxs_tbl(i).tax_amount_pcc         := 0;
            v_trxs_tbl(i).total_amount           := 0;
            v_trxs_tbl(i).total_amount_pcc       := 0;
            v_trxs_tbl(i).net_amount_exento      := 0;
            v_trxs_tbl(i).net_amount_exento_pcc  := 0;
            v_trxs_tbl(i).net_amount_gravado     := 0;
            v_trxs_tbl(i).net_amount_gravado_pcc := 0;
            v_trxs_tbl(i).tax_amount_iva         := 0;
            v_trxs_tbl(i).tax_amount_iva_pcc     := 0;
            for r_trxs_lines in c_trx_lines (p_customer_trx_id =>v_trxs_tbl(i).customer_trx_id
                                              ,p_vat_tax         => g_vat_tax
                                              ,p_printing_currency_code => v_trxs_tbl(i).printing_currency_code
                                              ,p_invoice_currency_code => v_trxs_tbl(i).invoice_currency_code
                                              ,p_exchange_rate => v_trxs_tbl(i).exchange_rate
                                              ,p_cust_trx_concept =>v_trxs_tbl(i).cust_trx_concept
                                              ,p_print_item_line_flag => v_trxs_tbl(i).print_item_line_flag) loop

                  if (r_trxs_lines.item_description is null) then
                      v_trxs_tbl(i).status := 'ERROR';
                      v_trxs_tbl(i).error_code := '020_INVALID_CONFIGURATION';
                      select 'No se pudo obtener descripcion para articulo '||msib.segment1||' y '||v_trxs_tbl(i).cust_trx_type_name
                      into   v_trxs_tbl(i).error_messages
                      from   mtl_system_items_b msib
                      where msib.inventory_item_id = r_trxs_lines.inventory_item_id
                      and   msib.organization_id = r_trxs_lines.organization_id;
                      debug(g_indent            ||
                            v_calling_sequence  ||
                            v_trxs_tbl(i).error_messages
                           ,'1'
                           );
                      continue;
                  end if;

                  v_trxs_tbl(i).net_amount             := v_trxs_tbl(i).net_amount + r_trxs_lines.net_amount;
                  v_trxs_tbl(i).tax_amount             := v_trxs_tbl(i).tax_amount + r_trxs_lines.tax_amount;
                  v_trxs_tbl(i).total_amount           := v_trxs_tbl(i).total_amount + r_trxs_lines.total_amount;
                  v_trxs_tbl(i).net_amount_exento      := v_trxs_tbl(i).net_amount_exento + r_trxs_lines.net_amount_exento;
                  v_trxs_tbl(i).net_amount_gravado     := v_trxs_tbl(i).net_amount_gravado + r_trxs_lines.net_amount_gravado;
                  v_trxs_tbl(i).tax_amount_iva         := v_trxs_tbl(i).tax_amount_iva + r_trxs_lines.tax_amount_iva;

                  -- Antes de acumular, Redondeo los valores que se van a imprimir para no manejar decimales (Chile no acepta decimales).
                  -- Recalculo el monto de Tax para que el % se calcule sobre el total (Los clientes quieren el calculo por total, Oracle lo hace por linea)
                  v_net_amount_exento_pcc  := r_trxs_lines.net_amount_exento_pcc;
                  v_net_amount_gravado_pcc := r_trxs_lines.net_amount_gravado_pcc;
                  v_net_amount_pcc         := v_net_amount_gravado_pcc + v_net_amount_exento_pcc;
                  v_tax_amount_iva_pcc     := round(v_net_amount_gravado_pcc * v_trxs_tbl(i).vat_percentage/100, 2);
                  v_total_amount_pcc       := v_net_amount_pcc + v_tax_amount_iva_pcc;

                  v_trxs_tbl(i).net_amount_exento_pcc   := v_trxs_tbl(i).net_amount_exento_pcc + v_net_amount_exento_pcc;
                  v_trxs_tbl(i).net_amount_gravado_pcc  := v_trxs_tbl(i).net_amount_gravado_pcc + v_net_amount_gravado_pcc;
                  v_trxs_tbl(i).net_amount_pcc          := v_trxs_tbl(i).net_amount_pcc + v_net_amount_pcc;
                  v_trxs_tbl(i).tax_amount_iva_pcc      := v_trxs_tbl(i).tax_amount_iva_pcc + v_tax_amount_iva_pcc;
                  v_trxs_tbl(i).total_amount_pcc        := v_trxs_tbl(i).total_amount_pcc + v_total_amount_pcc;

                  -- El Total de Impuestos es igual el total del Iva (Por las dudas se valida afuera, No puede haber otro impuesto)
                  v_trxs_tbl(i).tax_amount_pcc          := v_trxs_tbl(i).tax_amount_pcc + v_tax_amount_iva_pcc;
            end loop;


            -- Valido que la transaccion solo calcule IVA, no debe haber otro impuesto
            if (v_trxs_tbl(i).tax_amount_iva != v_trxs_tbl(i).tax_amount) then
                v_trxs_tbl(i).error_code := '020_INVALID_CONFIGURATION';
                v_trxs_tbl(i).error_messages := 'El comprobante tiene impuestos que no corresponden con Iva. Total Iva: '||v_trxs_tbl(i).tax_amount_iva||
                                                ' Total Impuestos: '||v_trxs_tbl(i).tax_amount;
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' El comprobante tiene impuestos que no corresponden con Iva. Total Iva: '||v_trxs_tbl(i).tax_amount_iva||
                                                ' Total Impuestos: '||v_trxs_tbl(i).tax_amount|| ' para customer_trx_id:'||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                 continue;
            end if;

            -- Llamo a la funcion que calcula el monto en letras
            v_amount_in_words  := xx_ar_reg_send_invoices_pk.get_amount_in_words
                                                             (p_amount                => v_trxs_tbl(i).total_amount_pcc
                                                             ,p_country_currency_code => g_func_currency_code
                                                             ,p_amount_currency_code  => v_trxs_tbl(i).printing_currency_code
                                                             ,p_country_code          => 'ES');

            if (v_trxs_tbl(i).total_amount_pcc != trunc(v_trxs_tbl(i).total_amount_pcc)) then
                v_amount_in_words := v_amount_in_words || ' CENTAVOS';
            end if;

            -- Obtengo el codigo de moneda a imprimir
            if (v_trxs_tbl(i).printing_currency_code = g_func_currency_code) then
               v_trxs_tbl(i).printing_currency_code_fe_code := g_func_currency_code;
            else
               begin
               select meaning
               into   v_trxs_tbl(i).printing_currency_code_fe_code
               from   fnd_lookup_values_vl flv
               where  flv.lookup_type = 'XX_AR_FE_PE_CURRENCIES'
               and    flv.lookup_code = v_trxs_tbl(i).printing_currency_code;
               exception
               when others then
                   null;
               end;
            end if;

            -- Determina si el comprobante tiene detraccion.
            if (v_trxs_tbl(i).invoice_currency_code =  g_func_currency_code) then
                v_trxs_tbl(i).detraction_code := set_detraction_code(p_document_type_code => v_trxs_tbl(i).electr_doc_type
                                                                   , p_payment_method     => v_trxs_tbl(i).collection_type
                                                                   , p_document_amount    => v_trxs_tbl(i).total_amount);
            else
                v_trxs_tbl(i).detraction_code := set_detraction_code(p_document_type_code => v_trxs_tbl(i).electr_doc_type
                                                                   , p_payment_method     => v_trxs_tbl(i).collection_type
                                                                   , p_document_amount    => round((v_trxs_tbl(i).net_amount +  v_trxs_tbl(i).tax_amount) * v_trxs_tbl(i).exchange_rate, 2));
            end if;

            -- Si es una NC, llamo a la funcion que obtiene la referencia a la FC original
            if (v_trxs_tbl(i).document_type in ('CM', 'DM')) then
                v_trxs_tbl(i).ref_customer_trx_id  := xx_ar_utilities_pk.get_related_invoice_id (p_customer_trx_id => v_trxs_tbl(i).customer_trx_id);

                -- Obtengo los datos del comprobante relacionado
                get_datos_trx (p_customer_trx_id          => v_trxs_tbl(i).ref_customer_trx_id
                              ,x_trx_number               => v_trxs_tbl(i).ref_trx_number
                              ,x_trx_date                 => v_trxs_tbl(i).ref_trx_date
                              ,x_electr_doc_type          => v_trxs_tbl(i).ref_electr_doc_type
                              ,x_procesado_fc_electronica => v_trxs_tbl(i).ref_procesado_fc_electronica);
            end if;

            -- Valida datos obligatorios
            if (v_trxs_tbl(i).customer_name is null) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                v_trxs_tbl(i).error_messages := 'No se informo nombre del cliente';
                v_trxs_tbl(i).customer_name := 'NO INFORMADO';
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' No se informó nombre del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;
            elsif (v_trxs_tbl(i).customer_doc_number is null) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                v_trxs_tbl(i).error_messages := 'No se informo Nro Documento del cliente';
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' No se informó Nro Documento del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;
            elsif (v_trxs_tbl(i).country_receptor_name is null) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                v_trxs_tbl(i).error_messages := 'No se informo Pais del cliente';
                v_trxs_tbl(i).country_receptor_name := 'X';
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' No se informó Pais del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;
            elsif (v_trxs_tbl(i).printing_currency_code_fe_code is null) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '020_INVALID_CONFIGURATION';
                v_trxs_tbl(i).error_messages := 'No se pudo obtener el código de factura electronica para la moneda:'||' '||v_trxs_tbl(i).printing_currency_code;
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' No se pudo obtener el código de factura electronica de la moneda para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;
            elsif (v_trxs_tbl(i).geo_code is null) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                v_trxs_tbl(i).error_messages := 'La entidad legal no tiene informado codigo ubicacion geografica';
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' No se informó e codigo de ubicacion geografica de la Entidad Legal para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;
            elsif (v_trxs_tbl(i).expedition_address is null or v_trxs_tbl(i).expedition_place is null) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                v_trxs_tbl(i).error_messages := 'La entidad legal no tiene informado el domicilio y/o la ciudad';
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' No se informó el domicilio y/o la ciudad de la Entidad Legal para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;
            elsif (v_trxs_tbl(i).collection_type is null) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '020_INVALID_CONFIGURATION';
                v_trxs_tbl(i).error_messages := 'No se pudo obtener el tipo de venta (collection_type) del Tipo de Transaccion';
                v_trxs_tbl(i).collection_type := 'NO INFORMADO';
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' No se configuro el collection_type del tipo de trx para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;
            elsif (v_amount_in_words is null) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                v_trxs_tbl(i).error_messages := 'No se pudo calcular el monto en letras';
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' No se pudo calcular el monto en letras para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;
            -- Valido que el tipo de documento sea uno de los esperados
            elsif (v_trxs_tbl(i).electr_doc_type  not in ('01', '03', '07', '08')) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '020_INVALID_CONFIGURATION';
                v_trxs_tbl(i).error_messages := 'Tipo de Doc de Fc Electronica Invalido: '||v_trxs_tbl(i).electr_doc_type;
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' Tipo de Doc invalido para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;
            -- Valido la informacion del comprobante referenciado para las NC y ND
            elsif (v_trxs_tbl(i).document_type in ('CM', 'DM')) then
                -- Valido que exista la Referencia
                if (v_trxs_tbl(i).ref_trx_number is null) then
                    v_trxs_tbl(i).status := 'ERROR';
                    v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                    v_trxs_tbl(i).error_messages := 'No se pudo obtener la referencia a la FC: ';
                    debug(g_indent            ||
                          v_calling_sequence  ||
                         ' No se pudo obtener la referencia a la factura para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                         ,'1'
                          );
                    continue;
                end if;
                -- Valido que se haya obtenido la informacion del tipo de trx de la referencia
                if (v_trxs_tbl(i).ref_electr_doc_type is null) then
                    v_trxs_tbl(i).status := 'ERROR';
                    v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                    v_trxs_tbl(i).error_messages := 'No se pudo obtener el tipo de documento electronico para la FC referenciada('||v_trxs_tbl(i).ref_trx_number||')';
                    debug(g_indent            ||
                          v_calling_sequence  ||
                         ' No se pudo obtener el tipo de documento electronico para la FC referenciada para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                         ,'1'
                          );
                    continue;
                end if;
                -- Valido que la factura referenciada haya vuelto de factura electronica
                if (nvl (v_trxs_tbl(i).ref_procesado_fc_electronica, 'N') = 'N') then
                    v_trxs_tbl(i).status := 'ERROR';
                    v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                    v_trxs_tbl(i).error_messages := 'La factura referenciada ('|| v_trxs_tbl(i).ref_trx_number||') aun no fue procesada por fc electronica';
                    debug(g_indent            ||
                          v_calling_sequence  ||
                         'La factura referenciada aun no fue procesada por fc electronica para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                         ,'1'
                          );
                    continue;
                end if;
            end if;

            debug(g_indent                 ||
                  v_calling_sequence       ||
                  '. Comienza a armar XML '
                 ,'1'
                 );

            begin
              v_send_line := '<G_INVOICE_HEADER>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<CONC_REQUEST_ID>'||v_request_id||'</CONC_REQUEST_ID>'||G_EOL;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<XX_AR_INVOICE_WORK_PATH>'||v_directory_path||'</XX_AR_INVOICE_WORK_PATH>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<CUSTOMER_TRX_ID>'||v_trxs_tbl(i).customer_trx_id||'</CUSTOMER_TRX_ID>'||G_EOL;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<XX_AR_TRX_PE_OUT_PRC_DIR>'||v_directory_path||'</XX_AR_TRX_PE_OUT_PRC_DIR>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<COUNTRY>PE</COUNTRY>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              --Informacion de cliente
              v_send_line := '<CLIENTE>'||v_trxs_tbl(i).cliente||'</CLIENTE>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);              
              v_send_line := '<ID_CLIENTE>'||v_trxs_tbl(i).id_cliente||'</ID_CLIENTE>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<EMAIL_CLIENTE>'||v_trxs_tbl(i).email_cliente||'</EMAIL_CLIENTE>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);              
--              ----------------- Inicio de Seccion Invoice / CreditNote / DebitNote -------------------------
--              if (v_trxs_tbl(i).document_type = 'INV') then
--                  v_send_line := '<Invoice>'||g_eol;
--              elsif (v_trxs_tbl(i).document_type = 'CM') then
--                  v_send_line := '<CreditNote>'||g_eol;
--              elsif (v_trxs_tbl(i).document_type = 'DM') then
--                  v_send_line := '<DebitNote>'||g_eol;
--              end if;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--            debug(g_indent                 ||
--                  v_calling_sequence       ||
--                  '. XML ID ' || v_trxs_tbl(i).trx_number || ' '|| v_trxs_tbl(i).doc_sequence_value
--                 ,'1'
--                 );
--
--              v_send_line := '<ID>'||v_trxs_tbl(i).doc_sequence_value||
--                             lpad(v_trxs_tbl(i).trx_number, 13 - length(v_trxs_tbl(i).doc_sequence_value), '0')||'</ID>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<IssueDate>'||to_char(v_trxs_tbl(i).trx_date, 'YYYY-MM-DD')||'</IssueDate>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<InvoiceTypeCode>'||v_trxs_tbl(i).electr_doc_type||'</InvoiceTypeCode>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<DocumentCurrencyCode>'||v_trxs_tbl(i).printing_currency_code_fe_code||'</DocumentCurrencyCode>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              debug(g_indent                       ||
--                    v_calling_sequence             ||
--                    '. Seccion DiscrepancyResponse '
--                   ,'1'
--                   );
--
--              ----------------------- Inicio de Seccion DiscrepancyResponse -----------------------------
--              if (v_trxs_tbl(i).document_type in ('CM', 'DM')) then
--                  v_send_line := '<DiscrepancyResponse>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                   v_send_line := '<ReferenceID>'||v_trxs_tbl(i).ref_trx_number||'</ReferenceID>'||g_eol;
--                   dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                   if v_trxs_tbl(i).document_type = 'DM' then
--                     v_send_line := '<ResponseCode>02</ResponseCode>'||g_eol;
--                   else
--                     v_send_line := '<ResponseCode>'||v_trxs_tbl(i).response_code||'</ResponseCode>'||g_eol;
--                   end if;
--                   dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                   if v_trxs_tbl(i).document_type = 'DM' then
--                     v_send_line := '<Description>Aumento en el valor</Description>'||g_eol;
--                   else
--                     v_send_line := '<Description>'||v_trxs_tbl(i).reason_description||'</Description>'||g_eol;
--                   end if;
--                   dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '</DiscrepancyResponse>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--              end if;
--              ----------------------- Fin de Seccion DiscrepancyResponse -----------------------------
--
--              debug(g_indent                       ||
--                    v_calling_sequence             ||
--                    '. Seccion BillingResponse '
--                   ,'1'
--                   );
--
--              ----------------------- Inicio de Seccion BillingResponse -----------------------------
--              if (v_trxs_tbl(i).document_type in ('CM', 'DM')) then
--                  v_send_line := '<BillingResponse>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                   v_send_line := '<ID>'||v_trxs_tbl(i).ref_trx_number||'</ID>'||g_eol;
--                   dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                   v_send_line := '<DocumentTypeCode>'||v_trxs_tbl(i).ref_electr_doc_type||'</DocumentTypeCode>'||g_eol;
--                   dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '</BillingResponse>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--              end if;
--              ----------------------- Fin de Seccion BillingResponse -----------------------------
--
--              debug(g_indent                             ||
--                    v_calling_sequence                   ||
--                    '. Seccion AccountingSupplierParty '
--                   ,'1'
--                   );
--
--              -------------------- Inicio de Seccion AccountingSupplierParty ----------------------
--              v_send_line := '<AccountingSupplierParty>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<CustomerAssignedAccountID>'||v_trxs_tbl(i).legal_entity_identifier||'</CustomerAssignedAccountID>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<AdditionalAccountID>6</AdditionalAccountID>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<Party>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<PartyName>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<Name>'||v_trxs_tbl(i).legal_entity_name||'</Name>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</PartyName>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<PostalAddress>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<ID>'||v_trxs_tbl(i).geo_code||'</ID>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<StreetName>'||v_trxs_tbl(i).expedition_address||'</StreetName>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<CityName>'||v_trxs_tbl(i).expedition_place||'</CityName>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<District>'||v_trxs_tbl(i).expedition_district||'</District>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<Country>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<IdentificationCode>'||v_trxs_tbl(i).org_country||'</IdentificationCode>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</Country>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</PostalAddress>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<PartyLegalEntity>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<RegistrationName>'||v_trxs_tbl(i).legal_entity_name||'</RegistrationName>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</PartyLegalEntity>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</Party>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</AccountingSupplierParty>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--              -------------------- Inicio de Seccion AccountingSupplierParty ----------------------
--
--              debug(g_indent                             ||
--                    v_calling_sequence                   ||
--                    '. Seccion AccountingCustomerParty '
--                   ,'1'
--                   );
--
--              -------------------- Inicio de Seccion AccountingCustomerParty ----------------------
--              v_send_line := '<AccountingCustomerParty>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<CustomerAssignedAccountID>'||v_trxs_tbl(i).customer_doc_number_full||'</CustomerAssignedAccountID>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<AdditionalAccountID>'||v_trxs_tbl(i).customer_doc_type_code||'</AdditionalAccountID>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<Party>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<PartyName>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<Name>'||v_trxs_tbl(i).customer_name||'</Name>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</PartyName>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<PostalAddress>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<StreetName>'||v_trxs_tbl(i).customer_address||'</StreetName>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<CitySubdivisionName></CitySubdivisionName>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<CityName>'||v_trxs_tbl(i).province_receptor_name||'</CityName>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<CountrySubentity>'||v_trxs_tbl(i).department_receptor_name||'</CountrySubentity>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<District>'||v_trxs_tbl(i).district_receptor_name||'</District>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<Country>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<IdentificationCode>'||v_trxs_tbl(i).country_receptor_code||'</IdentificationCode>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</Country>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</PostalAddress>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<PartyLegalEntity>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<RegistrationName>'||v_trxs_tbl(i).customer_name||'</RegistrationName>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</PartyLegalEntity>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</Party>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</AccountingCustomerParty>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--              --------------------- Fin de Seccion AccountingCustomerParty ------------------------------
--
--              debug(g_indent              ||
--                    v_calling_sequence    ||
--                    '. Seccion TaxTotal '
--                   ,'1'
--                   );
--
--              --------------------------- Inicio de Seccion TaxTotal-------------------------------------
--              v_send_line := '<TaxTotal>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<TaxAmount>'||abs(v_trxs_tbl(i).tax_amount_iva_pcc)||'</TaxAmount>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<TaxSubtotal>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<TaxAmount>'||abs(v_trxs_tbl(i).tax_amount_iva_pcc)||'</TaxAmount>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<TaxCategory>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<TaxScheme>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<ID>1000</ID>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<Name>IGV</Name>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<TaxTypeCode>VAT</TaxTypeCode>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</TaxScheme>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</TaxCategory>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</TaxSubtotal>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</TaxTotal>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--              ----------------------------- Fin de Seccion TaxTotal--------------------------------------
--
--              debug(g_indent                       ||
--                    v_calling_sequence             ||
--                    '. Seccion LegalMonetaryTotal '
--                   ,'1'
--                   );
--
--              ---------------------- Inicio de Seccion LegalMonetaryTotal--------------------------------
--              v_send_line := '<LegalMonetaryTotal>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<PayableAmount>'||abs(v_trxs_tbl(i).total_amount_pcc)||'</PayableAmount>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<ChargeTotalAmount>0</ChargeTotalAmount>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</LegalMonetaryTotal>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--              ------------------------- Fin de Seccion LegalMonetaryTotal--------------------------------
--
--              debug(g_indent           ||
--                    v_calling_sequence ||
--                    '. Seccion Totales '
--                   ,'1'
--                   );
--
              v_nro_lin_det := 0;
              for r_trxs_lines in c_trx_lines (p_customer_trx_id        => v_trxs_tbl(i).customer_trx_id
                                              ,p_vat_tax                => g_vat_tax
                                              ,p_printing_currency_code => v_trxs_tbl(i).printing_currency_code
                                              ,p_invoice_currency_code  => v_trxs_tbl(i).invoice_currency_code
                                              ,p_exchange_rate          => v_trxs_tbl(i).exchange_rate
                                              ,p_cust_trx_concept       => v_trxs_tbl(i).cust_trx_concept
                                              ,p_print_item_line_flag   => v_trxs_tbl(i).print_item_line_flag) loop

--                  if (r_trxs_lines.item_description is null) then
--                      v_trxs_tbl(i).status := 'ERROR';
--                      v_trxs_tbl(i).error_code := '020_INVALID_CONFIGURATION';
--                      select 'No se pudo obtener descripcion para articulo '||msib.segment1||' y '||v_trxs_tbl(i).cust_trx_type_name
--                      into   v_trxs_tbl(i).error_messages
--                      from   mtl_system_items_b msib
--                      where msib.inventory_item_id = r_trxs_lines.inventory_item_id
--                      and   msib.organization_id = r_trxs_lines.organization_id;
--                      debug(g_indent            ||
--                            v_calling_sequence  ||
--                            v_trxs_tbl(i).error_messages
--                           ,'1'
--                           );
--                      continue;
--                  end if;
--
                  -- Redondeo los valores para no manejar decimales (Chile no acepta decimales).
                  -- Recalculo el monto de Tax para que el % se calcule sobre el total (Los clientes quieren el calculo por total, Oracle lo hace por linea)
                  v_net_amount_exento_pcc  := r_trxs_lines.net_amount_exento_pcc;
                  v_net_amount_gravado_pcc := r_trxs_lines.net_amount_gravado_pcc;
                  v_net_amount_pcc         := v_net_amount_gravado_pcc + v_net_amount_exento_pcc;
                  v_tax_amount_iva_pcc     := round(v_net_amount_gravado_pcc * v_trxs_tbl(i).vat_percentage/100, 2);
                  v_total_amount_pcc       := v_net_amount_pcc + v_tax_amount_iva_pcc;

                  v_nro_lin_det := v_nro_lin_det + 1;

                  v_send_line := '<G_INVOICE_LINE>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<PNR_NUMBER>'||r_trxs_lines.pnr_number||'</PNR_NUMBER>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<NRO_TICKET>'||r_trxs_lines.nro_ticket||'</NRO_TICKET>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<PASAJERO>'||r_trxs_lines.pasajero||'</PASAJERO>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<ID_PASAJERO>'||r_trxs_lines.id_pasajero||'</ID_PASAJERO>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<TIPO_PASAJERO>'||r_trxs_lines.tipo_pasajero||'</TIPO_PASAJERO>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '</G_INVOICE_LINE>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);

                  debug(g_indent           ||
                        v_calling_sequence ||
                        '. Seccion InvoiceLine '
                       ,'1'
                       );
                  --------------------------- Inicio de Seccion InvoiceLine----------------------------------
--                  if (v_trxs_tbl(i).document_type = 'INV') then
--                      v_send_line := '<InvoiceLine>'||g_eol;
--                  elsif (v_trxs_tbl(i).document_type = 'CM') then
--                      v_send_line := '<CreditNoteLine>'||g_eol;
--                  elsif (v_trxs_tbl(i).document_type = 'DM') then
--                      v_send_line := '<DebitNoteLine>'||g_eol;
--                  end if;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<ID>'||v_nro_lin_det||'</ID>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  if (v_trxs_tbl(i).document_type = 'INV') then
--                      v_send_line := '<InvoicedQuantity>'||abs(r_trxs_lines.quantity)||'</InvoicedQuantity>'||g_eol;
--                  elsif (v_trxs_tbl(i).document_type = 'CM') then
--                      v_send_line := '<CreditedQuantity>'||abs(r_trxs_lines.quantity)||'</CreditedQuantity>'||g_eol;
--                  elsif (v_trxs_tbl(i).document_type = 'DM') then
--                      v_send_line := '<DebitedQuantity>'||abs(r_trxs_lines.quantity)||'</DebitedQuantity>'||g_eol;
--                  end if;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<UnitCode>NIU</UnitCode>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<LineExtensionAmount>'||abs(v_net_amount_pcc)||'</LineExtensionAmount>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<PricingReference>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<AlternativeConditionPrice>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<PriceAmount>'||abs(v_total_amount_pcc)||'</PriceAmount>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<PriceTypeCode>01</PriceTypeCode>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '</AlternativeConditionPrice>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '</PricingReference>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  --------------------------- Inicio de Seccion TaxTotal-------------------------------------
--                  v_send_line := '<TaxTotal>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<TaxAmount>'||abs(v_tax_amount_iva_pcc)||'</TaxAmount>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<TaxSubtotal>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<TaxAmount>'||abs(v_tax_amount_iva_pcc)||'</TaxAmount>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<TaxScheme>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<ID>1000</ID>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<Name>IGV</Name>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<TaxTypeCode>VAT</TaxTypeCode>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '</TaxScheme>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '</TaxSubtotal>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '</TaxTotal>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--                  ----------------------------- Fin de Seccion TaxTotal--------------------------------------
--
--                  ----------------------------- Inicio de Seccion Item---------------------------------------
--                  v_send_line := '<Item>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<Description>'||psp_xmlgen.convert_xml_controls(r_trxs_lines.item_description)||'</Description>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '</Item>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--                  ------------------------------ Inicio de Seccion Item--------------------------------------
--
--                  ----------------------------- Inicio de Seccion Price---------------------------------------
--                  v_send_line := '<Price>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<PriceAmount>'||abs(v_net_amount_pcc)||'</PriceAmount>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '</Price>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--                  ----------------------------- Inicio de Seccion Price--------------------------------------
--
--                  if (v_trxs_tbl(i).document_type = 'INV') then
--                      v_send_line := '</InvoiceLine>'||g_eol;
--                  elsif (v_trxs_tbl(i).document_type = 'CM') then
--                      v_send_line := '</CreditNoteLine>'||g_eol;
--                  elsif (v_trxs_tbl(i).document_type = 'DM') then
--                      v_send_line := '</DebitNoteLine>'||g_eol;
--                  end if;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--                  ------------------------------ Fin de Seccion InvoiceLine----------------------------------
--
--                  ---------------------- Inicio de Seccion AdditionalInformation-----------------------------
--                  v_send_line := '<AdditionalInformation>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<AdditionalMonetaryTotal>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<ID>1001</ID>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<PayableAmount>'||abs(v_net_amount_pcc)||'</PayableAmount>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '</AdditionalMonetaryTotal>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '</AdditionalInformation>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--                  ------------------------ Fin de Seccion AdditionalInformation--------------------------------
--
              end loop;
--
--
--              ------------------------------ Inicio de Seccion Adjuntos ---------------------------------
--              v_send_line := '<Adjuntos>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '<MontoPalabras>'||v_amount_in_words||'</MontoPalabras>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
              ---- Informacion de Terceros
              for r_trxs_lines_terceros in c_trx_lines_terceros (p_customer_trx_id =>v_trxs_tbl(i).customer_trx_id
                                                                ,p_printing_currency_code => v_trxs_tbl(i).printing_currency_code
                                                                ,p_invoice_currency_code => v_trxs_tbl(i).invoice_currency_code
                                                                ,p_exchange_rate => v_trxs_tbl(i).exchange_rate) loop
--
--                  v_send_line := '<DescripcionTerceros>'||psp_xmlgen.convert_xml_controls (r_trxs_lines_terceros.tercero_description)||'</DescripcionTerceros>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--                  v_send_line := '<ImporteTerceros>'||abs(r_trxs_lines_terceros.tercero_amount)||'</ImporteTerceros>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
                null; --Para verificar si es necesario un dato
              end loop;
--
              ---- Informacion Adicional
              for r_trx_lines_inf_adic in c_trx_lines_inf_adic (p_customer_trx_id       => v_trxs_tbl(i).customer_trx_id
                                                               ,p_collection_type       => v_trxs_tbl(i).collection_type
                                                               ,p_hotel_stmt_trx_number => v_trxs_tbl(i).hotel_stmt_trx_number
                                                               ,p_country_receptor_code => v_trxs_tbl(i).country_receptor_code
                                                               ,p_original_taxpayer_id  => v_trxs_tbl(i).original_taxpayer_id) loop
--
--                  v_send_line := '<Observaciones>'||psp_xmlgen.convert_xml_controls(r_trx_lines_inf_adic.info_adic)||'</Observaciones>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
                null; --Para verificar si es necesario un dato
              end loop;
--
--              -- Leyenda Adicional
--              -- Imprime Comentarios
--              if (v_trxs_tbl(i).comments is not null) then
--                  v_send_line := '<Observaciones>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).comments)||'</Observaciones>'||g_eol;
--                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--              end if;
--
--              -- Leyenda Adicional
--              -- Imprime Monto en Moneda Original (Solo cuando es distinta a la moneda de impresion de factura).
--              if (v_trxs_tbl(i).invoice_currency_code != v_trxs_tbl(i).printing_currency_code) then
--
--                 v_send_line := '<Observaciones>'||'Son '||abs(v_trxs_tbl(i).total_amount)||' '||v_trxs_tbl(i).invoice_currency_code||
--                                ' TC ('||round(v_trxs_tbl(i).exchange_rate, 2)||')</Observaciones>'||g_eol;
--                 dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              end if;
--
--              -- Condicion de Pago
--              v_send_line := '<FormaPago>'||v_trxs_tbl(i).receipt_method_name||'</FormaPago>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              -- Condicion de Pago
--              v_send_line := '<Detraccion>'||v_trxs_tbl(i).detraction_code||'</Detraccion>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--
--              v_send_line := '</Adjuntos>'||g_eol;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
--              -------------------------- Fin de Seccion Datos Adjuntos ----------------------------------
--
--              if (v_trxs_tbl(i).document_type = 'INV') then
--                  v_send_line := '</Invoice>'||g_eol;
--              elsif (v_trxs_tbl(i).document_type = 'CM') then
--                  v_send_line := '</CreditNote>'||g_eol;
--              elsif (v_trxs_tbl(i).document_type = 'DM') then
--                  v_send_line := '</DebitNote>'||g_eol;
--              end if;
--              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              if (v_trxs_tbl(i).status != 'ERROR') then
                v_send_line := '</G_INVOICE_HEADER>'||g_eol;
                dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              end if;
              ----------------- Fin de Seccion Invoice / CreditNote / DebitNote -----------------------
            exception
            when others then
                v_mesg_error := 'Error cargando el contenido del archivo en la tabla de Envios de Transacciones ' ||
                                '(XX_AR_FE_PE_TRX). Texto: ' || v_send_line || '. ' || sqlerrm;
            end;

            if (v_mesg_error is null and v_trxs_tbl(i).status != 'ERROR') then
                debug(g_indent            ||
                      v_calling_sequence  ||
                      ' Copiando lob'
                     ,'1'
                     );
                dbms_lob.createtemporary(v_trxs_tbl(i).send_file, false);
                dbms_lob.copy(v_trxs_tbl(i).send_file, v_send_file, dbms_lob.getlength(v_send_file));
                dbms_lob.freetemporary(v_send_file);
                debug(g_indent            ||
                      v_calling_sequence  ||
                      ' Copiado de lob finalizado'
                     ,'1'
                     );
            end if;

        end loop;   --  Loop Principal

    end if; --  Fin Completa detalles a imprimir

    -- Genera los archivos
    if (v_mesg_error is null) then

        debug(g_indent            ||
              v_calling_sequence  ||
              ' Generando archivos'
             ,'1'
             );

        begin
           --if not print_text(p_print_output => null
           --                 ,p_mesg_error   => v_mesg_error
           --                 ) then
           --   v_mesg_error := 'Error generando archivos: '||v_mesg_error;
           --end if;

           if not print_text(p_print_output => 'Y'
                            ,p_mesg_error   => v_mesg_error
                            ) then
              v_mesg_error := 'Error generando archivos: '||v_mesg_error;
           end if;

         exception
           when others then
             v_mesg_error := v_calling_sequence               ||
                             '. Error llamando a la funcion ' ||
                             'PRINT_TEXT. '                   ||
                             sqlerrm;
         end;

    end if; -- Genera los archivos
    fnd_file.put(fnd_file.output,'</LIST_G_INVOICE_HEADER>');
    fnd_file.put(fnd_file.output,'</XXARPETRXP>');
    -- Inserta registros en tabla de intercambio
    if (v_mesg_error is null) then
        for i in 1..v_trxs_tbl.count loop

           if v_trxs_tbl(i).status = 'ERROR' then
               v_error_qty := v_error_qty + 1;
           else
               v_success_qty := v_success_qty + 1;
           end if;

            begin

                -- Se obtiene extracto del comprobante relacionado cuando corresponde
                v_hotel_stmt_trx_number := xx_ar_utilities_pk.get_hotel_stmt_trx_number(v_trxs_tbl(i).customer_trx_id);

                -- Se obtiene el periodo del extracto
                xx_ar_utilities_pk.get_hotel_stmt_info(p_hotel_stmt_trx_number => v_hotel_stmt_trx_number
                                                     , x_period_name           => v_month_billed);

                select case
                       when nvl(v_trxs_tbl(i).collection_type, 'XX') = 'PD' then
                         null
                       else
                           decode(rctl.interface_line_context
                                ,'ORDER ENTRY',oos.name
                                ,'XX_MANUAL'
                                )
                       end
                       ,ooh.orig_sys_document_ref
                       ,xahsh.stmt_source
                  into v_order_source
                      ,v_orig_sys_document_ref
                      ,v_stmt_source
                  from oe_order_sources           oos
                      ,oe_order_headers           ooh
                      ,oe_order_lines             ool
                      ,ra_customer_trx            rct
                      ,ra_customer_trx_lines      rctl
                      ,xx_ap_hotel_statements_hdr xahsh
                 where 1 = 1
                   and v_trxs_tbl(i).customer_trx_id       = rct.customer_trx_id
                   and rct.customer_trx_id                 = rctl.customer_trx_id
                   and rctl.line_type                      = 'LINE'
                   and rctl.interface_line_attribute6      = ool.line_id(+)
                   and ool.header_id                       = ooh.header_id(+)
                   and xx_ar_utilities_pk.get_hotel_stmt_trx_number(rct.customer_trx_id) = xahsh.hotel_stmt_trx_number(+)
                   and decode(rctl.interface_line_context
                             ,'ORDER ENTRY',rctl.interface_line_attribute1
                             ,-1
                             )                        = decode(rctl.interface_line_context
                                                              ,'ORDER ENTRY',ooh.order_number
                                                              ,-1
                                                             )
                  and ooh.order_source_id            = oos.order_source_id(+)
                  and rownum = 1;

            exception
              when others then
                  v_order_source := null;
                  v_orig_sys_document_ref := null;
                  v_stmt_source := null;
            end;

            ----------------------------
            -- Calcula datos adicionales
            ----------------------------
            begin

               insert into xx_ar_reg_invoice_request (customer_trx_id
                    , trx_number_ori
                    , reference
                    , receive_date
                    , trx_number_new
                    , link
                    , cae
                    , fecha_cae
                    , file_name
                    , status
                    , error_code
                    , error_messages
                    , created_by
                    , creation_date
                    , last_updated_by
                    , last_update_date
                    , last_update_login
                    , purchase_order
                    , request_number
                    , order_source
                    , orig_sys_document_ref
                    , collection_type
                    , document_type
                    , email
                    , source_system_number
                    , legal_entity
                    , legal_entity_code
                    , request_id
                    , stmt_source
                    , hotel_stmt_trx_number
                    , attribute_category
                    , attribute1
                    , attribute2
                    , attribute3
                    , attribute4
                    , attribute5
                    , attribute6
                    , attribute7
                    , attribute8
                    , attribute9
                    , attribute10
                    , net_amount
                    , net_amount_pcc
                    , tax_amount
                    , tax_amount_pcc
                    , total_amount
                    , total_amount_pcc
                    , trx_date
                    , collection_country
                    , month_billed
                    , invoice_currency_code
                    , printing_currency_code)
                values (v_trxs_tbl(i).customer_trx_id       -- CUSTOMER_TRX_ID
                    , v_trxs_tbl(i).trx_number              -- TRX_NUMBER_ORI
                    , nvl(v_trxs_tbl(i).customer_name, 'NO INFORMADO') -- REFERENCE
                    , null                                  -- RECEIVE_DATE
                    , null                                  -- TRX_NUMBER_NEW
                    , null                                  -- LINK
                    , null                                  -- CAE
                    , null                                  -- FECHA_CAE
                    --, v_trxs_tbl(i).output_file             -- FILE_NAME
                    , v_trxs_tbl(i).customer_trx_id||'-'||v_request_id||'.pdf' -- FILE_NAME
                    , decode(v_trxs_tbl(i).status
                            ,'ERROR', 'PROCESSING_ERROR_ORACLE'
                    --        ,'NEW')                         -- STATUS
                            ,'WORK_IN_PROGRESS')            -- STATUS
                    , v_trxs_tbl(i).error_code              -- ERROR_CODE
                    , v_trxs_tbl(i).error_messages          -- ERROR_MESSAGES
                    , fnd_global.user_id                    -- CREATED_BY
                    , sysdate                               -- CREATION_DATE
                    , fnd_global.user_id                    -- LAST_UPDATED_BY
                    , sysdate                               -- LAST_UPDATE_DATE
                    , fnd_global.login_id                   -- LAST_UPDATE_LOGIN
                    , v_trxs_tbl(i).purchase_order          -- PURCHASE_ORDER
                    , v_trxs_tbl(i).request_number          -- REQUEST_NUMBER
                    , v_order_source                        -- ORDER_SOURCE
                    , v_orig_sys_document_ref               -- ORIG_SYS_DOCUMENT_REF
                    , v_trxs_tbl(i).collection_type         -- COLLECTION_TYPE
                    , v_trxs_tbl(i).document_type           -- DOCUMENT_TYPE
                    , v_trxs_tbl(i).customer_email          -- EMAIL
                    , v_trxs_tbl(i).source_system_number    -- SOURCE_SYSTEM_NUMBER
                    , v_trxs_tbl(i).legal_entity_name       -- LEGAL_ENTITY
                    , v_trxs_tbl(i).legal_entity_id         -- LEGAL_ENTITY_CODE
                    , fnd_global.conc_request_id            -- REQUEST_ID
                    , v_stmt_source                         -- STMT_SOURCE
                    , v_hotel_stmt_trx_number               -- HOTEL_STMT_TRX_NUMBER
                    , p_territory_code                      -- ATTRIBUTE_CATEGORY
                    , v_trxs_tbl(i).electr_doc_type         -- ATTRIBUTE1
                    , v_trxs_tbl(i).legal_entity_identifier -- ATTRIBUTE2
                    , v_trxs_tbl(i).doc_sequence_value||
                      lpad(v_trxs_tbl(i).trx_number, 13 - length(v_trxs_tbl(i).doc_sequence_value), '0') -- ATTRIBUTE3
                    , 'TKT_FLG'                             -- ATTRIBUTE4 --Agregado para tickets
                    , null                                  -- ATTRIBUTE5
                    , null                                  -- ATTRIBUTE6
                    , null                                  -- ATTRIBUTE7
                    , null                                  -- ATTRIBUTE8
                    , null                                  -- ATTRIBUTE9
                    , null                                  -- ATTRIBUTE10
                    , v_trxs_tbl(i).net_amount              -- NET_AMOUNT
                    , v_trxs_tbl(i).net_amount_pcc          -- NET_AMOUNT_PCC
                    , v_trxs_tbl(i).tax_amount              -- TAX_AMOUNT
                    , v_trxs_tbl(i).tax_amount_pcc          -- TAX_AMOUNT_PCC
                    , v_trxs_tbl(i).total_amount            -- TOTAL_AMOUNT
                    , v_trxs_tbl(i).total_amount_pcc        -- TOTAL_AMOUNT_PCC
                    , v_trxs_tbl(i).trx_date                -- TRX_DATE
                    , v_trxs_tbl(i).collection_country      -- COLLECTION_COUNTRY
                    , v_month_billed                        -- MONTH_BILLED
                    , v_trxs_tbl(i).invoice_currency_code   -- INVOICE_CURRENCY_CODE
                    , v_trxs_tbl(i).printing_currency_code  -- PRINTING_CURRENCY_CODE
                    );
            exception
              when dup_val_on_index then
                update xx_ar_reg_invoice_request
                   set trx_number_ori = v_trxs_tbl(i).trx_number
                    , reference = nvl(v_trxs_tbl(i).customer_name, 'NO INFORMADO')
                    , receive_date = null
                    , trx_number_new = null
                    , link = null
                    , cae = null
                    , fecha_cae = null
                    , file_name = v_trxs_tbl(i).output_file
                    , status = decode(v_trxs_tbl(i).status
                                     ,'ERROR','PROCESSING_ERROR_ORACLE'
                    --               ,'NEW')
                                     ,'WORK_IN_PROGRESS')  -- STATUS
                    , error_code = v_trxs_tbl(i).error_code
                    , error_messages = v_trxs_tbl(i).error_messages
                    , last_updated_by = fnd_global.user_id
                    , last_update_date = sysdate
                    , last_update_login = fnd_global.login_id
                    , purchase_order = v_trxs_tbl(i).purchase_order
                    , request_number = v_trxs_tbl(i).request_number
                    , order_source = v_order_source
                    , orig_sys_document_ref = v_orig_sys_document_ref
                    , collection_type = v_trxs_tbl(i).collection_type
                    , document_type = v_trxs_tbl(i).document_type
                    , email = v_trxs_tbl(i).customer_email
                    , source_system_number = v_trxs_tbl(i).source_system_number
                    , legal_entity = v_trxs_tbl(i).legal_entity_name
                    , legal_entity_code = v_trxs_tbl(i).legal_entity_id
                    , request_id = fnd_global.conc_request_id
                    , stmt_source = v_stmt_source
                    , hotel_stmt_trx_number = v_hotel_stmt_trx_number
                    , attribute_category = p_territory_code
                    , attribute1 = v_trxs_tbl(i).electr_doc_type
                    , attribute2 = v_trxs_tbl(i).legal_entity_identifier
                    , attribute3 = v_trxs_tbl(i).doc_sequence_value||lpad(v_trxs_tbl(i).trx_number, 13 - length(v_trxs_tbl(i).doc_sequence_value), '0')
                    , attribute4 = null
                    , attribute5 = null
                    , attribute6 = null
                    , attribute7 = null
                    , attribute8 = null
                    , attribute9 = null
                    , attribute10 = null
                    , net_amount = v_trxs_tbl(i).net_amount
                    , net_amount_pcc =v_trxs_tbl(i).net_amount_pcc
                    , tax_amount = v_trxs_tbl(i).tax_amount
                    , tax_amount_pcc = v_trxs_tbl(i).tax_amount_pcc
                    , total_amount = v_trxs_tbl(i).total_amount
                    , total_amount_pcc = v_trxs_tbl(i).total_amount_pcc
                    , trx_date = v_trxs_tbl(i).trx_date
                    , collection_country = v_trxs_tbl(i).collection_country
                    , month_billed = v_month_billed
                    , invoice_currency_code = v_trxs_tbl(i).invoice_currency_code
                    , printing_currency_code = v_trxs_tbl(i).printing_currency_code
                where v_trxs_tbl(i).customer_trx_id = customer_trx_id;
            end;

        end loop;
        if upper(nvl(p_draft_mode,'N')) = 'N' then
            debug(g_indent              ||
                  v_calling_sequence    ||
                  '. Realizando commit'
                 ,'1'
                 );
            commit;
        else
            debug(g_indent                ||
                  v_calling_sequence      ||
                  '. Realizando rollback'
                  ,'1'
                 );
            rollback;
        end if;
        -- Luego de inserta dispara el bursting
        if v_success_qty > 0 then
                fnd_file.put_line(fnd_file.log, 'dispara bursting');
                l_request_id := fnd_request.submit_request(application => 'XDO'
                                                          ,program     => 'XDOBURSTREP'
                                                          ,description =>  null
                                                          ,start_time  =>  null
                                                          ,sub_request =>  false
                                                          ,argument1   =>  null
                                                          ,argument2   =>  v_request_id
                                                          ,argument3   =>  'Y');
                commit;
            if l_request_id != 0 then
                l_result := true;
                fnd_file.put_line(fnd_file.log, 'id bursting:'||l_request_id);
                /*
                lb_complete := fnd_concurrent.wait_for_request (request_id   => l_request_id,
                                                INTERVAL     => 10,
                                                max_wait     => 3000,
                                                phase        => lc_phase,
                                                status       => lc_status,
                                                dev_phase    => lc_dev_phase,
                                                dev_status   => lc_dev_status,
                                                MESSAGE      => lc_message);
                 */
            else
             -- Put message in log
             fnd_file.put_line(fnd_file.log, 'Failed to launch bursting request');
             update xx_ar_reg_invoice_request
               set  status = 'PROCESSING_ERROR_ORACLE',
                    error_code = '040_FILE_GENERATION_PROBLEM',
                    error_messages = 'Error al disparar la solicitud de generacion de archivo'
              where request_id = fnd_global.conc_request_id 
               and  status = 'WORK_IN_PROGRESS';
            end if;
      end if;
    end if;
    -- ---------------------------------------------------------------------------
    -- Verifico si se produjo un error.
    -- ---------------------------------------------------------------------------
    if v_mesg_error is not null        and
       v_mesg_error != 'NO_DATA_FOUND' then
        debug(g_indent           ||
              v_calling_sequence ||
              '. '               ||
              v_mesg_error
             ,'1'
             );
        fnd_file.put(fnd_file.log
                    ,g_indent           ||
                     v_calling_sequence ||
                     '. '               ||
                     v_mesg_error
                    );
        fnd_file.new_line(fnd_file.log, 1);
        debug(g_indent                ||
              v_calling_sequence      ||
              '. Realizando rollback'
             ,'1'
             );
        rollback;
        retcode := '2';
        errbuf  := substr(v_mesg_error,1,2000);
    else
        if upper(nvl(p_draft_mode,'N')) = 'N' then
            debug(g_indent              ||
                  v_calling_sequence    ||
                  '. Realizando commit'
                 ,'1'
                 );
            commit;
        else
            debug(g_indent                ||
                  v_calling_sequence      ||
                  '. Realizando rollback'
                  ,'1'
                 );
            rollback;
        end if;
    retcode := '0';
    end if;

    fnd_file.put(fnd_file.log, '---------------------------------------------------------------------');
    fnd_file.new_line(fnd_file.log, 1);
    fnd_file.put(fnd_file.log, ' Registros procesados exitosamente: '||v_success_qty);
    fnd_file.new_line(fnd_file.log, 1);
    fnd_file.put(fnd_file.log, ' Registros procesados con error   : '||v_error_qty);
    fnd_file.new_line(fnd_file.log, 1);
    fnd_file.put(fnd_file.log, '---------------------------------------------------------------------');
    fnd_file.new_line(fnd_file.log, 1);

    debug(g_indent           ||
          v_calling_sequence ||
          '. Fin de proceso'
         ,'1'
         );

exception
    when others then
        v_mesg_error := 'Error general generando factura electronica. ' ||
                        sqlerrm;
        debug(v_calling_sequence ||
              '. '               ||
              v_mesg_error
             ,'1'
             );
        fnd_file.put(fnd_file.log
                    ,g_indent           ||
                     v_calling_sequence ||
                     '. '               ||
                     v_mesg_error
                     );
        fnd_file.new_line(fnd_file.log, 1);
        retcode := '2';
        errbuf  := substr(v_mesg_error, 1, 2000);
end generate_files;
/*=========================================================================+
|                                                                          |
| Public Procedure                                                         |
|    validate_files                                                        |
|                                                                          |
| Description                                                              |
|    Procedimiento que valida la generacion de archivos y ajusta estado.   |
|                                                                          |
| Parameters                                                               |
|    errbuf            OUT VARCHAR2 Uso interno del concurrente.           |
|    retcode           OUT VARCHAR2 Uso interno del concurrente.           |
|    p_draft_mode      IN  VARCHAR2 Modo draft (Y/N).                      |
|    p_debug_flag      IN  VARCHAR2 Flag de debug.                         |
|                                                                          |
+=========================================================================*/
procedure validate_files(errbuf            out varchar2
                        ,retcode           out number
                        ,p_draft_mode      in  varchar2)
is
  cursor c_xx_ar_reg_invoice_request(p_req_id number)
  is
  select rowid
        ,customer_trx_id
        ,file_name
  from   xx_ar_reg_invoice_request
  where  status  = 'WORK_IN_PROGRESS'
  and    request_id = p_req_id;
  xx_ar_reg_invoice_request_type c_xx_ar_reg_invoice_request%rowtype;
  v_exists                       varchar2(1);
  v_directory_path               varchar2(100);
  l_gen_file_req_id              number;
  l_bursting_request_id          number;
  lb_complete                    boolean;
  lc_phase                       varchar2 (100);
  lc_status                      varchar2 (100);
  lc_dev_phase                   varchar2 (100);
  lc_dev_status                  varchar2 (100);
  lc_message                     varchar2 (100);
begin
  fnd_file.put_line (fnd_file.log, 'p_draft_mode = '||p_draft_mode);
  select directory_path
  into   v_directory_path
  from   all_directories
  where  directory_name = 'XX_AR_TRX_PE_OUT_PRC_DIR';
  /* get bursting request_id */
  select fcr1.request_id
        ,fcr2.request_id
  into   l_gen_file_req_id
        ,l_bursting_request_id
  from   fnd_concurrent_requests    fcr1 -- XXARCOFEG
        ,fnd_concurrent_programs_vl fcpv
        ,fnd_concurrent_requests    fcr2 --  XDOBURSTREP
        ,fnd_concurrent_requests    fcr  -- XXARCOFEV
  where  fcr.request_id               = fnd_global.conc_request_id
  and    fcr1.priority_request_id     = fcr.priority_request_id
  and    fcpv.concurrent_program_id   = fcr1.concurrent_program_id
  and    fcpv.concurrent_program_name = 'XXARPETRXP'
  and    fcr2.parent_request_id       = fcr1.request_id;
  fnd_file.put_line (fnd_file.log, 'l_bursting_request_id : '||l_bursting_request_id);
  lc_dev_phase := 'X';
  while (upper (lc_dev_phase) != 'COMPLETE')
  loop
    lb_complete := fnd_concurrent.wait_for_request(request_id      => l_bursting_request_id
                                                  ,interval        => 2
                                                  ,max_wait        => 60
                                                  -- out arguments
                                                  ,phase           => lc_phase
                                                  ,status          => lc_status
                                                  ,dev_phase       => lc_dev_phase
                                                  ,dev_status      => lc_dev_status
                                                  ,message         => lc_message);
    fnd_file.put_line (fnd_file.log, 'Bursting Concurrent request completed');
  end loop;
  open c_xx_ar_reg_invoice_request(l_gen_file_req_id);
  loop fetch c_xx_ar_reg_invoice_request into xx_ar_reg_invoice_request_type;
  exit when c_xx_ar_reg_invoice_request%notfound;
    -- Chequea archivo generado y marca comprobante como impreso
    if upper(nvl(p_draft_mode,'N')) = 'N' then
      v_exists := xx_ar_fe_file_manager_pk.exists(v_directory_path||'/'||xx_ar_reg_invoice_request_type.file_name);
      if v_exists = 'Y' then
        update xx_ar_reg_invoice_request
        set    status = 'PICKED_OK_ORACLE'
        where  request_id      = l_gen_file_req_id
        and    status          = 'WORK_IN_PROGRESS'
        and    customer_trx_id = xx_ar_reg_invoice_request_type.customer_trx_id;
        update ra_customer_trx_all rct
        set    rct.attribute9       = 'Y'
        where  rct.customer_trx_id = xx_ar_reg_invoice_request_type.customer_trx_id;
      else
        update xx_ar_reg_invoice_request
        set    status = 'PROCESSING_ERROR_ORACLE'
              ,error_code = '040_FILE_GENERATION_PROBLEM'
              ,error_messages = 'No se encuentra el archivo generado en el servidor '||xx_ar_reg_invoice_request_type.file_name
        where  request_id = l_gen_file_req_id
        and    status = 'WORK_IN_PROGRESS'
        and    customer_trx_id = xx_ar_reg_invoice_request_type.customer_trx_id;
      end if;
    end if;
  end loop;
  commit;
exception
  when others then
    fnd_file.put_line (fnd_file.log, 'Error : ' || sqlerrm);
end validate_files;
end xx_ar_trx_pe_sends_pk;
/

show errors;

spool off;

exit;
