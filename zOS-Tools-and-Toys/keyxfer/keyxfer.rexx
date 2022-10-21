/* REXX ***************************************************************
**                                                                   **
** Copyright 2009-2020 IBM Corp.                                     **
**                                                                   **
**  Licensed under the Apache License, Version 2.0 (the "License");  **
**  you may not use this file except in compliance with the License. **
**  You may obtain a copy of the License at                          **
**                                                                   **
**     http://www.apache.org/licenses/LICENSE-2.0                    **
**                                                                   **
**  Unless required by applicable law or agreed to in writing,       **
**  software distributed under the License is distributed on an      **
**  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,     **
**  either express or implied. See the License for the specific      **
**  language governing permissions and limitations under the         **
**  License.                                                         **
**                                                                   **
** ----------------------------------------------------------------- **
**                                                                   **
** Disclaimer of Warranties:                                         **
**                                                                   **
**   The following enclosed code is sample code created by IBM       **
**   Corporation.  This sample code is not part of any standard      **
**   IBM product and is provided to you solely for the purpose       **
**   of assisting you in the development of your applications.       **
**   The code is provided "AS IS", without warranty of any kind.     **
**   IBM shall not be liable for any damages arising out of your     **
**   use of the sample code, even if they have been advised of       **
**   the possibility of such damages.                                **
**                                                                   **
**                                                                   **
**********************************************************************/

