/*

//0817*changed set-up to use just assessment reason level information instead of constructing admissions and discharge for every individual. Summary stats shows present increases over time, indicating there are more discharge information missing than admissions. Can ignore for now because year and month fixed effects are included. 

//compared to v2, factor in people with only admissions or only discharge information.

Questions: do admissions and discharges go across different years? why is there 2016 in this data?

//note we only need the numbers on the dates where admissions took place anyway. 

//first version don't factor in some people are not officially discharged but are doing inpatient stays so probably not needing home health at the particular date. 

//it seems that the data start with 20150101 but about 70,000 observations in the next year. Check whether this is all discharges of some sort. 


//can't just use one year because always start with 0 patients so beginning very biased

should remove firms with has less than 5% MA all the time and firms with more than 95% MA all the time. 

in the first year missing adm information a lot, in the last year missing discharge information

this form doesn't work with some of the dates missing (as zeros) then sorting for the dates will not work

//for the FFS people can see their admission and discharge dates in the homehealth data, might make sense to use those instead just for the FFS people, because they are the majority.

//stata help 
https://www.statalist.org/forums/forum/general-stata-discussion/general/139328-converting-data-from-time-periods-to-counts-on-days
dm0068

to try, medicare medicaid, ma was not, manage vs not, community vs inpatient, informal care vs not
*/

//the forocc.dta is constructed using combine_years_occ.do 

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

tostring assess_date, gen(datestring)

gen datenew=date(datestring,"YMD")

bys id_unique: egen long adm_date_last = max(assess_date*(assess_reason ==1)) 
gen last_adm_date =1 if assess_date ==adm_date_last
bys id_unique: gen adm_last_six_months =(inrange(adm_date_last,20190701,20200529)) 
bys id_unique: egen ever_admited =max(inout)
bys id_unique: egen ever_discharged = min(inout)
bys id_unique: gen admited_no_discharge = (ever_admited ==1 & ever_discharged !=-1 & adm_last_six_months==0) //this still has room for issues because of multiple admissions, but ignore for now
set seed 1234
bys id_unique: gen random = runiformint(1,100) if admited_no_discharge==1 //generate random length of stay 

gen date_disch_constructed = datenew + random  if last_adm_date ==1 & admited_no_discharge==1 //admissions date plus random 

expand 2 if last_adm_date ==1 & admited_no_discharge==1, gen(admit_only)
bys id_unique: egen date_disch_random =max(date_disch_constructed ) if admit_only==1
format %td date_disch_random
gen WANTED = strofreal(date_disch_random, "%tdCCYYNNDD")
destring WANTED, replace 
format %20.0g WANTED 

drop datenew 
drop datestring 

replace assess_date = WANTED if admit_only ==1 
replace inout=-1 if admit_only ==1 

tostring assess_date, gen(datestring)

gen datenew=date(datestring,"YMD")

sort cms_num assess_date  //sort by date 

bys cms_num: gen present = sum(inout) 

by cms_num assess_date: gen dup = cond(_N==1,0,_n) //unique by firm and date 

drop if dup>1


gen mth =month(datenew)
drop year 
gen year = year(datenew)
gen week=week(datenew)
gen day_of_week = dow(datenew)
*0 is sunday. 
gen weekday = inlist(day_of_week,1,2,3,4,5)

gen modate=ym(year,mth)
format modate %tm

lgraph present modate //this increases over time 

lgraph present modate, statistic(median) //this increases over time 

save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/data/CA_15-19_occ2.dta", replace //8 million 




//egen percentile =xtile(present), n(100) by(cms_num) //this is very slow, need to merge with labor data first. 


/*
graph shows increase in present over time. 

tostring assess_date, gen(datestring)

gen datenew=date(datestring,"YMD")

format %td datenew

gen mdate = mofd(datenew)
format mdate %tm
sort mdate 
lgraph present mdate //this increases over time 
*/

/* started code on generating random discharge //create fake discharge information 

*bys id_unique: egen long adm_date_last = max(assess_date*(assess_reason ==1)) 
gen last_adm_date =1 if assess_date ==adm_date_last
bys id_unique: gen adm_last_six_months =(inrange(adm_date_last,20190701,20200529)) 
bys id_unique: egen ever_admited =max(inout)
bys id_unique: egen ever_discharged = min(inout)
bys id_unique: gen admited_no_discharge = (ever_admited ==1 & ever_discharged !=-1 & adm_last_six_months==0)
set seed 1234
bys id_unique: gen random = runiformint(1,100) if admited_no_discharge==1 //generate random length of stay 

tostring assess_date, gen(datestring)
gen datenew=date(datestring,"YMD")
gen date_discharged = datenew + random  if last_adm_date ==1 & admited_no_discharge==1

expand 2 if last_adm_date ==1 & admited_no_discharge==1
bys id_unique: replace assess_date =max(date_discharged) if _n=2 & last_adm_date ==1 & admited_no_discharge==1



/* doesn't seem to differ much this way, 2015 seems weirdly high compared to the rest
bys year month: egen total_census = total(inout)

forvalues i=1(1)12 {
	tab total_census if year ==2015 & month ==`i'
}

forvalues i=1(1)12 {
	tab total_census if year ==2017 & month ==`i'
}


forvalues i=1(1)12 {
	tab total_census if year ==2019 & month ==`i'
}

















//unique res_id: 3273659
//unique id_unique:5028551 -many people seem to have stays in multiple home health

/*
//check people with multiple admissions in the year 

bys id_unique: egen num_admits = sum(assess_reason ==1) //number of admissions observed, substantial multiple admits, only 1.54% admission not observed

by id_unique: gen dup = cond(_N==1,0,_n)

drop if dup >1 //about 30% had more than 1 admissions at the same home health agency 
*/

