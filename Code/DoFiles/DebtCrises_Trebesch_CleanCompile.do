*****************************************************************************
* Opens Trebesch Dataset and cleans it for analysis
* Source: https://sites.google.com/site/christophtrebesch/data (2020 Monthly Default Dataset)
*****************************************************************************
import excel "Data\original\Asonuma_Trebesch_DEFAULT_DATABASE.xlsx", clear sheet("DATASET Defaults & Restruct.") cellrange(E6) firstrow
drop	P
gen 	default_length = (Endofrestructuringcompletion - Startofdefaultorrestructurin)/30
rename 	Countrycase Country
rename 	WDIcode Country_code
gen 	year = year(Startofdefaultorrestructurin)
keep 	Country Country_code year default_length
drop if Country == ""
replace Country_code = "HRV" if Country == "Croatia"
replace Country_code = "ROU" if Country == "Romania"
replace Country_code = "SVN" if Country == "Slovenia"


* some doubles to deal with in unique ways -- Poland and Yugoslavia have years with 2 unique defaults
sort Country year
gen dble = 1 if Country[_n] == Country[_n+1] & year[_n] == year[_n+1]
foreach c in POL YUG{
replace default_length = default_length + default_length[_n+1] if dble==1 & Country_code=="`c'"
drop if dble[_n-1] == 1 & Country_code=="`c'"
}
drop dble
collapse (firstnm) Country (max) default_length, by(Country_code year)

label var default_length "Months between announcement and completion of restructuring"
drop Country //just to make sure they don't replace names
save "Data\created\Default_Details.dta", replace  


