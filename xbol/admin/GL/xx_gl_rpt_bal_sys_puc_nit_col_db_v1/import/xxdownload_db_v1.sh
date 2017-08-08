# +=======================================================================+
# |    Copyright (c) 2016 Oracle Argentina, Buenos Aires                  |
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
# |    03-NOV-2016 1.0    AMalatesta          Created                     |
# |                                                                       |
# | NOTES                                                                 |
# |                                                                       |
# +=======================================================================+
echo '====================================================================='
echo 'Script xxdownload_db_v1.sh'
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

echo 'Bajando Programa Concurrente'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpprog.lct PC_XXGLBSSPN_db_v1.ldt PROGRAM APPLICATION_SHORT_NAME="XBOL" CONCURRENT_PROGRAM_NAME="XXGLBSSPN"

echo 'Bajando Grupo de Solicitudes'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpreqg.lct RGU_XXGLBSSPN_GCO_db_v1.ldt REQUEST_GROUP REQUEST_GROUP_NAME="XX_GL_GERENTE_CO" APPLICATION_SHORT_NAME="XBOL" REQUEST_GROUP_UNIT UNIT_APP="XBOL" UNIT_NAME="XXGLBSSPN"
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpreqg.lct RGU_XXGLBSSPN_GEG_db_v1.ldt REQUEST_GROUP REQUEST_GROUP_NAME="XX_GL_GERENTE" APPLICATION_SHORT_NAME="SQLGL" REQUEST_GROUP_UNIT UNIT_APP="XBOL" UNIT_NAME="XXGLBSSPN"
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpreqg.lct RGU_XXGLBSSPN_ANG_db_v1.ldt REQUEST_GROUP REQUEST_GROUP_NAME="XX_GL_ANALISTA" APPLICATION_SHORT_NAME="SQLGL" REQUEST_GROUP_UNIT UNIT_APP="XBOL" UNIT_NAME="XXGLBSSPN"
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $FND_TOP/patch/115/import/afcpreqg.lct RGU_XXGLBSSPN_CNG_db_v1.ldt REQUEST_GROUP REQUEST_GROUP_NAME="XX_GL_CONSULTAS" APPLICATION_SHORT_NAME="SQLGL" REQUEST_GROUP_UNIT UNIT_APP="XBOL" UNIT_NAME="XXGLBSSPN"
