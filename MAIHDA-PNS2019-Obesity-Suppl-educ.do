/*******************************************************************************
These are the codes for the supplemental figure 2 and table 2
of the manuscript entitled "Assessing Intersectional Disparities in Obesity 
among Brazilian Adults: A MAIHDA Approach".

Authors: Dr Marcos Fanton, Dr Raquel Canuto, Dr Helena M. Constante

The codes for the main paper and the supplemental figure 1 and table 1 can be 
found on this same github page	
*******************************************************************************/
		
/*******************************************************************************
1 - Preparing the dataset (2019 PNS) 
*******************************************************************************/

/*

// Open the dataset based on the dictionary created
	clear
	infile using ".\2021-11-13-input_Stata_PNS_2019.txt"
	codebook V0001
	** This dataset corresponds to individual and household data and
	** has a total of 293,726 rows

// Prepare the sample weight variables 
	rename *, upper
	gen UF=V0001
	format UF UPA_PNS V00291 V0024 V00292 V00293 // all numeric
	
// Keep only variables important for this manuscript
	keep UF UPA_PNS V00291 V0024 V00292 V00293 V0015 V0025A P005 V0026 ///
	C008 C006 C009 VDF003 VDF004 VDD004A ///
	P00102 P00402 P00103 P00403 ///
	P00104 P00201 P00404 P00405 ///
	W00201 W00101 W00202 W00102
		
// save database
	save ".\pnsPESDOM2019.dta", replace	
*/

	
/*******************************************************************************
2 - Identification and control
*******************************************************************************/

//	Open dataset
	use ".\pnsPESDOM2019.dta",clear 

// 	Label yes/no
	label define noyes 0 "No" 1 "Yes"
	label define yesno 1 "Yes" 2 "No"

// 	gen ID variable
	gen ID=_n
	sum ID // n=293,726
	  
/***************************************	
2.1 - Generate initial filters
***************************************/	
	
// 	Restrict to those who were interviewed
	codebook V0015
	ta V0015 // n=279,382 conducted interviews 
	gen sample=.
	replace sample=1 if V0015==1
	ta sample // n=279,382

// 	Restrict to those who answered the individual questionnaire
	codebook V0025A
	gen selected = V0025A
	recode selected 9=. // NA
	ta selected // n= 94,114 
	drop sample
	gen sample=.
	replace sample=1 if V0015==1 & selected==1
	ta sample // n= 94,114

//	Restrict to those who are not pregnant	
	codebook P005 // 1-Yes, 2-No, 3-Don't know
	drop sample
	gen sample=.
	replace sample=1 if V0015==1 & selected==1 & P005!=1
	ta sample // n= 93,341 

//	Restrict to those who are >=18 years of age and <=65
	codebook C008 
	drop sample
	gen sample=.
	replace sample=1 if V0015==1 & selected==1 & P005!=1 & C008>=18 & C008<=65
	ta sample // n= 76,069 
	
//	Restrict to those with plausible BMI measures (BMI<=15 & BMI>=60)
	* see below
	
/*******************************************************************************
3 - Outcomes
*******************************************************************************/

/***************************************	
3.1 - BMI reported
***************************************/	
	  
//	Imputation mark for self-reported height and/or weight (0-No,1-Yes)
	codebook P00405
	label values P00405 noyes

