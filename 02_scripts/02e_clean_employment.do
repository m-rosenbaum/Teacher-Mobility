********************************************************************************
** 	TITLE: 1e_clean_employment.do
**
**	PURPOSE: Clean teacher employment info, and create a quarterly employment panel
**			This fuzzy matches across employment records released each quarter.
**							
**	INPUTS:	School Rosters
**	
**	OUTPUTS: 1e_teach_employ.dta
**				
**	NOTES:	-Name formats for schools and teachers changes during this panel.
**
**	AUTHOR: Michael Rosenbaum	
**
**	CREATED: 9/1/17
********************************************************************************
*Table of Contents
*1. Import clean and appennd
*2. Merge on files sequestially

/*
to-do: 9/20/2017
	-Replace individual string cleaning for the fuzzy merge into
	an excel file to merge onto the results of the string cleaning
	-try to find an unqiuely identified ISBE record
to-do: 12/17/2019
	-try matchit or Ambramitzky/Boustan/Eriksson ML-based linking
	for match across CPS record format change
*/

version 14.2
cap log close
set more off

loc cdate = subinstr("`c(current_date)'"," ", "", .) // remove spaces
log using "${log_path}/02e_clean_employment_`cdate'.log", replace


*****************************
* 1. Import clean and appennd
*****************************
*A. Import and clean files
*B. Sequentially Merge files

**A. Create school name dataset
	use "${data}/1a_demos_13_18.dta", clear
	gen msch_name = sch_name
	keep schid sch_name msch_name year
		replace msch_name = subinstr(msch_name, " MIDDLE", "", .)
		replace msch_name = subinstr(msch_name, " HIGH", "", .)	
		replace msch_name = subinstr(msch_name, " SCHOOL", "", .)
		replace msch_name = subinstr(msch_name, " ELEMENTARY", "", .)
		*replace msch_name = subinstr(msch_name, " ACADEMY", "", .)
		replace msch_name = subinstr(msch_name, " HS", "", .)
		replace msch_name = subinstr(msch_name, " ES", "", .)
		replace msch_name = subinstr(msch_name, "(", "",.)
		replace msch_name = subinstr(msch_name, ")", "",.)
		replace msch_name = strtrim(msch_name)
	duplicates drop msch_name year, force
	drop if regexm(schid, "^[4]")
	sort msch_name year 
	ren sch_name demo_sch_name
	gen rsch_id = _n
	isid rsch_id
	save "${temp}/schid_name_xwalk.dta", replace


