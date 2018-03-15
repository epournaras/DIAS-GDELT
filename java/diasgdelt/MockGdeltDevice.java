package diasgdelt;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Queue;

import org.zeromq.ZMQ;

import com.google.gson.Gson;

import diasguimsg.AckMessage;
import diasguimsg.GUIMessage;
import diasguimsg.MessageFactory;
import diasguimsg.PeerAddressMessage;
import diasguimsg.PeerAddressRequestMessage;
import diasguimsg.PossibleStatesMessage;
import diasguimsg.SelectedStateMessage;
import diasguimsg.SensorAgentDescription;
import diasguimsg.SensorDescription;
import diasguimsg.SensorSetControlMessage;
import diasguimsg.SensorState;
import diasguimsg.StartAggregationMessage;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedList;


public class MockGdeltDevice {

    
	static private final ZMQ.Context 				zmqContext = ZMQ.context(2);
    
    // message serialisation
	static private final Gson 						gson = new Gson();
       
       // factory for converting DIAS GUI messages from JSON
	static private final MessageFactory				messageFactory = new MessageFactory();
    
       
    public static void main(String[] args) throws SQLException, IOException 
    {
        
        /*
         System.out.printf("MockGdeltDevice (2018-03-12)\n" );
        if (args.length < 3) 
		{
			System.err.printf("usage: device.id gateway.port gateway.host\n" );
            return;
         }
        
        // command-line args
        final 		int				device_id = Integer.parseInt(args [0]),
									gatway_port = Integer.parseInt(args [1]);
									
		final		String			gateway_host = args [2],
									gdelt_warmup_table = "gdelt";
		*/
        
    	System.out.printf("MockGdeltDevice (2018-03-14 - dev version)\n" );
    	
    	final 		int				device_id = 1,
									gatway_port = 3427;
				
    	final		String			gateway_host = "localhost",
    								gdelt_warmup_table = "gdelt_test";
    	
    	System.out.printf("device_id : %d\n", device_id );
        System.out.printf("gatway_port : %d\n", gatway_port );
        System.out.printf("gateway_host : %s\n", gateway_host );
        System.out.printf("gdelt_warmup_table : %s\n", gdelt_warmup_table );
    	
    	// params
        // description about this peer
        SensorAgentDescription 		sensorAgentDescription = new SensorAgentDescription( "dev#" + device_id, 1);
        System.out.printf("sensorAgentDescription : %s\n", sensorAgentDescription );

        SensorDescription 			sensorDescription = new SensorDescription("SensorA", "GPS");
        System.out.printf("sensorDescription : %s\n", sensorDescription );
        
        
        
        final int					peerTimeoutMs = 240,	
        							gdeltSelectedSubscribePort = 5555,		// subscribe to real-time GDELT data on this port
        							possibleStatesSampleSize = 1000,
        							numberPossibleStates = 9;
        
        System.out.printf("peerTimeoutMs : %d\n", peerTimeoutMs );
        System.out.printf("gdeltSelectedSubscribePort : %d\n", gdeltSelectedSubscribePort );
        System.out.printf("possibleStatesSampleSize : %d\n", possibleStatesSampleSize );
        System.out.printf("numberPossibleStates : %d\n", numberPossibleStates );
        
        // ----------------------------------
        // create instances of helper classes
        // ----------------------------------
        
        
        System.out.printf("helper classes created\n" );
        
        // -------------------------------
        // compute initial possible states
        // -------------------------------
        
        System.out.println( "\n--- Warmup ---" );
        
        // using the values from the sensor stored in the database
        final String        database = "dias";
        
        final String 		sql = "SELECT * FROM " + gdelt_warmup_table + " WHERE peer = " + device_id + " ORDER BY globaleventid DESC LIMIT " + possibleStatesSampleSize;
        System.out.printf("sql : %s\n", sql );
        
        // TOOD: use a circular buffer
        Queue<Double>		dataQueue = new LinkedList<Double>();
        
        databaseWarmup(database, sql, dataQueue);
        
        ArrayList<SensorState>			possibleStates = null;
        
        SensorState						selectedState = null;
        
        if( dataQueue.size() >=  possibleStatesSampleSize )
        {
        	// crop queue
        	while( dataQueue.size() > possibleStatesSampleSize)
        		dataQueue.poll();
        	
        	System.out.printf("dataQueue.size for initial possible states", dataQueue.size() );
        	
        	// compute initial possible states
        	possibleStates = convertStates(computePossibleStates(dataQueue, numberPossibleStates));
        	
        	System.out.printf("initial possibleStates : %s\n", possibleStates.toString() );
        	
        	// TODO: compute initial selectedState based on queue value
        	selectedState = possibleStates.get(0);
        	
        	System.out.printf("initial selectedState : %s\n", selectedState.toString() );
        	
        	// clear queue
        	dataQueue.clear();
        	
        }
        else
        {
        	System.err.printf("warning: no possible states/selected state generated during warmup\n" );
        	System.out.printf("dataQueue.size : %d\n", dataQueue.size() );
        }
        
        // ------------------------------
        // obtain a peer from the Gateway
        // ------------------------------
        System.out.println( "\n--- Connecting to Gateway ---" );
        
        PeerAddressMessage	peerAddressMessage =	connectGateway(gateway_host, gatway_port, sensorAgentDescription );
        if( peerAddressMessage == null )
        {
        	System.err.println("no peers available" );
        	return;
        }
        
        final String	peerFinger = peerAddressMessage.peerFinger;
        
        final int		peerId = peerAddressMessage.peerId;
        
 		System.out.printf( "peerId : %s\n", peerId );
 		System.out.printf( "peerFinger : %s\n", peerFinger );
 		
        // ---------------
        // connect to peer
        // ---------------
 		System.out.println( "\n--- Connecting to Peer ---" );
 		
 		// connect to the peer
        final 		String	peerConnectString = "tcp://" + peerFinger;
        System.out.printf( "peerConnectString : %s\n", peerConnectString );
        
        // connect to peer
   	 	ZMQ.Socket			zmqPeerSocket = null;
   	 	
		zmqPeerSocket = zmqContext.socket(ZMQ.REQ);
		zmqPeerSocket.connect(peerConnectString);
		zmqPeerSocket.setHWM(100);
		zmqPeerSocket.setLinger(-1);
		
		System.out.printf( "Connected\n" );
		
		// send heartbeat timeout
		SensorSetControlMessage		setPeerTimeoutMessage = new SensorSetControlMessage( 
       		 sensorAgentDescription, 
       		 sensorDescription, 
       		 "TimeoutMs", 
       		 Integer.toString(peerTimeoutMs) 
       		 );
		
		sendMsgPeer( zmqPeerSocket, gson.toJson(setPeerTimeoutMessage).toString() );
		
		System.out.printf( "Timeout sent, set to %d\n", peerTimeoutMs );
		
		System.out.printf( "\n### CONNECTED WITH PEER ###\n" );
		
		// can aggregation start?
		boolean 	aggregationStarted = false;
		
		if( possibleStates != null )
		{
			startAggregation( zmqPeerSocket, possibleStates, selectedState, sensorAgentDescription, sensorDescription );
			aggregationStarted = true;
		}
		else
			System.out.printf( "Aggregation has not yet started : aggregationStarted = %b\n", aggregationStarted );
        
        // ------------------------------
        // listen for new selected states
        // ------------------------------
		
		System.out.println( "\n--- Listening to new selected states ---" );
        
		final String		gdeletConnectString = "tcp://127.0.0.1:" + gdeltSelectedSubscribePort;
		System.out.printf( "gdeletConnectString : %s\n", gdeletConnectString );
		
		ZMQ.Socket			zmqGDELTSocket = zmqContext.socket(ZMQ.SUB);
		zmqGDELTSocket.subscribe("");
		
		zmqGDELTSocket.connect(gdeletConnectString);
		
		long			msg_counter = 0;
		
		while( true )
		{
	        // TODO: non-blocking because need to:
			// 1. send heartbeats
			// 2. process 'q' -> send Leave Message
			// subscribe
			
			//String			msg = zmqGDELTSocket.recvStr(ZMQ.DONTWAIT );
			String			msg = zmqGDELTSocket.recvStr();
			
			if( (msg != null) && (msg.length() > 0) )
			{
				// parse message
				LinkedHashMap<String,String>	dict = hashMapFromPythonDictString( msg );
				
				final int		peerID = Integer.valueOf(dict.get("peer"));
				
				// is this message for us?
				if( peerID == device_id )
				{
					++msg_counter;
					System.out.printf( "\nMsg %d : %s\n", msg_counter, msg );
					
					// extract selected state value
					final double 	latestGDELTValue = Double.valueOf(dict.get("AvgTone"));
					
					System.out.printf("AvgTone : %f\n",  latestGDELTValue );
					
					// update selected state
					if( aggregationStarted )
					{
						// TODO: compute initial selectedState based on queue value
			        	selectedState = possibleStates.get(0);
			        	System.out.printf("selectedState : %s\n", selectedState);
					
						SelectedStateMessage				selectedStateMsg = new SelectedStateMessage( selectedState, sensorAgentDescription,sensorDescription );
						
						// add as a JSON string to the list of messages to send
						sendMsgPeer( zmqPeerSocket, gson.toJson(selectedStateMsg).toString() );
						
						System.out.printf( "Selected state sent\n" );
						 
					}
					
					// add value to data queue
					dataQueue.add(latestGDELTValue);
					
					// if enough data, compute new possible states
					if( dataQueue.size() ==  possibleStatesSampleSize )
			        {
			        	// crop queue
			        	while( dataQueue.size() > possibleStatesSampleSize)
			        		dataQueue.poll();
			        	
			        	System.out.printf("computing new possible states, queue size : %d\n", dataQueue.size() );
			        	
			        	// compute possible states
			        	possibleStates = convertStates(computePossibleStates(dataQueue, numberPossibleStates));
			        	
			        	System.out.printf("updated possibleStates : %s\n", possibleStates.toString() );
			        	
			        	// clear queue
			        	dataQueue.clear();
			        	
			        	// send possible states
			    		PossibleStatesMessage			updatedPossibleStatesMessage = new  PossibleStatesMessage( possibleStates,  sensorAgentDescription, sensorDescription );
			    		
			    		// add as a JSON string to the list of messages to send
			    		sendMsgPeer( zmqPeerSocket, gson.toJson(updatedPossibleStatesMessage).toString() );
			       	 
			    		System.out.printf( "Updated possible states sent\n" );
			        	
			        }// data queue is full
					else
						System.out.printf( "Queue still warmimg up : %d\n", dataQueue.size() );
					
					// it is possible that aggregation was not yet started, typically because there was not enough data during warmup
					if( !aggregationStarted && (possibleStates != null))
					{
						// TODO: compute initial selectedState based on queue value
			        	selectedState = possibleStates.get(0);
			        	
						startAggregation( zmqPeerSocket, possibleStates, selectedState, sensorAgentDescription, sensorDescription );
						aggregationStarted = true;
					}
					
				}// message for us
				
				// wait
				/*
				try 
				{
					Thread.sleep(1000);
					
				} catch (InterruptedException e) 
				{
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
				*/
			}// non-empty message
				
		}// while
        
        // TODO: send leave message
		
		// TODO: close sockets

        
    }// main
    
