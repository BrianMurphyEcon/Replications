********************************************************************************
********************************************************************************
************* THIS CODE REPLICATES THE NEAL AND JOHNSON 1996 PAPER *************
********************************************************************************
********************************************************************************

/* log using NJ_Replication_Log_BM, replace */

clear

#delimit ;

/*******************************************************************************
********************************************************************************
********************************* IMPORT DATA **********************************
********************************************************************************
*******************************************************************************/

infile id month79 year79 magazine79 newspaper79 library79 grademom79 gradedad79 
		  sibls79 sid79 race sex79 momwork80 dadwork80 month81 year81 asvabcode81 
		  gradstatus81 arith81 word81 paracomp81 numericalops81 math81 stanarith
		  stanmath stanverb afqtptile80 afqtptile89 sex82 class90 wage90 esr90 
		  class91 wage91 earn91 esr91
          using "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\Neal and Johnson Replication\Replication_Data\replicateNJ.dat";

/*******************************************************************************
********************************************************************************
********************************** DATA WORK ***********************************
********************************************************************************
*******************************************************************************/

/*** Keep Observations Born Between 1957 and 1964 - page 872: "a panel data set
of 12,686 young people born between 1957 and 1964" ***/

drop if year81 < 57 | year81 > 64;

/*** Drop if Suplemental White Data. page 872 "our analysis combines the 
cross-section sample and the supplemental sample of black and Hispanics" so it 
doesn't use the supplemental white data ***/
 
drop if sid79 == 9 | sid79 == 12;

/*** Score Calculations Come from: https://tinyurl.com/sff4h8ky. Also, see
footnote five. For Intuition, Verbal is multiplied by 2, since it is a 
combination of the word knowledge and paragraph comprehension score page 871 
"we control for a single measure of skill, the AFQT" and see footnote 5 on page
873. This was easily found by simple googling. ***/

gen rawafqt = (2 * stanverb) + stanmath + stanarith;
drop if rawafqt<0;

/*** Generate Age-Adjusted AFQT Score: "Since panel members took the AFQT at 
different ages and scores clearly rise with age, we adjusted the raw AFQT score 
for age at the test date and also normalized the score so that the sample mean 
is zero and the standard deviation is one." page 874***/

reg rawafqt i.year81;
predict afqtresid, rstandard;

/*** Create AFQT and AFQT Squared Variables ***/

gen afqt = afqtresid;
gen afqt2 = afqt^2;

/*** Drop Observations with No Work in Both Years. Paper is studying effect on
wages, and people who do not work do not have wages Footnote 7, page 874: "The 
wage variable is the log of the mean of real wages in 1990 and 1991 for workers 
who worked in both years." ***/

drop if class90 <= 0 & class91 <= 0;

/*** Calculate Standardized Wage. I average the wages from the two years 
as I couldn't find any explicit direction on how they did this ***/

gen wage = 1;

replace wage = (wage90 + wage91) / 2; 

/*** Drop Observations with Invalid Wages ***/

drop if wage <= 1;

/*** page 888 in the table, variable is mom graduated high school, variable is
mom graduated college, variable is variable is dad graduated high school
and variable is dad graduated college. These variable is defined below ***/

gen momhs = (grademom79 >= 12);
gen momcol = (grademom79 >= 16);

gen dadhs = (gradedad79 >= 12);
gen dadcol = (gradedad79 >= 16);

/*** page888 in table, variable is mother professional and variable is
father professional. I take this to mean do they work. These variable are
 defined below ***/

gen mompro = (momwork80 == 1 | momwork80 == 2);
gen dadpro = (dadwork80 == 1 | dadwork80 == 2);

/*** page 888 "no reading material means none of the above and numerous means
all of the above." This variable is defined below ***/

gen noread = (magazine79 == 0 & newspaper79 == 0 & library79 == 0);
gen numerousread = (magazine79 == 1 & newspaper79 == 1 & library79 == 1);

/*** Create Gender Variable - Used in Many Tables***/

gen female = 0;
replace female = 1 if sex82 == 2 | sex79 == 2;

