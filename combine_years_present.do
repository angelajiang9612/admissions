*script combines different years using only variables helpful for constructing occupancy measure s



forvalues i = 2006(1)2019 {
	use "/disk/aging/oasis/data/100pct/`i'/oas`i'.dta", clear
	keep if state_cd == "CA"
	keep rsdnt_intrnl_id m0010_cms_crtfctn_num m0090_asmt_cmplt_dt m0100_rsn_for_asmt_cd 
	gen year =`i'
	destring, replace
	save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/CA_`i'_forocc.dta", replace 
}

use "/disk/aging/oasis/data/100pct/2018/oas2018.dta", clear
keep if state_cd == "CA"
rename qies_rsdnt_intrnl_id rsdnt_intrnl_id //in 2018 resident id variable has a different name  
keep rsdnt_intrnl_id m0010_cms_crtfctn_num m0090_asmt_cmplt_dt m0100_rsn_for_asmt_cd 
gen year = 2018
destring, replace
save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/CA_2018_forocc.dta", replace 


use "/disk/aging/oasis/data/100pct/2019/oas2019.dta", clear
keep if state_cd == "CA"
rename qies_rsdnt_intrnl_id rsdnt_intrnl_id //in 2018 resident id variable has a different name  
keep rsdnt_intrnl_id m0010_cms_crtfctn_num m0090_asmt_cmplt_dt m0100_rsn_for_asmt_cd 
gen year = 2019
destring, replace
save "/homes/snber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/CA_2019_forocc.dta", replace 


use "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/CA_2006_forocc.dta", clear 

//tried using five years first 2014-2018 //most recent five years without 2019 (Covid started)

forvalues i = 2007(1)2018 {
	append using "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/CA_`i'_forocc.dta", force 
}

save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/CA_06-18_forocc.dta", replace 
