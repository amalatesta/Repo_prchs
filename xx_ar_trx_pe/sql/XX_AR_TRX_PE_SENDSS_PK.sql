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

spool XX_AR_TRX_PE_SENDSS_PK.log

prompt =====================================================================
prompt script XX_AR_TRX_PE_SENDSS_PK.sql
prompt =====================================================================

prompt creando paquete xx_ar_trx_pe_sendss_pk

create or replace package apps.xx_ar_trx_pe_sendss_pk authid current_user as
/* $Id: XX_AR_TRX_PE_SENDSS_PK.sql 1 2017-05-21 20:46:37 amalatesta@despegar.com $ */

-- -----------------------------------------------------------------------------
-- Variables Globales.
-- -----------------------------------------------------------------------------
  -- debug.
  g_debug_flag     varchar2(1);
  g_debug_mode     varchar2(30);
  g_message_length number(15);
  -- indentacion.
  g_indent         varchar2(32767) := '';
/*=========================================================================+
|                                                                          |
| private function                                                         |
|    get_supplier_name                                                     |
|                                                                          |
| description                                                              |
|    funcion privada que busca nombre de proveedor                         |
|                                                                          |
| parameters                                                               |
|    p_nit    in  varchar2                                                 |
|    p_org_id in  number                                                   |
|                                                                          |
+=========================================================================*/
function get_supplier_name(p_nit    in varchar2
                          ,p_org_id in number)
return varchar2;
/*=========================================================================+
|                                                                          |
| public function                                                          |
|    get_inventory_item_desc                                               |
|                                                                          |
| description                                                              |
|    funcion que obtiene la descripcion del articulo.                      |
|                                                                          |
| parameters                                                               |
|    p_organization_id   in  number  id orgnization de inventario.         |
|    p_inventory_item_id in number   id de articulo de inventario.         |
|                                                                          |
+=========================================================================*/
function get_inventory_item_desc(p_oe_line_id        in varchar2
                                ,p_origen            in varchar2
                                ,p_customer_trx_id   in number
                                ,p_trx_type          in varchar2
                                ,p_organization_id   in number
                                ,p_inventory_item_id in number
                                ,p_cust_trx_concept  in varchar2
                                ,p_rfc               in varchar2
                                ) return varchar2;
/*=========================================================================+
|                                                                          |
| public procedure                                                         |
|    generate_files                                                        |
|                                                                          |
| description                                                              |
|    procedimiento que genera los archivos de factura electronica.         |
|                                                                          |
| parameters                                                               |
|    errbuf            out varchar2 uso interno del concurrente.           |
|    retcode           out varchar2 uso interno del concurrente.           |
|    p_draft_mode      in  varchar2 modo draft (y/n).                      |
|    p_debug_flag      in  varchar2 flag de debug.                         |
|    p_cust_trx_type   in  number   tipo de transaccion.                   |
|    p_date_from       in  date     fecha desde.                           |
|    p_date_to         in  date     fecha hasta.                           |
|    p_trx_number_from in  varchar2 numero de transaccion desde.           |
|    p_trx_number_to   in  varchar2 numero de transaccion hasta.           |
|    p_territory_code  in  varchar2 pais.                                  |
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
                        );
/*=========================================================================+
|                                                                          |
| public procedure                                                         |
|    validate_files                                                        |
|                                                                          |
| description                                                              |
|    procedimiento que valida la generacion de archivos y ajusta estado.   |
|                                                                          |
| parameters                                                               |
|    errbuf            out varchar2 uso interno del concurrente.           |
|    retcode           out varchar2 uso interno del concurrente.           |
|    p_draft_mode      in  varchar2 modo draft (y/n).                      |
|    p_debug_flag      in  varchar2 flag de debug.                         |
|                                                                          |
+=========================================================================*/
procedure validate_files(errbuf            out varchar2
                        ,retcode           out number
                        ,p_draft_mode      in  varchar2
                        );
end xx_ar_fe_co_sends_pk;
/

show errors

spool off

exit
