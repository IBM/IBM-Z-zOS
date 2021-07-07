import com.ibm.eserver.zos.racf.userregistry.*;
import com.ibm.security.userregistry.*;
import javax.naming.*;
import javax.naming.directory.*;

public class CreateProtectedUserid {


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


      /////////////////////////////////////////////////////////////////////
      // Define the user attributes and create the user
      /////////////////////////////////////////////////////////////////////
      try
        {
        BasicAttributes ba = new BasicAttributes();
        BasicAttribute pwd = new BasicAttribute("base_password");
        pwd.add("nopassword");
        ba.put(pwd);
        protect = racfAdmin.createUser("protect", ba);
        System.out.println("Successfully created userid 'protect'.");
        }
      catch (SecAdminException e)
        {
        System.out.println("Unable to create user 'protect'. "+e.getMessage());
        return;
        }

        /////////////////////////////////////////////////////////////////////
        // Get the user attributes of the recently created user
        // and display the BASE_PASSWORD attribute
        /////////////////////////////////////////////////////////////////////
      try
        {
        BasicAttributes prot_at = protect.getAttributes();
        System.out.println(prot_at.get("BASE_PASSWORD"));
        }
      catch (SecAdminException e)
        {
        System.out.println("Error retrieving attributes "+e.getMessage());
        return;
        }

 
  }

}