**B. Sequentially merge files
	/*
		CPS releases data using two file formats for employment records.

		This format change takes place between December 31, 2015 and March 31,
		2016. This causes a number of difficulties in cleaning, but this is
		primarily an issue for the fuzzy match as CPS also updated the way
		names are stored during that time period. Due to this the match rate
		during that school year is substantially less. For the purpose of this
		estimate, the 12/31/15 - 03/31/2016 quarter is not used for any retention
		outcomes.
	*/
	*Create filename locals
	loc filename1 09302018 06302018 03312018 12312017 09302017 ///
		06302017 03312017 12312016 09302016 06302016 03312016 
	loc filename2 12312015 09302015 06302015 03312015 12302014 ///
		09302014 06302014 03312014 12312013 10282013

	*set sort seed for drops
	set sortseed 3298358 // random.org 0-9999999

	*Import and save temp files pattern 1
	loc i = 100000
	foreach f of loc filename1 {

		*Import rosters by date
		import excel using "${raw}/EmployeePositionRoster_`f'.xls", first clear
		
		ren Pos 				posid
		ren DeptID 				dept_id
		ren Department 			sch_name
		ren FTE 				fte_p
		ren ClsIndc				classroom_indicator
		ren AnnualSalary		salary
		ren FTEAnnualSalary		salary_fte
		ren AnnualBenefitCost	benefit_cost
		ren JobCode				jobcode
		ren JobTitle			title
		ren Name				t_name

		*dropmissings
		keep posid dept_id fte_p sch_name salary salary_fte benefit_cost ///
			jobcode title t_name classroom_indicator
		dropmiss, force
		dropmiss, obs force

		*date
		gen pull_date = date("`f'","MDY")
		format pull_date %td
		tab pull_date

		*drop empty positions
		drop if mi(t_name)

		*create spring year variable
		gen year = year(pull_date)
			replace year = year + 1 if month(pull_date) == 09
			replace year = year + 1 if month(pull_date) == 12
			replace year = year + 1 if month(pull_date) == 10

		*Select teachers and principals
		keep if regexm(title, "[tT][eE][aA][cC][hH][eE][rR]") | ///
			regexm(title, "[pP][rR][iI][nN][cC][iI][pP][aA][lL]") | ///
			regexm(title, "[cC][lL][aA][sS][sS][rR][oO][oO][mM] [aA][sS][sS][iI][sS][tT]")

		*clean for merge
		/* Unfortunately, common parts of names can make school names non-unique. 
			(ex. Voise Academy & Voise HS). Clean anyway and do some manual replacements
			from the raw data after the fuzzy match
		*/
		replace sch_name = strupper(sch_name)
		
		gen msch_name = sch_name
			replace msch_name = subinstr(msch_name, " MIDDLE", "", .)
			replace msch_name = subinstr(msch_name, " HIGH", "", .)	
			replace msch_name = subinstr(msch_name, " SCHOOL", "", .)
			replace msch_name = subinstr(msch_name, " ELEMENTARY", "", .)
			replace msch_name = subinstr(msch_name, " HS", "", .)
			replace msch_name = subinstr(msch_name, " ES", "", .)
			replace msch_name = subinstr(msch_name, "(", "",.)
			replace msch_name = subinstr(msch_name, ")", "",.)
			replace msch_name = strtrim(msch_name)
		gen rec_id = _n
		
		preserve 

			*keep one var
			egen tag = tag(msch_name)
			keep if tag
			drop tag

			*Fuzzy Match
			reclink msch_name year using "${temp}/schid_name_xwalk.dta", idmaster(rec_id) idusing(rsch_id) gen(matchscore) required(year)
			gen rkeep = (matchscore >= .90 & !mi(matchscore))

			if `f' == 09302018 | `f' == 06302018 | `f' == 03312018 | `f' == 12312017 {
				
				*Corrections
				replace schid = "610174" if msch_name == "JAMES SHIELDS ELEM"
				replace schid = "610183" if msch_name == "HERBERT SPENCER MATH & SCI ACA"
				replace schid = "609839" if msch_name == "CHARLES CARROLL"
				replace schid = "609678" if msch_name == "WILLIAM JONES ACADEMIC MAG"				
				replace schid = "610003" if msch_name == "PAUL CUFFE"
				replace schid = "610188" if msch_name == "EDWARD F DUNNE"

				*Manual match
				replace schid = "609737" if sch_name == "FREDERICK W VN STEUBN MT SC CT"				
				replace schid = "609694" if sch_name == "HANCOCK HIGH SCHOOL"				
				replace schid = "609711" if sch_name == "HARPER HIGH SCHOOL"							
				replace schid = "609751" if sch_name == "KING SELECTIVE ENROLLMENT HS"
				replace schid = "609730" if sch_name == "SENN METRO ACD OF LIB ARTS/TEC"
				replace schid = "609760" if sch_name == "CARVER MILITARY HIGH SCHOOL"
				replace rkeep = 1 if sch_name == "FREDERICK W VN STEUBN MT SC CT"				
				replace rkeep = 1 if sch_name == "HANCOCK HIGH SCHOOL"				
				replace rkeep = 1 if sch_name == "HARPER HIGH SCHOOL"								
				replace rkeep = 1 if sch_name == "KING SELECTIVE ENROLLMENT HS"
				replace rkeep = 1 if sch_name == "SENN METRO ACD OF LIB ARTS/TEC"						
				replace rkeep = 1 if sch_name == "CARVER MILITARY HIGH SCHOOL"						

				*Below threshold
				replace rkeep = 1 if msch_name == "ANTON DVORAK SPECIALTY ACADEMY"
				replace rkeep = 1 if msch_name == "DAVIS MAGNET"
				replace rkeep = 1 if msch_name == "LAVIZZO"
				replace rkeep = 1 if msch_name == "BOUCHET ACADEMY"
				replace rkeep = 1 if msch_name == "SCHL OF SOCIAL JUSTICE"
			}
			// end if AY2018 + Q1 AY2019

			else if  `f' == 09302017 {

				*Corrections
				replace schid = "610174" if msch_name == "JAMES SHIELDS ELEM"
				replace schid = "610183" if msch_name == "HERBERT SPENCER MATH & SCI ACA"
				replace schid = "609839" if msch_name == "CHARLES CARROLL"
				replace schid = "609678" if msch_name == "WILLIAM JONES ACADEMIC MAG"				
				replace schid = "610003" if msch_name == "PAUL CUFFE"
				replace schid = "610188" if msch_name == "EDWARD F DUNNE"

				*Manual match
				replace schid = "609737" if sch_name == "FREDERICK W VN STEUBN MT SC CT"				
				replace schid = "609694" if sch_name == "HANCOCK HIGH SCHOOL"				
				replace schid = "609711" if sch_name == "HARPER HIGH SCHOOL"							
				replace schid = "609751" if sch_name == "KING SELECTIVE ENROLLMENT HS"
				replace schid = "609730" if sch_name == "SENN METRO ACD OF LIB ARTS/TEC"
				replace schid = "609760" if sch_name == "CARVER MILITARY HIGH SCHOOL"
				replace schid = "610518" if msch_name == "VOISE ACADEMY"
				replace rkeep = 1 if sch_name == "FREDERICK W VN STEUBN MT SC CT"				
				replace rkeep = 1 if sch_name == "HANCOCK HIGH SCHOOL"				
				replace rkeep = 1 if sch_name == "HARPER HIGH SCHOOL"								
				replace rkeep = 1 if sch_name == "KING SELECTIVE ENROLLMENT HS"
				replace rkeep = 1 if sch_name == "SENN METRO ACD OF LIB ARTS/TEC"						
				replace rkeep = 1 if sch_name == "CARVER MILITARY HIGH SCHOOL"
				replace rkeep = 1 if msch_name == "VOISE ACADEMY"						

				*Below threshold
				replace rkeep = 1 if msch_name == "ANTON DVORAK SPECIALTY ACADEMY"
				replace rkeep = 1 if msch_name == "DAVIS MAGNET"
				replace rkeep = 1 if msch_name == "LAVIZZO"
				replace rkeep = 1 if msch_name == "BOUCHET ACADEMY"
				replace rkeep = 1 if msch_name == "SCHL OF SOCIAL JUSTICE"
			}
			// end if Sept. 2017

			else if  `f' == 06302017 | `f' == 03312017 | `f' == 12312016 | `f' == 09302016 {

				*Corrections
				replace schid = "610174" if msch_name == "JAMES SHIELDS ELEM"
				replace schid = "610183" if msch_name == "HERBERT SPENCER MATH & SCI ACA"
				replace schid = "609839" if msch_name == "CHARLES CARROLL"
				replace schid = "609678" if msch_name == "WILLIAM JONES ACADEMIC MAG"				
				replace schid = "610003" if msch_name == "PAUL CUFFE"
				replace schid = "610188" if msch_name == "EDWARD F DUNNE"

				*Manual match
				replace schid = "609737" if sch_name == "FREDERICK W VN STEUBN MT SC CT"				
				replace schid = "609694" if sch_name == "HANCOCK HIGH SCHOOL"				
				replace schid = "609711" if sch_name == "HARPER HIGH SCHOOL"							
				replace schid = "609751" if sch_name == "KING SELECTIVE ENROLLMENT HS"
				replace schid = "609730" if sch_name == "SENN METRO ACD OF LIB ARTS/TEC"
				replace schid = "609760" if sch_name == "CARVER MILITARY HIGH SCHOOL"
				replace schid = "610518" if msch_name == "VOISE ACADEMY"
				replace schid = "610321" if msch_name == "THURGOOD MARSHALL SCHOO"
				replace rkeep = 1 if sch_name == "FREDERICK W VN STEUBN MT SC CT"				
				replace rkeep = 1 if sch_name == "HANCOCK HIGH SCHOOL"				
				replace rkeep = 1 if sch_name == "HARPER HIGH SCHOOL"								
				replace rkeep = 1 if sch_name == "KING SELECTIVE ENROLLMENT HS"
				replace rkeep = 1 if sch_name == "SENN METRO ACD OF LIB ARTS/TEC"						
				replace rkeep = 1 if sch_name == "CARVER MILITARY HIGH SCHOOL"
				replace rkeep = 1 if msch_name == "VOISE ACADEMY"
				replace rkeep = 1 if msch_name == "THURGOOD MARSHALL SCHOO"						

				*Below threshold
				replace rkeep = 1 if msch_name == "ANTON DVORAK SPECIALTY ACADEMY"
				replace rkeep = 1 if msch_name == "DAVIS MAGNET"
				replace rkeep = 1 if msch_name == "LAVIZZO"
				replace rkeep = 1 if msch_name == "BOUCHET ACADEMY"
				replace rkeep = 1 if msch_name == "SCHL OF SOCIAL JUSTICE"
			}
			// end if AY2017

			else if  `f' == 06302016 | `f' == 03312016 {

				*Corrections
				replace schid = "610174" if msch_name == "JAMES SHIELDS ELEM"
				replace schid = "610183" if msch_name == "HERBERT SPENCER MATH & SCI ACA"
				replace schid = "609839" if msch_name == "CHARLES CARROLL"
				replace schid = "609678" if msch_name == "WILLIAM JONES ACADEMIC MAG"				
				replace schid = "610003" if msch_name == "PAUL CUFFE"
				replace schid = "610188" if msch_name == "EDWARD F DUNNE"

				*Manual match
				replace schid = "609737" if sch_name == "FREDERICK W VN STEUBN MT SC CT"				
				replace schid = "609694" if sch_name == "HANCOCK HIGH SCHOOL"				
				replace schid = "609711" if sch_name == "HARPER HIGH SCHOOL"							
				replace schid = "609751" if sch_name == "KING SELECTIVE ENROLLMENT HS"
				replace schid = "609730" if sch_name == "SENN METRO ACD OF LIB ARTS/TEC"
				replace schid = "609760" if sch_name == "CARVER MILITARY HIGH SCHOOL"
				replace schid = "400018" if sch_name == "AUSTIN BUSINESS & ENTREPRENEUR"
				replace schid = "609793" if sch_name == "LILLIAN R NICHOLSON SCH-MTH/SC"
				replace schid = "610075" if sch_name == "MOSES MONTEFIORE SPECIAL SCHOO"
				replace rkeep = 1 if sch_name == "FREDERICK W VN STEUBN MT SC CT"				
				replace rkeep = 1 if sch_name == "HANCOCK HIGH SCHOOL"				
				replace rkeep = 1 if sch_name == "HARPER HIGH SCHOOL"								
				replace rkeep = 1 if sch_name == "KING SELECTIVE ENROLLMENT HS"
				replace rkeep = 1 if sch_name == "SENN METRO ACD OF LIB ARTS/TEC"						
				replace rkeep = 1 if sch_name == "CARVER MILITARY HIGH SCHOOL"
				replace rkeep = 1 if sch_name == "AUSTIN BUSINESS & ENTREPRENEUR"
				replace rkeep = 1 if sch_name == "LILLIAN R NICHOLSON SCH-MTH/SC"
				replace rkeep = 1 if sch_name == "MOSES MONTEFIORE SPECIAL SCHOO"
				

				*Below threshold
				replace rkeep = 1 if msch_name == "ANTON DVORAK SPECIALTY ACADEMY"
				replace rkeep = 1 if msch_name == "DAVIS MAGNET"
				replace rkeep = 1 if msch_name == "LAVIZZO"
				replace rkeep = 1 if msch_name == "BOUCHET ACADEMY"
				replace rkeep = 1 if msch_name == "SCHL OF SOCIAL JUSTICE"
			}
			// end if Q3-Q4 AY2016


			keep if rkeep == 1
			keep msch_name schid demo_sch_name
			duplicates drop msch_name, force // if reclink has exact match it duplicates, which happens in 2018
			save "${temp}/schid_employ_xwalk.dta", replace
		
		restore


