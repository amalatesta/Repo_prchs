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
rem |    basado en el paquete xx_ar_fe_co_sends_pk.                         |
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

spool XX_AR_TRX_PE_SENDSB_PK.log

prompt =====================================================================
prompt script XX_AR_TRX_PE_SENDSB_PK.sql
prompt =====================================================================

prompt creando cuerpo paquete xx_ar_trx_pe_sends_pk

create or replace package body apps.xx_ar_trx_pe_sends_pk as
/* $Id: XX_AR_TRX_PE_SENDSB_PK.sql 1 2017-05-21 20:46:37 amalatesta@despegar.com $ */
  -- Variables globales
  g_eol                varchar2(2)  := chr(10);
  g_func_currency_code varchar2(3)  := 'PEN';
  g_func_currency_desc varchar2(30) := 'SOLES';
  --g_co_inv_org_id      number       := 221;
  g_num_format         varchar2(99) := '9999999999999999999999999999999999999999999999990.99';
  g_vat_tax            varchar2(240):= 'PE IVA AR';
  g_detraction_amount  number;

  cursor c_trxs (p_cust_trx_type_id in number
                ,p_trx_number_from  in varchar2
                ,p_trx_number_to    in varchar2
                ,p_date_from        in date
                ,p_date_to          in date
                ,p_draft_mode       in varchar2)
  is
    select rct.customer_trx_id
          ,'XX_AR_FE_PE_OUT_PRC_DIR'                            tmp_output_directory
          ,lpad(rct.customer_trx_id,15,'0')|| '.tmp'            tmp_output_file
          ,'XX_AR_FE_PE_OUT_PRC_DIR'                            output_directory
          ,lpad(rct.customer_trx_id,15,'0')|| '.txt'            output_file
          ,rct.trx_number                                       trx_number
          ,rct.org_id                                           rct_org_id
          ,to_char(rct.trx_date,'DD/MM/YYYY')                   trx_date
          ,hca.orig_system_reference                            source_system_number
          ,nvl(hca.attribute20,'N')                             generic_customer
          ,hca.party_id                                         party_id
          ,hca.cust_account_id                                  cust_account_id
          ,replace(replace(rct.attribute1,'|',''),'  ',' ')     customer_name
          ,substr(rct.attribute2,1,instr(rct.attribute2,'|')-1) customer_doc_type
          ,nvl(substr(rct.attribute2,instr(rct.attribute2,'|') + 1)
              ,rct.attribute2)                                  customer_doc_number
          ,rct.attribute12                                      customer_country_name
          ,rct.attribute11                                      customer_address
          ,rct.attribute3                                       customer_email
          ,rct.attribute4                                       request_number
          ,rct.attribute13                                      purchase_order
          ,rct.attribute15                                      -- se usa para calcular exchange_rate,line_amount y tax_amount
          ,rbs.batch_source_type                                batch_source_type
          ,rct.purchase_order                                   hotel_stmt_trx_number
          ,rct.comments                                         comments
          ,rct.invoice_currency_code                            currency_code
          ,rct.invoice_currency_code                            original_currency_code
          ,rct.doc_sequence_value                               doc_sequence_value
          ,nvl(rct.exchange_rate,1)                             exchange_rate
          ,rct.bill_to_site_use_id                              bill_to_site_use_id
          ,rctt.type                                            document_type
          ,decode(rctt.type
                 ,'INV','Factura de Venta'
                 ,'Nota de Credito')                            doc_type_display
          ,rctt.name                                            cust_trx_type_name
          ,rctt.attribute1                                      cust_trx_concept
          ,rctt.attribute2                                      collection_type
          ,nvl(rctt.attribute15,'DEFAULT')                      cust_trx_tipo
          ,rctt.description                                     cust_trx_desc
          ,rct.legal_entity_id                                  legal_entity_id
          ,xep.name                                             legal_entity_name
          ,substr(xep.legal_entity_identifier,1,length(xep.legal_entity_identifier)-1)
                ||'-'||substr(xep.legal_entity_identifier,length(xep.legal_entity_identifier)) registration_number
          ,hl_org.address_line_1
           ||' '||hl_org.address_line_2
           ||' '||hl_org.address_line_3                         org_address_line1
          ,hl_org.region_1                                      org_address_line2
          ,hl_org.postal_code                                   org_postal_code
          ,hl_org.telephone_number_1                            org_telephone_number_1
          ,hl_org.telephone_number_2                            org_telephone_number_2
          ,hl_org.town_or_city                                  org_expedition_place
          ,hl_org.country                                       org_country
          ,doc_dfv.xx_ff_co_inicio                              ff_valor_inicial
          ,doc_dfv.xx_ff_co_final                               ff_valor_final
          ,doc_dfv.xx_ff_legal_message                          ff_legal_message
          ,xarir.status                                         status
          ,xarir.error_code                                     error_code
          ,xarir.error_messages                                 error_messages
          ,rct.status_trx                                       status_trx
          ,empty_clob()                                         send_file
    from   ra_customer_trx            rct
          ,ra_cust_trx_types          rctt
          ,ra_batch_sources           rbs
          ,xx_ar_reg_invoice_request  xarir
          ,hz_cust_accounts           hca
          ,xle_entity_profiles        xep
          ,hr_organization_units      hou
          ,hr_locations               hl_org
          ,fnd_document_sequences_dfv doc_dfv
          ,fnd_document_sequences     doc
    where  rct.org_id              = hou.organization_id
    and    rct.cust_trx_type_id    = rctt.cust_trx_type_id
    and    hou.location_id         = hl_org.location_id
    and    rct.bill_to_customer_id = hca.cust_account_id
    and    rct.legal_entity_id     = xep.legal_entity_id
    and    rct.doc_sequence_id     = doc.doc_sequence_id(+)
    and    doc.rowid               = doc_dfv.row_id(+)
    and    rct.batch_source_id     = rbs.batch_source_id
    and    rct.customer_trx_id     = xarir.customer_trx_id (+)
    and    nvl(xarir.status,'@')   in ('@','PROCESSING_ERROR_ORACLE')
    and    rct.complete_flag       = 'Y'
    and    nvl(rct.attribute9,'N') = 'N'
    and    rctt.attribute12        = 'Y'
    and    p_draft_mode            = 'N'
    and    rct.cust_trx_type_id    = nvl(p_cust_trx_type_id,rct.cust_trx_type_id)
    and    rct.trx_date between nvl(trunc(p_date_from),rct.trx_date)
                        and nvl(trunc(p_date_to + 1) - 1 / 24 / 60 / 60,rct.trx_date)
    and    rct.trx_number between nvl(p_trx_number_from,rct.trx_number)
                          and nvl(p_trx_number_to,rct.trx_number)
    union all
    select rct.customer_trx_id
          ,'XX_AR_FE_PE_OUT_PRC_DIR'                            tmp_output_directory
          ,lpad(rct.customer_trx_id,15,'0')|| '.tmp'            tmp_output_file
          ,'XX_AR_FE_PE_OUT_PRC_DIR'                            output_directory
          ,lpad(rct.customer_trx_id,15,'0')|| '.txt'            output_file
          ,rct.trx_number                                       trx_number
          ,rct.org_id                                           rct_org_id
          ,to_char(rct.trx_date,'DD/MM/YYYY')                   trx_date
          ,hca.orig_system_reference                            source_system_number
          ,nvl(hca.attribute20,'N')                             generic_customer
          ,hca.party_id                                         party_id
          ,hca.cust_account_id                                  cust_account_id
          ,replace(replace(rct.attribute1,'|',''),'  ',' ')     customer_name
          ,substr(rct.attribute2,1,instr(rct.attribute2,'|')-1) customer_doc_type
          ,nvl(substr(rct.attribute2,instr(rct.attribute2,'|') + 1)
              ,rct.attribute2)                                  customer_doc_number
          ,rct.attribute12                                      customer_country_name
          ,rct.attribute11                                      customer_address
          ,rct.attribute3                                       customer_email
          ,rct.attribute4                                       request_number
          ,rct.attribute13                                      purchase_order
          ,rct.attribute15                                      -- se usa para calcular exchange_rate,line_amount y tax_amount
          ,rbs.batch_source_type                                batch_source_type
          ,rct.purchase_order                                   hotel_stmt_trx_number
          ,rct.comments                                         comments
          ,rct.invoice_currency_code                            currency_code
          ,rct.invoice_currency_code                            original_currency_code
          ,rct.doc_sequence_value                               doc_sequence_value
          ,nvl(rct.exchange_rate,1)                             exchange_rate
          ,rct.bill_to_site_use_id                              bill_to_site_use_id
          ,rctt.type                                            document_type
          ,decode(rctt.type
                 ,'INV','Factura de Venta'
                 ,'Nota de Credito')                            doc_type_display
          ,rctt.name                                            cust_trx_type_name
          ,rctt.attribute1                                      cust_trx_concept
          ,rctt.attribute2                                      collection_type
          ,nvl(rctt.attribute15,'DEFAULT')                      cust_trx_tipo
          ,rctt.description                                     cust_trx_desc
          ,rct.legal_entity_id                                  legal_entity_id
          ,xep.name                                             legal_entity_name
          ,substr(xep.legal_entity_identifier,1,length(xep.legal_entity_identifier)-1)
                ||'-'||substr(xep.legal_entity_identifier,length(xep.legal_entity_identifier)) registration_number
          ,hl_org.address_line_1
           ||' '||hl_org.address_line_2
           ||' '||hl_org.address_line_3                         org_address_line1
          ,hl_org.region_1                                      org_address_line2
          ,hl_org.postal_code                                   org_postal_code
          ,hl_org.telephone_number_1                            org_telephone_number_1
          ,hl_org.telephone_number_2                            org_telephone_number_2
          ,hl_org.town_or_city                                  org_expedition_place
          ,hl_org.country                                       org_country
          ,doc_dfv.xx_ff_co_inicio                              ff_valor_inicial
          ,doc_dfv.xx_ff_co_final                               ff_valor_final
          ,doc_dfv.xx_ff_legal_message                          ff_legal_message
          ,xarir.status                                         status
          ,xarir.error_code                                     error_code
          ,xarir.error_messages                                 error_messages
          ,rct.status_trx                                       status_trx
          ,empty_clob()                                         send_file
    from   ra_customer_trx            rct
          ,ra_cust_trx_types          rctt
          ,ra_batch_sources           rbs
          ,xx_ar_reg_invoice_request  xarir
          ,hz_cust_accounts           hca
          ,xle_entity_profiles        xep
          ,hr_organization_units      hou
          ,hr_locations               hl_org
          ,fnd_document_sequences_dfv doc_dfv
          ,fnd_document_sequences     doc
    where  rct.org_id              = hou.organization_id
    and    hou.location_id         = hl_org.location_id
    and    rct.bill_to_customer_id = hca.cust_account_id
    and    rct.legal_entity_id     = xep.legal_entity_id
    and    rct.doc_sequence_id     = doc.doc_sequence_id (+)
    and    doc.rowid               = doc_dfv.row_id (+)
    and    rct.batch_source_id     = rbs.batch_source_id
    and    rct.customer_trx_id     = xarir.customer_trx_id (+)
    and    rct.cust_trx_type_id    = rctt.cust_trx_type_id
    and    rct.complete_flag       = 'Y'
    and    rctt.attribute12        = 'Y'
    and    p_draft_mode            = 'Y'
    and    rct.cust_trx_type_id    = nvl(p_cust_trx_type_id,rct.cust_trx_type_id)
    and    rct.trx_date between nvl(trunc(p_date_from),rct.trx_date)
                        and     nvl(trunc(p_date_to + 1) - 1 / 24 / 60 / 60,rct.trx_date)
    and    rct.trx_number between p_trx_number_from
                          and     p_trx_number_to; -- Con draft mode son obligatorios
  type trx_table_type is table of c_trxs%rowtype index by binary_integer;
  v_trxs_tbl     trx_table_type;
  v_trxs_aux_tbl trx_table_type;
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
procedure indent(p_type in varchar2)
is
  v_calling_sequence varchar2(2000);
  v_indent_length    number(15);
