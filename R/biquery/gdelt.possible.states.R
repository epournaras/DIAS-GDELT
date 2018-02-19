# gdelt.possible.states.R
# compute possible states from  a GDELT timeseries
# GDELT 2.0 is stored in Google BiqQuery

# edward | 2018-0


library(bigrquery)  #install.packages('bigrquery')
library(dplyr)
library(cluster) #install.packages('cluster')

# constants
project <- 'quantum-tableau-wdc'  # put your projectID here; obtained from the Google Developer Console

path <- '/Users/edward/Dropbox/eth/coss/Gdelt'

query.filename <- 'tone.country.timeline.3months.sql'

now <- Sys.time()

# debug
use.cache <- FALSE

view.df <- FALSE

do.plot <- TRUE

k <- 5 # number of possible states

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
  colnames(df) <- tolower(colnames(df))
  print(sprintf('data retrieved : %s', nrows))
}else
{
  print('using cached data')
}


# convert sqldate to an R date
df$dt <- strptime( df$sqldate, "%Y%m%d" )


# debug
if( view.df )
  View(df)

# plot
if( do.plot )
{
  ylim.all <- c( range(df$avgtone) )
  ylim <- c( min(ylim.all), max(ylim.all) )

  plot( 
      df$avgtone, 
      type = 'l',
      pch = 0.1,
      lwd = 0.5,
      ylab = 'AvgTone',
      xlab = paste('Timeline (rebased', min(df$sqldate),')' ),
      main = paste('GDELT 2.0', 'AvgTone', query.filename, now, sep=' | '),
      ylim = ylim,
      col = 'grey'
      )
}
# TODO
# EM: Expectation Maximisation to determine number of clusters -> k

print(sprintf('k : %s', k))

# clustering
print('clustering')
clust <- pam(df$avgtone, k )

print('clustering completed')

# overlay the centroids onto the tlime
if( do.plot )
{
  points(df$avgtone[clust$clustering], 
       col= clust$clustering,
       lwd = 2
       )
  
  # legend
  legend( "bottomleft", legend = clust$medoids, col = 1:k, pch = 19)
  
}