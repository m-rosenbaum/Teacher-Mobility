********************************************************************************
** 	TITLE: 02f_clean_stu_mobility.do
**
**	PURPOSE: Clean student mobility sheet from CPS site
**							
**	INPUTS: Metrics_Mobility_SchoolLevel.xls
**
**	OUTPUTS: 02f_stu_mobility.dta
**				
**	NOTES:
**
**	AUTHOR: Michael Rosenbaum	
**
**	CREATED: 9/1/17
********************************************************************************
*Table of Contents
*1. Load and clean data
*2. Run Regressions 


version 14.2
cap log close
set more off

loc cdate = subinstr("`c(current_date)'", " ", "", .) // remove spaces
log using "${logs}/02f_clean_stu_mobility_`cdate'.log", replace
di "`cdate'"



*****************************
* 1. Load and clean data
*****************************
*A. Load excel
*B. Reshape


**A. Load Excel
	*import excel
	import excel using "${raw}/Metrics_Mobility_SchoolLevel.xls", first clear

	*Rename through regular expressions as this data is wide in a single sheet
	qui ds
	foreach v in `r(varlist)' {

		*Match to variable label from excel import
		loc vlab: var label `v'

		*Save schoolname
		if regexm("`vlab'", "School") ren `v' sch_name
		if regexm("`vlab'", "[0-9]") ren `v' y`vlab'

		*Some data modification for school ID
		else if regexm("`vlab'", "[iI][dD]") {
			ren `v' schid
			tostring schid, replace
		}
		// end else if regexm("`vlab'", "[iI][dD]")

	}
	// end foreach v in `r(varlist)'

	*dropmissing obs
	dropmiss, obs force

	*drop CPS subtotal counters
	drop if mi(schid)

	*Destring all
	qui ds y*
	foreach v in `r(varlist)' {
		destring `v', replace
	}


**B. Reshape long
	reshape long y, i(schid) j(year)
	ren y stu_mob_p

	*keep if year
	keep if year >= 2013 & year <= $endyear
	
	*Fix schid
	drop if !regexm(schid, "[0-9]")
	destring schid, replace



*****************************
* 2. Save and exit
*****************************
*A. Var amanagement
*B. Keep and order
*C. Save and exit


**A. Var management 
	*Variable labels
	lab var schid 		"School ID, 6 Digit "
	lab var sch_name    "School Name"
	lab var year 		"Spring School Year"
	lab var stu_mob_p 	"Student Mobility Percentage"


**B. Keep and Order
	loc vars schid sch_name year stu_mob_p

	ds `vars', not
	assert "`: word count `r(varlist)''" == 0 // ensure nothing dropped
	keep `vars'
	order `vars'

	compress


**C. Save and quit
	save "${data}/02f_stu_mobility.dta", replace

	log c


**EOF**
