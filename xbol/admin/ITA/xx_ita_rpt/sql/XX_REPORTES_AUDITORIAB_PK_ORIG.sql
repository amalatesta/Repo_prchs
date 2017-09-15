create or replace PACKAGE BODY      XX_REPORTES_AUDITORIA_PKG
AS

PROCEDURE enable_debug
IS
  l_dir_log            CONSTANT VARCHAR2(30) := 'ECX_UTL_LOG_DIR_OBJ';
  l_path                        VARCHAR2(480);
BEGIN
  g_debug := 'Y';
  --
/*
  BEGIN
    SELECT directory_path
      INTO l_path
     FROM all_directories
     WHERE directory_name = l_dir_log;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
        l_path := Fnd_Profile.VALUE('ECX_UTL_LOG_DIR_OBJ');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001,'No se pudo setear el directorio del debug; '||SQLERRM);
  END;
  --
  Fnd_File.put_names( 'UA_TEST_'||SYS_CONTEXT('USERENV','SESSIONID')||'.log'
                     ,'UA_TEST_'||SYS_CONTEXT('USERENV','SESSIONID')||'.out'
                     ,l_path );
*/
  Dbms_Output.Enable(1000000);
END enable_debug;

PROCEDURE disable_debug
IS
BEGIN
  g_debug := 'N';
  Fnd_File.CLOSE;
END disable_debug;

PROCEDURE show_debug( p_msg IN VARCHAR2 )
IS
BEGIN
  IF g_debug = 'Y' THEN
     Dbms_Output.Put_Line(SUBSTR(p_msg,1,255));
     Fnd_File.put_line(Fnd_File.LOG, p_msg);
  END IF;
END show_debug;

FUNCTION begin_session
   RETURN Utl_Smtp.connection
IS
   conn   Utl_Smtp.connection;
BEGIN
--open smtp connection
   conn := Utl_Smtp.open_connection (c_smtp_host, c_smtp_port);
   Utl_Smtp.helo (conn, c_smtp_domain);
   RETURN conn;
END begin_session;

FUNCTION get_address(addr_list IN OUT VARCHAR2)
         RETURN VARCHAR2
