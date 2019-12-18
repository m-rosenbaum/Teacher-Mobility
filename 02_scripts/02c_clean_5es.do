********************************************************************************
** 	TITLE: 2c_clean_5es.do
**
**	PURPOSE: Clean five essentials survey data scraped from 5E site.
**							
**	INPUTS:	Panel_5es_2012_$endyear
**	
**	OUTPUTS: 2c_5es.dta
**				
**	NOTES: Raw data scraped by 1b_
**
**	AUTHOR: Michael Rosenbaum	
**
**	CREATED: 9/1/17
********************************************************************************
*Table of Contents
*1. Load and clean data
*2. Save 


version 14.2
cap log close
set more off

loc cdate = subinstr("`c(current_date)'"," ", "", .) // remove spaces
log using "${logs}/02c_clean_5es_`cdate'.log", replace
di "`cdate'"



*****************************
* 1. Load data
*****************************
*A. Load data


**A. load data
	import delimited using "${raw}/panel_5es_2012_${endyear}.csv", clear varn(1)

	*Remove empty values from R
	qui ds, has(type string)
	foreach v in `r(varlist)' {
		replace `v' == "" if `v' == "NA"
		destring `v', replace
	}

	*Drop empties
	missings dropvars, force
	missings dropobs, force

	*Choose lowerst efle
	sort sid year efle
	duplicates drop sid year, force



*****************************
* 2. Save 
*****************************
*A. Var management
*B. Keep and Order
*C. Save and quit


**A. Variable management
	*rename
	ren sid schid

	*Variable labels
	lab var schid 		"School ID, 6 Digit "
	lab var year 		"Spring School Year"
	lab var ins3 		"5E Subcomponent: Principal Instructional Leadership"
	lab var inf3 		"5E Subcomponent: Teacher Influence"
	lab var pgmc 		"5E Subcomponent: Program Coherence"
	lab var trpr 		"5E Subcomponent: Teacher-Principal Trust"
	lab var colb 		"5E Subcomponent: Collabrative Practice"
	lab var colr 		"5E Subcomponent: Collective Responsibility"
	lab var qpd2 		"5E Subcomponent: Quality Professional Development"
	lab var scmt 		"5E Subcomponent: School Commitment of Peers"
	lab var trte 		"5E Subcomponent: Teacher-Teacher Trust"
	lab var efle_5e 	"5E: Effective Leaders"
	lab var teen_5e 	"5E: Teacher Environment"


**B. Keep and Order
	loc vars schid year 				/// ID vars
		ins3 inf3 pgmc trpr 			/// Principal 5e
		colb colr qpd2 scmt trte 		/// Teacher environ 5e
		efle_5e teen_5e					// 5E scales

	ds `vars', not
	assert `: word count `r(varlist)'' == 0
	keep `vars'
	order `vars'

	*Compress
	compress


**C. Save and quit
	save "${data}/02c_5es.dta", replace


**EOF**	
