********************************************************************************
* SECTION 1: DATA CLEANING
* Paper: How Nigerian Households with Non-communicable Diseases Combine Coping Strategies
* During Health Shocks: Evidence from the Nigeria Living Standards Survey (2018-2019)
*
* Author: Adelakun Odunyemi
* Date: December 2025
*
* This code cleans and merges relevant NLSS files
*
********************************************************************************


* ***********************************************************************
* INDIVIDUAL-LEVEL DATA
* ***********************************************************************

* ***********************************************************************
* Section 1: roster
* ***********************************************************************

*Now Loading sect1_roster:
	use sect1_roster, clear
	
* Reformat HHID
 	format %5.0f hhid

*Retain only needed variables:
	keep hhid indiv s01q02 s01q04a s01q07
	
* Create household head variables:
	recode s01q02 (1=0) (2=1), gen (sex)
	rename s01q04a age
	recode s01q07 (4/7=0) (1/3=1), gen(mstat)
	
*Generate age group variables:
	gen elderly=.
	replace elderly=0 if age <65
	replace elderly=1 if inrange(age,65,.)
	gen children=.
	replace children=0 if !inrange(age,0,14)
	replace children=1 if inrange(age,0,14)
	
*Remove redundant variables
	drop s01q02 s01q07
	
* Label variables
	label def yes_no 0 "No" 1 "Yes"
	label var sex "Gender"
	label def sex 0 "Male" 1 "Female"
	label val sex sex
	label var age "Age in year"
	label var mstat "Marital status"
	label def mstat 0 "Not Married" 1 "Married"
	label val mstat mstat
	label var elderly "> 65 years old"
	label var children "Children 15 years & below"
	label val elderly yes_no
	label val children yes_no
	
*save temp file
	tempfile tempa
	save `tempa'

	
* ***********************************************************************
* Section 2: Education
* ***********************************************************************

*Load sect2_education:
	use sect2_education, clear
	
* Reformat HHID
 	format %5.0f hhid

*Retain only needed variables:
	keep hhid indiv s02q07

*Re-categorise level of education into:
/*
0. No formal education
1. Primary school education
2. Secondary school education
3. Above secondary education
*/
	
	recode s02q07 (0/3 51/52=0) (11/16 61=1) (21/28=2) (31/43 321/424=3), gen(educ)
	
* Remove redundant variables
	drop s02q07

* Label variables
	label var edu "Highest level of education"
	label def edu 0 "None" 1 "Primary" 2 "Secondary" 3 "Tertiary"
	label val edu edu
*save temp file
	tempfile tempb
	save `tempb'


* ***********************************************************************
* Section 3: Health
* ***********************************************************************

*Loading the health dataset:
	use sect3_health, clear
	
* Reformat HHID
 	format %5.0f hhid
 
*Remove variables not needed for our analysis:
	keep hhid indiv s03q06_1 s03q06_2 s03q06_os s03q07a s03q08 s03q09  ///
	s03q10_1 s03q13 s03q19

*Generate NCD variable: 
/* 
NCD LIST
*********
0. Not an NCDs or Injury (communicable, maternal, neonatal and nutritional diseases)- OTHER DIS
1.cardiovascular diseases
2.cancers
3.chronic respiratory diseases (Asthma)
4.diabetes
5.mental disorders
6.neurological disorders(epilepsy, seizure)
7.haemoglobinopathies (sickle cell diseases)
8.sense organ disorders- (eye problem, hearing problem, cataract, glaucoma)
9.kidney diseases
10.gastrointestinal diseases (ulcer, stomach pain)
11.musculoskeletal disorders (neck pain, waist pain, back pain, body pain)
12.dermatological conditions (Skin and subcutaneous diseases)
13. dental diseases (teeth problem)
14.others NCDs (urinary disorders (prostate problem)
*/

*Recode s03q06_1 and s03q06_2:
	recode s03q06_1 (4 10 11 15 16 23 24 25 =1) (22=2) (nonmiss=0)
	recode s03q06_2 (4 10 11 15 16 23 24 25 =1) (22=2) (nonmiss=0)