/*** page 875, Table 1: uses Black, Hispanic, and Age. These variables are 
defined below. Wage data used till 91, so subtract 91. ***/

gen hisp = (race == 1);
gen black = (race == 2);
gen age = 91 - year81;

/*** page 874: "using the AFQT score as the measure of skill in the log wage 
regression," so I create a log wage variable ***/

gen logwage = log(wage);

/*******************************************************************************
********************************************************************************
***************************** FINAL DATA CLEANING ******************************
********************************************************************************
*******************************************************************************/

/*** Ensure Final Dataset Contains Relevant Observations Only: "We analyze 
respondents born after 1961 who would have been 18 or younger when they 
took the AFQT." page 873 ***/

drop if logwage <= 0 | rawafqt < 0 | year81 <= 61;

/*******************************************************************************
********************************************************************************
********************************* Replication **********************************
********************************************************************************
*******************************************************************************/

/*** Replicate Table 1 ***/

reg logwage black hisp age if female==0;
eststo model1;

reg logwage black hisp age afqt afqt2 if female==0;
eststo model2;

reg logwage black hisp age if female==1;
eststo model3;

reg logwage black hisp age afqt afqt2 if female==1;
eststo model4;

esttab model1 model2 model3 model4 using "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\Neal and Johnson Replication\Tables\Table_1", star(* 0.10 ** 0.05 *** 0.01) se label replace;

/*** Replicate Table 2 ***/

reg logwage black hisp age afqt afqt2 black##c.afqt black##c.afqt2 if female==0;
eststo model5;

reg logwage age afqt afqt2 if female==0 & black==0 & hisp==0;
eststo model6;

reg logwage age afqt afqt2 if female==0 & black==1 & hisp==0;
eststo model7;

reg logwage age afqt afqt2 if female==0 & black==0 & hisp==1;
eststo model8;

esttab model5 model6 model7 model8 using "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\Neal and Johnson Replication\Tables\Table_2", star(* 0.10 ** 0.05 *** 0.01) se label replace;

/*** Replicate Table 3 ***/

reg logwage black hisp age afqt afqt2 black##c.afqt black##c.afqt2 if female==1;
eststo model9;

reg logwage age afqt afqt2 if female==1 & black==0 & hisp==0;
eststo model10;

reg logwage age afqt afqt2 if female==1 & black==1 & hisp==0;
eststo model11;

reg logwage age afqt afqt2 if female==1 & black==0 & hisp==1;
eststo model12;

esttab model9 model10 model11 model12 using "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\Neal and Johnson Replication\Tables\Table_3", star(* 0.10 ** 0.05 *** 0.01) se label replace;

/*** Replicate Table 4 uses median log wage, so do quantile regression ***/

qreg logwage black hisp age if female==0;
eststo model13;

qreg logwage black hisp age afqt afqt2 if female==0;
eststo model14;

esttab model13 model14 using "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\Neal and Johnson Replication\Tables\Table_4", star(* 0.10 ** 0.05 *** 0.01) se label replace;

/*** Replicate Table 5 ***/

reg afqt black hisp if female==0;
eststo model15;

reg afqt black hisp momhs momcol dadhs dadcol mompro dadpro if female==0;
eststo model16;

reg afqt black hisp momhs momcol dadhs dadcol mompro dadpro sibls79 numerousread noread if female==0;
eststo model17;

/*** I was unable to replicate column (4) I was unsure of the variables ***/

esttab model15 model16 model17 using "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\Neal and Johnson Replication\Tables\Table_5", star(* 0.10 ** 0.05 *** 0.01) se label replace;

/*** Replicate Table 6 ***/

reg afqt black hisp if female==1;
eststo model18;

reg afqt black hisp momhs momcol dadhs dadcol mompro dadpro if female==1;
eststo model19;

reg afqt black hisp momhs momcol dadhs dadcol mompro dadpro sibls79 numerousread noread if female==1;
eststo model20;

/*** I was unable to replicate column (4) I was unsure of the variables ***/

esttab model18 model19 model20 using "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\Neal and Johnson Replication\Tables\Table_6", star(* 0.10 ** 0.05 *** 0.01) se label replace;

* log close;