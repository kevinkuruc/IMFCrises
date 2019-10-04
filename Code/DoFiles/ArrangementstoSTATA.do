clear
set more off

global Folder "C:\Users\kevin\Desktop\IMF"
local imfdata "\Main Data\DATA\IMF Lending"
local juldata "\Main Data\DATA\JuliaData"
local statadata "\Main Data\DATA\STATA_Ready"
 
import excel using "$Folder`imfdata'/FundArrangementsEdit.xlsx", clear firstrow sheet("Edit")
rename Year year
rename OriginalDurationMonths ODuration
rename ActualDurationMonth ADuration
rename TotalAmountApprovedIncluding AmtApp
rename ActualApprovedAmountpercent AmtAppP
rename ActualAvgAnnualAccessperc   AnnualAmtP
rename AccessinofGDP 		       IMFsizeGDP
destring IMFsizeGDP, replace force
rename NGDPinSDRsatyearofapproval NGDPSDR
destring NGDPSDR, replace force
gen IMFsizeAnn = (IMFsizeGDP/ADuration)*12
gen count=1
gen Quota = AmtApp*100/AmtAppP
gen month = month(DateofArrangement)
gen monthend = month(ActualCurrentExpirationDate)
gen yearend  = year(ActualCurrentExpirationDate)
gen yearlength = yearend-year
collapse (firstnm) ArrType Country_code (max) ODuration ADuration monthend yearend (mean) Quota NGDPSDR (sum) AmtApp AmtAppP AnnualAmtP IMFsizeGDP IMFsizeAnn count, by(Country year month)
replace ArrType = "Blend" if count>1
replace count=1
/*
Note for user: Argentina, DRC, and Macedonia each have 2 lending arrangements in a year, which is troublesome for my code.
Argentia + DRC + ETH: Temp. at start of year, signed on for full at end. Will drop for now and manually add back later after "smoothing" arrangements
Macedonia: Two year long ones reported right near one another.. I've made an amendment to the original data to change the start date by 2 days
			so that it collapses in the line above.
Add back in after smoothing longer arrangements:
	ARG 2003: 2174 approved, 2.3% GDP, 3.34% GDP annually
	COD 2009: 25 approved, 1.14% GDP, infinite percent GDP annually (zero length)
	ETH 2009: 33.425 approved, .16% GDP, infinte annually
*/
collapse (firstnm) ArrType Country (max) NGDPSDR Quota ODuration ADuration monthend yearend AmtApp AmtAppP AnnualAmtP IMFsizeGDP IMFsizeAnn (min) month (sum) count, by(Country_code year)
replace AnnualAmtP = 21.667 if Country_code=="COD" & year==2009
drop count
tempfile MONAmerge //have a few I need to take care of... collapse Macedonia, drop ARG COD and ETH double counts to put back in manually
drop if Country_code=="" 
save "`MONAmerge'"

import excel using "$Folder`imfdata'/SDRtoUSD.xlsx", clear firstrow
keep Date USdollarUSD
rename USdollarUSD SDRtoUSD
destring SDRtoUSD, force replace
gen year = regexs(0) if regexm(Date, "[0-9]*$")
drop if year==""
destring year, force replace
collapse ExRate = SDRtoUSD, by(year)  
scalar N = [_N]+1
set obs `=scalar(N)'
replace year = 2017 if [_n]==[_N]
replace ExRate = 0.730471264 if year==2017
tempfile exrates
save `exrates'

