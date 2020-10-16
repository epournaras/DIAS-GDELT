


#------------------------------------------------------------- step 1

# read.dias.aggregates.R
# connects to a PostgreSQL database that contains the real-time DIAS data and reads aggreaets

# edward gaere | 2018-01-26

# required external variables
db.host <- 'localhost'

db.schema <- 'dias'

diasNetworkId <- 0

source_table <- 'aggregation_event'


stopifnot( sum(ls() == 'db.host') == 1 )
stopifnot( sum(ls() == 'db.schema') == 1 )
stopifnot( sum(ls() == 'diasNetworkId') == 1 )
stopifnot( sum(ls() == 'source_table') == 1 )


setwd("/home/edward/R/rscript/C0")

print(getwd())
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
db.user <- ''
db.pwd <- ''

# dataset settings
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


#------------------------------------------------------------- step 2



# read.true.gdelt.sum.R
# connects to a PostgreSQL database that true values for the gdelt sum of events

# edward gaere | 2018-09-21

# required external variables


print(sprintf('db.host : %s', db.host))
stopifnot( sum(ls() == 'db.host') == 1 )
stopifnot( sum(ls() == 'db.schema') == 1 )
stopifnot( sum(ls() == 'diasNetworkId') == 1 )

print(sprintf('db.host : %s', db.host))
print(sprintf('diasNetworkId : %s', diasNetworkId))

# include
library(dplyr) # install.packages( 'dplyr')
library("RPostgreSQL")#install.packages("RPostgreSQL")
#install.packages("RPostgreSQL")

# constants
now <- Sys.time()

# plot settings
#db.rows <- 50000 # number of (most recent) rows to retrieve from database

# files + folders

# create output dataframe
df.true.gdelt.sum <- data.frame()

# loads the PostgreSQL driver
psql.drv <- dbDriver("PostgreSQL")
# creates a connection to the postgres database
# note that "con" will be used later in each connection to the database
db.con <- dbConnect(psql.drv, dbname = db.schema,
                    host = db.host, port = db.port,
                    user = db.user, password = db.pwd)


# read sum of events for all peers
sql <- 'SELECT epoch,SUM(eventcount) AS true_sum_events FROM gdeltv2c WHERE epoch is NOT NULL GROUP BY epoch ORDER BY epoch'

print( 'reading data')
df.true.gdelt.sum <- dbGetQuery(db.con, sql)
nrows <- nrow(df.true.gdelt.sum)
print(sprintf( '#rows : %s', nrows))
print( 'completed')

# important to disconnect as a maximum of 16 open connections
dbDisconnect(db.con)


#------------------------------------------------------------- step 3


# plot.sum.rrd.gdelt.R
# plot event based aggregates from DIAS, including the true sums from the raw GDELT data
# edward gaere | 2018-09-21

# verify source data frame exists
stopifnot( sum(ls() == 'df.dias.all') == 1 )
stopifnot( sum(ls() == 'df.true.gdelt.sum') == 1 )

# include
library(dplyr) # install.packages( 'dplyr')
library(tidyr) # spread

# constants
now <- Sys.time()
series <- 'Sum'

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
unique.epochs <- sort(unique(df.dias.all$epoch))

len.scaffolding <- length(unique.epochs)
print(sprintf('len.scaffolding : %s', len.scaffolding))

df.scaffolding <- data.frame( epoch = unique.epochs,
                              epoch.rebase = seq( 1, len.scaffolding) )

#View(df.scaffolding)

# compute average value of each peer at each epoch
# this is because in the event table, there can be many updates per epoch
df.peers <-
  df.dias.all %>%
  filter (active == TRUE ) %>%
  group_by(epoch, peer) %>%
  summarize( state = mean(state)
              ,avg = mean(avg)
              ,sum = mean(sum)
             ,cnt_obs = n()
             ) %>%
  arrange( epoch, peer )

#View(df.peers )

# prepare baseline
df.baseline <- data.frame( epoch = unique.epochs
                           ,epoch.rebase = seq( 1, len.scaffolding)
                           ,state = numeric(len.scaffolding)
                           ,sum = numeric(len.scaffolding)
                           ,cnt = numeric(len.scaffolding)
                           ,true_sum_events = numeric(len.scaffolding)

)



# ylim: range for the y-axis
# show exact range
ylim <- range(df.peers$sum, na.rm = TRUE)

# prepare output for website
# ouptut table contains 1 column per peer; to facilitate the construction of the output data.frame
# we created an unpivoted view first, and then unpivot(spread) before saving to database
# df.gdelt.web.plot.t
# edward | 2018-09-24
df.gdelt.web.plot.t <- data.frame( epoch = numeric()
                                   ,field = character()
                                   ,aggregate = numeric()
                                   ,stringsAsFactors = FALSE
                                   )