// Self-reported Height
	
	* Do you know your height? (1-Yes,2=No)
	codebook P00402 
	
	* Self-reported height
	codebook P00403
	codebook P00403 if sample==1 
	gen selfheight=P00403

		count if P00402==2 & selfheight!=. & sample==1 // n=2
		list selfheight P00405 if P00402==2 & selfheight!=. & sample==1
		* Two people didnt know their height, but had values reported
		* P00405 shows that one of the heights (106cm) were imputed
		* We will keep these values
	
		* There is another variable in the dataset called "final"
		* Let's compared this with "selfheight"
		codebook P00404 if sample==1
		count if selfheight==. & P00404==. & sample==1 // 3,017
		count if selfheight!=. & P00404==. & sample==1 // zero
		count if selfheight==. & P00404!=. & sample==1 // 9,801
		count if selfheight!=. & P00404!=. & sample==1 // 63,251
		count if selfheight!=. & P00404!=. & selfheight==P00404 & sample==1 // 63,191
		count if selfheight!=. & P00404!=. & selfheight!=P00404 & sample==1 // 60
		* selfheight will be our main variable, but there are situations in which
		* selfheight is missing and P00404 is not, and situations in
		* which selfheight and P00404 are not missing and have different values
		* Let's check those:

		list selfheight P00404 P00405 if ///
		(selfheight!=. & P00404!=. & selfheight!=P00404 & sample==1)
		count if selfheight!=. & P00404!=. & selfheight!=P00404 & sample==1 & P00405==0
		* Let's compared with the anthropometry measurements
		list selfheight P00404 W00201 W00202 if ///
		(selfheight!=. & P00404!=. & selfheight!=P00404 & sample==1)
		
		listsome selfheight P00404 P00405 W00201 W00202 if ///
		selfheight==. & P00404!=. & sample==1 & W00201!=., max(10) random

		* Let's keep self-reported height (P00403) as the standard, but allow  
		* missing values to be replace to values from P00404
		sum selfheight if sample==1 // before: n=63,251 - mean 165.89 (106-210)
		replace selfheight=P00404 if selfheight==. & P00404!=.
		sum selfheight if sample==1 // after: n=73,052 - mean 165.51 (106-210)
	
// Self-reported Weight
	
	* Do you know your weight? (1-Yes,2=No)
	codebook P00102
	
	* Weight self-reported
	codebook P00103
	codebook P00103 if sample==1
	gen selfweight=P00103
	
		count if P00102==2 & selfweight!=. & sample==1 // n=0

		* There is another variable in the dataset called "final"
		* Let's compared this with "selfweight"
		codebook P00104 if sample==1
		count if selfweight==. & P00104==. & sample==1 // 3,017
		count if selfweight!=. & P00104==. & sample==1 // zero
		count if selfweight==. & P00104!=. & sample==1 // 4,639
		count if selfweight!=. & P00104!=. & sample==1 // 68,413
		count if selfweight!=. & P00104!=. & selfweight==P00104 & sample==1 // 67,822
		count if selfweight!=. & P00104!=. & selfweight!=P00104 & sample==1 //  591
		* selfweight will be our main variable, but there are situations in which
		* selfweight is missing and P00104 is not, and situations in
		* which selfweight and P00104 are not missing and have different values
		* Let's check those:

		listsome selfweight P00104 P00405 if ///
		(selfweight!=. & P00104!=. & selfweight!=P00104 & sample==1), random max(10)
		count if selfweight!=. & P00104!=. & selfweight!=P00104 & sample==1 & P00405==0 // 501
		
		listsome selfweight P00104 P00405 W00101 W00102 if ///
		selfweight==. & P00104!=. & sample==1 & W00101!=., max(10) random

		* Let's keep self-reported weight (P00103) as the standard, but allow  
		* missing values to be replace to values from P00104
		sum selfweight if sample==1 // before: n=68,413 - mean 73.06 (25-190)
		replace selfweight=P00104 if selfweight==. & P00104!=.
		sum selfweight if sample==1 // after: n=72,052 - mean 72.97 (25-190)

//	BMI based on self-reported height and weight
	* Height is in cm	
	gen BMI=selfweight/((selfheight/100)^2)
		replace BMI = round(BMI, 0.01)
		sum BMI	// n=89,954
		
	* check implausible BMI measures (BMI<=15 & BMI>=60)
		twoway (scatter BMI C008) if sample==1, ///
			yline(15 60, lcolor(red)) ///
			ylabel(10(5)70) xlabel (15(5)70) ///
			xtitle("Age in years") ytitle("BMI (kg/m²)") ///
			graphregion(color(white)) plotregion(color(white))	
		
		count if BMI<=15 & BMI!=. & sample==1 // 46
		count if BMI>=60 & BMI!=. & sample==1 // 6
		twoway (scatter selfweight selfheight if sample==1)
		
		twoway ///
		(scatter selfweight selfheight if sample==1 & BMI > 15 & BMI < 60) ///
		(scatter selfweight selfheight if sample==1 & (BMI <= 15 | BMI >= 60), ///
		mcolor(red) msymbol(X))		
		
		list selfweight selfheight if BMI<=15 & BMI!=. & sample==1
		list selfweight selfheight if BMI>=60 & BMI!=. & sample==1
	
