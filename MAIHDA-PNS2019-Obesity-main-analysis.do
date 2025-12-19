/*******************************************************************************
This do-file contains all needed commands to analyse data for the manuscript 	
entitled "Assessing Intersectional Disparities in Obesity among Brazilian
Adults: A MAIHDA Approach". 

Authors: Dr Marcos Fanton, Dr Raquel Canuto, Dr Helena M. Constante

Data comes from the National Health Survey conducted in 2019 (2019 PNS) carried 
out by the Brazilian Institute of Geography and Statistics. Files are in the 
public domain and can be downloaded from the following link: 
ftp://ftp.ibge.gov.br/PNS/2019/Microdados/

This do-file runs from the file "pnsPESDOM2019.dta"

Some important information
	- Unlike the 2013 PNS in which the individual selected to answer the
	individual questionnaire needed to be 18 years or older, in the PNS 2019 
	individuals 15 years old or more were selected for this stage (V0025A)

	- The questionnaire is divided into three sections: 
	1) household questionnaire,
	2) questionnaire for all residents of the household, 
	3) individual questionnaire.
	The svyset below focuses on the weights of the responses of individuals 
	who answered the individual questionnaire.

	- For more methodological information about the 2019 PNS:
	Stopa SR, Szwarcwald CL, Oliveira MM, Gouvea E, Vieira M, Freitas MPS, et al.
	National Health Survey 2019: history, methods and perspectives.
	Epidemiol Serv Saude. 2020; 29 (5): e2020315.
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
4.6 - Intersections of sex, race, income, education	
***************************************/
			
