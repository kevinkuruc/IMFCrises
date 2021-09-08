
import excel "Data/original/SYSTEMIC BANKING CRISES DATABASE_2018.xlsx", sheet("Crisis Years") clear
rename A Country
rename B Banking
rename C Currency
rename D Debt
drop E

split Banking, p(",")
split Currency, p(",")
split Debt, p(",")
drop Banking Currency Debt
drop if [_n]==1
drop if [_n]==1
replace Country = strtrim(Country)
#delimit ;
local vars Banking1 Banking2 Banking3 Banking4
Currency1 Currency2 Currency3 Currency4 Currency5 Currency6 Currency7
Debt1 Debt2 Debt3;
#delimit cr
foreach v in `vars'{
replace `v' = strtrim(`v')
}

preserve
import excel "Data/created/CrossWalk.xlsx", clear first
drop if Country_code==""
tempfile VLCrosswalk
save `VLCrosswalk'
restore

rename Country Country_VL
merge 1:1 Country using `VLCrosswalk'
drop if _merge==1
drop _merge
#delimit ;
#delimit ;
local yrs 
1970 1971 1972 1973 1974 1975 1976 1977 1978 1979
1980 1981 1982 1983 1984 1985 1986 1987 1988 1989
1990 1991 1992 1993 1994 1995 1996 1997 1998 1999
2000 2001 2002 2003 2004 2005 2006 2007 2008 2009
2010 2011 2012 2013 2014 2015 2016 2017 2018 ;
#delimit cr
foreach v in `yrs'{
replace Banking`v' = 1 if Banking1=="`v'" | Banking2=="`v'" | Banking3=="`v'" | Banking4=="`v'"
replace Currency`v' = 1 if Currency1=="`v'" | Currency2=="`v'" | Currency3=="`v'" | Currency4=="`v'" | Currency5=="`v'" | Currency6=="`v'" | Currency7=="`v'"
replace Debt`v'=1 if Debt1=="`v'" | Debt2=="`v'" | Debt3=="`v'"
}
drop `vars'
reshape long Banking Currency Debt, i(Country_code) j(year)
rename Country_VL Country
order Country Country_code year Banking Currency Debt
save "Data\created\ValenciaLaeven.dta", replace
