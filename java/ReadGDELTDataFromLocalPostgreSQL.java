import java.io.IOException;
import java.nio.file.Files;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.text.SimpleDateFormat;
import java.util.LinkedHashMap;
import java.util.LinkedList;
import java.util.Queue;

import com.fasterxml.jackson.core.JsonParseException;
import com.fasterxml.jackson.databind.JsonMappingException;
import com.fasterxml.jackson.databind.ObjectMapper;

public class ReadVizDb {

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
    
    public static void main(String[] args) throws SQLException, JsonParseException, JsonMappingException, IOException {
        System.out.printf("Test Visualization database (2018-02-14)\n" );
        
        final String        database = "dias";
        
        if( !connectDatabase(database))
        {
            System.out.printf( "Failed to connect to database\n");
            return;
        }
        
        // Read some data.
//        PreparedStatement pst = connection.prepareStatement("SELECT * FROM viz");
//        PreparedStatement pst = connection.prepareStatement("SELECT * FROM viz WHERE peer = 2 AND epoch = 2");
        
//        PreparedStatement pst = connection.prepareStatement("SELECT * FROM viz WHERE peer = 2 ORDER BY epoch");
        PreparedStatement pst = connection.prepareStatement("SELECT * FROM viz WHERE peer = 2 AND epoch > 0 ORDER BY epoch");
        //PreparedStatement pst = connection.prepareStatement("SELECT * FROM viz WHERE peer = 2 AND epoch > 797 ORDER BY epoch");
        ResultSet rs = pst.executeQuery();
        
        ObjectMapper mapper = new ObjectMapper();
        // Reading from database
        while (rs.next()) {
            String json_value = rs.getString("json_value");
            final int epoch_db = rs.getInt("epoch");
            final int peer_db = rs.getInt("peer");
            System.out.print(rs.getInt("seq_id") + " ");
            System.out.print(rs.getString("dt") + " ");
            System.out.print(peer_db + " ");
            System.out.print(epoch_db + " ");
            System.out.print(json_value + " ");
            System.out.println();
            
//            byte[] jsonData = Files.readAllBytes(file.toPath());
            NodeInfo node = mapper.readValue(json_value, NodeInfo.class);
            
            int epoch = node.getEpoch();
            int id = node.getId();
            
            assert(epoch == epoch_db);
            assert(id == peer_db);
            System.out.println("Push array: " + node.getPush());
//            String json_value = new String(jsonData);
//            String dt = dateFormatter.format(file.lastModified());
//            String sql_insert = sql_insert_template.replace("{dt}", dt).replace("{peer}", Integer.toString(id)).replace("{epoch}", Integer.toString(epoch)).replace("{json_value}", json_value);
//            statementQueue.add(sql_insert);
        }

        connection.close();
        System.out.printf( "Disconnected from database\n" );
       
    }
}
