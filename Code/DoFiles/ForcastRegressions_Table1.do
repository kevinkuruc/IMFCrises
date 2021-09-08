set more off 

do "Code\DoFiles\Forecasts_CleanCompile.do"
use "Data\created\StandardAggregates.dta", clear
local Seasons S F
foreach Szn in `Seasons'{
preserve
qui merge 1:1 Country_code year using "Data\created\Forecasts_`Szn'.dta" 
qui drop _merge
qui encode Country_code, gen(Country_num)
qui xtset Country_num year

**Forecasts Ahead
qui gen CumulativeFcast1 = (1+F1.Fcast1/100)
qui gen CumulativeFcast2 = (1+F1.Fcast1/100)*(1+F2.Fcast2/100)
qui gen CumulativeFcast3 = (1+F1.Fcast1/100)*(1+F2.Fcast2/100)*(1+F3.Fcast3/100)

qui merge 1:1 Country_code year using "Data\created\MasterData.dta"
qui keep if _merge==3
*drop _merge
qui sort Country_num year
qui gen CumulativeGrowth1=(1+FGrowth1/100)
qui gen CumulativeGrowth2=(1+FGrowth1/100)*(1+FGrowth2/100)
qui gen CumulativeGrowth3=(1+FGrowth1/100)*(1+FGrowth2/100)*(1+FGrowth3/100)

qui keep if CumulativeFcast3 !=.
qui keep if CumulativeGrowth3 !=.
qui drop if Currency==.
qui drop if DWDI==.
*qui drop if Banking+Currency+Debt>1 
local growthcontrols DWDI Banking Currency Debt
reg CumulativeGrowth1 CumulativeFcast1  
reg CumulativeGrowth1 CumulativeFcast1 `growthcontrols'  
reg CumulativeGrowth1 CumulativeFcast1 IMF `growthcontrols' 

reg CumulativeGrowth2 CumulativeFcast2  
reg CumulativeGrowth2 CumulativeFcast2 `growthcontrols'  
reg CumulativeGrowth2 CumulativeFcast2 IMF `growthcontrols' 

reg CumulativeGrowth3 CumulativeFcast3 
reg CumulativeGrowth3 CumulativeFcast3 `growthcontrols'   
reg CumulativeGrowth3 CumulativeFcast3 IMF `growthcontrols'
restore  
}
*********************************************************
* Penn World Table Starts for Appendix Table
**********************************************************

use "Data\created\StandardAggregates.dta", clear
local Seasons S F
foreach Szn in `Seasons'{
preserve
qui merge 1:1 Country_code year using "Data\created\Forecasts_`Szn'.dta" 
qui drop _merge
qui encode Country_code, gen(Country_num)
qui xtset Country_num year

**Forecasts Ahead
qui gen CumulativeFcast1 = (1+F1.Fcast1/100)
qui gen CumulativeFcast2 = (1+F1.Fcast1/100)*(1+F2.Fcast2/100)
qui gen CumulativeFcast3 = (1+F1.Fcast1/100)*(1+F2.Fcast2/100)*(1+F3.Fcast3/100)

qui merge 1:1 Country_code year using "Data\created\MasterData_PWT.dta"
qui keep if _merge==3
*drop _merge
qui sort Country_num year
qui gen CumulativeGrowth1=(1+FGrowth1/100)
qui gen CumulativeGrowth2=(1+FGrowth1/100)*(1+FGrowth2/100)
qui gen CumulativeGrowth3=(1+FGrowth1/100)*(1+FGrowth2/100)*(1+FGrowth3/100)

qui keep if CumulativeFcast3 !=.
qui keep if CumulativeGrowth3 !=.
qui drop if Currency==.
qui drop if DPWT==.
local growthcontrols DPWT Banking Currency Debt
reg CumulativeGrowth1 CumulativeFcast1  
reg CumulativeGrowth1 CumulativeFcast1 `growthcontrols'  
reg CumulativeGrowth1 CumulativeFcast1 IMF `growthcontrols' 

reg CumulativeGrowth2 CumulativeFcast2  
reg CumulativeGrowth2 CumulativeFcast2 `growthcontrols'  
reg CumulativeGrowth2 CumulativeFcast2 IMF `growthcontrols' 

reg CumulativeGrowth3 CumulativeFcast3 
reg CumulativeGrowth3 CumulativeFcast3 `growthcontrols'   
reg CumulativeGrowth3 CumulativeFcast3 IMF `growthcontrols'
restore  
}