    static private void startAggregation( ZMQ.Socket			zmqPeerSocket
    									,ArrayList<SensorState> possibleStates
    									,SensorState selectedState 
    									,SensorAgentDescription sensorAgentDescription
    									,SensorDescription sensorDescription
    									)
    {
    	System.out.printf( "\n--- startAggregation ---\n" );
    
    	// send possible states
		PossibleStatesMessage			possibleStatesMessage = new  PossibleStatesMessage( possibleStates,  	sensorAgentDescription, sensorDescription );
		sendMsgPeer( zmqPeerSocket, gson.toJson(possibleStatesMessage).toString() );
		System.out.printf( "Possible states sent\n" );
	
	
		// send selected states
		SelectedStateMessage				selectedStateMsg = new SelectedStateMessage( selectedState, sensorAgentDescription,sensorDescription );
		sendMsgPeer( zmqPeerSocket, gson.toJson(selectedStateMsg).toString() );
		System.out.printf( "Selected state sent\n" );
		
		// start aggregation 
		sendMsg( zmqPeerSocket, gson.toJson(new StartAggregationMessage(sensorAgentDescription)));
		System.out.printf( "Aggregation start sent\n" );
		 
	
		System.out.printf( "\n### AGGREGATION STARTED ###\n" );
    }
    
