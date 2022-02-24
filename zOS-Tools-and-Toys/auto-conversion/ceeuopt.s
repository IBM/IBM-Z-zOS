*/****************************************************************/
*/* LICENSED MATERIALS - PROPERTY OF IBM                         */
*/*                                                              */
*/* 5650-ZOS                                                     */
*/*                                                              */
*/*     COPYRIGHT IBM CORP. 1991, 2012                           */
*/*                                                              */
*/* US GOVERNMENT USERS RESTRICTED RIGHTS - USE,                 */
*/* DUPLICATION OR DISCLOSURE RESTRICTED BY GSA ADP              */
*/* SCHEDULE CONTRACT WITH IBM CORP.                             */
*/*                                                              */
*/* STATUS = HLE7790                                             */
*/****************************************************************/
CEEUOPT  CSECT
CEEUOPT  AMODE ANY
CEEUOPT  RMODE ANY
         CEEXOPT ENVAR=('_BPXK_AUTOCVT=ON','_TAG_REDIR_ERR=TXT',' _TAG_X
               REDIR_IN=TXT','_TAG_REDIR_OUT=TXT'),                    X
               FILETAG=(AUTOCVT,AUTOTAG),                              X
               POSIX=(ON),                                             X
               XPLINK=(ON)
         END
