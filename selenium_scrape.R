# Most of the code I used below was found at this website
#https://stackoverflow.com/questions/50310595/data-scraping-in-r

library(RSelenium) 
library(rvest)
library(stringi)
library(knitr)


# helper functions ---------------------------

click_el <- function(remDr, el) {
  remDr$executeScript("arguments[0].click();", args = list(el))
}

# wrapper around findElement()
find_el <- function(remDr, xpath) {
  remDr$findElement("xpath", xpath)
}

# check if an element exists on the dom
el_exists <- function(remDr, xpath) {
  maybe_el <- read_html(remDr$getPageSource()[[1]]) %>%
    xml_find_first(xpath = xpath)
  length(maybe_el) != 0
}

# try to click on a element if it exists
click_if_exists <- function(remDr, xpath) {
  if (el_exists(remDr, xpath)) {
    suppressMessages({
      try({
        el <- find_el(remDr, xpath)
        el$clickElement()
      }, silent = TRUE
      )
    })
  }
}

# close google adds so they don't get in the way of clicking other elements
maybe_close_ads <- function(remDr) {
  click_if_exists(remDr, '//a[@id="advertClose" and @class="closeBtn"]')
}

# click on button that requires we accept cookies
maybe_accept_cookies <- function(remDr) {
  click_if_exists(remDr, "//div[@class='btn-primary cookies-notice-accept']")
}

# parse the data table you're interested in
get_tbl <- function(remDr) {
  read_html(remDr$getPageSource()[[1]]) %>% 
    html_nodes("table") %>% 
    .[[1]] %>% 
    html_table()
}

# actual execution ---------------------------

#RSelenium::startServer()
remDr <- remoteDriver(remoteServerAddr = "localhost", port = 4445L, browserName = "firefox")
remDr$open()

remDr$navigate("https://www.premierleague.com/stats/top/players/total_keeper_sweeper?po=GOALKEEPER")

# close adds
maybe_close_ads(remDr)
Sys.sleep(3)

# the seasons to iterate over
start <- 2015:2015
seasons <- paste0(start, "/", substr(start + 1, 3, 4))

# list to hold each season's data
out_list <- vector("list", length(seasons))
names(out_list) <- seasons

for (season in seasons) {
  
  maybe_close_ads(remDr)
  
  
  cur_season <- find_el(
    remDr, '//div[@class="current" and @data-dropdown-current="FOOTBALL_COMPSEASON" and @role="button"]'
  )
  click_el(remDr, cur_season)
  Sys.sleep(3)
  
 #select the season of interest
  xpath <- sprintf(
    '//ul[@data-dropdown-list="FOOTBALL_COMPSEASON"]/li[@data-option-name="%s"]', 
    season
  )
  season_lnk <- find_el(remDr, xpath)
  click_el(remDr, season_lnk)
  Sys.sleep(3)
  
  # parse the table shown on the first page
  tbl <- get_tbl(remDr)
  
  # iterate over all additional pages 
  nxt_page_act <- '//div[@class="paginationBtn paginationNextContainer"]'
  nxt_page_inact <- '//div[@class="paginationBtn paginationNextContainer inactive"]'
  
  while (!el_exists(remDr, nxt_page_inact)) {
    
    maybe_close_ads(remDr)
    maybe_accept_cookies(remDr)
    
    remDr$maxWindowSize()
    btn <- find_el(remDr, nxt_page_act)
    click_el(remDr, btn) # click "next button"
    
    maybe_accept_cookies(remDr)
    new_tbl <- get_tbl(remDr)
    tbl <- rbind(tbl, new_tbl)
    cat(".")
    Sys.sleep(2)
  }
  
  # put this season's data into the output list
  out_list[[season]] <- tbl
  print(season)
}

lapply(tbl, function(x) write.table( data.frame(x), 
            '2015-2016_KeeperSweeper.csv'  , append= T, sep=',' ))

print(tbl)
print(season)
