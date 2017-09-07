#/*======================================================================+
#|  Copyright (c) 2017 Oracle Corporation, Buenos Aires, Argentina       |
#|                         ALL rights reserved.                          |
#+=======================================================================+
#|                                                                       |
#| FILENAME                                                              |
#|     buildpatch_db_v5.sh                                               |
#|                                                                       |
#| DESCRIPTION                                                           |
#|     Script para crear el patch.                                       |
#|                                                                       |
#| HISTORY                                                               |
#|     07-SEP-2017 - 5.0 - AMalatesta - DSP - Modified                   |
#|                                                                       |
#+=======================================================================*/

rm -rf $XBOL_TOP/patches/xx_ar_rev_chkout_db_v5
rm -rf $XBOL_TOP/patches/xx_ar_rev_chkout_db_v5.tar

# Creo el patch con el driver
echo 'Creando el patch con el driver'
$XBOL_TOP/bin/xxbuildpatch xx_ar_rev_chkout_db_v5.drv xx_ar_rev_chkout_db_v5

sleep 1

# Armo el tar
echo 'Armando el tar'
cd $XBOL_TOP/patches
tar -cvf xx_ar_rev_chkout_db_v5.tar xx_ar_rev_chkout_db_v5