IS
   -- Variables.
   addr   VARCHAR2 (256);
   i      PLS_INTEGER;
   -- Procedimientos y Funciones.
   FUNCTION lookup_unquoted_char (str IN VARCHAR2, chrs IN VARCHAR2)
            RETURN PLS_INTEGER
   IS
      c              VARCHAR2 (5);
      i              PLS_INTEGER;
      len            PLS_INTEGER;
      inside_quote   BOOLEAN;
   BEGIN
      inside_quote := FALSE;
      i := 1;
      len := LENGTH (str);
      --
      WHILE (i <= len) LOOP
         c := SUBSTR (str, i, 1);
         IF (inside_quote) THEN
            IF (c = '"') THEN
               inside_quote := FALSE;
            ELSIF (c = '\') THEN
               i := i + 1;                     -- Skip the quote character
            END IF;
            GOTO next_char;
         END IF;
         IF (c = '"') THEN
            inside_quote := TRUE;
            GOTO next_char;
         END IF;
         IF (INSTR (chrs, c) >= 1) THEN
            RETURN i;
         END IF;
         <<next_char>>
         i := i + 1;
      END LOOP;
      --
      RETURN 0;
   END lookup_unquoted_char;
-- ----------------------------------------------
-- PROCEDIMIENTO PRINCIPAL.
-- ----------------------------------------------
BEGIN
   show_debug('get_address (+)');
   addr_list := LTRIM (addr_list);
   i := lookup_unquoted_char (addr_list, ',;');
   --
   IF (i >= 1) THEN
      addr := SUBSTR (addr_list, 1, i - 1);
      addr_list := SUBSTR (addr_list, i + 1);
   ELSE
      addr := addr_list;
      addr_list := '';
   END IF;
   --
   i := lookup_unquoted_char (addr, '<');
   --
   IF (i >= 1) THEN
      addr := SUBSTR (addr, i + 1);
      i := INSTR (addr, '>');
      --
      IF (i >= 1) THEN
         addr := SUBSTR (addr, 1, i - 1);
      END IF;
   END IF;
   --
   show_debug('get_address (-); addr = '||addr);
   RETURN addr;
END get_address;

-- Write a MIME header
PROCEDURE write_mime_header (
   conn    IN OUT NOCOPY   Utl_Smtp.connection,
   NAME    IN              VARCHAR2,
   VALUE   IN              VARCHAR2 )
IS
BEGIN
-- utl_smtp.write_data(conn, name || ': ' || value || utl_tcp.CRLF);
   Utl_Smtp.write_raw_data (conn, Utl_Raw.cast_to_raw( NAME||': '||VALUE||Utl_Tcp.crlf) );
END write_mime_header;



-- Mark a message-part boundary. SET <last> TO TRUE FOR the last boundary.
PROCEDURE write_boundary (
   conn   IN OUT NOCOPY   Utl_Smtp.connection,
   LAST   IN              BOOLEAN DEFAULT FALSE )
IS
BEGIN
   IF (LAST) THEN
      Utl_Smtp.write_data (conn, c_last_boundary);
   ELSE
      Utl_Smtp.write_data (conn, c_first_boundary);
   END IF;
END write_boundary;

PROCEDURE write_text (
   conn      IN OUT NOCOPY   Utl_Smtp.connection,
   MESSAGE   IN              VARCHAR2 )
IS
BEGIN
   show_debug('write_text (+)');
   Utl_Smtp.write_data (conn, MESSAGE);
   show_debug('write_text (-)');
END write_text;



PROCEDURE write_mb_text (
   conn      IN OUT NOCOPY   Utl_Smtp.connection,
   MESSAGE   IN              VARCHAR2 )
IS
BEGIN
   show_debug('write_mb_text (+)');
   Utl_Smtp.write_raw_data (conn, Utl_Raw.cast_to_raw (MESSAGE));
   show_debug('write_mb_text (-)');
END write_mb_text;



PROCEDURE write_raw (conn IN OUT NOCOPY Utl_Smtp.connection, MESSAGE IN RAW)
IS
BEGIN
   Utl_Smtp.write_raw_data (conn, MESSAGE);
END write_raw;


PROCEDURE begin_mail_in_session (
  conn         IN OUT NOCOPY   Utl_Smtp.connection,
  sender       IN              VARCHAR2,
  recipients   IN              VARCHAR2,
  cc           IN              VARCHAR2,
  subject      IN              VARCHAR2,
  mime_type    IN              VARCHAR2 DEFAULT 'text/plain',
  priority     IN              PLS_INTEGER DEFAULT NULL)
IS
  my_recipients   VARCHAR2 (32767) := recipients;
  my_sender       VARCHAR2 (32767) := sender;
  my_cc           VARCHAR2 (32767) := cc;
BEGIN
   show_debug('begin_mail_in_session (+)');
  -- Specify sender's address (our server allows bogus address as long as it is a full email address (xxx@yyy.com).
  Utl_Smtp.mail (conn, get_address (my_sender));
  -- Specify recipient(s) of the email.
  WHILE (my_recipients IS NOT NULL) LOOP
     Utl_Smtp.rcpt (conn, get_address (my_recipients));
  END LOOP;
  --
  WHILE (my_cc IS NOT NULL) LOOP
     Utl_Smtp.rcpt (conn, get_address (my_cc));
  END LOOP;
  --
  Utl_Smtp.open_data (conn);                        -- Start body of email
  write_mime_header (conn, 'From', sender);         -- Set "From" MIME header
  write_mime_header (conn, 'To', recipients);       -- Set "To" MIME header
  --
  IF cc IS NOT NULL THEN
     write_mime_header (conn, 'CC', cc);            -- Set "CC" MIME header
  END IF;
  --
  write_mime_header (conn, 'Date', TO_CHAR (SYSDATE, 'dd Mon yy hh24:mi:ss') );
  write_mime_header (conn, 'Subject', subject);         -- Set "Subject" MIME header
  write_mime_header (conn, 'Content-Type', mime_type);  -- Set "Content-Type" MIME header
  write_mime_header (conn, 'X-Mailer', c_from_name);    -- Set "X-Mailer" MIME header
  --
  IF (priority IS NOT NULL) THEN                        -- Set priority: High Normal Low (1 2 3 4 5)
     write_mime_header (conn, 'X-Priority', priority);
  END IF;
  -- Send an empty line to denotes end of MIME headers and eginning of message body.
  Utl_Smtp.write_data (conn, Utl_Tcp.crlf);
  --
  IF (mime_type LIKE 'multipart/mixed%') THEN
     write_text (conn, 'This is a multi-part message in MIME format.' || Utl_Tcp.crlf );
  END IF;
   show_debug('begin_mail_in_session (-)');
END begin_mail_in_session;



PROCEDURE end_mail_in_session (conn IN OUT NOCOPY Utl_Smtp.connection)
IS
BEGIN
   Utl_Smtp.close_data (conn);
END end_mail_in_session;



PROCEDURE end_session (conn IN OUT NOCOPY Utl_Smtp.connection)
IS
BEGIN
   Utl_Smtp.quit (conn);
END end_session;



FUNCTION begin_mail (
   sender       IN   VARCHAR2,
   recipients   IN   VARCHAR2,
   cc           IN   VARCHAR2 DEFAULT NULL,
   subject      IN   VARCHAR2,
   mime_type    IN   VARCHAR2 DEFAULT 'text/plain',
   priority     IN   PLS_INTEGER DEFAULT NULL )
   RETURN Utl_Smtp.connection
IS
   conn   Utl_Smtp.connection;
BEGIN
   show_debug('begin_mail (+)');
   conn := begin_session;
   begin_mail_in_session (conn,
                          sender,
                          recipients,
                          cc,
                          subject,
                          mime_type,
                          priority );
   show_debug('begin_mail (-)');
   RETURN conn;
END begin_mail;

PROCEDURE begin_attachment (
   conn           IN OUT NOCOPY   Utl_Smtp.connection,
   mime_type      IN              VARCHAR2 DEFAULT 'text/plain',
   INLINE         IN              BOOLEAN DEFAULT TRUE,
   filename       IN              VARCHAR2 DEFAULT NULL,
   transfer_enc   IN              VARCHAR2 DEFAULT NULL)
IS
BEGIN
   write_boundary (conn);
   write_mime_header (conn, 'Content-Type', mime_type);
   --
   IF (filename IS NOT NULL) THEN
      IF (INLINE) THEN
         write_mime_header (conn,
                            'Content-Disposition',
                            'inline; filename="' || filename || '"' );
      ELSE
         write_mime_header (conn,
                            'Content-Disposition',
                            'attachment; filename="' || filename || '"' );
      END IF;
   END IF;
   --
   IF (transfer_enc IS NOT NULL) THEN
      write_mime_header (conn, 'Content-Transfer-Encoding', transfer_enc);
   END IF;
   --
   Utl_Smtp.write_data (conn, Utl_Tcp.crlf);
END begin_attachment;



PROCEDURE end_attachment (
   conn   IN OUT NOCOPY   Utl_Smtp.connection,
   LAST   IN              BOOLEAN DEFAULT FALSE)
IS
BEGIN
   Utl_Smtp.write_data (conn, Utl_Tcp.crlf);
   --
   IF (LAST) THEN
      write_boundary (conn, LAST);
   END IF;
END end_attachment;


PROCEDURE attach_text (
   conn        IN OUT NOCOPY   Utl_Smtp.connection,
   DATA        IN              VARCHAR2,
   mime_type   IN              VARCHAR2 DEFAULT 'text/plain',
   INLINE      IN              BOOLEAN DEFAULT TRUE,
   filename    IN              VARCHAR2 DEFAULT NULL,
   LAST        IN              BOOLEAN DEFAULT FALSE )
IS
BEGIN
   show_debug('attach_text (+)');
   begin_attachment (conn, mime_type, INLINE, filename);
   write_text (conn, DATA);
   end_attachment (conn, LAST);
   show_debug('attach_text (-)');
END attach_text;



PROCEDURE attach_mb_text (
   conn        IN OUT NOCOPY   Utl_Smtp.connection,
   DATA        IN              VARCHAR2,
   mime_type   IN              VARCHAR2 DEFAULT 'text/plain',
   INLINE      IN              BOOLEAN DEFAULT TRUE,
   filename    IN              VARCHAR2 DEFAULT NULL,
   LAST        IN              BOOLEAN DEFAULT FALSE )
IS
BEGIN
   show_debug('attach_mb_text (+)');
   begin_attachment (conn, mime_type, INLINE, filename);
   Utl_Smtp.write_raw_data (conn, Utl_Raw.cast_to_raw (DATA));
--write_text(conn, data);
   end_attachment (conn, LAST);
   show_debug('attach_mb_text (-)');
END attach_mb_text;



PROCEDURE attach_base64 (
   conn        IN OUT NOCOPY   Utl_Smtp.connection,
   DATA        IN              RAW,
   mime_type   IN              VARCHAR2 DEFAULT 'application/octet',
   INLINE      IN              BOOLEAN DEFAULT TRUE,
   filename    IN              VARCHAR2 DEFAULT NULL,
   LAST        IN              BOOLEAN DEFAULT FALSE)
IS
   i     PLS_INTEGER;
   len   PLS_INTEGER;
BEGIN
   begin_attachment (conn, mime_type, INLINE, filename, 'base64');
--Split the Base64-encoded attachment into multiple lines
   i := 1;
   len := Utl_Raw.LENGTH (DATA);
   --
   WHILE (i < len) LOOP
      IF (i + c_max_base64_line_width < len) THEN
         Utl_Smtp.write_raw_data(conn, Utl_Encode.base64_encode(Utl_Raw.SUBSTR(DATA,i,c_max_base64_line_width)) );
      ELSE
         Utl_Smtp.write_raw_data(conn, Utl_Encode.base64_encode(Utl_Raw.SUBSTR(DATA,i)) );
      END IF;
      --
      Utl_Smtp.write_data (conn, Utl_Tcp.crlf);
      i := i + c_max_base64_line_width;
   END LOOP;
   --
   end_attachment (conn, LAST);
END attach_base64;




PROCEDURE end_mail (conn IN OUT NOCOPY Utl_Smtp.connection)
IS
BEGIN
   end_mail_in_session (conn);
   end_session (conn);
END end_mail;






FUNCTION get_email_address( p_user_id IN NUMBER )
         RETURN VARCHAR2
IS
  l_email_address           fnd_user.email_address%TYPE;
BEGIN
  SELECT email_address
    INTO l_email_address
    FROM fnd_user
   WHERE user_id = NVL(p_user_id,Fnd_Global.user_id);
  --
  RETURN( l_email_address );
EXCEPTION
  WHEN NO_DATA_FOUND THEN
       show_debug('No se encontrÃ³ el usuario '||NVL(p_user_id,Fnd_Global.user_id));
       RETURN( TO_CHAR(NULL) );
  WHEN OTHERS THEN
       show_debug('Error al buscar al usuario '||NVL(p_user_id,Fnd_Global.user_id)||'; '||SQLERRM);
       Raise_Application_Error(-20001,'Error al buscar al usuario '||NVL(p_user_id,Fnd_Global.user_id)||'; '||SQLERRM);
END get_email_address;


PROCEDURE get_distribution_list( p_distribution_list  IN VARCHAR2
                                ,x_to                OUT VARCHAR2
                                ,x_cc                OUT VARCHAR2 )
IS
--  l_to                           alr_distribution_lists.to_recipients%TYPE;
--  l_cc                           alr_distribution_lists.cc_recipients%TYPE;
BEGIN
  --
  -- Si el l_to estÃ¡ vacÃ­o, pero hay datos en el l_cc, entonces mando el l_cc a l_to, y dejo el l_cc vacÃ­o.
  SELECT NVL(to_recipients,cc_recipients)              to_recipients
        ,DECODE(to_recipients,NULL,NULL,cc_recipients) cc_recipients
    INTO x_to, x_cc
    FROM alr_distribution_lists
   WHERE NAME = p_distribution_list
     AND NVL(enabled_flag,'N') = 'Y'
     AND NVL(end_date_active,TRUNC(SYSDATE)) >= TRUNC(SYSDATE);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
       show_debug('No se encontrÃ³ la lista de distribuciÃ³n: '||p_distribution_list);
       x_to := TO_CHAR(NULL);
       x_cc := TO_CHAR(NULL);
  WHEN OTHERS THEN
       show_debug('Error al buscar la lista de distribuciÃ³n: '||p_distribution_list||'; '||SQLERRM);
       Raise_Application_Error(-20001,'Error al buscar la lista de distribuciÃ³n: '||p_distribution_list||'; '||SQLERRM);
END get_distribution_list;



-- -----------------------------------------------------------------------------
-- Name   : with_text_attach
-- Purpose: EnvÃ­a un mail con un archivo de texto attachado.
-- Params : p_to      : puede ser en formato 'Daniel Vartabedian <daniel.vartabedian@ua.com.ar>'
--          p_cc      : Ã­dem.
--          p_subject : asunto; se puede formatear con cÃ³digos html; por ej.: '<h1>Esto es el body</h1>'
--          p_body    : cuerpo del mail: Ã­dem.
--          p_filename: el archivo debe existir en Fnd_Profile.Value('ECX_UTL_LOG_DIR_OBJ').
-- Return :
-- History: 04/02/2014  Created
-- -----------------------------------------------------------------------------
PROCEDURE with_text_attach (
   p_to         IN   VARCHAR2,
   p_cc         IN   VARCHAR2,
   p_subject    IN   VARCHAR2,
   p_body       IN   VARCHAR2,
   p_filename   IN   VARCHAR2 DEFAULT NULL,
   p_location   IN   VARCHAR2 )
IS
   l_procname      VARCHAR2(70) := c_procname || '.WITH_TEXT_ATTACH';
   l_conn          Utl_Smtp.connection;
   l_file_handle   Utl_File.FILE_TYPE;
   l_line          VARCHAR2(1000);
   l_message       VARCHAR2(32767);
BEGIN
   show_debug (l_procname || ' (+)');
   l_conn := begin_mail( sender          => c_from_name,
                         recipients      => p_to,
                         cc              => p_cc,
                         subject         => p_subject,
                         mime_type       => c_multipart_mime_type );
   show_debug ('  Hizo el begin_mail');
   -- El primer llamado al attach_text es para el body (se puede formatear con cÃ³digos HTML).
   attach_mb_text( conn           => l_conn,
                   DATA           => p_body,  --||c_crlf||c_crlf
                   mime_type      => 'text/html; charset=iso-8859-1' );
   show_debug ('  Hizo el attach_mb_file');
   --
   -- Para hacer el attach, empezar con el begin_attachment, continuar con el
   -- write_text tantas veces como piezas haya, y finalizar con end_attachment.
   IF p_filename IS NOT NULL THEN
      BEGIN
         begin_attachment( conn              => l_conn,
                           mime_type         => 'text/plain; charset=iso-8859-1',
                           INLINE            => TRUE,
                           filename          => p_filename,
                           transfer_enc      => '8 bit' );
         show_debug ('  Hizo el begin_attachment');
         BEGIN
            show_debug('  Abre el archivo en: '||p_location||' (+)');
            l_file_handle := Utl_File.FOPEN(p_location, p_filename, 'r');
            LOOP
               Utl_File.GET_LINE (l_file_handle, l_line);
               l_message := l_line || c_crlf;
--               write_text(conn => l_conn, message => l_message);        -- funciona ok!
               write_mb_text (conn => l_conn, message => l_message );   -- funciona ok! (es la original)
--             write_raw(conn => l_conn, message => l_message);           -- para archivos de text no funciona.
            END LOOP;
            show_debug ('  Abre el archivo (-)');
         EXCEPTION
            WHEN OTHERS THEN  -- siempre sale por aquÃ­, cuando deja de encontrar datos.
                 NULL;
         END;
         --
         Utl_File.FCLOSE (l_file_handle);
         end_attachment(conn => l_conn);  -- Si no se llama al end_attachment, no se attacha el archivo.
      END;
      show_debug ('  Va a cerrar el attach y el mail');
   END IF;
--
--end_attachment( conn => l_conn );
-- Siempre finalizar con end_mail.
   end_mail (conn => l_conn);
   show_debug (l_procname || ' (-)');
EXCEPTION
  WHEN NO_DATA_FOUND THEN
       show_debug(   'Salio por NDF en with_text_attach; '||SQLERRM);
       end_attachment (conn => l_conn);
       end_mail (conn => l_conn);
  WHEN OTHERS THEN
       show_debug(   'Error el enviar mail en with_text_attach; '||SQLERRM);
       end_attachment (conn => l_conn);
       end_mail (conn => l_conn);
END with_text_attach;



-- -----------------------------------------------------------------------------
-- Name   : with_binary_attach
-- Purpose: EnvÃ­a un mail con un archivo binario (por ejemplo, un .pdf) attachado.
-- Params : p_to      : puede ser en formato 'Daniel Vartabedian <daniel.vartabedian@ua.com.ar>'
--          p_cc      : Ã­dem.
--          p_subject : asunto; se puede formatear con cÃ³digos html; por ej.: '<h1>Esto es el body</h1>'
--          p_body    : cuerpo del mail: Ã­dem.
--          p_filename: el archivo debe existir en Fnd_Profile.Value('ECX_UTL_LOG_DIR_OBJ').
-- Return :
-- History: 04/02/2014  Created
-- -----------------------------------------------------------------------------
PROCEDURE with_binary_attach (
   p_to         IN   VARCHAR2,
   p_cc         IN   VARCHAR2,
   p_subject    IN   VARCHAR2,
   p_body       IN   VARCHAR2,
   p_filename   IN   VARCHAR2,
   p_location   IN   VARCHAR2 )
IS
   l_procname        VARCHAR2 (70)  := c_procname || '.WITH_BINARY_ATTACH';
   l_conn            Utl_Smtp.connection;
   l_file_handle     Utl_File.FILE_TYPE;
   l_line            VARCHAR2 (1000);
   l_message         VARCHAR2 (32767);
   l_mime_type_bin   VARCHAR2 (30) := 'application/pdf';
   l_bfile           BFILE;
--  l_file_handle             UTL_FILE.file_type;
   l_length          PLS_INTEGER;
   l_amt             BINARY_INTEGER := 672 * 3;
   l_modulo          PLS_INTEGER;
   l_pieces          PLS_INTEGER;
   l_filepos         PLS_INTEGER := 1;     -- pointer for the file
   l_buf             RAW (2100);
   l_chunks          PLS_INTEGER;
   max_line_width    PLS_INTEGER := 54;
   l_data            RAW (2100);
BEGIN
   show_debug (l_procname || ' (+)');
   l_conn := begin_mail( sender         => c_from_name,
                         recipients      => p_to,
                         cc              => p_cc,
                         subject         => p_subject,
                         mime_type       => c_multipart_mime_type );
   show_debug ('  Hizo el begin_mail');
   -- El primer llamado al attach_text es para el subject y el body (se puede formatear con cÃ³digos HTML).
   attach_mb_text( conn       => l_conn,
                   DATA       => p_body,   --p_subject||c_crlf||c_crlf||p_body
                   mime_type  => 'text/html; charset=iso-8859-1' );
   show_debug ('  Hizo el attach_mb_file');
   --
   -- Para hacer el attach, empezar con el begin_attachment, continuar con el
   -- write_text tantas veces como piezas haya, y finalizar con end_attachment.
   BEGIN
      begin_attachment (conn              => l_conn,
                        mime_type         => l_mime_type_bin,
                        INLINE            => TRUE,
                        filename          => p_filename,
                        transfer_enc      => 'base64' );
      show_debug ('  Hizo el begin_attachment');
      BEGIN
         show_debug ('Busca el archivo ' || p_filename);
--         l_bfile := BFILENAME (c_binary_files_directory, p_filename);
         l_bfile := BFILENAME(p_location, p_filename);
         show_debug ('Abre el archivo binario');
         l_length := Dbms_Lob.Getlength (l_bfile);
         show_debug ('Longitud del archivo: ' || l_length);
         l_modulo := MOD (l_length, l_amt);
         show_debug ('MÃ³dulo = '||l_modulo);
         --
         -- Si el archivo es muy chico, no manda el mail.
         IF l_length < (672*3) THEN
            l_amt := 672;
         END IF;
         --
         l_pieces := TRUNC (l_length / l_amt);
         --
         IF l_modulo <> 0 THEN
            l_pieces := l_pieces + 1;
         END IF;
         show_debug ('Cant. Piezas: ' || l_pieces);
         Dbms_Lob.Fileopen (l_bfile, Dbms_Lob.File_Readonly);
         -- Lee el primer amt y lo manda al buffer.
         Dbms_Lob.Read (l_bfile, l_amt, l_filepos, l_buf);
         l_data := NULL;
         show_debug ('Loop por cada pieza de archivo (+)');
         --
         FOR i IN 1 .. l_pieces LOOP
            l_filepos := i * l_amt + 1;                                     -- Position file pointer for next read
            l_length := l_length - l_amt;                                   -- Calculate remaining file length
            l_data := Utl_Raw.CONCAT (l_data, l_buf);                       -- Stick the buffer contents into data
            l_chunks := TRUNC (Utl_Raw.LENGTH (l_data) / max_line_width);   -- calculate the number of chunks in this piece
            show_debug('  l_filepos = '||l_filepos);
            show_debug('  l_length  = '||l_length);
            --
            IF i <> l_pieces THEN   -- don't want too many chunks
               l_chunks := l_chunks - 1;
            END IF;
            show_debug('  l_chunks  = '||l_chunks);
            write_raw( conn         => l_conn,
                                      MESSAGE      => Utl_Encode.base64_encode(l_data));
            show_debug('  Hizo el write_raw');
            l_data := NULL;
            IF l_length < l_amt AND l_length > 0 THEN          -- We're running out of file, only get the rest of it
               l_amt := l_length;
            END IF;
            show_debug('  l_amt = '||l_amt);
            Dbms_Lob.Read (l_bfile, l_amt, l_filepos, l_buf);  -- Read the next amount into the buffer
         END LOOP;
         show_debug ('Loop por cada pieza de archivo (-)');
      END;
      -- Cierra el archivo, el attach y el mail.
      Dbms_Lob.Fileclose (l_bfile);
      end_attachment (conn => l_conn);
   END;
   end_mail (conn => l_conn);
EXCEPTION
   WHEN NO_DATA_FOUND THEN
        end_attachment (conn => l_conn);
        Dbms_Lob.Fileclose (l_bfile);
   WHEN OTHERS THEN
        end_attachment (conn => l_conn);
        show_debug ('Error en ' || l_procname || '; ' || SQLERRM);
END with_binary_attach;




-- -----------------------------------------------------------------------------
-- Name   : with_body_attach
-- Purpose: EnvÃ­a un mail con un archivo de texto attachado con el contenido del body.
-- Params : p_to      : puede ser en formato 'Daniel Vartabedian <daniel.vartabedian@ua.com.ar>'
--          p_cc      : Ã­dem.
--          p_subject : asunto; se puede formatear con cÃ³digos html; por ej.: '<h1>Esto es el body</h1>'
--          p_body    : cuerpo del mail: Ã­dem.
--          p_filename: el archivo debe existir en Fnd_Profile.Value('ECX_UTL_LOG_DIR_OBJ').
-- Return :
-- History: 04/02/2014  Created
-- -----------------------------------------------------------------------------
PROCEDURE with_body_attach (
   p_to         IN   VARCHAR2,
   p_cc         IN   VARCHAR2 DEFAULT NULL,
   p_subject    IN   VARCHAR2 DEFAULT NULL,
   p_body       IN   VARCHAR2 DEFAULT NULL,
   p_filename   IN   VARCHAR2 DEFAULT NULL,
   p_location   IN   VARCHAR2 )
IS
   l_conn   Utl_Smtp.connection;
   l_msg    VARCHAR2 (32000);
   l_to     VARCHAR2 (2000) := p_to;
   l_cc     VARCHAR2 (2000) := p_cc;
BEGIN
   l_conn := Utl_Smtp.open_connection (c_smtp_host);
   Utl_Smtp.helo (l_conn, c_smtp_host);
   Utl_Smtp.mail (l_conn, '< ' || c_from_address || ' >');
   --
   -- Specify recipient(s) of the email.
   WHILE (l_to IS NOT NULL) LOOP
      Utl_Smtp.rcpt (l_conn, get_address (l_to));
   END LOOP;
   --
   WHILE (l_cc IS NOT NULL)
   LOOP
      Utl_Smtp.rcpt (l_conn, get_address (l_cc));
   END LOOP;
   --
   --
   IF p_filename IS NULL  THEN
      l_msg :=  'Date: '||SYSDATE||c_crlf||
                'From: '||c_from_name||c_crlf||
                'Subject: '||p_subject||c_crlf||''||c_crlf;
      Utl_Smtp.DATA (l_conn, l_msg || p_body);
   ELSE
      Utl_Smtp.open_data(l_conn);
      Utl_Smtp.write_data(l_conn, 'From'||': '||'"'||c_from_name||'" <'||c_from_address||'>'||c_crlf);
      Utl_Smtp.write_data (l_conn,'To'  ||': '||''||p_to||''||c_crlf);
      Utl_Smtp.write_data (l_conn,'cc'  ||': '||''||p_cc||''||c_crlf);
      Utl_Smtp.write_data (l_conn,'Date'||': '||TO_CHAR(SYSDATE,'dd Mon yy hh:mi:ss')||c_crlf);
      Utl_Smtp.write_data (l_conn,'Subject'||': '||p_subject||c_crlf);
      Utl_Smtp.write_data (l_conn,'Content-Type'||': '||c_multipart_mime_type||c_crlf);
      Utl_Smtp.write_data (l_conn, c_crlf);
      Utl_Smtp.write_data (l_conn,'This is a multi-part message in MIME format.'||c_crlf);
      Utl_Smtp.write_data (l_conn, c_first_boundary);
      Utl_Smtp.write_data (l_conn,'Content-Type' || ': ' || c_mime_type_xls||c_crlf);
      Utl_Smtp.write_data (l_conn,'Content-Disposition'||': '||'attachment; filename= '||p_filename||c_crlf);
      Utl_Smtp.write_data (l_conn, c_crlf);
      Utl_Smtp.write_data (l_conn, p_body);
      Utl_Smtp.write_data (l_conn, c_crlf);
      Utl_Smtp.write_data (l_conn, c_last_boundary);
      Utl_Smtp.close_data (l_conn);
   END IF;
   --
   Utl_Smtp.quit (l_conn);
END with_body_attach;





PROCEDURE mail (
   sender       IN   VARCHAR2,
   recipients   IN   VARCHAR2,
   cc           IN   VARCHAR2,
   subject      IN   VARCHAR2,
   MESSAGE      IN   VARCHAR2 )
IS
   conn   Utl_Smtp.connection;
BEGIN
   conn := begin_mail (sender, recipients, cc, subject);
   write_text (conn, MESSAGE);
   end_mail (conn);
END mail;

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
   p_location      IN   VARCHAR2 DEFAULT 'ECX_UTL_LOG_DIR_OBJ' )
