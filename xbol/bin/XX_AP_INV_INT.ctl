load data
infile *
append
into table xx_ap_inv_int
fields terminated by '|'
optionally enclosed by '"'
trailing nullcols
  (operating_unit                char
  ,status                        char
  ,vendor_num                    char
  ,vendor_site_code              char
  ,group_id                      char
  ,invoice_type_lookup_code      char
  ,invoice_num                   char
  ,description                   char
  ,invoice_date                  date 'DD/MM/YYYY'
  ,terms_date                    date 'DD/MM/YYYY'
  ,gl_date                       date 'DD/MM/YYYY'
  ,invoice_currency_code         char
  ,invoice_amount                integer external
  ,global_attribute_category     char
  ,global_attribute11            char
  ,global_attribute12            char
  ,global_attribute13            char
  ,global_attribute17            char
  ,source                        char
  ,calc_tax_during_import_flag   char
  ,add_tax_to_inv_amt_flag       char
  ,taxation_country              char
  ,payment_method_code           char
  ,payment_currency_code         char
  ,terms_name                    char
  ,payment_cross_rate            integer external
  ,payment_cross_rate_date       date 'DD/MM/YYYY'
  ,pay_group_lookup_code         char
  ,accts_pay_code_combination    char
  ,exclusive_payment_flag        char
  ,line_number                   integer external
  ,line_type_lookup_code         char
  ,amount                        integer external
  ,tax_classification_code       char
  ,dist_code_combination         char
  ,ship_to_location              char
  ,inv_int_id                    "xx_ap_inv_int_s.nextval"
  ,creation_date                 "to_date(sysdate, 'DD/MM/RRRR HH:MI:SS PM')"
  ,created_by                    "fnd_global.user_id"
  ,last_update_date              "to_date(sysdate, 'DD/MM/RRRR HH:MI:SS PM')"
  ,last_updated_by               "fnd_global.user_id"
  ,last_update_login             "fnd_global.login_id")