******************************************************************
** This do file fixes up "Event Study Academic" which is an offshoot
** of code I wrote while at the IMF to judge the effectiveness
** of the IMF with Fragile States. I believe there is a Figure here
** that is striking enough to build an academic publication around.
******************************************************************

clear all
set more off

cd "C:\Users\kevin\Desktop\IMF\"

import excel using "Main Data\DATA\WDIEXCEL\GDPWDI(Local).xls", clear first
rename CountryCode Country_code
replace Country_code="UVK" if Country_code=="XKX"
rename CountryName Country 
drop IndicatorName IndicatorCode
reshape long GDPWDI, i(Country) j(year)
drop if year<1960
tempfile tempGDPWDI
save "`tempGDPWDI'"


use "Main Data\DATA\STATA_Ready\IMFLending.dta"
***For now just to get organized I want to keep only relevant variables
keep Country year Country_code ArrType month IMFnew AmtUSD IMFsizeGDP
gen Shortterm = 0 
local shorts SBA SCF RFI RCF PLL FCL ESF
foreach s in `shorts'{
replace Shortterm = 1 if ArrType=="`s'"
}

merge 1:1 Country_code year using "`tempGDPWDI'"
drop _merge

merge 1:1 Country_code year using "Main Data\DATA\STATA_Ready\PennWorldTable9.dta", keepusing(rgdpna rgdpe csh_g pop)
drop _merge
rename csh_g Gshare
rename rgdpna GDPPWT
gen GDPcap = rgdpe/pop
bysort year: egen yravgGDPcap = mean(GDPcap)
gen GDPRank = GDPcap/yravgGDPcap
replace GDPPWT = GDPPWT

merge 1:1 Country_code year using "Main Data\DATA\STATA_Ready\WEOforFragility.dta", keepusing(Infl CAB EXDEBT ToT FDI GDP)
rename GDP GDPWEO
label var ToT "Price of Exports/Price Imports"
drop _merge

merge 1:1 Country_code year using "Main Data\DATA\STATA_Ready\Forecasts.dta"
drop _merge

merge 1:1 Country_code year using "Main Data\DATA\STATA_Ready\ValenciaLaeven.dta"
drop _merge

merge 1:1 Country_code year using "Main Data\DATA\STATA_Ready\CPIA.dta"
drop _merge

replace Country = "Hong Kong" if Country=="Hong Kong SAR"
replace Country = "Sao Tome & Principe" if Country_code=="STP"
replace Country = "Papau New Guinea" if Country=="Papua New Guinea"
replace Country = "Montenegro" if Country=="Montenegro, Rep. of"

****Bring in exchange rate regime data
preserve
import excel "Main Data\DATA\ExchangeRateRegime.xlsx", first sheet(FineTransposed) clear
rename A Country
reshape long RateRegime, i(Country) j(year)
keep if year>1974
replace Country = "Trinidad and Tobago" if Country=="Trinidad & Tobago"
replace Country = "St. Vincent and the Grenadines" if Country=="St. Vincent & Grenadines"
tempfile RR
save `RR'
restore

drop if Country=="West Bank and Gaza"
drop if Country=="New Caledonia"
drop if Country==""

merge 1:1 Country year using `RR'
drop _merge
drop if Country=="West Bank and Gaza" //keep giving me issues
drop if Country=="UAE"
drop if Country=="Netherlands Antilles"

sort Country_code year
bysort Country_code: gen Country_new = Country[_N]
replace Country = Country_new
drop Country_new

****Bring in exchange rate data
preserve
import excel "Main Data\DATA\WEOEXCEL\EXRATEIFS.xlsx", first clear
drop B
reshape long EXRATE, i(Country) j(year)
encode Country, gen(Country_num)
xtset Country_num year 
gen TwoYearApp = 100*(EXRATE/L2.EXRATE -1)
drop Country_num
rename EXRATE REER
tempfile EXRATE
save `EXRATE'
restore

merge 1:1 Country year using `EXRATE'
drop _merge

***Label advanced economies and LICs
#delimit ;
local adv USA DEU FRA ITA ESP NLD BEL AUT GRC PRT FIN IRL SVK
		  SVN LUX EST CYP MLT JPN GBR CAN KOR AUS TWN SWE SGP 
		  CHE HKG CZE NOR ISR DNK NZL ISL;