//	Restrict to those with plausible BMI measures (BMI<=15 & BMI>=60)
	sum BMI if sample==1
	drop sample
	gen sample=.
	replace sample=1 if V0015==1 & selected==1 & P005!=1 & C008>=18 & C008<=65 & BMI<60 & BMI>15
	ta sample // n= 73,000
		
	// BMI categorical 
	gen BMI_cat=BMI
		replace BMI_cat=0 if BMI!=. & BMI<18.5
		replace BMI_cat=1 if BMI!=. & BMI>=18.5 & BMI<25 
		replace BMI_cat=2 if BMI!=. & BMI>=25 & BMI<30
		replace BMI_cat=3 if BMI!=. & BMI>=30	
		ta BMI_cat
		
	gen obesity=BMI
		recode obesity min/29.99=0 30/max=1
		label values obesity noyes
		ta obesity
		
/*******************************************************************************
4 - Main exploratory variables
*******************************************************************************/

/***************************************	
4.1 - Age
***************************************/

	// Original
	gen age=C008 
	sum age if sample==1
	
	gen agegroups=C008
	recode agegroups min/34=1 35/48=2 49/max=3
	label define agegroups ///
		1 "young" ///
		2 "mid" ///
		3 "older"
	label values agegroups agegroups
	
/***************************************	
4.2 - Sex
***************************************/

	codebook C006
	gen sex=C006
		label define sex ///
			1 "Men" ///
			2 "Women"
		label values sex sex

/***************************************	
4.3 - Race
***************************************/

	// Original
	ta C009
	gen race_all=C009
		recode race_all 1=1 2=2 3=3 4=4 5=5 9=. // Ignored for 5 individuals
		label define race_all /// 
			1 "White" /// 
			2 "Black" /// 
			3 "Yellow" /// 
			4 "Brown" /// 
			5 "Indigenous" 
		label values race_all race_all

	// Categorisation 
	gen race=C009
		recode race 1=1 2=3 3=. 4=2 5=. 9=.
		label define race ///
			1 "White" ///
			2 "Brown" ///
			3 "Black" 
		label values race race

/***************************************	
4.4 - Household income per capita (excluding the income of persons whose 
condition in the household was a pensioner, housekeeper or relative of the 
housekeeper)	
* Minimum wage in 2019 - R$ 998,00
***************************************/

	// Original
	codebook VDF003
	gen income=VDF003
					
	// Minimum wage 2019 (R$998.00)
	*Ilow - 0 to 1 MW - <=998
	*Imid - 1 to 3 MW - >998 to <=2994
	*Ihigh - 3 or more MW - >2994
	
	display 3*998
	
	gen wage=VDF003
		recode wage min/998=1 999/2994=2 2995/max=3
		ta wage if sample==1
			label define wage ///
			1 "Ilow" ///
			2 "Imid" ///
			3 "Ihigh" 
		label values wage wage

/***************************************	
4.5 - Highest level of education achieved (ages 5 and over) standardized for 
Elementary School - 9 YEARS SYSTEM
***************************************/

// 	Original
	codebook VDD004A
	gen educ_original=VDD004A
		label define educ_original ///
			1 "Without education" ///
			2 "Incomplete elementary school or equivalent" ///
			3 "Complete elementary school or equivalent" ///
			4 "Incomplete high school or equivalent" ///
			5 "Complete high school or equivalent" ///
			6 "Incomplete higher education or equivalent" ///
			7 "Complete higher education"
		label values educ_original educ_original
	
	// Categorisation 
	gen educ=VDD004A
		recode educ 1/2=1 3/5=2 6/7=3
		label define educ ///
			1 "Elow" ///
			2 "Emid" ///
			3 "Ehigh" 
		label values educ educ
					