    static private LinkedHashMap<String,String>	hashMapFromPythonDictString( String str )
	{
		final String		clean = str.replace("{", "").replace("}", "").replace("'", "");
		//System.out.printf("clean : %s\n",  clean );
		
		String[]			key_values = clean.split(", ");
		//System.out.printf("key_values.length : %d\n",  key_values.length );
		
		LinkedHashMap<String,String> 		dict = new LinkedHashMap<String,String> ();
		for( String key_value:key_values)
		{
			final String 		key = key_value.split(": ")[0],
								value = key_value.split(": ")[1];
			
			//System.out.printf("%s -> %s\n",  key, value );
			
			dict.put(key, value);
		}
		
		return dict;

	}
    static private String recv(ZMQ.Socket socket, int zeromqFlags)
    {
		String data = new String(socket.recv(), ZMQ.CHARSET);
			
		return data;
    }
    
    static private void sendMsgPeer( ZMQ.Socket socket, String msg )
    {
    	System.out.printf( "sending message to peer..." );
		sendMsg(socket, msg);
		System.out.printf( "ok\n" );
		 
		 
		// wait for response
		System.out.printf( "waiting for response..." );
		
		final String 		response = new String(socket.recv(), ZMQ.CHARSET);
		System.out.printf( "ok\n" );
		
		// parse response
		GUIMessage 					guiMessage = messageFactory.CrackMessage(response);
	   	 
		String						mtype = guiMessage.MessageType;
		
		if ( mtype.compareTo( "Ack" ) != 0)
			throw new RuntimeException( "Ack message expected" );
		 
	   	AckMessage					ackMessage = gson.fromJson(response, AckMessage.class);
	 		
	 	
	   	boolean 					return_value  = false;
	 	if( ackMessage.ackText.compareTo( "OK" ) == 0 ) 		// either OK or NOK
	 	{
	 		System.out.printf( "peer responded with OK\n" );
	 		return_value = true;;
	 	}
	 	else if( ackMessage.ackText.compareTo( "NOK") != 0 )
	 	{
	 		System.err.printf( "peer responded with NOK : %s\n",  ackMessage.errorText);
	 	}
	 	else
	 	{
	 		System.err.printf( "peer responded with unhandled value '%s' : %s\n",  ackMessage.ackText, ackMessage.errorText);
	 	}
	 	if(!return_value)
	 		throw new RuntimeException( "sendMsgPeer: error communicating with peer");
	 	
   	 	
    }// sendMsgPeer
    
