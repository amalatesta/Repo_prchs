REM +======================================================================+
REM |           Copyright (c) 2017 Oracle Argentina, Buenos Aires          |
REM |                         All rights reserved.                         |
REM +======================================================================+
REM |  FILENAME                                                            |
REM |    XX_PO_AME_UTILS_PK.sql                                            |
REM |                                                                      |
REM |  DESCRIPTION                                                         |
REM |    Crea el paquete XX_PO_AME_UTIL_PK                                 |
REM |                                                                      |
REM |  LANGUAGE                                                            |
REM |    PL/SQL                                                            |
REM |                                                                      |
REM |  PRODUCT                                                             |
REM |    Oracle Financials                                                 |
REM |                                                                      |
REM |  HISTORY                                                             |
REM |    07-SEP-17 - AKrajcsik - DSP - Created                             |
REM |                                                                      |
REM | NOTES                                                                |
REM |                                                                      |
REM +======================================================================+

SPOOL XX_PO_AME_UTILS_PK.log

prompt =====================================================================
prompt script XX_PO_AME_UTILS_PK.sql
prompt =====================================================================

prompt creando paquete XX_PO_AME_UTIL_PK

create or replace PACKAGE XX_PO_AME_UTIL_PK AS
/* $Header: XX_PO_AME_UTILS_PK.sql 1.0 2017-09-07 14:30:00 akrajcsik@despegar.com $ */
/*+======================================================================+*/
/*|           Copyright (c) 2017 Oracle Argentina, Buenos Aires          |*/
/*|                         All rights reserved.                         |*/
/*+======================================================================+*/
/*|  FILENAME                                                            |*/
/*|    XX_PO_AME_UTILS_PK.sql                                            |*/
/*|                                                                      |*/
/*|  DESCRIPTION                                                         |*/
/*|    Crea el paquete XX_PO_AME_UTIL_PK                                 |*/
/*|                                                                      |*/
/*|  LANGUAGE                                                            |*/
/*|    PL/SQL                                                            |*/
/*|                                                                      |*/
/*|  PRODUCT                                                             |*/
/*|    Oracle Financials                                                 |*/
/*|                                                                      |*/
/*|  HISTORY                                                             |*/
/*|    07-SEP-17 - AKrajcsik - DSP - Created                             |*/
/*|                                                                      |*/
/*| NOTES                                                                |*/
/*|                                                                      |*/
/*+======================================================================+*/

/*=========================================================================+
|                                                                          |
| name    : Get_PO_BR_EXCEPTIONS                                           |
| purpose : Traer las excepciones a las reglas AME BR                      |
|                                                                          |
+=========================================================================*/
FUNCTION Get_PO_BR_EXCEPTIONS (p_transaction_id IN NUMBER)
RETURN VARCHAR2;

/*=========================================================================+
|                                                                          |
| name    : Get_PO_SC_SOLICITANTE                                          |
| purpose : Traer el ID de solicitante de la SC                            |
|                                                                          |
+=========================================================================*/
FUNCTION Get_PO_SC_SOLICITANTE (p_transaction_id IN NUMBER)
RETURN VARCHAR2;

END XX_PO_AME_UTIL_PK;
/
show errors
spool off
exit
