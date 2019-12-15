********************************************************************************
** 	TITLE: 02d_clean_suspensions.do
**
**	PURPOSE: Clean suspension data from CPS site
**							
**	INPUTS: Misconduct_Report_EOY2018_SchoolLevel.xls
**
**	OUTPUTS: 02d_attendence.dta
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

loc cdate = subinstr("`c(current_date)'"," ", "", .) // remove spaces
log using "${log_path}/02d_clean_discipline_`cdate'.log", replace
di "`cdate'"


*****************************
* 1. Clean Data
*****************************
*A. Load data
*B. Rename
*C. Clean data

**A. Load data
	import excel using "${raw}/Misconduct_Report_EOY${endyear}_SchoolLevel.xls", first clear


**B. Rename and select 
	*rename 
	ren SchoolID 			schid
	ren SchoolName 			sch_name
	ren SchoolNetwork 		network
	ren SchoolYear 			year 
	ren TimePeriod 			semester
	ren ofMisconducts 		n_misconducts
	ren OSSper100Students   oss_p
	ren P 					unique_iss_p				
	ren V 					unique_oss_p
	ren Y 					police_p
	ren AB 					unique_police_p

	/*
		Unused variables below, to clean later if some sort LASSO is used:

		ofMisconductsResultinginaSuspension(includesISSandOSS 
		ofISS 
		ofMisconductsResultinginanISS 
		ISSper100Students	
		ofUniqueStudentsReceivingISS 
		ofUniqueStudentsReceivingISS 
		ofGroup12Misconducts 
		ofGroup34Misconducts 
		ofGroup56Misconducts	
		ofSuspensions(includesISSandOSS) 
		AverageLengthofISS 
		ofOSS 
		ofMisconductsResultinginanOSS	
		OSSper100Students	
		ofUniqueStudentsReceivingOSS 
		ofUniqueStudentsReceivingOSS 
		AverageLengthofOSS 
		ofPoliceNotifications	
		ofMisconductsResultinginaPoliceNotification	
		PoliceNotificationsper100Students	
		ofUniqueStudentsReceivingPoliceNotification	
		ofUniqueStudentsReceivingPoliceNotification	
		ofStudentsExpelled Expulsionsper100Students	
	*/

	*clean school year
	replace year = substr(year, -4, 4)
	destring year, replace
	destring schid, replace


**C. Select Observations
	*Only keep end of year observations
	keep if semester == "EOY"
	drop semester

	drop if year == 2012 // different reporting standards due to Student Code of COnduct change



*****************************
* 2. Save and exit
*****************************
*A. Var amanagement
*B. Keep and order
*C. Save and exit


**A. Var management 
	*Variable labels
	lab var schid 				"School ID, 6 Digit "
	lab var sch_name    		"School Name"
	lab var year 				"Spring School Year"
	lab var network				"CPS Academic Network"
	lab var n_misconducts 		"Number of Student Misconducts"
	lab var oss_p 				"Out-of-School Suspensions per 100"
	lab var unique_iss_p	 	"Percent Unique Students In-school Suspensions"			
	lab var unique_oss_p 		"Percent Unique Students Out-of-school Suspensions"
	lab var police_p 			"Percent of misconducts with police calls"
	lab var unique_police_p 	"Percent Unique Students with police calls"


**B. Keep and Order
	loc vars schid sch_name network year 		 /// IDs
		network n_misconducts oss_p unique_iss_p ///
		unique_oss_p police_p unique_police_p

	ds `vars', not
	assert "`: word count `r(varlist)''" == 0 // ensure nothing dropped
	keep `vars'
	order `vars'

	compress


**C. Save and quit
	save "${data}/02d_discipline.dta", replace

	log c


**EOF**
