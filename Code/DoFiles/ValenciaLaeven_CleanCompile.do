clear all
set more off

cap cd "C:\Users\kevin\OneDrive\IMF"
cap cd "C:\Users\Admin\OneDrive\IMF"

local VL Banking Currency Debt Restructure
foreach v in `VL'{
import excel "Data\original\ValenciaLaeven.xlsx", first sheet(`v') clear
reshape long `v', i(Country_code) j(year)
recode `v' (.=0)
tempfile temp`v'
save `temp`v''
}

use `tempBanking', clear
merge 1:1 Country_code year using "`tempCurrency'"
drop _merge
merge 1:1 Country_code year using "`tempDebt'"
drop _merge
merge 1:1 Country_code year using "`tempRestructure'"
drop _merge

save "Data\created\ValenciaLaeven.dta", replace
gen any = 1 if Banking==1 | Currency==1 | Debt==1

collapse (sum) Banking Currency Debt any
