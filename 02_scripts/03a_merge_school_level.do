********************************************************************************
** 	TITLE: 03a_merge_school_level.do
**
**	PURPOSE: Merge school level information
**							
**	INPUTS: ${data}/02a_demos_13_18.dta
** 			${data}/02b_assessment_map.dta
** 			${data}/02c_5es.dta
**			${data}/02d_discipline.dta
** 			${data}/02f_stu_mobility.dta
**			${data}/02h_attendance.dta
**
**	OUTPUTS: 03a_school_level.dta
**				
**	NOTES:
**
**	AUTHOR: Michael Rosenbaum	
**
**	CREATED: 9/1/17	
********************************************************************************
*Table of Contents
*1. Merge on files
*2. Run asserts


version 14.2
cap log close
set more off

loc cdate = subinstr("`c(current_date)'"," ", "", .) // remove spaces
log using "${logs}/03a_merge_school_level_`cdate'.log", replace
di "`cdate'"



*****************************
* 1. Sequentially Merge on School-level
*****************************
*A. Merge on MAP
*B. Merge on ACT
*C. Merge on Discipline
*D. Merge on Mobility
*E. Merge on Attendance
*F. Merge on 5E


**A. Merge on MAP
	use "${data}/02a_demos_2013_${endyear}.dta", clear
	destring schid, replace
	drop if year == 2019 // drop 2019 demos
	gen has_demos = 1

	mmerge schid year using "${data}/02b_assessment_map.dta", t(1:1) 
	tab _merge
	gen has_map = _merge == 3
	/*
	Endyear == 2019
	                          _merge |      Freq.     Percent        Cum.
	---------------------------------+-----------------------------------
	             only in master data |      1,015       24.83       24.83 // HS
	              only in using data |         59        1.44       26.28 // Mostly charters
	   both in master and using data |      3,013       73.72      100.00
	---------------------------------+-----------------------------------
	                           Total |      4,087      100.00
	*/

	replace has_demos = 0 if _merge == 2
	drop _merge


**B. Merge on ACT
	mmerge schid year using "${data}/02g_act.dta", t(1:1)
	tab _merge
	gen has_act = _merge == 3
	gen has_assess = (has_act == 1 | has_map == 1)
	tab has_assess year, m
	drop if _merge == 2
	/*
	Endyear == 2019
	                          _merge |      Freq.     Percent        Cum.
	---------------------------------+-----------------------------------
	             only in master data |      3,437       83.36       83.36 // ES
	              only in using data |         36        0.87       84.23 // Mostly charters
	   both in master and using data |        650       15.77      100.00
	*/

	replace has_demos = 0 if _merge == 2
	replace has_map = 0 if _merge == 2
	drop _merge


**C. Merge on discipline
	mmerge schid year using "${data}/02d_discipline.dta", t(1:1)
	tab _merge
	gen has_discipline = _merge == 3
	drop if _merge == 2
	/*
	Endyear == 2019
	                          _merge |      Freq.     Percent        Cum.
	---------------------------------+-----------------------------------
	             only in master data |        644       15.58       15.58 // Only charters
	              only in using data |         11        0.27       15.84 // only AA schools and charters
	   both in master and using data |      3,479       84.16      100.00
	---------------------------------+-----------------------------------
	                           Total |      4,134      100.00
	*/

	foreach v in has_assess has_act has_demos {
		replace `v' = 0 if _merge == 2
	}
	drop _merge


**D. Merge on sutdent mobility
	mmerge schid year using "${data}/02f_stu_mobility.dta", t(1:1)
	tab _merge
	gen has_mobility = _merge == 3
	drop if _merge == 2
	/*
	                          _merge |      Freq.     Percent        Cum.
	---------------------------------+-----------------------------------
	             only in master data |        782       16.02       16.02 // 672 in 2018
	              only in using data |        795       16.28       32.30 // Duplicates for HS with gifted programs that no longer exist
	   both in master and using data |      3,305       67.70      100.00
	---------------------------------+-----------------------------------
	                           Total |      4,882      100.00
	*/

	foreach v in has_assess has_act has_demos has_discipline {
		replace `v' = 0 if _merge == 2
	}
	drop _merge