//	Option 1 - Intersections of sex, race, income, education
	* Considering sex, race, income tertile, and educ											
	mark nomiss 
	markout nomiss agegroups sex race wage educ obesity
	ta nomiss if sample==1 // incomplete = 1,104 (1.51%)
	
	gen stratum = (10000*agegroups + 1000*sex + 100*race + 10*wage + 1*educ) if sample==1 
	display 3*2*3*3*3 // 162 stratas are expected
	codebook stratum // 159 stratas available. Which ones are missing?
	ta stratum
	* 12231 - Younger Women Brown High income Low education
	* 12331 - Younger Women Black High income Low education
	* 22231 - Middle Women Brown High income Low educatio
	
	label define intersection_label ///
		11111 "Younger Men White Low income Low education" ///
		11112 "Younger Men White Low income Mid education" ///
		11113 "Younger Men White Low income High education" ///
		11121 "Younger Men White Mid income Low education" ///
		11122 "Younger Men White Mid income Mid education" ///
		11123 "Younger Men White Mid income High education" ///
		11131 "Younger Men White High income Low education" ///
		11132 "Younger Men White High income Mid education" ///
		11133 "Younger Men White High income High education" ///
		11211 "Younger Men Brown Low income Low education" ///
		11212 "Younger Men Brown Low income Mid education" ///
		11213 "Younger Men Brown Low income High education" ///
		11221 "Younger Men Brown Mid income Low education" ///
		11222 "Younger Men Brown Mid income Mid education" ///
		11223 "Younger Men Brown Mid income High education" ///
		11231 "Younger Men Brown High income Low education" ///
		11232 "Younger Men Brown High income Mid education" ///
		11233 "Younger Men Brown High income High education" ///
		11311 "Younger Men Black Low income Low education" ///
		11312 "Younger Men Black Low income Mid education" ///
		11313 "Younger Men Black Low income High education" ///
		11321 "Younger Men Black Mid income Low education" ///
		11322 "Younger Men Black Mid income Mid education" ///
		11323 "Younger Men Black Mid income High education" ///
		11331 "Younger Men Black High income Low education" ///
		11332 "Younger Men Black High income Mid education" ///
		11333 "Younger Men Black High income High education" ///
		12111 "Younger Women White Low income Low education" ///
		12112 "Younger Women White Low income Mid education" ///
		12113 "Younger Women White Low income High education" ///
		12121 "Younger Women White Mid income Low education" ///
		12122 "Younger Women White Mid income Mid education" ///
		12123 "Younger Women White Mid income High education" ///
		12131 "Younger Women White High income Low education" ///
		12132 "Younger Women White High income Mid education" ///
		12133 "Younger Women White High income High education" ///
		12211 "Younger Women Brown Low income Low education" ///
		12212 "Younger Women Brown Low income Mid education" ///
		12213 "Younger Women Brown Low income High education" ///
		12221 "Younger Women Brown Mid income Low education" ///
		12222 "Younger Women Brown Mid income Mid education" ///
		12223 "Younger Women Brown Mid income High education" ///
		12231 "Younger Women Brown High income Low education" ///
		12232 "Younger Women Brown High income Mid education" ///
		12233 "Younger Women Brown High income High education" ///
		12311 "Younger Women Black Low income Low education" ///
		12312 "Younger Women Black Low income Mid education" ///
		12313 "Younger Women Black Low income High education" ///
		12321 "Younger Women Black Mid income Low education" ///
		12322 "Younger Women Black Mid income Mid education" ///
		12323 "Younger Women Black Mid income High education" ///
		12331 "Younger Women Black High income Low education" ///
		12332 "Younger Women Black High income Mid education" ///
		12333 "Younger Women Black High income High education" ///
		21111 "Middle Men White Low income Low education" ///
		21112 "Middle Men White Low income Mid education" ///
		21113 "Middle Men White Low income High education" ///
		21121 "Middle Men White Mid income Low education" ///
		21122 "Middle Men White Mid income Mid education" ///
		21123 "Middle Men White Mid income High education" ///
		21131 "Middle Men White High income Low education" ///
		21132 "Middle Men White High income Mid education" ///
		21133 "Middle Men White High income High education" ///
		21211 "Middle Men Brown Low income Low education" ///
		21212 "Middle Men Brown Low income Mid education" ///
		21213 "Middle Men Brown Low income High education" ///
		21221 "Middle Men Brown Mid income Low education" ///
		21222 "Middle Men Brown Mid income Mid education" ///
		21223 "Middle Men Brown Mid income High education" ///
		21231 "Middle Men Brown High income Low education" ///
		21232 "Middle Men Brown High income Mid education" ///
		21233 "Middle Men Brown High income High education" ///
		21311 "Middle Men Black Low income Low education" ///
		21312 "Middle Men Black Low income Mid education" ///
		21313 "Middle Men Black Low income High education" ///
		21321 "Middle Men Black Mid income Low education" ///
		21322 "Middle Men Black Mid income Mid education" ///
		21323 "Middle Men Black Mid income High education" ///
		21331 "Middle Men Black High income Low education" ///
		21332 "Middle Men Black High income Mid education" ///
		21333 "Middle Men Black High income High education" ///
		22111 "Middle Women White Low income Low education" ///
		22112 "Middle Women White Low income Mid education" ///
		22113 "Middle Women White Low income High education" ///
		22121 "Middle Women White Mid income Low education" ///
		22122 "Middle Women White Mid income Mid education" ///
		22123 "Middle Women White Mid income High education" ///
		22131 "Middle Women White High income Low education" ///
		22132 "Middle Women White High income Mid education" ///
		22133 "Middle Women White High income High education" ///
		22211 "Middle Women Brown Low income Low education" ///
		22212 "Middle Women Brown Low income Mid education" ///
		22213 "Middle Women Brown Low income High education" ///
		22221 "Middle Women Brown Mid income Low education" ///
		22222 "Middle Women Brown Mid income Mid education" ///
		22223 "Middle Women Brown Mid income High education" ///
		22231 "Middle Women Brown High income Low education" ///
		22232 "Middle Women Brown High income Mid education" ///
		22233 "Middle Women Brown High income High education" ///
		22311 "Middle Women Black Low income Low education" ///
		22312 "Middle Women Black Low income Mid education" ///
		22313 "Middle Women Black Low income High education" ///
		22321 "Middle Women Black Mid income Low education" ///
		22322 "Middle Women Black Mid income Mid education" ///
		22323 "Middle Women Black Mid income High education" ///
		22331 "Middle Women Black High income Low education" ///
		22332 "Middle Women Black High income Mid education" ///
		22333 "Middle Women Black High income High education" ///
		31111 "Older Men White Low income Low education" ///
		31112 "Older Men White Low income Mid education" ///
		31113 "Older Men White Low income High education" ///
		31121 "Older Men White Mid income Low education" ///
		31122 "Older Men White Mid income Mid education" ///
		31123 "Older Men White Mid income High education" ///
		31131 "Older Men White High income Low education" ///
		31132 "Older Men White High income Mid education" ///
		31133 "Older Men White High income High education" ///
		31211 "Older Men Brown Low income Low education" ///
		31212 "Older Men Brown Low income Mid education" ///
		31213 "Older Men Brown Low income High education" ///
		31221 "Older Men Brown Mid income Low education" ///
		31222 "Older Men Brown Mid income Mid education" ///
		31223 "Older Men Brown Mid income High education" ///
		31231 "Older Men Brown High income Low education" ///
		31232 "Older Men Brown High income Mid education" ///
		31233 "Older Men Brown High income High education" ///
		31311 "Older Men Black Low income Low education" ///
		31312 "Older Men Black Low income Mid education" ///
		31313 "Older Men Black Low income High education" ///
		31321 "Older Men Black Mid income Low education" ///
		31322 "Older Men Black Mid income Mid education" ///
		31323 "Older Men Black Mid income High education" ///
		31331 "Older Men Black High income Low education" ///
		31332 "Older Men Black High income Mid education" ///
		31333 "Older Men Black High income High education" ///
		32111 "Older Women White Low income Low education" ///
		32112 "Older Women White Low income Mid education" ///
		32113 "Older Women White Low income High education" ///
		32121 "Older Women White Mid income Low education" ///
		32122 "Older Women White Mid income Mid education" ///
		32123 "Older Women White Mid income High education" ///
		32131 "Older Women White High income Low education" ///
		32132 "Older Women White High income Mid education" ///
		32133 "Older Women White High income High education" ///
		32211 "Older Women Brown Low income Low education" ///
		32212 "Older Women Brown Low income Mid education" ///
		32213 "Older Women Brown Low income High education" ///
		32221 "Older Women Brown Mid income Low education" ///
		32222 "Older Women Brown Mid income Mid education" ///
		32223 "Older Women Brown Mid income High education" ///
		32231 "Older Women Brown High income Low education" ///
		32232 "Older Women Brown High income Mid education" ///
		32233 "Older Women Brown High income High education" ///
		32311 "Older Women Black Low income Low education" ///
		32312 "Older Women Black Low income Mid education" ///
		32313 "Older Women Black Low income High education" ///
		32321 "Older Women Black Mid income Low education" ///
		32322 "Older Women Black Mid income Mid education" ///
		32323 "Older Women Black Mid income High education" ///
		32331 "Older Women Black High income Low education" ///
		32332 "Older Women Black High income Mid education" ///
		32333 "Older Women Black High income High education"
	label values stratum intersection_label
	
