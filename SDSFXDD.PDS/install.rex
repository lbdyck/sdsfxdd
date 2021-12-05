Installation
1. Copy the SDSFXDD into a REXX (or CLIST) library that will be
   available to your intended audientce.
2. Then just use it

Sample JCL:

//... JOB ...
.. several steps ..
//EXTRACT EXEC PGM=IKJEFT1B,DYNAMNBR=50
//SYSEXEC DD DISP=SHR,DSN=SDSFEXT.RUNTIME.LIBRARY
//SYSPRINT DD SYSOUT=*
//SYSIN DD *
 %sdsfext job(*) dd(*) sys(no) qual(ext) step(*) list(no)
/*
