#/*======================================================================+
#|  Copyright (c) 2017 Oracle Corporation, Buenos Aires, Argentina       |
#|                         ALL rights reserved.                          |
#+=======================================================================+
#|                                                                       |
#| FILENAME                                                              |
#|     buildpatch_db.sh                                                  |
#|                                                                       |
#| DESCRIPTION                                                           |
#|     Script para crear el patch.                                       |
#|                                                                       |
#| HISTORY                                                               |
#|     24-ENE-2017     AMalatesta            Created                     |
#|                                                                       |
#+=======================================================================*/

rm -rf $XBOL_TOP/patches/xx_db_trg_cl_gl_db_v1
rm -rf $XBOL_TOP/patches/xx_db_trg_cl_gl_db_v1.tar

# Creo el patch con el driver
echo 'Creando el patch con el driver'
$XBOL_TOP/bin/xxbuildpatch xx_db_trg_cl_gl_db_v1.drv xx_db_trg_cl_gl_db_v1

sleep 1

# Armo el tar
echo 'Armando el tar'
cd $XBOL_TOP/patches
tar -cvf xx_db_trg_cl_gl_db_v1.tar xx_db_trg_cl_gl_db_v1