IS
   l_extension   VARCHAR2 (4);
BEGIN
   l_extension := UPPER (SUBSTR (p_filename, -4, 4));
--
--  IF NVL(p_body_attach,'N') = 'Y' OR p_filename IS NULL THEN
   IF NVL (p_body_attach, 'N') = 'Y' THEN
      -- EnvÃ­a el mail con el body attachado en un archivo de texto (si p_filename is not null)
      -- o sinÃ³, manda un mail comÃºn (con subject y body).
      IF (p_filename IS NULL) OR (p_filename IS NOT NULL AND l_extension NOT IN ('.TXT', '.LST', '.OUT', '.XLS', '.CSV')) THEN
         Raise_Application_Error(-20001,'Si el body va attachado, debe ser en un formato de texto');
      ELSE
         with_body_attach (p_to            => p_to,
                           p_cc            => p_cc,
                           p_subject       => p_subject,
                           p_body          => p_body,
                           p_filename      => p_filename,
                           p_location      => p_location);
      END IF;
   ELSE
      IF p_filename IS NULL THEN
         with_text_attach (p_to            => p_to,
                           p_cc            => p_cc,
                           p_subject       => p_subject,
                           p_body          => p_body,
                           p_filename      => p_filename,
                           p_location      => p_location);
      ELSE
         IF l_extension IN ('.PDF') THEN
            -- EnvÃ­a mail con archivo binario attachado (debe estar en el fnd_profile.value('ECX_UTL_LOG_DIR_OBJ')).
            with_binary_attach (p_to            => p_to,
                                p_cc            => p_cc,
                                p_subject       => p_subject,
                                p_body          => p_body,
                                p_filename      => p_filename,
                                p_location      => p_location);
         ELSE
            -- EnvÃ­a un mail con un archivo de texto attachado.
            with_text_attach (p_to            => p_to,
                              p_cc            => p_cc,
                              p_subject       => p_subject,
                              p_body          => p_body,
                              p_filename      => p_filename,
                              p_location      => p_location);
         END IF;
      END IF;
   END IF;
