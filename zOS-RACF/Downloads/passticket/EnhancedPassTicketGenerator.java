/* 
 * EnhancedPassTicketsGenerator 
 * Version V1.00
 * 
 * Licensed Materials - Property of IBM
 * 5650-ZOS
 * Copyright IBM Corp. 2020, 2021
 * 
 * This sample JAVA program implements the enhanced 
 * PassTicket generation algorithm as documented in
 * z/OS Security Server RACF Macros and Interfaces.
 * 
 * 
 * THIS CODE HAS NOT BEEN SUBMITTED TO ANY FORMAL IBM TEST
 * AND IS DISTRIBUTED ON AN "AS IS" BASIS WITHOUT ANY
 * WARRANTY EITHER EXPRESS OR IMPLIED. THE IMPLEMENTATION
 * OF ANY OF THE TECHNIQUES DESCRIBED OR USED HEREIN IS A
 * CUSTOMER RESPONSIBILITY AND DEPENDS ON THE CUSTOMER'S
 * OPERATIONAL ENVIRONMENT. WHILE EACH ITEM MAY HAVE BEEN
 * REVIEWED FOR ACCURACY IN A SPECIFIC SITUATION AND MAY
 * RUN IN A SPECIFIC ENVIRONMENT, THERE IS NO GUARANTEE
 * THAT THE SAME OR SIMILAR RESULTS WILL BE OBTAINED ELSE-
 * WHERE. CUSTOMERS ATTEMPTING TO ADAPT THESE TECHNIQUES TO
 * THEIR OWN ENVIRONMENTS DO SO AT THEIR OWN RISK.
 */
package com.ibm.eserver.PassTicket; 

import java.io.IOException;
import java.io.ByteArrayOutputStream;
import java.io.UnsupportedEncodingException;
import java.util.Date;

import javax.crypto.Mac;
import java.security.Key;
import java.security.NoSuchAlgorithmException;
import java.security.InvalidKeyException;


public class EnhancedPassTicketGenerator {

  /**  
   * Enhanced PassTicket type
   */
  public enum PassTicketType {
    /**
     * Enhanced PassTicket type MIXED
     */
    ENH_MIXED, 
    /**
     * Enhanced PassTicket type UPPER
     */
    ENH_UPPER;
  }

  // Enhanced PassTicket character array
  // All chars are used for PassTicketType ENH_MIXED
  // Only first 36 chars are used for PassTicketType ENH_UPPER
  protected static final char[] passTicketChars = {
    '0','1','2','3','4','5','6','7','8','9',
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    'a','b','c','d','e','f','g','h','i','j','k','l','m',
    'n','o','p','q','r','s','t','u','v','w','x','y','z',
    '-','_'};

