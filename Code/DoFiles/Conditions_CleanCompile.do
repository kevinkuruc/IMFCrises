*****************************************************************************
* Opens Conditionality Dataset and Creates a Variable By Country
*****************************************************************************
use "Data\original\inetdataset_main.dta", clear
rename cname Country
rename ccode Country_code

rename BA3TOT conditions //weighted average of soft-hard conditions (all categtories)
keep Country Country_code year conditions
egen id = group(Country_code)
xtset id year
gen conditions2 = conditions if conditions>F1.conditions
replace conditions2 = F1.conditions if F1.conditions>=conditions
drop conditions
rename conditions2 conditions
replace Country_code = "AND" if Country_code=="ADO"
replace Country_code = "COD" if Country_code=="ZAR"
replace Country_code = "UVK" if Country_code=="KSV"
replace Country_code = "ROU" if Country_code=="ROM"
replace Country_code = "TLS" if Country_code=="TMP"

label var conditions "Weighted Avg of all conditions (max of this year and next)"
save "Data\created\conditions.dta", replace





