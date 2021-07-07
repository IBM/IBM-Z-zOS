import com.ibm.eserver.zos.racf.userregistry.*;
import com.ibm.security.userregistry.*;
import javax.naming.*;
import javax.naming.directory.*;
import java.util.Enumeration;

public class DeleteGroupWithMembers {


  public static void main(String[] args)
    {
      SecAdmin racfAdmin = null;
      UserGroup dwarves = null;
      User dwarf;

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
      // Show the members of Dwarves
      /////////////////////////////////////////////////////////////////////
        System.out.println("Dwarves Members:");
        try
        {
        dwarves = racfAdmin.getGroup("dwarves");
        }
     catch (SecAdminException e)
        {
        System.out.println("Problem getting userGroup 'dwarves'. "+e.getMessage());
        return;
        }
        Enumeration ae = dwarves.members();
        if (ae == null)
          {
          System.out.println("None");
          }
        else
        {
        while(ae.hasMoreElements())
          {
          User user = (User)ae.nextElement();
          System.out.println(user.getName());
          }
        }
      /////////////////////////////////////////////////////////////////////
      // Now delete the users (Dwarves)
      /////////////////////////////////////////////////////////////////////
      try
        {
        System.out.println("Now we delete the userids that belonged to Dwarves.");
        System.out.println(
        "We could also just remove them from the group, but we delete so CreateGroupsandMembers can create them.");
        racfAdmin.deleteUser("Sleepy");
        racfAdmin.deleteUser("Grumpy");
        racfAdmin.deleteUser("Sneezy");
        racfAdmin.deleteUser("Dopey");
        racfAdmin.deleteUser("Bashful");
        racfAdmin.deleteUser("Happy");
        racfAdmin.deleteUser("Doc");
        }
     catch (SecAdminException e)
        {
        System.out.println("Exception trying to delete users. "+e.getMessage());
        return;
        }


      /////////////////////////////////////////////////////////////////////
      // Again, show the members of Dwarves
      /////////////////////////////////////////////////////////////////////
        System.out.println("Dwarves Members:");
        ae = dwarves.members();
        if (ae == null)
          {
          System.out.println("None");
          }
        else
        {
        while(ae.hasMoreElements())
          {
          User user = (User)ae.nextElement();
          System.out.println(user.getName());
          }
        }

       /////////////////////////////////////////////////////////////////////
      // Finally delete the group named dwarves
      /////////////////////////////////////////////////////////////////////
      try
        {
        racfAdmin.deleteGroup("dwarves");
        System.out.println("We just deleted a group called Dwarves.");
        }
      catch (SecAdminException e)
        {
        System.out.println("Unable to delete group 'dwarves'. "+e.getMessage());
        return;
        }



  }

}