begin
  v_calling_sequence := 'XX_AR_TRX_PE_SENDSB_PK.INDENT';
  v_indent_length    := 3;
  if p_type = '+' then
    g_indent := replace(rpad(' ',nvl(length(g_indent),0)+v_indent_length),' ',' ');
  elsif p_type = '-' then
    g_indent := replace(rpad(' ',nvl(length(g_indent),0)-v_indent_length),' ',' ');
  end if;
exception
  when others then
    raise_application_error(-20000
                           ,v_calling_sequence
                           ||'. Error general indentando linea. '
                           ||sqlerrm);
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
                               ,p_message in      varchar2)
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
  v_calling_sequence := 'XX_AR_TRX_PE_SENDSB_PK.DISPLAY_MESSAGE_SPLIT';
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
            fnd_file.put(fnd_file.log
                        ,v_message);
            fnd_file.new_line(fnd_file.log,1);
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
procedure debug(p_message in varchar2
               ,p_type    in varchar2 default null)
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
  v_calling_sequence := 'XX_AR_TRX_PE_SENDSB_PK.DEBUG';
  -- ---------------------------------------------------------------------------
  -- Realizo el debug.
  -- ---------------------------------------------------------------------------
  if g_debug_flag = 'Y' then
    if p_type is null then
      v_message := substr(p_message,1,32767);
    else
      v_message := substr(to_char(sysdate,'DD-MM-YYYY HH24:MI:SS')||' - '||p_message,1,32767);
    end if;
    display_message_split(p_output  => g_debug_mode
                         ,p_message => v_message);
  end if;
exception
  when others then
    null;
end debug;
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
function get_inventory_item_desc(p_oe_line_id        in  varchar2
                                ,p_origen            in  varchar2
                                ,p_customer_trx_id   in  number
                                ,p_trx_type          in  varchar2
                                ,p_organization_id   in  number
                                ,p_inventory_item_id in  number
                                ,p_cust_trx_concept  in  varchar2
                                ,p_rfc               in  varchar2)
return varchar2
is
  v_item_desc varchar2(2000) := null;
  v_count     number         := 0;
begin
  if p_origen = 'FOREIGN' and p_oe_line_id is null then
    return v_item_desc;
  end if;
  if p_trx_type = 'CM' then
    select count(*)
    into   v_count
    from   mtl_item_categories   mic
          ,mtl_category_sets     mcs
          ,mtl_categories        mc
          ,ra_customer_trx_lines rctl
    where  rctl.customer_trx_id  = p_customer_trx_id
    and    mic.inventory_item_id = rctl.inventory_item_id
    and    mic.organization_id   = p_organization_id
    and    mcs.category_set_name = 'XX_AR_FE_LINE_TYPE'
    and    mcs.category_set_id   = mic.category_set_id
    and    mc.category_id        = mic.category_id
    and    mc.segment1           = 'DISCOUNT';
    if v_count != 0 then
      v_item_desc := 'Descuentos ';
      return v_item_desc;
    end if;
  end if;
  begin
    select mc.description
    into   v_item_desc
    from   mtl_item_categories     mic
          ,mtl_category_sets       mcs
          ,mtl_categories          mc
    where  mic.inventory_item_id = p_inventory_item_id
    and    mic.organization_id   = p_organization_id
    and    mcs.category_set_name = 'XX_DESCR_ARTICULO'
    and    mcs.category_set_id   = mic.category_set_id
    and    mc.category_id        = mic.category_id;
  exception
    when no_data_found then
      if (v_item_desc is null) then
        v_item_desc := p_cust_trx_concept;
      end if;
  end;
  -- Si no se obtuvo descripcion, no se concatena RFC
  if (v_item_desc is not null) then
    if (p_rfc is not null) then
      v_item_desc := v_item_desc ||' '||substr(p_rfc, 1, length(p_rfc) - 1)||'-'||substr(p_rfc, length(p_rfc));
    end if;
  end if;
  return v_item_desc;
exception
  when others then
    return null;
end get_inventory_item_desc;
/*=========================================================================+
|                                                                          |
| Private Function                                                         |
|    Get_supplier_name                                                     |
|                                                                          |
| Description                                                              |
|    Funcion privada que busca nombre de proveedor                         |
|                                                                          |
| Parameters                                                               |
|    p_nit    IN  VARCHAR2                                                 |
|    p_org_id IN  NUMBER                                                   |
|                                                                          |
+=========================================================================*/
function get_supplier_name(p_nit    in varchar2
                          ,p_org_id in number)
return varchar2
is
  v_supp_name ap_suppliers.vendor_name%type;
  v_count     number := 0;
begin
  if p_nit is not null then
    begin
      select vendor_name
      into   v_supp_name
      from   ap_suppliers          ap
            ,ap_supplier_sites_all aps
      where  ap.num_1099 like substr(p_nit, 1, length(p_nit) - 1)||'%'
      and    (   p_nit = trim(ap.num_1099 || nvl(ap.global_attribute12, ' '))
              or p_nit = ap.num_1099)
      and    ap.vendor_id = aps.vendor_id
      and    aps.org_id = p_org_id
      and rownum = 1;
      return(v_supp_name);
    exception
      when no_data_found then
        begin
          select vendor_name
          into   v_supp_name
          from   ap_suppliers
          where  num_1099 = p_nit
          and    rownum = 1;
          return(v_supp_name);
        exception
          when others then
            return null;
        end;
    when others then
      return null;
    end;
  else
    return null;
  end if;
exception
  when others then
    return null;
end get_supplier_name;
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
function print_text(p_print_output in  varchar2
                   ,p_mesg_error   out varchar2)