/*******************************************************************************
5 - Survey design and weights
*******************************************************************************/
		
	/*
	For all analyses, the survey design will be used according to the oficial	
	webpage of the Ministry of Health, with reference to the 2013 PNS:
	https://portalarquivos.saude.gov.br/images/pdf/2019/janeiro/10/Orientacoes-sobre-o-uso-das-bases-de-dados.pdf

	Selected individuals weights are described below 
	- 	UPA (primary sampling units): UPA_PNS
	-	Strata: V0024
	- 	Selected resident weight with non-interview correction with population 	
		projection calibration for selected resident - used in calculating 		
		selected resident indicators: V00291
	*/
	
	// Check if there are any missing values for the weights needed
	codebook V00291 V0024 UPA_PNS
	codebook V00291 V0024 UPA_PNS if sample==1
	ta sample if nomiss==1 // n= 71,896 
	
	//	Set the survey design
	svyset UPA_PNS [pweight=V00291], strata(V0024) ///
	vce(linearized) singleunit(centered)

	//	Check the estimated population for inferences
	svy: mean V00291 if sample==1 & nomiss==1 // n=133,823,631

/***************************************************************************
6 - Missing data	
****************************************************************************/
	
//	Preparing the variable "sample" for the analysis
	drop sample
	gen sample=.
	replace sample=1 if V0015==1 & selected==1 & P005!=1 & C008>=18 & ///
		C008<=65 & BMI<60 & BMI>15 & stratum!=. & nomiss==1
	replace sample=0 if sample!=1
	ta sample // n=71,896
	
