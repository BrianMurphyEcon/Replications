********************************************************************************
********************************************************************************
********************** THIS CODE REPLICATES THE JMP PAPER **********************
********************************************************************************
********************************************************************************

/* log using JMP_Replication_Log_BM, replace */

/* ssc install jmpierce2 */

clear

/*******************************************************************************
********************************************************************************
********************************* IMPORT DATA **********************************
********************************************************************************
*******************************************************************************/

use "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\JMP Replication\Replication_Data\cps_00002.dta",clear

/*******************************************************************************
********************************************************************************
********************************** DATA WORK ***********************************
********************************************************************************
*******************************************************************************/

/*** JMP uses weekly wages. There's no weeks worked data for 1964-1976, 
so I will use annual earnings. ***/ 

drop if year == 1962 | year == 1963

/*** Drop Female ***/

drop if sex == 2

/*** Keep only Black and White ***/

keep if race == 100 | race == 200 

/*** Keep if Full Timer Worker ***/

keep if fullpart == 1 
keep if wkswork1 > 38

/*** Drop Self Employed ***/

drop if classwly == 10

/*** Drop if Wage equals 0 ***/

drop if incwage == 0

/*** Dummy for White ***/

gen white = (race == 100) if inlist(race, 100, 200) // dummy for white

/*** Drop Missing Educational Observations ***/

drop if educ == 999

/*** Create Educational Years ***/

recode educ (2 = 0) (10 12= 2) (11 =1) (13 = 3) (14 = 4) ///
 (20 21= 5) (22 = 6) (30 31= 7) (32 = 8) (40 = 9) (50 = 10) ///
 (60 71= 11) (72 73 = 12) (80 = 13) (81 90= 14) (91 92 100 = 15) ///
 (110 111 121 122 = 16) (123 124 = 18) (125 = 20), gen (educyears)
 
/*** Create Educational Categories ***/

recode educ (2/71 = 1 "Less than High School") (72 73 = 2 "High School") ///
 (80/100 = 3 "Some College") (101/125 = 4 "College"), gen(educ_cat)
 
/*** Create Experience Categories ***/

gen experience = min(age - educyears - 7, age - 17)
recode experience (-10/5 = 1 "less than 6") (6/10 =2 "6 to 10") ///
 (11/15 = 3 "11 to 15") (16/20 = 4 "16 to 20") (21/25 = 5 "21 to 25") ///
 (26/30 =6 "26 to 30") (31/35 = 7 "31 to 35") (36/60 = 8 "greater than 35"), gen(experience_cat)

/*** Merge to Translate the 2017 Dollars and Calculate Wages ***/

merge m:1 year using "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\JMP Replication\Replication_Data\deflator.dta" 

gen realwage = (incwage / deflator)*100
gen logwage = log(realwage)


/*******************************************************************************
********************************************************************************
********************************* Replication **********************************
********************************************************************************
*******************************************************************************/

/*** Figure 4-1 ***/

/*** Preserve the original dataset ***/

preserve

/*** Define the years ***/

local start_year 1964
local end_year 1988

/*** Create a matrix ***/