return boolean
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
  v_calling_sequence := 'XX_AR_TRX_PE_SENDSB_PK.PRINT_TEXT';
  debug(g_indent||v_calling_sequence,'1');
  -- ---------------------------------------------------------------------------
  -- Despliego Parametros.
  -- ---------------------------------------------------------------------------
   debug(g_indent
       ||v_calling_sequence
       ||'. Imprime interface en la salida del concurrente: '
       ||p_print_output,'1');
  -- ---------------------------------------------------------------------------
  -- Recorro la salida de interface.
  -- ---------------------------------------------------------------------------
  debug(g_indent
      ||v_calling_sequence
      ||'. Recorriendo la salida de interface','1');
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
      if   nvl(v_trxs_tbl(i).output_directory,'@') != nvl(v_output_directory ,'@')
        or nvl(v_trxs_tbl(i).output_file ,'@')     != nvl(v_output_file      ,'@') then
        -- -----------------------------------------------------------------
        -- Verifico si el archivo de salida anterior esta abierto.
        -- -----------------------------------------------------------------
        if utl_file.is_open(v_file) then
          fnd_file.put(fnd_file.log,'Se genero el archivo de salida: '||v_output_file
                     ||' en el directorio: '||v_output_directory);
          fnd_file.new_line(fnd_file.log,1);
          debug(g_indent
              ||v_calling_sequence
              ||'. Cerrando archivo de salida: '||v_output_file
              ||' en el directorio: '||v_output_directory,'1');
          begin
            utl_file.fclose(v_file);
          exception
            when others then
              p_mesg_error := v_calling_sequence
                            ||'. Error cerrando archivo de salida: '||v_output_file
                            ||' en el directorio: '||v_output_directory||'. '||sqlerrm;
              exit;
          end;
        end if;
        -- -----------------------------------------------------------------
        -- Verifico si hay que generar un nuevo archivo de salida.
        -- -----------------------------------------------------------------
        if    v_trxs_tbl(i).output_directory is not null
          and v_trxs_tbl(i).output_file is not null
          and v_trxs_tbl(i).status = 'NEW' then
          -- --------------------------------------------------------------
          -- Genero el nuevo archivo de salida.
          -- --------------------------------------------------------------
          debug(g_indent
              ||v_calling_sequence
              ||'. Generando archivo de salida: ' ||v_trxs_tbl(i).output_file
              ||' en el directorio: '||v_trxs_tbl(i).output_directory,'1');
          begin
            v_file := utl_file.fopen(v_trxs_tbl(i).output_directory,v_trxs_tbl(i).output_file,'w');
          exception
            when e_invalid_directory then
              p_mesg_error := 'Directorio de salida invalido: '||v_trxs_tbl(i).output_directory;
              exit;
          when e_invalid_file_name then
            p_mesg_error := 'Archivo de salida invalido: '||v_trxs_tbl(i).output_file;
            exit;
          when others then
            p_mesg_error := 'Error generando archivo de salida: '||v_trxs_tbl(i).output_file
                          ||' en el directorio: '||v_trxs_tbl(i).output_directory
                          ||'. '||sqlerrm;
            exit;
          end;
        end if;
      end if;
      -- --------------------------------------------------------------------
      -- Verifico si hay que imprimir el texto en el archivo de salida.
      -- --------------------------------------------------------------------
      if    v_trxs_tbl(i).output_directory is not null
        and v_trxs_tbl(i).output_file is not null
        and v_trxs_tbl(i).status = 'NEW' then
        -- -----------------------------------------------------------------
        -- Imprimo el texto en el archivo de salida.
        -- -----------------------------------------------------------------
        begin
          debug(g_indent
              ||v_calling_sequence
              ||'. Leyendo lob','1');
          v_amount := 2000;
          if (dbms_lob.getlength(v_trxs_tbl(i).send_file) != 0) then
            dbms_lob.read(v_trxs_tbl(i).send_file, v_amount, 1, v_text1);
          end if;
          debug(g_indent
              ||v_calling_sequence
              ||'. v_text1: '||v_text1,'1');
          if (dbms_lob.getlength(v_trxs_tbl(i).send_file) > 2000) then
            dbms_lob.read(v_trxs_tbl(i).send_file, v_amount, 2001, v_text2);
          end if;
          if (dbms_lob.getlength(v_trxs_tbl(i).send_file) > 4000) then
            dbms_lob.read(v_trxs_tbl(i).send_file, v_amount, 4001, v_text3);
          end if;
          utl_file.put_line(v_file,v_text1||v_text2||v_text3);
          utl_file.fflush(v_file);
        exception
          when others then
            p_mesg_error := v_calling_sequence
                         ||'. Error imprimiendo texto en el archivo de salida: '||v_trxs_tbl(i).output_file
                         ||' en el directorio: '||v_trxs_tbl(i).output_directory||'. '||sqlerrm;
            exit;
        end;
      end if;
    else
    -- -----------------------------------------------------------------
    -- Imprimo el texto en la salida del concurrente.
    -- -----------------------------------------------------------------
    begin
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
    /*
    fnd_file.put(fnd_file.output
    ,'Numero Factura: ' || v_trxs_tbl(i).trx_number
    );
    */
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
    fnd_file.new_line(fnd_file.output
    ,1
    );
    
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
|    p_date_from       IN  DATE     Fecha desde.                           |
|    p_date_to         IN  DATE     Fecha hasta.                           |
|    p_trx_number_from IN  VARCHAR2 Numero de Transaccion desde.           |
|    p_trx_number_to   IN  VARCHAR2 Numero de Transaccion hasta.           |
|    p_territory_code  IN  VARCHAR2 Pa�s.                                  |
|                                                                          |
+=========================================================================*/
procedure generate_files(errbuf            out varchar2
                        ,retcode           out number
                        ,p_draft_mode      in  varchar2
                        ,p_debug_flag      in  varchar2
                        ,p_cust_trx_type   in  number
                        ,p_date_from       in  varchar2
                        ,p_date_to         in  varchar2
                        ,p_trx_number_from in  varchar2
                        ,p_trx_number_to   in  varchar2
                        ,p_territory_code  in  varchar2
                        )
is

    -- ---------------------------------------------------------------------------
    -- Definicion de Variables
    -- ---------------------------------------------------------------------------
    v_calling_sequence        varchar2(2000);
    v_request_id              number(15);
    v_mesg_error              varchar2(32767);
    v_order_source            oe_order_sources.name%type;
    v_orig_sys_document_ref   oe_order_headers.orig_sys_document_ref%type;
    v_stmt_source             xx_ap_hotel_statements_hdr.stmt_source%type;
    v_hotel_stmt_trx_number   xx_ap_hotel_statements_hdr.hotel_stmt_trx_number%type;
    v_send_file               clob;
    v_send_line               varchar2(4000);
    v_sub_tot                 number;
    v_subtotal                number;
    v_subtot_sintax           number;
    v_total                   number;
    v_total_in_words          varchar2(4000);
    v_vat_translated_amount   number;
    v_other_translated_amount number;
    v_vat_id                  number;
    v_org_id                  number;
    v_sub_ter_otros           number;
    v_sub_ter_vat             number;
    v_sub_ter_imp             number;
    v_sub_rentas              number;
    v_sub_retica              number;
    v_sub_retiva              number;
    v_sub_otros_tax           number;
    v_sub_iva                 number;
    v_sub_ica                 number;
    v_pais                    varchar2(100);
    v_estado                  varchar2(100);
    v_ciudad                  varchar2(100);
    v_terc_count              number;
    v_own_count               number;
    v_temp                    number;
    v_directory_path          varchar2(100);

    v_success_qty             number := 0;
    v_error_qty               number := 0;

    l_request_id            number;
    l_result                boolean;
    lb_complete             boolean;
    lc_phase                varchar2 (100);
    lc_status               varchar2 (100);
    lc_dev_phase            varchar2 (100);
    lc_dev_status           varchar2 (100);
    lc_message              varchar2 (100);

    v_return_status          varchar2(1);
    v_msg_count              number;
    v_msg_data               varchar2(2000);
    v_msg_index_out          number;
    v_net_amount             number;
    v_net_amount_pcc         number;
    v_tax_amount             number;
    v_tax_amount_pcc         number;
    v_total_amount           number;
    v_total_amount_pcc       number;
    v_trx_date               date;
    v_collection_country     varchar2(2);
    v_month_billed           varchar2(30);
    v_invoice_currency_code  varchar2(15);
    v_printing_currency_code varchar2(15);

