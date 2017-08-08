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
# |    26-MAY-2017 - 1.0 - AMalatesta - DSP - Created                     |
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

echo 'US - Bajando Programa Concurrente XXARPETRXP'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpprog.lct cp_us_xx_ar_trx_pe_gen_db_v1.ldt PROGRAM APPLICATION_SHORT_NAME="XBOL" CONCURRENT_PROGRAM_NAME="XXARPETRXP"

echo 'US - Bajando objeto XXARPETRXP'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $XDO_TOP/patch/115/import/xdotmpl.lct cp_us_xx_ar_trx_pe_gen_xdo_db_v1.ldt XDO_DS_DEFINITIONS APPLICATION_SHORT_NAME="XBOL" DATA_SOURCE_CODE="XXARPETRXP"

echo 'US - Bajando Programa Concurrente XXARPETRXV'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpprog.lct cp_us_xx_ar_trx_pe_val_db_v1.ldt PROGRAM APPLICATION_SHORT_NAME="XBOL" CONCURRENT_PROGRAM_NAME="XXARPETRXV"

echo 'US - Bajando Juego de solicitudes XXARPETRXPSET'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcprset.lct rs_us_xx_ar_trx_pe_db_v1.ldt REQ_SET APPLICATION_SHORT_NAME="XBOL" REQUEST_SET_NAME="XXARPETRXPSET"

echo 'US - Bajando Links de Juego de solicitudes XXARPETRXPSET'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcprset.lct rsl_us_xx_ar_trx_pe_db_v1.ldt REQ_SET_LINKS APPLICATION_SHORT_NAME="XBOL" REQUEST_SET_NAME="XXARPETRXPSET"

echo 'US - Bajando Grupo de Solicitudes XX_AR_GERENTE para la unidad XXARPETRXP'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpreqg.lct rgu_us_xx_ar_trx_pe_gen_db_v1.ldt REQUEST_GROUP REQUEST_GROUP_NAME="XX_PE_AR_GERENTE" APPLICATION_SHORT_NAME="XBOL" REQUEST_GROUP_UNIT UNIT_APP="XBOL" UNIT_NAME="XXARPETRXP"

echo 'US - Bajando Grupo de Solicitudes XX_AR_GERENTE para la unidad XXARPETRXPSET'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpreqg.lct rgu_us_xx_ar_trx_pe_rs_db_v1.ldt REQUEST_GROUP REQUEST_GROUP_NAME="XX_PE_AR_GERENTE" APPLICATION_SHORT_NAME="XBOL" REQUEST_GROUP_UNIT UNIT_APP="XBOL" UNIT_NAME="XXARPETRXPSET"

echo '====================================================================='
echo 'End Objects Download.'
echo '====================================================================='
