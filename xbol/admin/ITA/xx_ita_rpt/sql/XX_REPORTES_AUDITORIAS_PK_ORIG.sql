create or replace PACKAGE      XX_REPORTES_AUDITORIA_PKG
AS

-- -----------------------------------------------------------------------------
-- CONSTANTS - Customizable.
-- -----------------------------------------------------------------------------
c_procname               CONSTANT VARCHAR2(30) := 'XX_REPORTES_AUDITORIA_PKG';
c_smtp_host              CONSTANT VARCHAR2(256) := Fnd_Profile.VALUE('XX_PO_SERVIDOR_SMTP');    --'10.1.1.10';
c_smtp_port              CONSTANT PLS_INTEGER   := Fnd_Profile.VALUE('OKS_SMTP_PORT');    --25;
c_smtp_domain            CONSTANT VARCHAR2(256) := NULL;                        --Fnd_Profile.VALUE('OKS_SMTP_DOMAIN');  --NULL;
c_from_name              CONSTANT VARCHAR2(256) := 'Notificaciones Oracle <ebs@despegar.com>';          --esta direcciÃ³n debe ser vÃ¡lida.
c_from_address           CONSTANT VARCHAR2(255) := 'Notificacion_Oracle';
c_crlf                   CONSTANT VARCHAR2( 2 ) := CHR(13)||CHR(10);
c_directory_name         CONSTANT VARCHAR2(100) := 'ECX_UTL_LOG_DIR_OBJ';       --'/var/tmp';
c_binary_files_directory CONSTANT VARCHAR2(100) := 'ECX_UTL_LOG_DIR_OBJ';       --'/var/tmp';
g_debug                           VARCHAR2(1)   := 'N';
--
-- -----------------------------------------------------------------------------
-- CONSTANTS - Not Customizable.
-- -----------------------------------------------------------------------------
c_boundary               CONSTANT VARCHAR2(256) := '-----7D81B75CCC90D2974F7A1CBD';
c_first_boundary         CONSTANT VARCHAR2(256) := '--'||c_boundary||Utl_Tcp.crlf;
c_last_boundary          CONSTANT VARCHAR2(256) := '--'||c_boundary||'--'||Utl_Tcp.crlf;
c_multipart_mime_type    CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary="'||c_boundary||'"';
c_mime_type_xls          CONSTANT VARCHAR2(256) := 'text/XLS';
c_max_base64_line_width  CONSTANT PLS_INTEGER   := 76 / 4 * 3;  -- 57
--


-- -----------------------------------------------------------------------------------------------------------
-- Name   : send_mail
-- Purpose: EnvÃ­a un mail con/sin un archivo de attachado.
--          El archivo puede ser de texto o binario (.pdf).
--          El body puede enviarse attachado en un archivo.
-- Params : p_to      : puede ser en formato 'Daniel Vartabedian <daniel.vartabedian@ua.com.ar>'
--          p_cc      : idem.
--          p_subject : asunto; se puede formatear con cÃ³digos html; por ej.: '<h1>Esto es el body</h1>'
--          p_body    : cuerpo del mail: Ã­dem.
--          p_body_attach: Y/N: indica si el body va a attacharse en un archivo.
--          p_filename: el archivo debe existir en el location pasado; el default es 'ECX_UTL_LOG_DIR_OBJ'.
--          p_location: ubicaciÃ³n del archivo que se va a attachar.
-- Notes  : En el caso en que p_body_attach = 'Y', el p_filename debe existir y
--          ser un tipo de archivo de texto (.lst, .txt, .out, .csv, etc.).
-- Return :
-- History: 03/02/2014  Created
-- -----------------------------------------------------------------------------------------------------------
PROCEDURE send_mail(
   p_to            IN   VARCHAR2,
   p_cc            IN   VARCHAR2 DEFAULT NULL,
   p_subject       IN   VARCHAR2 DEFAULT NULL,
   p_body          IN   VARCHAR2 DEFAULT NULL,
   p_body_attach   IN   VARCHAR2 DEFAULT 'N',
   p_filename      IN   VARCHAR2 DEFAULT NULL,
   p_location      IN   VARCHAR2 DEFAULT 'ECX_UTL_LOG_DIR_OBJ' );


-- -----------------------------------------------------------------------------
-- Name   : reporte_usaurios_respo
-- Purpose: genera un reporte de usuarios y responsabilidades.
-- Params : p_user_name: fnd_user.user_name
--          p_resp_name: fnd_responsibility_vl.responsibility_name
--          p_con_bajas: si incluye o no a usuarios dados de baja.
-- Return :
-- History: 12/04/2016  Created
-- -----------------------------------------------------------------------------
PROCEDURE reporte_usuarios_respo( errbuf      OUT VARCHAR2
                                 ,retcod      OUT VARCHAR2
                                 ,p_user_name  IN VARCHAR2
                                 ,p_resp_name  IN VARCHAR2
                                 ,p_con_bajas  IN VARCHAR2 );


-- -----------------------------------------------------------------------------
-- Name   : reporte_menu_conc
-- Purpose: genera un reporte con el Ã¡rbol de menÃº de una responsabilidad.
-- Params : p_resp_name: fnd_responsibility_vl.responsibility_name
--          p_con_conc: si incluye o no los concurrentes de esa respo.
-- Return :
-- History: 12/04/2016  Created
-- -----------------------------------------------------------------------------
PROCEDURE reporte_menu_conc( errbuf        OUT VARCHAR2
                            ,retcod        OUT VARCHAR2
                            ,p_resp_name    IN VARCHAR2
                            ,p_con_detalle  IN VARCHAR
                            ,p_con_conc     IN VARCHAR2 );


-- -----------------------------------------------------------------------------
-- Name   : concurrentes_por_respo
-- Purpose: busca en quÃ© responsabilidades se encuentra determinado concurrente.
-- Params : p_conc_name: fnd_concurrent_programs_vl.user_concurrent_program_name
--          p_resp_name: fnd_responsibility_vl.responsibility_name
-- Return :
-- History: 18/04/2016  Created
-- -----------------------------------------------------------------------------
PROCEDURE concurrentes_por_respo( errbuf      OUT VARCHAR2
                                 ,retcod      OUT VARCHAR2
                                 ,p_conc_name  IN VARCHAR2
                                 ,p_resp_name  IN VARCHAR2 );


-- -----------------------------------------------------------------------------
-- Name   : variables_de_perfil
-- Purpose: informa todas las variables de perfil de una responsabilidad.
-- Params : p_resp_name: fnd_responsibility_vl.responsibility_name
--          "XX Reporte de Variables de Perfil de una Responsabilidad".
-- Return :
-- History: 01/07/2016  Created
-- -----------------------------------------------------------------------------
PROCEDURE variables_de_perfil( errbuf      OUT VARCHAR2
                              ,retcod      OUT VARCHAR2
                              ,p_level      IN VARCHAR2
                              ,p_appl_name  IN VARCHAR2
                              ,p_resp_name  IN VARCHAR2
                              ,p_user_name  IN VARCHAR2 );

END xx_reportes_auditoria_pkg;