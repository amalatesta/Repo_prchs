# +=======================================================================+
# |    Copyright (c) 2017 Oracle Argentina, Buenos Aires                  |
# |                         All rights reserved.                          |
# +=======================================================================+
# | FILENAME                                                              |
# |    xxdownload_db_v5.sh                                                |
# |                                                                       |
# | DESCRIPTION                                                           |
# |    Script de Download                                                 |
# |                                                                       |
# | PRODUCT                                                               |
# |    Oracle Financials                                                  |
# |                                                                       |
# | HISTORY                                                               |
# |    07-SEP-2017 - 5.0 - AMalatesta - DSP - Created                     |
# |                                                                       |
# | NOTES                                                                 |
# |                                                                       |
# +=======================================================================+
echo '====================================================================='
echo 'Script xxdownload_db_v5.sh'
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

export NLS_LANG="AMERICAN_AMERICA.US7ASCII"

echo 'US - Bajando FFDD XX_OM_CUPO'
FNDLOAD $APPS_USER/$APPS_PWD@$BASE 0 Y DOWNLOAD $XBOL_TOP/admin/XX/util/import/xxflexfields.lct xx_om_ffdd_flg_n_rmbsnt_db_v5.ldt DESC_FLEX DESCRIPTIVE_FLEXFIELD_NAME=XX_ALL_EXTRA_ATTRIBUTES DESCRIPTIVE_FLEX_CONTEXT_CODE='OOL%' END_USER_COLUMN_NAME="XX_OM_FLG_N_RMBSNT"

echo '====================================================================='
echo 'End Objects Download.'
echo '====================================================================='