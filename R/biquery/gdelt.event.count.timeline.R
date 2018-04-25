# gdelt.timeline.R
# test reading GDELT data from R; plot a bar chart from summary data
# GDELT 2.0 is stored in Google BiqQuery

# edward | 2018-01-31 

#install.packages('bigrquery')
library(bigrquery)
library(dplyr)

# constants
project <- 'quantum-tableau-wdc'  # put your projectID here; obtained from the Google Developer Console

path <- '/Users/edward/Documents/workspace/DIAS-GDELT/R/biquery'

#query.filename <- 'tone.ch.timeline.sql'
#query.filename <- 'goldstein.ch.timeline.sql'

query.filename <- 'event.count.sql'

now <- Sys.time()

# debug
use.cache <- FALSE

view.df <- TRUE


# files + folders1
setwd(path)
stopifnot( file.exists(query.filename))


# read SQL from file
sql <- paste( readLines( query.filename ), collapse = ' ')
print(sprintf('sql : %s',sql))

# run query
# importantü the first time this is run it will require an authentication (will open a webpage)
if( !use.cache | sum(ls() == 'df') != 1 )
{
  print('executing query')
  df <- query_exec(sql, project)
  nrows <- nrow(df)
  print(sprintf('data retrieved : %s', nrows))
  
  # debug
  if( view.df )
    View(df)
  
}else
{
  print('using cached data')
}


# convert sqldate to an R date
df$dt <- strptime( df$sqldate, "%Y%m%d" )


# plot
ylim <- range(df$cnt_events)

plot( df$dt, 
      df$cnt_events, 
      type = 'l', 
      main = paste('GDELT 2.0', query.filename, now, sep=' | '),
      ylim = ylim,
      )

lines( df$dt, df$cnt_events, col= 2)

legend('topleft', legend = c('avg', 'min', 'max'), col=seq(1,3), pch=1)
