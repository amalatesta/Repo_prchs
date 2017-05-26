REM +=======================================================================+
REM |    Copyright (c) 1997 Oracle Argentina, Buenos Aires                  |
REM |                         All rights reserved.                          |
REM +=======================================================================+
REM | FILENAME                                                              |
REM |    XX_AR_FE_PE_SENDS_PK.sql                                           |
REM |                                                                       |
REM | DESCRIPTION                                                           |
REM |    Crea el paquete XX_AR_FE_PE_SENDS_PK                               |
REM |    que contiene funciones y procedimientos para el proceso de         |
REM |    envio de factura electronica de Peru.                              |
REM |                                                                       |
REM | LANGUAGE                                                              |
REM |    PL/SQL                                                             |
REM |                                                                       |
REM | PRODUCT                                                               |
REM |    Oracle Financials                                                  |
REM |                                                                       |
REM | HISTORY                                                               |
REM |    23-ENE-17  abornanc         Created                                |
REM |                                                                       |
REM | NOTES                                                                 |
REM |                                                                       |
REM +=======================================================================+

spool xx_ar_fe_pe_sendss_pk.log

PROMPT =====================================================================
PROMPT Script XX_AR_FE_PE_SENDS_PK.sql
PROMPT =====================================================================

PROMPT Creando paquete XX_AR_FE_PE_SENDS_PK

create or replace package xx_ar_fe_pe_sends_pk authid current_user as

/* $Id: XX_AR_FE_PE_SENDSS_PK.sql 7995 2017-04-11 21:54:27Z augusto.bornancin@oracle.com $ */

-- -----------------------------------------------------------------------------
-- Variables Globales.
-- -----------------------------------------------------------------------------
  -- Debug.
  g_debug_flag     varchar2(1);
  g_debug_mode     varchar2(30);
  g_message_length number(15);
  -- Indentacion.
  g_indent      varchar2(2000) := '';

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
                                ) return varchar2;

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
                       ) return varchar2;

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
                           ) return varchar2;

/*=========================================================================+
|                                                                          |
| Private Function                                                         |
|    Get_supplier_name                                                     |
|                                                                          |
| Description                                                              |
|    Funcion privada que busca nombre de proveedor                         |
|                                                                          |
| Parameters                                                               |
|    p_taxpayer_id  IN  VARCHAR2                                           |
|    p_org_id       IN  NUMBER                                             |
|                                                                          |
+=========================================================================*/
function get_supplier_name(p_taxpayer_id       in varchar2
                         , p_taxpayer_doc_type in varchar2
                         , p_org_id            in number
                         ) return varchar2;

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
                         ,p_prestador          in varchar2) return varchar2;


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
                         ,x_procesado_fc_electronica   out varchar2);

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
|    p_territory_code  IN  VARCHAR2 Pa�s.                                  |
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
                        );

end xx_ar_fe_pe_sends_pk;
/

show errors

spool off;

exit;
