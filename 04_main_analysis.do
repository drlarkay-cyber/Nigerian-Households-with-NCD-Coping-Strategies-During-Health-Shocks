********************************************************************************
* SECTION 4: MAIN ANALYSIS
* Paper: How Nigerian Households with Non-communicable Diseases Combine Coping Strategies
* During Health Shocks: Evidence from the Nigeria Living Standards Survey (2018-2019)
*
* Author: Adelakun Odunyemi
* Date: December 2025
*
* This code for main analysis:
* 	* ERM (eprobit, eregress & etpoisson)
* 	* Churdle
*	* Regression tables
*	* Coefplot
*	
*
********************************************************************************


* ********************************************************************************
* Analysis 3: Double Hurdle Model- Determinants of Coping Strategy Decisions (ERM)
* ********************************************************************************
* Perform ERM separately for each hurdle
	// The system is triangular (recursive): No simultaneous causation between equations. If theory suggests one endogenous variable affects another (e.g., access to credit influences safety nets), include it in the subequation to enforce recursivity.
	// Errors are multivariate normal, with correlations capturing endogeneity.
	// The endogenous variables are binary, modeled via probit links.
	// No unobserved confounders beyond the modeled correlations.

*-------------------------------------------------------------------------------
* Step 1. Define global exogenous variables
*-------------------------------------------------------------------------------
* Define regressor macros:
	global xlist c.hage##c.hage hsex hmstat i.heduc2 hwork hhsize children ib5.expquint ncd i.cred_access insur assist admins private episode oshock location i.zone
	
	global xlist2 hage hsex hmstat heduc2 hwork hhsize children expquint ncd cred_access insur assist admins private episode oshock location zone elderly remit unmet


	global exog_vars c.hage##c.hage hsex hmstat i.heduc2 hwork hhsize children elderly ib5.expquint ncd admins private episode oshock location i.zone 
	
	global exog_vars2 c.hage##c.hage hsex hmstat i.heduc2 hwork hhsize children ib5.expquint ncd insur assist admins private episode oshock location i.zone
	
* Define the participation indicator (given coping count is positive): 
	gen coping_part = (coping_count > 0)
	
*-------------------------------------------------------------------------------
* Step 2a. First Hurdle (Participation)- Full model
*-------------------------------------------------------------------------------
	eprobit coping_part $exog_vars, ///
    endogenous(insur = $exog_vars, probit) ///
    endogenous(assist = $exog_vars, probit) ///
    endogenous(cred_access = $exog_vars, probit) ///
    vce(cluster ea) nonrtolerance difficult iterate(200)
	
	outreg2 using hurdle_full.docx, label dec(2) ci bracket ///
	addstat(Log likelihood, e(ll), Wald chi2, e(chi2), Prob > chi2, e(p)) replace
	
*-------------------------------------------------------------------------------
* Step 2b. First Hurdle (Participation)- Final model
*-------------------------------------------------------------------------------
	eprobit coping_part $exog_vars2, ///
    endogenous(cred_access = $exog_vars2, probit) ///
    vce(cluster ea) nonrtolerance difficult iterate(200)
	
	outreg2 using hurdle_final.docx, label dec(2) ci bracket ///
	addstat(Log likelihood, e(ll), Wald chi2, e(chi2), Prob > chi2, e(p)) replace
	
*Post-estimations (Calculate meaningful effect sizes)
	margins, dydx(*) post
	outreg2 using hurdle_margins.docx, label dec(2) ci bracket replace
	estimate store part
	
*-------------------------------------------------------------------------------
* Step 3a. Second Hurdle (Count Given Positive)- Full model
*-------------------------------------------------------------------------------
	eregress coping_count $exog_vars if coping_part==1, ///
    endogenous(insur = $exog_vars, probit) ///
    endogenous(assist = $exog_vars, probit) ///
    endogenous(cred_access = $exog_vars, probit) ///
    vce(cluster ea) nonrtolerance difficult iterate(200) 
	
	outreg2 using hurdle_full.docx, label dec(2) ci bracket ///
	addstat(Log likelihood, e(ll), Wald chi2, e(chi2), Prob > chi2, e(p))
	
*-------------------------------------------------------------------------------
* Step 3b. Second Hurdle (Count Given Positive)- Final model
*-------------------------------------------------------------------------------
eregress coping_count $exog_vars2 if coping_part==1, ///
    endogenous(cred_access = $exog_vars2, probit) ///
    vce(cluster ea) nonrtolerance difficult iterate(200)	
	
	outreg2 using hurdle_final.docx, label dec(2) ci bracket ///
	addstat(Log likelihood, e(ll), Wald chi2, e(chi2), Prob > chi2, e(p))
	
etpoisson coping_count $exog_vars2 if coping_part==1, ///
    treat(cred_access = $exog_vars2) ///
    vce(cluster ea) nonrtolerance difficult iterate(200) technique(bhhh 10 nr 5)
	
	outreg2 using hurdle_final.docx, label dec(2) ci bracket ///
	addstat(Log likelihood, e(ll), Wald chi2, e(chi2), Prob > chi2, e(p))
	
*Post-estimations (Calculate meaningful effect sizes)
	estat ic
	margins, dydx(*) post
	outreg2 using hurdle_margins.docx, label dec(2) ci bracket
	estimate store count
	
	
* ************************************************************************************
* Analysis 4: Double Hurdle Model- Determinants of Coping Strategy Decisions (Churdle) 
* ************************************************************************************
	
churdle exponential coping_count $exog_vars2 cred_access, select($exog_vars2 cred_access) ll(0) vce (cluster ea)

outreg2 using hurdle_final.docx, label dec(2) ci bracket ///
	addstat(Log likelihood, e(ll), Pseudo-R-squared, e(r2_p), Wald chi2, e(chi2), Prob > chi2, e(p))

               
	
* Plot the final model (two parts)
coefplot part || count, ///
drop(_cons) ciopts(color(cranberry)) mcolor(cranberry) mfc(white) msize(small) ///
	xline(0, lcolor(emerald) lpattern()) mlabel(cond(@pval<0.01, string(@b,"%9.2f") + "***", ///
cond(@pval<0.05, string(@b,"%9.2f") + "**", ///
cond(@pval<0.1, string(@b,"%9.2f") + "*", ///
string(@b,"%9.2f"))))) scheme(s1mono )

	
etpoisson coping_count $exog_vars2 remit unmet elderly if coping_part==1, ///
    treat(cred_access = $exog_vars2 remit unmet elderly) ///
    vce(cluster ea) nonrtolerance difficult iterate(200) technique(bhhh 10 nr 5)
	estat ic