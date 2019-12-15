********************************************************************************
** 	TITLE: 02h_clean_attendance.do
**
**	PURPOSE: Clean attendance sheet from CPS site
**							
**	INPUTS: Metrics_Attendance_2018.xls
**
**	OUTPUTS: 02h_attendence.dta
**				
**	NOTES:
**
**	AUTHOR: Michael Rosenbaum	
**
**	CREATED: 9/1/17
********************************************************************************
*Table of Contents
*1. Load and clean data
*2. Save and exit


version 14.2
cap log close
set more off

loc cdate = subinstr("`c(current_date)'"," ", "", .) // remove spaces
log using "${logs}/02h_clean_attendance_`cdate'.log", replace
di "`cdate'"



*****************************
* 1. Load and clean data
*****************************
*A. Load excel
*B. Reshape


**A. Load Excel
	*import excel
	import excel using "${raw}/Metrics_Attendance_2018.xls", first sheet("Attendance Overtime") clear

	*loop through varlist using regular expressions as it is wide
	qui ds
	foreach v in `r(varlist)' {

		*Save excel labeling from import
		loc vlab: var label `v'

		*Match to known pattern
		if regexm("`vlab'", "[0-9]") 		ren `v' y`vlab'
		if regexm("`vlab'", "[Nn]etwork") 	ren `v' network
		if regexm("`vlab'", "School") 		ren `v' sch_name
		
		*Some var management
		if regexm("`vlab'", "[iI][dD]") {
			ren `v' schid
			tostring schid, replace
		}
		// end if regexm("`vlab'", "[iI][dD]")

	}
	// end foreach v in `r(varlist)'

	*Keep only school-wide
	ren Group group
	ren Grade grade
	tab group 
	drop if group == "Grade"
	drop group grade


	*dropmissing obs
	dropmiss, obs force

	*drop CPS subtotal counters
	drop if mi(schid)


**B. Reshape to long
	reshape long y, i(schid) j(year)
	ren y attend_p

	*keep if year
	keep if year >= 2013 & year <= 2018

	destring schid, replace
	drop if mi(schid)



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
	lab var network		"CPS Academic Network"
	lab var attend_p 	"Student attendance Percentage"


**B. Keep and Order
	loc vars schid sch_name network year attend_p

	ds `vars', not
	assert "`: word count `r(varlist)''" == 0 // ensure nothing dropped
	keep `vars'
	order `vars'

	compress


**C. Save and quit
	save "${data}/02h_attendance.dta", replace

	log c


**EOF**