/**********************************
Table 1. Distribution of the social characteristics of sample and prevalence 
of obesity (BMI≥30kg/m2). Brazilian National Health Survey, 2019.
**********************************/
	*ssc install asdoc															

//	Distribution of the analytical sample
	svy, subpop(sample): ta agegroups, obs percent ci nomarginal
	svy, subpop(sample): ta sex, obs percent ci nomarginal
	svy, subpop(sample): ta race, obs percent ci nomarginal
	svy, subpop(sample): ta wage, obs percent ci nomarginal
	svy, subpop(sample): ta educ, obs percent ci nomarginal
	svy, subpop(sample): ta obesity, obs percent ci nomarginal
	
//	Prevalence obesity according to explanatory variables
	svy, subpop(sample): ta agegroups obesity, row obs percent ci nomarginal
	svy, subpop(sample): ta sex obesity, row obs percent ci nomarginal 
	svy, subpop(sample): ta race obesity, row obs percent ci nomarginal 
	svy, subpop(sample): ta wage obesity, row obs percent ci nomarginal
	svy, subpop(sample): ta educ obesity, row obs percent ci nomarginal			
	
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
		by stratum, sort: gen id = _n
		
//	Generate dummys
		gen mid = (agegroups==2)
		gen older = (agegroups==3)
		gen women = (sex==2)
		gen brown = (race==2)
		gen black = (race==3)
		gen Imid = (wage==2)
		gen Ihigh = (wage==3)
		gen Emid = (educ==2)
		gen Ehigh = (educ==3)
		
//	Generate a new variabe which records stratum size
	bysort stratum: generate n = _N
			
/*******************************************************************************
Table 2. Parameters estimates from the multilevel logistic regression models of
of individual heterogeneity and discriminatory accuracy for obesity (BMI≥30kg/m2). 
Brazilian National Health Survey, 2019.
*******************************************************************************/
	
*************************************
* Null model
*************************************
	runmlwin obesity cons if sample==1, ///
		level2(stratum: cons,) ///
		level1(id:, weightvar(V00291)) ///
		discrete(distribution(binomial) link(logit) denominator(cons) pql2) ///
		nopause				
	
	runmlwin obesity cons if sample==1, ///
		level2(stratum: cons, residuals(u)) ///
		level1(id:) ///
		discrete(distribution(binomial) link(logit) denom(cons)) mcmc(on) ///
		initsprevious or nopause nogroup
		
	* The intercept is estimated to be 0.2715
	* The between-strata variance is estimated to be 0.1045

	test [RP2]var(cons)=0 // p<0.01
	
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
	
	* VPC - Variance partition coefficients (two ways)
	display 100*([RP2]var(cons)/([RP2]var(cons) + (_pi^2)/3)) // 3.08%
	display "VPC_u = " %9.4f 100*(m2Asigma2/(m2Asigma2 + m1sigma2e)) 
	
	* Predict the linear predictor for the fixed portion of the model only
	predict m2Axb, xb // option xb is the default
	
	* Predict the fitted linear predictor (including both fixed and random effects)
	* predict m2Axbu, eta - is not allowed in runmlwin
	generate m2Axbu = m2Axb + u0 
	
	* Calculate the area under the receiver operating characteristic (ROC) curve
	* based on fitted linear predictor for the fixed portion of the model only 
	* (only the intercept)
	roctab obesity m2Axb // 0.50

	* Calculate the area under the receiver operating characteristic (ROC) curve
	* based on fitted linear predictor (intercept and stratum random effect)
	roctab obesity m2Axbu // 0.59
	roctab obesity m2Axbu, graph summary

	runmlwin, or
	
	drop u0 u0se	
	
