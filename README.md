# Replication: 
## Juhn, Murphy & Pierce (1991) and Neal & Johnson (1996)

This repository contains Stata code for replicating key results from:

- **Juhn, Murphy, and Pierce (1991)** — *Accounting for the Slowdown in Black-White Wage Convergence*, AER  
- **Neal and Johnson (1996)** — *The Role of Premarket Factors in Black-White Wage Differences*, JPE

## What This Repository Does

- Recreates key tables and regression results from both studies
- Documents assumptions, data sources, and Stata commands used
- Follows the original authors' methodology as closely as possible

---

## How to Run the Code

To replicate the results:

1. Open Stata
2. Navigate to the appropriate folder (`JMP1991/do_files/` or `NJ1996/do_files/`).
3. Run the main `.do` file:

``` stata
do JMP_Replication.do
```

Or for Neal & Johnson:

``` stata
do NJ_Replication_BM.do
```


## Note: 
While the data is publicly available, it is not saved in these files.

---

## Citation

If you use this repository, please cite the original studies:

- Juhn, Chinhui, Kevin M. Murphy and Brooks Pierce (1991), "Accounting for the slowdown in black-white wage convergence" in: Marvin H. Kosters, ed., Workers and their wages (AEI Press, Washington, DC)

- Neal, Derek and Johnson, William, (1996), The Role of Premarket Factors in Black-White Wage Differences, Journal of Political Economy, 104, issue 5, p. 869-95.

---

## Maintained By

**Brian Murphy**  
PhD Student in Economics, University of Houston  
📫 [bmmurphy2@uh.edu](mailto:bmmurphy2@uh.edu)

---

## License

This repository is intended for educational and academic research purposes only.  
Please credit the original authors when reproducing or referencing their results.

All code is provided as-is under a permissive academic use model. Contact the maintainer for questions about use, collaboration, or data access.
