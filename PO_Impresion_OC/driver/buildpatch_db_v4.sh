#/*======================================================================+
#|  Copyright (c) 2005 Oracle Corporation, Buenos Aires, Argentina       |
#|                         ALL rights reserved.                          |
#+=======================================================================+
#|                                                                       |
#| FILENAME                                                              |
#|     buildpatch_db_v4.sh                                               |
#|                                                                       |
#| DESCRIPTION                                                           |
#|     Script para crear el patch.                                       |
#|                                                                       |
#| HISTORY                                                               |
#|     20-FEB-2017    cratto           Created                           |
#|                                                                       |
#+=======================================================================*/

# Creo el patch con el driver
echo 'Creando el patch con el driver'
$XBOL_TOP/bin/xxbuildpatch xx_po_impresion_oc_db_v4.drv xx_po_impresion_oc_db_v4
# Armo el tar
echo 'Armando el tar'
cd $XBOL_TOP/patches
tar -cvf xx_po_impresion_oc_db_v4.tar xx_po_impresion_oc_db_v4
