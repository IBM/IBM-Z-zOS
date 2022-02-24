*/****************************************************************/
*/* LICENSED MATERIALS - PROPERTY OF IBM                         */
*/*                                                              */
*/* 5650-ZOS                                                     */
*/*                                                              */
*/*     COPYRIGHT IBM CORP. 2004, 2013                           */
*/*                                                              */
*/* US GOVERNMENT USERS RESTRICTED RIGHTS - USE,                 */
*/* DUPLICATION OR DISCLOSURE RESTRICTED BY GSA ADP              */
*/* SCHEDULE CONTRACT WITH IBM CORP.                             */
*/*                                                              */
*/* STATUS = HLE7790                                             */
*/****************************************************************/
CELQUOPT CSECT
CELQUOPT AMODE 64
CELQUOPT RMODE ANY
         CEEXOPT ENVAR=('_BPXK_AUTOCVT=ON','_TAG_REDIR_ERR=TXT',' _TAG_X
               REDIR_IN=TXT','_TAG_REDIR_OUT=TXT'),                    X
               FILETAG=(AUTOCVT,AUTOTAG),                              X
               POSIX=(ON),                                             X
               XPLINK=(ON)
         END
