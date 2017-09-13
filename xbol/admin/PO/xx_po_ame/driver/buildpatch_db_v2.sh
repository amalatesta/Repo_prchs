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
#|     13-SEP-2017 - 1.0 - AKrajcsik - DSP - Created                     |
#|                                                                       |
#+=======================================================================*/

rm -rf $XBOL_TOP/patches/xx_po_ame_db_v2
rm -rf $XBOL_TOP/patches/xx_po_ame_db_v2.tar

# Creo el patch con el driver
echo 'Creando el patch con el driver'
$XBOL_TOP/bin/xxbuildpatch xx_po_ame_db_v2.drv xx_po_ame_db_v2

sleep 1

# Armo el tar
echo 'Armando el tar'
cd $XBOL_TOP/patches
tar -cvf xx_po_ame_db_v2.tar xx_po_ame_db_v2