END send_mail;



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
                                 ,p_con_bajas  IN VARCHAR2 )
IS
  -- Constantes.
  l_procname           CONSTANT VARCHAR2(70)  := c_procname||'.REPORTE_USUARIOS_RESPO';
  l_location           CONSTANT VARCHAR2(240) := 'ECX_UTL_LOG_DIR_OBJ';
  l_filename           CONSTANT VARCHAR2(70)  := 'Reporte_Usuarios_Respo.csv';
  l_titulo             CONSTANT VARCHAR2(240) := 'Reporte Usuarios y Responsabilidades';
  l_separador          CONSTANT VARCHAR2(1)   := ';';
  -- Variables.
  l_fhandle                     Utl_File.FILE_TYPE;
  l_linea                       VARCHAR2(700);
  l_kreg                        NUMBER := 0;
  l_to                          VARCHAR2(50);
 CURSOR ccur IS
         SELECT fu.user_name
               ,pa.d_set_of_books_id  country
               ,resp.responsibility_name
               ,pp.full_name
               ,resp.application_id
               ,TO_CHAR(furg.end_date,'dd/mm/yyyy')  end_date_direct
               ,TO_CHAR(fu.end_date,'dd/mm/yyyy')    end_date_user
               ,TO_CHAR(resp.end_date,'dd/mm/yyyy')  end_date_resp
               ,pa.d_supervisor_id  supervisor
               ,(SELECT d_supervisor_id FROM per_assignments_v7 WHERE person_id = pa.supervisor_id AND TRUNC(SYSDATE) BETWEEN effective_start_date AND effective_end_date) super_supervisor
               ,fu.email_address
               ,fu.user_id
               ,resp.responsibility_id
               ,furg.created_by
               ,TO_CHAR(furg.creation_date,'dd/mm/yyyy') creation_date
               ,pp.person_id
               ,pa.supervisor_id
               ,TO_CHAR(fu.last_logon_date,'dd/mm/yyyy') last_logon_date
           FROM per_assignments_v7          pa
               ,per_people_v7               pp
               ,fnd_responsibility_vl       resp
               ,fnd_user_resp_groups_direct furg
               ,fnd_user                    fu
          WHERE 1=1
            AND (p_user_name IS NULL OR (p_user_name IS NOT NULL AND UPPER(fu.user_name) LIKE UPPER(p_user_name)||'%'))
            AND (p_resp_name IS NULL OR (p_resp_name IS NOT NULL AND UPPER(resp.responsibility_name) LIKE UPPER(p_resp_name)||'%'))
            AND furg.user_id = fu.user_id
            AND resp.responsibility_id = furg.responsibility_id
            AND resp.application_id = furg.responsibility_application_id
            AND pp.person_id(+) = fu.employee_id
            AND pa.person_id(+) = pp.person_id
            AND TRUNC(SYSDATE) BETWEEN pa.effective_start_date AND pa.effective_end_date
            AND ( (UPPER(NVL(p_con_bajas,'N')) = 'N' AND NVL(fu.end_date,TO_DATE('31124712','ddmmyyyy')) > TRUNC(SYSDATE)) OR (UPPER(NVL(p_con_bajas,'N')) = 'Y') )
            AND ( (UPPER(NVL(p_con_bajas,'N')) = 'N' AND NVL(furg.end_date,TO_DATE('31124712','ddmmyyyy')) > TRUNC(SYSDATE)) OR (UPPER(NVL(p_con_bajas,'N')) = 'Y') )
            AND NVL(resp.end_date,TO_DATE('31124712','ddmmyyyy')) > TRUNC(SYSDATE);
