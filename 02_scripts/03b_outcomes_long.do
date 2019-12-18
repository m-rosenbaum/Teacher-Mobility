********************************************************************************
** 	TITLE: 2b_create_long.do
**
**	PURPOSE: Merge school level information
**							
**	INPUTS: ${data}/03a_school_level.dta
**			${data}/02e_employment_panel.dta
**
**	OUTPUTS: ${data}2b_panel_long.dta
**			 ${data}2b_panel_long.csv
**				
**	NOTES:
**
**	AUTHOR: Michael Rosenbaum	
**
**	CREATED: 11/25/2018
********************************************************************************
*Table of Contents
*1. Merge on files
*2. Run asserts


version 14.2
cap log close
set more off

loc cdate = subinstr("`c(current_date)'"," ", "", .) // remove spaces 
log using "${logs}/03b_create_long_`cdate'.log", replace
di "`cdate'"



*****************************
* 1. Load employment panel
*****************************
*A. Load panel
*B. Create mobility outcomes
*C. Create treatment statuses
*D. Collapse

/*
	Some cleaning revolves around time period 11 (the quarter where 
	CPS employment data changes format). To modify this, I fill the 
	treatment assignment dummy forward to ensure it's not missing
	and then exclude it in the following synthetic control script.
	This functions to the count the mid-year principal change in 
	as a pooled 6-month panel in the middle of the 2015-16 school 
	year.

	This isn't good from an analytical perspective, but as this 
	exercise will not be used aside as a code example, this choice
	is fine. My preferred solution would be to get identified data 
	and not have to deal with the fuzzy merge issues.
*/


**A. Load panel
	use "${data}/02e_employment_panel.dta", clear

	*Create local for number of years
	qui ds fte_p*
	loc current_n = `: word count `r(varlist)''


**B. Create mobility outcomes
	*Non-mobile for each schid
	forval i = 1(1)`current_n' {
		loc j = `i' - 1

		if `i' == 1 {
			gen outmobile`i' = 0 if !mi(fte_p`i')
		}

		else {
			gen outmobile`i' = 0 if !mi(fte_p`i')
			replace outmobile`i' = 1 if mi(fte_p`i') & !mi(fte_p`j') 
		}
	}

	*fix outmobility across missingness
	replace outmobile11 = . if outmobile11 == 1
	replace outmobile12 = 0 if !mi(fte_p10) & !mi(fte_p12)


**C. Create treatment statuses
	*Identify principal
	forval i = 1(1)`current_n' {
		gen principal`i' = (title`i' == "Principal" | title`i' == "Interim Principal" | ///
				title`i' == "Acting Principal" | title`i' == "Resident Principal")
		bys schid: egen has_p`i' = max(principal`i')
	}

	*drop assistant pricnipals
	// MR - assistants aren't teachers and aren't principals, so remove as middle managers
	forval i = 1(1)`current_n' {
		drop if title`i' == "Assistant Principal"
	}

	*Identify treatment
	gen trt1 = 0 
	forval i = 2(1)11 {
		loc j = `i' - 1
		gen trt`i' = 1 if principal`j' == 1 & outmobile`i' == 1
			replace trt`i' = 1 if trt`j' == 1
	}

	*Zero out treatment in time 11 due to CPS data containing only 220 principals in time 11
	replace trt11 = 0 if trt11 == 1
		replace trt11 = . if trt10 == 0
		replace trt11 = 1 if trt10 == 1

	forval i = 12(1)`current_n' {
		loc j = `i' - 1
		gen trt`i' = 1 if principal`j' == 1 & outmobile`i' == 1
			replace trt`i' = 1 if trt`j' == 1
	}

	*fill pull date so no gaps for missing records
	foreach v in pull_date year {
		forval i = 1(1)`current_n' {
			egen mode_`v'`i' = mode(`v'`i')
			replace `v'`i' = mode_`v'`i' if mi(`v'`i')
			assert `v'`i' == mode_`v'`i'
			drop mode_`v'`i'
		}
	}


**D. Collapse
	*egen treat control and salary vars
	destring salary10, replace

	forval i = 1(1)`current_n' {
		bys schid: egen avg_salary`i' = mean(salary`i')
		bys schid: egen n_teach`i' = count(fte_p`i')
		bys schid: egen p_mobility`i' = mean(outmobile`i')
		bys schid: egen sch_trt`i' = max(trt`i')
			replace sch_trt`i' = 0 if mi(sch_trt`i')
	}	
	replace p_mobility11 = .
	replace n_teach11 = .
	replace avg_salary11 = .

	*Convert to school-level dataset
	egen tag = tag(schid)
	keep if tag == 1

	forval i = 2(1)`current_n' {
		qui count if sch_trt`i' == 1
		di "Time `i', Treatment Num == `r(N)'"
	}

	forval i = 2(1)`current_n' {
		qui sum p_mobility`i'
		di "Time `i', Outcome % == `r(mean)'"
	}
	


*****************************
* 2. Manage data
*****************************
*A. Merge on school-level outcomes
*B. Standardize


