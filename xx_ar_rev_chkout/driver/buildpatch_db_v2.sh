#/*======================================================================+
#|  Copyright (c) 2017 Oracle Corporation, Buenos Aires, Argentina       |
#|                         ALL rights reserved.                          |
#+=======================================================================+
#|                                                                       |
#| FILENAME                                                              |
#|     buildpatch_db_v1.sh                                               |
#|                                                                       |
#| DESCRIPTION                                                           |
#|     Script para crear el patch.                                       |
#|                                                                       |
#| HISTORY                                                               |
#|     26-JUN-2017 - 1.0 - AMalatesta - DSP - Modified                   |
#|                                                                       |
#+=======================================================================*/

rm -rf $XBOL_TOP/patches/xx_ar_rev_chkout_db_v2
rm -rf $XBOL_TOP/patches/xx_ar_rev_chkout_db_v2.tar

# Creo el patch con el driver
echo 'Creando el patch con el driver'
$XBOL_TOP/bin/xxbuildpatch xx_ar_rev_chkout_db_v2.drv xx_ar_rev_chkout_db_v2

sleep 1

# Armo el tar
echo 'Armando el tar'
cd $XBOL_TOP/patches
tar -cvf xx_ar_rev_chkout_db_v2.tar xx_ar_rev_chkout_db_v2
