import com.ibm.eserver.zos.racf.userregistry.*;
import com.ibm.security.userregistry.*;
import javax.naming.*;
import javax.naming.directory.*;
import java.util.Enumeration;

public class CreateGroupsAndMembers {


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
      // Define create a group named dwarves
      /////////////////////////////////////////////////////////////////////
      try
        {
        dwarves = racfAdmin.createGroup("dwarves", null);
        System.out.println("We just created a group called Dwarves.");
        }
      catch (SecAdminException e)
        {
        System.out.println("Unable to create group 'dwarves'. "+e.getMessage());
        return;
        }

      /////////////////////////////////////////////////////////////////////
      // Show the members of Dwarves
      /////////////////////////////////////////////////////////////////////
        System.out.println("Dwarves Members:");
        for (Enumeration ae = dwarves.members(); ae.hasMoreElements();)
          {
          User user = (User)ae.nextElement();
          System.out.println(user.getName());
          }

      /////////////////////////////////////////////////////////////////////
      // Add some members to Dwarves
      /////////////////////////////////////////////////////////////////////
      try
        {
        System.out.println("Now we are going to add some members.");
        dwarves.addMember(racfAdmin.createUser("Sleepy",null));
        dwarves.addMember(racfAdmin.createUser("Grumpy",null));
        dwarves.addMember(racfAdmin.createUser("Sneezy",null));
        dwarves.addMember(racfAdmin.createUser("Dopey",null));
        dwarves.addMember(racfAdmin.createUser("Bashful",null));
        dwarves.addMember(racfAdmin.createUser("Happy",null));
        dwarves.addMember(racfAdmin.createUser("Doc",null));
        }
     catch (SecAdminException e)
        {
        System.out.println("Exception trying to add members to group 'dwarves'. "+e.getMessage());
        return;
        }

      /////////////////////////////////////////////////////////////////////
      // Again, show the members of Dwarves
      /////////////////////////////////////////////////////////////////////
        System.out.println("Dwarves Members:");
        for (Enumeration ae = dwarves.members(); ae.hasMoreElements();)
          {
          User user = (User)ae.nextElement();
          System.out.println(user.getName());
          }

        /////////////////////////////////////////////////////////////////////
        // Now let's modify the membership attributes of User Doc
        /////////////////////////////////////////////////////////////////////
      try
        {
        System.out.println("Doc is leader of the group, should be SPECIAL.");
        ModificationItem mods[] = new ModificationItem[1];
        mods[0] = new ModificationItem(DirContext.ADD_ATTRIBUTE,
        new BasicAttribute("BASE_SPECIAL"));
        dwarf = racfAdmin.getUser("DOC");
        dwarves.modifyMembershipAttributes(dwarf,mods);

        }
      catch (SecAdminException e)
        {
        System.out.println("Error modifying membership attributes "+e.getMessage());
        return;
        }


        //////////////////////////////////////////////////////////////////////////
        // Display the membership attributes of Doc and Happy
        //////////////////////////////////////////////////////////////////////////
       try
        {
        BasicAttributes member_at = dwarves.getMembershipAttributes(dwarf);
        System.out.println("Membership attributes returned for DOC are: ");
        RACF_SecAdmin.displayAttributes(member_at);

        // Now we are going to get and display the membership attributes of HAPPY
        dwarf = racfAdmin.getUser("HAPPY");
        member_at = dwarves.getMembershipAttributes(dwarf);
        System.out.println("Membership attributes returned for HAPPY are: ");
        RACF_SecAdmin.displayAttributes(member_at);
        }
      catch (SecAdminException e)
        {
        System.out.println("Error retrieving membership attributes "+e.getMessage());
        return;
        }




  }

}