  /**
   * Generate an enhanced PassTicket from the input user ID, 
   * application name, HMAC key and PassTicket type. 
   * 
   * The ptKey PassTicket key parameter may be created with a 
   * SecretKeySpec as follows:
   * <pre>{@code
   * SecretKeySpec ptKey = new SecretKeySpec(keyBytes, "HmacSHA512")
   * }</pre>
   * 
   * @param userid User ID. Must be 1-8 characters in length.
   * @param appl Application name. Must be 1-8 characters in length. 
   * @param ptKey Key object used to generate the PassTicket.
   * @param ptType Enhanced PassTicketType of ENH_UPPER or ENH_MIXED.
   * @return An enhanced PassTicket 
   * 
   * @throws InvalidKeyException
   * @throws NoSuchAlgorithmException
   * @throws IOException
   * @throws PassTicketException
   */
  public static String generate(String userid, 
                                String appl, 
                                Key ptKey, 
                                PassTicketType ptType)
      throws InvalidKeyException, NoSuchAlgorithmException, 
             IOException, PassTicketException, 
             UnsupportedEncodingException {
    
    // -------------------------------------------------------------------- 
    // Step 1:
    // Convert the User ID and Application name to EBCDIC and
    // append the User ID and Application name together 
    // -------------------------------------------------------------------- 
    byte[] userApplBytes = encodeUserAppl(userid, appl);
    
    // -------------------------------------------------------------------- 
    // Step 2:
    // Calculate HMAC with SHA-512 on the user ID and Application name
    // -------------------------------------------------------------------- 
    byte[] userApplHmac = generateHMAC(userApplBytes, ptKey);

    // -------------------------------------------------------------------- 
    // Step 3 (part 1):
    // Get current GMT time in seconds since Jan 1, 1970 and convert to binary
    // -------------------------------------------------------------------- 
    long curTimeSeconds = new Date().getTime() / 1000;
    byte[] binaryPassTicketBytes = new byte[] {
      (byte) ((curTimeSeconds >> 40) & 0x0FF),
      (byte) ((curTimeSeconds >> 32) & 0x0FF),
      (byte) ((curTimeSeconds >> 24) & 0x0FF),
      (byte) ((curTimeSeconds >> 16) & 0x0FF),
      (byte) ((curTimeSeconds >> 8) & 0x0FF),
      (byte) (curTimeSeconds & 0x0FF)};

    // -------------------------------------------------------------------- 
    // Step 3 (part 2):
    // Loop for each of the 6 bytes in binary time
    // -------------------------------------------------------------------- 
    for (int i = 0; i < binaryPassTicketBytes.length; i++) {
      // -------------------------------------------------------------------- 
      // Step 4: 
      // XOR each byte of the time with the HMACed userApplBytes
      // -------------------------------------------------------------------- 
      binaryPassTicketBytes[i] ^= userApplHmac[i];
    }

    // -------------------------------------------------------------------- 
    // Step 5:
    // Call the PassTicket Time-Coder algorithm
    // -------------------------------------------------------------------- 
    timeCoder(binaryPassTicketBytes, userApplBytes, ptKey, ptType);

    // -------------------------------------------------------------------- 
    // Step 6:
    // Translate binary PassTicket to Java String
    // -------------------------------------------------------------------- 
    String ptString = translatePassTicket(binaryPassTicketBytes, ptType);

    // Return the enhanced PassTicket to the caller.
    return new String(ptString);
  }

  /**
   * Encode the RACF user ID and application name into a byte array.
   * Each parameter is blank padded to 8 characters, uppercased 
   * and converted to EBCDIC.
   * 
   * @param userid The input target user ID.
   * @param appl The input target application name.
   * @return Encoded user ID and application name.
   * @throws IOException
   * @throws PassTicketException
   * @throws UnsupportedEncodingException
   */
  protected static byte[] encodeUserAppl(String userid, 
                                         String appl) 
    throws IOException, PassTicketException, UnsupportedEncodingException {

    // Convert user ID and application name
    byte[] EBCUser = convertStringToEBCDIC(userid, "userid");
    byte[] EBCAppl = convertStringToEBCDIC(appl, "application");

    // Write the EBCDIC userid and appl to a Byte Array Output Stream
    ByteArrayOutputStream userApplBaos = new ByteArrayOutputStream();
    userApplBaos.write(EBCUser);
    userApplBaos.write(EBCAppl);

    return userApplBaos.toByteArray();
  }

  /**
   * Converts a Java String to an 8 byte EBCDIC byte array.
   * Result is uppercased and padded with EBCDIC spaces.
   * 
   * @param value String to convert to EBCDIC.
   * @param valueName Name of value to convert.
   * @return EBCDIC byte array padded with spaces and uppercased
   * @throws PassTicketException
   * @throws UnsupportedEncodingException
   */
  private static byte[] convertStringToEBCDIC(String value, 
                                              String valueName)
      throws PassTicketException, UnsupportedEncodingException {

    // Verify length
    if (value.length() > 8 || value.length() == 0) {
      throw new PassTicketException(
        "Length[" + value.length() +"] not valid for " +
        "parameter[" + valueName + "] with value[" + value + "].");
    }

    // Uppercase and pad to 8 bytes with blanks
    value = value.toUpperCase();
    value = String.format("%-8s", value);

    // Get EBCDIC bytes
    byte[] returnValue = value.getBytes("IBM-1047");

    return returnValue;
  }

  /**
   * Generate HMAC with SHA-512 based on input byte array and key.
   * 
   * @param tbsBytes The input bytes to be signed.
   * @param ptKey Key to use to calculate the HMAC.
   * @return HMAC results byte array.
   * @throws NoSuchAlgorithmException
   * @throws InvalidKeyException
   * @throws IOException
   */
  protected static byte[] generateHMAC(byte[] tbsBytes, 
                                       Key ptKey) 
    throws NoSuchAlgorithmException, InvalidKeyException, IOException {

    // Generate HMAC with SHA-512
    Mac sha512HMAC = Mac.getInstance("HmacSHA512");
    sha512HMAC.init(ptKey);
    byte[] sigBytes = sha512HMAC.doFinal(tbsBytes);

    return sigBytes;
  }

