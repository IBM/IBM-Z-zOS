import java.util.Enumeration;
import java.util.Hashtable;

import com.ibm.security.userregistry.*;
import com.ibm.eserver.zos.racf.userregistry.*;

import javax.naming.directory.BasicAttribute;
import javax.naming.directory.BasicAttributes;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import javax.naming.directory.ModificationItem;
import javax.naming.directory.SearchControls;
import javax.naming.directory.SearchResult;
import javax.naming.*;



////////////////////////////////////////////////////////////////////////////////////////
// The following sample code can be used to search a RACF database for users or groups
// that begin with a particular string.  The default of an
// empty string shown below will return all users and groups.
// But one could use 'java SearchUsersAndGroups b' to find all users
// and groups that begin with the letter 'B'.
////////////////////////////////////////////////////////////////////////////////////////
public class SearchUsersAndGroups {


  public static void main(String[] args)
    {
    String search_string;
    InitialDirContext ctx = null;
    NamingEnumeration answer = null;


    if (args.length > 0)
      {
      search_string = args[0];
      }
    else search_string = "";

/////////////////////////////////////////////////////////////////////////////////
//  We define a RACF_remote object not to get a RACF_SecAdmin object, but
//  simply because this is how we have defined our connection information in
//  all the other samples.   We use the RACF_remote object in such a way that
//  the rest of the code could be cut and pasted into code that was using JSec.
////////////////////////////////////////////////////////////////////////////////
      RACF_remote remote = new RACF_remote("ldap://alps4014.pok.ibm.com:389",
         "simple",
         "IBMUSER",
         "secret",       // password during testing
         "o=racfdb,c=us");


////////////////////////////////////////////////////////////////////////////////
//  The following code is using LDAP/SDBM to connect to RACF
///////////////////////////////////////////////////////////////////////////////
      String ldap_suffix = remote.getConnect_suffix();  // diff for each system

      try
        {
        SecAdmin racfAdmin = new RACF_SecAdmin(remote);
        if (racfAdmin != null)
          {
          Hashtable hashtable = new Hashtable(7);
          hashtable.put(Context.INITIAL_CONTEXT_FACTORY,
              "com.sun.jndi.ldap.LdapCtxFactory");
          hashtable.put(Context.PROVIDER_URL, remote.getConnect_url() );
          hashtable.put(Context.SECURITY_AUTHENTICATION, "simple");  // if second parm to RACF_REMOTE is 'secure' then use 'ssl' here
          String dn = "racfid=" + remote.getConnect_principal() + ",profiletype=user," + remote.getConnect_suffix();
          hashtable.put(Context.SECURITY_PRINCIPAL, dn);
          hashtable.put(Context.SECURITY_CREDENTIALS, remote.getConnect_credentials());

          try
          {
          // Create initial context
          ctx = new InitialDirContext(hashtable);
          } catch (NamingException e)
            {
            System.out.println("Error initially connecting to LDAP/SDBM."+e.getMessage());
            }


////////////////////////////////////////////////////////////////////////////////
// Initialize some parameters we'll need
///////////////////////////////////////////////////////////////////////////////
          String[] attrIDs = {"racfid"};
          SearchControls ctls = new SearchControls();
          ctls.setReturningAttributes(attrIDs);
      	  //Specify the search scope
  	  ctls.setSearchScope(SearchControls.SUBTREE_SCOPE);

          String filter = "racfid="+search_string+"*";
          System.out.println("filter looks like: "+filter);


////////////////////////////////////////////////////////////////////////////////
//  the specific code for searching for users
///////////////////////////////////////////////////////////////////////////////
          try
          {
          answer = ctx.search("profiletype=user,"+ldap_suffix, filter,ctls);
          }
          catch (javax.naming.NamingException ne)
          {
          String e_text = ne.getMessage();
          if (e_text.toUpperCase().indexOf("NO ENTRIES MEET SEARCH CRITERIA") > -1)
            answer = null;
            else throw ne;
          }

////////////////////////////////////////////////////////////////////////////////
// Display any userids we find
///////////////////////////////////////////////////////////////////////////////
          if (answer != null)
            {
        	while (answer.hasMoreElements()) {
				SearchResult sr = (SearchResult)answer.next();
	            System.out.println("Userid: " + deLDAP(sr.getName()));
				}
            }
          else System.out.println("System didn't find matching user");

////////////////////////////////////////////////////////////////////////////////
//  the specific code for searching for groups
///////////////////////////////////////////////////////////////////////////////
         try
          {
          answer = ctx.search("profiletype=group,"+ldap_suffix, filter,ctls);
          }
          catch (javax.naming.NamingException ne)
          {
          String e_text = ne.getMessage();
          if (e_text.toUpperCase().indexOf("NO ENTRIES MEET SEARCH CRITERIA") > -1)
            answer = null;
            else throw ne;
          }


////////////////////////////////////////////////////////////////////////////////
// Display any groupnames we find
///////////////////////////////////////////////////////////////////////////////
          if (answer != null)
            {
        	while (answer.hasMoreElements()) {
				SearchResult sr = (SearchResult)answer.next();
	            System.out.println("Group: " + deLDAP(sr.getName()));
				}
            }
          else System.out.println("System didn't find matching group");



        }    // end if racf_admin is not null
        } catch (Exception e)
        {
        System.out.println("Exception in SearchUsersAndGroups.java " + e.getMessage() + "\n");
        e.printStackTrace();
        }

    }

  /**
  *
  * @param in String that may or may not be a userid or groupname in LDAP DN format
  * @return   String that is striped of any LDAP stuff
  *
  * example: in: "racfid=IBMUSER,profiletype=USER,o=racfdb,c=us"
  *          returns "IBMUSER"
  */
 protected static String deLDAP(String in)
   {

   if (in == null)             // protect against bad input
     return in;

   String out;
   String lower_in = in.toLowerCase();

   String racfid = "racfid=";
   int pos = lower_in.indexOf("racfid=");
   if (pos > -1)
     {
     int comma = in.indexOf(',',pos);
     if (comma > -1)
       out = in.substring(pos+racfid.length(),comma);
     else out = in.substring(pos+racfid.length());
     return out;
     }
   else return in;
   }


}