begin
    -- ---------------------------------------------------------------------------
    -- Inicializo variables Grales de Ejecucion.
    -- ---------------------------------------------------------------------------
    v_calling_sequence := 'XX_AR_FE_CO_SEND_PK.GENERATE_FILES';
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

     -- Para modo draft se debe informar Transaccion Desde y Hats
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

     select global_attribute8, org_id
     into v_vat_id, v_org_id
     from ar_system_parameters;

     debug(g_indent            ||
           v_calling_sequence  ||
           '.v_vat_id:'||v_vat_id
          ,'1'
          );

     select organization_id
     into g_co_inv_org_id
     from org_organization_definitions od
     where operating_unit = v_org_id;

     debug(g_indent            ||
           v_calling_sequence  ||
           '.g_co_inv_org_id:'||g_co_inv_org_id
          ,'1'
          );


     select directory_path
     into   v_directory_path
     from   all_directories
     where  directory_name = 'XX_CO_INVOICE_WORK_PATH';

     debug(g_indent            ||
           v_calling_sequence  ||
           '.v_directory_path :'||v_directory_path
          ,'1'
          );

    open c_trxs(p_cust_trx_type_id => p_cust_trx_type,
                p_trx_number_from  => p_trx_number_from,
                p_trx_number_to    => p_trx_number_to,
                p_date_from        => fnd_date.canonical_to_date(p_date_from),
                p_date_to          => fnd_date.canonical_to_date(p_date_to),
                p_draft_mode       => p_draft_mode);

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

    --            <?xml version="1.0" encoding="UTF-8"?>
    fnd_file.put(fnd_file.output,'<?xml version="1.0" encoding="iso-8859-1"?>');
    fnd_file.put(fnd_file.output,'<XXARCOIMP>');
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

            -- Verifica si es un cliente generico o no para obtener los datos
            if (v_trxs_tbl(i).generic_customer = 'N') then
                begin
                    select replace(hp.party_name,'('||v_trxs_tbl(i).org_country||')','')
                          ,hp.jgzz_fiscal_code||decode(hca.global_attribute12, null, null, '-')||hca.global_attribute12
                          ,ac.email_address
                          ,ft.territory_short_name
                          ,substr(hl_cusb.state||
                            decode(hl_cusb.city, null, null, ', '||hl_cusb.city)||', '||
                            hl_cusb.address1 ||decode(hl_cusb.address2, null, null, ', '||hl_cusb.address2),1, 150) customer_address
                          ,flv.description
                      into v_trxs_tbl(i).customer_name
                          ,v_trxs_tbl(i).customer_doc_number
                          ,v_trxs_tbl(i).customer_email
                          ,v_trxs_tbl(i).customer_country_name
                          ,v_trxs_tbl(i).customer_address
                          ,v_trxs_tbl(i).customer_doc_type
                      from hz_party_sites        hpsb
                          ,hz_cust_acct_sites    hcasb
                          ,hz_cust_site_uses     hcsub
                          ,fnd_territories_vl    ft
                          ,hz_locations          hl_cusb
                          ,hz_parties            hp
                          ,ar_contacts_v         ac
                          ,hz_cust_accounts      hca
                          ,cll_f043_hz_parties_ext cfhpe
                          ,fnd_lookup_values_vl  flv
                     where v_trxs_tbl(i).party_id            = hp.party_id
                       and v_trxs_tbl(i).cust_account_id     = hca.cust_account_id
                       and hca.cust_account_id               = ac.customer_id(+)
                       and v_trxs_tbl(i).bill_to_site_use_id = hcsub.site_use_id
                       and hcsub.cust_acct_site_id           = hcasb.cust_acct_site_id
                       and hcasb.party_site_id               = hpsb.party_site_id
                       and hpsb.location_id                  = hl_cusb.location_id
                       and hl_cusb.country                   = ft.territory_code(+)
                       and hp.party_id                       = cfhpe.party_id(+)
                       and cfhpe.attribute1                  = flv.lookup_code(+)
                       and 'CLL_F041_DOCUMENT_TYPE'          = flv.lookup_type(+)                 
                       and rownum <= 1;
                    if (v_trxs_tbl(i).customer_doc_type is null) then
                        v_trxs_tbl(i).status := 'ERROR';
                        v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                        v_trxs_tbl(i).error_messages := 'No se encuentra Tipo de Documento en Extension Cliente de Colombia';
                        debug(g_indent            ||
                              v_calling_sequence  ||
                              ' No se encuentra Tipo de Documento en Extension Cliente de Colombia para Cliente: '||v_trxs_tbl(i).cust_account_id||' '||sqlerrm
                             ,'1'
                             );
                    end if;
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
            else -- Cliente generico valida tipo de documento
                if v_trxs_tbl(i).customer_doc_type is not null then
                   begin
                    select flv.description
                      into v_trxs_tbl(i).customer_doc_type
                      from fnd_lookup_values_vl flv
                     where flv.lookup_type = 'CLL_F041_DOCUMENT_TYPE'
                       and flv.lookup_code = v_trxs_tbl(i).customer_doc_type
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

                -- Para NIT, se formatea el numero con un guion antes del digito verificador
                if v_trxs_tbl(i).customer_doc_type = '31' then
                    if v_trxs_tbl(i).customer_doc_number not like '%-_' then
                        v_trxs_tbl(i).customer_doc_number := substr(v_trxs_tbl(i).customer_doc_number, 1, length(v_trxs_tbl(i).customer_doc_number) - 1) || '-' ||
                                                             substr(v_trxs_tbl(i).customer_doc_number, length(v_trxs_tbl(i).customer_doc_number));
                    end if;
                end if;

                -- Cliente generico obtiene datos de direccion
                if v_trxs_tbl(i).customer_country_name is not null then

                   -- Ajusta formato
                   if substr(v_trxs_tbl(i).customer_country_name,3,1) is null then
                      v_trxs_tbl(i).customer_country_name := v_trxs_tbl(i).customer_country_name || '||';
                   elsif instr (v_trxs_tbl(i).customer_country_name, '|',4,1) = 0 then
                         v_trxs_tbl(i).customer_country_name := v_trxs_tbl(i).customer_country_name  || '|';
                   end if;

                   select substr(v_trxs_tbl(i).customer_country_name,1,2),
                          substr(v_trxs_tbl(i).customer_country_name,
                                instr (v_trxs_tbl(i).customer_country_name, '|',1,1)+1,
                                instr (v_trxs_tbl(i).customer_country_name, '|',1,2) - instr (v_trxs_tbl(i).customer_country_name, '|',1,1) -1) ,
                          substr(v_trxs_tbl(i).customer_country_name,
                                 instr (v_trxs_tbl(i).customer_country_name, '|',1,2)+1)
                   into   v_pais, v_estado, v_ciudad
                   from   dual;

                   if v_pais is not null then

                      begin
                         select hg.geography_name
                         into   v_trxs_tbl(i).customer_country_name
                         from   hz_geographies hg
                         where  country_code = v_pais
                         and    geography_type = 'COUNTRY'
                         and    rownum <= 1;

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
                      end;

                    end if;

                    if v_ciudad is not null then
                         begin
                         select decode(v_trxs_tbl(i).customer_address, null, hg.geography_name, hg.geography_name||', '||v_trxs_tbl(i).customer_address)
                         into   v_trxs_tbl(i).customer_address
                           from hz_geography_identifiers hgi_state
                              , hz_geographies hg
                              , hz_hierarchy_nodes hhn
                              , hz_geography_identifiers hgi_city
                        where hgi_state.geography_type = 'STATE'
                        and hgi_state.identifier_subtype = 'CLL_F041_CODE'
                        and upper(hgi_state.identifier_value) = v_estado
                        and hgi_state.geography_use = 'MASTER_REF'
                        and hg.country_code = 'CO'
                        and hgi_city.geography_id = hg.geography_id
                        and hhn.parent_id = hgi_state.geography_id
                        and hhn.child_id = hgi_city.geography_id
                        and hgi_city.geography_type = 'CITY'
                        and hgi_city.identifier_value = v_ciudad;

                          exception
                         when others then
                              v_trxs_tbl(i).status := 'ERROR';
                              v_trxs_tbl(i).error_code := '030_UNEXPECTED_ERROR';
                              v_trxs_tbl(i).error_messages := 'Error inesperado obteniendo datos de cliente :'||sqlerrm;
                              v_trxs_tbl(i).customer_name := 'ERROR OBTENIENDO DATOS CLIENTE';
                              debug(g_indent            ||
                                    v_calling_sequence  ||
                                    ' Error inesperado obteniendo datos ciudad de direccion '||v_trxs_tbl(i).cust_account_id||' '||sqlerrm
                                    ,'1'
                                    );
                      end;

                      end if;

                      if v_estado is not null then
                        begin
                         select decode(v_trxs_tbl(i).customer_address, null, hg.geography_name, hg.geography_name||', '||v_trxs_tbl(i).customer_address)
                         into   v_trxs_tbl(i).customer_address
                         from   hz_geography_identifiers hgi_state
                              , hz_geographies hg
                         where  hgi_state.geography_type = 'STATE'
                         and hgi_state.identifier_subtype = 'CLL_F041_CODE'
                         and upper(hgi_state.identifier_value) = v_estado
                         and hgi_state.geography_use = 'MASTER_REF'
                         and hg.country_code = v_pais
                         and hgi_state.geography_id = hg.geography_id;

                          exception
                         when others then
                              v_trxs_tbl(i).status := 'ERROR';
                              v_trxs_tbl(i).error_code := '030_UNEXPECTED_ERROR';
                              v_trxs_tbl(i).error_messages := 'Error inesperado obteniendo datos de cliente :'||sqlerrm;
                              v_trxs_tbl(i).customer_name := 'ERROR OBTENIENDO DATOS CLIENTE';
                              debug(g_indent            ||
                                    v_calling_sequence  ||
                                    ' Error inesperado obteniendo datos estado de direccion '||v_trxs_tbl(i).cust_account_id||' '||sqlerrm
                                    ,'1'
                                    );
                          end;

                      end if;
                end if;
            end if;

            -- Valida datos obligarios
            if (v_trxs_tbl(i).customer_name is null) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                v_trxs_tbl(i).error_messages := 'No se informo nombre del cliente';
                v_trxs_tbl(i).customer_name := 'NO INFORMADO';
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' No se inform� nombre del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;
            elsif (v_trxs_tbl(i).customer_doc_number is null) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                v_trxs_tbl(i).error_messages := 'No se informo RFC del cliente';
                v_trxs_tbl(i).customer_doc_number := '0';
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' No se inform� RFC del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;

            elsif (v_trxs_tbl(i).customer_country_name is null) then
                v_trxs_tbl(i).status := 'ERROR';
                v_trxs_tbl(i).error_code := '010_MISSING_VALUE';
                v_trxs_tbl(i).error_messages := 'No se informo Pais del cliente';
                v_trxs_tbl(i).customer_country_name := 'X';
                debug(g_indent            ||
                      v_calling_sequence  ||
                     ' No se inform� Pais del cliente para customer_trx_id:'||' '||v_trxs_tbl(i).customer_trx_id
                     ,'1'
                      );
                continue;

            end if;

            begin

              v_send_line := '<G_INVOICE_HEADER>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<CONC_REQUEST_ID>'||v_request_id||'</CONC_REQUEST_ID>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<XX_AR_INVOICE_WORK_PATH>'||v_directory_path||'</XX_AR_INVOICE_WORK_PATH>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<CUST_TRX_TIPO>'||v_trxs_tbl(i).cust_trx_tipo||'</CUST_TRX_TIPO>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<CUSTOMER_TRX_ID>'||v_trxs_tbl(i).customer_trx_id||'</CUSTOMER_TRX_ID>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<XX_CO_INVOICE_WORK_PATH>'||v_directory_path||'</XX_CO_INVOICE_WORK_PATH>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<COUNTRY>CO</COUNTRY>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<ORG_ADDRESS_LINE_1>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).org_address_line1)||'</ORG_ADDRESS_LINE_1>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<ORG_ADDRESS_LINE_2>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).org_address_line2)||'</ORG_ADDRESS_LINE_2>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<REGISTERED_NAME>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).legal_entity_name)||'</REGISTERED_NAME>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<ORG_PHONE_NUMBER_1>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).org_telephone_number_1)||'</ORG_PHONE_NUMBER_1>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<ORG_PHONE_NUMBER_2>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).org_telephone_number_2)||'</ORG_PHONE_NUMBER_2>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<REGISTERED_ID>'||v_trxs_tbl(i).registration_number||'</REGISTERED_ID>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<ADDRESS_LINE_2>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).org_country)||'</ADDRESS_LINE_2>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              -- Se imprime para Facturas, no para Notas de Credito
              if v_trxs_tbl(i).document_type = 'INV' then
                  v_send_line := '<NRO_DESDE>'||'DEL No. '||v_trxs_tbl(i).ff_valor_inicial||'</NRO_DESDE>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<NRO_HASTA>'||'AL No. '||v_trxs_tbl(i).ff_valor_final||'</NRO_HASTA>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<LEYENDA_LEGAL>'||v_trxs_tbl(i).ff_legal_message||' RANGO'||'</LEYENDA_LEGAL>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              end if;
              v_send_line := '<DOC_TIPO>'||v_trxs_tbl(i).doc_type_display||'</DOC_TIPO>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              -- Para Facturas se imprime 'FV' antes del numero
              if v_trxs_tbl(i).document_type = 'INV' then
              v_send_line := '<TRX_NUMBER>'||'FV '||v_trxs_tbl(i).trx_number||'</TRX_NUMBER>'||g_eol;
              else
              v_send_line := '<TRX_NUMBER>'||v_trxs_tbl(i).trx_number||'</TRX_NUMBER>'||g_eol;
              end if;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<TRX_DATE>'||v_trxs_tbl(i).trx_date||'</TRX_DATE>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<CUSTOMER_NAME>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).customer_name)||'</CUSTOMER_NAME>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<CUSTOMER_COUNTRY>'||v_trxs_tbl(i).customer_country_name||'</CUSTOMER_COUNTRY>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<CUSTOMER_ADDRESS>'||psp_xmlgen.convert_xml_controls(initcap(v_trxs_tbl(i).customer_address))||'</CUSTOMER_ADDRESS>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<CUSTOMER_DOC>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).customer_doc_type||': '||v_trxs_tbl(i).customer_doc_number)||'</CUSTOMER_DOC>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<CURR_CODE>'||v_trxs_tbl(i).currency_code||'</CURR_CODE>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<EXCHANGE_RATE>'||v_trxs_tbl(i).exchange_rate||'</EXCHANGE_RATE>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              v_send_line := '<COMMENTS>'||psp_xmlgen.convert_xml_controls(v_trxs_tbl(i).comments)||'</COMMENTS>'||g_eol;
              dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);

              v_sub_ter_otros := 0;
              v_sub_ter_vat := 0;
              v_sub_ter_imp := 0;
              v_sub_rentas := 0;
              v_sub_retica := 0;
              v_sub_retiva := 0;
              v_sub_otros_tax := 0;
              v_sub_iva := 0;
              v_subtotal := 0;
              v_sub_tot := 0;
              v_subtot_sintax := 0;
              v_total := 0;
              v_terc_count := 0;
              v_own_count := 0;
              v_vat_translated_amount := 0;
              v_other_translated_amount := 0;


    debug(g_indent            ||
          v_calling_sequence  ||
          '. Obtiene lineas '  ||
          ' de facturas a procesar'
         ,'1'
         );

              for r_trxs_lines in (-- Transaciones importadas
                                   select abs(nvl(rctll.quantity_invoiced, rctll.quantity_credited))               quantity
                                        , sum(rctll.extended_amount - ((nvl(fnd_number.canonical_to_number(replace(xaea.attribute48, ',', '.')), 0)
                                           + nvl(fnd_number.canonical_to_number(replace(xaea.attribute49, ',', '.')), 0)) *
                                           nvl(rctll.quantity_invoiced, rctll.quantity_credited)))                 amount
                                        , sum(rctll.extended_amount) + sum(nvl(taxes.extended_amount, 0))          extended_amount
                                        , sum(taxes.std_ren_cost) std_ren_cost
                                        , sum(taxes.std_ica_cost) std_ica_cost
                                        , sum(taxes.std_iva_cost) std_iva_cost
                                        , sum(taxes.std_vat_cost) std_vat_cost
                                        , get_inventory_item_desc(    xaea.source_id_char1,
                                                                      v_trxs_tbl(i).batch_source_type,
                                                                      v_trxs_tbl(i).customer_trx_id,
                                                                      v_trxs_tbl(i).document_type,
                                                                      nvl(rctll.warehouse_id, g_co_inv_org_id),
                                                                      rctll.inventory_item_id,
                                                                      v_trxs_tbl(i).cust_trx_concept,
                                                                      xaea.attribute50) item_description
                                        , max(rctll.inventory_item_id)                                             inventory_item_id
                                        , max(nvl(rctll.warehouse_id, g_co_inv_org_id))                            organization_id
                                        , xaea.attribute50                                                         rfc
                                        , get_supplier_name(xaea.attribute50, v_trxs_tbl(i).rct_org_id)            rfc_supplier
                                        , sum(nvl(fnd_number.canonical_to_number(replace(xaea.attribute48, ',', '.')), 0) *
                                          nvl(rctll.quantity_invoiced, rctll.quantity_credited))                            rfc_vat_cost
                                        , sum(nvl(fnd_number.canonical_to_number(replace(xaea.attribute49, ',', '.')), 0) *
                                          nvl(rctll.quantity_invoiced, rctll.quantity_credited))                            rfc_others_cost
                                     from ra_customer_trx_lines   rctll
                                        , oe_order_lines_all      ool
                                        , xx_all_extra_attributes xaea
                                        , (select sum(decode(nvl(avt.tax, 'X'),'RENRET', rctlt.extended_amount, 0))                std_ren_cost
                                                , sum(decode(nvl(avt.tax, 'X'),'ICARET', rctlt.extended_amount, 0))                std_ica_cost
                                                , sum(decode(nvl(avt.tax, 'X'),'IVARET', rctlt.extended_amount, 0))                std_iva_cost
                                                , sum(decode(nvl(avt.global_attribute1, -1),v_vat_id, rctlt.extended_amount, 0))   std_vat_cost
                                                , sum(rctlt.extended_amount)                                                       extended_amount
                                                , rctlt.link_to_cust_trx_line_id
                                             from ra_customer_trx_lines_all rctlt
                                                , zx_lines                  zx_line
                                                , ar_vat_tax_all            avt
                                            where rctlt.customer_trx_id       = v_trxs_tbl(i).customer_trx_id
                                              and rctlt.line_type             = 'TAX'
                                              and zx_line.tax_line_id         = rctlt.tax_line_id
                                              and zx_line.entity_code         = 'TRANSACTIONS'
                                              and zx_line.application_id      = 222
                                              and avt.vat_tax_id              = rctlt.vat_tax_id
                                              and avt.org_id                  = rctlt.org_id
                                          group by rctlt.link_to_cust_trx_line_id) taxes
                                   where rctll.customer_trx_id           = v_trxs_tbl(i).customer_trx_id
                                     and rctll.line_type                 = 'LINE'
                                     and rctll.interface_line_attribute6 = ool.line_id(+)
                                     and xaea.source_table(+)            = 'OE_ORDER_LINES'
                                     and rctll.customer_trx_line_id      = taxes.link_to_cust_trx_line_id(+)
                                     and to_char(ool.line_id)            = xaea.source_id_char1(+)
                                     and v_trxs_tbl(i).batch_source_type = 'FOREIGN'
                                     and nvl(rctll.quantity_invoiced, rctll.quantity_credited) != 0
                                  group by abs(nvl(rctll.quantity_invoiced, rctll.quantity_credited)),
                                           get_inventory_item_desc(   xaea.source_id_char1,
                                                                      v_trxs_tbl(i).batch_source_type,
                                                                      v_trxs_tbl(i).customer_trx_id,
                                                                      v_trxs_tbl(i).document_type,
                                                                      nvl(rctll.warehouse_id, g_co_inv_org_id),
                                                                      rctll.inventory_item_id,
                                                                      v_trxs_tbl(i).cust_trx_concept,
                                                                      xaea.attribute50),
                                           xaea.attribute50, 
                                           get_supplier_name(xaea.attribute50, v_trxs_tbl(i).rct_org_id)
                                    union -- Transaciones manuales
                                   select abs(nvl(rctll.quantity_invoiced, rctll.quantity_credited))               quantity
                                        , sum(rctll.extended_amount)                                               amount
                                        , sum(rctll.extended_amount) + sum(nvl(taxes.extended_amount, 0))          extended_amount
                                        , sum(taxes.std_ren_cost) std_ren_cost
                                        , sum(taxes.std_ica_cost) std_ica_cost
                                        , sum(taxes.std_iva_cost) std_iva_cost
                                        , sum(taxes.std_vat_cost) std_vat_cost
                                        , get_inventory_item_desc(    null,
                                                                      v_trxs_tbl(i).batch_source_type,
                                                                      v_trxs_tbl(i).customer_trx_id,
                                                                      v_trxs_tbl(i).document_type,
                                                                      nvl(rctll.warehouse_id, g_co_inv_org_id),
                                                                      rctll.inventory_item_id,
                                                                      v_trxs_tbl(i).cust_trx_concept,
                                                                      null) item_description
                                        , max(rctll.inventory_item_id)                                             inventory_item_id
                                        , max(nvl(rctll.warehouse_id, g_co_inv_org_id))                            organization_id
                                        , null                                                    rfc
                                        , null
                                        , 0   rfc_vat_cost
                                        , 0   rfc_others_cost
                                     from ra_customer_trx_lines   rctll
                                        , (select sum(decode(nvl(avt.tax, 'X'),'RENRET', rctlt.extended_amount, 0))                std_ren_cost
                                                , sum(decode(nvl(avt.tax, 'X'),'ICARET', rctlt.extended_amount, 0))                std_ica_cost
                                                , sum(decode(nvl(avt.tax, 'X'),'IVARET', rctlt.extended_amount, 0))                std_iva_cost
                                                , sum(decode(nvl(avt.global_attribute1, -1),v_vat_id, rctlt.extended_amount, 0))   std_vat_cost
                                                , sum(rctlt.extended_amount)                                                       extended_amount
                                                , rctlt.link_to_cust_trx_line_id
                                             from ra_customer_trx_lines   rctlt
                                                , zx_lines                zx_line
                                                , ar_vat_tax_vl           avt
                                            where rctlt.customer_trx_id          = v_trxs_tbl(i).customer_trx_id
                                              and rctlt.line_type                = 'TAX'
                                              and zx_line.tax_line_id            = rctlt.tax_line_id
                                              and zx_line.entity_code            = 'TRANSACTIONS'
                                              and zx_line.application_id         = 222
                                              and avt.vat_tax_id                 = rctlt.vat_tax_id
                                              and avt.org_id                     = rctlt.org_id
                                           group by rctlt.link_to_cust_trx_line_id) taxes
                                   where rctll.customer_trx_id           = v_trxs_tbl(i).customer_trx_id
                                     and rctll.line_type                 = 'LINE'
                                     and rctll.customer_trx_line_id      = taxes.link_to_cust_trx_line_id(+)
                                     and v_trxs_tbl(i).batch_source_type = 'INV'
                                     and nvl(rctll.quantity_invoiced, rctll.quantity_credited) != 0
                                  group by abs(nvl(rctll.quantity_invoiced, rctll.quantity_credited)),
                                           get_inventory_item_desc(   null,
                                                                      v_trxs_tbl(i).batch_source_type,
                                                                      v_trxs_tbl(i).customer_trx_id,
                                                                      v_trxs_tbl(i).document_type,
                                                                      nvl(rctll.warehouse_id, g_co_inv_org_id),
                                                                      rctll.inventory_item_id,
                                                                      v_trxs_tbl(i).cust_trx_concept,
                                                                      null),
                                           null) loop

                 debug(g_indent            ||
                       v_calling_sequence  ||
                        '. Procesa lineas '
                          ,'1'
                          );

                  if (v_trxs_tbl(i).batch_source_type = 'FOREIGN' and r_trxs_lines.item_description is null) then
                      v_trxs_tbl(i).status := 'ERROR';
                      v_trxs_tbl(i).error_code := '020_INVALID_CONFIGURATION';
                      select 'No se encontro informacion adicional para la l�nea de pedido (RFC) '
                        into v_trxs_tbl(i).error_messages
                        from dual;
                      debug(g_indent            ||
                            v_calling_sequence  ||
                            v_trxs_tbl(i).error_messages
                           ,'1'
                           );
                      continue;
                  end if;

                  if (v_trxs_tbl(i).batch_source_type = 'INV' and r_trxs_lines.item_description is null) then
                      v_trxs_tbl(i).status := 'ERROR';
                      v_trxs_tbl(i).error_code := '020_INVALID_CONFIGURATION';
                      select 'No se pudo obtener descripcion para articulo '||msib.segment1||' y '||v_trxs_tbl(i).cust_trx_type_name
                        into v_trxs_tbl(i).error_messages
                        from mtl_system_items_b msib
                       where msib.inventory_item_id = r_trxs_lines.inventory_item_id
                         and msib.organization_id = r_trxs_lines.organization_id;
                      debug(g_indent            ||
                            v_calling_sequence  ||
                            v_trxs_tbl(i).error_messages
                           ,'1'
                           );
                      continue;
                  end if;

                  -- Datos de Conceptos si el tipo es prepago
                  --IF v_trxs_tbl(i).collection_type = 'PP' THEN
                      v_send_line := '<G_INVOICE_LINE>'||g_eol;
                      dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                      if r_trxs_lines.rfc is null then
                         v_send_line := '<LIN_TYPE>PROPIO</LIN_TYPE>'||g_eol;
                         dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                         v_send_line := '<ITEM_DESC>'||psp_xmlgen.convert_xml_controls(r_trxs_lines.item_description)||'</ITEM_DESC>'||g_eol;
                         dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                         v_own_count := v_own_count + 1;
                      else
                         v_send_line := '<LIN_TYPE>TERC</LIN_TYPE>'||g_eol;
                         dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                         v_send_line := '<ITEM_DESC>'||psp_xmlgen.convert_xml_controls(r_trxs_lines.item_description||' '||r_trxs_lines.rfc_supplier)||'</ITEM_DESC>'||g_eol;
                         dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                         v_sub_ter_otros := v_sub_ter_otros + 
                                            r_trxs_lines.std_ren_cost + 
                                            r_trxs_lines.std_ica_cost + 
                                            r_trxs_lines.std_iva_cost +
                                            r_trxs_lines.rfc_others_cost;
                         v_sub_ter_vat := v_sub_ter_vat + r_trxs_lines.std_vat_cost + r_trxs_lines.rfc_vat_cost;
                         v_sub_ter_imp := v_sub_ter_imp + (r_trxs_lines.amount);
                         v_sub_tot :=       v_sub_tot + r_trxs_lines.amount +
                                            r_trxs_lines.std_ren_cost + 
                                            r_trxs_lines.std_ica_cost + 
                                            r_trxs_lines.std_iva_cost +
                                            r_trxs_lines.rfc_others_cost +
                                            r_trxs_lines.std_vat_cost + r_trxs_lines.rfc_vat_cost;
                         v_terc_count := v_terc_count + 1;
                      end if;
                      --v_send_line := '<QUANTITY>'||r_trxs_lines.quantity||'</QUANTITY>'||G_EOL;
                      --dbms_lob.writeappend(v_send_file, LENGTH(v_send_line), v_send_line);
                      v_send_line := '<IMPORTE>'|| trim(to_char(r_trxs_lines.amount, g_num_format))||'</IMPORTE>'||g_eol;
                      dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                      v_temp := r_trxs_lines.std_vat_cost +  r_trxs_lines.rfc_vat_cost;
                      v_send_line := '<IVA>'|| trim(to_char(v_temp, g_num_format))||'</IVA>'||g_eol;
                      dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                      v_temp := r_trxs_lines.rfc_others_cost;
                      v_send_line := '<OTROS>'|| trim(to_char(v_temp, g_num_format)) ||'</OTROS>'||g_eol;
                      dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                      v_temp := r_trxs_lines.amount + 
                                r_trxs_lines.std_vat_cost + 
                                r_trxs_lines.rfc_vat_cost +
                                r_trxs_lines.rfc_others_cost;
                      v_send_line := '<AMOUNT>'||trim(to_char(v_temp, g_num_format))||'</AMOUNT>'||g_eol;
                      dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                      v_send_line := '</G_INVOICE_LINE>'||g_eol;
                      dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  --END IF;

                  v_sub_rentas := v_sub_rentas + r_trxs_lines.std_ren_cost;
                  v_sub_retica := v_sub_retica + r_trxs_lines.std_ica_cost;
                  v_sub_retiva := v_sub_retiva + r_trxs_lines.std_iva_cost;
                  v_sub_otros_tax := v_sub_otros_tax + r_trxs_lines.rfc_others_cost;
                  v_sub_iva := v_sub_iva + r_trxs_lines.std_vat_cost + r_trxs_lines.rfc_vat_cost;
                  v_subtot_sintax := v_subtot_sintax + r_trxs_lines.amount + r_trxs_lines.rfc_others_cost;
                  v_subtotal := v_subtotal + r_trxs_lines.amount + 
                                             r_trxs_lines.std_vat_cost + 
                                             r_trxs_lines.std_ren_cost + 
                                             r_trxs_lines.std_ica_cost + 
                                             r_trxs_lines.std_iva_cost + 
                                             r_trxs_lines.rfc_vat_cost + 
                                             r_trxs_lines.rfc_others_cost;
                  v_total := v_total + r_trxs_lines.extended_amount;

              end loop;

    debug(g_indent            ||
          v_calling_sequence  ||
          '. Obtiene lineas adicional '  ||
          ' de facturas a procesar'
         ,'1'
         );

               -- loop informacion adicional
              for r_trxs_adic in (   -- Transaciones con Pago Destino
                                     select distinct 'Extracto: '||v_trxs_tbl(i).hotel_stmt_trx_number     info_adic
                                     from dual
                                     where v_trxs_tbl(i).collection_type = 'PD'
                                       and v_trxs_tbl(i).hotel_stmt_trx_number is not null
                                     union all -- Transacciones con Prepago
                                     -- Transacciones con Prepago
                                     select distinct 'Reserva '||rctl.interface_line_attribute15||' - '||flv2.meaning||' - '||
                                                   nvl (rctd.xx_ar_passenger_name , nvl (rct_dfv.xx_ar_customer, ac.customer_name))||' - '||
                                                        decode (rctl.attribute_category, '0001', flv2.description,  substr (rctd.xx_ar_provider,instr (rctd.xx_ar_provider, '_') + 1
                                                   , length(rctd.xx_ar_provider))  )||' '||decode (rctl.attribute_category, '0001', ' - #Tkt '||rctd.xx_ar_ticket_number, null) info_adic
                                     from   ra_customer_trx_lines rctl,
                                            ra_customer_trx_lines_all_dfv rctd,
                                            fnd_lookup_values_vl flv,
                                            ra_customer_trx rct,
                                            ra_customer_trx_all_dfv rct_dfv,
                                            fnd_lookup_values_vl flv2,
                                            ar_customers ac
                                     where  v_trxs_tbl(i).collection_type = 'PP'
                                     and    rct.customer_trx_id = v_trxs_tbl(i).customer_trx_id
                                     and    rctl.customer_trx_id = rct.customer_trx_id
                                     and    nvl(rctl.attribute_category, '@') != '0008' -- No se muestran datos de FEE
                                     and    rctl.line_type = 'LINE'
                                     and    rct.rowid = rct_dfv.row_id
                                     and    rct.bill_to_customer_id = ac.customer_id(+)
                                     and    rctl.rowid = rctd.row_id
                                     and    rctd.xx_ar_provider = flv.lookup_code(+)
                                     and    flv.lookup_type(+) = 'XX_AP_CARRIER_CODES'
                                     and    rctl.attribute_category = flv2.lookup_code(+)
                                     and    flv2.lookup_type(+) = 'XX_OE_TIPO_PRODUCTO') loop

                      v_send_line := '<G_INVOICE_ADIC>'||g_eol;
                      dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                      v_send_line := '<VTA_ADIC>'||psp_xmlgen.convert_xml_controls(r_trxs_adic.info_adic)||'</VTA_ADIC>'||g_eol;
                      dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                      v_send_line := '</G_INVOICE_ADIC>'||g_eol;
                      dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);

              end loop;

