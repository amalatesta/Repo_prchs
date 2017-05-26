#/*======================================================================+
#|  Copyright (c) 2005 Oracle Corporation, Buenos Aires, Argentina       |
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
#|     01-JAN-1951    giturbur         Created                           |
#|                                                                       |
#+=======================================================================*/

# Creo el patch con el driver
echo 'Creando el patch con el driver'
$XBOL_TOP/bin/xxbuildpatch xx_ar_fact_elec_pe_db_v1.drv xx_ar_fact_elec_pe_db_v1

# Armo el tar
echo 'Armando el tar'
cd $XBOL_TOP/patches
tar -cvf xx_ar_fact_elec_pe_db_v1.tar xx_ar_fact_elec_pe_db_v1


