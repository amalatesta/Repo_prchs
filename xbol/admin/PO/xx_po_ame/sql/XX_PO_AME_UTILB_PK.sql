REM +======================================================================+
REM |           Copyright (c) 2017 Oracle Argentina, Buenos Aires          |
REM |                         All rights reserved.                         |
REM +======================================================================+
REM |  FILENAME                                                            |
REM |    XX_PO_AME_UTILB_PK.sql                                            |
REM |                                                                      |
REM |  DESCRIPTION                                                         |
REM |    Crea el cuerpo del paquete XX_PO_AME_UTIL_PK                      |
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

SPOOL XX_PO_AME_UTILB_PK.log

prompt =====================================================================
prompt script XX_PO_AME_UTILB_PK.sql
prompt =====================================================================

prompt creando el cuerpo del paquete XX_PO_AME_UTIL_PK

create or replace PACKAGE BODY XX_PO_AME_UTIL_PK AS
/* $Header: XX_PO_AME_UTILB_PK.sql 1.0 2017-09-07 14:30:00 akrajcsik@despegar.com $ */
/*+======================================================================+*/
/*|           Copyright (c) 2017 Oracle Argentina, Buenos Aires          |*/
/*|                         All rights reserved.                         |*/
/*+======================================================================+*/
/*|  FILENAME                                                            |*/
/*|    XX_PO_AME_UTILB_PK.sql                                            |*/
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
RETURN VARCHAR2
IS

     --------------------
     -- Cursores
     ----------------------
    cursor cur_mkt_item is
        SELECT 1 mkt
        FROM APPS.po_headers_all ph, 
             APPS.po_line_locations_all pll , 
             APPS.PO_distributions_ALL Pd , 
             APPS.gl_code_combinations gcc , 
             APPS.PO_LINES_ALL PL 
        WHERE ph.po_header_id = pl.po_header_id 
        and pll.po_line_id = pl.po_line_id 
        and pll.line_location_id = pd.line_location_id 
        and pd.code_combination_id= gcc.code_combination_id 
        and (gcc.segment2 ||'.'|| gcc.segment3 ||'.'|| gcc.segment4 ||'.'|| gcc.segment6) 
        not in (select distinct  lookup_code  
                from  apps.fnd_lookup_values flv
                where flv.lookup_type = 'XX_BR_PO_AME_MKT')
        and ph.ame_approval_id = p_transaction_id    ; 
        
    cursor cur_fa_item is
        SELECT 1  fa
        FROM APPS.po_headers_all ph, 
             APPS.po_line_locations_all pll , 
             APPS.PO_distributions_ALL Pd , 
             APPS.gl_code_combinations gcc , 
             APPS.PO_LINES_ALL PL 
        WHERE ph.po_header_id = pl.po_header_id 
        and pll.po_line_id = pl.po_line_id 
        and pll.line_location_id = pd.line_location_id 
        and pd.code_combination_id= gcc.code_combination_id 
        and (gcc.segment2 ||'.'|| gcc.segment3) 
        not in (select distinct  lookup_code  
                from  apps.fnd_lookup_values flv
                where flv.lookup_type = 'XX_BR_PO_AME_FA')
        and ph.ame_approval_id = p_transaction_id    ; 
        
    cursor cur_rc_dt is
          SELECT 1 rc_dt
        FROM APPS.po_headers_all ph, 
             APPS.po_line_locations_all pll , 
             APPS.PO_distributions_ALL Pd , 
             APPS.gl_code_combinations gcc , 
             APPS.PO_LINES_ALL PL 
        WHERE ph.po_header_id = pl.po_header_id 
        and pll.po_line_id = pl.po_line_id 
        and pll.line_location_id = pd.line_location_id 
        and pd.code_combination_id= gcc.code_combination_id 
        and (gcc.segment4 ||'.'|| gcc.segment6) 
        not in (select distinct lookup_code 
                from  apps.fnd_lookup_values flv
                where flv.lookup_type = 'XX_BR_PO_AME_RC_DEPTO')
        and ph.ame_approval_id = p_transaction_id    ; 
    
    cursor cur_rc_pr_dt is
        SELECT 1  rc_pr_dt
        FROM APPS.po_headers_all ph, 
             APPS.po_line_locations_all pll , 
             APPS.PO_distributions_ALL Pd , 
             APPS.gl_code_combinations gcc , 
             APPS.PO_LINES_ALL PL 
        WHERE ph.po_header_id = pl.po_header_id 
        and pll.po_line_id = pl.po_line_id 
        and pll.line_location_id = pd.line_location_id 
        and pd.code_combination_id= gcc.code_combination_id 
        and (gcc.segment4 ||'.'|| gcc.segment5 ||'.' || gcc.segment6) 
        not in (select distinct  lookup_code  
                from  apps.fnd_lookup_values flv
                where flv.lookup_type = 'XX_BR_PO_AME_RC_PRODUCTO_DEPTO')
        and ph.ame_approval_id = p_transaction_id    ; 
     ---------------------
     -- Variables locales
     ---------------------
     l_mkt_c             cur_mkt_item%ROWTYPE;
     l_mkt               VARCHAR2(50):= NULL;
     
     l_fa_c              cur_fa_item%ROWTYPE;
     l_fa                VARCHAR2(50):= NULL;
     
     l_rc_dt_c           cur_rc_dt%ROWTYPE;
     l_rc_dt             VARCHAR2(50):= NULL;
     
     l_rc_pr_dt_c        cur_rc_pr_dt%ROWTYPE;
     l_rc_pr_dt          VARCHAR2(50):= NULL;

