package diasgdelt;

import java.util.LinkedHashMap;

public class TestParsePythonDictionnaryString {

	public static void main(String[] args) 
	{
		// TODO Auto-generated method stub
		
		final String		msg = "{'dt': '2018-03-14 06:31:00', 'peer': 17, 'globaleventid': 1993, 'sqldate': '20180314', 'ActionGeo_CountryCode': 'LO', 'AvgTone': 73.0}";
		System.out.printf("msg : %s\n",  msg );
		
		LinkedHashMap<String,String>	dict = hashMapFromPythonDictString( msg );
		System.out.printf("#items : %d\n",  dict.size() );
		
		
		System.out.printf("peer -> %s\n",  dict.get("peer") );
		System.out.printf("AvgTone -> %s\n",  dict.get("AvgTone") );
		
		
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

}
