********************************************************************************
* SECTION 5: ROBUSTNESS CHECKS
* Paper: How Nigerian Households with Non-communicable Diseases Combine Coping Strategies
* During Health Shocks: Evidence from the Nigeria Living Standards Survey (2018-2019)
*
* Author: Adelakun Odunyemi
* Date: December 2025
*
* This code for main analysis:
* 	* Multicollinarity (eprobit, eregress & etpoisson)
* 	* Goodness of fit statistics
*	* Alternative count models
*	* Oster's sensitivity analysis
* 	* Weighted models
*	* Multiple imputation (MICE)
*	* Recall-restricted analysis
*
********************************************************************************
	
/*==============================================================================
  ROBUSTNESS CHECKS AND SENSITIVITY ANALYSES
==============================================================================*/

*-------------------------------------------------------------------------------
* Test 1: Collinarity test
*-------------------------------------------------------------------------------
	collin $xlist2
	
*-------------------------------------------------------------------------------
* Test 2: Compare naive models/goodness of fit test (Probit)
*-------------------------------------------------------------------------------
	probit coping_part $exog_vars2 cred_access, vce(cluster ea)
	outreg2 using naive.docx, label dec(2) ci bracket ///
	addstat(Log likelihood, e(ll), Pseudo-R-squared, e(r2_p), Wald chi2, e(chi2), Prob > chi2, e(p)) replace
	estat gof, group(10) table
	estat ic
	
*-------------------------------------------------------------------------------
* Test 3a: Comparing the mean and variance of non-zero counts
*-------------------------------------------------------------------------------
	sum coping_count if coping_part==1, detail
	scalar mean_count = r(mean)
	scalar var_count = r(Var)
	scalar disp_ratio = var_count / mean_count

	display "Mean: " mean_count
	display "Variance: " var_count
	display "Dispersion ratio (Var/Mean): " disp_ratio
// If ratio ≈ 1, Poisson is appropriate; if >1, consider Negative Binomial

*-------------------------------------------------------------------------------
* Test 3b: Pearson Goodness of fit tests from ordinary poisson model
*-------------------------------------------------------------------------------
	poisson coping_count $exog_vars insur assist cred_access if coping_part == 1, vce(cluster ea)
	outreg2 using count_model.docx, label dec(2) ci bracket replace
	outreg2 using naive.docx, label dec(2) ci bracket ///
	addstat(Log likelihood, e(ll), Pseudo-R-squared, e(r2_p), Wald chi2, e(chi2), Prob > chi2, e(p))
	estat gof, pearson  // Pearson χ2 / df ≈ 1 suggests no overdispersion
	predict pearson
	summarize pearson
	estat ic
	
	probit cred_access $exog_vars2 if coping_part==1
predict phat_cred, xb
gen cf_cred = normalden(phat_cred)/normal(phat_cred) if cred_access==1
replace cf_cred = -normalden(phat_cred)/(1-normal(phat_cred)) if cred_access==0
nbreg coping_count $exog_vars2 assist cred_access cf_cred if coping_part==1
estimates store nbreg
etpoisson coping_count $exog_vars2 if coping_part==1, treat(cred_access = $exog_vars2) 
estimates store etpoisson
lrtest nbreg etpoisson

*-------------------------------------------------------------------------------
* Test 3c: Test 3b: Zero-inflated models (ZIP/ZINB)
*-------------------------------------------------------------------------------
* Non-Zero-inflated poisson model 	
	poisson coping_count $exog_vars2 cred_access if coping_part == 1, vce(cluster ea)
	outreg2 using count_model.docx, label dec(2) ci bracket replace
	
* Non-zero-inflated negative binomial model
	nbreg coping_count $exog_vars2 cred_access if coping_part == 1, vce(cluster ea)
	outreg2 using count_model.docx, label dec(2) ci bracket
	
* Zero-inflated poisson (ZIP) model 
	zip coping_count $exog_vars2 cred_access,  inflate($exog_vars2 cred_access) vce(cluster ea) nonrtolerance
	outreg2 using count_model.docx, label dec(2) ci bracket
	estimates store zip_model

* Zero-inflated negative binomial (ZINB) model
	zinb coping_count $exog_vars2 cred_access,  inflate($exog_vars2 cred_access) vce(cluster ea) nonrtolerance
	outreg2 using count_model.docx, label dec(2) ci bracket
	estimates store zinb_model

// Test for overdispersion (alpha parameter)
display "Alpha (overdispersion): " _b[/lnalpha]
display "If alpha ≈ 0, ZIP preferred; if alpha > 0, ZINB
	

*-------------------------------------------------------------------------------
* Test 3c: Comparing all count models (Alternative count model comparison)
*-------------------------------------------------------------------------------
	countfit coping_count $exog_vars2 cred_access, inflate($exog_vars cred_access)	
	
