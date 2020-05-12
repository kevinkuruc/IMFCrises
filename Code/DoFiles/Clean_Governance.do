*****************************************************************************
* Opens World Governance Indicators Dataset and Creates a Variable By Country
*****************************************************************************
set more off
cd "C:\Users\Kevin\Documents\GitHub\IMFCrises\"

use "Data\original\WorldGovernance.dta", clear
rename countryname Country
rename code Country_code

replace Country_code = "AND" if Country_code=="ADO"
replace Country_code = "COD" if Country_code=="ZAR"
replace Country_code = "UVK" if Country_code=="KSV"
replace Country_code = "ROU" if Country_code=="ROM"
replace Country_code = "TLS" if Country_code=="TMP"
collapse gee, by(Country Country_code)
rename gee WGI
label var WGI "General Governance Indicator (Average)"
save "Data\created\WGI.dta", replace





