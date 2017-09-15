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
#|     15-SEP-2017 - 1.0 - DVartabedian - DSP - Created                  |
#|                                                                       |
#+=======================================================================*/

rm -rf $XBOL_TOP/patches/xx_ita_rpt_db_v1
rm -rf $XBOL_TOP/patches/xx_ita_rpt_db_v1.tar

# Creo el patch con el driver
echo 'Creando el patch con el driver'
$XBOL_TOP/bin/xxbuildpatch xx_ita_rpt_db_v1.drv xx_ita_rpt_db_v1

sleep 1

# Armo el tar
echo 'Armando el tar'
cd $XBOL_TOP/patches
tar -cvf xx_ita_rpt_db_v1.tar xx_ita_rpt_db_v1
