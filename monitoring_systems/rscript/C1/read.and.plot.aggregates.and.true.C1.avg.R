# read.dias.aggregates.R
# connects to a PostgreSQL database that contains the real-time DIAS data and reads aggreaets

# edward gaere | 2018-01-26

# required external variables
db.host <- 'ip.of.remote.server' #TODO: add server ip

db.schema <- 'dias'

diasNetworkId <- 0

source_table <- 'aggregation_event'

setwd("/home/edward/R/rscript/C1")

stopifnot( sum(ls() == 'db.host') == 1 )
stopifnot( sum(ls() == 'db.schema') == 1 )
stopifnot( sum(ls() == 'diasNetworkId') == 1 )
stopifnot( sum(ls() == 'source_table') == 1 )

print(sprintf('db.host : %s', db.host))
print(sprintf('diasNetworkId : %s', diasNetworkId))
print(sprintf('source_table : %s', source_table))

# include
library(dplyr) # install.packages( 'dplyPerr')
library("RPostgreSQL")#install.packages("RPostgreSQL")
#install.packages("RPostgreSQL")

# constants
now <- Sys.time()

# database settings
db.port <- 5432
db.user <- '' #TODO: POSTGRES USERNAME HERE
db.pwd <- ''  #TODO: POSTGRES PASSWORD HERE

# dataset settings
#last.epoch <- 1558353740 # set to -1 to read all rows
last.epoch <- -1

# plot settings
db.rows <- 50000 # number of (most recent) rows to retrieve from database



# files + folders

# create output dataframe
df.dias.all <- data.frame()

# loads the PostgreSQL driver
psql.drv <- dbDriver("PostgreSQL")
# creates a connection to the postgres database
# note that "con" will be used later in each connection to the database
db.con <- dbConnect(psql.drv, dbname = db.schema,
                    host = db.host, port = db.port,
                    user = db.user, password = db.pwd)


# read data for all peers
#sql <- paste('SELECT * FROM aggregation WHERE seq_id >= (SELECT MAX(seq_id) FROM aggregation) -', db.rows - 1, 'ORDER BY seq_id ASC');
#sql <- paste('SELECT * FROM aggregation WHERE network =', diasNetworkId, 'ORDER BY seq_id DESC', 'LIMIT', db.rows);
#sql <- paste('SELECT * FROM aggregation_plot WHERE network =', diasNetworkId);
#sql <- paste('SELECT * FROM aggregation_plot WHERE epoch BETWEEN 1534338941 AND 1534338950 AND  network =', diasNetworkId);

# mod eag 2018-09-11 - use the event-based source
#sql <- paste('SELECT * FROM',source_table,'WHERE network =', diasNetworkId);

# mod eag 2018-09-11 - allow user to set a limit
sql <- ''
if( last.epoch == -1 ){
  if( db.rows == -1 ){
    sql <- paste('SELECT * FROM',source_table,'WHERE network =', diasNetworkId, 'ORDER BY seq_id ASC');
  }
  else{
    sql <- paste('SELECT * FROM',source_table,'WHERE network =', diasNetworkId, 'AND seq_id >= (SELECT MAX(seq_id) FROM',source_table, ') -', db.rows - 1, 'ORDER BY seq_id ASC');
  }
}else{
  sql <- paste('SELECT * FROM',source_table,'WHERE network =', diasNetworkId, 'AND seq_id >= (SELECT MAX(seq_id) FROM',source_table, ' WHERE epoch <=', last.epoch,') -', db.rows - 1, 'ORDER BY seq_id ASC');
  
}

print(sql)

print( 'reading data')
df.dias.all <- dbGetQuery(db.con, sql)
nrows <- nrow(df.dias.all)
print(sprintf( '#rows : %s', nrows))
print(sprintf( 'epoch range : %s - %s', min(df.dias.all$epoch), max(df.dias.all$epoch) ))
print( 'completed')

