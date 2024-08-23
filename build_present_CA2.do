/*

//0817*changed set-up to use just assessment reason level information instead of constructing admissions and discharge for every individual. Summary stats shows present increases over time, indicating there are more discharge information missing than admissions. Can ignore for now because year and month fixed effects are included. 


Questions: do admissions and discharges go across different years? why is there other years in each year's data?


https://www.statalist.org/forums/forum/general-stata-discussion/general/139328-converting-data-from-time-periods-to-counts-on-days
dm0068

*/

//the forocc.dta is constructed using combine_years_present.do 

use "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/temp/CA_15-19_forocc.dta", replace //8 million assessments

rename m0090_asmt_cmplt_dt assess_date 
rename m0100_rsn_for_asmt_cd assess_reason 
rename m0010_cms_crtfctn_num cms_num 
rename rsdnt_intrnl_id res_id
drop if missing(res_id) //20 observations
drop if missing(cms_num) //some observations don't have firm id
drop if cms_num =="0"
drop if cms_num =="000000"
egen id_unique = group(res_id cms_num) //unique in firm 

drop if assess_date> 20191231 //in 2020 large increases

label define a_reason 1 "1 start of care" 3 "3 resumption (after inpatient)" 4 "4 recertification" 5 "5 other follow up " 6 "6 tranfered to inpatient (not discharged)" 7 "7 transferred to inpatient (discharged)" 8 "8 death at home" 9 "9 discharged", modify 

label values assess_reason a_reason

gen inout =1 if inlist(assess_reason,1,3) //start or resumption add 1 to stock, /for now just just use assess_date for admissions as proxy for start of care date, which is within 5 days 
 
replace inout=-1 if inlist(assess_reason,6,7,8,9) //transferred (no discharge and discharge), death, and discharge minus 1
drop if inlist(assess_reason,4,5) //4 and 5 disregard 


//*add in the adjustment for people were were not observed to be discharged, exclude for simple version

tostring assess_date, gen(datestring)
gen datenew=date(datestring,"YMD")

bys id_unique: egen long adm_date_last = max(assess_date*(assess_reason ==1)) 
gen last_adm_date =1 if assess_date ==adm_date_last
bys id_unique: gen adm_last_six_months =(inrange(adm_date_last,20190701,20200529)) 

bys id_unique: egen ever_disch_after_last_adm = min(inout*(assess_date >= adm_date_last))  //0 and 1 means no negative 1 

bys id_unique: gen admited_no_discharge = (ever_disch_after_last_adm !=-1 & adm_last_six_months==0) 

set seed 1234
bys id_unique: gen random = runiformint(1,100) if admited_no_discharge==1 //generate random length of stay between 1 and 100 /alternatively can drop this 

gen date_disch_constructed = datenew + random  if last_adm_date ==1 & admited_no_discharge==1 //admissions date plus random 

expand 2 if last_adm_date ==1 & admited_no_discharge==1, gen(admit_only) //create a discharge record, admit_only==1 means second observation. 
bys id_unique: egen date_disch_random =max(date_disch_constructed ) if admit_only==1
format %td date_disch_random
gen WANTED = strofreal(date_disch_random, "%tdCCYYNNDD")
destring WANTED, replace 
format %20.0g WANTED 

drop datenew 
drop datestring 

replace assess_date = WANTED if admit_only ==1 
replace inout=-1 if admit_only ==1 

*//////////////end add in/////////


sort cms_num assess_date  //sort by date 

bys cms_num: gen present = sum(inout) 

by cms_num assess_date: gen last= cond(_n==_N,1,0) //last observation of the day sums over all inouts in that day 
by cms_num assess_date: egen present_final = max(present*(last==1)) //replace present by present in the last observation of the day  

replace present = present_final
drop present 

keep if last ==1 //remove duplicates 

//can just remove some with very high inout 

tostring assess_date, gen(datestring)
gen datenew=date(datestring,"YMD")
gen mth =month(datenew)
drop year 
gen year = year(datenew)
gen week=week(datenew)
gen day_of_week = dow(datenew)
*0 is sunday. 
gen weekday = inlist(day_of_week,1,2,3,4,5)

gen modate=ym(year,mth)
format modate %tm

lgraph present modate  //this increases over time 
lgraph present modate, statistic(median) //this increases over time, but more slowly than mean 

//try this 

tab inout if year==2015
tab inout if year==2016
tab inout if year==2017
tab inout if year==2018
tab inout if year==2019  //looks more balanced except for last year, not sure why there is still small differences in the earlier years

bys cms_num: egen firm_inout = total(inout)
sum firm_inout, detail

/*


lgraph present modate  //this increases over time 
lgraph present modate, statistic(median) //this increases over time, but more slowly than mean 

bys cms_num: egen firm_inout = total(inout)
sum firm_inout, detail
keep if inrange(firm_inout,r(p5),r(p95)) //lowest and highest five percent 

//check some summary statistics 

tab inout if year==2015
tab inout if year==2016
tab inout if year==2017
tab inout if year==2018
tab inout if year==2019 //very stable in terms of ins being 5% higher than outs. 

bys cms_num year: egen firm_inout_year = total(inout) //by year 
sum firm_inout_year if year==2015, detail
sum firm_inout_year if year==2016, detail
sum firm_inout_year if year==2017, detail
sum firm_inout_year if year==2018, detail
sum firm_inout_year if year==2019, detail //over the years look similar 


//even if a home health agency expands, it should still have the same amount of admissions than discharges, just larger of each type. 

*/ 

drop res_id 

save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/data/CA_15-19_present_random_discharge.dta", replace 





