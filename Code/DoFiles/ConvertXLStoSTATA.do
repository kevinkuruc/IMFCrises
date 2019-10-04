clear 

set more off

cap cd "C:\Users\kevin\OneDrive\IMF"
cap cd "C:\Users\Admin\OneDrive\IMF"
******MAKE WDI DATASET**********
local WDIs GDP ODA CAB Infl EXDEBT NGDPUSD
foreach v in `WDIs'{
import excel using "Data\\original\\`v'WDI.xls", clear firstrow
rename CountryCode Country_code
rename CountryName Country 
drop IndicatorCode
reshape long `v', i(Country) j(year)
tempfile temp`v'
save "`temp`v''"
}

use "`tempGDP'", clear
local lessWDI ODA CAB Infl EXDEBT NGDPUSD
foreach vv in `lessWDI'{
merge 1:1 Country_code year using "`temp`vv''", keepusing(`vv')
drop _merge
}
replace Country_code="UVK" if Country_code=="XKX"
drop IndicatorName 
drop if year<1965

foreach v in GDP ODA NGDPUSD{
	replace `v' = `v'/1000000000
}

label var GDP "2010s Billions of Local Currency"
label var NGDPUSD "(Current) Billions of USD"
label var ODA "(Current) Billions of USD" 
label var CAB "Current Account Balance (% GDP)"
label var EXDEBT "External Debt (% GNI)"
label var Infl "% change CPI"

replace Country_code= "WBG" if Country_code=="PSE"
replace Country_code="UVK" if Country_code=="XKX"

#delimit ;
local Regions ARB CEB CSS EAP EAR EAS ECA ECS EMU EUU FCS HIC HPC IBD
IBT IDA IDB IDX INX LAC LCN LDC LIC LMC LMY LTE MEA MIC MNA NAC OED OSS
PRE PSS PST SAS SSA SSF SST TEA TEC TLA TMN TSA TSS UMC WLD;
#delimit cr
foreach r in `Regions'{
	drop if Country_code == "`r'"
}

rename GDP GDPWDI

tempfile WDI
save "`WDI'"

**ODA as GDP frac
gen ODAPercentGDP = 100*ODA/NGDPUSD
summ ODAPercentGDP, detail
drop NGDPUSD

**PWT Downloadable in STATA so just load it in
merge 1:1 Country_code year using "Data\original\PennWorldTable9.dta", keepusing(rgdpna rgdpe csh_g pop)
drop _merge //worked fine
rename csh_g Gshare
rename rgdpna GDPPWT
gen GDPcap = rgdpe/pop
bysort year: egen yravgGDPcap = mean(GDPcap)
gen GDPRank = GDPcap/yravgGDPcap
replace GDPPWT = GDPPWT
**Label adv economies and LICs
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
import excel using "Data\original\IMFLIC.xlsx", clear firstrow
tempfile LIC
save "`LIC'"
restore

merge m:1 Country_code using "`LIC'", keepusing("IMFLIC")
drop _merge
drop if Country==""
rename IMFLIC LIC 

*Quick clean to look nice... only countries missing dont have enough data to be used
drop if year<1965
drop if Country==""
sort Country year

save "Data\created\StandardAggregates.dta", replace

