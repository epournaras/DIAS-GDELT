# gdelt.timeline.R
# test reading GDELT data from R; plot a bar chart from summary data
# GDELT 2.0 is stored in Google BiqQuery

# edward | 2018-01-31 

#install.packages('bigrquery')
library(bigrquery)
library(dplyr)

# constants
project <- 'quantum-tableau-wdc'  # put your projectID here; obtained from the Google Developer Console

path <- '/Users/edward/Dropbox/eth/coss/Gdelt'

#query.filename <- 'tone.ch.timeline.sql'
#query.filename <- 'goldstein.ch.timeline.sql'

query.filename <- 'tone.gr.timeline.sql'

now <- Sys.time()

# debug
use.cache <- FALSE

view.df <- FALSE


# files + folders
setwd(path)
stopifnot( file.exists(query.filename))


# read SQL from file
sql <- paste( readLines( query.filename ), collapse = ' ')

# run query
# importantü the first time this is run it will require an authentication (will open a webpage)
if( !use.cache | sum(ls() == 'df') != 1 )
{
  print('executing query')
  df <- query_exec(sql, project)
  nrows <- nrow(df)
  print(sprintf('data retrieved : %s', nrows))
}else
{
  print('using cached data')
}


# convert sqldate to an R date
df$dt <- strptime( df$SQLDATE, "%Y%m%d" )

# debug
if( view.df )
  View(df)

# plot
ylim.all <- c( range(df$avg_metric), range(df$min_metric), range(df$max_metric) )
ylim <- c( min(ylim.all), max(ylim.all) )

plot( df$dt, 
      df$avg_metric, 
      type = 'l', 
      main = paste('GDELT 2.0', query.filename, now, sep=' | '),
      ylim = ylim,
      )

lines( df$dt, df$min_metric, col= 2)
lines( df$dt, df$max_metric, col= 3)

legend('topleft', legend = c('avg', 'min', 'max'), col=seq(1,3), pch=1)
