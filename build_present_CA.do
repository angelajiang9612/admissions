

use "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/data/CA_15-19_occ_simple.dta", clear //8 million 

merge m:1 cms_num year using "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/pos_labor_CA_15-19.dta"

keep if _merge==3

drop _merge 

//many in POS doesn't have OASIS

unique cms_num //3007 firms 

keep cms_num assess_date present fte_rn fte_lpn fte_nurse

gen congestion = present/fte_nurse //use total nurse for now, this will sometimes be negative, often not a variable that can be interpreted by itself because present is a relative term

egen percentile =xtile(congestion), n(100) by(cms_num) 

keep cms_num assess_date percentile present 

save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/data/CA_15-19_occ_final.dta", replace 


use "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/CA_admissions_ind_2015-19.dta", clear 

merge m:1 cms_num assess_date using "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/data/CA_15-19_occ_final.dta"

keep if _merge==3 

save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/data/CA_15-19_analysis.dta", replace 

///////why would so many not be matched? the date system might have some issues with translating to and from....

//not matched from master might be discharged dates that had no admissions and would make sense. but unclear why there should be not matched from the admissions side.. need to check if date conversions went wrong. 