/*
              IF v_trxs_tbl(i).collection_type = 'PD' THEN
                      v_send_line := '<G_INVOICE_LINE>'||G_EOL;
                      dbms_lob.writeappend(v_send_file, LENGTH(v_send_line), v_send_line);
                      v_send_line := '<LIN_TYPE>PROPIO</LIN_TYPE>'||G_EOL;
                      dbms_lob.writeappend(v_send_file, LENGTH(v_send_line), v_send_line);
                      v_send_line := '<ITEM_DESC>'||r_trxs_lines.item_description||'</ITEM_DESC>'||G_EOL;
                      dbms_lob.writeappend(v_send_file, LENGTH(v_send_line), v_send_line);
                      v_send_line := '<QUANTITY>'||v_subtotal||'</QUANTITY>'||G_EOL;
                      dbms_lob.writeappend(v_send_file, LENGTH(v_send_line), v_send_line);
                      v_send_line := '<IMPORTE>'||v_subtotal||'</IMPORTE>'||G_EOL;
                      dbms_lob.writeappend(v_send_file, LENGTH(v_send_line), v_send_line);
                      v_send_line := '<IVA>'||v_sub_iva||'</IVA>'||G_EOL;
                      dbms_lob.writeappend(v_send_file, LENGTH(v_send_line), v_send_line);
                      v_temp := v_sub_rentas + v_sub_retica + v_sub_retiva;
                      v_send_line := '<OTROS>'|| v_temp ||'</OTROS>'||G_EOL;
                      dbms_lob.writeappend(v_send_file, LENGTH(v_send_line), v_send_line);
                      v_send_line := '<AMOUNT>'||TRIM(TO_CHAR(ABS(v_subtotal), G_NUM_FORMAT))||'</AMOUNT>'||G_EOL;
                      dbms_lob.writeappend(v_send_file, LENGTH(v_send_line), v_send_line);
                      v_send_line := '<VTA_ADIC>'||'Extracto:'||v_trxs_tbl(i).hotel_stmt_trx_number||'</VTA_ADIC>'||G_EOL;
                      dbms_lob.writeappend(v_send_file, LENGTH(v_send_line), v_send_line);
                      v_send_line := '</G_INVOICE_LINE>'||G_EOL;
                      dbms_lob.writeappend(v_send_file, LENGTH(v_send_line), v_send_line);
             END IF;
*/

              if (v_trxs_tbl(i).status != 'ERROR') then

                  v_send_line := '<TERC_COUNT>'||v_terc_count||'</TERC_COUNT>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<PROP_COUNT>'||v_own_count||'</PROP_COUNT>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<SUB_TOT>'||trim(to_char(v_sub_tot, g_num_format))||'</SUB_TOT>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<SUB_IVA>'||trim(to_char(v_sub_ter_vat, g_num_format))||'</SUB_IVA>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<SUB_OTRO>'||trim(to_char(v_sub_ter_otros, g_num_format))||'</SUB_OTRO>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<SUB_IMP>'||trim(to_char(v_sub_ter_imp, g_num_format))||'</SUB_IMP>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<SUBT_TOT>'||trim(to_char(v_subtot_sintax, g_num_format))||'</SUBT_TOT>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<SUBT_IVA>'||trim(to_char(v_sub_iva, g_num_format))||'</SUBT_IVA>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<SUBT_ROTROS>'||trim(to_char(v_sub_otros_tax, g_num_format))||'</SUBT_ROTROS>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<SUBT_RIVA>'||trim(to_char(v_sub_retiva, g_num_format))||'</SUBT_RIVA>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<SUBT_RICA>'||trim(to_char(v_sub_retica, g_num_format))||'</SUBT_RICA>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '<SUBT_RREN>'||trim(to_char(v_sub_rentas, g_num_format))||'</SUBT_RREN>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);

                  v_send_line := '<SUBTOTAL>'||trim(to_char(v_subtotal, g_num_format))||'</SUBTOTAL>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);

                 debug(g_indent            ||
                       v_calling_sequence  ||
                       ' v_subtotal: ' || v_subtotal ||' IVA: '|| v_vat_translated_amount || ' Otros: '|| v_other_translated_amount
                      ,'1'
                      );

                  v_send_line := '<TOTAL>'||trim(to_char(v_total, g_num_format))||'</TOTAL>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);

                  v_total_in_words := iby_amount_in_words.get_amount_in_words(p_amount        => abs(v_total)
                                                                            , p_currency_code => 'COP'
                                                                            , p_precision     => 2
                                                                            , p_country_code  => 'CO');

                  ------------------------------------------------------------
                  -- Si NLS_LANGUAGE es AMERICAN y la moneda USD o EUR,
                  -- la API devuelve el monto en ingles. Se traduce a espa�ol.
                  ------------------------------------------------------------
                  if (v_trxs_tbl(i).original_currency_code != 'COP') then
                      if (v_trxs_tbl(i).original_currency_code = 'USD') then
                          select replace(replace(v_total_in_words, 'PESOS', 'D�LARES'), 'M.N', 'CENTAVOS')
                            into v_total_in_words
                            from dual;
                      elsif (v_trxs_tbl(i).original_currency_code = 'EUR') then
                          select replace(replace(v_total_in_words, 'PESOS', 'EURO'), 'M.N', 'CENTAVOS')
                            into v_total_in_words
                            from dual;
                      else
                           v_total_in_words := iby_amount_in_words.get_amount_in_words(p_amount        => abs(v_total)
                                                                                     , p_currency_code => v_trxs_tbl(i).original_currency_code
                                                                                     , p_precision     => 2
                                                                                     , p_country_code  => 'CO');
                      end if;
                  end if;

                  v_send_line := '<TOTAL_TEXTO>'||v_total_in_words||'</TOTAL_TEXTO>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
                  v_send_line := '</G_INVOICE_HEADER>'||g_eol;
                  dbms_lob.writeappend(v_send_file, length(v_send_line), v_send_line);
              end if;

            exception
              when others then
                v_mesg_error := 'Error cargando el '       ||
                                'contenido del archivo '   ||
                                'en la tabla de '          ||
                                'Envios de Transacciones ' ||
                                '(XX_AR_FE_CO_TRX). '      ||
                                'Texto: '                  ||
                                v_send_line                ||
                                '. '                       ||
                                sqlerrm;
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

        end loop;
    end if; -- Completa detalles a imprimir

    -- Genera los archivos
    if (v_mesg_error is null) then

        debug(g_indent            ||
              v_calling_sequence  ||
              ' Generando archivos'
             ,'1'
             );

        begin
        /*
           IF NOT print_text(p_print_output => NULL
                            ,p_mesg_error   => v_mesg_error
                            ) THEN
              v_mesg_error := 'Error generando archivos: '||v_mesg_error;
           END IF;*/

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
    fnd_file.put(fnd_file.output,'</XXARCOIMP>');

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

                -- Se obtiene el periodo del extracto
                xx_ar_utilities_pk.get_hotel_stmt_info(p_hotel_stmt_trx_number => v_hotel_stmt_trx_number
                                                     , x_period_name           => v_month_billed);

                xx_ar_reg_send_invoices_pk.get_invoice_values(p_customer_trx_id        => v_trxs_tbl(i).customer_trx_id
                                                             ,p_country                => 'CO'
                                                             ,x_net_amount             => v_net_amount
                                                             ,x_net_amount_pcc         => v_net_amount_pcc
                                                             ,x_tax_amount             => v_tax_amount
                                                             ,x_tax_amount_pcc         => v_tax_amount_pcc
                                                             ,x_total_amount           => v_total_amount
                                                             ,x_total_amount_pcc       => v_total_amount_pcc
                                                             ,x_trx_date               => v_trx_date
                                                             ,x_collection_country     => v_collection_country
                                                             ,x_invoice_currency_code  => v_invoice_currency_code
                                                             ,x_printing_currency_code => v_printing_currency_code
                                                             ,x_return_status          => v_return_status
                                                             ,x_msg_count              => v_msg_count
                                                             ,x_msg_data               => v_msg_data);
      
                if (v_return_status != fnd_api.g_ret_sts_success) then
                    for cnt in 1..v_msg_count loop
                        fnd_msg_pub.get(p_msg_index     => cnt
                                       ,p_encoded       => fnd_api.g_false
                                       ,p_data          => v_msg_data
                                       ,p_msg_index_out => v_msg_index_out);
    
                        v_mesg_error := v_mesg_error || v_msg_data;
                    end loop;
                    v_mesg_error := 'Get_Invoice_Values: '||v_mesg_error;
                end if;

            exception
              when others then
                  v_mesg_error := 'Get_Invoice_Values: '||sqlerrm;
            end;

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
                values (v_trxs_tbl(i).customer_trx_id     -- CUSTOMER_TRX_ID
                    , v_trxs_tbl(i).trx_number            -- TRX_NUMBER_ORI
                    , v_trxs_tbl(i).customer_name         -- REFERENCE
                    , null                                -- RECEIVE_DATE
                    , null                                -- TRX_NUMBER_NEW
                    , null                                -- LINK
                    , null                                -- CAE
                    , null                                -- FECHA_CAE
                    , v_trxs_tbl(i).customer_trx_id||'-'||v_request_id||'.pdf'           -- FILE_NAME
                    , decode(v_trxs_tbl(i).status,
                          'ERROR', 'PROCESSING_ERROR_ORACLE'
                        , 'WORK_IN_PROGRESS')             -- STATUS
                    , v_trxs_tbl(i).error_code            -- ERROR_CODE
                    , v_trxs_tbl(i).error_messages        -- ERROR_MESSAGES
                    , fnd_global.user_id                  -- CREATED_BY
                    , sysdate                             -- CREATION_DATE
                    , fnd_global.user_id                  -- LAST_UPDATED_BY
                    , sysdate                             -- LAST_UPDATE_DATE
                    , fnd_global.login_id                 -- LAST_UPDATE_LOGIN
                    , v_trxs_tbl(i).purchase_order        -- PURCHASE_ORDER
                    , v_trxs_tbl(i).request_number        -- REQUEST_NUMBER
                    , v_order_source                      -- ORDER_SOURCE
                    , v_orig_sys_document_ref             -- ORIG_SYS_DOCUMENT_REF
                    , v_trxs_tbl(i).collection_type       -- COLLECTION_TYPE
                    , v_trxs_tbl(i).document_type         -- DOCUMENT_TYPE
                    , v_trxs_tbl(i).customer_email        -- EMAIL
                    , v_trxs_tbl(i).source_system_number  -- SOURCE_SYSTEM_NUMBER
                    , v_trxs_tbl(i).legal_entity_name     -- LEGAL_ENTITY
                    , v_trxs_tbl(i).legal_entity_id       -- LEGAL_ENTITY_CODE
                    , fnd_global.conc_request_id          -- REQUEST_ID
                    , v_stmt_source                       -- STMT_SOURCE
                    , v_hotel_stmt_trx_number             -- HOTEL_STMT_TRX_NUMBER
                    , p_territory_code                    -- ATTRIBUTE_CATEGORY
                    , null                                -- ATTRIBUTE1
                    , null                                -- ATTRIBUTE2
                    , null                                -- ATTRIBUTE3
                    , null                                -- ATTRIBUTE4
                    , null                                -- ATTRIBUTE5
                    , null                                -- ATTRIBUTE6
                    , null                                -- ATTRIBUTE7
                    , null                                -- ATTRIBUTE8
                    , null                                -- ATTRIBUTE9
                    , null                                -- ATTRIBUTE10
                    , v_net_amount                        -- NET_AMOUNT
                    , v_net_amount_pcc                    -- NET_AMOUNT_PCC
                    , v_tax_amount                        -- TAX_AMOUNT
                    , v_tax_amount_pcc                    -- TAX_AMOUNT_PCC
                    , v_total_amount                      -- TOTAL_AMOUNT
                    , v_total_amount_pcc                  -- TOTAL_AMOUNT_PCC
                    , v_trx_date                          -- TRX_DATE
                    , v_collection_country                -- COLLECTION_COUNTRY
                    , v_month_billed                      -- MONTH_BILLED
                    , v_invoice_currency_code             -- INVOICE_CURRENCY_CODE
                    , v_printing_currency_code            -- PRINTING_CURRENCY_CODE
                    );
            exception
              when dup_val_on_index then
                update xx_ar_reg_invoice_request
                   set trx_number_ori = v_trxs_tbl(i).trx_number
                    , reference = v_trxs_tbl(i).customer_name
                    , receive_date = null
                    , trx_number_new = null
                    , link = null
                    , cae = null
                    , fecha_cae = null
                    , file_name = v_trxs_tbl(i).customer_trx_id||'-'||v_request_id||'.pdf'
                    , status = decode(v_trxs_tbl(i).status,
                          'ERROR', 'PROCESSING_ERROR_ORACLE'
                        , 'WORK_IN_PROGRESS')
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
                    , attribute1 = null
                    , attribute2 = null
                    , attribute3 = null
                    , attribute4 = null
                    , attribute5 = null
                    , attribute6 = null
                    , attribute7 = null
                    , attribute8 = null
                    , attribute9 = null
                    , attribute10 = null
                    , net_amount = v_net_amount
                    , net_amount_pcc = v_net_amount_pcc
                    , tax_amount = v_tax_amount
                    , tax_amount_pcc = v_tax_amount_pcc
                    , total_amount = v_total_amount
                    , total_amount_pcc = v_total_amount_pcc
                    , trx_date = v_trx_date
                    , collection_country = v_collection_country
                    , month_billed = v_month_billed
                    , invoice_currency_code = v_invoice_currency_code
                    , printing_currency_code = v_printing_currency_code
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
                l_request_id :=
            fnd_request.submit_request(application => 'XDO',
                                 program     => 'XDOBURSTREP',
                                 description =>  null,
                                 start_time  =>  null,
                                 sub_request =>  false,
                                 argument1   =>  null,
                                 argument2   =>  v_request_id,
                                 argument3   =>  'Y'
                                 );
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


