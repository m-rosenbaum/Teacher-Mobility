*******************************************************************************
** 	TITLE:		00_master.do
**
**	PURPOSE: 	Run .do files for BA Thesis Update 
**
**	NOTES:		-Requires R 3.6.1
**				-Requires Stata 15.1
**				- This was originally my BA Thesis that used a Dif-in-Dif to
**				estimate this, but did not have parallel pre-trends. I update
**				these data as a code sample. These data should be cleaned
**				more thoroughly, especially in the fuzzy merge across the 
**				employment panel, if this is to be used for any sort of analysis.
**
**	AUTHOR:		Michael Rosenbaum
**
**	CREATED:	11/23/18
*******************************************************************************
*Table of Contents:
*1. Insheet
*2. Clean
*3. Create outcomes
*4. Analysis


clear all
cap log close

version 15.1
set more off
pause on




******************************
*	0. Setting directories and locals
******************************
*A. Working directory
*B. Globals


**A. Working Directory
	*Michael
	if "`c(username)'" == "Michael Rosenbaum" {
		gl udir "C:/Users/Michael Rosenbaum/Documents/Coding/Teacher-Mobility"
		gl Rdir "C:/Program Files/R/R-3.6.1/bin/x64/R.exe"
	}
	// end if Michael

	*[Next User]
	else {
		gl udir = subinstr("`c(pwd)'", "\", "/", .)
		gl udir = subinstr("${udir}", "/02_scripts", "")

		*Assume standard location and R 
		gl Rdir "C:/Program Files/R/R-3.6.1/bin/x64/R.exe"
	}
	// end else, new user


**B. Define global locations
	*Define project folder locations
	gl raw			"${udir}/01_raw"
	gl dos 			"${udir}/02_scripts"
	gl ados 		"${udir}/03_programs"
	gl logs 		"${udir}/04_logs"
	gl data 		"${udir}/05_clean"
	gl temp 		"${udir}/06_temp"
	gl tables 		"${udir}/07_tables"
	gl figures 		"${udir}/08_figures"

	*Ensure these exist
	foreach directory in raw dos ados logs data temp tables figures {
		cap mkdir ${`directory'}
		if !_rc di "${`directory'} created"
	}
	// end foreach directory


**C. Add user written programs
    *Load packages to scripts directory for version control
    net set ado "${ados}"
	foreach package in fre sdecode sencode mmerge missings ///
			outreg2 reclink matchit ietoolkit {
	    qui{
	    	loc fldr = substr("`package'",1,1)
			capture confirm file "${ados}/`fldr'/`package'.ado"
			if _rc == 601 ssc install `package'
		}
		// end qui
	}
	// end foreach package

	*Preferentially use packages in ado file for version control
    adopath++ "${ados}"


**D. User control
	*Final year for scraoe
	gl endyear 2018 // Spring year

	*RUn locals
	loc scrape 		0 // 0 or 1
	loc clean 		0 // 0 or 1
	loc outcome 	1 // 0 or 1
	loc analysis 	0 // 0 or 1



***************************************
*	1. Insheeting data
***************************************
*A. Scrape school-level datasets
*B. Scrape 5Es

/*
	Chicago Public Schools public data is stored on the CPS
	website. This can scraped relatively easily. However, data
	is often obfuscated, or has different formats by year.

	In addition, school climate surveys -- 5-Essentials, branded
	My Voice My School (MVMS) -- by CPS are made inaccessible. To
	scrape these survey responses at the school-level, the 5E user
	site needs to be scraped. Unfortunately, there isn't an API to 
	do this in a sane way. I use the legacy portal as R Selenium
	seems to take much longer to navigate the JavaScript version.
*/


**A. Scrape school-level datasets
	// Site format has changed since initial script was written
	// https://cps.edu/SchoolData/Pages/SchoolData.aspx
	// to-do is to update scraping list for new CPS portal.
	// Otherwise all data is in /Raw for now.


**B. Scrape 5Es
	/*
	PURPOSE: Scrapes 5Essentials survey data from the 5E website           
	INPUTS: 
	OUTPUTS: ${raw}/1a_demos_2013_$endyear.csv    
	NOTES: 
	AUTHOR: Michael Rosenbaum 
	*/
* /!\ ATTN /!\
* /!\ Scrape of all schools. Takes ~1 hour to run per year scraped /!\
* /!\ ATTN /!\
	*Check if files exist
	if `scrape' cap confirm file "${raw}/panel_5es_2012_${endyear}.csv"

	*Run shell command
	if _rc & `scrape' {
		! "${rdir}" CMD BATCH "${dos}/01b_scrape5e.R"
		loc scrape_done 0

		*Then check every minute for shell to complete
		loc i = 0 // init empty
		while `scrape_done' == 0 {
			sleep 60000 // 1 minute
			cap confirm file "${raw}/panel_5es_2012_$endyear.csv"
			
			*Display counter
			if _rc {
				loc ++i
				if round(`i'/60) == `i'/60 di "+" // line break every hour
				else di ".", _continue // dots
			}
			// end if _rc

			*Advance local if successful confirmation
			if !_rc {
				loc ++scrape_done
			}
			// end if !_rc

		}
		// end while `scrape_done'

	}
	// end if _rc & `scrape'



***************************************
*	2. Cleaning Dos
***************************************
*A. Clean and merge demos
*B. Clean and assessment
*C. Clean 5Es
*D. Clean discipline
*E. Clean mobility


**A. Clean and merge demos
	/*
	PURPOSE: Clean demographic sheets from CPS Site						
	INPUTS:	Scraped FRL files 2013 - $endyear
			Scraped Race/Ethnicity files 2013 - $endyear
			Scraped Enrollment files 2013 - $endyear
	OUTPUTS: ${raw}//1a_demos_2013_$endyear			
	NOTES: 
	AUTHOR: Michael Rosenbaum	
	*/
	if `clean' do "${dos}/02a_clean_demos.do"


**B. Clean assessment data
	/*
	PURPOSE: Clean achievement scores scraped from CPS' Site							
	INPUTS:	NWEA MAP files
	OUTPUTS: 2a_demos_13_18			
	NOTES:
	AUTHOR: Michael Rosenbaum	
	*/
	if `clean' do "${dos}/02b_clean_map.do"


**C. Clean 5Es
	/*
	PURPOSE: Clean five essentials survey data scraped from 5E site.						
	INPUTS:	Panel_5es_2012_$endyear
	OUTPUTS: 2c_5es.dta			
	NOTES: Raw data scraped by 01b_scrape5e.R
	AUTHOR: Michael Rosenbaum	
	*/
	if `clean' do "${dos}/02c_clean_5es.do"


**D. Clean Discipline
	/*
	PURPOSE: Clean suspension data from CPS site						
	INPUTS: Misconduct_Report_EOY2018_SchoolLevel.xls
	OUTPUTS: 02d_attendence.dta			
	NOTES:
	AUTHOR: Michael Rosenbaum	
	*/
	if `clean' do "${dos}/02d_clean_discipline.do"


**E. Create mobility panel
	/*
	**	PURPOSE: Clean teacher employment info, and create a quarterly employment panel
	**			This fuzzy matches across employment records released each quarter.						
	**	INPUTS:	School Rosters
	**	OUTPUTS: 1e_teach_employ.dta			
	**	NOTES:	-Name formats for schools and teachers changes during this panel.
	**	AUTHOR: Michael Rosenbaum	
	*/
* /!\ ATTN /!\
* /!\ Large fuzzy merge, takes ~20 minutes to run on a laptop per academic year /!\
* /!\ ATTN /!\
	*if `clean' do "${dos}02e_clean_employment.do"


**F. Clean student mobility
	/*
	PURPOSE: Clean student mobility sheet from CPS site					
	INPUTS: Metrics_Mobility_SchoolLevel.xls
	OUTPUTS: 02f_stu_mobility.dta			
	NOTES:
	AUTHOR: Michael Rosenbaum
	*/
	if `clean' do "${dos}/02f_clean_stu_mobility.do"


**G. Clean ACT scores
	/*
	PURPOSE: Clean ACT test data for high schools from website						
	INPUTS: AverageACT_2016_SchoolLevels.xls
	OUTPUTS: 02g_act.dta			
	NOTES:
	AUTHOR: Michael Rosenbaum
	*/
	if `clean' do "${dos}/02g_clean_act.do"


**H. Clean attendance 
	/*
	PURPOSE: Clean student attendance data from CPS site							
	INPUTS: Metrics_Attendance_$endyear.xls
	OUTPUTS: 02h_attendence.dta			
	NOTES:
	AUTHOR: Michael Rosenbaum	
	*/
	if `clean' do "${dos}/02h_clean_attendance.do"



***************************************
* 3. Merge files and create outcomes
***************************************
*A. Merge Raw
*B. Create outcomes


**A. Merge school_level
	/*
	PURPOSE: Merge school level information						
	INPUTS: ${data}/02a_demos_13_18.dta
			${data}/02b_assessment_map.dta
			${data}/02c_5es.dta
			${data}/02d_discipline.dta
			${data}/02f_stu_mobility.dta
			${data}/02h_attendance.dta
	OUTPUTS: 03a_school_level.dta			
	NOTES:
	AUTHOR: Michael Rosenbaum	
	*/
	if `outcome' do "${dos}/03a_merge_school_level.do"


**B. Create outcomes
	/*
	PURPOSE: Merge school level information						
	INPUTS: ${data}/03a_school_level.dta
			${data}/02e_employment_panel.dta
	OUTPUTS: ${data}/03b_panel_long.dta
			 ${data}/03b_panel_long.csv			
	NOTES:
	AUTHOR: Michael Rosenbaum	
	*/
	if `outcome' do "${dos}/03b_outcomes_long.do"



***************************************
* 4. Analysis 
***************************************
*A. Balance Tables
*B. Synth


**A. Summary Statistics & Balance
	/*
	PURPOSE: Create balance table for various restricted sample to show sample
			stats and approximate covariate coverage for synthetic control.						
	INPUTS: ${data}3b_panel_long.dta
	OUTPUTS: ${tables}4a_bal_tab.tex			
	NOTES:
	AUTHOR: Michael Rosenbaum
	*/
	if `analysis' do "${dos}/04a_bal_tab.do"


**B. Synthetic Control
	/*
	Purpose: Run synthetic control specification and save figures and tables
	Inputs: 	${clean}03b_panel_long.csv"
	Outputs:	$(figures)sc_all_att.png
				${figures}sc_all_tca.png
				${figures}sc_noaoi_att.png
				$(figures)sc_noaoi_tca.png
	Programmer:  Michael Rosenbaum
	*/
	if `analysis' {
		! "${rdir}" CMD BATCH "${dos}/04b_scrape5e.R"
	}


**EOF**
