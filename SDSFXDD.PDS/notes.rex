SDSFXDD is a tool, written in REXX, that utilizes the SDSF REXX API
(which should also work with (E)JES and any other spool access product
that supports the SDSF REXX API).

Purpose:

SDSFXDD is intended to be used as a step within a batch job to extract
sysout data for all, or selected, DDs into z/OS datasets.

Syntax:

               %sdsfxdd JOB(jobname(jobid)) +
                  STEP(stepname) +
                  DD(ddname) +
                  QUAL(qualifier) +
                  SUF(suffix) +
                  LIST(list) +
                  OWNER(owner) +
                  SYS(sys) +
                  DATE(date)

Keywords:

               jobname(jobid) is jobname(jobnnnnn)
                              or jobname
                              or jobname*
                              or * for the current job
               stepname is the job step name (e.g. STEP1)
                              or * for all steps
               ddname is the ddname to extract (or * for all)
               qualifier is the 2nd level qualifier (single
                  level) - Default is X
               suffix is the suffix to be used for the
                  generated datasets or NONE (default)
               owner to limit the jobs to those owned by the
                  specified userid (default is all)
               list is Yes for a dataset list or No or Return
                  - default is YES
               sys Yes to include or No to exclude these DD's
                 JESMSGLG, JESYSMSG and JESJCL
               date - default to use job creation date/time
                      any character for jobid (e.g. JOBnnnnn)

               *** Qual may be no more than 8 characters
                   and must conform to z/OS dataset naming

               *** Suffix may be no more than 7 characters
                   and must conform to z/OS dataset naming

     The output datasets will have this prefix:
     hlq'.'qual'.D'yyddd'.T'hhmm'.'step'.'dd'.'suffix
     or
     hlq'.'qual'.'jobid'.T'hhmm'.'step'.'dd'.'suffix

   Notes: Because of the limitation of 44 characters for a
           dataset name it is IMPORTANT that the QUAL and SUF
           be minimal.

           If a duplicate dataset is generated due to proc and
           procstep, then the dataset name will be suffixed
           with a .A, .B, etc. The extension is for uniqueness
           and increments within each duplicate ddname.

   Dependencies:   Address SDSF support is required
