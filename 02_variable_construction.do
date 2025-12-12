* ***********************************************************************
* 						**** ANALYSIS ****                              *
* **********************************************************************
	
* ***********************************************************************
* Preliminary Analysis - Coding of Relevant Variables
* ***********************************************************************
* Subset to households affected by health shocks
	keep if hshock==1
********************************************************************************
* SECTION 2: VARIABLE CONSTRUCTION
* Paper: How Nigerian Households with Non-communicable Diseases Combine Coping Strategies
* During Health Shocks: Evidence from the Nigeria Living Standards Survey (2018-2019)
*
* Author: Adelakun Odunyemi
* Date: December 2025
*
* This code creates other required variables for analysis
*
********************************************************************************


* Declare survey design:
    *svyset [pweight=wt], strata(state) psu(ea)

* Genarate square of household head age
	gen hage2=hage^2
	
* Generate socioeconomic income group:
	xtile expquint = cons [pw= wt], nq(5)

* Generate coping_count of coping strategies (the number of coping strategies adopted)	
	egen assistance= anymatch(inf_ass form_ass), val(1)
	egen redconsum= anymatch(redfood rednonfood), val(1)
	egen borrowing= anymatch(loan borrow), val(1)
	egen coping_count= rowtotal(saving inf_ass form_ass work_add borrow loan redfood rednonfood child_disp sale), missing // Number of active coping strategies (excludes those reporting "Doing nothing")
	recode coping_count (2/max=2), gen(coping_count_grp)
	egen distress=  rowtotal(borrow loan sale)
	
* Imput values for missing education values for variables, using median value:
	clonevar heduc2=heduc
	egen median_heduc = median(heduc), by()
	replace heduc2 = median_heduc if missing(heduc2)
	drop median_heduc
	
*Label variables
	label var hage2 "Age of household head squared"
	label var expquint "Expenditure quintile"
	label define expquint 1 "Poorest expenditure quintile" 2 "Poor expenditure quintile" 3 "Middle expenditure quintile" 4 "Rich expenditure quintile" 5 "Richest expenditure quintile", replace
	label values expquint expquint
	label var coping_count "Active coping strategy combinations" 
	label var coping_count_grp "Active coping strategy combination groups"
	label var assistance "Received formal or informal assistance"
	label var redconsum "Reduced food & non-food consumption"
	label val assistance redconsum borrowing yes_no
	label def coping_count_grp 0 "No active strategy" 1 "Only one strategy" 2 "More than one strategy", replace
	label val coping_count_grp coping_count_grp
	
	
* Save files
	save "nlss_analysis_ready.dta", replace
	
	