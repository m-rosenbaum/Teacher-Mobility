********************************************************************************
** 	TITLE: 04a_create_balance_table for sample restriction
**
**	PURPOSE: Create balance table for various restricted sample to show sample
**			standards and approximate covariate coverage for synthetic control.
**							
**	INPUTS: ${data}3b_panel_long.dta
**
**	OUTPUTS: ${tables}4a_bal_tab.tex
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
log using "${logs}/04a_bal_tab_`cdate'.log", replace
di "`cdate'"


*****************************
* 1. Create iebaltab
*****************************
*A. Clean for iebaltab
	*Use long data quarter-year
	use "${data}/3b_panel_long.dta", clear


**A. clean for iebaltab
	*Create first treat
	drop if time == 1
	gsort schid +time
	gen f_trt = .
	gen f_trt_num = .
	
	*Create treatment starting at 3, so have pre-treatment trends. Otherwise restrict out
	qui levelsof time
	forval i = 3(1)`: word count `r(levels)'' {
		loc j = `i' - 1
		by schid: replace f_trt = 1 if sch_trt[`i'] == 1 & sch_trt[`j'] == 0 & time == `i'
		by schid: replace f_trt_num = `i' if sch_trt[`i'] == 1 & sch_trt[`j'] == 0
	}
	// end forval i = 3(1)`: word count `r(levels)''

	destring oss_p, replace
	destring unique_police_p, replace

	*create max_trt 
	egen max_trt = max(sch_trt)

	*gen restriction
	gen restrict_t05 = f_trt_num <= 5 

	*drop missing year
	drop if time == 11 // due to missing reporting by CPS
	keep if max_trt == 1 & sch_trt == 0 // keep pre-treatment outcomes

	loc vlist year avg_salary n_teach p_mobility  ///
		rac_wht_p rac_lat_p rac_blk_p enroll sped_p esl_p frl_p ///
		stu_mob_p attend_p unique_police_p oss_p z_rit_math z_rit_ela z_act_math ///
		z_act_read efle_5e teen_5e network



**B. Balance table out
	/*
		World Bank DIME's balance tab program is perfectly fine for this
		and exports as a TeX file. It conducts an F-test per David McKenzie
		as well as individual t-tests without any multiple comparison. 
	*/
	iebaltab `vlist', grpvar(restrict_t05) savetex("${tables}/4a_bal_tab.tex") replace


**EOF**