import excel using "$Folder`imfdata'/DisburesementsByMonth.xlsx", clear firstrow sheet("STATA")
gen year = year(TransactionValueDate)
rename Amount AmtSDR
replace AmtSDR = AmtSDR/1000000
merge m:1 year using "`exrates'"
gen AmtUSD = AmtSDR/ExRate
gen yearStart = regexs(0) if regexm(OriginalArrangementDate, "[0-9]*$")
destring yearStart, force replace
collapse (sum) AmtSDR AmtUSD (firstnm) FlowType (lastnm) Description (min) yearStart, by(Country_code year)  
label var AmtSDR "Disbursements (millions of SDR)"
label var AmtUSD "Disbursements (millions of USD)"
tempfile Disburse
save `Disburse'

local keepSPR ArrType ODuration ADuration Quota AmtApp AmtAppP AnnualAmtP IMFsizeGDP IMFsizeAnn month monthend yearend NGDPSDR
use "$Folder`statadata'\IMFbase.dta", clear
merge 1:1 Country_code year using "`MONAmerge'", keepusing(`keepSPR')
drop _merge
merge 1:1 Country_code year using "`Disburse'", keepusing(AmtSDR AmtUSD yearStart Description)
drop _merge
replace ArrType="RCF" if Description=="Rapid Credit Facility"
replace ArrType="RFI" if Description=="Rapid Financing Instrument"
recode AmtUSD (.=0)
replace AmtUSD =. if AmtSDR!=. & AmtUSD==0

drop if year<1975 

***Create Vars
gen IMFnew = 1 if ArrType!=""
gen IMFinv =0
replace IMFinv = 1 if AmtSDR!=.
recode AmtSDR (.=0)

preserve
import excel "$Folder/`imfdata'\MONA_LICs.xlsx", clear firstrow sheet("SMPs")
gen NonLend=1
tempfile SMPs
save `SMPs'
restore

merge 1:1 Country_code year using `SMPs'
drop _merge
recode NonLend (.=0)


***Need to label how many months in each year lending arrangement existed
/*
gen F0MinYr = 13-month
recode F0MinYr (.=0)
forvalues t = 1/5{
gen F`t'MinYr = 0
replace F`t'MinYr = 12 if IMFnew==1 & yearend>F`t'.year
replace F`t'MinYr = monthend if IMFnew==1 & yearend==F`t'.year
}

gen IMFfracGDPt=0
forvalues q = 0/5{
replace IMFfracGDPt = (L`q'.F`q'MinYr/12)*L`q'.IMFsizeAnn + IMFfracGDPt if L`q'.IMFnew==1
}


gen IMFinv =0
replace IMFinv = 1 if IMFfracGDPt!=0

recode IMFsizeAnn (.=0)
recode IMFnew (.=0)
gen EverExtend = 1 if ADuration>ODuration & IMFnew==1
replace EverExtend =0 if ADuration<=ODuration & IMFnew==1
gen EverTerm   = 1 if ADuration<ODuration  & IMFnew==1
replace EverTerm = 0 if ADuration>=ODuration & IMFnew==1

gen Extend=0
forvalues i = 1/5{
scalar j = 12*`i'
scalar k = 12*(`i'+1)
replace Extend =1 if L`i'.IMFnew==1 & L`i'.EverExtend==1 & L`i'.ODuration>=j & L`i'.ODuration<k
}

**Put back in 3 weird loans for annual numbers
replace AnnualAmtP = AnnualAmtP+(2174/Quota)*100 if Country_code=="ARG" & year==2003
replace AnnualAmtP = AnnualAmtP+(25/Quota)*100 if Country_code=="COD" & year==2009
replace AnnualAmtP = AnnualAmtP + (33.425/Quota)*100 if Country_code=="ETH" & year==2009
replace IMFfracGDPt = IMFfracGDPt+ (25/NGDPSDR)/10 if Country_code=="COD" & year==2009
replace IMFfracGDPt = IMFfracGDPt + (2174/NGDPSDR)/10 if Country_code=="ARG" & year==2003
replace IMFfracGDPt = IMFfracGDPt + (33.425/NGDPSDR)/10 if Country_code=="ETH" & year==2009

label var IMFfracGDPt "Lending in Yr (% of GDP)"
*/
save "$Folder`statadata'/IMFLending.dta", replace
drop if Country==""
export excel using "$Folder`juldata'\\Lending.xlsx", first(var) replace
