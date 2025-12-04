CREATE OR REPLACE PROCEDURE RRHH."ENVIO_CORREO_REAL" (
sender IN VARCHAR2,
recipient IN VARCHAR2,
ccrecipient IN VARCHAR2,
subject IN VARCHAR2,
message IN VARCHAR2
) IS

crlf VARCHAR2(2):= UTL_TCP.CRLF;
connection utl_smtp.connection;
mailhost VARCHAR2(90) := 'aytosalamanca-es.mail.protection.outlook.com';
header VARCHAR2(1000);
cc_recipient1 VARCHAR2(70);
cc_recipient2 VARCHAR2(70);
BEGIN

-- Start the connection.

connection := utl_smtp.open_connection(mailhost,25);

header:= 'Date: '||TO_CHAR(SYSDATE,'dd Mon yy hh24:mi:ss')||crlf||
'From: '||sender||''||crlf||
'Subject: '||subject||crlf||
'To: '||recipient||crlf||
'CC: '||ccrecipient||crlf;

cc_recipient1:=substr(ccrecipient,1,instr(ccrecipient,';',1)-1);
cc_recipient2:=substr(ccrecipient,instr(ccrecipient,';',1)+1,length(ccrecipient)-instr(ccrecipient,';',1));

-- Handshake with the SMTP server
utl_smtp.helo(connection, mailhost);
utl_smtp.mail(connection, sender);
utl_smtp.rcpt(connection, recipient);
--utl_smtp.rcpt(connection, cc_recipient1);
--utl_smtp.rcpt(connection, cc_recipient2);
--utl_smtp.rcpt(connection, ccrecipient);
utl_smtp.open_data(connection);

-- Write the header

utl_smtp.write_data(connection, header);
UTL_smtp.write_data(connection, 'MIME-Version: ' || '1.0' || UTL_tcp.CRLF);
UTL_smtp.write_data(connection, 'Content-Type: ' || 'text/html; charset=utf-8' || UTL_tcp.CRLF);
UTL_smtp.write_data(connection, 'Content-Transfer-Encoding: '  || '8bit' || UTL_tcp.CRLF); /* ** End of header information */
--UTL_smtp.write_data(connection, UTL_tcp.CRLF); /* ** Actual body is sent here */

utl_smtp.write_data(connection, crlf ||message);
utl_smtp.close_data(connection);
utl_smtp.quit(connection);

EXCEPTION
WHEN UTL_SMTP.INVALID_OPERATION THEN
dbms_output.put_line(' Invalid Operation in SMTP transaction.');
WHEN UTL_SMTP.TRANSIENT_ERROR THEN
dbms_output.put_line(' Temporary problems with sending email - try again
later.');
WHEN UTL_SMTP.PERMANENT_ERROR THEN
dbms_output.put_line(' Errors in code for SMTP transaction.');


END ENVIO_CORREO_REAL;
/