BEGIN
  fnd_file.put_line(fnd_file.LOG, l_procname||' (+)');
  fnd_file.put_line(fnd_file.LOG, 'Params: ');
  fnd_file.put_line(fnd_file.LOG, '+ p_user_name = '||p_user_name);
  fnd_file.put_line(fnd_file.LOG, '+ p_resp_name = '||p_resp_name);
  fnd_file.put_line(fnd_file.LOG, '+ p_con_bajas = '||p_con_bajas);
  --
  -- Abro el archivo de log.
  fnd_file.put_line(fnd_file.LOG, 'Abro UTL_FILE (+)');
  fnd_file.put_line(fnd_file.LOG, '  l_location = '||l_location);
  fnd_file.put_line(fnd_file.LOG, '  l_filename = '||l_filename);
  l_fhandle  := Utl_File.FOPEN( LOCATION     => l_location
                               ,filename     => l_filename
                               ,open_mode    => 'w'
                               ,max_linesize => 500 );
  fnd_file.put_line(fnd_file.LOG, 'Abro UTL_FILE (-)');
  -- Titulos.
  fnd_file.put_line(fnd_file.LOG, 'TÃ­tulos (+)');
--  Utl_File.put_line(l_fhandle, l_titulo);
--  fnd_file.put_line(fnd_file.output, l_titulo);
--  Utl_File.put_line(l_fhandle, ' ');
--  fnd_file.put_line(fnd_file.output, ' ');
  l_linea := 'NOMBRE USUARIO'||l_separador||'PAIS'||l_separador||'RESPONSABILIDAD'||l_separador||'NOMBRE COMPLETO'||l_separador||'FIN ASIGNACION'||l_separador||
             'BAJA USUARIO'||l_separador||'SUPERVISOR'||l_separador||'SUPER SUPERVISOR'||l_separador||'EMAIL'||l_separador||'ULTIMO ACCESO';
  Utl_File.put_line(l_fhandle, l_linea);
  Utl_File.fflush(l_fhandle);
  fnd_file.put_line(fnd_file.output, l_linea);
  fnd_file.put_line(fnd_file.LOG, 'TÃ­tulos (-)');
  --
  -- Recorro el cursor principal.
  fnd_file.put_line(fnd_file.LOG, 'Recorre CURSOR principal (+)');
  FOR rcur IN ccur LOOP
      l_linea := rcur.user_name||l_separador||rcur.country||l_separador||rcur.responsibility_name||l_separador||rcur.full_name||l_separador||rcur.end_date_direct||l_separador||
                 rcur.end_date_user||l_separador||rcur.supervisor||l_separador||rcur.super_supervisor||l_separador||rcur.email_address||l_separador||rcur.last_logon_date;
      l_kreg  := l_kreg + 1;
      Utl_File.put_line(l_fhandle, l_linea);
      fnd_file.put_line(fnd_file.output, l_linea);
  END LOOP;
  fnd_file.put_line(fnd_file.LOG, 'Recorre CURSOR principal (-)');
  fnd_file.put_line(fnd_file.LOG, 'Se seleccionaron '||l_kreg||' registros.');
  Utl_File.fclose(l_fhandle);
  --
  fnd_file.put_line(fnd_file.LOG, 'Envia mail (+)');
  BEGIN
    SELECT email_address
      INTO l_to
      FROM fnd_user
     WHERE user_id = fnd_global.user_id;
  EXCEPTION
    WHEN others THEN
         Raise_Application_Error(-20001,'Error: no se encontrÃ³ el email del usuario actual; '||SQLERRM);
  END;
  fnd_file.put_line(fnd_file.LOG,'Envia mail a '||NVL(l_to,'')||' (+)');
  send_mail( p_to          => l_to
            ,p_cc          => NULL
            ,p_subject     => l_titulo
            ,p_body        => NULL
            ,p_body_attach => 'N'
            ,p_filename    => l_filename
            ,p_location    => l_location );
  fnd_file.put_line(fnd_file.LOG,'Envia mail a '||NVL(l_to,'')||' (-)');
  fnd_file.put_line(fnd_file.LOG, l_procname||' (-)');
EXCEPTION
    WHEN OTHERS THEN
         Dbms_Output.Put_Line('ERROR General; '||SQLERRM); --> no me interesa hacer un RAISE porque el proceso ya finalizÃ³, y no lo voy a parar por esto.
END reporte_usuarios_respo;





-- -----------------------------------------------------------------------------
-- Name   : reporte_menu_conc
-- Purpose: genera un reporte con el Ã¡rbol de menÃº de una responsabilidad.
-- Params : p_resp_name: fnd_responsibility_vl.responsibility_name
--          p_con_detalle: si incluye o no las funciones ocultas (sin prompt)
--          p_con_conc: si incluye o no los concurrentes de esa respo.
-- Notes  : este procedure es invocado por: XX Reporte de MenÃºes y Concurrentes
-- Return :
-- History: 12/04/2016  Created
-- -----------------------------------------------------------------------------
PROCEDURE reporte_menu_conc( errbuf        OUT VARCHAR2
                            ,retcod        OUT VARCHAR2
                            ,p_resp_name    IN VARCHAR2
                            ,p_con_detalle  IN VARCHAR
                            ,p_con_conc     IN VARCHAR2 )
IS
  -- Constantes.
  l_procname           CONSTANT VARCHAR2(70)  := c_procname||'.REPORTE_MENU_CONC';
  l_location           CONSTANT VARCHAR2(240) := 'ECX_UTL_LOG_DIR_OBJ';
  l_filename           CONSTANT VARCHAR2(70)  := 'Reporte_Menu.csv';
  l_titulo             CONSTANT VARCHAR2(240) := 'Menu de la Responsabilidad: '||p_resp_name;
  l_separador          CONSTANT VARCHAR2(1)   := ';';
  -- Variables.
  l_fhandle                     Utl_File.FILE_TYPE;
  l_linea                       VARCHAR2(700);
  l_kreg                        NUMBER := 0;
  l_to                          VARCHAR2(50);
  -- Este cursor se utiliza cuando el parÃ¡metro p_con_detalle = 'N'.
  CURSOR ccur1 IS
         SELECT LEVEL, LPAD (' ', (LEVEL - 1) * 5)|| fme.PROMPT PROMPT, fme.entry_sequence, fme.menu_id, fme.sub_menu_id, fme.function_id
               ,fff.TYPE, DECODE(fme.sub_menu_id, NULL, 'FUNCTION', DECODE (fme.function_id, NULL, 'SUBMENU', 'BOTH')) menu_type, fff.function_name
               ,fff.user_function_name, (SELECT fm.user_menu_name FROM fnd_menus_vl fm WHERE fm.menu_id = fme.menu_id) user_menu_name
               ,SYS_CONNECT_BY_PATH(PROMPT,' / ') PATH
           FROM fnd_form_functions_vl fff
               ,fnd_menu_entries_vl   fme
          WHERE 1=1
            AND fff.function_id(+) = fme.function_id
            AND fme.PROMPT IS NOT NULL
            AND NVL(fff.TYPE,'x') <> 'SUBFUNCTION'
            -- elimina las entradas de submenu de los cuales ninguno de sus hijos tienen prompt.
            AND (SELECT DECODE(DECODE (fme.sub_menu_id, NULL, 'FUNCTION', DECODE(fme.function_id, NULL, 'SUBMENU', 'BOTH')),'SUBMENU',DECODE(COUNT(1),0,'BAJAR','OK'),'OK')
                   FROM fnd_menu_entries_vl me
                  WHERE me.menu_id = fme.sub_menu_id
                    AND me.PROMPT IS NOT NULL) = 'OK'
            -- hasta aquÃ­.
        CONNECT BY PRIOR fme.sub_menu_id = fme.menu_id
            AND fme.PROMPT IS NOT NULL
          START WITH fme.menu_id = (SELECT menu_id FROM fnd_responsibility_vl WHERE UPPER(responsibility_name) = UPPER(p_resp_name))
            AND fme.PROMPT IS NOT NULL
            AND fme.grant_flag = 'Y'
           ORDER SIBLINGS BY fme.entry_sequence;
  --
  -- Este cursor se utiliza cuando el parÃ¡metro p_con_detalle = 'Y'.
  CURSOR ccur2 IS
         SELECT LEVEL, LPAD (' ', (LEVEL - 1) * 5)|| fme.PROMPT PROMPT, fme.entry_sequence, fme.menu_id, fme.sub_menu_id, fme.function_id
               ,fff.TYPE, DECODE(fme.sub_menu_id, NULL, 'FUNCTION', DECODE (fme.function_id, NULL, 'SUBMENU', 'BOTH')) menu_type, fff.function_name
               ,fff.user_function_name, (SELECT fm.user_menu_name FROM fnd_menus_vl fm WHERE fm.menu_id = fme.menu_id) user_menu_name
               ,SYS_CONNECT_BY_PATH(PROMPT,' / ') PATH
           FROM fnd_form_functions_vl fff
               ,fnd_menu_entries_vl   fme
          WHERE 1=1
            AND fff.function_id(+) = fme.function_id
