create or replace trigger trg_cl_om_go_live
before insert on bolinf.xx_om_sales
for each row when
(  new.legal_entity = 'Despegar.com Chile SpA' and new.status = 'NEW')
declare
  v_status varchar2(50) := 'GO_LIVE';
begin
 :new.status := v_status;
exception
 when others then
   arp_standard.debug('Exception:xx_om_sales');
   arp_standard.debug('Not able to enqueue the message');
   raise;
end;
/
create or replace trigger trg_cl_po_go_live
before insert on bolinf.xx_po_prov
for each row when
(  new.legal_entity = 'Despegar.com Chile SpA' and new.status = 'NEW')
declare
  v_status varchar2(50) := 'GO_LIVE';
begin
 :new.status := v_status;
exception
 when others then
   arp_standard.debug('Exception:xx_po_prov');
   arp_standard.debug('Not able to enqueue the message');
   raise;
end;
/
create or replace trigger trg_cl_ar_go_live
before insert on bolinf.xx_ar_int_receipts
for each row when
(  new.legal_entity = 'Despegar.com Chile SpA' and new.status = 'NEW')
declare
  v_status varchar2(50) := 'GO_LIVE';
begin
 :new.status := v_status;
exception
 when others then
   arp_standard.debug('Exception:xx_ar_int_receipts');
   arp_standard.debug('Not able to enqueue the message');
   raise;
end;
/

EXIT
