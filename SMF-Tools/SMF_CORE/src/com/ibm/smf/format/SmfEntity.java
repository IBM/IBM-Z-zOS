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
/** Base class for versioned SMF entities. */
public abstract class SmfEntity {
  
  /** Version of this instance of SmfEntity. */
  private int m_version = 0;
  
  //----------------------------------------------------------------------------
  /** Creates an instance of SmfEntity with the specified version.
   * @param aVersion Version of the entity as requested from the SmfRecord.
   * @throws UnsupportedVersionException Exception thrown when requested version does is higher than supported version.
   */
  public SmfEntity(int aVersion) throws UnsupportedVersionException {
    
    setVersion(aVersion);
    
  } // SmfEntity()
  
  //----------------------------------------------------------------------------
  /** Returns the version of this SmfEntity.
   * @return Version of this SmfEntity.
   */
  public int version() {
    
    return m_version;
    
  } // version()
  
  //----------------------------------------------------------------------------
  /** Returns the version supported by the implementation of SmfEntity as provided by a derived class.
   * @return version supported by the implementation of SmfEntity as given by a derived class.
   */
  public abstract int supportedVersion();
  
  //----------------------------------------------------------------------------
  /** Sets the version as requested by the SmfRecord.
   * @param aVersion Version as requested for this instance of SmfEntity.
   * @throws UnsupportedVersionException Exception thrown when the requested version is not supported.
   */
  protected void setVersion(int aVersion)
  throws UnsupportedVersionException {
    
    int supportedVersion = supportedVersion();
    
    if (aVersion > supportedVersion) {
      throw new UnsupportedVersionException(
      getClass().getName(),
      supportedVersion,
      aVersion);
    }
    m_version = aVersion;
    
  } // setRecordVersion(...)
  
} // SmfEntity