/***************************************	
4.6 - Intersections of sex, race, education	
***************************************/
			
	mark nomiss2 
	markout nomiss2 agegroups sex race educ obesity
	ta nomiss2 if sample==1 // incomplete = 1,083 (1.48%)
	
	gen stratum2 = (1000*agegroups + 100*sex + 10*race + 1*educ) if sample==1 
	display 3*2*3*3 // 54
	codebook stratum2 // No stratas are missing
	ta stratum2

	label define intersection_label2 ///
		1111 "Younger Men White Low education" ///
		1112 "Younger Men White Mid education" ///
		1113 "Younger Men White High education" ///
		1121 "Younger Men Brown Low education" ///
		1122 "Younger Men Brown Mid education" ///
		1123 "Younger Men Brown High education" ///
		1131 "Younger Men Black Low education" ///
		1132 "Younger Men Black Mid education" ///
		1133 "Younger Men Black High education" ///
		1211 "Younger Women White Low education" ///
		1212 "Younger Women White Mid education" ///
		1213 "Younger Women White High education" ///
		1221 "Younger Women Brown Low education" ///
		1222 "Younger Women Brown Mid education" ///
		1223 "Younger Women Brown High education" ///
		1231 "Younger Women Black Low education" ///
		1232 "Younger Women Black Mid education" ///
		1233 "Younger Women Black High education" ///
		2111 "Middle-aged Men White Low education" ///
		2112 "Middle-aged Men White Mid education" ///
		2113 "Middle-aged Men White High education" ///
		2121 "Middle-aged Men Brown Low education" ///
		2122 "Middle-aged Men Brown Mid education" ///
		2123 "Middle-aged Men Brown High education" ///
		2131 "Middle-aged Men Black Low education" ///
		2132 "Middle-aged Men Black Mid education" ///
		2133 "Middle-aged Men Black High education" ///
		2211 "Middle-aged Women White Low education" ///
		2212 "Middle-aged Women White Mid education" ///
		2213 "Middle-aged Women White High education" ///
		2221 "Middle-aged Women Brown Low education" ///
		2222 "Middle-aged Women Brown Mid education" ///
		2223 "Middle-aged Women Brown High education" ///
		2231 "Middle-aged Women Black Low education" ///
		2232 "Middle-aged Women Black Mid education" ///
		2233 "Middle-aged Women Black High education" ///
		3111 "Older Men White Low education" ///
		3112 "Older Men White Mid education" ///
		3113 "Older Men White High education" ///
		3121 "Older Men Brown Low education" ///
		3122 "Older Men Brown Mid education" ///
		3123 "Older Men Brown High education" ///
		3131 "Older Men Black Low education" ///
		3132 "Older Men Black Mid education" ///
		3133 "Older Men Black High education" ///
		3211 "Older Women White Low education" ///
		3212 "Older Women White Mid education" ///
		3213 "Older Women White High education" ///
		3221 "Older Women Brown Low education" ///
		3222 "Older Women Brown Mid education" ///
		3223 "Older Women Brown High education" ///
		3231 "Older Women Black Low education" ///
		3232 "Older Women Black Mid education" ///
		3233 "Older Women Black High education" 
		label values stratum2 intersection_label2
		
		ta stratum2
		
//	Preparing the variable "sample" for the analysis
	drop sample
	gen sample2=.
	replace sample2=1 if V0015==1 & selected==1 & P005!=1 & C008>=18 & ///
		C008<=65 & BMI<60 & BMI>15 & stratum2!=. & nomiss2==1
	replace sample2=0 if sample2!=1
	ta sample2 // n=71,917
	
/*******************************************************************************
Preparing data for multilevel analysis
*******************************************************************************/
	
**	Two-level analyses
	/* 	Leckie, G. and Charlton, C. (2013). runmlwin - A Program to Run the MLwiN 
	Multilevel Modelling Software from within Stata. Journal of Statistical 
	Software, 52 (11),1-40. */
	
// 	instal MlWin to use on STATA
		ssc install runmlwin
		adoupdate runmlwin
		
// 	assigned a directory
		global MLwiN_path C:\(omitted)\MLwiN v3.04\mlwin.exe

// 	creating a constant variable
		gen cons = 1

// 	Generate ID variable
		gen obs=_n
		sum obs

// 	Generate ID for each individual clustered in an intersectional strata
		by stratum2, sort: gen id = _n
		
//	Generate dummys
		gen mid = (agegroups==2)
		gen older = (agegroups==3)
		gen women = (sex==2)
		gen brown = (race==2)
		gen black = (race==3)
		gen Emid = (educ==2)
		gen Ehigh = (educ==3)
		
//	Generate a new variabe which records stratum size
	bysort stratum2: generate n = _N
			
/*******************************************************************************
Table 2. Parameters estimates from the multilevel logistic regression models of
of individual heterogeneity and discriminatory accuracy for obesity (BMI≥30kg/m2). 
Brazilian National Health Survey, 2019.
*******************************************************************************/
	
