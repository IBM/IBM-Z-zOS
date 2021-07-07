import com.ibm.eserver.zos.racf.userregistry.*;
import com.ibm.security.userregistry.*;
import javax.naming.*;
import javax.naming.directory.*;

public class DeleteTSOUserid {


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
        racfAdmin.deleteUser("cat");
        System.out.println("Successfully deleted userid 'cat'.");
        }
        catch (Exception e)
        {
        System.out.println("Exception deleting user cat: "+e.getMessage());
        }

  }

}
