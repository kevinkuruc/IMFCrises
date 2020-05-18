import excel using "Data\\original\\FundPrograms.xlsx", clear firstrow

gen year = year(Start)
gen yearend = year(Ended)

replace Type = "Supplemental" if Type=="of which Supplemental Reserve Facility"
replace Type = "Supplemental" if Type=="      of which Supplemental Reserve Facility"


collapse (firstnm) Country Type (sum) AmountAgreed AmountDrawn (mean) year (max) yearend, by(Country_code Start)
gen count = 1
collapse (firstnm) Country Type (sum) AmountAgreed AmountDrawn count (max) yearend, by(Country_code year) 
replace Type="Multi" if count>1
drop count

label var AmountAgreed "In Thousands SDRs (Current)"
label var AmountDrawn "In Thousands SDRs (Current)"
label var Type "Lending Instrument"
label var Type "When Program of that Year Ended" 
tempfile Programs
save `Programs'

use "Data\created\StandardAggregates.dta"
keep Country Country_code year

merge 1:1 Country_code year using `Programs'
drop if _merge==2 //only keeping between 1965-2017 to match WDI data
drop _merge
tempfile ProgramsNew
save `ProgramsNew'

import excel using "Data\original\International_Financial_Statistics_SDREX.xlsx", clear firstrow
drop B
reshape long SDRX, i(A) j(year)
drop A
label var SDRX "SDRs to USD Exchange Rate"
tempfile exrates
save `exrates'

import excel using "Data\original\NGDPUSDWDI.xls", clear first
rename CountryCode Country_code
rename CountryName Country 
replace Country_code="UVK" if Country_code=="XKX"
drop IndicatorCode
reshape long NGDPUSD, i(Country) j(year)
keep Country year Country_code NGDPUSD
#delimit ;
local Regions ARB CEB CSS EAP EAR EAS ECA ECS EMU EUU FCS HIC HPC IBD
IBT IDA IDB IDX INX LAC LCN LDC LIC LMC LMY LTE MEA MIC MNA NAC OED OSS
PRE PSS PST SAS SSA SSF SST TEA TEC TLA TMN TSA TSS UMC WLD;
#delimit cr
foreach r in `Regions'{
	drop if Country_code == "`r'"
}
tempfile tempNomGDP
save "`tempNomGDP'"

use `ProgramsNew'
merge m:1 year using `exrates'
drop if _merge==2
drop _merge

gen AmountAgreedUSD = AmountAgreed/SDRX
gen AmountDrawnUSD = AmountDrawn/SDRX

merge 1:1 Country_code year using "`tempNomGDP'", keepusing(NGDPUSD)
drop if _merge==1
drop _merge

gen AmountAgreedPercentGDP = 100*(1000*AmountAgreedUSD/(NGDPUSD)) //SDRs in thousands
gen AmountDrawnPercentGDP  = 100*(1000*AmountDrawnUSD/(NGDPUSD))

summ AmountAgreedPercentGDP if AmountAgreed!=., detail

drop SDRX AmountAgreed AmountDrawn NGDPUSD

replace Type="ESF" if Type=="Exogenous Shock Facility"
replace Type="ECF" if Type=="Extended Credit Facility"
replace Type="EFF" if Type=="Extended Fund Facility"
replace Type="FCL" if Type=="Flexible Credit Line"
replace Type="PLL" if Type=="Precautionary and Liquidity Line"
replace Type="SBA" if Type=="Standby Arrangement"
replace Type="SBCF" if Type=="Standby Credit Facility"
replace Type="SBCF" if Type=="Structural Adjustment Facility Commitment"
replace Type="SBCF" if Type=="Supplemental"

save "Data\created\IMFLending.dta", replace

import delimited "Data\original\CPIFRED.csv", clear
rename cpifred CPI
tempfile CPI
save "`CPI'"

use "Data\created\IMFLending.dta", replace
keep if Type!=""
gen count = 1
collapse (sum) count AmountAgreedUSD, by(year)
merge 1:1 year using "`CPI'"

gen RealAmountAgreed = AmountAgreedUSD*251.1/CPI/1000000 //251.1 is CPI in 2018, divide by 1000000 to put in billions
summ RealAmountAgreed if year>1969 & year<2011, detail


