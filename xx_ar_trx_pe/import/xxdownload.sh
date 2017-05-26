# +=======================================================================+
# |    Copyright (c) 2017 Oracle Argentina, Buenos Aires                  |
# |                         All rights reserved.                          |
# +=======================================================================+
# | FILENAME                                                              |
# |    xxdownload.sh                                                      |
# |                                                                       |
# | DESCRIPTION                                                           |
# |    Script de Download                                                 |
# |                                                                       |
# | PRODUCT                                                               |
# |    Oracle Financials                                                  |
# |                                                                       |
# | HISTORY                                                               |
# |    24-MAY-2017 1.0     Generic          Created                       |
# |                                                                       |
# | NOTES                                                                 |
# |                                                                       |
# +=======================================================================+
echo '====================================================================='
echo 'Script xxdownload.sh'
echo '====================================================================='

echo 'Please, enter the APPS USER: '
read APPS_USER 
echo 'Please, enter the APPS PASSWORD: '
read APPS_PWD 
echo 'Please, enter the DATABASE name: '
read BASE 

echo 'Conecting with ' $APPS_USER
echo 'Base ' $BASE 
echo '====================================================================='
echo 'Begin Objects Download.'
echo '====================================================================='

echo 'Bajando objeto XX_XX_AR_FE_PE'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $XBOL_TOP/admin/XX/util/import/xxcustom.lct XX_CUS_XX_AR_FE_PE_0.ldt XX_CUSTOM_HEADERS CUSTOM_CODE=XX_AR_FE_PE

echo 'Bajando objeto XX_XX_AR_FE_PE_CREDIT_MEMO_REASON'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $FND_TOP/patch/115/import/aflvmlu.lct XX_LKP_XX_AR_FE_PE_CREDIT_MEMO_REASON_10.ldt FND_LOOKUP_TYPE LOOKUP_TYPE=XX_AR_FE_PE_CREDIT_MEMO_REASON

echo 'Bajando objeto XX_XX_AR_FE_PE_CURRENCIES'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $FND_TOP/patch/115/import/aflvmlu.lct XX_LKP_XX_AR_FE_PE_CURRENCIES_20.ldt FND_LOOKUP_TYPE LOOKUP_TYPE=XX_AR_FE_PE_CURRENCIES

echo 'Bajando objeto XX_XX_AR_FE_PE_TIPO_COMP_ELEC'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $FND_TOP/patch/115/import/aflvmlu.lct XX_LKP_XX_AR_FE_PE_TIPO_COMP_ELEC_15.ldt FND_LOOKUP_TYPE LOOKUP_TYPE=XX_AR_FE_PE_TIPO_COMP_ELEC

echo 'Bajando objeto XX_XX_AR_FE_PE_TIPO_COMP_ELEC'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $FND_TOP/patch/115/import/afffload.lct XX_VLS_XX_AR_FE_PE_TIPO_COMP_ELEC_60.ldt VALUE_SET FLEX_VALUE_SET_NAME=XX_AR_FE_PE_TIPO_COMP_ELEC

echo 'Bajando objeto XX_XX_AR_SRS_CUSTOMER_ID'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $FND_TOP/patch/115/import/afffload.lct XX_VLS_XX_AR_SRS_CUSTOMER_ID_100.ldt VALUE_SET FLEX_VALUE_SET_NAME=XX_AR_SRS_CUSTOMER_ID

echo 'Bajando objeto XX_XX_PE_FE_AR_BATCH_SOURCES'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $FND_TOP/patch/115/import/afffload.lct XX_VLS_XX_PE_FE_AR_BATCH_SOURCES_70.ldt VALUE_SET FLEX_VALUE_SET_NAME=XX_PE_FE_AR_BATCH_SOURCES

echo 'Bajando objeto XX_XX_PE_FE_AR_CUST_TRX_TYPES'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $FND_TOP/patch/115/import/afffload.lct XX_VLS_XX_PE_FE_AR_CUST_TRX_TYPES_100.ldt VALUE_SET FLEX_VALUE_SET_NAME=XX_PE_FE_AR_CUST_TRX_TYPES

echo 'Bajando objeto XX_XX_PE_FE_AR_TRX_NUMBERS'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $FND_TOP/patch/115/import/afffload.lct XX_VLS_XX_PE_FE_AR_TRX_NUMBERS_100.ldt VALUE_SET FLEX_VALUE_SET_NAME=XX_PE_FE_AR_TRX_NUMBERS

echo 'Bajando objeto XX_AR_SYSTEM_PARAMETERS'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $XBOL_TOP/admin/XX/util/import/xxflexfields.lct XX_DFF_AR_SYSTEM_PARAMETERS_40.ldt DESC_FLEX DESCRIPTIVE_FLEXFIELD_NAME=AR_SYSTEM_PARAMETERS DESCRIPTIVE_FLEX_CONTEXT_CODE='Global Data Elements' END_USER_COLUMN_NAME=XX_AR_DETRACTION_AMOUNT

echo 'Bajando objeto XX_RA_BATCH_SOURCES'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $XBOL_TOP/admin/XX/util/import/xxflexfields.lct XX_DFF_RA_BATCH_SOURCES_55.ldt DESC_FLEX DESCRIPTIVE_FLEXFIELD_NAME=RA_BATCH_SOURCES DESCRIPTIVE_FLEX_CONTEXT_CODE='PE' END_USER_COLUMN_NAME=

echo 'Bajando objeto XX_RA_CUST_TRX_TYPES'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $XBOL_TOP/admin/XX/util/import/xxflexfields.lct XX_DFF_RA_CUST_TRX_TYPES_30.ldt DESC_FLEX DESCRIPTIVE_FLEXFIELD_NAME=RA_CUST_TRX_TYPES DESCRIPTIVE_FLEX_CONTEXT_CODE='PE' END_USER_COLUMN_NAME=

echo 'Bajando objeto XX_XLE_LE_ADD_INFO'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $XBOL_TOP/admin/XX/util/import/xxflexfields.lct XX_DFF_XLE_LE_ADD_INFO_50.ldt DESC_FLEX DESCRIPTIVE_FLEXFIELD_NAME=XLE_LE_ADD_INFO DESCRIPTIVE_FLEX_CONTEXT_CODE='PE' END_USER_COLUMN_NAME=XX_XLE_UBIGEO_CODE

echo 'Bajando objeto XX_XXARPFEG'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $XBOL_TOP/admin/XX/util/import/xxconcurrents.lct XX_CNC_XXARPFEG_100.ldt PROGRAM CONCURRENT_PROGRAM_NAME=XXARPFEG

echo 'Bajando objeto XX_XXARPFER'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $XBOL_TOP/admin/XX/util/import/xxconcurrents.lct XX_CNC_XXARPFER_110.ldt PROGRAM CONCURRENT_PROGRAM_NAME=XXARPFER

echo 'Bajando objeto XX_XX_PE_AR_GERENTE'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpreqg.lct XX_GRP_XX_PE_AR_GERENTE_100.ldt REQUEST_GROUP REQUEST_GROUP_NAME='XX_PE_AR_GERENTE' UNIT_TYPE=P UNIT_NAME='XXARPFEG'
