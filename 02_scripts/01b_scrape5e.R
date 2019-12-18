################################################################################
##  TITLE: 01b_scrape5e.R
##
##  PURPOSE: Scrapes 5Essentials survey data from the 5E website
##              
##  INPUTS: 
##  
##  OUTPUTS: ${raw}/1a_demos_2013_$endyear
##        
##  NOTES: C:/Users/Michael Rosenbaum/Downloads/Panel_5es_2012_2018.csv
##
##  AUTHOR: Michael Rosenbaum 
##
##  CREATED: 9/1/17 
################################################################################
# 1. Define functions
# 2. Scrape
# 3. Append and clear


# Clear if no master
    if(exists("masterfile_run") == "FALSE"){
        rm(list = ls())
    }

# install and load packages
    install  <- FALSE
    load <- TRUE
    package_list <- c('rvest','tidyverse',"RCurl")
    if(install){install.packages(package_list, repos='http://cran.us.r-project.org')}
    if(load){lapply(package_list, library, character.only = TRUE)}
    rm(load, install, package_list)



#######################################
# 1. Functions
#######################################
# A. extract_urls -- returns html
# B. extract_teach_lte2014 -- scrapes 5Es before 2014
# C. extract_5eval -- scrapes individual 5E value


## A. extract URL -- get list of all schools linked in the 5E sites
    extract_urls <- function(year){
        
        #Create url to search by year
        url <- paste0("https://www.5-essentials.org/classic/cps/", year, "/schools/",)
      
        # Add Url
        add <- read_html(url)

        # Create data frame of schools on the classic site school list
        url_l <-
          add %>%
          html_nodes(".firstcol a") %>%
          html_attr('href') %>%
          as_data_frame()

        # Return list to pass to other functions
        return(url_l)
    }

    
## B. extract teach_lte2014 -- Scrapes 5Es
    extract_teach <- function(url_use, extract_list){

        # Get URL
        url_use2 <- paste0("https://www.5-essentials.org/",url_use)

        # Create measures and name
        l_5e <- lapply(extract_list, extract_5eval, url2 = url_use2) %>%
        as.data.frame()
        colnames(l_5e) <- (extract_list)

        # Create final 5e by year list
        school_5e <- l_5e %>%
        mutate(sid=str_extract(url_use,"[0-9]{6}"), 
               year=str_extract(url_use, "[2][0][1][0-9]{1}"))

        return(school_5e)
    }


## C. extract_5eval -- Takes the value in the 5E table on the site
    extract_5eval <- function(measure, url2){
      
      # Take measure and find the measure page
      add2 <- paste0(url2,"measures/",measure,"/") %>%
        read_html()
      
      # Scrape value from the measure page
      e_5e <- 
        add2 %>%
        html_node(".tree_item_score") %>%
        html_text() %>%
        as.integer()
      return(e_5e)
    }



#######################################
# 2. Extract URLs and measures
#######################################
# A. Establish lists
# B. Run functions 
# C. Clean data

## 5Es are constructed by taking a simple avergae of Rasch-scaled 
## components. These subcomponents were renormed in 2015, and have
## different identifiers on the 5E site. This only requires
## 5Es from the teacher suveys so only 8/9 subcomponents need to be
## scraped from each school-year.

### Post-2014
## Effective Leaders
    # Stem https://cps.5-essentials.org/2017/s
    # /measures/ins3/ // instrutional leadership
    # /measures/inf3/ // teacher influence
    # /measures/pgmc/ // program coherence
    # /measures/trpr/ // teacher principal trust

## Teacher environment
    # URL Stem https://cps.5-essentials.org/2017/s
    # measures/colb/ // collabrative practice
    # measures/colr/ // collective responsibility
    # measures/qpd2/ // Quality PD
    # measures/scmt/ // School Commitment
    # measures/trte/ // Teacher-Teacher Trust

### Pre-2015
## Effective Leaders
    # URL Stem https://cps.5-essentials.org/2014/s/610229
    # /measures/ins3/ // instrutional leadership
    # /measures/inf3/ // teacher influence
    # /measures/pgmc/ // program coherence
    # /measures/trpr/ // teacher principal trust  
   
