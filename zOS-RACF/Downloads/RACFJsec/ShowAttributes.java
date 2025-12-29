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
