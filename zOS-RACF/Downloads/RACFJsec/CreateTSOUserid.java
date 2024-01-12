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

public class CreateTSOUserid {


  public static void main(String[] args)
    {
      SecAdmin racfAdmin = null;
      User catuser = null;
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


      /////////////////////////////////////////////////////////////////////
      // Define the user attributes and create the user
      /////////////////////////////////////////////////////////////////////
      try
        {
          BasicAttributes ba = new BasicAttributes();
          BasicAttribute pwd = new BasicAttribute("base_password");
          pwd.add("meow");       // cat simply has to enter �meow� to log on
          pwd.add("noexpired");
          ba.put(pwd);
          ba.put(new BasicAttribute("TSO"));
          catuser = (User)racfAdmin.createUser("cat", ba);
          System.out.println("You have successfully created TSO user cat, password meow.  Try logging on if you don't believe me.");
        }
      catch (SecAdminException e)
        {
        System.out.println("Unable to create user 'cat'. "+e.getMessage());
        return;
        }

        /////////////////////////////////////////////////////////////////////
        // Get the user attributes of the recently created user
        // and display the BASE_PASSWORD attribute
        /////////////////////////////////////////////////////////////////////
      try
        {
        BasicAttributes u_at = catuser.getAttributes();
        System.out.println(u_at.get("BASE_PASSWORD"));
        }
      catch (SecAdminException e)
        {
        System.out.println("Error retrieving attributes "+e.getMessage());
        return;
        }


  }

}