**E. Merge on attendance
	mmerge schid year using "${data}/02h_attendance.dta", t(1:1)
	tab _merge
	gen has_attend = _merge == 3
	drop if _merge == 2
	/*
	Endyear == AY2018
	                          _merge |      Freq.     Percent        Cum.
	---------------------------------+-----------------------------------
	              only in using data |      1,007       19.77       19.77 // Duplicates for HS with gifted programs that no longer exist
	   both in master and using data |      4,087       80.23      100.00
	---------------------------------+-----------------------------------
	                           Total |      5,094      100.00
	*/

	foreach v in has_assess has_act has_demos has_discipline has_mobility {
		replace `v' = 0 if _merge == 2
	}
	drop _merge


**F. Merge on 5Es
	mmerge schid year using "${data}/02c_5es.dta", t(1:1)
	tab _merge
	gen has_5e = _merge == 3
	drop if _merge == 2
	/*
	Endyear == AY2018 
		                      _merge |      Freq.     Percent        Cum.
	---------------------------------+-----------------------------------
	             only in master data |         77        1.60        1.60
	              only in using data |        718       14.94       16.55
	   both in master and using data |      4,010       83.45      100.00
	---------------------------------+-----------------------------------
	                           Total |      4,805      100.00
	*/

	foreach v in has_assess has_act has_demos has_discipline has_mobility has_attend {
		replace `v' = 0 if _merge == 2
	}
	drop _merge 



*****************************
* 2. Asserts and var managemtn
*****************************
*A. Check has filled out
*B. Check has assess correct
*C. Manage dataset


**A. Check has filled out
	qui ds has_*
	foreach v in `r(varlist)' {
		assert !mi(`v')
	} 


**B. Check has assess matches
	count if mi(rit_math) & has_map == 1  
	assert `r(N)' == 75 // charters and 4 schools with delayed IEPs
	count if mi(act_math) & has_act == 1
	assert `r(N)' ==16 // charters and options

	count if mi(act_math) & hs == 1 & has_act == 1
	assert `r(N)' == 16 // charters and options
	count if mi(rit_math) & es == 1 & has_map == 1
	assert `r(N)' == 49

	count if mi(efle_5e) & year >= 2014


**C. Manage dataset 
	*drop 2013, as the employment records start in 2013-14
	drop if year == 2013

	*Figure out panel length
	bys schid: gen num_years = _N
	tab num_years
	gen full_panel = num_years == 5 // 656 in for 5 years, 10 for 4, 14 for 3, 10 for 2, 3 for 1

	*Generate charter 
	gen charter = schid <= 500000 // Charter schids start with 4, reg school with 6



*****************************
* Save and Exit
*****************************
*A. Var management
*B. Keep and order
*C. Save and quit


**A. Var management
	loc dif = $endyear - 2013 // full year count labeling

	*Variable labels
	lab var has_demos		"Dummy = 1: Has demographic data"
	lab var has_map			"Dummy = 1: Has NWEA MAP assessment data"
	lab var has_act			"Dummy = 1: Has ACT assessment data"
	lab var has_assess		"Dummy = 1: Has Assessment data"
	lab var has_discipline	"Dummy = 1: Has Discipline data"
	lab var has_mobility 	"Dummy = 1: Has Student mobility data"
	lab var has_attend		"Dummy = 1: Has Attendance data"
	lab var has_5e 			"Dummy = 1: Has 5Es data"
	lab var num_years 		"Number of years school is in panel"
	lab var full_panel 		"Dummy = 1: Has all `dif' years of data"


**B. Keep and Order
	loc vars schid sch_name year network /// IDs
		has_* num_years full_panel


	ds `vars', not
	assert `: word count `r(varlist)'' == 0
	keep `vars'
	order `vars'

	compress


**C. Save and quit
	save "${data}/03a_school_level.dta", replace

	log c


**EOF**