## Teacher environemnt
    # measures/colr/ // collective responsibility
    # measures/qpd2/ // Quality PD
    # measures/scmt/ // School Commitment
    # measures/trte/ // Teacher-Teacher Trust


## A. Create Lists
    # Create range of years
    endyear <- 2019 # placeholder for relative reference
    li_years <- seq(2013, endyear, by= 1)
   
    # Create list of 5Es
    # dif is first two
    li_5es_gt2014 <-  c("ins3", "inf3", "pgmc", "trpr","colb", "colr", "qpd2", "scmt",
        "trte")
    li_5es_lte2014 <- c("inst", "infl", "pgmc", "trpr","colb", "colr","qpd2","scmt",
        "trte")
  

##  B. RUn Scrape
  # Establish url list
  url_5e_all <- sapply(li_years, extract_urls) %>%
    unlist()
    
  # Extract 5e teacher measures
  measure_5e_all <- data.frame()

  for(i in url_5e_all){
    
    ## Check if scrape completed
    yr_tracker <- str_extract(i, "201[0-9]")
    if(!exists("yr_lagged")){yr_lagged <- yr_tracker} #Create variable if not existing
    
    # Check if file exists
    if(TRUE %in% (list.files("C:/Users/Michael Rosenbaum/Documents/Coding/Teacher-Mobility/01_Raw/5e/") == 
                  paste0("ay", yr_tracker,".csv"))){
        
        # Advance if scraped file exists
        next
    } 

    ## Scrape site
    # Scrape a tempfile of each school
    if(FALSE %in% url.exists(paste0("https://www.5-essentials.org/", i))){next} # skip if error to connect
    if(yr_tracker <= 2014){temp <- extract_teach(i, li_5es_lte2014)}
    if(yr_tracker > 2014){temp <- extract_teach(i, li_5es_gt2014)}

    temp <- temp %>% mutate(year = yr_tracker)

    # Attach to file
    measure_5e_all <- bind_rows(measure_5e_all, temp)
    
    # If file does not exist and new year save file
    if((yr_tracker != yr_lagged) | (i == url_5e_all[length(url_5e_all)])) {
      save <- filter(measure_5e_all, year == yr_tracker)
      write.csv(save, 
                paste0("C:/Users/Michael Rosenbaum/Documents/Coding/Teacher-Mobility/01_Raw/5e/ay",
                       yr_tracker,".csv")) 
      rm(save)
    }
    ## end if
    
    # Create lag for loop check
    yr_lagged <- yr_tracker
  }
  ## end for(i in url_5e_all)
  
  
  
#######################################
## 3. Clean Data
#######################################
# A. Load and append year-wise data
# B. Save file


## A. Load and append year-wise data
    # Define old sdata
    years <- list.files(path = "C:/Users/Michael Rosenbaum/Documents/Coding/Teacher-Mobility/01_raw/5e/", 
        pattern = ".csv$")


    #reading each file within the range and append them to create one file
    measure_5e_all <-  read.csv(paste0("C:/Users/Michael Rosenbaum/Documents/Coding/Teacher-Mobility/01_raw/5e/",
                                       years[1]))
    for(f in years[-1]) {
        temp <- read.csv(paste0("C:/Users/Michael Rosenbaum/Documents/Coding/Teacher-Mobility/01_raw/5e/",f))    
        measure_5e_all <- bind_rows(measure_5e_all, temp)  
    } 

    # Generate 5Es
    measure_5e_all <- measure_5e_all %>%
    rowwise() %>% 
    mutate(efle_5e = mean(c(inst, infl, ins3, inf3, pgmc, trpr), na.rm = T), 
           teen_5e = mean(c(colb, colr, qpd2, scmt, trte), na.rm = T))

## B. Save completed file
    # Save
    write.csv(measure_5e_all, file = 
        paste0("C:/Users/Michael Rosenbaum/Documents/Coding/Teacher-Mobility/01_raw/Panel_5es_2012_",
               endyear,".csv")) 


## EOF ##