**A. Merge on school-level coariates
	destring schid, replace

	*Loop through months
	forval i = 1(1)`current_n' {
		mmerge schid year`i' using "${data}/03a_school_level.dta", t(1:1) umatch(schid year) ///
			ukeep(rac_wht_p rac_lat_p rac_blk_p enroll sped_p esl_p frl_p ///
			stu_mob_p attend_p unique_police_p oss_p rit_math rit_ela act_math ///
			act_read efle_5e teen_5e network) uname(t`i'_)
		ds t`i'*
		foreach v in `r(varlist)' {
			loc stub = subinstr("`v'","t`i'_","",.)
			ren t`i'_`stub' `stub'`i'
		}
		drop if _merge == 2
		drop _merge
	}

	# del ;

	lab define network_label
		1	"AUSL" 
		2	"Charter" 
		3	"Contract" 
		4	"ISP" 
		5	"Military" 
		6	"Network 1" 
		7	"Network 10" 
		8	"Network 11" 
		9	"Network 12" 
		10	"Network 13" 
		11	"Network 2" 
		12	"Network 3" 
		13	"Network 4" 
		14	"Network 5" 
		15	"Network 6" 
		16	"Network 7" 
		17	"Network 8" 
		18	"Network 9" 
		19	"OS4" 
		20	"Options" 
		21	"Service Leadership Academies"
	; 

	# del cr

	forval i = 1(1)`current_n' {
		sencode network`i', replace label(network_label)
	}
	// end forval i = 1(1)`current_n'


**B. Standardize test scores
	*Get number of datapoints
	qui ds rit_ela*
	loc map_n = `: word count `r(varlist)''

	foreach v in rit_ela rit_math {
		forval i = 1(1)`map_n' {
			qui summarize `v'`i'
			cap assert `r(N)' != 0
			if _rc continue // skip if no MAP data for a given year
			gen z_`v'`i' = (`v'`i' - `r(mean)') / `r(sd)'
		}
		// end forval i = 1(1)`map_n'

	}
	// end foreach v in rit_ela rit_math

	*ACT now
	qui ds act_math*
	loc act_n = `: word count `r(varlist)''

	foreach v in act_math act_read {
		forval i = 1(1)`act_n' {
			qui summarize `v'`i'
			cap assert `r(N)' != 0
			if _rc continue // skip if no ACT data for a given year
			gen z_`v'`i' = (`v'`i' - `r(mean)') / `r(sd)'
		}
		// end forval i = 1(1)`act_n'
	}


*****************************
* 3. Save and quit
*****************************
*A. Var management 
*B. Keep order
*C. Save and quit


**A. Varlabel
	*only keep those with 5 years of data
	qui ds p_mobility*
	egen tot_mob_data = rownonmiss(`r(varlist)')
	count
	loc dropn = `r(N)'
	keep if tot_mob_data == 20
	count 
	assert `r(N)' == `dropn' - 21 // drop 21 schools (3%) without five years of data

	*Drop if school closed (100% mobility)
	qui ds p_mobility*
	egen max_mob = rowmax(`r(varlist)')
	count
	loc dropn = `r(N)'
	drop if max_mob == 1
	count
	assert `r(N)' == `dropn' - 6 // 6 schools (<1%)
	drop max_mob

	*Assign dummy for those with treatment within the exclusion period for synthetic control calculation 
	/* Need some pre-trends for over one year and to see outcomes within a full
		school year + 1 quarter to capture treatment effects.
	*/
	gen newtrt_lastyear = 1 if trt17 == 0 & (trt18 == 1 | trt19 == 1 | trt20 == 1 | trt21 == 1)
	gen newtrt_firstyear = 1 if trt1 == 1 | trt2 == 1 | trt3 == 1 | trt4 == 1
	count if newtrt_lastyear == 0 & newtrt_firstyear == 0

	forval i = 1(1)`current_n' {
		loc vlab = pull_date`i'
		lab var	avg_salary`i' 	"Average Salary, `vlab'"
		lab var n_teach`i'  	"Number of Teachers, `vlab'"
		lab var p_mobility`i' 	"Percent out-mobile teachers, `vlab'"	
		lab var sch_trt`i' 		"School has principal firing before `vlab'"
	}
	lab var newtrt_lastyear 	"School has principal firing in last year of employment data"
	lab var newtrt_lastyear 	"School has principal firing in first year of employment data"


**B. Keep and order
	loc vars schid pull_date* year* 									/// IDs
		avg_salary* n_teach* p_mobility* sch_trt*						/// Outcomes & Treatment
		rac_wht_p* rac_lat_p* rac_blk_p* enroll* sped_p* esl_p* frl_p* 	/// 20th day vars
		stu_mob_p* attend_p* unique_police_p* oss_p* 					/// Discipline 
		z_rit_math* z_rit_ela* z_act_math* z_act_read* 					/// School-level test score
		efle_5e* teen_5e* newtrt* network*								//  Climete yearr end vars

	keep `vars'
	order `vars'

	*reshape long
	reshape long year pull_date avg_salary n_teach p_mobility sch_trt					///
		rac_wht_p rac_lat_p rac_blk_p enroll sped_p esl_p frl_p 						///
		stu_mob_p attend_p unique_police_p oss_p z_rit_math z_rit_ela z_act_math ///
		z_act_read efle_5e teen_5e network, i(schid) j(time)

	** Generate dummies by network for special governance
	gen ausl = network == 1
	by schid: egen any_ausl = max(ausl)

	gen os4 = network == 19
	by schid: egen any_os4 = max(os4)
	drop os4

	gen isp = network == 4
	by schid: egen any_isp = max(isp)
	drop isp

	**D. Generate restrictions
	// restrict to no turnarounds
	bys schid : egen max_ausl = max(ausl)
	bys schid : egen min_ausl = min(ausl)
	gen rest_nota = max_ausl != min_ausl
	drop max_ausl min_ausl ausl

	*Label dummies
	lab var any_ausl 	"Dummy=1: Part of AUSL in any year"
	lab var any_os4 	"Dummy=1: Part of OS4 in any year"
	lab var any_isp 	"Dummy=1: Part of ISP in any year"
	lab var rest_nota 	"Dummy=1: School has never been a turnaround school"

	*Compress
	compress


**C. Save and quit
	*Save for Stata and R
	save "${data}/03b_panel_long.dta", replace
	export delim using "${data}/03b_panel_long.csv", replace

	log c


**EOF**
