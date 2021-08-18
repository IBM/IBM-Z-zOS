package com.ibm.smf.was.plugins.utilities;
//(C) Copyright IBM Corp. 2010 - All Rights Reserved.
//DISCLAIMER:
//The following source code is sample code created by IBM Corporation.
//This sample code is provided to you solely for the purpose of assisting you
//in the  use of  the product. The code is provided 'AS IS', without warranty or
//condition of any kind. IBM shall not be liable for any damages arising out of your
//use of the sample code, even if IBM has been advised of the possibility of
//such damages.

import java.io.ByteArrayInputStream;
import java.io.DataInputStream;

/**
 * A set of utilities used by various plugin routines to get 
 * SMF data formatted stuff (byte arrays usually) into some
 * more manageable (or readable) format.
 *
 */
public class ConversionUtilities 
{

  final protected static char[] hexArray = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

  /**
   * Convert a byte array to a hex string
   * @param bytes bytes to convert
   * @return an ascii string for the hex value
   */
  public static String bytesToHex(byte[] bytes) {
  char[] hexChars = new char[bytes.length * 2];
  int v;
  for ( int j = 0; j < bytes.length; j++ ) 
  {
    v = bytes[j] & 0xFF;
    hexChars[j * 2] = hexArray[v >>> 4];
    hexChars[j * 2 + 1] = hexArray[v & 0x0F];
  }
  return new String(hexChars);
 }	
	
  /**
   * Strip off trailing zeroes
   * @param s input string
   * @return pruned string
   */
  public static String stripTrailingZeroes(String s) {
   char[] chars = s.toCharArray();
   int length,index;
   length = s.length();
   index = length -1;
   for (; index >=0;index--)
   {
    if (chars[index] != '0'){
	  break;}
   }
  return (index == length-1) ? s :s.substring(0,index+1);
  }
  
/**
 * Converts a 16-byte byte array into a hex string
 * @param x a 16-byte byte array
 * @return a hex string 
 */
 public static String sixteenByteArrayToHexString(byte x[])
 {
  byte y[] = new byte[8];
  byte z[] = new byte[8];
  
  for (int i=0;i<8;++i)
  {
   y[i] = x[i];
   z[i] = x[i+8];
  }
  
  return longByteArrayToHexString(y)+longByteArrayToHexString(z);
  
 }
	
 /**
  * Converts an eight-byte (long) byte array into a hex string
  * @param x an eight byte byte array
  * @return a hex string
  */
 public static String longByteArrayToHexString(byte x[])
 { 
  ByteArrayInputStream bis;
  DataInputStream dis;
	 
  try
  {
   bis = new ByteArrayInputStream(x);
   dis = new DataInputStream(bis);
   long y = dis.readLong(); 
   return Long.toHexString(y).toUpperCase();
  }
  catch(Exception ex)
  {
   System.out.println("oops "+ex);
   return null;
  }
 }
	
 /**
  * Converts a four-byte byte array into a hex string
  * @param x a four byte byte array
  * @return a hex string
  */
 public static String intByteArrayToHexString(byte x[])
 { 
  ByteArrayInputStream bis;
  DataInputStream dis;
	 
  try
  {
   bis = new ByteArrayInputStream(x);
   dis = new DataInputStream(bis);
   int y = dis.readInt(); 
   return Integer.toHexString(y).toUpperCase();
  }
  catch(Exception ex)
  {
   System.out.println("oops "+ex);
   return null;
  }
 }
 
 /**
  * Converts a two-byte byte array into a hex string
  * @param x a two-byte byte array
  * @return a hex string
  */
 public static String shortByteArrayToHexString(byte x[])
 { 
  ByteArrayInputStream bis;
  DataInputStream dis;
	 
  try
  {
   bis = new ByteArrayInputStream(x);
   dis = new DataInputStream(bis);
   short y = dis.readShort(); 
   Integer z = new Short(y).intValue();   
   return Integer.toHexString(z).toUpperCase();
  }
  catch(Exception ex)
  {
   System.out.println("oops "+ex);
   return null;
  }
 }

 /**
  * Converts an eight byte byte array into a long
  * @param x an eight byte byte array
  * @return a long
  */
 public static long longByteArrayToLong(byte x[])
 {
  ByteArrayInputStream bis;
  DataInputStream dis;
	 
  try
  {
   bis = new ByteArrayInputStream(x);
   dis = new DataInputStream(bis);
   long y = dis.readLong(); 
   return y;
  }
  catch(Exception ex)
  {
   System.out.println("oops "+ex);
   return 0L;
  }
 }
 
 /**
  * Converts a four-byte byte array into an int
  * @param x a four byte byte array
  * @return an int
  */
 public static int intByteArrayToInt(byte x[])
 {
  ByteArrayInputStream bis;
  DataInputStream dis;
		 
  try
  {
   bis = new ByteArrayInputStream(x);
   dis = new DataInputStream(bis);
   int y = dis.readInt(); 
   return y;
  }
  catch(Exception ex)
  {
   System.out.println("oops "+ex);
   return 0;
  }
 }
 
}

