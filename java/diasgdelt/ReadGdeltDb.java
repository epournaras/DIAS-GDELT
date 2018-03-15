package diasgdelt;

import java.io.IOException;
import java.nio.file.Files;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Queue;
import java.util.LinkedList;


public class ReadGdeltDb {

    private static Connection connection = null;
    
    private static void sqlExecute( String sql )
    {
        try 
        {
            Statement       statement = connection.createStatement();
            
            //System.out.printf( "inserting record..." );
            statement.execute(sql);
            //System.out.printf( "ok\n" );
            
            statement.close();
              
        } 
        catch (SQLException e1) 
        {
            System.out.printf( "sqlExecute: Error executing statement : %s\n", e1 );
            System.out.printf( "%s\n\n", sql );
        
        }
    }
    
    private static boolean connectDatabase(String database)
    {
        // connect to PostgreSQL
        try
        {
            // dynamically load org.postgresql.Driver 
            Class.forName("org.postgresql.Driver");
            String url = "jdbc:postgresql://localhost/" + database;
            connection = DriverManager.getConnection(url,"postgres", "postgres");
            
         }
        catch (ClassNotFoundException e)
        {
          e.printStackTrace();
          connection = null;
         
        }
        catch (SQLException e)
        {
          e.printStackTrace();
          connection = null;
          
        }
        
        if( connection == null )
            System.out.printf( "Unable to connect to database\n" );
        else
            System.out.printf( "Connected to database\n" );
        
        
        return (connection == null ? false : true );
    }
    
    private static double[] computePossibleStates(Queue<Double> queue, int numberPossibleStates)
    {
    	double 	[]possibleStates = new double[numberPossibleStates];
    			
    	double	[]values = new double[queue.size()];	
    	
    	double 	min = 100.0,
    			max = -100.0;

    	int		counter = 0;
    	
    	while( !queue.isEmpty())
    	{
    		final double value = queue.poll();
    		values[counter++] = value;
    		
    		max = Math.max(max, value);
    		min = Math.min(min, value);
    	}
    	
    	System.out.printf("--- computePossibleStates ---\n" );
    	
    	
    	System.out.printf("min : %f\n", min );
    	System.out.printf("max : %f\n", max );
    	System.out.printf("counter : %d\n", counter );
    	
    	possibleStates[0] = min;
    	for( int j = 1; j < numberPossibleStates; j++ )
    		possibleStates[j] = possibleStates[j-1] + (max-min) / (double)(numberPossibleStates - 1.0);
    			
    	
    	return possibleStates;
    	
    }
    
    public static void main(String[] args) throws SQLException, IOException 
    {
        System.out.printf("Test Reading values from GDELT database (2018-03-04)\n" );
        
        final int			possibleStatesSampleSize = 1000,
        					numberPossibleStates = 9;
        
        System.out.printf("possibleStatesSampleSize : %d\n", possibleStatesSampleSize );
        System.out.printf("numberPossibleStates : %d\n", numberPossibleStates );
        
        final String        database = "dias";
        
        if( !connectDatabase(database))
        {
            System.out.printf( "Failed to connect to database\n");
            return;
        }
        
        // Read some data.
        PreparedStatement pst = connection.prepareStatement("SELECT * FROM gdelt WHERE peer = 1 ORDER BY globaleventid DESC LIMIT 5000");
        ResultSet rs = pst.executeQuery();
        
        // Reading from database
        Queue<Double>			queueValues = new LinkedList();
        
        while (rs.next()) {
        	final int 		db_seq_id = rs.getInt("seq_id"),
        					sqlDate = rs.getInt("sqldate"),
        					epoch = rs.getInt("epoch"),
        					peer = rs.getInt("peer"),
        					globaleventid = rs.getInt("globaleventid");
        	
        	final String 	dt = rs.getString( "dt" ),
        					actiongeo_countrycode = rs.getString( "actiongeo_countrycode" );
        	
        	final double 	avgtone = rs.getDouble("avgtone");
        	
            System.out.print(db_seq_id + " ");
            System.out.print(sqlDate+ " ");
            System.out.print(epoch + " ");
            System.out.print(peer + " ");
            System.out.print(globaleventid + " ");
            System.out.print(dt + " ");
            System.out.print(actiongeo_countrycode + " ");
            System.out.print(avgtone + " ");
            System.out.println();
            
            // add to queue
            queueValues.add( avgtone );
            
            // compute possible states
            if( queueValues.size() == possibleStatesSampleSize)
            {
            	double []possibleStates = computePossibleStates(queueValues, numberPossibleStates);
            	
            	System.out.println("possibleStates:" );
            	for( double j:possibleStates )
            		System.out.printf("%f ", j );
            	
            	System.out.println();
            	
            	queueValues.clear();
            	
            }
            
//         
        }

        connection.close();
        System.out.printf( "Disconnected from database\n" );
       
    }
}