*************************************
* Null model
*************************************
	runmlwin obesity cons if sample2==1, ///
		level2(stratum2: cons,) ///
		level1(id:, weightvar(V00291)) ///
		discrete(distribution(binomial) link(logit) denominator(cons) pql2) ///
		nopause				
	
	test [RP2]var(cons)=0 
	display [RP2]var(cons)/([RP2]var(cons) + (_pi^2)/3) 

	runmlwin obesity cons if sample2==1, ///
		level2(stratum2: cons, residuals(u)) ///
		level1(id:) ///
		discrete(distribution(binomial) link(logit) denom(cons)) mcmc(on) ///
		initsprevious or nopause nogroup
		
	test [RP2]var(cons)=0 
	
	* Store Level-2 variance / between-strata variance
	* [RP2]var(cons) could tell us how much intersectional stratas differ from
	* each other in terms of their average outcome.
	display [RP2]var(cons) 
	scalar m2Asigma2 = [RP2]var(cons)
		scalar list m2Asigma2 
	
	* Store Level-1 variance (always 3.29 for logit)
	display (_pi^2)/3 
	scalar m1sigma2e = _pi^2/3
		scalar list m1sigma2e 
	
	* VPC - Variance partition coefficients  
	display 100*([RP2]var(cons)/([RP2]var(cons) + (_pi^2)/3)) 
	display "VPC_u = " %9.4f 100*(m2Asigma2/(m2Asigma2 + m1sigma2e)) 
	
	* Predict the linear predictor for the fixed portion of the model only
	predict m2Axb, xb // option xb is the default
	
	* Predict the fitted linear predictor (including both fixed and random effects)
	* predict m2Axbu, eta - is not allowed in runmlwin
	generate m2Axbu = m2Axb + u0 
	
	* Calculate the area under the receiver operating characteristic (ROC) curve
	* based on fitted linear predictor for the fixed portion of the model only 
	* (only the intercept)
	roctab obesity m2Axb 

	* Calculate the area under the receiver operating characteristic (ROC) curve
	* based on fitted linear predictor (intercept and stratum random effect)
	roctab obesity m2Axbu 
	roctab obesity m2Axbu, graph summary

	runmlwin, or
	
	drop u0 u0se	
	
*************************************
* Full model
*************************************

	runmlwin obesity cons mid older women brown black Emid Ehigh if sample2==1, ///
		level2(stratum2: cons,) ///
		level1(id:, weightvar(V00291)) ///
		discrete(distribution(binomial) link(logit) denominator(cons) pql2) ///
		nopause				
	
	test [RP2]var(cons)=0 
	display [RP2]var(cons)/([RP2]var(cons) + (_pi^2)/3) 

	runmlwin obesity cons mid older women brown black Emid Ehigh if sample2==1, ///
		level2(stratum2: cons, residuals(u)) ///
		level1(id:) ///
		discrete(distribution(binomial) link(logit) denom(cons)) mcmc(on) ///
		initsprevious or nopause nogroup
		
	test [RP2]var(cons)=0 
	
	* Store Level-2 variance / between-strata variance
	* [RP2]var(cons) could tell us how much intersectional stratas differ from
	* each other in terms of their average outcome.
	display [RP2]var(cons) 
	scalar m2Bsigma2 = [RP2]var(cons)
		scalar list m2Bsigma2 
	
	* Store Level-1 variance (always 3.29 for logit)
	display (_pi^2)/3 
	scalar m1sigma2e = _pi^2/3
		scalar list m1sigma2e 

	* VPC - Variance partition coefficients  
	display 100*([RP2]var(cons)/([RP2]var(cons) + (_pi^2)/3)) 
	display "VPC_u = " %9.4f 100*(m2Bsigma2/(m2Bsigma2 + m1sigma2e)) 
		
	* PCV
	display "PCV = " %9.4f 100*(m2Asigma2 - m2Bsigma2)/m2Asigma2 
	
	* Predict the linear predictor for the fixed portion of the model only
	predict m2Bxb, xb // option xb is the default
	
	* Predict the fitted linear predictor (including both fixed and random effects)
	* predict m2Axbu, eta - is not allowed in runmlwin
	generate m2Bxbu = m2Bxb + u0 
	
	* Predict the standard error of the fixed-portion linear prediction
	predict m2Bxbse, stdp 

	* Predict the stratum random effect and its standard error
	* predict m2Bu, reffect reses(m2Buse) 
	// doesnt work with runmlwin
	gen m2Bu = u0
	gen m2Buse = u0se

	* Calculate the area under the receiver operating characteristic (ROC) curve
	* based on linear predictor for the fixed portion of the model only (main 
	* effects only)
	roctab obesity m2Bxb 

	* Calculate the area under the receiver operating characteristic (ROC) curve
	* based on fitted linear predictor (main effects and interactions)
	roctab obesity m2Bxbu 

