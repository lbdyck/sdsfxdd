  /* --------------------  rexx procedure  -------------------- */
  ver = '0.92'
  /*Name:      sdsfxdd                                         |
  |                                                            |
  | Function:  Extract the DD's for a specific Job and Step    |
  |            to z/OS datasets.                               |
  |                                                            |
  | Syntax:    %sdsfxdd JOB(jobname(jobid)) +                  |
  |               STEP(stepname) +                             |
  |               DD(ddname) +                                 |
  |               QUAL(qualifier) +                            |
  |               SUF(suffix) +                                |
  |               LIST(list) +                                 |
  |               SYS(sys) +                                   |
  |               DATE(date)                                   |
  |                                                            |
  |            jobname(jobid) is jobname(jobnnnnn)             |
  |                           or jobname                       |
  |                           or jobname*                      |
  |                           or * for the current job         |
  |            stepname is the job step name (e.g. STEP1)      |
  |                           or * for all steps               |
  |            ddname is the ddname to extract (or * for all)  |
  |            qualifier is the 2nd level qualifier (single    |
  |               level) - Default is X                        |
  |            suffix is the suffix to be used for the         |
  |               generated datasets or NONE (default)         |
  |            list is Yes for a dataset list or No or Return  |
  |               - default is YES                             |
  |            sys Yes to include or No to exclude these DD's  |
  |              JESMSGLG, JESYSMSG and JESJCL                 |
  |            date - default to use date/time in dsname or    |
  |                   any character for jobid (e.g. JOBnnnnn)  |
  |                                                            |
  |            *** Qual may be no more than 8 characters       |
  |                and must conform to z/OS dataset naming     |
  |                                                            |
  |            *** Suffix may be no more than 7 characters     |
  |                and must conform to z/OS dataset naming     |
  |                                                            |
  |  The output datasets will have this prefix:                |
  |  hlq'.'qual'.D'jul_date'.T'dsn_time'.'step'.'dd'.'suffix   |
  |  or                                                        |
  |  hlq'.'qual'.'jobid'.T'dsn_time'.'step'.'dd'.'suffix       |
  |                                                            |
  | Notes: Because of the limitation of 44 characters for a    |
  |        dataset name it is IMPORTANT that the QUAL and SUF  |
  |        be minimal.                                         |
  |                                                            |
  |        If a duplicate dataset is generated due to proc and |
  |        procstep, then the dataset name will be suffixed    |
  |        with a .A, .B, etc. The extension is for uniqueness |
  |        and increments within each duplicate ddname.        |
  |                                                            |
  | Dependencies:  Address SDSF support is required            |
  |                                                            |
  | Author:    Lionel B. Dyck                                  |
  |                                                            |
  | History:  (most recent on top)                             |
  |    v0.92   2022/05/03 LBD - Corrections for Jxxx->JOBxxx   |
  |    v0.91   2021/12/09 LBD - Add DATE keyword               |
  |    v0.9    2021/12/06 LBD - Add version and improve dups   |
  |            2021/12/05 LBD - Add checking and help          |
  |            2021/12/04 LBD - Major refinement               |
  |            2021/12/03 LBD - Major update w/keywords        |
  |            2021/09/21 LBD - Refinement                     |
  |            2021/09/20 LBD - Creation                       |
  |                                                            |
  * ---------------------------------------------------------- *
  | Copyright (c) 2021 by Lionel B. Dyck under the MIT License |
  | https://mit-license.org                                    |
  * ---------------------------------------------------------- */
  arg options

  say 'SDSFXDD Version:' ver date() time()

  /* --------------- *
  | Define defaults |
  * --------------- */
  parse value '' with null duplicates
  ddn = 'sd'time('s')

  /* ---------------------- *
  | Check for help request |
  * ---------------------- */
  if wordpos('?',options) > 0 then call tutor

  /* -------------------------------- *
  | Determine which keywords we have |
  * -------------------------------- */
  parse value options with 'JOB('jobname') ' . 1 ,
    'DD('ddname')' . 1 ,
    'STEP('stepname')' . 1 ,
    'SUF('suffix')' 1 ,
    'QUAL('qual')' 1 ,
    'LIST('list')' . 1,
    'DATE('dopt')' . 1,
    'SYS('sys')' .

  if qual = null then qual = 'X'
  else if length(qual) > 8 then do
    say 'Qualifier must not exceed 8 characters'
    exit 8
  end

  /* --------------------------- *
  | Test for List specification |
  * --------------------------- */
  if list = null then list = 'YES'

  if jobname  = null then call tutor
  if stepname = null then call tutor
  if ddname   = null then call tutor

  /* -------------------------------------------------------- *
  | Test suffix for less than 7 so that the generated dsname |
  | won't be more than 44 characters.                        |
  * -------------------------------------------------------- */
  if length(suffix) > 7 then do
    say 'Suffix is invalid as it is longer than the allowed 7 characters'
    exit 8
  end

  Say 'Processing Options:'
  say 'jobname:  ' jobname
  say 'stepname: ' stepname
  say 'ddname:   ' ddname
  say 'qualifier:' qual
  say 'suffix:   ' suffix
  say 'list:     ' list
  say 'date:     ' dopt
  say 'sys:      ' sys

  if sys = 'NO' then sys = null

  /* ------------ *
  | Fixup Suffix |
  * ------------ */
  if suffix = null then suffix = 'NONE'
  if suffix = 'NONE'
  then suf = null
  else suf = '.'suffix

  /* ------------------------- *
  | check for current jobname |
  * ------------------------- */
  if jobname = '*' then jobname = get_jobid()

  /* ----------------------------------- *
  | Separate the jobid from the jobname |
  * ----------------------------------- */
  parse value jobname with jobname'('jobid')'
  if left(jobid,3) /= 'JOB' then
     if left(jobid,1) = 'J' then
        jobid = 'JOB'substr(jobid,2)
  if left(jobid,3) /= 'TSU' then
     if left(jobid,1) = 'T' then
        jobid = 'TSU'substr(jobid,2)

  /* --------------- *
  | Inform the user |
  * --------------- */
  say 'Processing Job:' jobname 'for Step:' stepname 'with DDname:' ddname ,
    'with Suffix:' suffix

  /* ----------------- *
  | Begin the Process |
  * ----------------- */
  rc=isfcalls('ON')
  Address SDSF "ISFEXEC ST" jobname
  lrc=rc
  if lrc<>0 then exit 20

  /* --------------------------------------- *
  | Loop thru jobs and find the one we want |
  | by Jobname *and/or* Jobid               |
  * --------------------------------------- */
  do ix=1 to JNAME.0
    if JNAME.ix = jobname then
    doit = 0
    if jobid = null then doit = 1
    if JOBID.ix = jobid then doit = 1
    if doit = 1 then do
      Address SDSF "ISFACT ST TOKEN('"TOKEN.ix"') PARM(NP ?) (prefix j_"
      call build_dsn_hlq
      do idd = 1 to j_ddname.0
        if sys = null then
        if wordpos(j_ddname.idd,'JESMSGLG JESYSMSG JESJCL') > 0 then iterate
        if stepname /= '*' then
        if j_stepn.idd /= stepname then iterate
        if ddname /= '*' then
        if ddname /= j_ddname.idd then iterate

        outdsn = "'"sdsfdsn'.'j_stepn.idd'.'j_ddname.idd''suf"'"

        if sysdsn(outdsn) = 'OK' then do
          parse value outdsn with "'"outdsn"'"
          ext = get_ext(outdsn)
          outdsn = "'"outdsn'.'ext"'"
        end

        if length(outdsn) > 46 then do
          say ' '
          say 'Error. The generated output dataset name exceeds 44' ,
            'characters.'
          say ' '
          say 'Generated dataset name:' outdsn
          say 'Suggest reducing the size of the QUAL, the size of the' ,
            'SUF, or setting SUF to NONE.'
          say ' '
          exit 16
        end
        say 'sdsfxdd: Extracting Step:' j_stepn.idd 'DD:' j_ddname.idd
        say 'sdsfxdd:         Dataset:' outdsn

        Address SDSF "ISFACT ST TOKEN('"j_TOKEN.idd"') PARM(NP SA)"

        blksize = (32760%j_lrecl.idd)*j_lrecl.idd
        space   = ((j_reccnt.idd*j_lrecl.idd)%56000)+1

        'Alloc f('ddn') new blksize('blksize') tracks' ,
          "ds("outdsn")" ,
          'space('space','space') lrecl('j_lrecl.idd')' ,
          'release recfm('left(j_recfm.idd,1) substr(j_recfm.idd,2,1) ,
          substr(j_recfm.idd,3,1)')'

        do forever
          'Execio 10000 diskr' isfddname.1 '(stem in.'
          if in.0 < 10000 then do
            'execio 0 diskr' isfddname.1 '(finis'
            'execio * diskw' ddn '(finis stem in.'
            leave
          end
          else 'Execio 10000 diskw' ddn '(stem in.'
          drop in.
        end
        'free f('ddn')'
        drop in.

      end
    end
  end

  if list /= 'YES' then call done

  /* ----------------------------------------------- *
  | Check for running under the web and if not then |
  | check for running under TSO and if so then      |
  | display (3.4 like) the datasets generated.      |
  * ----------------------------------------------- */
  if sysvar('sysenv') = 'FORE' then
  if sysvar('sysispf') = 'ACTIVE' then do
    Address ISPExec
    sdsfdsn = translate(sdsfdsn,' ','.')
    if dopt = null
        then sdsfdsn = translate(subword(sdsfdsn,1,2),'.',' ')'.D*'
        else sdsfdsn = translate(subword(sdsfdsn,1,2),'.',' ')
    "LMDINIT LISTID(LISTID) LEVEL("sdsfdsn")"
    "LMDDISP LISTID("ListId") Confirm(Yes)",
      "View(Volume)"
    "LMDFREE LISTID("ListId")"
  end

  /* ------------------------ *
  | Done so cleanup and exit |
  * ------------------------ */