# important to disconnect as a maximum of 16 open connections
dbDisconnect(db.con)

# plot.avg.db.R
# plot the DIAS aggreated average of each peer against the true average
# the true average is computed by taking the average of the states of the active peers at each epoch
# requires data to have been read before

# edward gaere | 2018-01-26

# verify source data frame exists
stopifnot( sum(ls() == 'df.dias.all') == 1 )

# include
library(dplyr) # install.packages( 'dplyr')

# constants
now <- Sys.time()
series <- 'Average'

# check there is data in the input data.frame
nrows <- nrow(df.dias.all)
print(sprintf( '#rows : %s', nrows))
stopifnot( nrows > 0 )

# get data range
dt.range <- range(df.dias.all$dt)
dt.range.str <- sprintf( '%s to %s', dt.range[1], dt.range[2] )
print(sprintf( 'dt.range : %s', dt.range.str))

#View(df.dias.all)

# get peers in the sample
peers <- sort(unique(df.dias.all$peer))
num.peers <- length(peers)
print(sprintf( '#num.peers : %s', num.peers))


# align all measurements to the same grid, since some
# peers leave the network and don't generate measurements when they have left
# scaffolding: seq
min.epoch <- min( df.dias.all$epoch )
max.epoch <- max( df.dias.all$epoch )
num.epochs <- max.epoch - min.epoch + 1

# need to show complete epochs! therefore don't show the very last one
# this still does assume that each peer has provided an update for MAX(epoch) - 1
epoch.rebase <- seq( 1, num.epochs - 2 )

df.scaffolding <- data.frame( epoch = seq( min.epoch + 1, max.epoch - 1),
                              epoch.rebase = epoch.rebase )


  
# compute baseline; this is the true mean for each epoch
# some epochs may not contain an observation for all peers, so the sum used as the baseline will be incorrect
# simply ignore these rows
# modified eag 2018-01-15
df.dias.all %>%
  filter (active == TRUE ) %>%
  group_by(epoch) %>%
  summarize( baseline = mean(state) , cnt_obs = n() ) -> df.baseline

  #View(df.baseline)
  
  
  # plot baseline
  df.scaffolding %>% left_join(df.baseline, by = 'epoch') -> df.scaffolding.baseline
  #View(df.scaffolding.baseline)
  
  
  # ylim: range for the y-axis
  # show exact range
  ylim <- range(df.dias.all$avg, na.rm = TRUE)
  
  # expand range to the nearest integers
  #r.min <- min(df.dias.all$avg, na.rm = TRUE)
  #ylim <- c( floor(r.min), floor(r.min) + 1)
  
  plot(df.scaffolding.baseline$epoch.rebase,
       df.scaffolding.baseline$baseline,
       xlab = paste( 'Epoch (rebased, starts at ', min.epoch,')', sep = '' ),
       ylab = series,
       ylim = ylim,
       main = paste( paste(db.host,'|', 'network',diasNetworkId,'|',series,'over',num.peers,'peers'),paste('last',nrows,'of',db.rows,'rows'),dt.range.str, sep = '\n')
       )
  
  # add peers
  #peer.id <- 1
  for( peer.id in peers )
  {
    df.dias.all %>% filter( peer == peer.id ) -> df.this.peer
    df.scaffolding %>% left_join(df.this.peer, by = 'epoch') -> df.scaffolding.peer
    
    points( df.scaffolding.peer$epoch.rebase,
            df.scaffolding.peer$avg,
            pch = 16,
            cex = 0.5,
            col = 4
            )
  }
  
  # replot the baseline, this time using a line
  lines(df.scaffolding.baseline$epoch.rebase,
       df.scaffolding.baseline$baseline,
       col = 'red',
       lwd = 1.5
  )
  
  
  # legend
  legend("bottomleft", c('baseline'), col=c('red'), lwd=1.5)
  
  # View data
  #View(df.dias.all)