**C. Add in school-level information and do data management on the unmerged
		mmerge msch_name using "${temp}/schid_employ_xwalk.dta", t(n:1) 
		tab _merge
		drop if _merge == 2
		drop _merge 

		*remove spacer list
		cap confirm string variable posid
		if !_rc {

			*Remove excel row titles
			drop if !regexm(posid, "[0-9]")
			
			*Storage format fixes
			foreach v in posid dept_id fte_p salary salary_fte benefit_cost jobcode {
				destring `v', replace
			}
			// end if foreach v in posid dept_id fte_p salary salary_fte benefit cost jobcode
		}

		*Create merge variables
		// Some different formats for first name to modify (namely titles)
		gen lname = regexs(1) if regexm(t_name, "([a-zA-Z '\-\.]+)[,]([a-zA-Z '\-\.]+)")
			replace lname = strlower(lname)
			replace lname = strtrim(lname)
			replace lname = subinstr(lname, ".","",.)
		gen fname = regexs(2) if regexm(t_name, "([a-zA-Z '\-\.]+)[,]([a-zA-Z '\-\.]+)")
			replace fname = subinstr(fname, "Mr. ", "", .)
			replace fname = subinstr(fname, "Miss ", "", .)
			replace fname = subinstr(fname, "Ms. ", "", .)
			replace fname = subinstr(fname, "Mrs. ", "", .)
			replace fname = subinstr(fname, "Dr. ", "", .)
			replace fname = subinstr(fname, ".","",.)
			replace fname = strlower(fname)
			replace fname = strtrim(fname)

		* Replace parentheses, which can occur multiple time 
		// no regex to ensure all are replaced
		gen rec_sch_name = subinstr(sch_name, "(", "",.)
		replace rec_sch_name = subinstr(rec_sch_name, ")", "",.)

		*Ensure not missing merge variables
		assert !mi(lname)
		assert !mi(fname)

		keep t_name lname fname schid rec_id msch_name sch_name /// Fuzzy merge
	 	fte_p salary jobcode title 		 					/// teacher chars
		pull_date year  /*schid posid dept_id */
		drop if mi(schid) // drop if missing merge var

		*drop duplicate obs by name // MR: Vast majority are at same school, but take first alphabetical school
		sort t_name sch_name
		duplicates drop fname lname schid, force

		*save tempfile for merge
		save "${temp}/roster_`f'.dta", replace

		loc i = `i' + 100000
	}
	// end foreach f of local filename1


	*Import and save temp files pattern2
	foreach f of loc filename2 {

		if `f' == 10282013 | `f' == 12312013 {
			loc xlsx x
		}

		else {
			loc xlsx
		}

		import excel using "${raw}/EmployeePositionRoster_`f'.xls`xlsx'", first clear
		
		ren POSITIONNUMBER		posid
		ren UNITNUMBER			dept_id
		ren FTE 				fte_p
		ren UNITNAME 			sch_name
		ren ANNUALSALARY		salary
		ren FTEANNUALSALARY		salary_fte
		ren ANNUALBENEFITCOST	benefit_cost
		ren JOBCODE				jobcode
		ren JOBDESCRIPTION		title
		ren EMPLOYEENAME		t_name

		*dropmissings
		keep posid dept_id fte_p sch_name salary salary_fte benefit_cost jobcode title t_name
		dropmiss, force
		dropmiss, obs force

		*date
		gen pull_date = date("`f'","MDY")
		format pull_date %td
		tab pull_date

		*drop empty positions
		drop if mi(t_name)
		drop if t_name == " "

		*create spring year variable
		gen year = year(pull_date)
			replace year = year + 1 if month(pull_date) == 09
			replace year = year + 1 if month(pull_date) == 12
			replace year = year + 1 if month(pull_date) == 10

		*Select teachers and principals
		keep if regexm(title, "[tT][eE][aA][cC][hH][eE][rR]") | ///
			regexm(title, "[pP][rR][iI][nN][cC][iI][pP][aA][lL]") | ///
			regexm(title, "[cC][lL][aA][sS][sS][rR][oO][oO][mM] [aA][sS][sS][iI][sS][tT]")

		*clean fo rmerge
		replace sch_name = strupper(sch_name)
		
		gen msch_name = sch_name
			replace msch_name = subinstr(msch_name, " MIDDLE", "", .)
			replace msch_name = subinstr(msch_name, " HIGH", "", .)	
			replace msch_name = subinstr(msch_name, " SCHOOL", "", .)
			replace msch_name = subinstr(msch_name, " ELEMENTARY", "", .)
			replace msch_name = subinstr(msch_name, " HS", "", .)
			replace msch_name = subinstr(msch_name, " ES", "", .)
			replace msch_name = subinstr(msch_name, "(", "",.)
			replace msch_name = subinstr(msch_name, ")", "",.)
			replace msch_name = strtrim(msch_name)
		gen rec_id = _n
		
		preserve 
			*keep one var
			egen tag = tag(msch_name)
			keep if tag
			drop tag

			reclink msch_name year using "${temp}/schid_name_xwalk.dta", idmaster(rec_id) idusing(rsch_id) gen(matchscore) required(year)
			gen rkeep = (matchscore >= .90 & !mi(matchscore))

			gen file = `f'


			if  `f' == 12312015 | `f' == 09302015 | `f' == 06302015 | `f' == 03312015 {

				*Corrections
				replace schid = "609839" if msch_name == "CHARLES CARROLL"			
				replace schid = "610003" if msch_name == "PAUL CUFFE"
				replace schid = "610188" if msch_name == "EDWARD F DUNNE"
				replace schid = "609676" if msch_name == "DUNBAR VOCATIONAL CAREER ACADEMY"
				replace schid = "609793" if msch_name == "LILLIAN R NICHOLSON SPECIALTY FOR SCIENCE & MATHEM"

				*Manual match				
				replace schid = "609694" if sch_name == "HANCOCK HIGH SCHOOL"				
				replace schid = "609711" if sch_name == "HARPER HIGH SCHOOL"							
				replace schid = "609751" if sch_name == "KING SELECTIVE ENROLLMENT HS"
				replace schid = "609760" if sch_name == "CARVER MILITARY HIGH SCHOOL"
				replace schid = "610383" if sch_name == "SCHOOL OF SOCIAL JUSTICE (AT LITTLE VILLAGE)"
				replace schid = "609730" if sch_name == "SENN METROPOLITAN ACADEMY OF LIBERAL ARTS & TECHNOLOGY"	
				replace schid = "610075" if sch_name == "MOSES MONTEFIORE SPECIAL SCHOOL"
				replace schid = "610208" if sch_name == "LAVIZZO ELEMENTRAY"
				replace schid = "400018" if sch_name == "AUSTIN BUSINESS AND ENTREPRENEURSHIP ACADEMY"	
				replace rkeep = 1 if sch_name == "HANCOCK HIGH SCHOOL"				
				replace rkeep = 1 if sch_name == "HARPER HIGH SCHOOL"								
				replace rkeep = 1 if sch_name == "KING SELECTIVE ENROLLMENT HS"					
				replace rkeep = 1 if sch_name == "CARVER MILITARY HIGH SCHOOL"	
				replace rkeep = 1 if sch_name == "SCHOOL OF SOCIAL JUSTICE (AT LITTLE VILLAGE)"
				replace rkeep = 1 if sch_name == "SENN METROPOLITAN ACADEMY OF LIBERAL ARTS & TECHNOLOGY"	
				replace rkeep = 1 if sch_name == "MOSES MONTEFIORE SPECIAL SCHOOL"
				replace rkeep = 1 if sch_name == "LAVIZZO ELEMENTRAY"
				replace rkeep = 1 if sch_name == "AUSTIN BUSINESS AND ENTREPRENEURSHIP ACADEMY"	

				*Below threshold
				replace rkeep = 1 if msch_name == "BOUCHET ACADEMY"
			}

			else if `f' == 12302014 | `f' == 09302014 {

				*Corrections
				replace schid = "609839" if msch_name == "CHARLES CARROLL"			
				replace schid = "610003" if msch_name == "PAUL CUFFE"
				replace schid = "610188" if msch_name == "EDWARD F DUNNE"
				replace schid = "609676" if msch_name == "DUNBAR VOCATIONAL CAREER ACADEMY"
				replace schid = "609793" if msch_name == "LILLIAN R NICHOLSON SPECIALTY FOR SCIENCE & MATHEM"

				*Manual match				
				replace schid = "609694" if sch_name == "HANCOCK HIGH SCHOOL"				
				replace schid = "609711" if sch_name == "HARPER HIGH SCHOOL"							
				replace schid = "609751" if sch_name == "KING SELECTIVE ENROLLMENT HS"
				replace schid = "609760" if sch_name == "CARVER MILITARY HIGH SCHOOL"
				replace schid = "610383" if sch_name == "SCHOOL OF SOCIAL JUSTICE (AT LITTLE VILLAGE)"
				replace schid = "609730" if sch_name == "SENN METROPOLITAN ACADEMY OF LIBERAL ARTS & TECHNOLOGY"	
				replace schid = "610075" if sch_name == "MOSES MONTEFIORE SPECIAL SCHOOL"
				replace schid = "610208" if sch_name == "LAVIZZO ELEMENTRAY"
				replace schid = "400018" if sch_name == "AUSTIN BUSINESS AND ENTREPRENEURSHIP ACADEMY"	
				replace schid = "609780" if sch_name == "AMES MIDDLE SCHOOL"
				replace rkeep = 1 if sch_name == "HANCOCK HIGH SCHOOL"				
				replace rkeep = 1 if sch_name == "HARPER HIGH SCHOOL"								
				replace rkeep = 1 if sch_name == "KING SELECTIVE ENROLLMENT HS"					
				replace rkeep = 1 if sch_name == "CARVER MILITARY HIGH SCHOOL"	
				replace rkeep = 1 if sch_name == "SCHOOL OF SOCIAL JUSTICE (AT LITTLE VILLAGE)"
				replace rkeep = 1 if sch_name == "SENN METROPOLITAN ACADEMY OF LIBERAL ARTS & TECHNOLOGY"	
				replace rkeep = 1 if sch_name == "MOSES MONTEFIORE SPECIAL SCHOOL"
				replace rkeep = 1 if sch_name == "LAVIZZO ELEMENTRAY"
				replace rkeep = 1 if sch_name == "AUSTIN BUSINESS AND ENTREPRENEURSHIP ACADEMY"	
				replace rkeep = 1 if sch_name == "AMES MIDDLE SCHOOL"

				*Below threshold
				replace rkeep = 1 if msch_name == "BOUCHET ACADEMY"
			}

			else if  `f' == 06302014 | `f' == 03312014 {

				*Corrections
				replace schid = "609839" if msch_name == "CHARLES CARROLL"			
				replace schid = "610003" if msch_name == "PAUL CUFFE"
				replace schid = "610188" if msch_name == "EDWARD F DUNNE"
				replace schid = "609676" if msch_name == "DUNBAR VOCATIONAL CAREER ACADEMY"
				replace schid = "609793" if msch_name == "LILLIAN R NICHOLSON SPECIALTY FOR SCIENCE & MATHEM"

				*Manual match				
				replace schid = "609694" if sch_name == "HANCOCK HIGH SCHOOL"				
				replace schid = "609711" if sch_name == "HARPER HIGH SCHOOL"							
				replace schid = "609751" if sch_name == "KING SELECTIVE ENROLLMENT HS"
				replace schid = "609760" if sch_name == "CARVER MILITARY HIGH SCHOOL"
				replace schid = "610383" if sch_name == "SCHOOL OF SOCIAL JUSTICE (AT LITTLE VILLAGE)"
				replace schid = "609730" if sch_name == "SENN METROPOLITAN ACADEMY OF LIBERAL ARTS & TECHNOLOGY"	
				replace schid = "610075" if sch_name == "MOSES MONTEFIORE SPECIAL SCHOOL"
				replace schid = "610208" if sch_name == "LAVIZZO ELEMENTRAY"
				replace schid = "400018" if sch_name == "AUSTIN BUSINESS AND ENTREPRENEURSHIP ACADEMY"	
				replace schid = "610018" if sch_name == "CANTER MIDDLE SCHOOL"
				replace rkeep = 1 if sch_name == "HANCOCK HIGH SCHOOL"				
				replace rkeep = 1 if sch_name == "HARPER HIGH SCHOOL"								
				replace rkeep = 1 if sch_name == "KING SELECTIVE ENROLLMENT HS"					
				replace rkeep = 1 if sch_name == "CARVER MILITARY HIGH SCHOOL"	
				replace rkeep = 1 if sch_name == "SCHOOL OF SOCIAL JUSTICE (AT LITTLE VILLAGE)"
				replace rkeep = 1 if sch_name == "SENN METROPOLITAN ACADEMY OF LIBERAL ARTS & TECHNOLOGY"	
				replace rkeep = 1 if sch_name == "MOSES MONTEFIORE SPECIAL SCHOOL"
				replace rkeep = 1 if sch_name == "LAVIZZO ELEMENTRAY"
				replace rkeep = 1 if sch_name == "AUSTIN BUSINESS AND ENTREPRENEURSHIP ACADEMY"	
				replace rkeep = 1 if sch_name == "CANTER MIDDLE SCHOOL"

				*Below threshold
				replace rkeep = 1 if msch_name == "BOUCHET ACADEMY"
				replace rkeep = 1 if msch_name == "ANTON DVORAK SPECIALTY ACADEMY"
			}

			else if  `f' == 12312013 {

				*Corrections
				replace schid = "609839" if msch_name == "CHARLES CARROLL"			
				replace schid = "610188" if msch_name == "EDWARD F DUNNE"
				replace schid = "610183" if msch_name == "HERBERT SPENCER MATH & SCI"
				replace schid = "610176" if msch_name == "JOHN D SHOOP S"
				replace schid = "610297" if msch_name == "SOUTH SHORE OF LEAD"
				replace schid = "609740" if msch_name == "WILLIAM H WELLS COMMUNITY"
				replace schid = "609676" if msch_name == "DUNBAR VOCATIONAL CAREER A"

				*Manual match	
				replace schid = "609815" if msch_name == "BOUCHET ACADEMY"			
				replace schid = "609694" if sch_name == "HANCOCK HIGH SCHOOL"				
				replace schid = "609711" if sch_name == "HARPER HIGH SCHOOL"							
				replace schid = "609730" if sch_name == "SENN METROPOLITAN ACADEMY"	
				replace schid = "610075" if sch_name == "MOSES MONTEFIORE SPECIAL SCHOOL"
				replace schid = "610208" if sch_name == "LAVIZZO ELEMENTRAY"
				replace schid = "610254" if sch_name == "ANTON DVORAK SPECIALTY ACA"
				replace schid = "400018" if sch_name == "AUSTIN BUSINESS AND ENTREPR"
				replace schid = "609751" if sch_name == "KING SELECTIVE ENROLLMENT H"
				replace schid = "609793" if sch_name == "LILLIAN R NICHOLSON SPECIALTY"
				replace schid = "610383" if sch_name == "SCHOOL OF SOCIAL JUSTICE"
				replace schid = "610018" if sch_name == "CANTER MIDDLE SCHOOL"
				replace rkeep = 1 if msch_name == "BOUCHET ACADEMY"
				replace rkeep = 1 if sch_name == "HANCOCK HIGH SCHOOL"				
				replace rkeep = 1 if sch_name == "HARPER HIGH SCHOOL"								
				replace rkeep = 1 if sch_name == "SENN METROPOLITAN ACADEMY"	
				replace rkeep = 1 if sch_name == "MOSES MONTEFIORE SPECIAL SCHOOL"
				replace rkeep = 1 if sch_name == "LAVIZZO ELEMENTRAY"
				replace rkeep = 1 if sch_name == "ANTON DVORAK SPECIALTY ACA"
				replace rkeep = 1 if sch_name == "AUSTIN BUSINESS AND ENTREPR"
				replace rkeep = 1 if sch_name == "KING SELECTIVE ENROLLMENT H"
				replace rkeep = 1 if sch_name == "LILLIAN R NICHOLSON SPECIALTY"
				replace rkeep = 1 if sch_name == "SCHOOL OF SOCIAL JUSTICE"
				replace rkeep = 1 if sch_name == "CANTER MIDDLE SCHOOL"

				*Below threshold
				replace rkeep = 1 if msch_name == "CARVER MILITARY"
			}

			else if `f' == 10282013 {

				*Corrections
				replace schid = "609839" if msch_name == "CHARLES CARROLL"			
				replace schid = "610188" if msch_name == "EDWARD F DUNNE"
				replace schid = "610183" if msch_name == "HERBERT SPENCER MATH & SCIENC"
				replace schid = "610297" if msch_name == "SOUTH SHORE OF LEAD"
				replace schid = "609740" if msch_name == "WILLIAM H WELLS COMMUNITY"
				replace schid = "609676" if msch_name == "DUNBAR VOCATIONAL CAREER ACA"
				replace schid = "610003" if msch_name == "PAUL CUFFE"
				replace schid = "610174" if msch_name == "JAMES SCHIELDS SCH"
				replace schid = "610034" if msch_name == "LAWNDALE COMMUNITY ACADEM"
				replace schid = "610385" if msch_name == "MULTICULTURAL ARTS A"

				*Manual match	
				replace schid = "609815" if msch_name == "BOUCHET ACADEMY"			
				replace schid = "609694" if sch_name == "HANCOCK HIGH SCHOOL"				
				replace schid = "609711" if sch_name == "HARPER HIGH SCHOOL"							
				replace schid = "609730" if sch_name == "SENN METROPOLITAN ACADEMY"	
				replace schid = "610075" if sch_name == "MOSES MONTEFIORE SPECIAL SCHOOL"
				replace schid = "610208" if sch_name == "LAVIZZO ELEMENTRAY"
				replace schid = "610254" if sch_name == "ANTON DVORAK SPECIALTY ACADE"
				replace schid = "610018" if sch_name == "CANTER MIDDLE SCHOOL"
				replace schid = "609712" if sch_name == "EMIL G HIRSCH METROPOLITAN HIG"
   				replace schid = "610245" if sch_name == "FREDERICK A DOUGLASS ACADEM"
   				replace schid = "609796" if sch_name == "JEAN BAPTISTE BEAUBIEN SCHOO"
   				replace schid = "609793" if sch_name == "LILLIAN R NICHOLSON SPECIALTY SC" 
   				replace schid = "609783" if sch_name == "NANCY B JEFFERSON ALTERNATIVE S"
   				replace schid = "610383" if sch_name == "SCHOOL OF SOCIAL JUSTICE (AT LITTL"
   				replace schid = "609730" if sch_name == "SENN METROPOLITAN ACADEMY OF"
   				replace schid = "400018" if sch_name == "AUSTIN BUSINESS AND ENTREPREN"
				replace schid = "609751" if sch_name == "KING SELECTIVE ENROLLMENT HS"
				replace rkeep = 1 if msch_name == "BOUCHET ACADEMY"
				replace rkeep = 1 if sch_name == "HANCOCK HIGH SCHOOL"				
				replace rkeep = 1 if sch_name == "HARPER HIGH SCHOOL"								
				replace rkeep = 1 if sch_name == "SENN METROPOLITAN ACADEMY"	
				replace rkeep = 1 if sch_name == "MOSES MONTEFIORE SPECIAL SCHOOL"
				replace rkeep = 1 if sch_name == "LAVIZZO ELEMENTRAY"
				replace rkeep = 1 if sch_name == "ANTON DVORAK SPECIALTY ACADE"
				replace rkeep = 1 if sch_name == "CANTER MIDDLE SCHOOL"
				replace rkeep = 1 if sch_name == "EMIL G HIRSCH METROPOLITAN HIG"
   				replace rkeep = 1 if sch_name == "FREDERICK A DOUGLASS ACADEM"
   				replace rkeep = 1 if sch_name == "JEAN BAPTISTE BEAUBIEN SCHOO"
   				replace rkeep = 1 if sch_name == "LILLIAN R NICHOLSON SPECIALTY SC" 
   				replace rkeep = 1 if sch_name == "NANCY B JEFFERSON ALTERNATIVE S"
   				replace rkeep = 1 if sch_name == "SCHOOL OF SOCIAL JUSTICE (AT LITTL"
   				replace rkeep = 1 if sch_name == "SENN METROPOLITAN ACADEMY OF"
   				replace rkeep = 1 if sch_name == "AUSTIN BUSINESS AND ENTREPREN"
				replace rkeep = 1 if sch_name == "KING SELECTIVE ENROLLMENT HS"


				*Below threshold
				replace rkeep = 1 if msch_name == "CARVER MILITARY"
			}

			keep if rkeep == 1
			keep msch_name schid demo_sch_name
			duplicates drop msch_name, force // if reclink has exact match it duplicates, which happens in 2018
			save "${temp}/schid_employ_xwalk.dta", replace

		restore

		*Merge on school_ids
		mmerge msch_name using "${temp}/schid_employ_xwalk.dta", t(n:1) 
		tab _merge

		drop if _merge == 2
		drop _merge 

		*remove spacer list
		cap confirm string variable posid
		if !_rc	{
			drop if !regexm(posid, "[0-9]")
			foreach v in posid dept_id fte_p salary salary_fte benefit_cost jobcode {
			destring `v', replace
			}
		}

		*string trim name for merge
		gen lname = regexs(1) if regexm(t_name, "([a-zA-Z '\-\.]+)[,]([a-zA-Z '\-\.]+)")
			replace lname = strlower(lname)
			replace lname = strtrim(lname)
			replace lname = subinstr(lname, ".","",.)
		gen fname = regexs(2) if regexm(t_name, "([a-zA-Z '\-\.]+)[,]([a-zA-Z '\-\.]+)")
			replace fname = subinstr(fname, "Mr. ", "", .)
			replace fname = subinstr(fname, "Miss ", "", .)
			replace fname = subinstr(fname, "Ms. ", "", .)
			replace fname = subinstr(fname, "Mrs. ", "", .)
			replace fname = subinstr(fname, "Dr. ", "", .)
			replace fname = subinstr(fname, ".","",.)
			replace fname = strlower(fname)
			replace fname = strtrim(fname)

		assert !mi(lname)
		assert !mi(fname)

		gen rec_sch_name = subinstr(sch_name, "(", "",.)
		replace rec_sch_name = subinstr(rec_sch_name, ")", "",.)

		*drop empty position
		drop if mi(t_name)

		keep t_name lname fname schid rec_id msch_name sch_name /// Fuzzy merge
		 	fte_p salary jobcode title 		 					/// teacher chars
			pull_date year  /*schid posid dept_id */
		drop if mi(schid) // drop those that can't be merged to panel
			
		*drop duplicate obs by name // MR: Vast majority are at same school, but take first alphabetical school
		sort t_name sch_name
		duplicates drop fname lname schid, force

		*save tempfile for merge
		save "${temp}/roster_`f'.dta", replace

		loc i = `i' + 100000
	}
	// end if 


*****************************
* 2. Sequentially merge in rosters
*****************************
*A. Merge in rosters
*B. 
*C.

**A. Merge in rosters
	*Create roster vars from 1st time period
	use "${temp}/roster_10282013.dta", clear
	qui ds fname lname schid, not
	foreach v in `r(varlist)' {
		ren `v' t10282013_`v'
	}

	gen has_10282013 = 1
	gen leave_before_10282013 = 0
	gen join_10282013 = 1


	*Merge on fname lname before format change
	loc mergef1 12312013 03312014 06302014 09302014 12302014 03312015 06302015 ///
		09302015 12312015
	foreach f of loc mergef1 {

		*merge on name
		mmerge fname lname schid using "${temp}/roster_`f'.dta", t(1:1) uname(t`f'_) ///
			ukeep(t_name rec_id msch_name sch_name fte_p salary jobcode title pull_date year)
		gen has_`f' = _merge ==  3
		gen leave_before_`f' = _merge == 1
		gen join_`f' = _merge == 2
		
		*housecleaning
		drop _merge
	}	

**B. Merge acroos 12312016 03312016 due a fuzzy merge
	/* 	To do this merge, I create a second name variable for future merges 
		from the non-matching names that were affected by the CPS format and
		content changes. Therefore, fname_upd lname_upd based off of Ufname 
		Ulname  and loop through the rest of the merges using the Ufname Ulname
		as merge keys.
	*/
	mmerge fname lname schid using "${temp}/roster_03312016.dta", t(1:1) uname(t03312016_) ///
		ukeep(t_name rec_id msch_name sch_name fte_p salary jobcode title pull_date year)	
	
	*Generate merge file
	preserve
		keep if _merge == 3
		save "${temp}/perf_form_change.dta", replace
	restore

	*create unmerged using file to produce useable names 
	preserve 
		keep if _merge == 2
		isid fname lname schid
		keep fname lname schid
		sort fname lname schid
		gen match_rec_id = _n
		save "${temp}/nomatch_form_change.dta", replace
	restore

	*create file of unmatched master
	drop if _merge == 3 | _merge == 2
	drop t03312016_*
	drop _merge
	gen fmatch_id = _n

	*fuzzy merge
	reclink fname lname schid using "${temp}/nomatch_form_change.dta", ///
		idmaster(fmatch_id) idusing(match_rec_id) gen(matchscore) exactstr(schid) req(schid)
	gen keepo = (matchscore >= 0.93 & matchscore <= 1) // .9410 is first that works

	*replace 0s, and drop for appned
	replace Ufname = "" if keepo != 1
	replace Ulname = "" if keepo != 1

	*preserve unmatched using and save 
	preserve
		*keep unmatched and clean vars
		keep if mi(Ufname) | _merge == 1
		drop match_rec_id fmatch_id
		replace _merge = 1

		*generate upd vars for future merges
		gen fname_upd = fname
		gen lname_upd = lname

		save "${temp}/append_nomatch_form_change.dta",replace
	restore
	drop if mi(Ufname) | _merge == 1

	*append on perfect matches to file of successes
	append using "${temp}/perf_form_change.dta"
	erase "${temp}/perf_form_change.dta"
	erase "${temp}/nomatch_form_change.dta"

	*drop relevant variable
	drop _merge matchscore keepo

	*generate vars from fuzzy match to merge 
	gen fname_upd = fname
		replace fname_upd = Ufname if !mi(Ufname)
	gen lname_upd = lname 
		replace lname_upd = Ulname if !mi(Ulname)
	drop Ufname Ulname Uschid

	gsort lname_upd fname_upd schid -fname // keep maximal information
	duplicates drop fname_upd lname_upd schid, force 

	*Merge using merge
	mmerge fname_upd lname_upd schid using "${temp}/roster_03312016.dta", t(1:1) uname(t03312016_) ///
		ukeep(t_name rec_id msch_name sch_name fte_p salary jobcode title pull_date year) umatch(fname lname schid)

	*Check that all match
	assert _merge == 3 | _merge == 2

	*Add on _merge == 1 group
	append using "${temp}/append_nomatch_form_change.dta"
	erase "${temp}/append_nomatch_form_change.dta"

	gen has_03312016 = _merge ==  3
	gen leave_before_03312016 = _merge == 1
	gen join_03312016 = _merge == 2

	duplicates drop // 47 from fuzzy 
	drop _merge


	*merge on fname lname after format change
	loc mergef2 06302016 09302016 12312016 03312017 06302017 ///
		09302017 12312017 03312018 06302018 09302018 
	foreach f of loc mergef2 {

		*merge on name
		mmerge fname_upd lname_upd schid using "${temp}/roster_`f'.dta", t(1:1) uname(t`f'_) ///
			ukeep(t_name rec_id msch_name sch_name fte_p salary jobcode title pull_date year) umatch(fname lname schid)
		gen has_`f' = _merge ==  3
		gen leave_before_`f' = _merge == 1
		gen join_`f' = _merge == 2
		
		*housecleaning
		drop _merge
	}

	*Rename vars for reshape
	loc i = 1
	foreach f in 10282013 `mergef1' 03312016 `mergef2' {
		foreach v in t_name rec_id msch_name sch_name fte_p salary jobcode title pull_date year {
			ren t`f'_`v' `v'`i'
		}

		ren has_`f' has`i' 
		ren leave_before_`f' leave_before`i' 
		ren join_`f' join`i'

		loc ++i
	}



*****************************
* 3. Save exit
*****************************
*A. Var Management
*B. Keep and order
*C. Save and quit


**A. Varlabel
	qui ds fte_p*
	forval i = 1(1)`: word count `r(varlist)'' {
		lab var t_name`i' 		"Teacher name, unformatted, Time `i'"
		lab var rec_id`i' 		"Employment record ID, time `i'"
		lab var msch_name`i' 	"Match Var School Name, time `i'"
		lab var sch_name`i' 	"School name from employment files, time `i'"
		lab var fte_p`i' 		"FTE Percentage of Role, time `i'"
		lab var salary`i' 		"Teacher Salary, time `i'"
		lab var jobcode`i' 		"Teacher job code, time `i'"
		lab var title`i' 		"Teacher title, time `i'"
		lab var pull_date`i' 	"Pull date for time `i'"
		lab var year`i' 		"Spring Year for time `i'"
	}
	lab var fname  	"Cleaned First Name"
	lab var lname  	"Cleaned Last Name"
	lab var schid 	"School ID"


**B. Keep and order
	loc vars ///
		fname lname schid 								/// IDs
		t_name* rec_id* fte_p* salary* jobcode* title* 	///
		pull_date* year*

	ds `vars', not
	assert "`: word count `r(varlist)''" == 0 // ensure nothing dropped
	keep `vars'
	order `vars'

	compress


**C. Save and quit
	save "${data}/02e_employment_panel.dta", replace
	erase "${temp}/schid_name_xwalk.dta"
	erase "${temp}/schid_employ_xwalk.dta"

	log c


**EOF**