# plot each peer, one at a time
#peer.id <- 28
for( peer.id in peers )
{
  # get observations for this peer only
  df.this.peer <-
    df.peers %>%
    filter( peer == peer.id )

  #View(df.this.peer)

  # align to scaffolding
  df.plot <-
    df.scaffolding %>%
    left_join(df.this.peer, by = 'epoch' )

  #View(df.plot)

  if( peer.id == 1 )
  {
    plot(df.plot$epoch.rebase
        ,df.plot$sum
        ,xlab = paste( 'Epoch (rebased, starts at ', min.epoch,')', sep = '' )
        ,ylab = series
        ,ylim = ylim
        ,main = paste( paste(db.host,'|', 'network',diasNetworkId,'|',series,'over',num.peers,'peers'),paste('last',nrows,'of',db.rows,'rows'),dt.range.str, sep = '\n')
        ,pch = 16
        ,cex = 0.5
        ,col = 4
       )
  }
  else
  {
    # peer.id <- 2
    points( df.plot$epoch.rebase,
            df.plot$sum,
            pch = 16,
            cex = 0.5,
            col = 4
            )
  }


  # append to df.gdelt.web.plot.t
  df.gdelt.web.plot.t <- rbind( df.gdelt.web.plot.t,
                                data.frame( epoch = df.plot$epoch
                                            ,field = rep( sprintf('peer%s',peer.id), nrow(df.plot) )
                                            ,aggregate = df.plot$sum )
                                )


  # update baseline
  # first, fill missing values
  df.this.peer.fill <- df.plot
  for(i in 1:len.scaffolding)
  {
    if( is.na(df.this.peer.fill$state[i] ))
    {
      prev_value = 0.0
      if( i >= 2 )
      {
        prev_value = if_else( is.na(df.this.peer.fill$state[i-1]), 0.0, df.this.peer.fill$state[i-1])
      }
      df.this.peer.fill$state[i] = prev_value
    }

    if( is.na(df.this.peer.fill$sum[i] ))
    {
      prev_value = 0.0
      if( i >= 2 )
      {
        prev_value = if_else( is.na(df.this.peer.fill$sum[i-1]), 0.0, df.this.peer.fill$sum[i-1])
      }
      df.this.peer.fill$sum[i] = prev_value
    }
  }

  # update baseline
  df.baseline$state = df.baseline$state + df.this.peer.fill$state
  df.baseline$sum = df.baseline$sum + df.this.peer.fill$sum
  df.baseline$cnt = df.baseline$cnt + 1

  #View(df.this.peer.fill)
  #View(df.baseline)
  #stop()

}

# compte the true sum of raw values
r <- 0
print('computing true sum of raw values')
for( epoch_loop in df.baseline$epoch)
{
  r <- r + 1

  true.gdelt.sum <-
    df.true.gdelt.sum %>%
    filter( epoch <= epoch_loop) %>%
    arrange(desc(epoch)) %>%
    head(n=1) %>%
    select(true_sum_events) %>%
    as.numeric()

  #print(sprintf('%s: epoch : %s -> %s', r, epoch_loop, true.gdelt.sum))

  # save
  df.baseline$true_sum_events[r] <- true.gdelt.sum

}

# -----------------------
# plot true sum of events
# -----------------------

lines(df.baseline$epoch.rebase,
      df.baseline$true_sum_events,
      col = 'green',
      lwd = 1.5
)

# append to df.gdelt.web.plot.t
df.gdelt.web.plot.t <- rbind( df.gdelt.web.plot.t,
                              data.frame( epoch = df.baseline$epoch
                                          ,field = rep( 'true_sum_gdelt_events', nrow(df.baseline) )
                                          ,aggregate = df.baseline$true_sum_events ))

# -------------------------------
# plot the true sum of the states
# -------------------------------

lines(df.baseline$epoch.rebase,
      df.baseline$state,
      col = 'blue',
      lwd = 1.5
)

# append to df.gdelt.web.plot.t
df.gdelt.web.plot.t <- rbind( df.gdelt.web.plot.t,
                              data.frame( epoch = df.baseline$epoch
                                          ,field = rep( 'sum_selected_states', nrow(df.baseline) )
                                          ,aggregate = df.baseline$state ))


# ---------------------------------
# plot the average aggregated value
# ---------------------------------

df.baseline$agg_sum <- df.baseline$sum / df.baseline$cnt
lines(df.baseline$epoch.rebase,
      df.baseline$agg_sum,
      col = 'red',
      lwd = 1.5
)

# append to df.gdelt.web.plot.t
df.gdelt.web.plot.t <- rbind( df.gdelt.web.plot.t,
                              data.frame( epoch = df.baseline$epoch
                                          ,field = rep( 'dias_sum_selected_states', nrow(df.baseline) )
                                          ,aggregate = df.baseline$agg_sum ))




# legend
legend("bottomleft", c('True sum of GDELT events', 'Sum of selected states', 'DIAS sum'), col=c('green', 'blue', 'red'), lwd=1.5)

  # View data
  #View(df.dias.all)