    // send a message to a socket; returns the number of bytes sent
    static private  boolean sendMsg( ZMQ.Socket socket, String msg )
 	{
         return( socket.send(msg, 0) );
 	}
 	
    static private PeerAddressMessage connectGateway(String gatewayHost, Integer gatewayPort, SensorAgentDescription sensorAgent )
    {
         final 		String	gatewayConnectString = "tcp://" + gatewayHost + ":" + gatewayPort;
         
         final 		boolean debug = true;
         
         PeerAddressMessage		peerAddressMessage = null;	// return value
         
         // connect
         System.out.printf( "connecting to gateway %s...", gatewayConnectString );
         ZMQ.Socket		gateway_socket= zmqContext.socket(ZMQ.REQ);
         gateway_socket.connect(gatewayConnectString);
         gateway_socket.setRcvHWM(1000);
         gateway_socket.setLinger(-1);
    	 System.out.printf( "ok\n" );
    	 
    	 // create PeerAddressRequest
    	 PeerAddressRequestMessage 	peerAddressRequestMessage = new PeerAddressRequestMessage( sensorAgent );
    	 String				peerAddressRequestMessageJson = gson.toJson(peerAddressRequestMessage);
    	 
    	 System.out.printf( "peerAddressRequestMessageJson : %s\n", peerAddressRequestMessageJson );
    	 
    	 
    	 // send message
    	 System.out.printf( "sending address request to gateway..." );
    	 sendMsg( gateway_socket, peerAddressRequestMessageJson);
    	 System.out.printf( "ok\n" );
    	 
    	 // wait for response
    	 System.out.printf( "\nwaiting for response..." );
    	 String 			gatewayResponse = new String(gateway_socket.recv(), ZMQ.CHARSET);
    	 System.out.printf( "ok\n" );
    	 
    	 if( debug ) System.out.printf( "incomingMessage : %s\n", gatewayResponse );
			
         
    	 // disconnect from gateway
    	 System.out.printf( "disconnecting..." );
    	 gateway_socket.close();
    	 System.out.printf( "ok\n" );
    	 
    	 gateway_socket = null;
    	 
    	 // verify that the gateway connected us to a peer
    	 GUIMessage 					guiMessage = messageFactory.CrackMessage(gatewayResponse);
    	 System.out.printf( "guiMessage : %s\n", guiMessage.toString() );
    	 
    	 String						mtype = guiMessage.MessageType;
    	 System.out.printf( "mtype : %s\n", mtype );
    	 
    	 switch( mtype )
    	 {
    	 	case "Ack":
    	 		AckMessage		ackMessage = gson.fromJson(gatewayResponse, AckMessage.class);
    	 		
    	 		System.out.printf( "received an ACK message with msg %s | %s -> goodbye\n", ackMessage.ackText, ackMessage.errorText );
    	 		
    	 		break;
    	 	case "PeerAddress":
    	 		peerAddressMessage = gson.fromJson(gatewayResponse, PeerAddressMessage.class);
    	 		
    	 		
    	 		System.out.printf( "\n*** Successfully bound with peer %d (%s) ***\n", peerAddressMessage.peerId, peerAddressMessage.peerFinger );
    	 		
    	 		break;
    	 		
    	 	default:
    	 		System.out.printf( "unhandled mtype : %s\n", mtype );
    	 }// switch
    	 
    	 return peerAddressMessage;
	  		
    }// connectGateway
    