*Encode s03q06_os:
	encode s03q06_os, gen (s03q06_osc)

*Recode s03q06_osc:
	recode s03q06_osc (6 7 11 26/52 54/63 67/68 72/73 75/77 78/84 ///
	89 97/99 101/102 105 111/114 118/123 129 134 137/139 /// 
	147/148 154/160 162/164 166/167 169/170 173/174 182 184 185  ///
	188/191 193/198 201 204 206/208 210 213/221 223 226/230 233  ///
	238/240 243/247 248/250 252/258 260/266 269 272/274 289/295 298 /// 
	306 309 311 315/318 323 325 327 329 331/341 349 359/375 378/393 /// 
	396 397 399 400 401 402 403/405 407/410 414/438 446/447 450/469 ///
	472/475 484/489 494/495 499/518 520 526/529 533 545/546=1) ///
	(nonmiss=0), gen(s03q06_cat)


*Subtitute for "others" in s03q06_1 and s03q06_2:
	replace s03q06_1= s03q06_cat if s03q06_1==2
	replace s03q06_2= s03q06_cat if s03q06_2==2
*Combine s03q06_1 and s03q06_2:
	egen ncd= anymatch(s03q06_1 s03q06_2), value(1)
	replace ncd=. if s03q06_1==. & s03q06_2==.
	
*Generate health utilization variables:
	gen losday= s03q09
	recode s03q10_1 (1=1) (nonmiss=0), gen(unmet)
	recode s03q13 (1/4=0) (5/10=1), gen(private)
	recode s03q19 (2=0), gen(admins)
		
*Remove redundant variables:
	drop s03q06_1 s03q06_2 s03q06_os s03q07a s03q08 s03q09 s03q10_1 s03q13 s03q19 ///
	s03q06_osc s03q06_cat

* Labal variables:
	label var ncd "Someone with NCDs"
	label var losday "Days lost to illness"
	label var unmet "Someone with unmet needs"
	label var private "Private health facility"
	label var admins "Hospital admission"
	
*save temp file
	tempfile tempc
	save `tempc'

	
* ***********************************************************************
* Section 4a1: Labour
* ***********************************************************************
*Load data:
	use sect4a1_labour, clear
	
* Reformat HHID
 	format %5.0f hhid
	
*Remove variables not needed:
	keep hhid indiv s04aq16
*Recode/rename variable
	recode s04aq16 (2=0), gen (work)
	
*Drop variable
	drop s04aq16
	
*Label variables
	label var work "Working member"
	
*save temp file
	tempfile tempd
	save `tempd'

* ***********************************************************************
* Section 5: Remmitance
* ***********************************************************************

*Load remittance data:
	use sect5_remittances, clear
	
* Reformat HHID
 	format %5.0f hhid
	
*Remove variables not needed:
	keep hhid indiv s05q01e
*Recode/rename variable
	recode s05q01e (2=0), gen (remit)

*Remove redundant variables
	drop s05q01e

*Label variables
	label var remit "Remmitance received"
	
*save temp file
	tempfile tempe
	save `tempe'

***********************************************************************
* Merge individual-level 1 data files
***********************************************************************	

* Merge files from all sections
	foreach s of newlist a b c d e {
		
	merge 1:1 indiv hhid using `temp`s'', nogen
		
	}
	
* ***********************************************************************
* COLLAPSE INDIVIDUAL-LEVEL TO HOUSEHOLD-LEVEL
* ***********************************************************************
* Sort and collapse:
	sort hhid indiv
	collapse (first) age sex mstat educ work ///
	(max) ncd private admins remit elderly children unmet ///
	(sum) losday  ///
	, by(hhid)
	
* Rename household head variables & recode needed variables:
	rename (age sex mstat educ work) (hage hsex hmstat heduc hwork)
	recode ncd admins private remit (.=0)

* Label variables:
	label var hage "Age of household head"
	label var hsex "Female household head"
	label def hsex 0 "Male" 1 "Female"
	label val hsex hsex
	label var hmstat "Married household head"
	label def hmstat 0 "Single" 1 "Married", replace
	label val hmstat hmstat
	label var heduc "Highest education"
	label def heduc 0 "No education" 1 "Primary education" 2 "Secondary education" 3 "Tertiary education",replace
	label val heduc heduc
	label var hwork "Working household head"
	label val hwork yes_no
	label var remit "Received remittance"
	label val remit yes_no
	label var ncd "Member affected by NCDs"
	label def ncd 0 "No one with NCDs" 1 "At least one person with NCDs", replace
	label val ncd ncd
	label var private "Member used private healthcare"
	label val private yes_no
	label var admins "Member with hospital admission"
	label val admins yes_no
	label var elder "Presence of older people > 65 years"
	label var children "Presence of children < 15 years"
	label var losday "Lost days to  illness"
	label var unmet "Member with Unmet needs"	

*Save file
	tempfile tempf
	save `tempf'
	
