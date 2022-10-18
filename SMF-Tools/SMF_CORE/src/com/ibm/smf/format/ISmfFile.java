/*                                                                   */
/* Copyright 2021 IBM Corp.                                          */
/*                                                                   */
/* Licensed under the Apache License, Version 2.0 (the "License");   */
/* you may not use this file except in compliance with the License.  */
/* You may obtain a copy of the License at                           */
/*                                                                   */
/* http://www.apache.org/licenses/LICENSE-2.0                        */
/*                                                                   */
/* Unless required by applicable law or agreed to in writing,        */
/* software distributed under the License is distributed on an       */
/* "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,      */
/* either express or implied. See the License for the specific       */
/* language governing permissions and limitations under the License. */
/*                                                                   */

package com.ibm.smf.format;

//------------------------------------------------------------------------------
/** Interface to make the SmfFile interpreter RMI capable. 
 * This enables processing of records on the local system 
 * which were read on another system and then transferred
 * by RMI to the local system.
 * Using that procedure enables interactive debug of the
 * Smf record interpreter with the help of PC tools.
 */
public interface ISmfFile extends java.rmi.Remote {
  
  /** Opens a SmfFile as specified by a name.
   * @param aSmfFilename name of the Smf file.
   * @throws java.io.IOException in case of IO errors.
   * @throws java.rmi.RemoteException as all RMI code.
   */
  public void open(String aSmfFilename)
    throws 
      java.io.IOException,
      java.rmi.RemoteException;

  /** Close the SmfFile. 
   * @throws java.io.IOException in case of IO errors.
   * @throws java.rmi.RemoteException as all RMI code.
   */ 
  public void close()
    throws 
      java.io.IOException,
      java.rmi.RemoteException;

  /** Read an array of bytes from the SmfFile. 
   * @return array of bytes.
   * @throws java.io.IOException in case of IO errors.
   * @throws java.rmi.RemoteException as all RMI code.
   */ 
  public byte[] read()
    throws 
      java.io.IOException,
      java.rmi.RemoteException;

} // ISmfFile