matrix results = J(`=`end_year' - `start_year' + 1', 2, .)

/*** Loop over each year, and store the results in the matrix ***/

forvalues i = `start_year'/`end_year' {
    quietly reg logwage white [pw = asecwt] if year == `i'
    
    * Calculate the row number (relative to start year)
    local row = `i' - `start_year' + 1
    
    * Store the year and the coefficient on 'white' in the matrix
    matrix results[`row', 1] = `i'
    matrix results[`row', 2] = _b[white]
}

/*** Convert Matrix to Dataset ***/

svmat results, names(col)

/*** Plot the scatterplot ***/

twoway scatter c2 c1, ///
    title("Log Wage Differential Between Whites and Blacks Over Time") ///
    ytitle("Log Wage Differential (White)") xtitle("Year") ///
	scheme(white_set3)
	
local trend_end 1980

/*** Generate a dummy variable to indicate years for estimation 
(1964-1980) ***/

gen trend_data = c1 < 1981
replace trend_data = c1 if c1 == .

/*** Run regression to estimate trend on 1964-1980 data ***/

reg c2 c1 if trend_data

/*** Predict fitted values (1964-1987) and extrapolated values (1981-1987) ***/

predict trend_fit, xb

/*** Plot the data with trend line ***/
twoway (scatter c2 c1, mcolor(black) msymbol(o)) ///
       (line trend_fit c1, lcolor(blue) lpattern(dash)), ///
    title("Log Wage Differential and Trend Line (1964-1988)") ///
    ytitle("Log Wage Differential (White)") xtitle("Year") ///
    legend(order(1 "Observed Differential" 2 "Predicted Differential")) ///
    scheme(white_set3)	
	
graph save "Graph" "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\JMP Replication\Output\fig4_1.gph", replace
graph export "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\JMP Replication\Output\fig4_1.pdf", as(pdf) name("Graph") replace

/*** Restore the original dataset ***/

restore

/*** Table 4-1 ***/

timer on 2

/*** Define the 5-year intervals ***/
 
local intervals "1964 1969 1974 1979 1984"
local labels "1965 1970 1975 1980 1985"  // Matrix column headings

/*** Initialize matrix to store results ***/
 
matrix results = J(1, 5, .)  // 1 row, 5 columns for 5 periods (All experience levels)

/*** Loop for "All experience levels" i.e. experience_cat >= 0 ***/
 
local col = 1
foreach start in `intervals' {
    * Define end year for the current period
    local end = `start' + 4

    * Initialize a scalar to store the sum of coefficients and counter for the number of years
    local sum_coeff = 0
    local year_count = 0

    * Loop through each year in the current 5-year period
    forvalues i = `start'/`end' {
        * Run the regression for all experience levels
        quietly reg logwage white [pw = asecwt] if year == `i'

        * Extract the coefficient on white
        local coeff = _b[white]

        * Add the coefficient to the sum and increment the counter
        local sum_coeff = `sum_coeff' + `coeff'
        local year_count = `year_count' + 1
    }

    * Calculate the average coefficient for the period
    local mean = `sum_coeff' / `year_count'

    * Store the mean in the results matrix
    matrix results[1, `col'] = `mean'

    * Move to the next column
    local col = `col' + 1
}

/*** Loop over experience categories (1-8) and append to the matrix ***/

forvalues exp = 1/8 {
    * Initialize a temporary matrix for the current experience category
    matrix current_results = J(1, 5, .)

    * Loop through each 5-year period
    local col = 1
    foreach start in `intervals' {
        * Define end year for the current period
        local end = `start' + 4

        * Initialize scalar to store the sum of coefficients and counter for the number of years
        local sum_coeff = 0
        local year_count = 0

        * Loop through each year in the current 5-year period
        forvalues i = `start'/`end' {
            * Run the regression for the current experience category
            quietly reg logwage white [pw = asecwt] if year == `i' & experience_cat == `exp'

            * Extract the coefficient on white
            local coeff = _b[white]

            * Add the coefficient to the sum and increment the counter
            local sum_coeff = `sum_coeff' + `coeff'
            local year_count = `year_count' + 1
        }

        * Calculate the average coefficient for the period
        local mean = `sum_coeff' / `year_count'

        * Store the mean in the current_results matrix
        matrix current_results[1, `col'] = `mean'

        * Move to the next column
        local col = `col' + 1
    }

    * Append current_results to the main results matrix
    matrix results = results \ current_results

    * Display progress for each experience category
    display "Processed experience category `exp'"
}

/*** Add row names (experience levels) and column labels ***/

matrix rownames results = "All experience levels" ///
                         "<6 years" "6-10 years" "11-15 years" "16-20 years" "21-25 years" ///
                         "26-30 years" "31-35 years" ">35 years"

matrix colnames results = `labels'

/*** Display the final matrix ***/
 
matrix list results

timer off 2

/*** Now Panel B ***/

/*** Create dummies for education categories ***/

recode educ_cat (1=1) (2/4 = 0), gen(educ_less_hs)
recode educ_cat (2=1) (1 3/4 = 0), gen(educ_hs)
recode educ_cat (3=1) (1/2 4 = 0), gen(educ_some_college)
recode educ_cat (4=1) (1/3 = 0), gen(educ_college_plus)

/*** Create the quartic in experience ***/
 
gen exp = experience
replace exp = 0 if exp < 0

gen exp_sq = exp^2

gen exp_cub = exp^3

gen exp_quart = exp^4

preserve

/*** Run regression to get residuals ***/

quietly reg logwage i.region i.educ_less_hs##c.exp i.educ_less_hs##c.exp_sq i.educ_less_hs##c.exp_cub i.educ_less_hs##c.exp_quart ///
i.educ_hs##c.exp i.educ_hs##c.exp_sq i.educ_hs##c.exp_cub i.educ_hs##c.exp_quart ///
i.educ_some_college##c.exp i.educ_some_college##c.exp_sq i.educ_some_college##c.exp_cub i.educ_some_college##c.exp_quart ///
i.educ_college_plus##c.exp i.educ_college_plus##c.exp_sq i.educ_college_plus##c.exp_cub i.educ_college_plus##c.exp_quart c.educyears, robust

/*** Get the residuals (unexplained part of wages) ***/

predict residual_wage, residual

/*** Define the 5-year intervals ***/
 
local intervals "1964 1969 1974 1979 1984"
local labels "1965 1970 1975 1980 1985" 

/*** Initialize matrix to store results ***/
matrix residual_results = J(9, 5, .) 

/*** Run the regressions for "All experience levels" ***/

local row = 1
local col = 1  // Initialize column counter
foreach start in `intervals' {
    * Define end year for the current period
    local end = `start' + 4

    * Initialize scalar to store the sum of residual coefficients and counter for the number of years
    local sum_residual = 0
    local year_count = 0

    * Loop through each year in the current 5-year period
    forvalues i = `start'/`end' {
        * Run the regression for all experience levels
        quietly reg residual_wage white [pw = asecwt] if year == `i'

        * Extract the coefficient on white
        local coeff = _b[white]

        * Add the coefficient to the sum and increment the counter
        local sum_residual = `sum_residual' + `coeff'
        local year_count = `year_count' + 1
    }

    * Calculate the average residual coefficient for the period
    local mean_residual = `sum_residual' / `year_count'

    * Store the mean in the results matrix
    matrix residual_results[`row', `col'] = `mean_residual'

    * Move to the next column
    local col = `col' + 1
}

/*** Move to the next row ***/
local row = `row' + 1


/*** Loop through each experience category (1-8) ***/

forvalues exp = 1/8 {
    local col = 1
    foreach start in `intervals' {
        * Define end year for the current period
        local end = `start' + 4

        * Initialize scalar to store the sum of residual coefficients and counter for the number of years
        local sum_residual = 0
        local year_count = 0

        * Loop through each year in the current 5-year period
        forvalues i = `start'/`end' {
            * Run the regression for the current experience category
            quietly reg residual_wage white [pw = asecwt] if year == `i' & experience_cat == `exp'

            * Extract the coefficient on white
            local coeff = _b[white]

            * Add the coefficient to the sum and increment the counter
            local sum_residual = `sum_residual' + `coeff'
            local year_count = `year_count' + 1
        }

        * Calculate the average residual coefficient for the period
        local mean_residual = `sum_residual' / `year_count'

        * Store the mean in the results matrix
        matrix residual_results[`row', `col'] = `mean_residual'

        * Move to the next column
        local col = `col' + 1
    }

    * Move to the next row
    local row = `row' + 1
}

/*** Add row names (experience levels) and column labels ***/

matrix rownames residual_results = "All experience levels" ///
                                 "<6 years" "6-10 years" "11-15 years" "16-20 years" "21-25 years" ///
                                 "26-30 years" "31-35 years" ">35 years"

matrix colnames residual_results = `labels'

/*** Display the final matrix with residual wages ***/
 
matrix list residual_results

restore

/*** Fig 4-7 ***/

/*** Initialize a matrix to store the results for each year ***/

local start_year 1964
local end_year 1988

/*** Columns: Year, Total Gap, Residual Gap ***/

matrix results = J(`=`end_year' - `start_year' + 1', 3, .)
local row = 1

/*** Loop through each year and perform decomposition ***/

forvalues year = `start_year'/`end_year' {
    
    * Display progress
    display as text "Processing year `year'"

    * Estimate the wage model for Whites (white = 1)
    quietly reg logwage educyears experience i.region if year == `year' & white == 1

    * Compute the predicted wage for Blacks (white = 0) using White coefficients
    quietly predict wage_black_pred if year == `year' & white == 0, xb

    * Calculate Total, Predicted, and Residual Gaps
    quietly summarize logwage if year == `year' & white == 0, meanonly
    local mean_black = r(mean)

    quietly summarize logwage if year == `year' & white == 1, meanonly
    local mean_white = r(mean)

    quietly summarize wage_black_pred if year == `year' & white == 0, meanonly
    local mean_pred_black = r(mean)

    local total_gap = `mean_white' - `mean_black'
    local residual_gap = `mean_pred_black' - `mean_black'

    * Store the year, total gap, and residual gap in the matrix
    matrix results[`row', 1] = `year'
    matrix results[`row', 2] = `total_gap'
    matrix results[`row', 3] = `residual_gap'

    * Drop wage_black_pred to avoid conflict in next iteration
    drop wage_black_pred

    * Increment the row
    local row = `row' + 1
}

/*** Preserve the original dataset ***/

preserve

/*** Convert the matrix into a dataset for plotting ***/
 
svmat results, names(col)
rename c1 years
rename c2 total_gap
rename c3 residual_gap

/*** Plot the results ***/

twoway (line total_gap years, lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (line residual_gap years, lcolor(red) lpattern(dash) lwidth(medium)), ///
       legend(order(1 "Total Gap" 2 "Residual Gap")) ///
       title("Black-White Wage Differential (1964-1988)") ///
       xtitle("Year") ///
       ytitle("Log Wage Differential") ///
       scheme(white_tableau)
	   
graph save "Graph" "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\JMP Replication\Output\fig4_7.gph", replace
graph export "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\JMP Replication\Output\fig4_7.pdf", as(pdf) name("Graph") replace	

/*** Restore the original dataset ***/

restore

/*** Fig 4-8 ***/

/*** Initialize a matrix to store the results for each year ***/
 
local start_year 1964
local end_year 1988

/*** Columns: Year, Total Gap, Residual Gap ***/

matrix results = J(`=`end_year' - `start_year' + 1', 3, .) 
local row = 1

/*** Loop through each year and perform decomposition ***/

forvalues year = `start_year'/`end_year' {

    * Display progress
    display as text "Processing year `year' (New Entrants, Experience <= 10)"

    * Estimate the wage model for Whites (white = 1 and experience <= 10)
    quietly reg logwage educyears experience i.region if year == `year' & white == 1 & experience <= 10

    * Compute the predicted wage for Blacks (white = 0 and experience <= 10) using White coefficients
    quietly predict wage_black_pred if year == `year' & white == 0 & experience <= 10, xb

    * Calculate Total, Predicted, and Residual Gaps
    quietly summarize logwage if year == `year' & white == 0 & experience <= 10, meanonly
    local mean_black = r(mean)

    quietly summarize logwage if year == `year' & white == 1 & experience <= 10, meanonly
    local mean_white = r(mean)

    quietly summarize wage_black_pred if year == `year' & white == 0 & experience <= 10, meanonly
    local mean_pred_black = r(mean)

    local total_gap = `mean_white' - `mean_black'
    local residual_gap = `mean_pred_black' - `mean_black'

    * Store the year, total gap, and residual gap in the matrix
    matrix results[`row', 1] = `year'
    matrix results[`row', 2] = `total_gap'
    matrix results[`row', 3] = `residual_gap'

    * Drop wage_black_pred to avoid conflict in the next iteration
    drop wage_black_pred

    * Increment the row
    local row = `row' + 1
}

/*** Preserve the original dataset ***/
 
preserve

/*** Convert the matrix into a dataset for plotting ***/

svmat results, names(col)
rename c1 years
rename c2 total_gap
rename c3 residual_gap

/*** Plot the results ***/
 
twoway (line total_gap years, lcolor(blue) lpattern(solid) lwidth(medium)) ///
       (line residual_gap years, lcolor(red) lpattern(dash) lwidth(medium)), ///
       legend(order(1 "Total Gap" 2 "Residual Gap")) ///
       title("Black-White Wage Differential (1964-1988, New Entrants)") ///
       xtitle("Year") ///
       ytitle("Log Wage Differential") ///
       scheme(white_tableau)

graph save "Graph" "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\JMP Replication\Output\fig4_8.gph", replace
graph export "C:\Users\bmmur\OneDrive\Desktop\Economics of Discrimination\Replication\JMP Replication\Output\fig4_8.pdf", as(pdf) name("Graph") replace	

/*** Restore the original dataset ***/
 
restore

/*** Table 4-5 ***/

/*** Preserve the original dataset before making changes ***/
 
preserve

/*** Define the range of years ***/
 
local start_year 1964
local end_year 1987

/*** Initialize a matrix to store results (Columns: Year, Total, Prices, 
Quantities, Observables, Unexplained_Prices, Gap) ***/

matrix results = J(`end_year' - `start_year' + 1, 7, .)

local row = 1

/*** Loop through each consecutive year pair and perform decomposition ***/
 
forvalues year = `start_year'/`end_year' {
    local next_year = `year' + 1  // Define the second year in the pair

    * Display progress
    display as text "Processing decomposition for `year' and `next_year'"

    * Regressions for year `year`
    quietly reg logwage educyears experience i.region if year == `year' & white == 1
    est sto white`year'

    quietly reg logwage educyears experience i.region if year == `year' & white == 0
    est sto black`year'

    * Regressions for year `next_year`
    quietly reg logwage educyears experience i.region if year == `next_year' & white == 1
    est sto white`next_year'

    quietly reg logwage educyears experience i.region if year == `next_year' & white == 0
    est sto black`next_year'

    * Perform the decomposition for the two periods
    quietly jmpierce2 white`year' black`year' white`next_year' black`next_year', benchmark(1)

    * Extract results and store them in the matrix
    matrix results[`row', 1] = `next_year'               // Year
    matrix results[`row', 2] = -r(DD)[1,1]               // Total convergence
    matrix results[`row', 3] = -r(E)[1,3]                // Prices
    matrix results[`row', 4] = -r(E)[1,2]                // Quantities
    matrix results[`row', 5] = -r(E)[1,1]                // Observables
    matrix results[`row', 6] = -r(U)[1,3]                // Unexplained prices
    matrix results[`row', 7] = -r(E)[1,2]                // Gap

    * Increment row counter
    local row = `row' + 1
}

clear

/*** Convert matrix into a dataset for review ***/
 
svmat results, names(col)
rename c1 year
rename c2 total
rename c3 prices
rename c4 quantities
rename c5 observables
rename c6 unexplained_prices
rename c7 gap

/*** Create the matrix: Initialize a 6x4 matrix to store results ***/

matrix results2 = J(6, 4, .)

/*** Define variables and row indices ***/

local vars total observables prices quantities unexplained_prices gap
local row 1

/*** Loop through each variable to calculate mean values and fill the matrix ***/

gen time1 = year - 1962

foreach var of local vars {
    * Calculate means for the periods and multiply by 100
    quietly summarize `var' if time1 >= 1 & time1 <= 7
    local mean1 = r(mean) * 100
    quietly summarize `var' if time1 >= 7 & time1 <= 16
    local mean2 = r(mean) * 100
    quietly summarize `var' if time1 >= 16 & time1 <= 24
    local mean3 = r(mean) * 100

    * Store in the matrix
    matrix results2[`row', 1] = `mean1'
    matrix results2[`row', 2] = `mean2'
    matrix results2[`row', 3] = `mean3'

    * Calculate and store the difference (column 2 - column 3) in the 4th column
    matrix results2[`row', 4] = `mean2' - `mean3'

    * Move to the next row for the next variable
    local row = `row' + 1
}

/*** Display the results matrix ***/
 
matrix list results2

/*** Restore the original dataset ***/
 
restore