  /**
   * Perform PassTicket Time-Coder Algorithm
   * 
   * @param binaryPassTicketBytes Current working binary PassTicket. 
   *   Updated by this method.
   * @param userApplBytes User ID and Appl ID byte array.
   * @param ptKey PassTicket HMAC key used to generate PassTicket.
   * @param ptType PassTicket type.
   * @return HMAC results
   * @throws NoSuchAlgorithmException
   * @throws InvalidKeyException
   * @throws IOException
   */
  protected static void timeCoder(byte[] binaryPassTicketBytes,
                                  byte[] userApplBytes,
                                  Key ptKey,
                                  PassTicketType ptType) 
    throws NoSuchAlgorithmException, InvalidKeyException, IOException {
   
    // -------------------------------------------------------------------- 
    // Step A:
    // Seperate binaryPassTicketBytes into left 3 bytes (L3B) and right 3 bytes (R3B)
    // -------------------------------------------------------------------- 
    byte[] binaryPassTicketBytes_L3B = new byte[3];
    System.arraycopy(binaryPassTicketBytes, 0, binaryPassTicketBytes_L3B, 0, 3);
    byte[] binaryPassTicketBytes_R3B = new byte[3];
    System.arraycopy(binaryPassTicketBytes, 3, binaryPassTicketBytes_R3B, 0, 3);

    // -------------------------------------------------------------------- 
    // Step B (Part 1):
    // Copy userApplBytes into padding portion of HMAC input buffer
    // -------------------------------------------------------------------- 
    byte[] hmacInputBuffer = new byte[20];
    for (int i = 0; i < 16; i++) {
      hmacInputBuffer[i+4] = userApplBytes[i];
    }

    // -------------------------------------------------------------------- 
    // Step H:
    // Loop for 6 rounds of time-coder
    // -------------------------------------------------------------------- 
    for (int roundNum = 1; roundNum < 7; roundNum++) {
      // -------------------------------------------------------------------- 
      // Steps B,C,D,E,F,G:
      // Perform one round of time-coder 
      // -------------------------------------------------------------------- 
      timeCoderRound(binaryPassTicketBytes_L3B, binaryPassTicketBytes_R3B, 
                     hmacInputBuffer, ptKey, ptType, roundNum);
    }

    // -------------------------------------------------------------------- 
    // Step I:
    // Recombine L3B and R3B
    // -------------------------------------------------------------------- 
    System.arraycopy(binaryPassTicketBytes_L3B, 0, binaryPassTicketBytes, 0, 3);
    System.arraycopy(binaryPassTicketBytes_R3B, 0, binaryPassTicketBytes, 3, 3);
  }