--            AND fme.PROMPT IS NOT NULL
            AND NVL(fff.TYPE,'x') <> 'SUBFUNCTION'
            -- elimina las entradas de submenu cuyo ninguno de sus hijos tienen prompt.
            AND (SELECT DECODE(DECODE (fme.sub_menu_id, NULL, 'FUNCTION', DECODE(fme.function_id, NULL, 'SUBMENU', 'BOTH')),'SUBMENU',DECODE(COUNT(1),0,'BAJAR','OK'),'OK')
                   FROM fnd_menu_entries_vl me
                  WHERE me.menu_id = fme.sub_menu_id
                    AND me.PROMPT IS NOT NULL) = 'OK'
            -- hasta aquÃ­.
        CONNECT BY PRIOR fme.sub_menu_id = fme.menu_id
--            AND fme.PROMPT IS NOT NULL
          START WITH fme.menu_id = (SELECT menu_id FROM fnd_responsibility_vl WHERE UPPER(responsibility_name) = UPPER(p_resp_name))
--            AND fme.PROMPT IS NOT NULL
            AND fme.grant_flag = 'Y'
           ORDER SIBLINGS BY fme.entry_sequence;
  --
  CURSOR cconc IS
         SELECT fr.responsibility_name, (SELECT request_group_name FROM fnd_request_groups WHERE request_group_id = gu.request_group_id) request_group_name
               ,fr.application_id appl_id_resp, fcp.concurrent_program_id, fcp.user_concurrent_program_name, fcp.application_id appl_id_conc, fcp.enabled_flag
               ,gu.request_group_id, gu.request_unit_id, gu.application_id appl_id_reqgroup
           FROM fnd_concurrent_programs_vl fcp
               ,fnd_request_group_units    gu
               ,fnd_responsibility_vl      fr
          WHERE 1=1
         --   AND fcp.application_id(+) = gu.application_id
            AND fcp.concurrent_program_id(+) = gu.request_unit_id
            AND gu.request_unit_type = 'P'
            AND UPPER(fr.responsibility_name) LIKE UPPER(p_resp_name) --||'%'
            AND gu.request_group_id = fr.request_group_id
         --   and gu.application_id = fr.application_id
            AND NVL(fcp.enabled_flag,'N') = 'Y';
BEGIN
  fnd_file.put_line(fnd_file.LOG, l_procname||' (+)');
  fnd_file.put_line(fnd_file.LOG, 'Params: ');
  fnd_file.put_line(fnd_file.LOG, '+ p_resp_name = '||p_resp_name);
  fnd_file.put_line(fnd_file.LOG, '+ p_con_detalle = '||p_con_detalle);
  fnd_file.put_line(fnd_file.LOG, '+ p_con_conc = '||p_con_conc);
  --
  -- Abro el archivo de log.
  fnd_file.put_line(fnd_file.LOG, 'Abro UTL_FILE (+)');
  fnd_file.put_line(fnd_file.LOG, '  l_location = '||l_location);
  fnd_file.put_line(fnd_file.LOG, '  l_filename = '||l_filename);
  l_fhandle  := Utl_File.FOPEN( LOCATION     => l_location
                               ,filename     => l_filename
                               ,open_mode    => 'w'
                               ,max_linesize => 500 );
  fnd_file.put_line(fnd_file.LOG, 'Abro UTL_FILE (-)');
  -- Titulos.
  fnd_file.put_line(fnd_file.LOG, 'TÃ­tulos (+)');
  Utl_File.put_line(l_fhandle, l_titulo);
  fnd_file.put_line(fnd_file.output, l_titulo);
  Utl_File.put_line(l_fhandle, ' ');
  fnd_file.put_line(fnd_file.output, ' ');
  l_linea := 'NIVEL'||l_separador||'ORDEN'||l_separador||'TITULO MENU'||l_separador||'TIPO'||l_separador||'FUNCION INTERNA'||l_separador||'NOMBRE FUNCION';
  Utl_File.put_line(l_fhandle, l_linea);
  Utl_File.fflush(l_fhandle);
  fnd_file.put_line(fnd_file.output, l_linea);
  fnd_file.put_line(fnd_file.LOG, 'TÃ­tulos (-)');
  --
  -- Recorro el cursor principal.
  fnd_file.put_line(fnd_file.LOG, 'Recorre CURSOR principal (+)');
  IF UPPER(NVL(p_con_detalle,'N')) = 'N' THEN
     FOR rcur IN ccur1 LOOP
         l_linea := rcur.LEVEL||l_separador||rcur.entry_sequence||l_separador||rcur.PROMPT||l_separador||rcur.TYPE||l_separador||rcur.function_name||l_separador||rcur.user_function_name;
         l_kreg  := l_kreg + 1;
         Utl_File.put_line(l_fhandle, l_linea);
         fnd_file.put_line(fnd_file.output, l_linea);
     END LOOP;
  ELSE
     FOR rcur IN ccur2 LOOP
         l_linea := rcur.LEVEL||l_separador||rcur.entry_sequence||l_separador||rcur.PROMPT||l_separador||rcur.TYPE||l_separador||rcur.function_name||l_separador||rcur.user_function_name;
         l_kreg  := l_kreg + 1;
         Utl_File.put_line(l_fhandle, l_linea);
         fnd_file.put_line(fnd_file.output, l_linea);
     END LOOP;
  END IF;
  fnd_file.put_line(fnd_file.LOG, 'Recorre CURSOR principal (-)');
  fnd_file.put_line(fnd_file.LOG, 'Se seleccionaron '||l_kreg||' registros.');
  --
  -- Reporte del Ã¡rbol de menÃº.
  IF NVL(p_con_conc,'N') <> 'N' THEN
     fnd_file.put_line(fnd_file.LOG,'Reporte del Ã¡rbol de MenÃº (+)');
     fnd_file.put_line(fnd_file.output,' ');
     fnd_file.put_line(fnd_file.output,' ');
     fnd_file.put_line(fnd_file.output,' ');
     Utl_File.put_line(l_fhandle, ' ');
     Utl_File.put_line(l_fhandle, ' ');
     Utl_File.put_line(l_fhandle, ' ');
      -- Titulos.
     fnd_file.put_line(fnd_file.LOG, 'TÃ­tulos (+)');
   --  Utl_File.put_line(l_fhandle, l_titulo);
   --  fnd_file.put_line(fnd_file.output, l_titulo);
   --  Utl_File.put_line(l_fhandle, ' ');
   --  fnd_file.put_line(fnd_file.output, ' ');
     l_linea := 'RESPONSABILIDAD'||l_separador||'GRUPO DE SOLICITUDES'||l_separador||'NOMBRE CONCURRENTE';
     Utl_File.put_line(l_fhandle, l_linea);
     Utl_File.fflush(l_fhandle);
     fnd_file.put_line(fnd_file.output, l_linea);
     fnd_file.put_line(fnd_file.LOG, 'TÃ­tulos (-)');
     --
     -- Recorro el cursor principal.
     l_kreg := 0;
     fnd_file.put_line(fnd_file.LOG, 'Recorre CURSOR principal (+)');
     FOR rcur IN cconc LOOP
         l_linea := rcur.responsibility_name||l_separador||rcur.request_group_name||l_separador||rcur.user_concurrent_program_name;
         l_kreg  := l_kreg + 1;
         Utl_File.put_line(l_fhandle, l_linea);
         fnd_file.put_line(fnd_file.output, l_linea);
     END LOOP;
     fnd_file.put_line(fnd_file.LOG, 'Recorre CURSOR principal (-)');
     fnd_file.put_line(fnd_file.LOG, 'Se seleccionaron '||l_kreg||' registros.');
     fnd_file.put_line(fnd_file.LOG, 'Reporte del Ã¡rbol de MenÃº (-)');
  END IF;
  --
  Utl_File.fclose(l_fhandle);
  --
  fnd_file.put_line(fnd_file.LOG, 'Envia mail (+)');
  BEGIN
    SELECT email_address
      INTO l_to
      FROM fnd_user
     WHERE user_id = fnd_global.user_id;
  EXCEPTION
    WHEN others THEN
         Raise_Application_Error(-20001,'Error: no se encontrÃ³ el email del usuario actual; '||SQLERRM);
  END;
  fnd_file.put_line(fnd_file.LOG,'Envia mail a '||NVL(l_to,'')||' (+)');
  send_mail( p_to          => l_to
            ,p_cc          => NULL
            ,p_subject     => l_titulo
            ,p_body        => NULL
            ,p_body_attach => 'N'
            ,p_filename    => l_filename
            ,p_location    => l_location );
  fnd_file.put_line(fnd_file.LOG,'Envia mail a '||NVL(l_to,'')||' (-)');
  fnd_file.put_line(fnd_file.LOG, l_procname||' (-)');
EXCEPTION
    WHEN OTHERS THEN
         fnd_file.put_line(fnd_file.LOG, 'ERROR General; '||SQLERRM);
         fnd_file.put_line(fnd_file.output, 'ERROR General; '||SQLERRM);
         Raise_Application_Error(-20001, 'ERROR General; '||SQLERRM);
END reporte_menu_conc;






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
                                 ,p_resp_name  IN VARCHAR2 )