done:
  rc=isfcalls('OFF')
  if list = 'RETURN' then exit sdsfdsn
  exit 0

Get_Ext: Procedure expose ext duplicates
  arg dsn
  dsn = translate(dsn,' ','.')
  ext = word(dsn,words(dsn))
  if wordpos(dsn,duplicates) = 0 then do
    duplicates = duplicates dsn
    return 'A'
  end
  str = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ$'
  p = pos(ext,str)
  if p = 0 then ext = 'A'
  else ext = substr(str,p+1,1)
  return ext

  /* ------------------------------------------ *
  | Chase control blocks for jobname and jobid |
  * ------------------------------------------ */
get_jobid: procedure
  tcb      = ptr(540)
  tiot     = ptr(tcb+12)
  jobname  = stg(tiot,8)
  jscb     = ptr(tcb+180)
  ssib     = ptr(jscb+316)
  jobidl   = stg(ssib+12,8)
  jobidl   = strip(jobidl)
  _jobidn_ = null
  do _idx_ = 1 to length(jobidl)
    _jobidc_ = substr(jobidl,_idx_,1)    /* only 1 char */
    if datatype(_jobidc_) = "NUM" ,
      then do;
      _jobtype = substr(jobidl,1,_idx_-1)
      _jobidn_ = substr(jobidl,_idx_)
      leave
    end;
  end;
  jobid    = substr(jobidl,1,1)""_jobidn_
  _stepname_ = strip(stg(tiot+8,8))
  _procstep_ = strip(stg(tiot+16,8))
  _program_  = strip(stg(jscb+360,8))
  return strip(jobname)'('jobid')'

  /* ----------------------------------------- *
  * Subroutines used to get data from storage *
  * ----------------------------------------- */