    // convertStates: convert array of doubles to a arraylist of sensorstates 
    static private ArrayList<SensorState> convertStates( double []possibleStatesVectorDoubles )
    {
    	if( possibleStatesVectorDoubles == null )
    		throw new RuntimeException( "possibleStatesVectorDoubles is null" );
    	
    	final int		numberPossibleStates = possibleStatesVectorDoubles.length;
    	
        ArrayList<SensorState>			possibleStates = new ArrayList<SensorState>(numberPossibleStates);
        for( int j = 0; j < numberPossibleStates; j++ )
        {
        	 // recall that a state is multi-dimensional, and is represented by >= N
        	LinkedHashMap<String,Object>		cluster_means = new LinkedHashMap<String,Object>();
    		cluster_means.put( "x.1", possibleStatesVectorDoubles[j] );
    		
    		// create the state object
			SensorState							possibleState = new SensorState( new Integer(j), cluster_means );
			
			// finally, add to the list of possible states (add to the end)
			possibleStates.add( possibleState );
    		
        }
        
        return possibleStates;
    }// convertStates
    
    
    // databaseWarmup: read the most recent N sensor values from the database and return a queue of values that can be used to compute posssible states
    static private void  databaseWarmup(String database, String sql, Queue<Double> queue)
    {
    	final boolean 	debug = false;
    	
    	try 
    	{
	        // Read some data
	        Connection 						connection = connectDatabase(database);
	        
	        PreparedStatement 				pst= connection.prepareStatement(sql);
			
	        ResultSet 						rs = pst.executeQuery();
	        
	        // read from database
	        long							record_counter = 0;
	        
	        while (rs.next()) 
	        {
	        	++record_counter;
	        	
	        	final int 		db_seq_id = rs.getInt("seq_id"),
	        					sqlDate = rs.getInt("sqldate"),
	        					epoch = rs.getInt("epoch"),
	        					peer = rs.getInt("peer"),
	        					globaleventid = rs.getInt("globaleventid");
	        	
	        	final String 	dt = rs.getString( "dt" ),
	        					actiongeo_countrycode = rs.getString( "actiongeo_countrycode" );
	        	
	        	final double 	avgtone = rs.getDouble("avgtone");
	        	
	        	if( debug )
	        	{
		            System.out.print(db_seq_id + " ");
		            System.out.print(sqlDate+ " ");
		            System.out.print(epoch + " ");
		            System.out.print(peer + " ");
		            System.out.print(globaleventid + " ");
		            System.out.print(dt + " ");
		            System.out.print(actiongeo_countrycode + " ");
		            System.out.print(avgtone + " ");
		            System.out.println();
	        	}
	            
	            // add to queue
	        	queue.add( avgtone );
	            
	            
	        }// while
	
	        connection.close();
	        System.out.printf( "Disconnected from database\n" );
	        
	        System.out.printf( "Records processed during warmup : %d\n", record_counter );
	        System.out.printf( "Queue size : %d\n", queue.size() );
    	}
    	catch (SQLException e) 
    	{
    		System.err.printf( "databaseWarmup: exception : + %s", e.toString() );
    		e.printStackTrace();
    	}
    	
    	
	}// databaseWarmup
    
    private static Connection connectDatabase(String database)
    {
    	Connection connection = null;
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
        
        
        return connection;
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
    	{
    		possibleStates[j] = possibleStates[j-1] + (max-min) / (double)(numberPossibleStates - 1.0);
    		System.out.printf("%f ", possibleStates[j] );
    		
    	}
    	System.out.printf("\n");
    			
    	
    	return possibleStates;
    	
    }

}// class