IS
  -- Constantes.
  l_procname           CONSTANT VARCHAR2(70)  := c_procname||'.CONCURRENTES_POR_RESPO';
  l_location           CONSTANT VARCHAR2(240) := 'ECX_UTL_LOG_DIR_OBJ';
  l_filename           CONSTANT VARCHAR2(70)  := 'Concurrentes_por_Respo.csv';
  l_titulo             CONSTANT VARCHAR2(240) := 'Concurrentes por Responsabilidad';
  l_separador          CONSTANT VARCHAR2(1)   := ';';
  -- Variables.
  l_fhandle                     Utl_File.FILE_TYPE;
  l_linea                       VARCHAR2(700);
  l_kreg                        NUMBER := 0;
  l_to                          VARCHAR2(50);
  CURSOR ccur IS
         SELECT fr.responsibility_name, (SELECT request_group_name FROM fnd_request_groups WHERE request_group_id = gu.request_group_id) request_group_name
               ,fr.application_id appl_id_resp, fcp.concurrent_program_id, fcp.user_concurrent_program_name, fcp.concurrent_program_name
               ,fcp.application_id appl_id_conc, fcp.enabled_flag, gu.request_group_id, gu.request_unit_id, gu.application_id appl_id_reqgroup
           FROM fnd_concurrent_programs_vl fcp
               ,fnd_request_group_units    gu
               ,fnd_responsibility_vl      fr
          WHERE 1=1
         --   AND fcp.application_id(+) = gu.application_id
            AND fcp.concurrent_program_id(+) = gu.request_unit_id
            AND gu.REQUEST_UNIT_TYPE = 'P'
            AND (p_conc_name IS NULL OR (p_conc_name IS NOT NULL AND UPPER(fcp.user_concurrent_program_name) LIKE UPPER(p_conc_name)||'%'))
            AND (p_resp_name IS NULL OR (p_resp_name IS NOT NULL AND UPPER(fr.responsibility_name) LIKE UPPER(p_resp_name)||'%'))
            AND gu.request_group_id = fr.request_group_id
         --   and gu.application_id = fr.application_id
            AND NVL(fcp.enabled_flag,'N') = 'Y';
BEGIN
  fnd_file.put_line(fnd_file.LOG, l_procname||' (+)');
  fnd_file.put_line(fnd_file.LOG, 'Params: ');
  fnd_file.put_line(fnd_file.LOG, '+ p_conc_name = '||p_conc_name);
  fnd_file.put_line(fnd_file.LOG, '+ p_resp_name = '||p_resp_name);
  --
  -- Abro el archivo de log.
  fnd_file.put_line(fnd_file.LOG, 'Abro UTL_FILE (+)');
  fnd_file.put_line(fnd_file.LOG, '  l_location = '||l_location);
  fnd_file.put_line(fnd_file.LOG, '  l_filename = '||l_filename);
  l_fhandle  := Utl_File.FOPEN( LOCATION     => l_location
                               ,filename     => l_filename
                               ,open_mode    => 'w'
                               ,max_linesize => 500 );
  fnd_file.put_line(fnd_file.LOG, 'Abro UTL_FILE (-)');
  -- Titulos.
  fnd_file.put_line(fnd_file.LOG, 'TÃ­tulos (+)');
--  Utl_File.put_line(l_fhandle, l_titulo);
--  fnd_file.put_line(fnd_file.output, l_titulo);
--  Utl_File.put_line(l_fhandle, ' ');
--  fnd_file.put_line(fnd_file.output, ' ');
  l_linea := 'RESPONSABILIDAD'||l_separador||'REPORTE/PROCESO'||l_separador||'GRUPO SOLICITUD';
  Utl_File.put_line(l_fhandle, l_linea);
  Utl_File.fflush(l_fhandle);
  fnd_file.put_line(fnd_file.output, l_linea);
  fnd_file.put_line(fnd_file.LOG, 'TÃ­tulos (-)');
  --
  -- Recorro el cursor principal.
  fnd_file.put_line(fnd_file.LOG, 'Recorre CURSOR principal (+)');
  FOR rcur IN ccur LOOP
      l_linea := rcur.responsibility_name||l_separador||rcur.user_concurrent_program_name||l_separador||rcur.request_group_name;
      l_kreg  := l_kreg + 1;
      Utl_File.put_line(l_fhandle, l_linea);
      fnd_file.put_line(fnd_file.output, l_linea);
  END LOOP;
  fnd_file.put_line(fnd_file.LOG, 'Recorre CURSOR principal (-)');
  fnd_file.put_line(fnd_file.LOG, 'Se seleccionaron '||l_kreg||' registros.');
  Utl_File.fclose(l_fhandle);
  --
  fnd_file.put_line(fnd_file.LOG, 'Envia mail (+)');
  BEGIN
    SELECT email_address
      INTO l_to
      FROM fnd_user
     WHERE user_id = fnd_global.user_id;
  EXCEPTION
    WHEN others THEN
         Raise_Application_Error(-20001,'Error: no se encontrÃ³ el email del usuario actual; '||SQLERRM);
  END;
  fnd_file.put_line(fnd_file.LOG,'Envia mail a '||NVL(l_to,'')||' (+)');
  send_mail( p_to          => l_to
            ,p_cc          => NULL
            ,p_subject     => l_titulo
            ,p_body        => NULL
            ,p_body_attach => 'N'
            ,p_filename    => l_filename
            ,p_location    => l_location );
  fnd_file.put_line(fnd_file.LOG,'Envia mail a '||NVL(l_to,'')||' (-)');
  fnd_file.put_line(fnd_file.LOG, l_procname||' (-)');
EXCEPTION
    WHEN OTHERS THEN
         Dbms_Output.Put_Line('ERROR General; '||SQLERRM); --> no me interesa hacer un RAISE porque el proceso ya finalizÃ³, y no lo voy a parar por esto.
END concurrentes_por_respo;





-- -----------------------------------------------------------------------------
-- Name   : variables_de_perfil
-- Purpose: informa todas las variables de perfil de una responsabilidad.
-- Params : p_resp_name: fnd_responsibility_vl.responsibility_name
-- Notes  : este procedimiento es invocado por el concurrente:
--          "XX Reporte de Variables de Perfil de una Responsabilidad".
-- Return :
-- History: 01/07/2016  Created
-- -----------------------------------------------------------------------------
PROCEDURE variables_de_perfil( errbuf      OUT VARCHAR2
                              ,retcod      OUT VARCHAR2
                              ,p_level      IN VARCHAR2
                              ,p_appl_name  IN VARCHAR2
                              ,p_resp_name  IN VARCHAR2
                              ,p_user_name  IN VARCHAR2 )
