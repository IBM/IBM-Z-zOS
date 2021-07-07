import com.ibm.eserver.zos.racf.userregistry.*;
import com.ibm.security.userregistry.*;


public class ShowAttributes {


  public static void main(String[] args)
    {
    System.out.print("The point of this program is to demonstrate how simply one can call");
    System.out.print(" RACF_User.attributesHTML, RACF_Group.attributesHTML and RACF_Group.membershipAttributesHTML. ");
    System.out.println(" The output should be displayed in a web browser.");
    System.out.println(" ");
    ///////////////////////////////////////////////////////////////////////////////////////////////
    System.out.println("-------------  Start of output from RACF_User.attributesHTML------------\n");
    System.out.println(RACF_User.attributesHTML());

    System.out.println("-------------  End of output from RACF_User.attributesHTML------------\n");

    System.out.println("-------------  Start of output from RACF_Group.attributesHTML------------");
    System.out.println(RACF_Group.attributesHTML());

    System.out.println("-------------  End of output from RACF_Group.attributesHTML------------");
        System.out.println("-------------  Start of output from RACF_Group.membershipAttributesHTML------------");
    System.out.println(RACF_Group.membershipAttributesHTML());

    System.out.println("-------------  End of output from RACF_Group.membershipAttributesHTML------------");

  }

}
