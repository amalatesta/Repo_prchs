select 'export NLS_LANG="'||nls_language
      ||'_'||nls_territory
      ||'.'||nls_codeset||'"' valor_export
from   fnd_languages
where  1=1
and    nls_territory = 'AMERICA'
and    language_code = 'US'
union all
select 'export NLS_LANG="'||nls_language
      ||'_'||nls_territory
      ||'.'||nls_codeset||'"' valor_export
from   fnd_languages
where  1=1
and    nls_territory = 'AMERICA'
and    language_code = 'ESA'
union all
select 'export NLS_LANG="'||nls_language
      ||'_'||nls_territory
      ||'.'||nls_codeset||'"' valor_export
from   fnd_languages
where  1=1
and    nls_territory = 'BRAZIL'
and    language_code = 'PTB'
;
/*
export NLS_LANG="AMERICAN_AMERICA.US7ASCII"
export NLS_LANG="LATIN AMERICAN SPANISH_AMERICA.WE8ISO8859P1"
export NLS_LANG="BRAZILIAN PORTUGUESE_BRAZIL.WE8ISO8859P1"
*/