bys id_unique: egen long adm_date_1st = min(assess_date*(assess_reason ==1)) //keep the date of records that are admissions, if missing then this take 0
bys id_unique: egen long dis_date = max(assess_date*(assess_reason ==7 | assess_reason ==8 | assess_reason ==9)) //keep the dates of records that are discharges/death

//if last date seen is transfer date then replace discharge date by transfer date if discharge date is missing
//if first date seen is resumption of care date then replace adm date by resumption date if admission date is missing 

bys id_unique: egen long first_date = min(assess_date)
bys id_unique: egen long last_date = max(assess_date)

bys id_unique:egen transfer_date = max(assess_date*(assess_reason==6)) 
bys id_unique:egen resump_date = max(assess_date*(assess_reason==3)) 

bys id_unique: gen adm_last_three_months =(inrange(adm_date,20191001,20200529)) //to the last date on record

bys id_unique: replace dis_date = transfer_date if transfer_date == last_date & dis_date==0 & adm_last_three_months ==0 //not in last three months 

bys id_unique: replace adm_date = resump_date  if resump_date == first_date & adm_date==0

bys id_unique: gen dup = cond(_N==1,0,_n) //unique by resident firm 
drop if dup>1
drop dup

gen diff_negative = (dis_date-adm_date<=0) & dis_date!=0 & adm_date!=0 

drop if diff_negative ==1 //if discharge is earlier than admissions or on the same date //many observations were dropped (5-10%)


expand 2 
bys id_unique: gen long date =cond(_n==1,adm_date,dis_date)
bys id_unique: gen inout=cond(_n==1,1,-1)
drop if date==0 //if no date information cannot be used to calculate stocks because will lead to problem with sorting 

sort cms_num date
bys cms_num: gen present = sum(inout) //no negative present now 
bys cms_num date: gen dup = cond(_N==1,0,_n)
drop if dup>1
drop dup

sum present, detail //actually looks alright, the negative stuff become less over time 
save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/CA_06-19_present.dta", replace 













/*

//this should prevent numbers from going too large or too small 

keep if dis_date!=0 & adm_date!=0  //for now keep observations that has both dates. a third of observations deleted--not sure how much due to in other years. ideally need to combine years together and maybe exclude the first year to get rid of stock issus (not observed) -stock variable noisy because does not consider initial stock so for the beginning of the year stock is all underestimated

*

/*
Alternatively 

drop if dis_date==0 & adm_date==0 //drop observations missing admissions date and discharge date. 15088 dropped

br adm_date if dis_date==0

replace dis_date =20151231 if dis_date ==0  //this one not very easonable because a lot of the adm dates are very early in the year

br dis_date if adm_date==0

replace adm_date=20150101 if adm_date==0 //this one seems more reasonable because most of the discharge dates are early in the year


*/


/*
use "/disk/aging/oasis/data/100pct/2015/oas2015.dta", clear 







keep if state_cd == "CA"

drop m1* m2*

destring, replace

tempfile holding
save `holding'

keep rsdnt_intrnl_id
duplicates drop 
set seed 1234 
sample 5

merge 1:m rsdnt_intrnl_id using `holding', assert(match using) keep(match)  //5% sample 


egen unique_id = group(rsdnt_intrnl_id c_ccn)

drop if missing(unique_id)

save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/oasis2015_CA_5.dta", replace


use "/disk/aging/oasis/data/100pct/2015/oas2015.dta", clear 

keep if state_cd == "CA"

destring, replace

save "/homes/nber/jiang326-dua70429/swanson-DUA70429/jiang326-dua70429/CA.dta", replace 



//creating duration 

gen test3=(duration1<=0)

tostring adm_date dis_date, replace
//testing to see admit day is always greater than discharge date 
gen admit= date(adm_date,"YMD")
gen discharge= date(dis_date,"YMD")
gen duration = discharge - admit //mean is around a month

gen test2=(duration <=0)

assert test3==test2
