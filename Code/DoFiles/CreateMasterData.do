******************************************************************
** This do file fixes up "Event Study Academic" which is an offshoot
** of code I wrote while at the IMF to judge the effectiveness
** of the IMF with Fragile States. I believe there is a Figure here
** that is striking enough to build an academic publication around.
******************************************************************

clear all
set more off

*Enter directory here
cd "C:\Users\Admin\Documents\GitHub\IMFCrises"

*Loading in from various external sources
do "Code\DoFiles\StandardAggregates_CleanCompile.do"
do "Code\DoFiles\ValenciaLaeven_CleanCompile.do"
do "Code\DoFiles\LendingData_CleanCompile.do"
do "Code\DoFiles\Governance_CleanCompile.do"
do "Code\DoFiles\Conditions_CleanCompile.do"
do "Code\DoFiles\DebtCrises_Trebesch_CleanCompile.do"

*Merge here to use
use "Data\created\StandardAggregates.dta"
merge 1:1 Country_code year using "Data\created\ValenciaLaeven.dta" //Yugoslavia a bit weird here
drop if _merge==2
drop _merge

**Count Crises for Section 1 Summary Stat
count if Banking==1 & Currency==0 & Debt==0 & year>1969 & year<2014
count if Banking==0 & Currency==1 & Debt==0 & year>1969 & year<2014
count if Banking==0 & Currency==0 & Debt==1 & year>1969 & year<2014
count if Banking+Currency+Debt>1 & Banking+Currency+Debt!=. & year>1969 & year<2014

merge m:1 Country_code year using "Data\created\Default_Details.dta"
drop if _merge==2
drop _merge

* Trebesh dataset has slightly different start dates for these events. Grab lengths from year before & after
replace default_length = default_length[_n-1] if Debt==1 & default_length==.
replace default_length = default_length[_n+1] if Debt==1 & default_length==.
 
merge m:1 Country using "Data\original\Regions.dta" //entered by hand from https://datahelpdesk.worldbank.org/knowledgebase/articles/906519-world-bank-country-and-lending-groups
replace Region="Africa" if Region=="SSA"
drop if _merge!=3
drop _merge

merge 1:1 Country_code year using "Data\created\IMFLending.dta"
drop if _merge!=3 //some years don't overlap
drop _merge
gen Shortterm = 0 
local shorts SBA SCF RFI RCF PLL FCL ESF
foreach s in `shorts'{
replace Shortterm = 1 if Type=="`s'"
}

*Variables for Heterogeneity
merge m:1 Country_code using "Data\created\WGI.dta"
drop if _merge==2
drop _merge

merge 1:1 Country_code year using "Data\created\conditions.dta"
drop if _merge==2
drop _merge
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


******************************************************************************
* GEN CSVs TO TAKE TO JULIA & MASTER STATA FILE
******************************************************************************
******************
* FIRST WITH IMF LOANS WITHOUT CRISES (FOR FIGURE 1)
******************
preserve
keep if Type!=""
keep L* F* DWDI Country year AmountAgreedPercentGDP AmountDrawnPercentAgreed Shortterm simple_conditions CAB EXDEBT Infl
summ AmountAgreedPercentGDP if Shortterm==1 & year>1969 & year<2014, detail
summ DWDI if Shortterm==1 & year>1969 & year<2014, detail
summ simple_conditions if Shortterm==1 & year>1969 & year<2014, detail
export delimited "Data\created\Loans.csv", replace
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
recode control (1 = .) if Type[_n+2]!="" //drop if treated by IMF 2 years afterwards
replace treat = . if L1.Banking==1 | L1.Currency==1 | L1.Debt==1
gen IMF = 1 if treat==1
replace IMF = 0 if control==1


