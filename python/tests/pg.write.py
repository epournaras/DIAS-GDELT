
import psycopg2 # PostgreSQL

import time

# constants
sql_template = """INSERT INTO gdelt(dt,peer,globaleventid,sqldate,ActionGeo_CountryCode,AvgTone) 
    VALUES(%s,%s,%s,%s,%s,%s)"""

current_time = time.localtime()

current_time_str = time.strftime('%Y-%m-%d %H:%M:%S', current_time)
print('current_time_str : ',current_time_str)

# PostgreSQL constants
db_name = 'dias'
db_host = 'localhost'
db_port = '5432'
db_user = 'postgres'
db_pwd = 'postgres'

# create connection string
conn_string = "dbname='" + db_name + "' user='" + db_user + "' host='" + db_host + "' port='" + db_port + "' password='" + db_pwd + "'"
print('conn_string : ' + conn_string)

# connect
connection = psycopg2.connect(conn_string)
assert connection is not None

cursor = connection.cursor()
assert cursor is not None

# get values to write
dt = current_time_str
peer = 1
globaleventid = 2212
sqldate = 20180219  # this is an integer
ActionGeo_CountryCode = 'SZ'
AvgTone = 0.56

# write
try:
    ret = cursor.execute(sql_template, (dt,peer,globaleventid,sqldate,ActionGeo_CountryCode,AvgTone,))
    print('ret : ', ret)

    connection.commit()

except (Exception, psycopg2.DatabaseError) as error:
        print(error)

finally:
    # disconnect
    cursor.close()
    connection.close()

