********************************************************************************
* SECTION 3: DESCRIPTIVE ANALYSIS
* Paper: How Nigerian Households with Non-communicable Diseases Combine Coping Strategies
* During Health Shocks: Evidence from the Nigeria Living Standards Survey (2018-2019)
*
* Author: Adelakun Odunyemi
* Date: December 2025
*
* This code creates Table 1 and other descriptive analysis
*
********************************************************************************


* ***********************************************************************
* Analysis 1 - Descriptive Statistic (Table 1)
* ***********************************************************************

	dtable hage i.hsex i.hmstat i.heduc i.hwork hhsize i.children i.elderly i.insur i.assist i.remit losday i.cred_access i.ncd i.admins i.unmet i.private i.expquint i.location i.coping_count_grp episode, nformat(%9.2f) export(table_1.docx, replace) //by(coping_count_grp, tests nototal)//Regress is equivalent to a one-way ANOVA or a pooled t-test
	dtable i.coping_count, by(ncd, tests total) nformat(%9.2f) export(table_2.docx, replace)

	
* Coping strategy count by NCD Status
	proportion coping_count, over(ncd)