# ReadMe
This repo contains an analysis of the approximate cost in teacher attrition of a principal separation in Chicago Public Schools (CPS). To do so, it scrapes a school-level data, creates a quarterly teacher employment panel, and then analyzes these data using a synthetic control model.

It contains a series of Stata and R scripts used to collect and clean these data used in the analysis as well as the version of the Stata programs used to clean these data.

*Note: as of December 15, 2019, the script scraping data from the [CPS data portal](https://cps.edu/SchoolData/Pages/SchoolData.aspx) is not included as the site has changed format since the script was originally written*

## Summary
In the US, teacher attrition imposes substantive academic costs on students and financial costs on school districts, especially those in low-income communities. Changes in school management may affect teacher employment behavior. I use a 5-year quarterly panel of teacher employment data from Chicago Public Schools and a synthetic control model to estimate the aggregate effect of principal separation on teacher attrition. I find that principal separation is associated with an increase in the rate of teacher attrition in the following quarter by 2.7 percentage points, or 14 percent. This has implications for school management policies that remove school management in an attempt to “turn-around” schools with low-performance on district measures. These types of turnaround policies may exacerbate teacher attrition, and therefore costs, for students and schools.

## Introduction 
Although school buildings persist in neighborhoods for decades, urban schools have close to 100% turnover of staff and students—not including promotion—[within 5 years](https://consortium-pub.uchicago.edu/sites/default/files/2018-10/CCSR_Teacher_Mobility.pdf). Substantive educational efforts are made to address student out-mobility, but teacher attrition receives less policy and media attention. This is a surprise given the financial costs to schools. In 2012, the direct cost of teacher separations for schools was estimated at between [$1.7 and $7.5 billion nationally]( https://www.jstor.org/stable/23353969) for districts . Teacher attrition does not only a financial cost to school districts. Although there is still a debate about what drives student learning, interruptions in instruction make [meaningful differences](https://hanushek.stanford.edu/sites/default/files/publications/Hanushek%202006%20HbEEdu%202.pdf) in educational achievement of students. Many districts do not take these costs into account when making policy decisions, nor costs shouldered by students in schools with high teacher mobility.

Given these costs, teacher retention is often a major concern for principals. In many districts, principals are directly responsible for teacher hiring, management, and are perceived as instructional leaders. In many ways, principals are the central management authority for teachers. Correlation evidence suggests that principal quality accounts for approximately [half of the difference](https://www.nber.org/papers/w20667) in administrative quality between schools. Principals play a central role in teacher retention as they serve a management and hiring function. It's possible that principal separation could have corresponding effects on teacher employment decision making. Estimating these effects is important for school districts as they balance decisions on management changes within schools. Financial costs and reductions in average teaching quality may outweigh any benefits by removing low-productivity principals.

## Data and Methods
Estimating the costs of principal separations on teacher retention is a challenge for causal identification. Public data availability poses one problem. Teacher employment records are reported yearly or quarterly depending on the district, and do not have unique identifiers for individuals in most publicly available datasets. A more serious problem is lack of random variation in principal separations: principal contracts are administered by school districts. Chicago Public Schools provides a potential case study due to high degrees of local control of principal hiring and firing. [Local school councils]( https://cps.edu/lscrelations/Pages/LSC_aboutlscs.aspx) (LSCs) have sole control on principal hiring and firing outside of select circumstances. Therefore, this allows individual schools to determine hiring and firing decisions with public voting. This provides substantive variation in principal employment within a consistent policy environment and salary schedule. 

To estimate costs of principal changes, I implement a [synthetic control model]( https://www.aeaweb.org/articles?id=10.1257/000282803321455188) to estimate these results. The synthetic model has one main advantage in this situation in that schools in this sample violate the parallel trends assumption in the pre-treatment period. However, the synthetic control model assumes that there is one treated group at one time point. One solution is to [average the effect obtained by the synthetic control]( https://www.mitpressjournals.org/doi/pdf/10.1162/REST_a_00413) across a number of comparative case studies to estimate an average treatment effect. Built in [cross-validation and bootstrapping](https://www.cambridge.org/core/journals/political-analysis/article/generalized-synthetic-control-method-causal-inference-with-interactive-fixed-effects-models/B63A8BD7C239DD4141C67DA10CD0E4F3) can be used to generate standard errors. Conceptually, these modifications are similar to defining a [differences-in-differences model with varied treatment timing](https://www.nber.org/papers/w25018). 

To estimate this model, I use a five-year quarterly panel of employment records for teachers in Chicago Public Schools (CPS) between academic years 2013-14 and 2017-18. I supplement these data with significant information on pretreatment trends including yearly school-level teacher survey data on school administrations and teacher relationships, student achievement data, student attendance data, and discipline reporting to inform the creation of the synthetic control. Due to the granularity of teacher employment data, effects of principal separation can be detected within the same school-year. Since the effects of teacher attrition on student performance are well studied and are known to be negative, teacher attrition can proxy for the costs of principal separation on student learning and be readily quantified into an average cost for school districts. I restrict this sample only to schools that were not entered into district management during the study duration.

## Results
I find that there is a small but significant decrease of 0.8 percentage points in teacher retention from principal separation. In the quarter following a principal separation, this rises to 2.8 percentage points, an increase of approximately 14 percent over average pretreatment period teacher attrition in treatment schools. These results suggest a relevant policy effect of management changes on teacher retention that should be studied further. However, concerns about endogeneity and external validity remain relevant in this context, as more granular employment, firing decision, and individual student retention data are available. In addition, potentially confounding changes in school-level budgets cannot be observed. Nonetheless, I find that these results are robust to a variety of restrictions based on school management structures. All results in the quarter following a principal separation are statistically significant at the p < 0.01 level.

<img src="https://github.com/m-rosenbaum/Teacher-Mobility/blob/master/08_figures/sc_noaoi_all.png" alt="Synthetic control estimates of teacher mobility" width="800"/>
