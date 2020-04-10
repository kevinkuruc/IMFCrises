*****************************************************************************
* Opens the WB CPIA database to generate fragile states indicator 			*
* for integration with Penn World Table 									*
*****************************************************************************
set more off
cd "C:\Users\Kevin\Documents\GitHub\IMFCrises\"



import excel "Data\original\CPIAEXCEL2016.xlsx", clear firstrow sheet("Data")
rename CountryName Country
rename CountryCode Country_code
replace Country_code = "UVK" if Country_code=="XKX"

keep if IndicatorCode=="IQ.CPA.IRAI.XQ"

#delimit ;
local yrs 		1977 1978 1979 1980 1981 1982 1983 1984 1985 1986 1987
				1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998
				1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 
				2010 2011 2012 2013 2014 2015 2016 2017 2018;
collapse (firstnm) Country (mean) CPIA*, by(Country_code);

#delimit cr

local noncountry DFS FXS DSF DNS DNF NXS IDA DXS NRS RRS NLS RSN RSO DSS

foreach code in `noncountry'{
qui drop if Country_code =="`code'"
}
tempfile CPIA05
save "`CPIA05'"

import excel "Data\original\CPIA1977.xlsx", clear firstrow sheet("1977-2004")
rename A Country_code
replace Country_code = "COD" if Country_code=="ZAR" //Dem Rep of Congo Changes
replace Country_code = "UVK" if Country_code=="KVO"
replace Country_code = "TLS" if Country_code=="TMP"
rename B Country
				rename C CPIA1977
				rename D CPIA1978				
				rename E CPIA1979
				rename F CPIA1980
				rename G CPIA1981
				rename H CPIA1982
				rename I CPIA1983
				rename J CPIA1984
				rename K CPIA1985
				rename L CPIA1986
				rename M CPIA1987
				rename N CPIA1988
				rename O CPIA1989
				rename P CPIA1990
				rename Q CPIA1991
				rename R CPIA1992
				rename S CPIA1993
				rename T CPIA1994
				rename U CPIA1995
				rename V CPIA1996
				rename W CPIA1997
				rename X CPIA1998
				rename Y CPIA1999
				rename Z CPIA2000
				rename AA CPIA2001
				rename AB CPIA2002
				rename AC CPIA2003
				rename AD CPIA2004

merge 1:1 Country_code using "`CPIA05'"		

drop _merge				
				
foreach yr in `yrs'{
	label var CPIA`yr' "Bank's CPIA"
	}

reshape long CPIA, i(Country) j(year)

save "Data\created\CPIA.dta", replace




