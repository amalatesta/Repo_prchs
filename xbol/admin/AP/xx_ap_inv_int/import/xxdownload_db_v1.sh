# +=======================================================================+
# |    Copyright (c) 2017 Oracle Argentina, Buenos Aires                  |
# |                         All rights reserved.                          |
# +=======================================================================+
# | FILENAME                                                              |
# |    xxdownload_db_v1.sh                                                |
# |                                                                       |
# | DESCRIPTION                                                           |
# |    Script de Download                                                 |
# |                                                                       |
# | PRODUCT                                                               |
# |    Oracle Financials                                                  |
# |                                                                       |
# | HISTORY                                                               |
# |    26-ENE-2017 - 1.0 - AMalatesta - DSP - Created                     |
# |                                                                       |
# | NOTES                                                                 |
# |                                                                       |
# +=======================================================================+
echo '====================================================================='
echo 'Script xxdownload_db_v1.sh'
echo '====================================================================='

if [ -z "$1" ]; then
   echo 'Please, enter the APPS USER: '
   read APPS_USER
else
   APPS_USER="$1"
fi;

if [ -z "$2" ]; then
   echo 'Please, enter the APPS PASSWORD: '
   stty -echo
   read APPS_PWD
   stty echo
else
   APPS_PWD="$2"
fi;

if [ -z "$3" ]; then
   echo 'Please, enter the DATABASE name: '
   read BASE
else
   BASE="$3"
fi;

echo 'Conecting with ' $APPS_USER
echo 'Base ' $BASE 
echo '====================================================================='
echo 'Begin Objects Download.'
echo '====================================================================='

export NLS_LANG="LATIN AMERICAN SPANISH_AMERICA.WE8ISO8859P1"

echo 'ESA - Bajando Programa Concurrente XX_AP_REG_INV_INT'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpprog.lct pc_esa_xx_ap_inv_int_db_v1_01.ldt PROGRAM APPLICATION_SHORT_NAME="XBOL" CONCURRENT_PROGRAM_NAME="XX_AP_REG_INV_INT"

echo 'ESA - Bajando Programa Concurrente XXAPREGINV'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpprog.lct pc_esa_xx_ap_inv_int_db_v1_02.ldt PROGRAM APPLICATION_SHORT_NAME="XBOL" CONCURRENT_PROGRAM_NAME="XXAPREGINV"

export NLS_LANG="BRAZILIAN PORTUGUESE_BRAZIL.WE8ISO8859P1"

echo 'PTB - Bajando Programa Concurrente XX_AP_REG_INV_INT'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpprog.lct pc_ptb_xx_ap_inv_int_db_v1_01.ldt PROGRAM APPLICATION_SHORT_NAME="XBOL" CONCURRENT_PROGRAM_NAME="XX_AP_REG_INV_INT"

echo 'PTB - Bajando Programa Concurrente XXAPREGINV'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpprog.lct pc_ptb_xx_ap_inv_int_db_v1_02.ldt PROGRAM APPLICATION_SHORT_NAME="XBOL" CONCURRENT_PROGRAM_NAME="XXAPREGINV"

export NLS_LANG="AMERICAN_AMERICA.US7ASCII"

echo 'US - Bajando Programa Concurrente XX_AP_REG_INV_INT'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpprog.lct pc_us_xx_ap_inv_int_db_v1_01.ldt PROGRAM APPLICATION_SHORT_NAME="XBOL" CONCURRENT_PROGRAM_NAME="XX_AP_REG_INV_INT"

echo 'US - Bajando Programa Concurrente XXAPREGINV'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpprog.lct pc_us_xx_ap_inv_int_db_v1_02.ldt PROGRAM APPLICATION_SHORT_NAME="XBOL" CONCURRENT_PROGRAM_NAME="XXAPREGINV"

echo 'US - Bajando Grupo de Solicitudes XX_CL_AP_GERENTE para la unidad XX_AP_REG_INV_INT'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpreqg.lct rgu_us_xx_ap_inv_int_db_v1_01.ldt REQUEST_GROUP REQUEST_GROUP_NAME="XX_CL_AP_GERENTE" APPLICATION_SHORT_NAME="XBOL" REQUEST_GROUP_UNIT UNIT_APP="XBOL" UNIT_NAME="XX_AP_REG_INV_INT"

echo 'US - Bajando Grupo de Solicitudes XX_CL_AP_GERENTE para la unidad XXAPREGINV'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpreqg.lct rgu_us_xx_ap_inv_int_db_v1_02.ldt REQUEST_GROUP REQUEST_GROUP_NAME="XX_CL_AP_GERENTE" APPLICATION_SHORT_NAME="XBOL" REQUEST_GROUP_UNIT UNIT_APP="XBOL" UNIT_NAME="XXAPREGINV"

echo '====================================================================='
echo 'End Objects Download.'
echo '====================================================================='