* ***********************************************************************
* HOUSEHOLD-LEVEL DATA
* ***********************************************************************	

* ***********************************************************************
* Section 4a2 - NHIS
* ***********************************************************************
*Load data:
	use sect4a2_labour, clear
	
* Reformat HHID
 	format 	%5.0f hhid
	
*Remove variables not needed:
	keep hhid s04aq61a

	*Recode/rename variable
	recode s04aq61a (2=0), gen (insur)
	
*Drop redundant variable
	drop s04aq61a
	
*Label variables
	label var insur "Contribution to NHIS"
	label val insur yes_no
	
*Save temp file
	tempfile  tempg
	save  `tempg'
	
* ***********************************************************************
* Section 11b: Credit facility
* ***********************************************************************
* Loan data:
	use sect11a_credit, clear
	
* Remove unnecessary variables:	
	keep hhid s11q01
	
* Reformat HHID
 	format %5.0f hhid
	
*Create access to credit variable:
 recode s11q01 (2=0), gen(cred_access)
 
*Drop redundant variables:
	drop s11q01
 
* Label variables:
	label var cred_access "Access to credit"
	label val cred_access yes_no

*Save temp file
	tempfile temph
	save `temph' 

	
* ***********************************************************************
* Section 12a: Safety Net
* ***********************************************************************
* Loan data:
	use sect12a_safety, clear
	
* Remove unnecessary variables:
	keep hhid s12q01a
	
* Reformat HHID
 	format %5.0f hhid

*Create assistance variable:
 recode s12q01a (2=0), gen(assist)
 
*Drop redundant variables:
	drop s12q01a
 
* Label variables:
	label var assist "Received assistance"
	label def yes_no 1 "YES" 0 "NO"
	label val assist yes_no