*************************************
* Full model
*************************************

	runmlwin obesity cons mid older women brown black Imid Ihigh Emid Ehigh if sample==1, ///
		level2(stratum: cons,) ///
		level1(id:, weightvar(V00291)) ///
		discrete(distribution(binomial) link(logit) denominator(cons) pql2) ///
		nopause				
	
	runmlwin obesity cons mid older women brown black Imid Ihigh Emid Ehigh if sample==1, ///
		level2(stratum: cons, residuals(u)) ///
		level1(id:) ///
		discrete(distribution(binomial) link(logit) denom(cons)) mcmc(on) ///
		initsprevious or nopause nogroup
		
	// To calculate more detailed graphical and statistical MCMC diagnostics for
	// the parameter chain

	* The command below produces trajectory plots (trace plots) of the deviance 
	* statistic and each model paramete	
	mcmcsum, trajectories	
	mcmcsum [RP2]var(cons), fiveway //  between-strata variance
	mcmcsum [RP2]var(cons), detail	

	* The intercept is estimated to be 0.19017
	* The between-strata variance is estimated to be 0.05599

	test [RP2]var(cons)=0 // p<0.01
	
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
	display 100*([RP2]var(cons)/([RP2]var(cons) + (_pi^2)/3)) // 1.65
	display "VPC_u = " %9.4f 100*(m2Bsigma2/(m2Bsigma2 + m1sigma2e)) // 1.65
		
	* PCV
	display "PCV = " %9.4f 100*(m2Asigma2 - m2Bsigma2)/m2Asigma2 // 47.02
	
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
	roctab obesity m2Bxb // 0.57

	* Calculate the area under the receiver operating characteristic (ROC) curve
	* based on fitted linear predictor (main effects and interactions)
	roctab obesity m2Bxbu // 0.59

	runmlwin, or

/*******************************************************************************
// Figure 1 - Predicted prevalence of obesity (BMI≥30kg/m2) (A) and residuals 
from the randomeffects (B) of the full model across intersectional strata 
considering an analytical sample(n=71,896) from the 2019 Brazilian National 
Health Survey.
*******************************************************************************/
	