IS
  -- Constantes.
  l_procname           CONSTANT VARCHAR2(70)  := c_procname||'.VARIABLES_DE_PERFIL';
  l_location           CONSTANT VARCHAR2(240) := 'ECX_UTL_LOG_DIR_OBJ';
  l_filename           CONSTANT VARCHAR2(70)  := 'Variables de Perfil.csv';
  l_titulo             CONSTANT VARCHAR2(240) := 'Variables de Perfil por Responsabilidad';
  l_separador          CONSTANT VARCHAR2(1)   := ';';
  -- Variables.
  l_fhandle                     Utl_File.FILE_TYPE;
  l_linea                       VARCHAR2(700);
  l_kreg                        NUMBER := 0;
  l_to                          VARCHAR2(50);
  CURSOR ccur IS
         SELECT ap.application_name, pn.user_profile_option_name,
                pv.profile_option_value, lc.meaning lvl, pv1.profile_option_value lvlvalue, NULL LvlAppl, '1'
           FROM fnd_application_vl ap, fnd_profile_options_vl pn, fnd_lookups lc,
                fnd_profile_option_values pv, fnd_profile_option_values pv1
          WHERE pv.application_id = ap.application_id
            AND pv.application_id = pn.application_id
            AND pv.profile_option_id = pn.profile_option_id
            AND lc.lookup_type = 'FND_PROFILE_LEVELS'
            AND lc.lookup_code = 'SITE'
            AND pv.level_id = 10001
            AND pv.level_value = pv1.level_value
            AND pv1.profile_option_id = 125
            AND pv1.application_id = 0
            AND (p_level IS NULL OR p_level = 'SITE')
            AND NOT EXISTS ( SELECT 'X'
                               FROM fnd_profile_option_values spv, fnd_user sfu
                              WHERE spv.profile_option_id = pv.profile_option_id
                                AND spv.application_id = pv.application_id
                                AND spv.level_id = 10004
                                AND spv.level_value = sfu.user_id
                             UNION ALL
                             SELECT 'X'
                               FROM fnd_profile_option_values spv,
                                    fnd_application sfa, fnd_responsibility_vl sfr
                              WHERE spv.profile_option_id = pv.profile_option_id
                                AND spv.application_id = pv.application_id
                                AND spv.level_id = 10003
                                AND spv.level_value = sfr.responsibility_id
                                AND sfa.application_id = sfr.application_id
                                AND sfa.application_id = spv.level_value_application_id
                      AND sfr.responsibility_name = P_RESP_NAME
                             UNION ALL
                             SELECT 'X'
                               FROM fnd_profile_option_values spv, fnd_application sfav
                              WHERE spv.profile_option_id = pv.profile_option_id
                                AND spv.application_id = pv.application_id
                                AND spv.level_id = 10002
                                AND spv.level_value = sfav.application_id
                           )
         UNION ALL
         SELECT ap.application_name, pn.user_profile_option_name,
                pv.profile_option_value, lc.meaning lvl, fa.application_name lvlvalue, NULL LvlAppl, '2'
           FROM fnd_application_vl ap, fnd_profile_options_vl pn, fnd_lookups lc,
                fnd_profile_option_values pv, fnd_application_vl fa
          WHERE pv.application_id = ap.application_id
            AND pv.application_id = pn.application_id
            AND pv.profile_option_id = pn.profile_option_id
            AND lc.lookup_type = 'FND_PROFILE_LEVELS'
            AND lc.lookup_code = 'APPLICATION'
            AND fa.application_name = p_appl_name
            AND pv.level_id = 10002
            AND pv.level_value = fa.application_id
            AND (p_level IS NULL OR p_level = 'APPLICATION')
            AND NOT EXISTS ( SELECT 'X'
                               FROM fnd_profile_option_values spv, fnd_user sfu
                              WHERE spv.profile_option_id = pv.profile_option_id
                                AND spv.application_id = pv.application_id
                                AND spv.level_id = 10004
                                AND spv.level_value = sfu.user_id
                             UNION ALL
                             SELECT 'X'
                               FROM fnd_profile_option_values spv,
                                    fnd_application sfa, fnd_responsibility_vl sfr
                              WHERE spv.profile_option_id = pv.profile_option_id
                                AND spv.application_id = pv.application_id
                                AND spv.level_id = 10003
                                AND spv.level_value = sfr.responsibility_id
                                AND sfa.application_id = sfr.application_id
                                AND sfa.application_id = spv.level_value_application_id
                      AND sfr.responsibility_name = P_RESP_NAME
                           )
         UNION ALL
         SELECT ap.application_name, pn.user_profile_option_name,
                pv.profile_option_value, lc.meaning lvl, fr.responsibility_name LvlValue,
                fa.application_name LvlAppl, '3'
           FROM fnd_application_vl ap, fnd_profile_options_vl pn, fnd_lookups lc,
                fnd_profile_option_values pv, fnd_application_vl fa,
                fnd_responsibility_vl fr
          WHERE pv.application_id = ap.application_id
            AND pv.application_id = pn.application_id
            AND pv.profile_option_id = pn.profile_option_id
            AND lc.lookup_type = 'FND_PROFILE_LEVELS'
            AND lc.lookup_code = 'RESPONSIBILITY'
            AND fr.responsibility_name = p_resp_name
            AND pv.level_id = 10003
            AND pv.level_value = fr.responsibility_id
            AND (p_level IS NULL OR p_level = 'RESPONSIBILITY')
            AND NVL(pv.level_value_application_id,0) = fa.application_id
            AND fa.application_id = fr.application_id
            AND NOT EXISTS ( SELECT 'X'
                               FROM fnd_profile_option_values spv, fnd_user sfu
                              WHERE spv.profile_option_id = pv.profile_option_id
                                AND spv.application_id = pv.application_id
                                AND spv.level_id = 10004
                                AND spv.level_value = sfu.user_id
                           )
         UNION ALL
         SELECT ap.application_name, pn.user_profile_option_name,
                pv.profile_option_value, lc.meaning lvl, fu.user_name lvlvalue, NULL LvlAppl, '4'
           FROM fnd_application_vl ap, fnd_profile_options_vl pn, fnd_lookups lc,
                fnd_profile_option_values pv, fnd_user fu
          WHERE pv.application_id = ap.application_id
            AND pv.application_id = pn.application_id
            AND pv.profile_option_id = pn.profile_option_id
            AND lc.lookup_type = 'FND_PROFILE_LEVELS'
            AND lc.lookup_code = 'USER'
            AND fu.user_name = p_user_name
            AND pv.level_id = 10004
            AND pv.level_value = fu.user_id
            AND (p_level IS NULL OR p_level = 'USER')
         ORDER BY 1, 2;
BEGIN
  fnd_file.put_line(fnd_file.LOG, l_procname||' (+)');
  fnd_file.put_line(fnd_file.LOG, 'Params: ');
  fnd_file.put_line(fnd_file.LOG, '+ p_level = '||p_level);
  fnd_file.put_line(fnd_file.LOG, '+ p_appl_name = '||p_appl_name);
  fnd_file.put_line(fnd_file.LOG, '+ p_resp_name = '||p_resp_name);
  fnd_file.put_line(fnd_file.LOG, '+ p_user_name = '||p_user_name);
  --
  -- Abro el archivo de log.
  fnd_file.put_line(fnd_file.LOG, 'Abro UTL_FILE (+)');
  fnd_file.put_line(fnd_file.LOG, '  l_location = '||l_location);
  fnd_file.put_line(fnd_file.LOG, '  l_filename = '||l_filename);
  l_fhandle  := Utl_File.FOPEN( LOCATION     => l_location
                               ,filename     => l_filename
                               ,open_mode    => 'w'
                               ,max_linesize => 500 );
  fnd_file.put_line(fnd_file.LOG, 'Abro UTL_FILE (-)');
  -- Titulos.
  fnd_file.put_line(fnd_file.LOG, 'TÃ­tulos (+)');
--  Utl_File.put_line(l_fhandle, l_titulo);
--  fnd_file.put_line(fnd_file.output, l_titulo);
--  Utl_File.put_line(l_fhandle, ' ');
--  fnd_file.put_line(fnd_file.output, ' ');
  IF p_level = 'SITE' THEN
     l_linea := 'SITIO'||l_separador||'APLICACION'||l_separador||'NIVEL'||l_separador||'NOMBRE VARIABLE'||l_separador||'VALOR';
  ELSIF p_level = 'APPLICATION' THEN
     l_linea := l_linea||'APLICACION'||l_separador||'APLICACION'||l_separador||'NIVEL'||l_separador||'NOMBRE VARIABLE'||l_separador||'VALOR';
  ELSIF p_level = 'RESPONSIBILITY' THEN
     l_linea := 'RESPONSABILIDAD'||l_separador||'APLICACION'||l_separador||'NIVEL'||l_separador||'NOMBRE VARIABLE'||l_separador||'VALOR';
  ELSIF p_level = 'USER' THEN
     l_linea := 'USUARIO'||l_separador||'APLICACION'||l_separador||'NIVEL'||l_separador||'NOMBRE VARIABLE'||l_separador||'VALOR';
  END IF;
  Utl_File.put_line(l_fhandle, l_linea);
  Utl_File.fflush(l_fhandle);
  fnd_file.put_line(fnd_file.output, l_linea);
  fnd_file.put_line(fnd_file.LOG, 'TÃ­tulos (-)');
  --
  -- Recorro el cursor principal.
  fnd_file.put_line(fnd_file.LOG, 'Recorre CURSOR principal (+)');
  FOR rcur IN ccur LOOP
      IF p_level = 'SITE' THEN
         l_linea := ' '||l_separador;
      ELSIF p_level = 'APPLICATION' THEN
         l_linea := p_appl_name||l_separador;
      ELSIF p_level = 'RESPONSIBILITY' THEN
         l_linea := p_resp_name||l_separador;
      ELSIF p_level = 'USER' THEN
         l_linea := p_user_name||l_separador;
      END IF;
      l_linea := l_linea||rcur.application_name||l_separador||rcur.lvl||l_separador||rcur.user_profile_option_name||l_separador||rcur.profile_option_value;
      l_kreg  := l_kreg + 1;
      Utl_File.put_line(l_fhandle, l_linea);
      fnd_file.put_line(fnd_file.output, l_linea);
  END LOOP;
  fnd_file.put_line(fnd_file.LOG, 'Recorre CURSOR principal (-)');
  fnd_file.put_line(fnd_file.LOG, 'Se seleccionaron '||l_kreg||' registros.');
  Utl_File.fclose(l_fhandle);
  --
  fnd_file.put_line(fnd_file.LOG, 'Envia mail (+)');
  BEGIN
    SELECT email_address
      INTO l_to
      FROM fnd_user
     WHERE user_id = fnd_global.user_id;
  EXCEPTION
    WHEN others THEN
         Raise_Application_Error(-20001,'ERROR: NO se encontrÃ³ el email del usuario actual; '||SQLERRM);
  END;
  fnd_file.put_line(fnd_file.LOG,'Envia mail A '||NVL(l_to,'')||' (+)');
  send_mail( p_to          => l_to
            ,p_cc          => NULL
            ,p_subject     => l_titulo
            ,p_body        => NULL
            ,p_body_attach => 'N'
            ,p_filename    => l_filename
            ,p_location    => l_location );
  fnd_file.put_line(fnd_file.LOG,'Envia mail a '||NVL(l_to,'')||' (-)');
  fnd_file.put_line(fnd_file.LOG, l_procname||' (-)');
EXCEPTION
    WHEN OTHERS THEN
         Dbms_Output.Put_Line('ERROR General; '||SQLERRM); --> no me interesa hacer un RAISE porque el proceso ya finalizÃ³, y no lo voy a parar por esto.
END variables_de_perfil;



END xx_reportes_auditoria_pkg;