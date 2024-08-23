//create individual level admissions information to merge with facility occupancy information for regressions, do past five years first 2015-2019

//create individual level admissions information to merge with facility occup

//keep all admission level data 


forvalues i = 2015(1)2017 {
	use "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/OASIS_`i'_CA.dta", replace
	keep if m0100_rsn_for_asmt_cd=="01" //only keep admissions //PPS relevant variables  
	
	local healthvars m1020_prmry_svrty_ratg_cd m1030_home_entrl_cd m1030_home_iv_thrpy_cd m1030_home_noa_cd ///
	m1030_home_prntrl_cd m1200_vsn_cd m1242_pain_freq_cd m1322_stg_1_ulcr_num m1340_srgcl_wnd_cd m1400_sob_cd ///
	m1610_urnry_incntnc_cd m1620_bwl_incntnc_freq_cd m1630_ostmy_cd m1740_dlsnl_cd ///
	m1740_dsrptv_cd m1740_imprd_dcsn_cd m1740_memry_dfct_cd m1740_cgntv_noa_cd ///
	m1740_phys_agrsn_cd m1740_vrbl_dsrptn_c 
	
	local healthvars_adl  m1800_grmg_cd  m1810_dress_upr_cd  m1820_dress_lwr_cd m1830_bathg_cd ///
	m1840_toilt_trnsfr_cd m1845_toilt_hygne_cd m1850_trnsfrg_cd m1860_ambltn_cd m1870_eatg_cd
	
	local service_vars m2200_thrpy_visit_num m1000_dschrg_ltch_cd m1000_dschrg_irf_cd m1000_dschrg_nf_cd ///
	m1000_dschrg_othr_cd m1000_dschrg_psych_cd m1000_dschrg_ipps_cd m1000_dschrg_snf_cd ///
	m1000_no_dschrg_cd m1100_ptnt_lvg_arngmt_cd
	
	keep hha_asmt_id rsdnt_intrnl_id m0010_cms_crtfctn_num m0090_asmt_cmplt_dt m0100_rsn_for_asmt_cd m0150* ///
	`healthvars' `healthvars_adl' `service_vars'
	
	destring, replace 
	gen year=`i'
	format %20.0g hha_asmt_id
	rename m0090_asmt_cmplt_dt assess_date 
	rename m0100_rsn_for_asmt_cd assess_reason 
	rename m0010_cms_crtfctn_num cms_num 
	rename rsdnt_intrnl_id res_id
	drop if missing(res_id) //20 observations
	drop if missing(cms_num) //some observations don't have firm id
	drop if cms_num =="0"
	drop if cms_num =="000000"
	drop if assess_date> 20191231

	rename m0150_mdcd_ffs_pmt_cd    pmt_medicaid_ffs 
	rename m0150_mdcd_hmo_pmt_cd    pmt_medicaid_managed
	rename m0150_mdcr_ffs_pmt_cd    pmt_medicare_ffs //check whether this is correct, seems large 
	rename m0150_mdcr_hmo_pmt_cd    pmt_medicare_managed
	rename m0150_no_pmt_cd          pmt_no_payment 
	rename m0150_othr_govt_pmt_cd   pmt_other_gov 
	rename m0150_othr_pmt_cd        pmt_other_payer
	rename m0150_prvt_hmo_pmt_cd    pmt_private_managed
	rename m0150_prvt_insrnc_pmt_cd pmt_private_insurance 
	rename m0150_self_pay_pmt_cd    pmt_self_pay
	rename m0150_title_pgm_pmt_cd   pmt_title_programs 
	rename m0150_unk_pmt_cd         pmt_unknown
	rename m0150_wc_pmt_cd          pmt_workers_comps

	rename m1000_dschrg_ltch_cd discharged_ltch //discharged from ltch inthe past 14 days //does this change within the person? i.e. should be focus on the admissions one only?
	rename m1000_dschrg_irf_cd discharged_irf //inpatient rehab 
	rename m1000_dschrg_nf_cd discharged_nursing 
	rename m1000_dschrg_othr_cd discharged_other_inpatient
	rename m1000_dschrg_psych_cd discharged_psychiatric 
	rename m1000_dschrg_ipps_cd discharged_short_stay_hospital //this is the biggested group (more than half)
	rename m1000_dschrg_snf_cd discharged_snf 
	rename m1000_no_dschrg_cd discharged_none
	replace m2200_thrpy_visit_num = "000" if  m2200_thrpy_visit_num == "^"
	destring m2200_thrpy_visit_num, replace
	rename m2200_thrpy_visit_num therapy_visits_num 

	destring m1100_ptnt_lvg_arngmt_cd, replace 
	rename m1100_ptnt_lvg_arngmt_cd living_arrangement 

	label define living 1 "1 lives alone, around the clock assistance" 2  "2 lives alone, daytime assistance"  3 "3 lives alone, nigh time assistance" 4 "4 lives alone, occasional assistance" 5 "5 lives alone, no assistance" 6 "6 lives w people, around the clock assistance"  7 "7 lives w people, daytime assistance" 8 "8 lives w people, nigh time assistance" 9 "9 lives w people, occasional assistance" 10 " lives w people, no assistance" 11 "11 lives in congregate, around the clock assistance" 12 "12 lives in congregate, daytime assistance"  13 "13 lives lives in congregate, nigh time assistance" 14 "14 lives in congregate, occasional assistance" 15 "15 lives in congregate, no assistance"
	label values living_arrangement living //basically less than 1 percent of these people do not receive any assistance at all, so they are likely tobe pretty sick 

	//payment source

	gen payment_ma = (pmt_medicare_managed ==1)
	gen payment_tm = (pmt_medicare_ffs ==1)
	gen payment_meda = (pmt_medicaid_managed==1)
	gen payment_tmed = (pmt_medicaid_ffs==1)
	gen payment_managed = (pmt_medicaid_managed==1 | pmt_medicare_managed ==1)
	gen payment_ffs = (pmt_medicare_ffs ==1 | pmt_medicaid_ffs==1)
	gen payment_others =(pmt_no_payment ==1 | pmt_other_gov ==1 | pmt_other_payer==1 | pmt_private_managed==1| ///
	 pmt_private_insurance ==1| pmt_self_pay==1 | pmt_title_programs==1 | pmt_unknown==1 | pmt_workers_comp==1)

	//services information and therapy 

	gen adm_community = (discharged_none==1)
	gen adm_hospital = (discharged_short_stay_hospital==1)
	gen adm_snf = (discharged_snf ==1)
	gen adm_inpatient =(discharged_ltch==1 | discharged_irf ==1 | discharged_nursing==1 | ///
	discharged_other_inpatient==1 | discharged_psychiatric==1 | discharged_short_stay_hospital ==1 | discharged_snf ==1)
	gen therapy_any = (therapy_visits_num>=1)

	//living arrangements and assistance 
	gen live_alone = inrange(living_arrangement,1,5)
	gen live_w_people = inrange(living_arrangement,6,10)
	gen live_congregate = inrange(living_arrangement,11,15)

	//other health conditions 

	//m1020_prmry_svrty_ratg_cd missing in 30% of cases, do not use 
	gen hth_home_therapy =(m1030_home_noa_cd==0) //IV or parethernal or nutrition
	gen hth_vision = inlist(m1200_vsn_cd,1,2) //moderate or severe 
	gen hth_pain = inlist(m1242_pain_freq_cd,3,4) //daily or all the time 
	gen hth_ulcers = inlist(m1322_stg_1_ulcr_num,1,2,3,4) //pressure ulcers 
	gen hth_surgical_wound = inlist(m1340_srgcl_wnd_cd,1,2)
	gen hth_breathing_problem = inlist(m1400_sob_cd,1,2,3,4) 
	gen hth_urine_incont = inlist(m1610_urnry_incntnc_cd,1,2)
	//skipped bowl incont and ostmy because rare and has missing 
	gen hth_cognitive_problem = (m1740_cgntv_noa_cd==0) //summaries memory issues (common) and decision impairemen (common) and disruptive behavior (rare)

	//ADL 
	gen diff_grooming = inlist(m1800_grmg_cd,1,2,3)
	gen diff_dressing = inlist(m1810_dress_upr_cd,1,2,3) | inlist(m1820_dress_lwr_cd ,1,2,3)
	gen diff_bathing = inrange(m1830_bathg_cd,2,6) //1 is can do with device 
	gen diff_toilet = inrange(m1840_toilt_trnsfr_cd,1,4)
	gen diff_transfer_any = inrange(m1850_trnsfrg_cd,1,5) //with device 
	gen diff_transfer_severe = inrange(m1850_trnsfrg_cd,2,5) //can't do byself 
	gen diff_move_any  = inrange(m1860_ambltn_cd,1,6)
	gen diff_move_severe  = inrange(m1860_ambltn_cd,3,6)
	gen diff_eating = inrange(m1870_eatg_cd,2,5) //somewhat severe 


	//keep only relevant variables 
	keep res_id cms_num assess_date hha_asmt_id payment* adm* therapy* live* hth* diff* 
	save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/admissions_ind_`i'.dta", replace  
}