/*******************************************************************************
// Figure 1B
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
	bysort stratum: egen m2BpBsimlo = pctile(m2BpBsim), p(2.5)
	bysort stratum: egen m2BpBsimhi = pctile(m2BpBsim), p(97.5)
	
	* Convert the data into a stratum-level dataset
	collapse (mean) m2BpBsim m2BpBsimlo m2BpBsimhi agegroups sex race wage educ, ///
	by(stratum)

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
		xlabel(0(1)160, labsize(*1.0)) ///
		legend(off) ///
		scheme(s1mono) ///
		name(Figure1B, replace) ///
		xsize(10)

	twoway ///
		(rspike m2BpBsimhi m2BpBsimlo m2Bpsimrank, lcolor(gs4)) ///
		(scatter m2BpBsim m2Bpsimrank if agegroups==1, mcolor(gs0) msymbol(o)) ///
		(scatter m2BpBsim m2Bpsimrank if agegroups==2, mcolor(gs14) mlcolor(gs0) msymbol(t)) ///
		(scatter m2BpBsim m2Bpsimrank if agegroups==3, mcolor(gs8) msymbol(d)), ///	
		ytitle("Difference in Predicted Percent" ///
		"of obesity due to Interactions", size(*1.0)) ///
		yline(0, lcolor(black)) ///
		yline(-20(5)20, lcolor(gs13)) ///
		ylabel(-20(5)20, angle(horizontal) labsize(*1.0)) ///
		xtitle("Intersectional strata", size(*0.8)) ///
			xlabel(0(10)160, ///
			angle(vertical) labsize(*0.8)) ///
			legend(position(7) cols(3) ring(1) size(*0.8) ///
			order(2 "Younger" 3 "Middled-aged" 4 "Older")) ///
			scheme(s1mono) ///
			name(Figure1B, replace) ///
			xsize(20) ysize (10) 
			
	list stratum m2Bpsimrank m2BpBsimlo m2BpBsimhi
	
	* Which intersectional stratas are above average? 
	count if m2BpBsimhi < 0 // 13
	list stratum m2BpBsim m2BpBsimlo m2BpBsimhi m2Bpsimrank if m2BpBsimhi < 0 
	
	count if m2BpBsimlo > 0 // 7
	list stratum m2BpBsim m2BpBsimlo m2BpBsimhi m2Bpsimrank if m2BpBsimlo > 0 

restore
	
/*******************************************************************************
* Save the data at the intersectioanl strata-level
*******************************************************************************/

	describe
	* Dataset has currently 71,896 rows
	
	mean(m2Axbu) if obesity==1 & stratum==11111 
	mean(m2Axb) if obesity==1 & stratum==11111 
	mean(m2Bxb) if obesity==1 & stratum==11111 
	mean(m2Bxbse) if obesity==1 & stratum==11111
	mean(m2Buse) if obesity==1 & stratum==11111 
	mean(m2Bu) if obesity==1 & stratum==11111 

	* Collapse the data down to a strata-level dataset
	collapse (count) n = obesity (mean) obesity ///
		agegroups sex race wage educ ///
		m2Axbu m2Axb m2Bxbu m2Bxb m2Bxbse m2Buse m2Bu, ///
		by (stratum)
	
	* Confirm if it worked
	mean(m2Axbu) if stratum==11111 
	mean(m2Axb) if stratum==11111 
	mean(m2Bxb) if stratum==11111 
	mean(m2Bxbse) if stratum==11111 
	mean(m2Buse) if stratum==11111 
	mean(m2Bu) if stratum==11111 

	describe
	* Dataset has now 160 rows, which is the number of stratas

	/* Why collapsing?
	The collapse command in Stata is used to summarize the dataset by 
	aggregating observations within specified groups, reducing it to one row 
	per group. 
	*(count) n = obesity* - creates a new variable n that counts the number of 
	non-missing values for obesity within each group
	*mean obesity* - replaces obesity with the mean value of obesity 
	within each group. Because outcome is binary, the mean will represent the 
	proportion of individuals who are considered 1 (obese) within each group
	*by(stratum)* - specify that the variable used to define each group is stratum
	*/
	
	* Convert the outcome from a proportion to a percentage
	replace obesity = 100*obesity

	* Set the display format to 2dp
	format %9.2f obesity m2Axbu m2Bxbu m2Bxb m2Bxbse m2Bu m2Buse

/*******************************************************************************
// Sample Size of Intersectional Social Strata
*******************************************************************************/

	* Generate binary indicators for whether each stratum has more than X 
	* individuals
	generate n100plus = (n >= 100)
	generate n50plus = (n >= 50)
	generate n30plus = (n >= 30)
	generate n20plus = (n >= 20)
	generate n10plus = (n >= 10)
	generate nlessthan10 = (n < 10)

	* Tabulate the binary indicators
	tabulate n100plus
	tabulate n50plus
	tabulate n30plus
	tabulate n20plus
	tabulate n10plus
	tabulate nlessthan10

