###############################################################################
## Title: 04b_gynth.R
##
## Purpose: Run synthetic control specification and save figures and tables
##
## Inputs: ${clean}03b_panel_long.csv"
##
## Outputs: $(figures)sc_all_att.png
##          ${figures}sc_all_tca.png
##          ${figures}sc_noaoi_att.png
##          $(figures)sc_noaoi_tca.png
##
## Programmer:  Michael Rosenbaum
##
## Created:     11/28/2018
###############################################################################
# 1. Load data
# 2. Synth Specifications
# 3. Save objects


# Clear
    if(exists("masterfile_run") == "FALSE"){
        rm(list = ls())
    }

# install and load packages
    install  <- FALSE
    load <- TRUE
    package_list <- c('gsynth','tidyverse')
    if(install){install.packages(package_list, repos='http://cran.us.r-project.org')}
    if(load){lapply(package_list, library, character.only = TRUE)}
    rm(load, install, package_list)


#############################
# Load and inspect data
#############################
# Load Data
# Inspect using PanelView

## Load Data
    cps <- read.csv("C:/Users/Michael Rosenbaum/Documents/Coding/Teacher-Mobility/05_clean/03b_panel_long.csv")

## Generate restricted sample
    cps_syn <- cps %>%
      filter(time != 1) %>% # remove pre-mobility year
      filter(time != 11) %>% # filter out panel year without correct matching
      mutate(time = ifelse(time > 11, time - 2, time-1)) %>% # hacky workaround for synth to calculate
      select(-newtrt_firstyear, -newtrt_lastyear, -pull_date)


## Speicifcation
    ## Generate specifications that take out all combinations of specially
    ## manage schools. This incldues ISP, OS4, AUSL turnarounds. These will
    ## serve as robustness checks. 
    
    # Order variables
    cps_syn_full <- cps_syn %>%
      select(-any_ausl, -any_os4, -any_isp, -network, -year)

    # Generate restrictions
    cps_syn_noa <- filter(cps_syn, any_ausl != 1) %>%
      select(-any_ausl, -any_os4, -any_isp, -network, -year)
    cps_syn_noo <- filter(cps_syn, any_os4 != 1) %>%
      select(-any_ausl, -any_os4, -any_isp, -network, -year)
    cps_syn_noao <- filter(cps_syn, any_ausl != 1 & any_os4 != 1) %>%
      select(-any_ausl, -any_os4, -any_isp, -network, -year)
    cps_syn_noi <- filter(cps_syn, any_isp != 1) %>%
      select(-any_ausl, -any_os4, -any_isp, -network, -year)
    cps_syn_noaoi <- filter(cps_syn, any_ausl != 1 & any_os4 != 1 & any_isp != 1) %>%
      select(-any_ausl, -any_os4, -any_isp, -network, -year)



###############################
# Synth specifications
###############################
# All
# No AUSL
# No OS4 + AUSL
# No ISL
# No ISL + OS4 + AUSL


## All
    sc_all <- gsynth(p_mobility ~ sch_trt,
                     data = cps_syn_full,  index = c("schid","time"), min.T0 = 5, 
                     se = TRUE, inference = "nonparametric", r = c(0, 3), CV = TRUE, 
                     force = "unit", parallel = TRUE,  
                     nboots = 1000, seed = 302139) # random.org 1-999999

    # Save plots
    p <- plot(sc_all, main = "Estimated Average Treatment Effect")
    ggsave("C:/Users/Michael Rosenbaum/Documents/Coding/Teacher-Mobility/08_figures/sc_all_att.png", 
           plot = p, width = 7.5, height = 4, units = "in", dpi = 300)
    p <- plot(sc_all, type = "counterfactual", raw = "all",
         main = "Treated and Counterfactual Averages")
    ggsave("C:/Users/Michael Rosenbaum/Documents/Coding/Teacher-Mobility/08_figures/sc_all_tca.png", 
           plot = p, width = 7.5, height = 4, units = "in", dpi = 300)

## No AUSL
    sc_noa <- gsynth(p_mobility ~ sch_trt,
                     data = cps_syn_noa,  index = c("schid","time"), min.T0 = 5, 
                     se = TRUE, inference = "nonparametric", r = c(0, 3), CV = TRUE, 
                     force = "unit", parallel = TRUE,  
                     nboots = 1000, seed = 108014) # random.org 1-999999

## No OS4
    sc_noo <- gsynth(p_mobility ~ sch_trt,
                     data = cps_syn_noo,  index = c("schid","time"), min.T0 = 5, 
                     se = TRUE, inference = "nonparametric", r = c(0, 3), CV = TRUE, 
                     force = "unit", parallel = TRUE,  
                     nboots = 1000, seed = 639555) # random.org 1-999999

## No OS4 + AUSL
    sc_noao <- gsynth(p_mobility ~ sch_trt,
                     data = cps_syn_noao,  index = c("schid","time"), min.T0 = 5, 
                     se = TRUE, inference = "nonparametric", r = c(0, 3), CV = TRUE, 
                     force = "unit", parallel = TRUE,  
                     nboots = 1000, seed = 690408)

## No ISP
    sc_noi <- gsynth(p_mobility ~ sch_trt,
                      data = cps_syn_noi,  index = c("schid","time"), min.T0 = 5, 
                      se = TRUE, inference = "nonparametric", r = c(0, 3), CV = TRUE, 
                      force = "unit", parallel = TRUE,  
                      nboots = 1000, seed = 67992) # random.org 1-999999


## No OS4 + AUSL + ISP
    sc_noaoi <- gsynth(p_mobility ~ sch_trt,
                     data = cps_syn_noaoi,  index = c("schid","time"), min.T0 = 5, 
                     se = TRUE, inference = "nonparametric", r = c(0, 3), CV = TRUE, 
                     force = "unit", parallel = TRUE,  
                     nboots = 1000, seed = 218130)

    # Save plots
    p <- plot(sc_noaoi, main = "Estimated Average Treatment Effect: No AUSL, OS4, ISP")
        ggsave("C:/Users/Michael Rosenbaum/Documents/Coding/Teacher-Mobility/08_figures/sc_noaoi_tca.png", 
        plot = p, width = 7.5, height = 4, units = "in", dpi = 300)
    p <-plot(sc_noaoi, type = "counterfactual", raw = "all",
        main = "Treated and Counterfactual Averages: No AUSL, OS4, ISP")
    ggsave("C:/Users/Michael Rosenbaum/Documents/Coding/Teacher-Mobility/08_figures/sc_noaoi_all.png", 
        plot = p, width = 7.5, height = 4, units = "in", dpi = 300)


## print for table as export to latex for multiple models doesn't seem to be intuitive.
    print(sc_all)
    print(sc_noa)
    print(sc_noo)
    print(sc_noao)
    print(sc_noi)
    print(sc_noaoi)

## EOF ##