ptr: return c2d(storage(d2x(arg(1)),4))
stg: return storage(d2x(arg(1)),arg(2))

Tutor:
  say ' '
  say copies('-',72)
  indent = copies(' ',8)
  indent2 = copies(' ',12)
  say 'SDSFXDD will extract files from the JES SPOOL',
    'utilizing SDSF REXX.'
  say ' '
  say 'Syntax:'
  say indent 'JOB(*) or JOB(jobname(jobnum))'
  say indent2 '* = the current/active job'
  say indent2 'or the jobname(jobnum) - e.g. MYJOB(J01234)'
  say indent2 'or jobname, or jobname*'
  say indent 'DD(*) or DD(ddname)'
  say indent2 '* = all DDnames (subject to SYS setting)'
  say indent2 'ddname is a specific ddname'
  say indent 'SYS(Yes or No)'
  say indent2 'Yes to include the System Sysout (JESMSGLG, JESSYSMG, JESJCL)'
  say indent2 'No to exclude them (Default)'
  say indent 'STEP(*) or STEP(stepname)'
  say indent2 '* = all steps'
  say indent2 'Specific stepname'
  say indent 'QUAL(qualifier)'
  say indent2 'This is the 2nd level qualifier after the userid/prefix'
  say indent2 'for the extracted sysout dataset names'
  say indent2 'Default is X'
  say indent 'SUF(suffix) or SUF(NONE)'
  say indent2 'The extracted sysout dataset name suffix or NONE'
  say indent2 'Must not exceed 7 characters'
  say indent 'LIST(Yes, No, or Return)'
  say indent2 'Yes - if under ISPF invoke LMDLIST for the extracted datasets'
  say indent2 'No - do not use LMDLIST even if under ISPF'
  say indent2 'Return - returns the generated HLQ for the extracted datasets'
  say indent2 'Default is Yes'
  say indent 'DATE(blank or JOB)'
  say indent2 'Default is use date and time in generated dataset name.'
  say indent2 'or any character for JOBID (e.g. JOBnnnnn)'
  say ' '
  say indent  'Becareful the generated dataset name does not exceed 44'
  say indent   'characters as then it will be invalid.'
  say copies('-',72)
  exit 0

Build_DSN_HLQ:
  /* ----------------------------------- *
  | Construct the output dataset prefix |
  * ----------------------------------- */
  if sysvar('syspref') /= null
  then sdsfdsn = sysvar('syspref')
  else sdsfdsn = sysvar('sysuid')
  /* Suggest using job submission or start time */
  if dopt = null then do
  dsn_time = time('n')
  dsn_date = date('j')
  dsn_time = left(dsn_time,2)''substr(dsn_time,4,2)
  sdsfdsn = sdsfdsn'.'qual'.D'dsn_date'.T'dsn_time
  end
  else do
     sdsfdsn = sdsfdsn'.'jobid.ix
     end
  return
