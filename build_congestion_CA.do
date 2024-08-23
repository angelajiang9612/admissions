
*v2 correct for minor problem with how present is constructed when there are multiple admissions and discharges on the same date. 

use "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/data/CA_15-19_present_random_discharge.dta", clear ////

merge m:1 cms_num year using "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/pos_labor_CA_15-19.dta"

keep if _merge==3

drop _merge //many not matched, should probably check why and see if the POS information is matched correctly or look if discarded too any POS firms 

unique cms_num //1596 firms 

gen congestion = present/fte_nurse //use total nurse for now, this will sometimes be negative, often not a variable that can be interpreted by itself because present is a relative term

sort cms_num 

gquantiles percentile  = congestion, xtile by(cms_num)  nq(100)

keep cms_num assess_date percentile present datenew

save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/CA_15-19_present_random.dta", replace 


use "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/CA_admissions_ind_2015-19.dta", clear 

merge m:1 cms_num assess_date using "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/CA_15-19_present_random.dta"

keep if _merge==3 //not matched from master because many in using were dropped due to having no labor information, not matched from using because there are dates where only discharged and no admissions took place 

drop _merge 

save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/data/CA_15-19_present_0822_random.dta", replace 

//versions

//CA_15-19_present_analysis (merged with simple version)









/*



//not matched from master might be discharged dates that had no admissions and would make sense. but unclear why there should be not matched from the admissions side.. need to check if date conversions went wrong. 

use "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/data/CA_15-19_present_simple.dta", clear 

merge 1:m cms_num assess_date using

"/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/CA_admissions_ind_2015-19.dta" //this part is correct, there should be no unmatched in using 

renam _merge _merged_with_individual //don't drop anything yet because dates need to be used for creating percentile --could use only percentile for admitted date .






