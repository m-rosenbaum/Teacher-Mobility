********************************************************************************
** 	TITLE: 02g_clean_act.do
**
**	PURPOSE: Clean ACT test data for high schools from website
**							
**	INPUTS: AverageACT_2016_SchoolLevels.xls
**
**	OUTPUTS: 02g_act.dta
**				
**	NOTES:
**
**	AUTHOR: Michael Rosenbaum	
**
**	CREATED: 11/24/2018
**
**	EDITED:		
********************************************************************************
*Table of Contents
*1. Load and clean data
*2. Run Regressions 


version 14.2
cap log close
set more off

loc cdate = subinstr("`c(current_date)'", " ", "", .) // remove spaces
log using "${logs}/02g_clean_act_`cdate'.do", replace
di "`cdate'"


*****************************
* 1. Load and clean data
*****************************
*A. Load excel
*B. Reshape

**A. Load Excel
	*import excel
	import excel using "${raw}/AverageACT_2016_SchoolLevel.xls", first  clear


**B. Rename and keep obs
	ren SchoolName 			sch_name
	ren SchoolID 			schid
	ren Network 			network
	ren Category 			category
	ren CategoryBreakdown 	category_breakdown
	ren Grade 				grade
	ren Year 				year
	ren Read				act_read
	ren Math				act_math
	ren Science 			act_sci
	ren Composite			act_comp
	ren n_read 				n_act_read
	ren n_math 				n_act_math
	ren n_comp 				n_act_comp
	
	*Keep obs
	keep if category == "Overall"
	destring year, replace
	keep if year >= 2013 & year <= 2018
	drop category category_breakdown grade act_sci n_sci

	destring schid, replace



************************
* 2. Save and exit
************************
*A. Var management
*B. keep and order
*C. Save and quit


**A. Var management 
	*Variable labels
	lab var schid 		"School ID, 6 Digit"
	lab var sch_name    "School Name"
	lab var year 		"Spring School Year"
	lab var network		"CPS Academic Network"
	lab var act_read 	"ACT Reading Scale Score"
	lab var act_math 	"ACT Math Scale Score"
	lab var act_comp 	"ACT Composite Scale Score"
	lab var n_act_read 	"ACT # take Reading"
	lab var n_act_math 	"ACT # take Math"
	lab var n_act_comp 	"ACT # take Composite"


**B. Keep and Order
	loc vars schid sch_name network year 	 ///
		act_read n_act_read act_math n_act_math act_comp n_act_comp

	ds `vars', not
	assert "`: word count `r(varlist)''" == 0 // ensure nothing dropped
	keep `vars'
	order `vars'

	compress


**C. Save and quit
	save "${data}/02g_act.dta", replace

	log c


**EOF**
