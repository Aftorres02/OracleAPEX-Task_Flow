-- Core LOV Currencies Data Load
-- Version: 1.0
-- Description: Load ISO-4217 currency data into core_lov_currencies table
-- Source: ISO 4217 Currency Codes

prompt ====================================
prompt Loading ISO-4217 Currency Data
prompt ====================================

merge into core_lov_currencies t
using (
  select 'USD' as currency_code, 'US Dollar' as currency_name, '$' as currency_symbol, 2 as decimal_places, 840 as numeric_code, 1 as display_seq from dual union all
  select 'EUR', 'Euro', '€', 2, 978, 2 from dual union all
  select 'GBP', 'British Pound', '£', 2, 826, 3 from dual union all
  select 'JPY', 'Japanese Yen', '¥', 0, 392, 4 from dual union all
  select 'AUD', 'Australian Dollar', 'A$', 2, 36, 5 from dual union all
  select 'CAD', 'Canadian Dollar', 'C$', 2, 124, 6 from dual union all
  select 'CHF', 'Swiss Franc', 'CHF', 2, 756, 7 from dual union all
  select 'CNY', 'Chinese Yuan', '¥', 2, 156, 8 from dual union all
  select 'INR', 'Indian Rupee', '₹', 2, 356, 9 from dual union all
  select 'MXN', 'Mexican Peso', 'Mex$', 2, 484, 10 from dual union all
  select 'BRL', 'Brazilian Real', 'R$', 2, 986, 11 from dual union all
  select 'ZAR', 'South African Rand', 'R', 2, 710, 12 from dual union all
  select 'SGD', 'Singapore Dollar', 'S$', 2, 702, 13 from dual union all
  select 'HKD', 'Hong Kong Dollar', 'HK$', 2, 344, 14 from dual union all
  select 'NZD', 'New Zealand Dollar', 'NZ$', 2, 554, 15 from dual union all
  select 'SEK', 'Swedish Krona', 'kr', 2, 752, 16 from dual union all
  select 'NOK', 'Norwegian Krone', 'kr', 2, 578, 17 from dual union all
  select 'DKK', 'Danish Krone', 'kr', 2, 208, 18 from dual union all
  select 'PLN', 'Polish Zloty', 'zł', 2, 985, 19 from dual union all
  select 'RUB', 'Russian Ruble', '₽', 2, 643, 20 from dual union all
  select 'TRY', 'Turkish Lira', '₺', 2, 949, 21 from dual union all
  select 'KRW', 'South Korean Won', '₩', 0, 410, 22 from dual union all
  select 'THB', 'Thai Baht', '฿', 2, 764, 23 from dual union all
  select 'IDR', 'Indonesian Rupiah', 'Rp', 2, 360, 24 from dual union all
  select 'MYR', 'Malaysian Ringgit', 'RM', 2, 458, 25 from dual union all
  select 'PHP', 'Philippine Peso', '₱', 2, 608, 26 from dual union all
  select 'ARS', 'Argentine Peso', '$', 2, 32, 27 from dual union all
  select 'CLP', 'Chilean Peso', '$', 0, 152, 28 from dual union all
  select 'COP', 'Colombian Peso', '$', 2, 170, 29 from dual union all
  select 'PEN', 'Peruvian Sol', 'S/', 2, 604, 30 from dual union all
  select 'AED', 'United Arab Emirates Dirham', 'د.إ', 2, 784, 31 from dual union all
  select 'SAR', 'Saudi Riyal', '﷼', 2, 682, 32 from dual union all
  select 'ILS', 'Israeli Shekel', '₪', 2, 376, 33 from dual union all
  select 'EGP', 'Egyptian Pound', 'E£', 2, 818, 34 from dual union all
  select 'NGN', 'Nigerian Naira', '₦', 2, 566, 35 from dual union all
  select 'CZK', 'Czech Koruna', 'Kč', 2, 203, 36 from dual union all
  select 'HUF', 'Hungarian Forint', 'Ft', 2, 348, 37 from dual union all
  select 'RON', 'Romanian Leu', 'lei', 2, 946, 38 from dual union all
  select 'BGN', 'Bulgarian Lev', 'лв', 2, 975, 39 from dual union all
  select 'HRK', 'Croatian Kuna', 'kn', 2, 191, 40 from dual union all
  select 'ISK', 'Icelandic Krona', 'kr', 0, 352, 41 from dual union all
  select 'UAH', 'Ukrainian Hryvnia', '₴', 2, 980, 42 from dual union all
  select 'VND', 'Vietnamese Dong', '₫', 0, 704, 43 from dual union all
  select 'PKR', 'Pakistani Rupee', '₨', 2, 586, 44 from dual union all
  select 'BDT', 'Bangladeshi Taka', '৳', 2, 50, 45 from dual union all
  select 'LKR', 'Sri Lankan Rupee', '₨', 2, 144, 46 from dual union all
  select 'NPR', 'Nepalese Rupee', '₨', 2, 524, 47 from dual union all
  select 'KES', 'Kenyan Shilling', 'KSh', 2, 404, 48 from dual union all
  select 'ETB', 'Ethiopian Birr', 'Br', 2, 230, 49 from dual union all
  select 'GHS', 'Ghanaian Cedi', '₵', 2, 936, 50 from dual
) s on (t.currency_code = s.currency_code)
when matched then
  update set
    t.currency_name = s.currency_name
  , t.currency_symbol = s.currency_symbol
  , t.decimal_places = s.decimal_places
  , t.numeric_code = s.numeric_code
  , t.display_seq = s.display_seq
  , t.active_yn = 'Y'
  , t.last_updated_by = coalesce(
                        sys_context('APEX$SESSION','app_user')
                      , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
                      , sys_context('userenv','session_user')
                      )
  , t.last_updated_on = localtimestamp
when not matched then
  insert (
    currency_code
  , currency_name
  , currency_symbol
  , decimal_places
  , numeric_code
  , display_seq
  , active_yn
  , created_by
  , created_on
  )
  values (
    s.currency_code
  , s.currency_name
  , s.currency_symbol
  , s.decimal_places
  , s.numeric_code
  , s.display_seq
  , 'Y'
  , coalesce(
      sys_context('APEX$SESSION','app_user')
    , regexp_substr(sys_context('userenv','client_identifier'),'^[^:]*')
    , sys_context('userenv','session_user')
    )
  , localtimestamp
  );

commit;

prompt ====================================
prompt Currency data loaded successfully
prompt ====================================