/*******************************************************************************
// Figure 1A
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

	mean m2Bp // 21.55
	mean m2Bplo // 16.65
	mean m2Bphi // 27.48

	* Plot the caterpillar plot of the predicted stratum means
	twoway (rspike m2Bphi m2Bplo m2Bprank) (scatter m2Bp m2Bprank)
	 
	* Re-plot the caterpillar plot of the predicted stratum percentages with options
	list stratum m2Bprank if !missing(m2Bprank), abbreviate(16)

	twoway ///
		(rspike m2Bphi m2Bplo m2Bprank, lcolor(gs4)) ///
		(scatter m2Bp m2Bprank if agegroups==1, mcolor(gs0) msymbol(o)) ///
		(scatter m2Bp m2Bprank if agegroups==2, mcolor(gs14) mlcolor(gs0) msymbol(t)) ///
		(scatter m2Bp m2Bprank if agegroups==3, mcolor(gs8) msymbol(d)), ///	
		ytitle("Predicted prevalence of obesity", size(*0.8)) ///
		ylabel(0(10)40, angle(vertical) labsize(*0.8)) ///
		yline(0 10 20 30 40, lwidth(vthin) lcolor(gs13)) ///
		yline(21.55) ///
		yline(27.48, lcolor(gray) lpattern(dash)) ///
		yline(16.65, lcolor(gray) lpattern(dash)) ///	
		xtitle("Intersectional strata", size(*0.8)) ///
			xlabel(0(10)160, ///
			angle(vertical) labsize(*0.8)) ///
			legend(position(7) cols(3) ring(1) size(*0.8) ///
			order(2 "Younger" 3 "Middled-aged" 4 "Older")) ///
			scheme(s1mono) ///
			name(Figure1A, replace) ///
			xsize(20) ysize (10) 
	
	* https://stats.oarc.ucla.edu/stata/faq/how-can-i-view-different-marker-symbol-options/
	* https://geocenter.github.io/StataTraining/pdf/StataCheatsheet_visualization2.pdf
	
/*******************************************************************************
// Table 3. Description of the intersectional strata of the predicted prevalence 
of obesity and residuals following results from the full model	
*******************************************************************************/

	mean m2Bp // 21.55
	mean m2Bplo // 16.65
	mean m2Bphi // 27.48

	* Generate list of 10 highest/lowest predicted stratum percentages (for Table 4)
	sort m2Bp
	extremes m2Bp m2Bplo m2Bphi stratum m2Bprank
	
	* Other option
	* list stratum1 m2Bprank m2Bp m2Bplo m2Bphi in f/5
	* list stratum1 m2Bprank m2Bp m2Bplo m2Bphi in -5/-1

	* Which intersectional stratas are below average? 
	count if m2Bp < 21.55
	list stratum m2Bprank if  m2Bp < 21.55
	
	* Which intersectional stratas are above average? 
	count if m2Bp > 21.55
	list stratum m2Bprank if  m2Bp > 21.55
			
	* Which intersectional strata have their highest 95% CI below the avg 95% CI?
	count if m2Bphi < 16.65 // 5
	list stratum m2Bp m2Bplo m2Bphi m2Bprank if m2Bphi<16.65
	list stratum m2Bp m2Bplo m2Bphi m2Bprank if m2Bphi==16.65

	* Which intersectional strata have their lowest 95% CI above the avg 95% CI?
	count if m2Bplo > 27.48 // 1
	list stratum m2Bp m2Bplo m2Bphi m2Bprank if m2Bplo>27.48
	list stratum m2Bp m2Bplo m2Bphi m2Bprank if m2Bplo==27.48	
	
// END OF DO-FILE 1