*-------------------------------------------------------------------------------
* Test 4: Oster's sensitivity analysis
*-------------------------------------------------------------------------------
* Run your full outcome regression with all regressors (including  potentially endogenous variables

	reg coping_part $xlist, vce (cluster ea)
	
	local full_r2=1.3 * e(r2)
	
* Run regression with restricted variables (e.g no control)
	reg coping_part assist insur cred_access, vce (cluster ea)
	
	//Then call psacalc separately for each endogenous regressor's coefficient
	
	psacalc delta cred_access, rmax(`full_r2') mcontrol(c.hage##c.hage hsex hmstat i.heduc2 hwork hhsize children elderly ib5.expquint insur assist ncd admins private episode oshock location i.zone)
	
	psacalc delta insur , rmax(`full_r2') mcontrol(c.hage##c.hage hsex hmstat i.heduc2 hwork hhsize children elderly ib5.expquint assist cred_access ncd admins private episode oshock location i.zone)
	
	psacalc delta assist , rmax(`full_r2') mcontrol(c.hage##c.hage hsex hmstat i.heduc2 hwork hhsize children elderly ib5.expquint insur cred_access ncd admins private episode oshock location i.zone)
	
	
	
  bs r(delta), rep(100): psacalc delta cred_access, model(reg coping_count $xlist, vce (cluster ea)) rmax(`full_r2')
 
 bs r(delta), rep(100): psacalc delta insur, model(reg coping_count $xlist, vce (cluster ea)) rmax(`full_r2')
 
 bs r(delta), rep(100): psacalc delta assist, model(reg coping_count $xlist, vce (cluster ea)) rmax(`full_r2')
 
*-------------------------------------------------------------------------------
* Test 5: Weighted Models
*-------------------------------------------------------------------------------
* First Hurdle ERM: Weighted
eprobit coping_part $exog_vars2 [pw=wt], ///
    endogenous(cred_access = $exog_vars2, probit) ///
    vce(cluster ea) nonrtolerance difficult iterate(200)
	
	outreg2 using hurdle_final_wt.docx, label dec(2) ci bracket ///
	addstat(Log likelihood, e(ll), Wald chi2, e(chi2), Prob > chi2, e(p)) replace

* Second Hurdle ERM: Weighted
etpoisson coping_count $exog_vars2 if coping_part==1 [pw=wt], ///
    treat(cred_access = $exog_vars2) ///
    vce(cluster ea) nonrtolerance difficult iterate(200) technique(bhhh 10 nr 5)
	
	outreg2 using hurdle_final_wt.docx, label dec(2) ci bracket ///
	addstat(Log likelihood, e(ll), Wald chi2, e(chi2), Prob > chi2, e(p))

*-------------------------------------------------------------------------------
* Test 6: Multiple Imputation (MICE)
*-------------------------------------------------------------------------------	

* Examine missing data patterns

	misstable summarize hage hsex hmstat heduc hwork hhsize children expquint ncd cred_access insur assist admins private episode oshock location zone

	misstable patterns heduc, freq

* Generate imputation identifier
	mi set mlong
	mi register imputed heduc
* Add other variables with missing data if needed

* Impute using chained equations (MICE)
	mi impute chained ///
    (ologit) heduc = ///
    hage hsex hmstat hwork hhsize children ib5.expquint ncd cred_access ///
	insur assist admins private episode oshock location i.zone, ///
    add(20) rseed(12345) augment

// Check imputation diagnostics
mi describe
mi varying

*-------------------------------------------------------------------------------
* 3c. Run models on imputed data
*-------------------------------------------------------------------------------
// Note: ERM commands may not work directly with mi
// We use standard probit/poisson for comparison

* Participation model on imputed data
	asdoc mi estimate, dots: probit coping_part hage hsex hmstat i.heduc hwork hhsize ///
	children ib5.expquint ncd cred_access insur assist admins private ///
	episode oshock location i.zone, ///
	vce(cluster ea) dec(2) label stars bracket save(mice.doc) replace

estimates store mi_part

* Count model on imputed data (positive counts only)
	asdoc mi estimate, dots: poisson coping_count hage hsex hmstat i.heduc hwork hhsize ///
	children ib5.expquint ncd cred_access insur assist admins private ///
	episode oshock location i.zone if coping_count>0, ///
    vce(cluster ea) dec(2) label stars bracket save(mice.doc)
	

estimates store mi_count

*-------------------------------------------------------------------------------
* 3d. Compare MICE results with median imputation
*-------------------------------------------------------------------------------
// Restore original data with median imputation
mi extract 0, clear

// Run original models (as in main analysis)
probit coping_part coping_part hage hsex hmstat i.heduc hwork hhsize ///
	children ib5.expquint ncd cred_access insur assist admins private ///
	episode oshock location i.zone, ///
	vce(cluster ea),

estimates store median_part

poisson coping_count hage hsex hmstat i.heduc hwork hhsize ///
	children ib5.expquint ncd cred_access insur assist admins private ///
	episode oshock location i.zone if coping_count>0, ///
	vce(cluster ea)

estimates store median_count


/*==============================================================================
  4. RECALL-RESTRICTED ANALYSIS
==============================================================================*/
* First Hurdle ERM: Weighted
	eprobit coping_part $exog_vars2 if y_2018==1 | y_2019==1, ///
    endogenous(cred_access = $exog_vars2, probit) ///
    vce(cluster ea) nonrtolerance difficult iterate(200)
	
	outreg2 using hurdle_restict.docx, label dec(2) ci bracket ///
	addstat(Log likelihood, e(ll), Wald  chi2, e(chi2), Prob > chi2, e(p)) replace

* Second Hurdle ERM: Weighted
	etpoisson coping_count $exog_vars2 if coping_part==1 & y_2018==1 | y_2019==1, ///
    treat(cred_access = $exog_vars2) ///
    vce(cluster ea) nonrtolerance difficult iterate(200) technique(bhhh 10 nr 5)
	
	outreg2 using hurdle_restict.docx, label dec(2) ci bracket 
	
