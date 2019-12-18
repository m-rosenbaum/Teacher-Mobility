# ReadMe

This folder contains scripts to scrape, clean, and analyze data in this repository. The 00_master.do file will run all files, including the R scripts. The scripts are organized as follows:

- **Insheet (01)** scrapes data from the CPS and 5Essentials sites to make it machine readable.
- **Cleaning (02)** imports the data into Stata and cleans each dataset
- **Outcome Creation (03)** merges data together at the school- and employment-time-levels, and then creates a long dataset for use in analysis.
- **Analysis (04)** creates a summary statistics table and runs a synthetic control model to estimate teacher mobility changes following principal separations.

These files are require Stata 15.1 and R 3.6.1. The R scripts called by Stata do not use relative references and will need to modified by hand.

*Note:*
-	*The CPS site has changed since initial script was written. One to-do item is to update the script that scrapes yearly data releases from the [CPS data portal](https://cps.edu/SchoolData/Pages/SchoolData.aspx) to-do is to update scraping list for new CPS portal. Otherwise all data is in /Raw for now.*
- *This was originally my BA Thesis that used a difference-in-differences model to estimate these costs, but did not have parallel pre-trends. I update these data as a code sample. These data should be cleaned more thoroughly, especially in the fuzzy merge across the employment panel, if this is to be used for any sort of analysis.*