//keep all admission level data, only difference is the qies thing

forvalues i = 2018(1)2019 {
	use "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/OASIS_`i'_CA.dta", replace
	keep if m0100_rsn_for_asmt_cd=="01" //only keep admissions //PPS relevant variables  
	local healthvars m1020_prmry_svrty_ratg_cd m1030_home_entrl_cd m1030_home_iv_thrpy_cd m1030_home_noa_cd ///
	m1030_home_prntrl_cd m1200_vsn_cd m1242_pain_freq_cd m1322_stg_1_ulcr_num m1340_srgcl_wnd_cd m1400_sob_cd ///
	m1610_urnry_incntnc_cd m1620_bwl_incntnc_freq_cd m1630_ostmy_cd m1740_dlsnl_cd ///
	m1740_dsrptv_cd m1740_imprd_dcsn_cd m1740_memry_dfct_cd m1740_cgntv_noa_cd ///
	m1740_phys_agrsn_cd m1740_vrbl_dsrptn_c 
	
	local healthvars_adl  m1800_grmg_cd  m1810_dress_upr_cd  m1820_dress_lwr_cd m1830_bathg_cd ///
	m1840_toilt_trnsfr_cd m1845_toilt_hygne_cd m1850_trnsfrg_cd m1860_ambltn_cd m1870_eatg_cd 
	
	local service_vars m2200_thrpy_visit_num m1000_dschrg_ltch_cd m1000_dschrg_irf_cd m1000_dschrg_nf_cd ///
	m1000_dschrg_othr_cd m1000_dschrg_psych_cd m1000_dschrg_ipps_cd m1000_dschrg_snf_cd ///
	m1000_no_dschrg_cd m1100_ptnt_lvg_arngmt_cd
	
	keep hha_asmt_id qies_rsdnt_intrnl_id m0010_cms_crtfctn_num m0090_asmt_cmplt_dt m0100_rsn_for_asmt_cd m0150* ///
	`healthvars' `healthvars_adl' `service_vars'
	destring, replace 
	gen year=`i'
	format %20.0g hha_asmt_id
	rename m0090_asmt_cmplt_dt assess_date 
	rename m0100_rsn_for_asmt_cd assess_reason 
	rename m0010_cms_crtfctn_num cms_num 
	rename qies_rsdnt_intrnl_id res_id
	drop if missing(res_id) //20 observations
	drop if missing(cms_num) //some observations don't have firm id
	drop if cms_num =="0"
	drop if cms_num =="000000"
	drop if assess_date> 20191231

	rename m0150_mdcd_ffs_pmt_cd    pmt_medicaid_ffs 
	rename m0150_mdcd_hmo_pmt_cd    pmt_medicaid_managed
	rename m0150_mdcr_ffs_pmt_cd    pmt_medicare_ffs //check whether this is correct, seems large 
	rename m0150_mdcr_hmo_pmt_cd    pmt_medicare_managed
	rename m0150_no_pmt_cd          pmt_no_payment 
	rename m0150_othr_govt_pmt_cd   pmt_other_gov 
	rename m0150_othr_pmt_cd        pmt_other_payer
	rename m0150_prvt_hmo_pmt_cd    pmt_private_managed
	rename m0150_prvt_insrnc_pmt_cd pmt_private_insurance 
	rename m0150_self_pay_pmt_cd    pmt_self_pay
	rename m0150_title_pgm_pmt_cd   pmt_title_programs 
	rename m0150_unk_pmt_cd         pmt_unknown
	rename m0150_wc_pmt_cd          pmt_workers_comps

	rename m1000_dschrg_ltch_cd discharged_ltch //discharged from ltch inthe past 14 days //does this change within the person? i.e. should be focus on the admissions one only?
	rename m1000_dschrg_irf_cd discharged_irf //inpatient rehab 
	rename m1000_dschrg_nf_cd discharged_nursing 
	rename m1000_dschrg_othr_cd discharged_other_inpatient
	rename m1000_dschrg_psych_cd discharged_psychiatric 
	rename m1000_dschrg_ipps_cd discharged_short_stay_hospital //this is the biggested group (more than half)
	rename m1000_dschrg_snf_cd discharged_snf 
	rename m1000_no_dschrg_cd discharged_none
	replace m2200_thrpy_visit_num = "000" if  m2200_thrpy_visit_num == "^"
	destring m2200_thrpy_visit_num, replace
	rename m2200_thrpy_visit_num therapy_visits_num 

	destring m1100_ptnt_lvg_arngmt_cd, replace 
	rename m1100_ptnt_lvg_arngmt_cd living_arrangement 

	label define living 1 "1 lives alone, around the clock assistance" 2  "2 lives alone, daytime assistance"  3 "3 lives alone, nigh time assistance" 4 "4 lives alone, occasional assistance" 5 "5 lives alone, no assistance" 6 "6 lives w people, around the clock assistance"  7 "7 lives w people, daytime assistance" 8 "8 lives w people, nigh time assistance" 9 "9 lives w people, occasional assistance" 10 " lives w people, no assistance" 11 "11 lives in congregate, around the clock assistance" 12 "12 lives in congregate, daytime assistance"  13 "13 lives lives in congregate, nigh time assistance" 14 "14 lives in congregate, occasional assistance" 15 "15 lives in congregate, no assistance"
	label values living_arrangement living //basically less than 1 percent of these people do not receive any assistance at all, so they are likely tobe pretty sick 

	//payment source

	gen payment_ma = (pmt_medicare_managed ==1)
	gen payment_tm = (pmt_medicare_ffs ==1)
	gen payment_meda = (pmt_medicaid_managed==1)
	gen payment_tmed = (pmt_medicaid_ffs==1)
	gen payment_managed = (pmt_medicaid_managed==1 | pmt_medicare_managed ==1)
	gen payment_ffs = (pmt_medicare_ffs ==1 | pmt_medicaid_ffs==1)
	gen payment_others =(pmt_no_payment ==1 | pmt_other_gov ==1 | pmt_other_payer==1 | pmt_private_managed==1| ///
	 pmt_private_insurance ==1| pmt_self_pay==1 | pmt_title_programs==1 | pmt_unknown==1 | pmt_workers_comp==1)

	//services information and therapy 

	gen adm_community = (discharged_none==1)
	gen adm_hospital = (discharged_short_stay_hospital==1)
	gen adm_snf = (discharged_snf ==1)
	gen adm_inpatient =(discharged_ltch==1 | discharged_irf ==1 | discharged_nursing==1 | ///
	discharged_other_inpatient==1 | discharged_psychiatric==1 | discharged_short_stay_hospital ==1 | discharged_snf ==1)
	gen therapy_any = (therapy_visits_num>=1)

	//living arrangements and assistance 
	gen live_alone = inrange(living_arrangement,1,5)
	gen live_w_people = inrange(living_arrangement,6,10)
	gen live_congregate = inrange(living_arrangement,11,15)

	//other health conditions 

	//m1020_prmry_svrty_ratg_cd missing in 30% of cases, do not use 
	gen hth_home_therapy =(m1030_home_noa_cd==0) //IV or parethernal or nutrition
	gen hth_vision = inlist(m1200_vsn_cd,1,2) //moderate or severe 
	gen hth_pain = inlist(m1242_pain_freq_cd,3,4) //daily or all the time 
	gen hth_ulcers = inlist(m1322_stg_1_ulcr_num,1,2,3,4) //pressure ulcers 
	gen hth_surgical_wound = inlist(m1340_srgcl_wnd_cd,1,2)
	gen hth_breathing_problem = inlist(m1400_sob_cd,1,2,3,4) 
	gen hth_urine_incont = inlist(m1610_urnry_incntnc_cd,1,2)
	//skipped bowl incont and ostmy because rare and has missing 
	gen hth_cognitive_problem = (m1740_cgntv_noa_cd==0) //summaries memory issues (common) and decision impairemen (common) and disruptive behavior (rare)

	//ADL 
	gen diff_grooming = inlist(m1800_grmg_cd,1,2,3)
	gen diff_dressing = inlist(m1810_dress_upr_cd,1,2,3) | inlist(m1820_dress_lwr_cd ,1,2,3)
	gen diff_bathing = inrange(m1830_bathg_cd,2,6) //1 is can do with device 
	gen diff_toilet = inrange(m1840_toilt_trnsfr_cd,1,4)
	gen diff_transfer_any = inrange(m1850_trnsfrg_cd,1,5) //with device 
	gen diff_transfer_severe = inrange(m1850_trnsfrg_cd,2,5) //can't do byself 
	gen diff_move_any  = inrange(m1860_ambltn_cd,1,6)
	gen diff_move_severe  = inrange(m1860_ambltn_cd,3,6)
	gen diff_eating = inrange(m1870_eatg_cd,2,5) //somewhat severe 


	//keep only relevant variables 
	keep res_id cms_num assess_date hha_asmt_id payment* adm* therapy* live* hth* diff* 
	save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/admissions_ind_`i'.dta", replace  
}

