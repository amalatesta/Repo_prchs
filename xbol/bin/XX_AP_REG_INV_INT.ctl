load data
infile *
append
into table xx_ap_inv_int
fields terminated by '|'
optionally enclosed by '"'
trailing nullcols
  (operating_unit              char
  ,status                      char
  ,vendor_num                  char
  ,vendor_site_code            char
  ,group_id                    char
  ,invoice_type_lookup_code    char
  ,invoice_num                 char
  ,description                 char
  ,invoice_date                date 'DD/MM/YYYY'
  ,terms_date                  date 'DD/MM/YYYY'
  ,gl_date                     date 'DD/MM/YYYY'
  ,invoice_currency_code       char
  ,invoice_amount              integer external
  ,source                      char
  ,calc_tax_during_import_flag char
  ,add_tax_to_inv_amt_flag     char
  ,taxation_country            char
  ,payment_method_code         char
  ,payment_currency_code       char
  ,terms_name                  char
  ,payment_cross_rate          integer external
  ,payment_cross_rate_date     date 'DD/MM/YYYY'
  ,pay_group_lookup_code       char
  ,accts_pay_code_combination  char
  ,exclusive_payment_flag      char
  ,line_number                 integer external
  ,line_type_lookup_code       char
  ,amount                      integer external
  ,tax_classification_code     char
  ,dist_code_combination       char
  ,ship_to_location            char
  ,document_sub_type           char
  ,global_attribute_category   char
  ,global_attribute1           char
  ,global_attribute2           char
  ,global_attribute3           char
  ,global_attribute4           char
  ,global_attribute5           char
  ,global_attribute6           char
  ,global_attribute7           char
  ,global_attribute8           char
  ,global_attribute9           char
  ,global_attribute10          char
  ,global_attribute11          char
  ,global_attribute12          char
  ,global_attribute13          char
  ,global_attribute14          char
  ,global_attribute15          char
  ,global_attribute16          char
  ,global_attribute17          char
  ,global_attribute18          char
  ,global_attribute19          char
  ,global_attribute20          char
  ,attribute_category          char
  ,attribute1                  char
  ,attribute2                  char
  ,attribute3                  char
  ,attribute4                  char
  ,attribute5                  char
  ,attribute6                  char
  ,attribute7                  char
  ,attribute8                  char
  ,attribute9                  char
  ,attribute10                 char
  ,attribute11                 char
  ,attribute12                 char
  ,attribute13                 char
  ,attribute14                 char
  ,attribute15                 char
  ,global_attribute_category_l char
  ,global_attribute1_l         char
  ,global_attribute2_l         char
  ,global_attribute3_l         char
  ,global_attribute4_l         char
  ,global_attribute5_l         char
  ,global_attribute6_l         char
  ,global_attribute7_l         char
  ,global_attribute8_l         char
  ,global_attribute9_l         char
  ,global_attribute10_l        char
  ,global_attribute11_l        char
  ,global_attribute12_l        char
  ,global_attribute13_l        char
  ,global_attribute14_l        char
  ,global_attribute15_l        char
  ,global_attribute16_l        char
  ,global_attribute17_l        char
  ,global_attribute18_l        char
  ,global_attribute19_l        char
  ,global_attribute20_l        char
  ,attribute_category_l        char
  ,attribute1_l                char
  ,attribute2_l                char
  ,attribute3_l                char
  ,attribute4_l                char
  ,attribute5_l                char
  ,attribute6_l                char
  ,attribute7_l                char
  ,attribute8_l                char
  ,attribute9_l                char
  ,attribute10_l               char
  ,attribute11_l               char
  ,attribute12_l               char
  ,attribute13_l               char
  ,attribute14_l               char
  ,attribute15_l               char
  ,inv_int_id                  "xx_ap_inv_int_s.nextval"
  ,creation_date               "to_date(sysdate, 'DD/MM/RRRR HH:MI:SS PM')"
  ,created_by                  "fnd_global.user_id"
  ,last_update_date            "to_date(sysdate, 'DD/MM/RRRR HH:MI:SS PM')"
  ,last_updated_by             "fnd_global.user_id"
  ,last_update_login           "fnd_global.login_id")