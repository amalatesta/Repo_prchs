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
# |    06-ENE-2017 - 1.0 - AMalatesta - DSP - Created                     |
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

echo 'Bajando Programa Concurrente XXZXCLRSLL'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpprog.lct pc_xx_ar_sales_ledger_db_v1.ldt PROGRAM APPLICATION_SHORT_NAME="XBOL" CONCURRENT_PROGRAM_NAME="XXZXCLRSLL"

echo 'Bajando objeto XXZXCLRSLL'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $XDO_TOP/patch/115/import/xdotmpl.lct xdo_xx_ar_sales_ledger_db_v1.ldt XDO_DS_DEFINITIONS APPLICATION_SHORT_NAME='XBOL' DATA_SOURCE_CODE='XXZXCLRSLL'

echo 'Bajando Grupo de Solicitudes XX_CL_AR_GERENTE para la unidad XXZXCLRSLL'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpreqg.lct rgu_xx_ar_sales_ledger_db_v1.ldt REQUEST_GROUP REQUEST_GROUP_NAME="XX_CL_AR_GERENTE" APPLICATION_SHORT_NAME="XBOL" REQUEST_GROUP_UNIT UNIT_APP="XBOL" UNIT_NAME="XXZXCLRSLL"

echo '====================================================================='
echo 'End Objects Download.'
echo '====================================================================='