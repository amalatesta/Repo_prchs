rem +=======================================================================+
rem |    copyright (c) 2017 despegar.com argentina, buenos aires            |
rem |                         all rights reserved.                          |
rem +=======================================================================+
rem | filename                                                              |
rem |    XX_AR_TRX_PE_SENDSS_PK.sql                                         |
rem |                                                                       |
rem | description                                                           |
rem |    crea el paquete xx_ar_trx_pe_sends_pk                              |
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

spool xx_ar_trx_pe_sendss_pk.log

prompt =====================================================================
prompt Script XX_AR_TRX_PE_SENDSS_PK.sql
prompt =====================================================================

prompt Creando paquete xx_ar_trx_pe_sends_pk

create or replace package xx_ar_trx_pe_sends_pk authid current_user as
/* $Id: XX_AR_TRX_PE_SENDSS_PK.sql 1 2017-05-21 20:46:37 amalatesta@despegar.com $ */

-- -----------------------------------------------------------------------------
-- Variables Globales.
-- -----------------------------------------------------------------------------
  -- Debug.
  g_debug_flag     VARCHAR2(1);
  g_debug_mode     VARCHAR2(30);
  g_message_length NUMBER(15);
  -- Indentacion.
  g_indent      VARCHAR2(2000) := '';

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
FUNCTION Get_Inventory_Item_Desc(p_organization_id   IN  NUMBER
                                ,p_inventory_item_id IN  NUMBER
                                ,p_cust_trx_concept  IN  VARCHAR2
                                ,p_taxpayer_id       IN  VARCHAR2
                                ,p_taxpayer_doc_type IN  VARCHAR2
                                ,p_print_item_line   IN  VARCHAR2
                                ,p_line_description  IN  VARCHAR2
                                ) RETURN VARCHAR2;

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
FUNCTION Item_Imprime_Prestador(p_organization_id   IN  NUMBER
                      ,p_inventory_item_id IN  NUMBER
                       ) RETURN VARCHAR2;

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
FUNCTION Get_Receipt_Method(p_receipt_method_id        IN  NUMBER
                           ,p_cust_trx_type            IN  VARCHAR2
                           ,p_previous_customer_trx_id IN  NUMBER
                           ,p_transaction_type         IN  VARCHAR2
                           ) RETURN VARCHAR2;

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
FUNCTION Get_supplier_name(p_taxpayer_id       IN VARCHAR2
                         , p_taxpayer_doc_type IN VARCHAR2
                         , p_org_id            IN NUMBER
                         ) RETURN VARCHAR2;

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
FUNCTION Get_Desc_Tercero(p_organization_id    IN NUMBER
                         ,p_inventory_item_id  IN NUMBER
                         ,p_taxpayer_id        IN VARCHAR2
                         ,p_taxpayer_doc_type  IN VARCHAR2
                         ,p_org_id             IN NUMBER
                         ,p_prestador          IN VARCHAR2) RETURN VARCHAR2;


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
PROCEDURE  Get_Datos_Trx (p_customer_trx_id             IN NUMBER
                         ,x_trx_number                 OUT VARCHAR2
                         ,x_trx_date                   OUT DATE
                         ,x_electr_doc_type            OUT VARCHAR2
                         ,x_procesado_fc_electronica   OUT VARCHAR2);

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
|    p_territory_code  IN  VARCHAR2 País.                                  |
|                                                                          |
+=========================================================================*/
PROCEDURE generate_files(errbuf            OUT VARCHAR2
				   ,retcode           OUT NUMBER
                        ,p_draft_mode      IN  VARCHAR2
                        ,p_debug_flag      IN  VARCHAR2
                        ,p_batch_source    IN  VARCHAR2
                        ,p_cust_trx_type   IN  NUMBER
                        ,p_trx_number_from IN  VARCHAR2
                        ,p_trx_number_to   IN  VARCHAR2
                        ,p_date_from       IN  VARCHAR2
                        ,p_date_to         IN  VARCHAR2
                        ,p_customer_id     IN  NUMBER
                        ,p_territory_code  IN  VARCHAR2
                        ,p_process_errors  IN  VARCHAR2
                        );
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
                        ,p_draft_mode      in  varchar2);
end xx_ar_trx_pe_sends_pk;
/

show errors

spool off;

exit;