use "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/admissions_ind_2015.dta", clear 

forvalues i = 2016(1)2019 {
	append using "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/admissions_ind_`i'.dta"
}

order cms_num assess_date res_id payment* adm* therapy* live* hth* diff* hha_asmt_id 

save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/CA_admissions_ind_2015-19.dta", replace 











/*

Health codes (refer to document home_health_PPS_OASIS)  -generally try to use the variable closest to the variable used that doesn't have nonmissing. 
*use the bigger categories with no missing first. Can use the more detailed severity ones later after recoding to make the levels more interpretable 


m1020_prmry_svrty_ratg_cd //primary severity rating IDC-9 Code, some missing values 
m1030_home_entrl_cd //iv/parethernal therapy, no missing values
m1030_home_iv_thrpy_cd 
m1030_home_noa_cd 
m1030_home_prntrl_cd
m1200_vsn_cd //vision, 1/3 has mild vision issues, no missing 
m1242_pain_freq_cd //pain frequency, over half has constant pain
m1322_stg_1_ulcr_num //number of stage 1 pressure ulcers //98% no ulcers
m1340_srgcl_wnd_cd //no missing 
m1400_sob_cd //difficulty breathing, many has moderate levels, no missing 
m1610_urnry_incntnc_cd //half has urine incontinence, no missing 
m1620_bwl_incntnc_freq_cd //1.5% missing values 
m1630_ostmy_cd //Ostomy For Bowel, rare, no missing 
m1740_dlsnl_cd /cognitive problems, non-missing 
m1740_dsrptv_cd 
m1740_imprd_dcsn_cd 
m1740_memry_dfct_cd 
m1740_cgntv_noa_cd //this is the summary variable, 30% has some cognitive problems. 
m1740_phys_agrsn_cd 
m1740_vrbl_dsrptn_c

m1800_grmg_cd //ADLs current, mostly somewhat limited and require assistance, no missing 
m1810_dress_upr_cd 
m1820_dress_lwr_cd 
m1830_bathg_cd 
m1840_toilt_trnsfr_cd 
m1845_toilt_hygne_cd 
m1850_trnsfrg_cd 
m1860_ambltn_cd 
m1870_eatg_cd

m2200_thrpy_visit_num //3.75 NA, just replace by zero because represents therapy needed not applicable. , 70% requires some therapy 










use "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/OASIS_2019_5pc.dta", clear

keep if state_cd == "CA"

save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/CA_5pc_2019.dta", replace 







