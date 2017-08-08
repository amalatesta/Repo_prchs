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
#|     03-NOV-2016    AMalatesta     Created                             |
#|                                                                       |
#+=======================================================================*/

rm -rf $XBOL_TOP/patches/xx_gl_rpt_mayor_puc_nit_col_db_v1
rm -rf $XBOL_TOP/patches/xx_gl_rpt_mayor_puc_nit_col_db_v1.tar

# Creo el patch con el driver
echo 'Creando el patch con el driver'
$XBOL_TOP/bin/xxbuildpatch xx_gl_rpt_mayor_puc_nit_col_db_v1.drv xx_gl_rpt_mayor_puc_nit_col_db_v1

sleep 1

# Armo el tar
echo 'Armando el tar'
cd $XBOL_TOP/patches
tar -cvf xx_gl_rpt_mayor_puc_nit_col_db_v1.tar xx_gl_rpt_mayor_puc_nit_col_db_v1
