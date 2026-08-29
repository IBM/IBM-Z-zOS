/*                                                                   */
/* Copyright 2023 IBM Corp.                                          */
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
import com.ibm.eserver.zos.racf.userregistry.*;
import com.ibm.security.userregistry.*;
import javax.naming.*;
import javax.naming.directory.*;

public class DeleteProtectedUserid {


  public static void main(String[] args)
    {
      SecAdmin racfAdmin = null;
      User protect = null;
      /////////////////////////////////////////////////////////////////////
      //  Instantiate RACF_remote object with connection data:
      /////////////////////////////////////////////////////////////////////
      RACF_remote remote = new RACF_remote("ldap://alps4014.pok.ibm.com:389",
         "simple",
         "IBMUSER",      // userid for sample/testing
         "secret",       // password during testing
         "o=racfdb,c=us");     // ldap suffix on sample/test system

      /////////////////////////////////////////////////////////////////////
      //  Create a new RACF_SecAdmin object.  This will create connection
      //  to RACF database with authority of userid provided in RACF_remote
      //  object.
      /////////////////////////////////////////////////////////////////////
      try
        {
        racfAdmin = new RACF_SecAdmin(remote);
        }
      catch (SecAdminException e)
        {
        System.out.println("Unable to connect to specified RACF database. "+e.getMessage());
        return;
        }


        ////////////////////////////////////////////////////////////////////
        // Now delete the userid we just created, so the testcase can be
        // run repeatedly.
        /////////////////////////////////////////////////////////////////////
       try
        {
        racfAdmin.deleteUser("protect");
        System.out.println("Successfully deleted userid 'protect'.");
        }
        catch (Exception e)
        {
        System.out.println("Exception deleting user protect: "+e.getMessage());
        }

  }

}
