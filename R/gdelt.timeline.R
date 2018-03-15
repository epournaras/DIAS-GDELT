# gdelt.timeline.R
# show timelines for a single country, reading from the local PostgreSQL database
# edward | 2018-03-04

library(dplyr)
library("RPostgreSQL")#install.packages("RPostgreSQL")

# verify arguments
stopifnot( sum(ls() == 'db.host') == 1 )
stopifnot( sum(ls() == 'country') == 1 )

# constants
now <- Sys.time()
path <- '/Users/edward/Documents/workspace/DIAS-GDELT'
query <- 'tone.1country.timeline.sql'

query.filename <- paste(path,'R', 'sql',query,sep='/')

# database settings
db.schema <- 'dias'
db.port <- 5432
db.user <- 'postgres'
db.pwd <- 'postgres'
psql.drv <- dbDriver("PostgreSQL")

# plot settings
db.rows <- 5000 # number of (most recent) rows to retrieve from database

# debug
use.cache <- FALSE
view.df <- TRUE

# files + folders
setwd(path)
stopifnot( file.exists(query.filename))

# read SQL from file
sql.template <- paste( readLines( query.filename ), collapse = ' ')

# replace tokens
sql <- gsub( '<country>', toupper(country), sql.template )
sql <- gsub( '<num.rows>', db.rows, sql )


# run query
# importantü the first time this is run it will require an authentication (will open a webpage)
if( !use.cache | sum(ls() == 'df') != 1 )
{
  print('executing query')
  # creates a connection to the postgres database
  # note that "con" will be used later in each connection to the database
  db.con <- dbConnect(psql.drv, dbname = db.schema,
                      host = db.host, port = db.port,
                      user = db.user, password = db.pwd)
  
  
  df <- dbGetQuery(db.con, sql)
  
  nrows <- nrow(df)
  print(sprintf('data retrieved : %s', nrows))
  
  # important to disconnect as a maximum of 16 open connections
  dbDisconnect(db.con)
}else
{
  print('using cached data')
}

# debug
if( view.df )
  View(df)


# rebase global event id to 0
min.event.id <- min(df$globaleventid)
df %>% mutate( event.rebase = globaleventid - min.event.id) -> df.plot

# plot
plot( df.plot$event.rebase, 
      df.plot$avgtone, 
      type = 'l', 
      main = paste('GDELT 2.0', 'Avg Tone for Country', country, min(df$sqldate), max(df$sqldate), now, sep=' | '),
      xlab = paste( 'globaleventid \n (rebeased to', min.event.id,')' )
      )


legend('topleft', legend = country, col=1, pch=1)
