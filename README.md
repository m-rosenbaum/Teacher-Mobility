FIX TeX cites
Add figure


# Teacher-Mobility

This repo contains a series of scripts that collect and analyze data to calculate the approximate cost of a principal separation in Chicago Public Schools on teacher attrition between AY2013 & AY2019. To do so, it scrapes a variety of school-level data, creates a teacher employment panel, and then analyzes these data using a synthetic control model.

## Summary
In the US, teacher attrition imposes substantive academic costs on students and financial costs on school districts. Changes in school management may change teacher employment behavior. I use a 5-year quarterly panel of teacher employment data from Chicago Public Schools and a synthetic control model to estimate the effect of principal separation on teacher attrition. I find that principal separation is associated with an increase in the rate of teacher attrition in the following quarter by 2.7 percentage points, or 14 percent. This has implications for school management policy that affect school leadership retention. These types of turnaround policies may exacerbate teacher attrition, and therefore costs, for schools serving low-income communities.

## Introduction 
Although school buildings persist in neighborhoods for decades, urban schools have close to 100% turnover of staff and students—not including promotion—within 5 years \cite{allensworth_schools_2009}. Significant educational efforts are made to address student out-mobility, but teacher attrition receives less policy and media attention. This is a surprise given the financial costs to schools. In Illinois, the direct cost of teacher separations for schools was estimated at $188 million during the 2004 school year (in 2018 dollars) \cite{alliance_for_excellent_education_teacher_2005}. This cost rises to around $3.5 billion nationally. Teacher attrition is not only a financial cost. Although there is still a debate about what drives student learning, interruptions in instruction make meaningful differences in educational achievement of students \cite{hanushek_chapter_2006}. Current policy does not correct for these costs, nor costs shouldered by students in schools with high teacher mobility.

Given these costs, teacher retention is often a major concern for principals. In many districts, principals are directly responsible for teacher hiring, management, and control of instructional strategy. In many ways, principals are the central management authority for teachers. Principal quality accounts for approximately half of the difference in administrative quality between schools due to the creation of long-term strategy \cite{bloom_does_2014}. Principals play a central role in teacher retention as they serve a management and hiring function. It's possible that principal separation could have corresponding effects on teacher retention.

## Data and Methods
Estimating the costs of principal separations on teacher retention is a challenge for causal identification with available public data. Data availability poses one problem, teacher employment records are reported yearly or quarterly depending on the district. A more serious problem is lack of pseudo-random variation in principal separations: principal contracts are public record and usually administered by school districts. Chicago provides an interesting case study due to high degrees of local control of principal hiring and firing – local school councils (LSCs) have sole control outside of select circumstances. Therefore, this allows individual schools to determine hiring and firing decisions, and provides substantive variation in principal employment within a consistent policy environment and salary schedule. 

To estimate costs of principal changes, I rely on the synthetic control method introduced by Abadie and Gardeazabal to study these results \cite{abadie_economic_2003}. However, the synthetic control model assumes that there is one treated group at one time point. To respond to this methodological challenge, I follow Cavallo et. al. and Xu to apply a synthetic control model that can estimate a counterfactual for each treated unit in each time period \cite{cavallo_catastrophic_2013, xu_generalized_2017}. This can be understood similar to the differences-in-differences framework, where treatment timing is varied. 

I use a five-year quarterly panel of employment records for teachers in Chicago Public Schools (CPS) between academic years 2013-14 and 2017-18 to estimate effects on teacher mobility. I supplement these data with significant information on pretreatment trends including yearly school-level teacher survey data on school administrations and teacher relationships, student achievement data, student attendance data, and discipline reporting to inform the creation of the synthetic control. Due to the granularity of teacher employment data, effects of principal separation can be detected within the same school-year. Since the effects of teacher attrition on student performance are well studied and are known to be negative, teacher attrition can proxy for the costs of principal separation on student learning. 

## Results
I find that there is a small but significant decrease of 0.8 percentage points in teacher retention from principal separation. In the quarter after the principal leaves, this rises to 2.8 percentage points, an increase of approximately 14 percent over average pretreatment period teacher attrition in treatment schools. These results suggest a relevant policy effect of management changes on teacher retention that should be studied further. However, concerns about endogeneity and external validity remain relevant in this context, as more granular employment, firing decision, and individual student retention data are available. In addition, potentially confounding changes in school-level budgets cannot be observed. Nonetheless, I find that these results are robust to the inclusion of schools with a variety of possible CPS management structures and are statistically significant at the p < 0.01 level when compared to a bootstrapped sample of untreated schools.
