REM +==========================================================================+
REM |             Copyright (c) 2017 Oracle Argentina, Buenos Aires            |
REM |                         All rights reserved.                             |
REM +==========================================================================+
REM |  FILENAME                                                                |
REM |    xx_ap_inv_int_db_v1.sql                                               |
REM |                                                                          |
REM |  DESCRIPTION                                                             |
REM |    Realiza alter de la tabla xx_ap_inv_int para agregar campos           |
REM |    para la consideracion de las localizaciones para cada pais            |
REM |    a nivel regional                                                      |
REM |    Adding more columns for several regional adaptations                  |
REM |                                                                          |
REM |  LANGUAGE                                                                |
REM |    PL/SQL                                                                |
REM |                                                                          |
REM |  PRODUCT                                                                 |
REM |    Oracle Financials                                                     |
REM |                                                                          |
REM |  HISTORY                                                                 |
REM |    26-ENE-17 - AMalatesta - DSP - Created                                |
REM |                                                                          |
REM | NOTES                                                                    |
REM |                                                                          |
REM +==========================================================================+

SPOOL xx_ap_inv_int_db_v1.log

prompt =========================================================================
prompt script xx_ap_inv_int_db_v1.sql
prompt =========================================================================

prompt Realizando alter de la tabla bolinf.xx_ap_inv_int
alter table bolinf.xx_ap_inv_int add
(document_sub_type varchar2(150)
,global_attribute1 varchar2(150)
,global_attribute2 varchar2(150)
,global_attribute3 varchar2(150)
,global_attribute4 varchar2(150)
,global_attribute5 varchar2(150)
,global_attribute6 varchar2(150)
,global_attribute7 varchar2(150)
,global_attribute8 varchar2(150)
,global_attribute9 varchar2(150)
,global_attribute10 varchar2(150)
,global_attribute14 varchar2(150)
,global_attribute15 varchar2(150)
,global_attribute16 varchar2(150)
,global_attribute18 varchar2(150)
,global_attribute19 varchar2(150)
,global_attribute20 varchar2(150)
,attribute_category varchar2(150)
,attribute1 varchar2(150)
,attribute2 varchar2(150)
,attribute3 varchar2(150)
,attribute4 varchar2(150)
,attribute5 varchar2(150)
,attribute6 varchar2(150)
,attribute7 varchar2(150)
,attribute8 varchar2(150)
,attribute9 varchar2(150)
,attribute10 varchar2(150)
,attribute11 varchar2(150)
,attribute12 varchar2(150)
,attribute13 varchar2(150)
,attribute14 varchar2(150)
,attribute15 varchar2(150)
,global_attribute_category_l varchar2(150)
,global_attribute1_l varchar2(150)
,global_attribute2_l varchar2(150)
,global_attribute3_l varchar2(150)
,global_attribute4_l varchar2(150)
,global_attribute5_l varchar2(150)
,global_attribute6_l varchar2(150)
,global_attribute7_l varchar2(150)
,global_attribute8_l varchar2(150)
,global_attribute9_l varchar2(150)
,global_attribute10_l varchar2(150)
,global_attribute11_l varchar2(150)
,global_attribute12_l varchar2(150)
,global_attribute13_l varchar2(150)
,global_attribute14_l varchar2(150)
,global_attribute15_l varchar2(150)
,global_attribute16_l varchar2(150)
,global_attribute17_l varchar2(150)
,global_attribute18_l varchar2(150)
,global_attribute19_l varchar2(150)
,global_attribute20_l varchar2(150)
,attribute_category_l varchar2(150)
,attribute1_l varchar2(150)
,attribute2_l varchar2(150)
,attribute3_l varchar2(150)
,attribute4_l varchar2(150)
,attribute5_l varchar2(150)
,attribute6_l varchar2(150)
,attribute7_l varchar2(150)
,attribute8_l varchar2(150)
,attribute9_l varchar2(150)
,attribute10_l varchar2(150)
,attribute11_l varchar2(150)
,attribute12_l varchar2(150)
,attribute13_l varchar2(150)
,attribute14_l varchar2(150)
,attribute15_l varchar2(150));
/
show errors
spool off
exit