/*********************************************************************/
/*                           KEYXFER                                 */
/*                Key Transfer Utility                               */
/*                                                                   */
/* DESCRIPTION:   This tool is intended to facilitate the transfer   */
/*                of PKDS or CKDS key tokens between systems.        */
/*                A key token is extracted and stored in a file.     */
/*                The file can be sent to another system and this    */
/*                utility can be used to read the key token from the */
/*                file and place it in the PKDS or CKDS              */
/*                of the new system.                                 */
/*                                                                   */
/*                The token is referenced by PKDS/CKDS label.        */
/*                The arguements for the utility are specified below */
/*                                                                   */
/*                OPER_CMD  = READ from file to PKDS                 */
/*                            WRITE from PKDS to file                */
/*                            READ_PKDS from file to PKDS            */
/*                            WRITE_PKDS from PKDS to file           */
/*                            READ_CKDS from file to CKDS            */
/*                            WRITE_CKDS from CKDS to file           */
/*          PLABEL    = label of PKDS/CKDS record to be read/written */
/*          DSNAME    = name of file holding the token               */
/*          OPTIONS   = OVERWRITE a label in the PKDS/CKDS.          */
/*                      If OVERWRITE is specified in the options     */
/*                      field then an existing PKDS/CKDS label will  */
/*                      be overwritten with the token from the       */
/*                      input file.                                  */
/*                      DEBUG can be specified to print out file data*/
/*                                                                   */
/* FILE OUTPUT:   A PS or PDS file can be used.                      */
/*                An LRECL=80 is recommended, but not required.      */
/*                The information stored in the KEYXFER file         */
/*                consists of the following:                         */
/*                                                                   */
/*           For PKDS:                                               */
/*                    Date                                           */
/*                    PKDS  label                                    */
/*                    Length of token                                */
/*                    Token                                          */
/*                                                                   */
/*           For CKDS:                                               */
/*                    Date                                           */
/*                    CKDS  label                                    */
/*                    Token                                          */
/*                                                                   */
/*                                                                   */
/* USAGE:                                                            */
/*  **PKDS                                                           */
/*           KEYXFER WRITE_PKDS, PKDS.KEY.LABEL, TEMP.MEM            */
/*                                                                   */
/*                      - write the key token stored in the PKDS     */
/*                        under the label PKDS.KEY.LABEL to the      */
/*                        file  TEMP.MEM                             */
/*                                                                   */
/*           KEYXFER READ_PKDS,  PKDS.KEY.LABEL, TEMP.MEM            */
/*                                                                   */
/*                      - read  the key token contained in the file  */
/*                        TEMP.MEM  and  write the token to the PKDS */
/*                        under the label PKDS.KEY.LABEL.            */
/*                        If the label already exists in the PKDS    */
/*                        the operation will fail.                   */
/*                                                                   */
/*                                                                   */
/*           KEYXFER READ_PKDS,  PKDS.KEY.LABEL, TEMP.MEM, OVERWRITE */
/*                                                                   */
/*                      - read  the key token contained in the file  */
/*                        TEMP.MEM  and  write the token to the PKDS */
/*                        under the label PKDS.KEY.LABEL             */
/*                        If the label already exists in the PKDS    */
/*                        the token for that label will be           */
/*                        overwritten.                               */
/*                                                                   */
/*           KEYXFER READ_PKDS, , TEMP.MEM                           */
/*                                                                   */
/*                      - read  the key token contained in the file  */
/*                        TEMP.MEM  and  write the token to the PKDS.*/
/*                        Since no label was specified the label     */
/*                        from the original system will be extracted */
/*                        from the file and used as the label        */
/*                        for the token on the new system.           */
/*                                                                   */
/*     *NOTE:     KEYXFER READ/WRITE defaults to PKDS function       */
/*            ex. KEYXFER WRITE, PKDS.KEY.LABEL, TEMP.MEM            */
/*            -----------is the same as -----------                  */
/*                KEYXFER WRITE_PKDS, PKDS.KEY.LABEL, TEMP.MEM       */
/*                                                                   */
/*                                                                   */
/***CKDS                                                             */
/*                                                                   */
/*          KEYXFER WRITE_CKDS, CKDS.KEY.LABEL, TEMP.MEM             */
/*                                                                   */
/*                      - write the key token stored in the CKDS     */
/*                        under the label CKDS.KEY.LABEL to the      */
/*                        file  TEMP.MEM                             */
/*                                                                   */
/*          KEYXFER READ_CKDS,  CKDS.KEY.LABEL, TEMP.MEM             */
/*                                                                   */
/*                      - read  the key token contained in the file  */
/*                        TEMP.MEM  and  write the token to the CKDS */
/*                        under the label CKDS.KEY.LABEL.            */
/*                        If the label already exists in the CKDS    */
/*                        the operation will fail.                   */
/*                                                                   */
/*          KEYXFER READ_CKDS,  CKDS.KEY.LABEL, TEMP.MEM, OVERWRITE  */
/*                                                                   */
/*                      - read  the key token contained in the file  */
/*                        TEMP.MEM  and  write the token to the CKDS */
/*                        under the label CKDS.KEY.LABEL             */
/*                        If the label already exists in the CKDS    */
/*                        the token for that label will be           */
/*                        overwritten.                               */
/*                                                                   */
/*          KEYXFER READ_CKDS, , TEMP.MEM                            */
/*                                                                   */
/*                      - read  the key token contained in the file  */
/*                        TEMP.MEM  and  write the token to the CKDS.*/
/*                        Since no label was specified the label     */
/*                        from the original system will be extracted */
/*                        from the file and used as the label        */
/*                        for the token on the new system.           */
/*                                                                   */
/*                                                                   */
/*                                                                   */
/* CREATED:       R. J. Edick       IBM CORPORATION         08/24/06 */
/*-------------------------------------------------------------------*/
/* MODIFIED:      Sean R. Hanson    CKDS  option added      05/27/09 */
/*                R. J.   Edick     Debug option added      10/08/09 */
/*                                                                   */
/*********************************************************************/
 PARSE ARG  oper_cmd ',' plabel ',' file_name ',' options

 /*------------------------------------------------------------------*/
 /*         TIME STAMP                                               */
 /*------------------------------------------------------------------*/
  t_stamp = " > "|| DATE('U') || "  " || TIME('C');/* Date/Time Stamp*/
  SAY t_stamp ;                                    /*                */
                                                   /*                */
 /*------------------------------------------------------------------*/
 /*          VALIDATE  arguments                                     */
 /*------------------------------------------------------------------*/
 oper_cmd = STRIP(oper_cmd) ;                     /*                 */
 IF  (oper_cmd \= "READ") & ,                     /*                 */
     (oper_cmd \= "READ_CKDS") & ,                /*                 */
     (oper_cmd \= "READ_PKDS") & ,                /* Operation       */
     (oper_cmd \= "WRITE") & ,                    /*                 */
     (oper_cmd \= "WRITE_PKDS") & ,               /*                 */
     (oper_cmd \= "WRITE_CKDS")                   /*                 */
                                  THEN DO         /*                 */
    SAY "*ERROR*  INVALID OPERATION: '" || oper_cmd || "'";
    EXIT;                                         /*                 */
  END;                                            /*                 */
                                                  /*-----------------*/
 plabel = STRIP(plabel) ;                         /*                 */
 IF  (plabel = "")  THEN  DO;                     /* PLABEL          */
   IF  (oper_cmd = "WRITE") |,                    /*                 */
       (oper_cmd = "WRITE_PKDS") |,               /*                 */
       (oper_cmd = "WRITE_CKDS")                  /*                 */
                             THEN DO              /* There must be   */
     SAY "*ERROR* PKDS/CKDS Label not specified ";/* a label         */
     EXIT;                                        /* specified for   */
   END;                                           /*  file WRITE     */
 END;                                             /*                 */
                                                  /*-----------------*/
 key_file = STRIP(file_name);                     /*                 */
 IF  (key_file = "")  THEN                        /* File Name       */
  DO                                              /*                 */
    SAY "*ERROR*  NO OUTPUT FILE SPECIFIED "      /*                 */
    EXIT;                                         /*                 */
  END;                                            /*                 */
                                                  /*-----------------*/
 overwrite = "NO";                                /* Set option      */
 debug     = "NO";                                /*     defaults    */
 options   = STRIP(options);                      /*                 */
 IF  (options \= "")  THEN                        /*                 */
  DO                                              /*                 */
                                                  /*-----------------*/
    PARSE VAR options  option1 ',' option2        /* Parse options   */
    option1 = STRIP(option1);                     /*                 */
    option2 = STRIP(option2);                     /*                 */
                                                  /*-----------------*/
    SELECT                                        /*                 */
      WHEN  (option1 = "OVERWRITE")  THEN         /* Find option1    */
             overwrite = "YES";                   /*                 */
      WHEN  (option1 = "DEBUG")      THEN         /*                 */
             debug   = "YES"  ;                   /*                 */
      OTHERWISE                                   /*                 */
      DO;                                         /*                 */
        SAY "*ERROR*  INVALID OPTION SPECIFIED "  /*                 */
        EXIT;                                     /*                 */
      END;                                        /*                 */
    END;                                          /*                 */
                                                  /*-----------------*/
    SELECT                                        /*                 */
      WHEN  (option2 = "OVERWRITE")  THEN         /* Find option2    */
             overwrite = "YES";                   /*                 */
      WHEN  (option2 = "DEBUG")      THEN         /*                 */
             debug   = "YES"  ;                   /*                 */
      WHEN  (option2 = "")           THEN         /*                 */
             opt_cnt = 1;                         /*                 */
      OTHERWISE                                   /*                 */
      DO;                                         /*                 */
        SAY "*ERROR*  INVALID OPTION SPECIFIED "  /*                 */
        EXIT;                                     /*                 */
      END;                                        /*                 */
    END;                                          /*                 */
                                                  /*-----------------*/
  END;                                            /*                 */
                                                  /*                 */
 /*------------------------------------------------------------------*/
 /*          Check for existance of file for READ                    */
 /*------------------------------------------------------------------*/
 key_file = "'" || key_file || "'" ;              /* Fully qualify   */
                                                  /* file name       */
                                                  /*-----------------*/
 fid = "KEYFILE";                                 /* Set DD name     */
                                                  /*                 */
 /*------------------------------------------------------------------*/
 /* Read  token from file                                            */
 /*------------------------------------------------------------------*/
 IF  (oper_cmd = "READ")      |,                  /*                 */
     (oper_cmd = "READ_PKDS") |,                  /*                 */
     (oper_cmd = "READ_CKDS")   THEN              /*                 */
 DO;                                              /*                 */
                                                  /*-----------------*/
   rtn = SYSDSN(key_file);                        /* Check for       */
   IF  (rtn \= "OK")  THEN DO                     /* existance       */
     SAY " *ERROR* " || key_file || "..." || rtn; /*                 */
     EXIT;                                        /*                 */
   END;                                           /*                 */
                                                  /*-----------------*/
   status = MSG('OFF');                           /*                 */
   "FREE  FILE(" fid ")";                         /*                 */
   "FREE  DATASET(" key_file ")" ;                /*                 */
   "ALLOC FILE(" fid ") DSN(" key_file ") SHR";   /* Allocate file   */
   IF  (rc \= 0)  THEN DO                         /*                 */
      SAY  "*ERROR* ... during allocation of ",   /*                 */
            key_file  " (" rc ") "                /*                 */
      EXIT (8) ;                                  /*                 */
   END ;                                          /*                 */
   "EXECIO * DISKR " fid " (FINIS STEM prec."     /* Read file       */
   IF  rc \= 0  THEN DO                           /*                 */
      SAY  "*ERROR* ... during read of " key_file;/*                 */
      EXIT(8);                                    /*                 */
   END;                                           /*                 */
   status = MSG('ON') ;                           /*                 */
                                                  /*-----------------*/
   IF (oper_cmd = "READ")       |,                /*                 */
      (oper_cmd = "READ_PKDS")  THEN              /*                 */
   DO;                                            /*                 */
         IF  (prec.0 < 4)  THEN DO                /* Need to be      */
             SAY " >" key_file " missing data ";  /* at least 4 lines*/
             SIGNAL CLEANUP;                      /* of data in the  */
         END;                                     /* file for PKDS   */
                                                  /*-----------------*/
         tdate   = prec.1 ;                       /*                 */
         tname   = STRIP(prec.2);                 /* If _PKDS then   */
         tok_len = STRIP(prec.3);                 /* Recover         */
         token   = "";                            /* token from PKDS */
         DO  n = 4 TO prec.0                      /*                 */
             token = token || STRIP(prec.n) ;     /*                 */
         END;                                     /*                 */
                                                  /*-----------------*/
                                                  /* If no PLABEL    */
      IF  (LENGTH(plabel) = 0)  THEN              /* passed then     */
              plabel = tname ;                    /* use name in     */
                                                  /* file            */
                                                  /*-----------------*/
       rtn = PKDS_WRITE(plabel,                   /*                 */
                        ,tok_len,                 /*                 */
                        ,token,                   /*  Write token    */
                        ,overwrite,               /*  to the PKDS    */
                        ,debug  );                /*                 */
       IF  (rtn  = 0)  THEN  DO                   /*                 */
          SAY " >" key_file " processed successfully."; /*           */
       END;                                       /*                 */
   END;                                           /*                 */
                                                  /*-----------------*/
   ELSE                                           /*                 */
   DO;                                            /*                 */
     IF  (prec.0 \= 4)  THEN DO                   /* Need to be      */
            SAY " >" key_file " missing data ";   /* exactly 4 lines */
            SIGNAL CLEANUP;                       /* of data in the  */
     END;                                         /* file for CKDS   */
                                                  /*-----------------*/
    tdate   = prec.1 ;                            /* If _CKDS then   */
    tname   = STRIP(prec.2);                      /* Recover         */
    token   = STRIP(prec.3) || STRIP(prec.4);     /* token from CKDS */
                                                  /*-----------------*/
                                                  /* If no PLABEL    */
     IF  (LENGTH(plabel) = 0)  THEN               /* passed then     */
      plabel = tname ;                            /* use name in     */
                                                  /* file            */
                                                  /*-----------------*/
     rtn = CKDS_WRITE(plabel,                     /* Write token     */
                        ,token,                   /* to the CKDS     */
                        ,overwrite,               /*                 */
                        ,debug  );                /*                 */
     IF  (rtn  = 0)  THEN                         /*                 */
        SAY " >" key_file " processed successfully."; /*             */
   END;                                           /*                 */
                                                  /*-----------------*/
 END ;                                            /* END for READ    */
                                                  /*                 */
 /*------------------------------------------------------------------*/
 /* Write token to file                                              */
 /*------------------------------------------------------------------*/
 IF  (oper_cmd = "WRITE")        |,               /*  If WRITE       */
      (oper_cmd = "WRITE_PKDS")  |,               /*  enter WRITE    */
      (oper_cmd = "WRITE_CKDS")  THEN             /*  function       */
 DO;                                              /*                 */
                                                  /*-----------------*/
   IF  (oper_cmd = "WRITE") |,                    /*                 */
       (oper_cmd = "WRITE_PKDS") THEN             /*                 */
   DO;                                            /*                 */
                                                  /* If PKDS         */
         rtn = PKDS_READ(plabel) ;                /* Get token       */
                                                  /* from the PKDS   */
     PARSE VAR rtn retc ':'  token_len ':'token   /*-----------------*/
     IF  (retc \= "00000000")  THEN DO            /*                 */
        SAY " * PKDS read of " plabel " unsuccessful";
        EXIT;                                     /*                 */
     END;                                         /*                 */
                                                  /*-----------------*/
     status = MSG('OFF');                         /*                 */
     "FREE  FILE(" fid ")";                       /*                 */
     "FREE  DATASET(" key_file ")" ;              /*                 */
     "ALLOC FILE(" fid ") DSN(" key_file ") SHR"; /*                 */
     "EXECIO 0 DISKW " fid " (OPEN";              /*                 */
      IF  (RC > 0)  THEN DO                       /* Allocate file   */
          SAY "*ERROR*  ",                        /*                 */
              " open of " key_file " for WRITE";  /*                 */
          SAY "         RTN = " RC ;              /*                 */
          EXIT ;                                  /*                 */
      END;                                        /*                 */
       status = MSG('ON') ;                       /*                 */
                                                  /*-----------------*/
     pref = " ";                                  /*                 */
     prec.1 = pref || t_stamp;                    /* Create header   */
     prec.2 = pref || STRIP(plabel);              /*                 */
     prec.3 = pref || STRIP(token_len)            /*                 */
                                                  /*-----------------*/
     token  = STRIP(token) ;                      /*                 */
     tlen = LENGTH(token) - 1;                    /* Compute number  */
     blk_cnt = (tlen%64) + 1;                     /* of output blocks*/
                                                  /* for token       */
     token = LEFT(token, 64*blk_cnt);             /* and pad token   */
                                                  /*-----------------*/
     cnt   = 3;                                   /*                 */
     index = 1;                                   /*                 */
     DO  n = 1 TO blk_cnt                         /*                 */
       cnt      = cnt + 1;                        /*                 */
       prec.cnt = pref || SUBSTR(token,index,64); /*                 */
       index    = index + 64;                     /*                 */
     END;                                         /*                 */
     prec.0 = cnt;                                /*                 */
   END;                                           /*                 */
                                                  /*-----------------*/
   IF (oper_cmd = "WRITE_CKDS") THEN              /* For CKDS        */
   DO;                                            /*                 */
     rtn = CKDS_READ(plabel) ;                    /* Get token       */
                                                  /* from the CKDS   */
    PARSE VAR rtn retc ':' token                  /*-----------------*/
    IF  (retc \= "00000000")  THEN DO             /*                 */
      SAY " *CKDS read of " plabel " unsuccessful";/*                 */
      EXIT;                                       /*                 */
    END;                                          /*-----------------*/
    ELSE DO                                       /*                 */
      status = MSG('OFF');                        /*                 */
      "FREE  FILE(" fid ")";                      /*                 */
      "FREE  DATASET(" key_file ")" ;             /*                 */
      "ALLOC FILE(" fid ") DSN(" key_file ") SHR";/*                 */
      "EXECIO 0 DISKW " fid " (OPEN";             /*                 */
       IF  (RC > 0)  THEN DO                      /* Allocate file   */
           SAY "*ERROR*  ",                       /*                 */
               " open of " key_file " for WRITE"; /*                 */
           SAY "         RTN = " RC ;             /*                 */
           EXIT ;                                 /*                 */
       END;                                       /*                 */
       status = MSG('ON') ;                       /*                 */
      token = STRIP(token) ;                      /*-----------------*/
      pref = " ";                                 /*                 */
      prec.1 = pref || t_stamp;                   /*                 */
      prec.2 = pref || STRIP(plabel);             /* Create header   */
      prec.3 = pref || SUBSTR(token,1,64);        /* CKDS should     */
      prec.4 = pref || SUBSTR(token,65,64);       /* always be 4     */
      prec.0 = 4;                                 /* lines           */
    END;                                          /*                 */
                                                  /*-----------------*/
   END;                                           /*                 */
 /*==================================================================*/
   IF  (debug = "YES")  THEN
   DO;
     SAY " ---------- ";
     SAY "  OUT FILE: " || key_file;
     DO  n = 1 TO prec.0;
         SAY "  " || prec.n ;
     END;
     SAY " ---------- ";
   END;
 /*==================================================================*/
                                                  /*-----------------*/
     "EXECIO * DISKW " fid " (FINIS STEM prec.";  /* Write token data*/
                                                  /* to file         */
                                                  /*-----------------*/
     SAY " >" plabel "  written to " key_file;    /*                 */
                                                  /*-----------------*/
 END;                                             /* END for WRITE   */
                                                  /*-----------------*/
                                                  /*                 */
 /*------------------------------------------------------------------*/
 /*         File Close                                               */
 /*------------------------------------------------------------------*/
