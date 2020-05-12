import excel "Data\original\WEO_forecasts.xlsx", clear first sheet(ngdp_rpch)

rename country Country
rename ISOAlpha_3Code Country_code
drop WEO_Country_Code

qui gen Fcast5 = .
qui gen Fcast4 = .
qui gen Fcast3 = .
qui gen Fcast2 = .
qui gen Fcast1 = .
qui gen nowcast = .
qui gen Bcast1 = .
qui gen Bcast2 = .
cap qui destring S*, replace
cap qui destring F*, replace

forvalues yr = 1990/2016{
scalar five = `yr' -5
scalar four = `yr' - 4
scalar three = `yr' - 3
scalar two = `yr' - 2
scalar one = `yr' -1
scalar now = `yr'
scalar Fone = `yr' + 1
scalar Ftwo = `yr' + 2

local Szn F
cap replace Fcast5 = `Szn'`=scalar(five)'ngdp_rpch if year==`yr'
cap replace Fcast4 = `Szn'`=scalar(four)'ngdp_rpch if year==`yr'
cap replace Fcast3 = `Szn'`=scalar(three)'ngdp_rpch if year==`yr'
cap replace Fcast2 = `Szn'`=scalar(two)'ngdp_rpch if year==`yr'
cap replace Fcast1 = `Szn'`=scalar(one)'ngdp_rpch if year==`yr'
cap replace nowcast = `Szn'`=scalar(now)'ngdp_rpch if year==`yr'
cap replace Bcast1 = `Szn'`=scalar(Fone)'ngdp_rpch if year==`yr'
cap replace Bcast2 = `Szn'`=scalar(Ftwo)'ngdp_rpch if year==`yr'
}
label var nowcast "IMF guess in year"
label var Fcast5 "IMF Forecast 5 yrs ago"
label var Fcast4 "IMF Forecast 4 yrs ago"
label var Fcast3 "IMF Forecast 3 yrs ago"
label var Fcast2 "IMF Forecast 2 yrs ago"
label var Fcast1 "IMF Forecast 1 yr ago"
label var Bcast1 "IMF Backcast 1 yr ahead"
label var Bcast2 "IMF Backcast 2 yr ahead"

keep Country Country_code year Fcast* nowcast Bcast*
keep if Country_code!=""
keep if year<2018
save "Data\created\Forecasts.dta", replace