BEGIN

     -------------------------------------------------
     -- Verifico si el parametro de entrada es valido
     -------------------------------------------------
     IF (p_transaction_id IS NULL OR
         p_transaction_id <= 0) THEN
         RETURN 0;
     END IF;

     -------------------------------------------------
     -- Comienza recorrido del cursor
     -------------------------------------------------
     FOR l_mkt_c  IN cur_mkt_item LOOP
         l_mkt := l_mkt_c.mkt;
     END LOOP;

     FOR l_fa_c   IN cur_rc_dt LOOP
         l_fa := l_rc_dt_c.rc_dt;
     END LOOP;

     FOR l_rc_dt_c IN cur_rc_pr_dt LOOP
         l_rc_dt := l_rc_pr_dt_c.rc_pr_dt;
     END LOOP;
     
     FOR l_rc_pr_dt_c IN cur_rc_pr_dt LOOP
         l_rc_pr_dt := l_rc_pr_dt_c.rc_pr_dt;
     END LOOP;
     
     IF (l_mkt != NULL or l_fa !=  NULL or l_rc_dt !=  NULL or l_rc_pr_dt !=  NULL) THEN 
     RETURN '1001';
     ELSE RETURN '1000';
     END IF;
     
      
     
END Get_PO_BR_EXCEPTIONS;

/*=========================================================================+
|                                                                          |
| name    : Get_PO_SC_SOLICITANTE                                          |
| purpose : Traer el ID de solicitante de la SC                            |
|                                                                          |
+=========================================================================*/
FUNCTION Get_PO_SC_SOLICITANTE (p_transaction_id IN NUMBER)
RETURN VARCHAR2
IS

   --------------------
     -- Cursores
   ----------------------
       cursor cur_sc_sol is
                SELECT preparer_ID sol
                FROM apps.po_requisition_headers_all 
                WHERE requisition_header_id= p_transaction_id
                and preparer_ID not in (select distinct lookup_code 
                                        from  apps.fnd_lookup_values flv
                                        where flv.lookup_type = 'XX_BR_PO_SC_SOLICITANTES');


      ---------------------
     -- Variables locales
     ---------------------
     l_sc_sol_c             cur_sc_sol%ROWTYPE;
     l_sc_sol               VARCHAR2(50):= NULL;
BEGIN
     -------------------------------------------------
     -- Verifico si el parametro de entrada es valido
     -------------------------------------------------
     IF (p_transaction_id IS NULL OR
         p_transaction_id <= 0) THEN
         RETURN 0;
     END IF;

     -------------------------------------------------
     -- Comienza recorrido del cursor
     -------------------------------------------------
     FOR l_sc_sol_c  IN cur_sc_sol LOOP
         l_sc_sol := l_sc_sol_c.sol;
     END LOOP;
     
     IF l_sc_sol != NULL THEN 
     RETURN '1001';
     ELSE RETURN '1002';
     END IF;
 
END Get_PO_SC_SOLICITANTE;

END XX_PO_AME_UTIL_PK;
/
show errors
spool off
exit
