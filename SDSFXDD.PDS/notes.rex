SDSFXDD is a tool, written in REXX, that utilizes the SDSF REXX API
(which should also work with (E)JES and any other spool access product
that supports the SDSF REXX API).

Customizations:  Find in the code *custom* and do what it says

Purpose:

SDSFXDD is intended to be used as a step within a batch job to extract
sysout data for all, or selected, DDs into z/OS datasets.

Syntax:

               %sdsfxdd JOBname(jobname(jobid)) +
                  STEPname(stepname) +
                  PROCstep(procstep) +
                  DDname(ddname) +
                  HLQ(high-level-qualifier) +
                  QUALifier(qualifier) +
                  SUFfix(suffix) +
                  LISt(list) +
                  OWNer(owner) +
                  SYStem(sys) +
                  DATE(date)

Keywords:

               jobname(jobid) is jobname(jobnnnnn)
                              or jobname
                              or jobname*
                              or * for the current job
               stepname is the job step name (e.g. STEP1)
                              or * for all steps
               procstep is the job proc step name (e.g. PROC1)
                              or * for all proc steps
               ddname is the ddname to extract (or * for all)
               hlq is used as the high-level-qualifer for the
                   generated datasets
                   ** the default is the userid or prefix
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

          A 1 second start up delay in processing was added due
          to a rare situation where the sdsf status returned no
          jobs found if the steps prior are quick. Not sure why
          this is happening but it was so the 1 second delay is
          now incorporated. This only applies if JOBname(*) is
          specified.

          If the job is active and the spool dataset is NOT
          blocked then messages at the top of the data will
          provide the user with that information so they know that
          it is possible that some spool data may not have been
          written to the spool and may still be in the spool
          buffer.

   Dependencies:   Address SDSF support is required
                   or (E)JES
