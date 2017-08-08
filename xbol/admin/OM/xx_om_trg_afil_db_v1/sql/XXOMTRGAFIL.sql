create or replace trigger trg_expedia_pay
before insert on bolinf.xx_om_sales
for each row when
(  new.attribute3_h = 'partnernotify@expedia.com' and new.status = 'NEW')
declare
 v_status varchar2(50) := 'EBS_EXPEDIA_PAY';
begin
 :new.status := v_status;
exception
 when others then
   arp_standard.debug('Exception:xx_om_sales');
   arp_standard.debug('Not able to enqueue the message');
   raise;
end;
/
create or replace trigger trg_avantrip
before insert on bolinf.xx_om_sales
for each row when
(  new.attribute3_h = 'clientes@avantrip.com' and new.status = 'NEW')
declare
 v_status varchar2(50) := 'EBS_AVANTRIP';
begin
 :new.status := v_status;
exception
 when others then
   arp_standard.debug('Exception:xx_om_sales');
   arp_standard.debug('Not able to enqueue the message');
   raise;
end;
/
create or replace trigger trg_hotusa
before insert on bolinf.xx_om_sales
for each row when
(  new.attribute3_h = 'product@restel.es' and new.status = 'NEW')
declare
 v_status varchar2(50) := 'EBS_HOTUSA';
begin
 :new.status := v_status;
exception
 when others then
   arp_standard.debug('Exception:xx_om_sales');
   arp_standard.debug('Not able to enqueue the message');
   raise;
end;
/
create or replace trigger trg_garbarino
before insert on bolinf.xx_om_sales
for each row when
(  new.attribute3_h = 'operaciones@garbarinoviajes.com.ar' and new.status = 'NEW')
declare
  v_status varchar2(50) := 'EBS_GARBARINO';
begin
 :new.status := v_status;
exception
 when others then
   arp_standard.debug('Exception:xx_om_sales');
   arp_standard.debug('Not able to enqueue the message');
   raise;
end;
/

exit