/*******************************************************************************
// Figure 1 - Predicted stratum interaction effects, ranked low to high.
Markers indicate predicted value for each stratum. Spikes indicate
approximate 95% CIs	
*******************************************************************************/
	
preserve
	
	set seed 1234
	
	* Generate the approximate standard error for the linear predictor
	generate m2xbuse = sqrt(m2Bxbse^2 + m2Buse^2)

	* Generate the predicted stratum percentages based on the regression 
	* coefficients and the predicted stratum random effect and factoring in 
	* prediction uncertainty
	generate m2Bpsim = 100 * invlogit(m2Bxb + m2Bu + rnormal(0, m2xbuse))

	* Generate the predicted stratum percentages ignoring the predicted stratum 
	* effect
	generate m2BpAsim = 100 * invlogit(m2Bxb)

	* Generate the difference in the predicted stratum percentages due to the 
	* predicted stratum effect
	generate m2BpBsim = m2Bpsim - m2BpAsim

	* Generate the lower and upper limits of the approximate 95% confidence 
	* intervals for the difference in predicted stratum percentages due to 
	* interaction
	bysort stratum2: egen m2BpBsimlo = pctile(m2BpBsim), p(2.5)
	bysort stratum2: egen m2BpBsimhi = pctile(m2BpBsim), p(97.5)
	
	* Convert the data into a stratum-level dataset
	collapse (mean) m2BpBsim, by(stratum2 m2BpBsimlo m2BpBsimhi)

	* Rank the predicted stratum percentage differences
	egen m2Bpsimrank = rank(m2BpBsim)

	* plot the caterpillar of the predicted stratum percentage 
	* difference in the predicted probability between the total predicted
	* probability in stratum j and the probability based on additive main
	* effects in the logistic case 
	twoway ///
		(rspike m2BpBsimhi m2BpBsimlo m2Bpsimrank, lcolor(gs4)) ///
		(scatter m2BpBsim m2Bpsimrank, mcolor(black) msymbol(smcircle)), ///
		ytitle("Difference in Predicted Percent" ///
		"of obesity due to Interactions", size(*1.0)) ///
		yline(0, lcolor(black)) ///
		yline(-20(5)20, lcolor(gs13)) ///
		ylabel(-20(5)20, angle(horizontal) labsize(*1.0)) ///
		xtitle("Stratum ranked", size(*1.0)) ///
		xlabel(0(1)55, labsize(*1.0)) ///
		legend(off) ///
		scheme(s1mono) ///
		name(Figure3C, replace) ///
		xsize(10)
		
	list stratum2 m2Bpsimrank m2BpBsimlo m2BpBsimhi
	
	* Which intersectional stratas are above average? 
	count if m2BpBsimhi < 0 
	list stratum2 m2BpBsimhi m2BpBsimhi m2BpBsimlo m2Bpsimrank if m2BpBsimhi < 0 
	
	count if m2BpBsimlo > 0 
	list stratum2 m2BpBsimhi m2BpBsimhi m2BpBsimlo m2Bpsimrank if m2BpBsimlo > 0 

restore
	
/*******************************************************************************
* Save the data at the intersectioanl strata-level
*******************************************************************************/

	describe
	* Dataset has currently 71,896 rows
	
	* Collapse the data down to a strata-level dataset
	collapse (count) n = obesity (mean) obesity ///
		agegroups sex race educ ///
		m2Axbu m2Axb m2Bxbu m2Bxb m2Bxbse m2Buse m2Bu, ///
		by (stratum2)

	describe
	* Dataset has now 35 rows, which is the number of stratas
	
	* Convert the outcome from a proportion to a percentage
	replace obesity = 100*obesity

	* Set the display format to 2dp
	format %9.2f obesity m2Axbu m2Bxbu m2Bxb m2Bxbse m2Bu m2Buse

