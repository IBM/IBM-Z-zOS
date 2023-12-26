package com.ibm.smf.was.plugins.utilities;
//(C) Copyright IBM Corp. 2010 - All Rights Reserved.
//DISCLAIMER:
//The following source code is sample code created by IBM Corporation.
//This sample code is provided to you solely for the purpose of assisting you
//in the  use of  the product. The code is provided 'AS IS', without warranty or
//condition of any kind. IBM shall not be liable for any damages arising out of your
//use of the sample code, even if IBM has been advised of the possibility of
//such damages.
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Calendar;
import java.util.TimeZone;
import java.math.BigInteger;

/**
 * Utilities to manage z/OS STCK formatted timestamps
 *
 */
public class STCK
{
  /**
   * Calculate and remember the origin difference between Java and the MVS time
   */
  public final static long JAVA_MVS_ORIGIN_DIFFERENCE = calculateClockOriginDifference();
  private static DateFormat formatter;

  private static long calculateClockOriginDifference() {
      Calendar calendar = Calendar.getInstance();

      // Origin for MVS TOD clock is January 1, 1900, 00:00:00 GMT
      calendar.setTimeZone(TimeZone.getTimeZone("UTC"));
      calendar.clear();
      calendar.set(1900, 0, 1);

      // Calculate the offset between MVS TOD clock origin and Java clock origin
      //   ( milliseconds since January 1, 1970 00:00:00 GMT )

      return calendar.getTime().getTime();
  }

  /**
   * Converts a STCK formatted timestamp into a human readable one
   * @param s a STCK timestamp
   * @return a readable date/time
   */
  public static String toString(String s)
  {
	   BigInteger stck = new BigInteger(s, 16);

	   if (stck.doubleValue()==0) return new String(" ");
	   // Bit 51 is usecs so shift out the low order 12 bits
	   // and then convert to milliseconds
	   long micros = stck.shiftRight(12).longValue();
	   long millis  = micros / 1000L;

	   // Add the timestamp to the origin difference and convert
	   Date date = new Date(millis + JAVA_MVS_ORIGIN_DIFFERENCE);

	   DateFormat df;
	   String dtf = System.getProperty("com.ibm.ws390.smf.dateTimeFormat");
	    if (dtf!=null){
	    	df = new SimpleDateFormat(dtf);
	    } else {
	    	df = DateFormat.getDateTimeInstance(DateFormat.FULL,DateFormat.FULL); 	
	    }
	   
	   
	   TimeZone tz = TimeZone.getTimeZone("GMT");
	   df.setTimeZone(tz);
	   return df.format(date);
	   
  }

  /**
   * Converts a BigInteger STCK timestamp to a human readable one
   * @param stck a BigInteger STCK timestamp
   * @return a readable date/time
   */
  public static String toString(BigInteger stck)
  {
	   // Bit 51 is usecs so shift out the low order 12 bits
	   // and then convert to milliseconds
	   long micros = stck.shiftRight(12).longValue();
	   long millis  = micros / 1000L;

	   // Add the timestamp to the origin difference and convert
	   Date date = new Date(millis + JAVA_MVS_ORIGIN_DIFFERENCE);

	   DateFormat df;
	   String dtf = System.getProperty("com.ibm.ws390.smf.dateTimeFormat");
	    if (dtf!=null){
	    	df = new SimpleDateFormat(dtf);
	    } else {
	    	df = DateFormat.getDateTimeInstance(DateFormat.FULL,DateFormat.FULL); 	
	    }

	   TimeZone tz = TimeZone.getTimeZone("GMT");
	   df.setTimeZone(tz);
	   return df.format(date);
	  
  }

  /**
   * Convert a long millisecond value to a readable time/date string
   * @param millis a STCK converted to milliseconds
   * @return A string form of the date/time (as above)
   */
  public static String toString(long millis) 
  {
	   // Add the timestamp to the origin difference and convert
	   Date date = new Date(millis + JAVA_MVS_ORIGIN_DIFFERENCE);

	   if (formatter == null) {
		   String dtf = System.getProperty("com.ibm.ws390.smf.dateTimeFormat");
		    if (dtf!=null){
		    	formatter = new SimpleDateFormat(dtf);
		    } else {
		    	formatter = DateFormat.getDateTimeInstance(DateFormat.FULL,DateFormat.FULL); 	
		    }

		   TimeZone tz = TimeZone.getTimeZone("GMT");
		   formatter.setTimeZone(tz);
	   }
	   
	   return formatter.format(date);
	  
  }
  
  /**
   * Converts a String format STCK timestamp into a java.util.Date 
   * @param s a String STCK timestamp
   * @return a Date object
   */
  public static Date toDate(String s)
  {
	   BigInteger stck = new BigInteger(s, 16);

	   // Bit 51 is usecs so shift out the low order 12 bits
	   // and then convert to milliseconds
	   long micros = stck.shiftRight(12).longValue();
	   long millis  = micros / 1000L;

	   // Add the timestamp to the origin difference and convert
	   Date date = new Date(millis + JAVA_MVS_ORIGIN_DIFFERENCE);
       return date;
	   
 }
}
