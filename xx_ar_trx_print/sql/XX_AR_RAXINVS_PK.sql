REM +======================================================================+
REM |           Copyright (c) 2017 Oracle Argentina, Buenos Aires          |
REM |                         All rights reserved.                         |
REM +======================================================================+
REM |  FILENAME                                                            |
REM |    XX_AR_RAXINVS_PK.sql                                              |
REM |                                                                      |
REM |  DESCRIPTION                                                         |
REM |    Crea el paquete XX_AR_RAXINV_PK                                   |
REM |    que contiene funciones y procedimientos para el proceso de        |
REM |    impresion de facturas.                                            |
REM |                                                                      |
REM |  LANGUAGE                                                            |
REM |    PL/SQL                                                            |
REM |                                                                      |
REM |  PRODUCT                                                             |
REM |    Oracle Financials                                                 |
REM |                                                                      |
REM |  HISTORY                                                             |
REM |    02-ENE-17 - AMalatesta - DSP - Created                            |
REM |                                                                      |
REM | NOTES                                                                |
REM |                                                                      |
REM +======================================================================+

SPOOL XX_AR_RAXINVS_PK.log

prompt =====================================================================
prompt script XX_AR_RAXINVS_PK.sql
prompt =====================================================================

prompt creando paquete xx_ar_raxinv_pk
create or replace package xx_ar_raxinv_pk authid current_user as
/* $Id: XX_AR_RAXINVS_PK.sql 1.0 2017-01-02 18:04:00 amalatesta@despegar.com $ */

/*+======================================================================+*/
/*|           Copyright (c) 2017 Oracle Argentina, Buenos Aires          |*/
/*|                         All rights reserved.                         |*/
/*+======================================================================+*/
/*|  FILENAME                                                            |*/
/*|    XX_AR_RAXINVS_PK.sql                                              |*/
/*|                                                                      |*/
/*|  DESCRIPTION                                                         |*/
/*|    Crea el paquete XX_AR_RAXINV_PK                                   |*/
/*|    que contiene funciones y procedimientos para el proceso de        |*/
/*|    impresion de facturas.                                            |*/
/*|                                                                      |*/
/*|  LANGUAGE                                                            |*/
/*|    PL/SQL                                                            |*/
/*|                                                                      |*/
/*|  PRODUCT                                                             |*/
/*|    Oracle Financials                                                 |*/
/*|                                                                      |*/
/*|  HISTORY                                                             |*/
/*|    02-ENE-17 - AMalatesta - DSP - Created                            |*/
/*|                                                                      |*/
/*| NOTES                                                                |*/
/*|                                                                      |*/
/*+======================================================================+*/

/*------------------------------------------------------------------------*/
/*             Variables Globales                                         */
/*------------------------------------------------------------------------*/
  /*--Debug--*/
  g_debug_flag     varchar2(1);
  g_debug_mode     varchar2(30);
  g_message_length number(15);
  /*--Indentacion--*/
  g_indent      varchar2(2000) := '';
/*=========================================================================+
|                                                                          |
| Public Function                                                          |
|    Get_Inventory_Item_Desc                                               |
|                                                                          |
| Description                                                              |
|    Funcion que obtiene la descripcion del articulo.                      |
|                                                                          |
| Parameters                                                               |
|    p_organization_id   IN  NUMBER  Id Orgnization de Inventario.         |
|    p_inventory_item_id IN NUMBER   Id de Articulo de Inventario.         |
|                                                                          |
+=========================================================================*/
function get_inventory_item_desc
  (p_organization_id   in number
  ,p_inventory_item_id in number
  ,p_cust_trx_concept  in varchar2
  ,p_rfc               in varchar2)
return varchar2;
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
function item_imprime_prestador
  (p_organization_id   in number
  ,p_inventory_item_id in number)
return varchar2;
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
function get_receipt_method
  (p_receipt_method_id        in number
  ,p_cust_trx_type            in varchar2
  ,p_previous_customer_trx_id in number
  ,p_transaction_type         in varchar2)
return varchar2;
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
function get_supplier_name
  (p_taxpayer_id       in varchar2
  ,p_taxpayer_doc_type in varchar2
  ,p_org_id            in number)
return varchar2;
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
function get_desc_tercero
  (p_organization_id   in number
  ,p_inventory_item_id in number
  ,p_taxpayer_id       in varchar2
  ,p_taxpayer_doc_type in varchar2
  ,p_org_id            in number
  ,p_prestador         in varchar2)
return varchar2;
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
procedure get_datos_trx
  (p_customer_trx_id          in number
  ,x_trx_number               out varchar2
  ,x_trx_date                 out date
  ,x_electr_doc_type          out varchar2
  ,x_procesado_fc_electronica out varchar2);
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
procedure generate_files
  (errbuf out varchar2
  ,retcode out number
  ,p_draft_mode in varchar2
  ,p_debug_flag in varchar2
  ,p_batch_source in varchar2
  ,p_cust_trx_type in number
  ,p_trx_number_from in varchar2
  ,p_trx_number_to in varchar2
  ,p_date_from in varchar2
  ,p_date_to in varchar2
  ,p_customer_id in number
  ,p_territory_code in varchar2);
/*=========================================================================+
|                                                                          |
| Public Procedure                                                         |
|    upload_files                                                          |
|                                                                          |
| Description                                                              |
|    Procedimiento que carga el contenido de los archivos a la tabla de    |
|    envio.                                                                |
|                                                                          |
| Parameters                                                               |
|    p_interface_id IN      NUMBER   Id de la interface.                   |
|    p_request_id   IN      NUMBER   Id de concurrente de generacion de    |
|                                    la interface.                         |
|    p_debug_flag   IN      VARCHAR2 Flag de debug.                        |
|                                                                          |
+=========================================================================*/
procedure upload_files
  (p_interface_id in number
  ,p_request_id in number
  ,p_debug_flag in varchar2);
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
procedure report
  (errbuf           out varchar2
  ,retcode          out number
  ,p_interface_name in varchar2
  ,p_request_id     in number
  ,p_delete_flag    in varchar2
  ,p_debug_flag     in varchar2);
end xx_ar_raxinv_pk;
/
show errors
spool off
exit
