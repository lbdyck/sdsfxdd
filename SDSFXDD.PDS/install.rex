SDSFXDD - SDSF Extract Data from the JES SPOOL to z/OS Datasets

Installation
1. Copy the SDSFXDD into a REXX (or CLIST) library that will be
   available to your intended audientce.
2. If using (E)JES then update the exec to specify EJES for the
   PROD variable (find string *custom*)
3. Then just use it

Sample JCL:

//... JOB ...
.. several steps ..
//EXTRACT EXEC PGM=IKJEFT1B,DYNAMNBR=50
//SYSEXEC DD DISP=SHR,DSN=SDSFXDD.RUNTIME.LIBRARY
//SYSTSPRT DD SYSOUT=*
//SYSTSIN DD *
 %sdsfxdd job(*) dd(*) sys(no) qual(ext) step(*) list(no)
/*