procedure validate_files(errbuf            out varchar2
                        ,retcode           out number
                        ,p_draft_mode      in  varchar2
                        ) is

cursor c_xx_ar_reg_invoice_request(p_req_id number) is
select rowid, customer_trx_id, file_name
from xx_ar_reg_invoice_request 
where status  = 'WORK_IN_PROGRESS' and request_id = p_req_id;

xx_ar_reg_invoice_request_type  c_xx_ar_reg_invoice_request%rowtype;

v_exists                varchar2(1);
v_directory_path        varchar2(100);
l_gen_file_req_id       number;
l_bursting_request_id   number;
lb_complete             boolean;
lc_phase                varchar2 (100);
lc_status               varchar2 (100);
lc_dev_phase            varchar2 (100);
lc_dev_status           varchar2 (100);
lc_message              varchar2 (100);

begin

    fnd_file.put_line (fnd_file.log, 'p_draft_mode = '||p_draft_mode);

     select directory_path
     into   v_directory_path
     from   all_directories
     where  directory_name = 'XX_CO_INVOICE_WORK_PATH';

    /* get bursting request_id */
    select fcr1.request_id, fcr2.request_id
    into   l_gen_file_req_id, l_bursting_request_id
    from   fnd_concurrent_requests fcr1 -- XXARCOFEG
          ,fnd_concurrent_programs_vl fcpv
          ,fnd_concurrent_requests fcr2 --  XDOBURSTREP
          ,fnd_concurrent_requests fcr -- XXARCOFEV
    where fcr.request_id = fnd_global.conc_request_id
    and   fcr1.priority_request_id =fcr.priority_request_id
    and   fcpv.concurrent_program_id = fcr1.concurrent_program_id
    and   fcpv.concurrent_program_name = 'XXARCOFEG'
    and   fcr2.parent_request_id = fcr1.request_id;

    fnd_file.put_line (fnd_file.log, 'l_bursting_request_id : '||l_bursting_request_id);

    lc_dev_phase := 'X';
    while (upper (lc_dev_phase) != 'COMPLETE')
    loop
        lb_complete :=
        fnd_concurrent.wait_for_request (request_id      => l_bursting_request_id
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
                set  status = 'NEW'
               where request_id = l_gen_file_req_id
                and  status = 'WORK_IN_PROGRESS'
                and  customer_trx_id = xx_ar_reg_invoice_request_type.customer_trx_id;

             update ra_customer_trx_all rct
                set rct.attribute9 = 'Y'
              where rct.customer_trx_id = xx_ar_reg_invoice_request_type.customer_trx_id;

           else
              update xx_ar_reg_invoice_request
                set  status = 'PROCESSING_ERROR_ORACLE',
                     error_code = '040_FILE_GENERATION_PROBLEM',
                     error_messages = 'No se encuentra el archivo generado en el servidor '||xx_ar_reg_invoice_request_type.file_name
               where request_id = l_gen_file_req_id
                and  status = 'WORK_IN_PROGRESS'
                and  customer_trx_id = xx_ar_reg_invoice_request_type.customer_trx_id;
           end if;
        end if;
    end loop;

    commit;

exception
when others then
	fnd_file.put_line (fnd_file.log, 'Error : ' || sqlerrm);
end;

end xx_ar_fe_co_sends_pk;
/

show errors

spool off

exit
