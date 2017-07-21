#/*======================================================================+
#|  Copyright (c) 2017 Oracle Corporation, Buenos Aires, Argentina       |
#|                         ALL rights reserved.                          |
#+=======================================================================+
#|                                                                       |
#| FILENAME                                                              |
#|     buildpatch_db_v3.sh                                               |
#|                                                                       |
#| DESCRIPTION                                                           |
#|     Script para crear el patch.                                       |
#|                                                                       |
#| HISTORY                                                               |
#|     21-JUL-2017 - 3.0 - AMalatesta - DSP - Modified                   |
#|                                                                       |
#+=======================================================================*/

rm -rf $XBOL_TOP/patches/xx_ar_rev_chkout_db_v3
rm -rf $XBOL_TOP/patches/xx_ar_rev_chkout_db_v3.tar

# Creo el patch con el driver
echo 'Creando el patch con el driver'
$XBOL_TOP/bin/xxbuildpatch xx_ar_rev_chkout_db_v3.drv xx_ar_rev_chkout_db_v3

sleep 1

# Armo el tar
echo 'Armando el tar'
cd $XBOL_TOP/patches
tar -cvf xx_ar_rev_chkout_db_v3.tar xx_ar_rev_chkout_db_v3
