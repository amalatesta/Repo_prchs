# +=======================================================================+
# |    Copyright (c) 2006 Oracle Argentina, Buenos Aires                  |
# |                         All rights reserved.                          |
# +=======================================================================+
# | FILENAME                                                              |
# |    xxdownload_db_v4.sh                                                |
# |                                                                       |
# | DESCRIPTION                                                           |
# |    Script de Download                                                 |
# |                                                                       |
# | PRODUCT                                                               |
# |    Oracle Financials                                                  |
# |                                                                       |
# | HISTORY                                                               |
# |    20-FEB-2017 1.0      Generic          Created                      |
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

echo 'Bajando objeto XX_XXPOCSTD'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE  0 Y DOWNLOAD $XDO_TOP/patch/115/import/xdotmpl.lct XX_XDO_XXPOCSTD_10.ldt XDO_DS_DEFINITIONS APPLICATION_SHORT_NAME='XBOL' DATA_SOURCE_CODE='XXPOCSTD'