sort Country_code year
forvalues b = 1/1{
recode control (1=.) if Type[_n-`b']!="" & yearend[_n-`b'] >= year & year[_n-`b']<year & AmountDrawnUSD[_n-`b']>0
}

***Putting IMFamount in to the treated year
sort Country_num year
replace AmountAgreedPercentGDP = F1.AmountAgreedPercentGDP if AmountAgreedPercentGDP==. & treat==1
replace AmountDrawnPercentAgreed = F1.AmountDrawnPercentAgreed if AmountDrawnPercentAgreed==. & treat==1
replace AmountDrawn = F1.AmountDrawn if AmountDrawn==. & treat==1
replace Type = Type[_n+1] if treat==1 & Type==""

*drop if Country=="Equatorial Guinea" & year==1994 //BIG OUTLIER, LEAVE IN AS DEFAULT BUT CHECK WITHOUT
#delimit ;
local ForJulia Country Country_code year IMF advecon Banking Currency Debt LGrowth5 LGrowth4 LGrowth3 LGrowth2 LGrowth1
DWDI FGrowth1 FGrowth2 FGrowth3 FGrowth4 FGrowth5 FGrowth6 Region WGI 
conditions quant_conditions structural_conditions AmountAgreedPercentGDP AmountDrawnPercentAgreed AmountDrawn default_length
EXDEBT CAB Infl GDPRank pop Gshare rgdpe;
#delimit cr
preserve 
keep if treat==1 | control==1
count if treat==1 
count if control==1
summ AmountAgreedPercentGDP if treat==1, detail
keep `ForJulia'
save "Data\created\MasterData.dta", replace
export delimited using "Data\created\MasterData.csv", replace
tab year
*Counting Banking Currency and Debt in Main Data
# delimit ;
count if 	Banking ==1 & Currency==0 & Debt==0 & DWDI!=. & FGrowth1!=. & FGrowth2!=. & FGrowth3!=. & FGrowth4!=. & FGrowth5!=. & FGrowth6!=. &
			LGrowth1!=. &  LGrowth2!=. & LGrowth3!=. & LGrowth4!=. & LGrowth5!=.;
count if 	Banking ==0 & Currency==1 & Debt==0 & DWDI!=. & FGrowth1!=. &  FGrowth2!=. & FGrowth3!=. & FGrowth4!=. & FGrowth5!=. & FGrowth6!=. &
			LGrowth1!=. &  LGrowth2!=. & LGrowth3!=. & LGrowth4!=. & LGrowth5!=.; 
count if 	Banking ==0 & Currency==0 & Debt==1 & DWDI!=. & FGrowth1!=. &  FGrowth2!=. & FGrowth3!=. & FGrowth4!=. & FGrowth5!=. & FGrowth6!=. &
			LGrowth1!=. &  LGrowth2!=. & LGrowth3!=. & LGrowth4!=. & LGrowth5!=.;
count if 	Banking + Currency + Debt > 1 & DWDI!=. & FGrowth1!=. &  FGrowth2!=. & FGrowth3!=. & FGrowth4!=. & FGrowth5!=. & FGrowth6!=. &
			LGrowth1!=. &  LGrowth2!=. & LGrowth3!=. & LGrowth4!=. & LGrowth5!=.;
#delimit cr
*Verifying that the local projection in Julia is working correctly
forvalues h = 1/6{
reg FGrowth`h' IMF Banking Currency Debt DWDI LGrowth* if FGrowth6!=.
}
restore 

*** Now PWT iteration of data
forvalues j = 1/5{
replace LGrowth`j' = L`j'.DPWT
}

forvalues j = 1/6{
replace FGrowth`j' = F`j'.DPWT
}

preserve 
keep if treat==1 | control==1
count if treat==1 
count if control==1
summ AmountAgreedPercentGDP if treat==1, detail
#delimit ;
local ForJulia Country Country_code year IMF advecon Banking Currency Debt LGrowth5 LGrowth4 LGrowth3 LGrowth2 LGrowth1
DPWT FGrowth1 FGrowth2 FGrowth3 FGrowth4 FGrowth5 FGrowth6 Region WGI conditions AmountAgreedPercentGDP
EXDEBT CAB Infl GDPRank pop Gshare rgdpe;
#delimit cr
keep `ForJulia'
save "Data\created\MasterData_PWT.dta", replace
export delimited using "Data\created\MasterData_PWT.csv", replace
restore 

*** Now for Levels iteration of the data
forvalues j = 1/5{
	gen LLevels`j' = L`j'.GDPCAP
}

forvalues j = 1/6{
	gen FLevels`j' = F`j'.GDPCAP
}

preserve 
keep if treat==1 | control==1
count if treat==1 
count if control==1
#delimit ;
local ForJulia Country Country_code year IMF advecon Banking Currency Debt LLevels5 LLevels4 LLevels3 LLevels2 LLevels1
GDPCAP FLevels1 FLevels2 FLevels3 FLevels4 FLevels5 FLevels6;
#delimit cr
keep `ForJulia'
save "Data\created\MasterData_Levels.dta", replace
export delimited using "Data\created\MasterData_Levels.csv", replace
restore 