#delimit cr
gen advecon = 0
foreach v in `adv'{
replace advecon = 1 if Country_code=="`v'"
}

preserve
import excel using "Main Data\DATA\WEOEXCEL\IMFLIC.xlsx", clear firstrow
tempfile LIC
save "`LIC'"
restore

merge m:1 Country_code using "`LIC'", keepusing("IMFLIC")
drop _merge
drop if Country==""
rename IMFLIC LIC 

******************************************************************************
* Data should be merged in by now
******************************************************************************

encode Country_code, gen(Country_num)
drop if Country_code==""
xtset Country_num year

local meas WEO WDI PWT
gen logtemp = .
foreach m in `meas'{
replace logtemp = log(GDP`m')
gen D`m' = 100*(GDP`m' - L1.GDP`m')/L1.GDP`m'
}

local crisis Banking Currency Debt
foreach c in `crisis'{
gen IMF`c' = .
replace IMF`c' = 1 if `c'==1
sort Country_num year
recode IMF`c' (1=0) if ArrType=="" & ArrType[_n+1]==""
}

******************************************************************************
* Gen forward and backward vars
******************************************************************************
forvalues j = 1/5{
gen LGrowth`j' = L`j'.DWDI
}
gen GrowthFall = DWDI - L5.DWDI
gen Pilast = L1.Infl

forvalues j = 1/6{
gen FGrowth`j' = F`j'.DWDI
}

**Forecasts Ahead
replace Fcast1 = F1.Fcast1
replace Fcast2 = F2.Fcast2
replace Fcast3 = F3.Fcast3
replace Fcast4 = F4.Fcast4

replace Pilast = 100*Pilast
******************************************************************************
* Gen CSVs
******************************************************************************
******************
* First with IMF loans ignoring crises
******************
preserve
keep if Shortterm==1
keep L* F* DWDI Country year IMFsizeGDP
summ IMFsizeGDP
drop LIC L3PK FDI Fcast*
export delimited "C:\\Users\\kevin\\Desktop\\IMF\\AERInsights\\Data\\AvgPathLoans.csv", replace
restore

******************
* First with all financial crises pooled
******************
gen treat = 0 
replace treat = 1 if IMFBanking==1 | IMFCurrency==1 | IMFDebt==1
gen control = 0 
replace control = 1 if Banking==1 | Currency==1 | Debt==1
replace control = 0 if treat==1
*Get rid of doubles
replace control = . if L1.Banking==1 | L1.Currency==1 | L1.Debt==1
replace control = . if F1.treat==1
*recode control (1 = .) if ArrType[_n+2]!="" //drop if treated by IMF 2 years afterwards
replace treat = . if L1.Banking==1 | L1.Currency==1 | L1.Debt==1
gen IMF = 1 if treat==1
replace IMF = 0 if control==1

*Checking if this addicted to IMF thing matters
recode control (1=.) if AmtUSD>0 & AmtUSD!=.

*Robustness without Great Recession
*replace control=. if year==2008 
*replace treat=. if year==2008

***Putting IMFamount in to the treated year
replace IMFsizeGDP = F1.IMFsizeGDP if IMFsizeGDP==.


*replace Pilast = Pilast*100
*drop if Country=="Equatorial Guinea" & year==1994
*drop if RateRegime==15
local forsynthmatch IMF Banking Currency Debt LGrowth5 LGrowth4 LGrowth3 LGrowth2 LGrowth1 DWDI GrowthFall FGrowth1 FGrowth2 FGrowth3 FGrowth4 FGrowth5 FGrowth6 EXDEBT CAB Infl ToT GDPRank pop Gshare CPIA rgdpe RateRegime
*preserve 
keep if treat==1 | control==1
keep Country year `forsynthmatch' Fcast* nowcast
export delimited using "C:\Users\kevin\Desktop\IMF\AERInsights\Data\MasterData.csv", replace
*restore 
preserve
keep if control==1 | treat==1
keep Country year `forsynthmatch' Fcast* nowcast
export delimited using "C:\Users\kevin\Desktop\IMF\AERInsights\Data\MasterForecastData.csv", replace
restore