CLEANUP:                                          /*                 */
 status = MSG('OFF');                             /*                 */
 "FREE  FILE(" fid ")";                           /* Free DD         */
 "FREE  DATASET(" key_file ")" ;                  /*  and DSN        */
 status = MSG('ON') ;                             /*                 */
                                                  /*                 */
 /*------------------------------------------------------------------*/
 /*    EXIT                                                          */
 /*------------------------------------------------------------------*/
  EXIT ;                                          /*    End          */
                                                  /*-----------------*/




 /********************************************************************/
 /***                   PKDS READ                                  ***/
 /********************************************************************/
 PKDS_READ:  PROCEDURE
  ARG  name
 /*------------------------------------------------------------------*/
 /*  Call KRR                                                        */
 /*------------------------------------------------------------------*/
 label = LEFT(name, 64) ;                         /*                 */
                                                  /*-----------------*/
 retx       = "00000000"x;                        /*                 */
 reasx      = "00000000"x;                        /*                 */
 exit_lenx  = "00000000"x;                        /*                 */
 exit_data  = "NONE";                             /*                 */
 rule_cntx  = "00000000"x;                        /*                 */
 rule_str   = "IGNORED ";                         /*                 */
 token_lenx = "00000600"x;                        /*                 */
 tokenx     = COPIES("00"x, 1600);                /*                 */
                                                  /*-----------------*/
 address linkpgm 'CSNDKRR' ,
                 ' retx'          ' reasx',
                 ' exit_lenx'     'exit_data',
                 ' rule_cntx'     'rule_str',
                 ' label',
                 ' token_lenx'    'tokenx'  ;
                                                  /*-----------------*/
 ret  = C2X(retx);                                /*                 */
 reas = C2X(reasx);                               /*                 */
 IF  (ret > 4)  THEN                              /*                 */
  DO                                              /*                 */
    IF  (reas \= "0000271C")  THEN                /*                 */
    DO                                            /*                 */
      SAY " ERROR KRR FAILED WITH  " || ret || " / " || reas ;
      SAY "       KRR LABEL:       " || label ;   /*                 */
      RETURN "" ;                                 /*                 */
    END ;                                         /*                 */
    ELSE                                          /*                 */
    DO                                            /*                 */
      SAY " ERROR KRR FAILED WITH  " || ret || " / " || reas ;
      SAY " ERROR " STRIP(label) " NOT FOUND ";   /*                 */
      RETURN "" ;                                 /*                 */
    END ;                                         /*                 */
  END ;                                           /*                 */
                                                  /*-----------------*/
 token_len = C2D(token_lenx) ;                    /* Obtain token    */
 tokenx    = LEFT(tokenx, token_len) ;            /* as hex chars    */
 token     = C2X(tokenx) ;                        /*                 */
                                                  /*-----------------*/
 rtn_str = ret       || ":",                      /*                 */
           token_len || ":",                      /*                 */
           token  ;                               /*                 */
                                                  /*-----------------*/
  RETURN rtn_str ;                                /*                 */
 /*------------------------------------------------------------------*/




 /********************************************************************/
 /***                   PKDS WRITE                                 ***/
 /********************************************************************/
 PKDS_WRITE: PROCEDURE
  PARSE ARG  name,  token_len,  token, over_write, debug_stmt
 /*------------------------------------------------------------------*/
 /*  Initialize                                                      */
 /*------------------------------------------------------------------*/
 label        = LEFT(name, 64) ;                  /*                 */
 label_exists = "";                               /*                 */
                                                  /*-----------------*/
 /*==================================================================*/
 IF  (debug_stmt = "YES")  THEN
 DO;
   SAY " ---------- ";
   SAY "     LABEL: " || label;
   SAY " OVERWRITE: " || over_write;
   SAY " TOKEN LEN: " || token_len;
   SAY "     TOKEN: " ;
   n = 1;
   DO  UNTIL (n > 2*token_len)
       SAY " >" || SUBSTR(token, n, 64);
       n = n + 64;
   END;
   SAY " ---------- ";
 END;
 /*==================================================================*/
 /*------------------------------------------------------------------*/
 /*  Check for existance of label                                    */
 /*------------------------------------------------------------------*/
 retx       = "00000000"x;                        /*                 */
 reasx      = "00000000"x;                        /*                 */
 exit_lenx  = "00000000"x;                        /*                 */
 exit_data  = "NONE";                             /*                 */
 rule_cntx  = "00000000"x;                        /*                 */
 rule_str   = "IGNORED ";                         /*                 */
 token_lenx = "00000600"x;                        /*                 */
 tokenx     = COPIES("00"x, 1600);                /*                 */
                                                  /*-----------------*/
 address linkpgm 'CSNDKRR' ,
                 ' retx'          ' reasx',
                 ' exit_lenx'     'exit_data',
                 ' rule_cntx'     'rule_str',
                 ' label',
                 ' token_lenx'    'tokenx'  ;
                                                  /*-----------------*/
 ret  = C2X(retx);                                /*                 */
 reas = C2X(reasx);                               /*                 */
 IF  (ret  = "00000000")  THEN                    /*                 */
     label_exists = "YES";                        /*                 */
 ELSE                                             /*                 */
 DO;                                              /*                 */
   IF  (ret  = "00000008")  &,                    /*                 */
       (reas = "0000271C")  THEN                  /*                 */
       label_exists = "NO";                       /*                 */
   ELSE                                           /*                 */
    DO                                            /*                 */
      SAY " ERROR KRR FAILED WITH  " || ret || " / " || reas ;
      SAY "       KRR LABEL:       " || label   ; /*                 */
      RETURN ret ;                                /*                 */
    END ;                                         /*                 */
 END;                                             /*                 */
                                                  /*                 */
 /*------------------------------------------------------------------*/
 /*  Create label if it doesn't exist                                */
 /*------------------------------------------------------------------*/
 IF  (label_exists = "NO")  THEN                  /*                 */
 DO;                                              /*                 */
   retx       = "00000000"x;                      /*                 */
   reasx      = "00000000"x;                      /*                 */
   exit_lenx  = "00000000"x;                      /*                 */
   exit_data  = "NONE";                           /*                 */
   rule_cntx  = "00000000"x;                      /*                 */
   rule_str   = "IGNORED ";                       /*                 */
   tokenx     = X2C(token) ;                      /*                 */
   token_len  = D2X(token_len) ;                  /*                 */
   token_len  = RIGHT(token_len, 8, '0');         /*                 */
   token_lenx = X2C(token_len) ;                  /*                 */
                                                  /*-----------------*/
   address linkpgm 'CSNDKRC' ,
                   ' retx'          ' reasx',
                   ' exit_lenx'     'exit_data',
                   ' rule_cntx'     'rule_str',
                   ' label',
                   ' token_lenx'    'tokenx'  ;
                                                  /*-----------------*/
   ret  = C2X(retx);                              /*                 */
   reas = C2X(reasx);                             /*                 */
   IF  (ret  = "00000000")  THEN                  /*                 */
   DO;                                            /*                 */
      SAY " >" name " created ";                  /*                 */
   END;                                           /*                 */
   ELSE                                           /*                 */
   DO;                                            /*                 */
      SAY " ERROR KRC FAILED WITH  " || ret || " / " || reas ;
      SAY "       KRC LABEL:       " || label ;   /*                 */
      RETURN ret;                                 /*                 */
   END;                                           /*                 */
 END;                                             /*                 */
                                                  /*                 */
 /*------------------------------------------------------------------*/
 /*  Overwrite label if it does exist                                */
 /*------------------------------------------------------------------*/
 IF  (label_exists = "YES")  THEN                 /*                 */
 DO;                                              /*                 */
                                                  /*-----------------*/
   IF  (over_write = "NO" )  THEN                 /*                 */
   DO;                                            /*                 */
      SAY "*ERROR* " STRIP(label) " exists ";     /*                 */
      SAY "          - overwrite option has not been specified ";
      RETURN 8;                                   /*                 */
   END;                                           /*                 */
                                                  /*-----------------*/
   retx       = "00000000"x;                      /*                 */
   reasx      = "00000000"x;                      /*                 */
   exit_lenx  = "00000000"x;                      /*                 */
   exit_data  = "NONE";                           /*                 */
   rule_cntx  = "00000001"x;                      /*                 */
   rule_str   = "OVERLAY ";                       /*                 */
   tokenx     = X2C(token) ;                      /*                 */
   token_len  = D2X(token_len) ;                  /*                 */
   token_len  = RIGHT(token_len, 8, '0');         /*                 */
   token_lenx = X2C(token_len) ;                  /*                 */
                                                  /*-----------------*/
   address linkpgm 'CSNDKRW' ,
                   ' retx'          ' reasx',
                   ' exit_lenx'     'exit_data',
                   ' rule_cntx'     'rule_str',
                   ' label',
                   ' token_lenx'    'tokenx'  ;
                                                  /*-----------------*/
   ret  = C2X(retx);                              /*                 */
   reas = C2X(reasx);                             /*                 */
   IF  (ret  = "00000000")  THEN                  /*                 */
   DO;                                            /*                 */
      SAY " >" name " overwritten ";              /*                 */
   END;                                           /*                 */
   ELSE                                           /*                 */
   DO;                                            /*                 */
      SAY " ERROR KRW FAILED WITH  " || ret || " / " || reas ;
      SAY "       KRW LABEL:       " || label ;   /*                 */
      RETURN ret;                                 /*                 */
   END;                                           /*                 */
 END;                                             /*                 */
                                                  /*-----------------*/
  RETURN 0;                                       /*                 */
 /*------------------------------------------------------------------*/




 /********************************************************************/
 /***                   CKDS READ                                  ***/
 /********************************************************************/
 CKDS_READ:  PROCEDURE
  ARG  name
 /*------------------------------------------------------------------*/
 /*  Call KRR                                                        */
 /*------------------------------------------------------------------*/
 label = LEFT(name, 64) ;                         /*                 */
                                                  /*-----------------*/
 retx       = "00000000"x;                        /*                 */
 reasx      = "00000000"x;                        /*                 */
 exit_lenx  = "00000000"x;                        /*                 */
 exit_data  = "NONE";                             /*                 */
 tokenx     = COPIES("00"x, 64);                  /*                 */
                                                  /*-----------------*/

   address linkpgm 'CSNBKRR' ,
                 ' retx'          ' reasx',
                 ' exit_lenx'     'exit_data',
                 ' label'         'tokenx'  ;
                                                  /*-----------------*/
 ret  = C2X(retx);                                /*                 */
 reas = C2X(reasx);                               /*                 */
 IF  (ret \= 0)  THEN                          /*                 */
  DO                                              /*                 */
    IF  (reas \= "0000271C")  THEN                /*                 */
    DO                                            /*                 */
      SAY " ERROR CKRR FAILED WITH  " || ret || " / " || reas ;
      SAY "       CKRR LABEL:       " || label ;  /*                 */
      RETURN "" ;                                 /*                 */
    END ;                                         /*                 */
    ELSE                                          /*                 */
    DO                                            /*                 */
      SAY " ERROR CKRR FAILED WITH  " || ret || " / " || reas ;
      SAY " ERROR " STRIP(label) " NOT FOUND ";   /*                 */
      RETURN "" ;                                 /*                 */
    END ;                                         /*                 */
  END ;                                           /*                 */
                                                  /*-----------------*/
  tokenx    = STRIP(tokenx) ;                     /*                 */
  tokenx    = LEFT(tokenx, 64) ;                  /* Obtain token    */
  token     = C2X(tokenx) ;                       /* as hex          */
                                                  /*-----------------*/
 rtn_str = ret || ":",                            /*                 */
           token  ;                               /*                 */
                                                  /*-----------------*/
  RETURN rtn_str ;                                /*                 */
 /*------------------------------------------------------------------*/




 /********************************************************************/
 /***                   CKDS WRITE                                 ***/
 /********************************************************************/
 CKDS_WRITE: PROCEDURE
  PARSE ARG  name,  token, over_write, debug_stmt
 /*------------------------------------------------------------------*/
 /*  Initialize                                                      */
 /*------------------------------------------------------------------*/
 label        = LEFT(name, 64) ;                  /*                 */
 label_exists = "";                               /*                 */
                                                  /*-----------------*/
 /*==================================================================*/
 IF  (debug_stmt = "YES")  THEN
 DO;
   SAY " ---------- ";
   SAY "     LABEL: " || label;
   SAY " OVERWRITE: " || over_write;
   SAY "     TOKEN: " ;
   SAY " >" || LEFT(token, 64);
   SAY " >" || RIGHT(token, 64);
   SAY " ---------- ";
 END;
 /*==================================================================*/
 /*------------------------------------------------------------------*/
 /*  Check for existence of label                                    */
 /*------------------------------------------------------------------*/
 retx       = "00000000"x;                        /*                 */
 reasx      = "00000000"x;                        /*                 */
 exit_lenx  = "00000000"x;                        /*                 */
 exit_data  = "NONE";                             /*                 */
 tokenx     = COPIES("00"x, 64);                  /*                 */
                                                  /*-----------------*/
  address linkpgm 'CSNBKRR' ,
                 ' retx'          ' reasx',
                 ' exit_lenx'     'exit_data',
                 ' label'         'tokenx'  ;
                                                  /*-----------------*/
 ret  = C2X(retx);                                /*                 */
 reas = C2X(reasx);                               /*                 */
 IF  (ret  = "00000000")  THEN                    /*                 */
     label_exists = "YES";                        /*                 */
 ELSE                                             /*                 */
 DO;                                              /*                 */
   IF  (ret  = "00000008")  &,                    /*                 */
       (reas = "0000271C")  THEN                  /*                 */
       label_exists = "NO";                       /*                 */
   ELSE                                           /*                 */
    DO                                            /*                 */
      SAY " ERROR CKRR FAILED WITH  " || ret || " / " || reas ;
      SAY "       CKRR LABEL:       " || label   ;/*                 */
      RETURN ret ;                                /*                 */
    END ;                                         /*                 */
 END;                                             /*                 */
                                                  /*                 */
 /*------------------------------------------------------------------*/
 /*  Create label if it doesn't exist                                */
 /*------------------------------------------------------------------*/
 IF  (label_exists = "NO")  THEN                  /*                 */
 DO;                                              /*                 */
   over_write = "YES" ;                           /*                 */
   retx       = "00000000"x;                      /*                 */
   reasx      = "00000000"x;                      /*                 */
   exit_lenx  = "00000000"x;                      /*                 */
   exit_data  = "NONE";                           /*                 */
                                                  /*-----------------*/
   address linkpgm 'CSNBKRC' ,
                   ' retx'          ' reasx',
                   ' exit_lenx'     'exit_data',
                   ' label' ;
                                                  /*-----------------*/
   ret  = C2X(retx);                              /*                 */
   reas = C2X(reasx);                             /*                 */
   IF  (ret  = "00000000")  THEN                  /*                 */
   DO;                                            /*                 */
      SAY " >" name " created ";                  /*                 */
   END;                                           /*                 */
   ELSE                                           /*                 */
   DO;                                            /*                 */
      SAY " ERROR CKRC FAILED WITH  " || ret || " / " || reas ;
      SAY "       CKRC LABEL:       " || label ;  /*                 */
      RETURN ret;                                 /*                 */
   END;                                           /*                 */
 END;                                             /*                 */
                                                  /*                 */
 /*------------------------------------------------------------------*/
 /*  Overwrite label if it does exist                                */
 /*------------------------------------------------------------------*/
   IF  (over_write = "NO" )  THEN                 /*                 */
   DO;                                            /*                 */
      SAY "*ERROR* " STRIP(label) " exists ";     /*                 */
      SAY "          - overwrite option has not been specified ";
      RETURN 8;                                   /*                 */
   END;                                           /*                 */
                                                  /*-----------------*/
   retx       = "00000000"x;                      /*                 */
   reasx      = "00000000"x;                      /*                 */
   exit_lenx  = "00000000"x;                      /*                 */
   exit_data  = "NONE";                           /*                 */
   tokenx     = X2C(token) ;                      /*                 */
                                                  /*-----------------*/
   address linkpgm 'CSNBKRW' ,
                   ' retx'          ' reasx',
                   ' exit_lenx'     'exit_data',
                   ' tokenx'     ' label';
                                                  /*-----------------*/
   ret  = C2X(retx);                              /*                 */
   reas = C2X(reasx);                             /*                 */
   IF  (ret  = "00000000")  THEN                  /*                 */
   DO;                                            /*                 */
      SAY " >" name " overwritten ";              /*                 */
   END;                                           /*                 */
   ELSE                                           /*                 */
   DO;                                            /*                 */
      SAY " ERROR CKRW FAILED WITH  " || ret || " / " || reas ;
      SAY "       CKRW LABEL:       " || label ;  /*                 */
      RETURN ret;                                 /*                 */
   END;                                           /*                 */
                                                  /*-----------------*/
  RETURN 0;                                       /*                 */
  /*-----------------------------------------------------------------*/
