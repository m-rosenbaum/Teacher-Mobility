********************************************************************************
** 	TITLE: 2b_clean_demos.do
**
**	PURPOSE: Clean achievement scores scraped from CPS' Site
**							
**	INPUTS:	NWEA MAP files
**	
**	OUTPUTS: 2a_demos_13_18
**				
**	NOTES:
**
**	AUTHOR: Michael Rosenbaum	
**
**	CREATED: 9/1/17	
********************************************************************************
*Table of Contents
*1. Load and clean data
*2. Save and Quit 


version 14.2
cap log close
set more off

loc cdate = subinstr("`c(current_date)'"," ", "", .) // remove spaces
log using "${logs}/02a_clean_map_`cdate'.log", replace
di "`cdate'"



***************************************
*1. Import and Clean
***************************************
*A. Import file
*B. Clean data


**A. Import file
	*Load attainment information
	import excel using "${raw}/Assessment_NWEA_SchoolLevel_2018.xls", clear first sheet("Attainment")

	*rename variables
	ren SchoolID 	schid
	ren SchoolName 	sch_name
	ren Network 	network
	ren Subject 	subject
	ren Grade 		grade


**B. Clean data
	*Select only grades that take 
	keep if grade == "Grades 2-8 Combined"

	*Destring subject for wide
	replace subject = "1" if subject == "MATH"
	replace subject = "2" if subject == "READING"
	destring subject, replace

	*Drop duplicates (4 schools have duplicates obs with dif 2016 results)
	set sortseed 4836067 // random.org
	sort schid subject 
	duplicates drop schid subject, force

	*match format
	qui ds rit* gt_50xile* nat_xile* n_take*
	foreach v in `r(varlist)' {
		destring `v', replace
	}

	*reshape to long for years
	reshape long rit gt_50xile nat_xile n_take, i(schid subject) j(year)

	*reshape to wide for math and reading
	ds rit gt_50xile nat_xile n_take
	reshape wide `r(varlist)', i(schid year) j(subject)
	foreach v in rit gt_50xile nat_xile n_take {
		ren `v'1 `v'_math
		ren `v'2 `v'_ela
	}



***************************************
* 2. Save and quit
***************************************
*A. Var management
*B. Keep and order
*C. Save and exit


**A. Varmanagement
	lab var schid 		"School ID, 6 Digit "
	lab var sch_name    "School Name"
	lab var year 		"Spring School Year"
	lab var network 	"CPS Academic Network"
	foreach v in ela math {
		lab var rit_`v' 		"MAP Scale Score, `v'"
		lab var gt_50xile_`v' 	"Student % Greater than 50th Percentile on MAP, `v'"
		lab var nat_xile_`v' 	"National Percentile of School Achievement on MAP, `v'"
		lab var n_take_`v' 		"Number of Students who took MAP, `v'"
	}


**B. Keep and order
	loc vars schid sch_name year network /// ID vars
		rit* gt_50xile* nat_xile* n_take* // MAP Vars

	ds `vars', not
	assert "`: word count `r(varlist)''" == 0 // ensure nothing dropped
	keep `vars'
	order `vars'

	*Compress data
	compress


**C. Save and exit
	save "${data}/02b_assessment_map.dta"


**EOF**
