#/*======================================================================+
#|  Copyright (c) 2016 Oracle Corporation, Buenos Aires, Argentina       |
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
#|     09-NOV-2016    AMalatesta     Created                             |
#|                                                                       |
#+=======================================================================*/

rm -rf $XBOL_TOP/patches/xx_om_trg_afil_db_v1
rm -rf $XBOL_TOP/patches/xx_om_trg_afil_db_v1.tar

# Creo el patch con el driver
echo 'Creando el patch con el driver'
$XBOL_TOP/bin/xxbuildpatch xx_om_trg_afil_db_v1.drv xx_om_trg_afil_db_v1

sleep 1

# Armo el tar
echo 'Armando el tar'
cd $XBOL_TOP/patches
tar -cvf xx_om_trg_afil_db_v1.tar xx_om_trg_afil_db_v1