*Save temp file
	tempfile tempi
	save `tempi'
	
		
* ***********************************************************************
* Section 16 - Shock
* ***********************************************************************
* Read shock data:
	use	sect16_shocks, clear

* Reformat HHID
	format %5.0f hhid

* Drop variables
	drop sector zone lga ea s16q00 s16q01_os s16q02 s16q05_os

* Rename/recode variables:
	recode s16q01 (2=0)
	
* Genarate/recode shock-related variables:
	gen	hshock1 = (s16q01==1 & shock_cd==1)
	gen	hshock2= (s16q01==1 & shock_cd==3)
	egen hshock= anymatch(hshock1 hshock2), val(1)
	gen	oshock= (s16q01==1 & inlist(shock_cd,2,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20))
	gen	episode1 =s16q03 if hshock1==1
	gen	episode2 =s16q03 if hshock2==1
	egen episode = rowtotal (episode1 episode2)
	rename (s16q04__0 s16q04__1 s16q04__2 s16q04__3 s16q04__4) ///
	(y_2015 y_2016 y_2017 y_2018 y_2019)
	
* Recode coping variables:
	recode s16q05__21 (1/4=1), gen(nothing) // Did nothing
	recode s16q05__16 (1/4=1), gen(saving) // Use of savings
	recode s16q05__8 (1/4=1), gen(borrow) // Borrow from friends & family 
	recode s16q05__14 (1/4=1), gen(redfood) // Reduced food consumption
	recode s16q05__15 (1/4=1), gen(rednonfood) // Reduced non-food consumption
	recode s16q05__7 (1/4=1), gen (inf_ass)
* Genarate coping variables by combination:	
	egen form_ass= anymatch(s16q05__17 s16q05__19), val(1 2 3 4) // Formal & informal assistance from NGOs & government)
	egen loan= anymatch(s16q05__9 s16q05__11 s16q05__12 s16q05__13 s16q05__18), val(1 2 3 4) // Borrow from financial institutions, Credit purchases or delayed payments & advanced sale or payment
	egen work_add= anymatch (s16q05__6 s16q05__10), val(1 2 3 4) // Living conditions adjustment (additional income-generating activities, migration for work)
	egen child_disp= anymatch(s16q05__4 s16q05__5), val(1 2 3 4) //Withrawal of children from school or sent to live with friends or family
	egen sale= anymatch(s16q05__1 s16q05__2 s16q05__3), val(1 2 3 4) // Sale of assests

* Drop unnecessary variables
	drop shock_cd s16q01 s16q03 s16q05__* hshock1 hshock2 episode1 episode2
	
* Re-order variables:
	order hhid hshock oshock episode y_* nothing saving inf_ass form_ass ///
	work_add borrow loan redfood rednonfood child_disp sale
	
* Collapse to single household level
	sort hhid
	collapse (max) hshock-sale , by(hhid)
	//assume NO for missing cases
	recode hshock-sale (.=0)
	recode y_* (.a=0)
	

* Rename & label variables:
	label var y_2015 "Year shock occurred: 2015"
	label var y_2016 "Year shock occurred: 2016"
	label var y_2017 "Year shock occurred: 2017"
	label var y_2018 "Year shock occurred: 2018"
	label var y_2019 "Year shock occurred: 2019"
	label var episode "Number of shock episodes"
	label var hshock "Any health shock"
	label var oshock "Other shocks"
	label var nothing "Used no coping strategy"
	label var inf_ass "Received informal assistance"
	label var form_ass "Received formal assistance"
	label var work_add "Engaged in additional work"
	label var redfood "Reduced food consumption"
	label var rednonfood "Reduced non-food consumption"
	label var saving "Financed from savings"
	label var borrow "Borrowing from family & friends"
	label var loan "Collected loan or used credit"
	label var sale "Sold valuable assests"
	label var child_disp "Withdrew children from school or home"
	label def yes_no 0 "NO" 1 "YES", replace
	label val hshock oshock yes_no
	label val nothing-sale yes_no
	
*Save temp file
	tempfile tempj
	save `tempj'	
	
* ***********************************************************************
* Consumption Aggregate
* ***********************************************************************

* Load consumption data:
	use totcons, clear
	
*Remove unnecessary variables:
	keep sector zone state ea hhid hhsize totcons_pc wt_final
	
* Reformat HHID
 	format 	%5.0f hhid

* Rename/recode variables
	rename totcons_pc cons
	rename wt_final wt
	
*Recode location:
	recode sector (1=0) (2=1), gen(location)

* Re-order variables:
	order hhid location zone state ea hhsize cons wt
	

* Save temp file
	tempfile tempk
	save `tempk'

* Combine all household data:
foreach s of newlist f g h i j k {
		
		merge 1:1 hhid using `temp`s'', nogen
		
	}
	
* Drop unnecessary variables:
	drop sector
	drop if cons==.
	
* Label variables:
	label var hhid "Household ID"
	label var location "Located in rural area"
	label var zone "Geopolitical zone"
	label var state "State"
	label var ea "Enumeration area"
	label var hhsize "Household size"
	label var cons "Annual consumption per capita (₦)"
	label def zone  1 "North-Central" 2 "North-East" 3 "North-West" 4 "South-East" 5 "South-South" 6 "South-West"
	label val zone zone
	label val location yes_no
	
	
* Re-order variables:
	order hhid zone state ea location hage hsex hmstat heduc hwork hhsize elderly ///
	assist remit insur ncd unmet private admins cred_access ///
	hshock oshock episode y_* cons wt ///
	nothing saving inf_ass form_ass work_add borrow loan ///
	redfood rednonfood child_disp sale  
	
* Save file:
	save	"nlss_cleaned.dta", replace
	