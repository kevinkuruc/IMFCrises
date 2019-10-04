
clear all
set more off

cap cd "C:\Users\kevin\OneDrive\IMF"
cap cd "C:\Users\Admin\OneDrive\IMF"

import delimited "Data\created\TreatedTable.csv", clear
tempfile Treated
save `Treated'

import delimited "Data\created\ControlTable.csv", clear
append using `Treated'

rename country Country
keep Country year matched
merge 1:1 Country year using "Data\created\MasterData.dta"
*drop if _merge!=3
drop _merge
*drop if matched!=1

cap gen CumulativeFcast4 = (1+Fcast1/100)*(1+Fcast2/100)*(1+Fcast3/100)*(1+Fcast4/100)
cap gen CumulativeGrowth4 = (1+FGrowth1/100)*(1+FGrowth2/100)*(1+FGrowth3/100)*(1+FGrowth4/100)

cap gen CumulativeFcast2 = (1+Fcast1/100)*(1+Fcast2/100)
cap gen CumulativeGrowth2=(1+FGrowth1/100)*(1+FGrowth2/100)

cap gen CumulativeFcast3 = (1+Fcast1/100)*(1+Fcast2/100)*(1+Fcast3/100)
cap gen CumulativeGrowth3=(1+FGrowth1/100)*(1+FGrowth2/100)*(1+FGrowth3/100)


*keep if LGrowth5 !=.
*keep if CumulativeFcast4 !=.
*keep if CumulativeGrowth4 !=.
drop if Currency==.
*drop if DWDI==.
local growthcontrols DWDI Banking Currency Debt
reg FGrowth1 Fcast1 
reg FGrowth1 Fcast1 `growthcontrols' 
reg FGrowth1 Fcast1 IMF `growthcontrols' 

reg CumulativeGrowth2 CumulativeFcast2  
reg CumulativeGrowth2 CumulativeFcast2 `growthcontrols'  
reg CumulativeGrowth2 CumulativeFcast2 IMF `growthcontrols' 

reg CumulativeGrowth3 CumulativeFcast3 
reg CumulativeGrowth3 CumulativeFcast3 `growthcontrols'   
reg CumulativeGrowth3 CumulativeFcast3 IMF `growthcontrols'  

reg CumulativeGrowth4 CumulativeFcast4  
reg CumulativeGrowth4 CumulativeFcast4 `growthcontrols' 
reg CumulativeGrowth4 CumulativeFcast4 IMF `growthcontrols'  

reg CumulativeGrowth2 CumulativeFcast2 IMF
reg CumulativeGrowth2 CumulativeFcast2 IMF DWDI
reg CumulativeGrowth2 CumulativeFcast2 IMF DWDI Banking Currency Debt
reg FGrowth1 Fcast1 DWDI IMF LGrowth5 Banking Currency Debt
reg FGrowth1 Fcast1 DWDI IMF LGrowth1 LGrowth2 LGrowth3 LGrowth4 LGrowth5 Banking Currency Debt
areg FGrowth1 Fcast1 DWDI IMF LGrowth1 LGrowth2 LGrowth3 LGrowth4 LGrowth5 Banking Currency Debt, a(year)

*reg FGrowth1 Fcast1 DWDI Bcast1 Banking Currency Debt

