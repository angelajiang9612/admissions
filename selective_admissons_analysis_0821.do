//need some variable to categorize whether they have any MA or not. 

//trying weigning by total admissions a home health agency has across the years 


//for the individual level, try to construct payment using MSBF

//currently 2 million CA observations over five years


use "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/data/CA_15-19_analysis.dta", clear 

tostring assess_date, gen(datestring)

gen datenew=date(datestring,"YMD")

gen mth =month(datenew)
gen year = year(datenew)
gen week=week(datenew)
gen day_of_week = dow(datenew)
*0 is sunday. 
gen weekday = inlist(day_of_week,1,2,3,4,5)

gen therapy_10_more=(therapy_visits_num>=10) 

gen payment_med = (payment_meda==1 | payment_tmed ==1)

local payment_vars payment_ma payment_tm payment_meda payment_tmed payment_managed payment_ffs payment_others 

local adm_vars adm_community adm_hospital adm_snf adm_inpatient therapy_any therapy_10_more

local hth_vars hth_home_therapy hth_vision hth_pain hth_ulcers hth_surgical_wound hth_breathing_problem hth_urine_incont hth_cognitive_problem

local diff_vars diff_grooming diff_dressing diff_bathing diff_toilet diff_transfer_any diff_transfer_severe diff_move_any diff_move_severe diff_eating

local live_vars live_alone live_w_people live_congregate


cd /homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/output/ 

putexcel set admissions_082224.xlsx, modify sheet(main, replace)

putexcel A1 = ("Outcome") B1= ("Coefficient") C1=("se") D1=("N")

local  i = 3

putexcel A`i' = ("Payment source") 

foreach var in `payment_vars' {
	local i =`i'+1
	putexcel A`i' = "`var'"
	local mean_value = r(mean)
	local mean_value_f : di %9.4f `mean_value'
	
	reghdfe `var' percentile `hth_vars', absorb(cms_num year mth day_of_week)  vce (cluster cms_num )
	
	matrix b = e(b)
	local b=_b[percentile]
	local se_b= _se[percentile]
	local n = e(N)
	
	if inrange(2 * ttail(e(df_r), abs(`b'/`se_b')),0.000000000,0.001) local starb = "***"
	else if inrange(2 * ttail(e(df_r), abs(`b'/`se_b')),0.0010000001,0.01) local starb = "**"
	else if inrange(2 * ttail(e(df_r), abs(`b'/`se_b')),0.010000001,0.05) local starb = "*"
	else if inrange(2 * ttail(e(df_r), abs(`b'/`se_b')),0.050000001,0.10) local starb = "+"
	else local starb = ""
	local b_f : di %9.4f `b'
	local se_b_f: di %9.4f `se_b'
	putexcel B`i' =("`b_f'`starb'") 
	putexcel C`i' =("`se_b_f'") 
	putexcel D`i' =("`n'") 

	
}


putexcel A`i' = ("Admission Source Variables") 

foreach var in `adm_vars' {
	local i =`i'+1
	putexcel A`i' = "`var'"
	local mean_value = r(mean)
	local mean_value_f : di %9.4f `mean_value'
	
	reghdfe `var' percentile `hth_vars', absorb(cms_num year mth day_of_week)  vce (cluster cms_num )
	
	matrix b = e(b)
	local b=_b[percentile]
	local se_b= _se[percentile]
	local n = e(N)
	
	if inrange(2 * ttail(e(df_r), abs(`b'/`se_b')),0.000000000,0.001) local starb = "***"
	else if inrange(2 * ttail(e(df_r), abs(`b'/`se_b')),0.0010000001,0.01) local starb = "**"
	else if inrange(2 * ttail(e(df_r), abs(`b'/`se_b')),0.010000001,0.05) local starb = "*"
	else if inrange(2 * ttail(e(df_r), abs(`b'/`se_b')),0.050000001,0.10) local starb = "+"
	else local starb = ""
	local b_f : di %9.4f `b'
	local se_b_f: di %9.4f `se_b'
	putexcel B`i' =("`b_f'`starb'") 
	putexcel C`i' =("`se_b_f'") 
	putexcel D`i' =("`n'") 

	
}