/*******************************************************************************
// Figure 2a - Predicted values by intersectional strata ranked low to high
*******************************************************************************/
	
	* Generate the predicted stratum percentages
	generate m2Bp = 100 * invlogit(m2Bxbu)

	* Rank the predicted stratum percentages
	egen m2Bprank = rank(m2Bp)

	* Generate the lower and upper limits of the approximate 95% confidence 
	* intervals for the predicted stratum percentages
	generate m2Bplo = 100 * invlogit(m2Bxb + m2Bu ///
		- 1.96 * sqrt(m2Bxbse^2 + m2Buse^2))
	generate m2Bphi = 100 * invlogit(m2Bxb + m2Bu ///
		+ 1.96 * sqrt(m2Bxbse^2 + m2Buse^2))
	// Approximate as the model assumes no sampling covariability between the 
	// regression coefficients and the stratum random effect

	mean m2Bp 
	mean m2Bplo 
	mean m2Bphi 

	* Plot the caterpillar plot of the predicted stratum means
	twoway (rspike m2Bphi m2Bplo m2Bprank) (scatter m2Bp m2Bprank)
	 
	* Re-plot the caterpillar plot of the predicted stratum percentages with options
	list stratum2 m2Bprank if !missing(m2Bprank), abbreviate(16)

	twoway ///
		(rspike m2Bphi m2Bplo m2Bprank, lcolor(gs4)) ///
		(scatter m2Bp m2Bprank if agegroups==1, mcolor(gs0) msymbol(o)) ///
		(scatter m2Bp m2Bprank if agegroups==2, mcolor(gs14) mlcolor(gs0) msymbol(t)) ///
		(scatter m2Bp m2Bprank if agegroups==3, mcolor(gs8) msymbol(d)), ///	
		ytitle("Predicted prevalence of obesity", size(*0.8)) ///
		ylabel(0(10)55, angle(vertical) labsize(*0.8)) ///
		yline(0 10 20 30 40 50, lwidth(vthin) lcolor(gs13)) ///
		yline(21.87) ///
		yline(27.29, lcolor(gray) lpattern(dash)) ///
		yline(17.27, lcolor(gray) lpattern(dash)) ///	
		xtitle("Intersectional strata", size(*0.8)) ///
			xlabel(0(10)55, ///
			angle(vertical) labsize(*0.8)) ///
			legend(position(7) cols(3) ring(1) size(*0.8) ///
			order(2 "Younger" 3 "Middled-aged" 4 "Older")) ///
			scheme(s1mono) ///
			name(Figure2a, replace) ///
			xsize(20) ysize (10) 
	
	* https://stats.oarc.ucla.edu/stata/faq/how-can-i-view-different-marker-symbol-options/
	* https://geocenter.github.io/StataTraining/pdf/StataCheatsheet_visualization2.pdf
	
/*******************************************************************************
// Table 3. Description of the intersectional strata of the predicted 
prevalence of obesity	
*******************************************************************************/

	* Generate list of 10 highest/lowest predicted stratum percentages (for Table 4)
	sort m2Bp
	extremes m2Bp m2Bplo m2Bphi stratum2 m2Bprank
	
	* Other option
	* list stratum2 m2Bprank m2Bp m2Bplo m2Bphi in f/5
	* list stratum2 m2Bprank m2Bp m2Bplo m2Bphi in -5/-1
	
	mean m2Bp 
	mean m2Bplo 
	mean m2Bphi 

	* Which intersectional stratas are above average? 
	count if m2Bp > 21.87
	list stratum2 m2Bp m2Bplo m2Bphi m2Bprank if  m2Bp > 21.87
			
	* Which intersectional stratas are below average? 
	count if m2Bp < 21.87
	list stratum2 m2Bp m2Bplo m2Bphi m2Bprank if  m2Bp < 21.87
			
	* Which intersectional strata have their highest 95% CI below the avg 95% CI?
	count if m2Bphi < 17.27 // 3
	list stratum2 m2Bp m2Bplo m2Bphi m2Bprank if m2Bphi<17.27
	list stratum2 m2Bp m2Bplo m2Bphi m2Bprank if m2Bphi==17.27

	* Which intersectional strata have their lowest 95% CI above the avg 95% CI?
	count if m2Bplo > 27.29 // zero
	list stratum2 m2Bp m2Bplo m2Bphi m2Bprank if m2Bplo > 27.29
	list stratum2 m2Bp m2Bplo m2Bphi m2Bprank if m2Bplo==27.29

