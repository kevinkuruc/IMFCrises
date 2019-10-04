******************************************************************
** This do file fixes up "Event Study Academic" which is an offshoot
** of code I wrote while at the IMF to judge the effectiveness
** of the IMF with Fragile States. I believe there is a Figure here
** that is striking enough to build an academic publication around.
******************************************************************

clear all
set more off

cap cd "C:\Users\kevin\OneDrive\IMF"
cap cd "C:\Users\Admin\OneDrive\IMF"

use "Data\created\StandardAggregates.dta"
merge 1:1 Country_code year using "Data\created\Forecasts.dta"
drop _merge
merge 1:1 Country_code year using "Data\created\ValenciaLaeven.dta"
drop if _merge==2
drop _merge

merge 1:1 Country_code year using "Data\created\IMFLending.dta"
drop if _merge==2
drop _merge
gen Shortterm = 0 
local shorts SBA SCF RFI RCF PLL FCL ESF
foreach s in `shorts'{
replace Shortterm = 1 if Type=="`s'"
}

**DATA MERGED IN

******************************************************************************
* CREATE GROWTH AND CREATE IMFCRISIS VARIABLE
******************************************************************************

encode Country_code, gen(Country_num)
drop if Country_code==""
xtset Country_num year

local meas WDI PWT
gen logtemp = .
foreach m in `meas'{
replace logtemp = log(GDP`m')
gen D`m' = 100*(GDP`m' - L1.GDP`m')/L1.GDP`m'
}

*GEN IMFCRISIS VARIABLE TO INDICATE HAS IMF INTERVENTION
local crisis Banking Currency Debt
foreach c in `crisis'{
gen IMF`c' = .
replace IMF`c' = 1 if `c'==1
sort Country_num year
recode IMF`c' (1=0) if Type=="" & Type[_n+1]==""
}

******************************************************************************
* GEN FORWARD AND BACKWARD DATA---MAKE DATA "SHORT" FORM
******************************************************************************
forvalues j = 1/5{
gen LGrowth`j' = L`j'.DWDI
}

forvalues j = 1/6{
gen FGrowth`j' = F`j'.DWDI
}

**Forecasts Ahead
replace Fcast1 = F1.Fcast1
replace Fcast2 = F2.Fcast2
replace Fcast3 = F3.Fcast3
replace Fcast4 = F4.Fcast4


******************************************************************************
* GEN CSVs TO TAKE TO JULIA & MASTER STATA FILE
******************************************************************************
******************
* FIRST WITH IMF LOANS WITHOUT CRISES (FOR FIGURE 1)
******************
preserve
keep if Shortterm==1
keep L* F* DWDI Country year AmountAgreedPercentGDP
summ AmountAgreedPercentGDP
drop Fcast*
export delimited "Data\created\AvgPathLoans.csv", replace
restore

******************
*NOW MASTER FILE FOR MAIN ANALYSES
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


sort Country_code year
forvalues b = 1/1{
recode control (1=.) if Type[_n-`b']!="" & yearend[_n-`b'] >= year & year[_n-`b']<year & AmountDrawnUSD[_n-`b']>0
}

sort Country_num year
gen keep = treat+control
kdensity AmountAgreedPercentGDP if treat==1
summ AmountAgreedPercentGDP if treat==1, detail
reg ODAPercentGDP treat if keep>0
reg F1.ODAPercentGDP treat if keep>0
reg ODAPercentGDP treat L1.ODAPercentGDP if keep>0
reg F1.ODAPercentGDP treat L1.ODAPercentGDP if keep>0





