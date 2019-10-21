# NOT MY CODE, Found this code at 
# https://stackoverflow.com/questions/40616357/how-to-scrape-tables-inside-a-comment-tag-in-html-with-r


library(stringi)
library(knitr)
library(rvest)


any_version_html <- function(x){
  XML::htmlParse(x)
}
a <- 'https://fbref.com/en/comps/9/1526/stats/2016-2017-Premier-League-Stats'
b <- readLines(a)
c <- paste0(b, collapse = "")
d <- as.character(unlist(stri_extract_all_regex(c, '<table(.*?)/table>', omit_no_match = T, simplify = T)))

e <- lapply(d, function(.d) html_table(read_html(.d))[[1]])


kable(summary(e),'rst')


kable(e[[1]],'rst')

write(d, file = "2016-2017_player.html")

my_data<-html_table(read_html("2016-2017.html")) 

my_data



lapply(my_data, function(x) write.table( data.frame(x), '2016-2017_player.csv'  , append= T, sep=',' ))