  /**
   * Perform one round of the time-coder algorithm. 
   * 
   * @param binaryPassTicketBytes_L3B Current working binary PassTicket Left 3 bytes. 
   *   Updated by this method.
   * @param binaryPassTicketBytes_R3B Current working binary PassTicket Right 3 bytes. 
   *   Updated by this method.
   * @param hmacInputBuffer Buffer for calculating HMAC. Updated by this method.
   * @param ptKey PassTicket HMAC key used to generate PassTicket.
   * @param ptType PassTicket type.
   * @param roundNum Current time encoder round number.
   * @return HMAC results byte array.
   * @throws NoSuchAlgorithmException
   * @throws InvalidKeyException
   * @throws IOException
   */
  protected static void timeCoderRound(byte[] binaryPassTicketBytes_L3B,
                                       byte[] binaryPassTicketBytes_R3B,
                                       byte[] hmacInputBuffer,
                                       Key ptKey,
                                       PassTicketType ptType,
                                       int roundNum) 
    throws NoSuchAlgorithmException, InvalidKeyException, IOException {

    // -------------------------------------------------------------------- 
    // Step B (Part 2):
    // Concatenate R3B with 17 byte padding in hmacInputBuffer
    // Update round counter in hmacInputBuffer
    // -------------------------------------------------------------------- 
    System.arraycopy(binaryPassTicketBytes_R3B, 0, hmacInputBuffer, 0, 3);
    hmacInputBuffer[3] = (byte)roundNum; // Set the round counter byte

    // -------------------------------------------------------------------- 
    // Step C:
    // Generate HMAC on R3B and padding data in hmacInputBuffer
    // -------------------------------------------------------------------- 
    byte[] hmacResult = generateHMAC(hmacInputBuffer, ptKey);

    // -------------------------------------------------------------------- 
    // Step D & E:
    // XOR L3B with left 3 bytes of HMAC results
    // -------------------------------------------------------------------- 
    byte[] xorResult = new byte[3];
    for (int byteIndex = 0; byteIndex < 3; byteIndex++) {
      xorResult[byteIndex] = (byte)(binaryPassTicketBytes_L3B[byteIndex] ^ 
        hmacResult[byteIndex]);
    }

    // -------------------------------------------------------------------- 
    // Step F:
    // When UPPER type and odd rounds (1,3,5) mask left 7 bits of XOR result to zero
    // -------------------------------------------------------------------- 
    if (((roundNum & 1) != 0) & 
        (ptType == PassTicketType.ENH_UPPER))   { // roundNum is odd and UPPER type?
      xorResult[0] &= (byte) 0x001;  // Mask left 7 bits to zero
    }

    // -------------------------------------------------------------------- 
    // Step G:
    // Set L3B = R3B 
    // Set R3B = XOR result
    // -------------------------------------------------------------------- 
    System.arraycopy(binaryPassTicketBytes_R3B, 0, binaryPassTicketBytes_L3B, 0, 3);
    System.arraycopy(xorResult, 0, binaryPassTicketBytes_R3B, 0, 3);
  }


  /**
   * Translate the binary enhanced PassTicket to a Java String.
   * 
   * @param binaryPassTicketBytes The binary enhanced PassTicket byte array.
   * @param ptType Enhanced PassTicket type.
   * @return Java string version of the enhanced PassTicket.
   */
  private static String translatePassTicket(byte[] binaryPassTicketBytes, 
                                            PassTicketType ptType) {

    // Char array to build enhanced PassTicket
    char[] passTicketCharArray = new char[8];

    // -------------------------------------------------------------------- 
    // Step A:
    // Convert 6 byte binary PassTicket to (64 bit) long PassTicket
    // -------------------------------------------------------------------- 
    long longPassTicket = 0;
    for (int i = 0; i < binaryPassTicketBytes.length; i++) {
      longPassTicket = (longPassTicket << 8) + (binaryPassTicketBytes[i] & 0xff);
    } 

    // -------------------------------------------------------------------- 
    // Step B (part 1):
    // Set character set size based on PassTicket type (UPPER vs MIXED)
    // -------------------------------------------------------------------- 
    int charSetSize;
    if (ptType == PassTicketType.ENH_UPPER) {
      charSetSize = 36;
    } else {
      charSetSize = 64;
    }

    // -------------------------------------------------------------------- 
    // Step G:
    // Loop for each PassTicket output character
    // -------------------------------------------------------------------- 
    for (int i = 7; i >= 0; i--) {
      // -------------------------------------------------------------------- 
      // Step B (part 2):
      // Calculate modulo 36 (UPPER) or 64 (MIXED) of current long PassTicket value
      // -------------------------------------------------------------------- 
      int curChar = (int)(longPassTicket % charSetSize);

      // -------------------------------------------------------------------- 
      // Step C & D:
      // Translate current binary value to a PassTicket character
      // Set the PassTicket character into the output PassTicket char array
      // -------------------------------------------------------------------- 
      passTicketCharArray[i] = EnhancedPassTicketGenerator.passTicketChars[curChar];

      // -------------------------------------------------------------------- 
      // Step E & F:
      // Divide current long PassTicket binary value by the character set size 
      // -------------------------------------------------------------------- 
      longPassTicket = longPassTicket / charSetSize;
    }

    // -------------------------------------------------------------------- 
    // Step H:
    // Convert char array to Java String
    // Final PassTicket value is assembled
    // -------------------------------------------------------------------- 
    String ptString = String.valueOf(passTicketCharArray);

    return ptString;
  }
}