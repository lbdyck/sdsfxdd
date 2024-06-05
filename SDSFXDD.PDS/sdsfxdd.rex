  /* --------------------  rexx procedure  -------------------- */
  ver = '1.06'
  /*Name:      sdsfxdd                                         |
  |                                                            |
  | Function:  Extract the DD's for a specific Job and Step    |
  |            to z/OS datasets.                               |
  |                                                            |
  | Customization: Find *custom* for site customizations       |
  |                                                            |
  | Syntax:    %sdsfxdd JOBname(jobname(jobid)) +              |
  |               STEPname(stepname) +                         |
  |               PROCstep(procstep) +                         |
  |               DDname(ddname) +                             |
  |               HLQ(high-level-qualifier) +                  |
  |               QUALifier(qualifier) +                       |
  |               SUFfix(suffix) +                             |
  |               LISt(list) +                                 |
  |               OWNer(owner) +                               |
  |               SYStem(sys) +                                |
  |               DATE(date)                                   |
  |                                                            |
  |            Abbreviations in CAPs.                          |
  |                                                            |
  |            jobname(jobid) is jobname(jobnnnnn)             |
  |                           or jobname                       |
  |                           or jobname*                      |
  |                           or * for the current job         |
  |            stepname is the job step name (e.g. STEP1)      |
  |                           or * for all steps               |
  |            procstep is the job proc step name              |
  |                           or * for all procsteps           |
  |            ddname is the ddname to extract (or * for all)  |
  |            hlq is used as the high-level-qualifer for the  |
  |                generated datasets                          |
  |                ** the default is the userid or prefix      |
  |            qualifier is the 2nd level qualifier (single    |
  |               level) - Default is X                        |
  |            suffix is the suffix to be used for the         |
  |               generated datasets or NONE (default)         |
  |            owner to limit the jobs to those owned by the   |
  |               specified userid (default is all)            |
  |            list is Yes for a dataset list or No or Return  |
  |               - default is YES                             |
  |            sys Yes to include or No to exclude these DD's  |
  |              JESMSGLG, JESYSMSG and JESJCL                 |
  |            date - default to use job creation date/time    |
  |                   any character for jobid (e.g. JOBnnnnn)  |
  |                                                            |
  |            *** Qual may be no more than 8 characters       |
  |                and must conform to z/OS dataset naming     |
  |                                                            |
  |            *** Suffix may be no more than 7 characters     |
  |                and must conform to z/OS dataset naming     |
  |                                                            |
  |  The output datasets will have this prefix:                |
  |  hlq'.'qual'.D'yyddd'.T'hhmm'.'step'.'dd'.'suffix          |
  |  or                                                        |
  |  hlq'.'qual'.'jobid'.T'hhmm'.'step'.'dd'.'suffix           |
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
  |    v1.06   2024/06/05 LBD - Add PROCSTEP                   |
  |    v1.05   2024/06/01 LBD - Improve customization for      |
  |                             SDSF/(E)JES                    |
  |    v1.04   2024/05/29 EEJ - Add support for (E)JES         |
  |    v1.03   2022/10/03 LBD - Only report blocked if not     |
  |                             me and foreground              |
  |    v1.02   2022/08/03 LBD - Report is job active and ds    |
  |                             is blocked (possible missing)  |
  |    v1.01   2022/05/10 LBD - Fix sleep test                 |
  |    v1.00   2022/05/08 LBD - Release 1.00 ready             |
  |                           - Thanks to Phil Smith III for   |
  |                             options parsing and QA         |
  |            2021/09/20 LBD - Creation                       |
  |                                                            |
  * ---------------------------------------------------------- *
  | Copyright (c) 2021-2024 by Lionel B. Dyck under the MIT    |
  | License                                                    |
  | https://mit-license.org                                    |
  * ---------------------------------------------------------- */
  arg options

  say 'SDSFXDD Version:' ver date() time()

  /* --------------- *
  | Define defaults |
  * --------------- */
  parse value '' with null duplicates itsme
  ddn = 'sd'time('s')

  /* ---- *custom* ---- *
   | Site Customization |
   | Prod: SDSF         |
   |       EJES         |
   * ------------------ */
   prod = 'SDSF'

  /* ---------------------- *
  | Check for help request |
  * ---------------------- */
  if wordpos('?',options) > 0 then call tutor

  /* -------------------------------- *
  | Determine which keywords we have |
  * -------------------------------- */
  parse value '' with ddname jobname stepname suffix qual list ,
    owner dopt sys hlq procstep
  do while options <> ''
    parse var options option '(' value ')' options
    option = strip(option)
    value = strip(value)
    if pos('(',value) > 0 then do
       value = value')'
       parse value options with ')' options
       end
    select
      when abbrev('DDNAME', option, 2)    then ddname   = value
      when abbrev('JOBNAME', option, 3)   then jobname  = value
      when abbrev('STEPNAME', option, 4)  then stepname = value
      when abbrev('PROCSTEP', option, 4)  then procstep = value
      when abbrev('SUFFIX', option, 3)    then suffix   = value
      when abbrev('HLQ', option, 3)       then hlq      = value
      when abbrev('QUALIFIER', option, 4) then qual     = value
      when abbrev('LIST', option, 3)      then list     = value
      when abbrev('OWNER', option, 3)     then owner    = value
      when abbrev('DATE', option, 4)      then dopt     = value
      when abbrev('SYSTEM', option, 3)    then sys      = value
      when abbrev('PRODUCT', option, 4)   then prod     = value
      otherwise do
        say 'Invalid option "'option'"'
        exit 8
      end
    end
  end


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

  if hlq = null then do
    if sysvar('syspref') /= null
    then hlq = sysvar('syspref')
    else hlq = sysvar('sysuid')
  end

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
  say 'procstep: ' procstep
  say 'ddname:   ' ddname
  say 'hlq:      ' hlq
  say 'qualifier:' qual
  say 'suffix:   ' suffix
  say 'owner:    ' owner
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
  if jobname = '*' then do
     jobname = get_jobid()
     itsme = 1
     end

  /* ----------------------------------- *
  | Separate the jobid from the jobname |
  * ----------------------------------- */
  parse value jobname with jobname'('jobid')'
  if length(jobid) < 8 then do
    if left(jobid,3) /= 'JOB' then
    if left(jobid,1) = 'J' then
    jobid = 'JOB'substr(jobid,2)
    if left(jobid,3) /= 'TSU' then
    if left(jobid,1) = 'T' then
    jobid = 'TSU'substr(jobid,2)
  end

  /* ------------------------------------------ *
  | Wait for 1 second to allow JES to catch up |
  | but only for the active job                |
  * ------------------------------------------ */
  if jobname = '*' then
     address 'SYSCALL' 'SLEEP (1)'

  /* --------------- *
  | Inform the user |
  * --------------- */
  say 'Processing Job:' jobname
  say 'StepName:      '  stepname
  if procstep /= null then
     say 'PROCStep:      '  procstep
  say 'DDName:        ' ddname
  say 'Suffix:        ' suffix

  /* ----------------- *
  | Begin the Process |
  * ----------------- */
  if prod = 'SDSF'
     then rc = ISFCALLS('ON')
     else rc = EJESISFX('ON')
  isfprefix = '*'
  isfdest   = ''
  if owner = null
  then isfowner  = ''
  else isfowner  = owner
  Address SDSF "ISFEXEC ST" jobname
  lrc=rc
  if lrc<>0 then do
    say 'SDSF Error encountered - rc:' lrc
    do i = 1 to isfmsg2.0
      say isfmsg2.i
    end
    exit lrc
  end

  if jname.0 = 0 then do
    say jname.0 'jobs found matching the provided jobname' jobname
    exit 0
  end

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
        if procstep /= null then
        if procstep /= '*' then
        if j_procs.idd /= procstep then iterate
        if ddname /= '*' then
        if ddname /= j_ddname.idd then iterate

        outdsn = "'"sdsfdsn'.'j_stepn.idd'.'j_ddname.idd''suf"'"

        do forever
          if sysdsn(outdsn) = 'OK' then do
            parse value outdsn with "'"outdsn"'"
            ext = get_ext(outdsn)
          end
          else leave
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
        say 'sdsfxdd: Extracting:'
        say '    Step: ' j_stepn.idd
        if procstep /= null then
           say '    ProcStep:' j_procs.idd
        say '    DD:      ' j_ddname.idd
        say '    Dataset: ' outdsn

        Address SDSF "ISFACT ST TOKEN('"j_TOKEN.idd"') PARM(NP SA)"
        open_blk.0 = 0

        if strip(actsys.ix) /= null then
           if substr(j_recfm.idd,2,1) = 'B'
           then if sysvar('sysenv') = 'FORE'
           then if itsme = null
           then do
                open_blk.0 = 5
                open_blk.1 = ' 'copies('-',70)
                open_blk.2 = ' Note: The job is active and the DD is' ,
                             'blocked which means that any data'
                open_blk.3 = ' in the last block',
                open_blk.4 = ' 'copies('-',70)
                open_blk.5 = '  '
                end

        blksize = (32760%j_lrecl.idd)*j_lrecl.idd
        space   = ((j_reccnt.idd*j_lrecl.idd)%56000)+1

        recfm = left(j_recfm.idd,1) substr(j_recfm.idd,2,1) ,
          substr(j_recfm.idd,3,1)

        if left(recfm,1) /= 'U' then do
          if substr(recfm,2,1) /= 'B' then
          recfm = left(j_recfm.idd,1) 'B' substr(j_recfm.idd,3,1)
        end
        else recfm = 'V B' substr(j_recfm.idd,3,1)

        'Alloc f('ddn') new blksize('blksize') tracks' ,
          "ds("outdsn")" ,
          'space('space','space') lrecl('j_lrecl.idd')' ,
          'release recfm('recfm')'

        if open_blk.0 > 0 then
            'execio * diskw' ddn '(stem open_blk.'

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
  | Check for running under TSO and if so then      |
  | if under ISPF then display (3.4 like) the       |
  | datasets generated.                             |
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
  if prod = 'SDSF'
     then rc = ISFCALLS('OFF')
     else rc = EJESISFX('OFF')
  exit 0

Get_Ext: Procedure expose ext duplicates outdsn
  arg dsn
  dsn = translate(dsn,' ','.')
  ext = word(dsn,words(dsn))
  if length(ext) = 1 then
  dsn = subword(dsn,1,words(dsn)-1)
  str = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ$'
  p = pos(ext,str)
  if p = 0 then ext = 'A'
  else ext = substr(str,p+1,1)
  dsn = translate(dsn,'.',' ')
  outdsn = "'"dsn'.'ext"'"
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
  say indent 'JOBname(*) or JOBname(jobname(jobnum))'
  say indent2 '* = the current/active job'
  say indent2 'or the jobname(jobnum) - e.g. MYJOB(J01234)'
  say indent2 'or jobname, or jobname*'
  say indent 'DDname(*) or DDname(ddname)'
  say indent2 '* = all DDnames (subject to SYS setting)'
  say indent2 'ddname is a specific ddname'
  say indent 'DATE(blank or JOB)'
  say indent2 'Default is use date and time in generated dataset name.'
  say indent2 'or any character for JOBID (e.g. JOBnnnnn)'
  say indent 'LIST(Yes or No)'
  say indent2 'Yes - if under ISPF invoke LMDLIST for the extracted datasets'
  say indent2 'No - do not use LMDLIST even if under ISPF'
  say indent2 'Default is Yes'
  say indent 'OWNer(blank or owning userid)'
  say indent2 'Default is to set owner to blank for all users,'
  say indent2 'or valid userid.'
  say indent 'HLQ(high-level-qualifier)'
  say indent2 'This is the 1nd level qualifier for the extracted'
  say indent2 'sysout dataset names'
  say indent2 'Default is userid or users prefix'
  say indent 'QUALifier(qualifier)'
  say indent2 'This is the 2nd level qualifier after the userid/prefix'
  say indent2 'for the extracted sysout dataset names'
  say indent2 'Default is X'
  say indent 'STEPname(*) or STEPname(stepname)'
  say indent2 '* = all steps'
  say indent2 'Specific stepname'
  say indent 'PROCstep(*) or PROCstep(procstep)'
  say indent2 '* = all proc steps'
  say indent2 'Specific procstep name'
  say indent 'SUFfix(suffix) or SUFfix(NONE)'
  say indent2 'The extracted sysout dataset name suffix or NONE'
  say indent2 'Must not exceed 7 characters'
  say indent 'SYStem(Yes or No)'
  say indent2 'Yes to include the System Sysout (JESMSGLG, JESSYSMG, JESJCL)'
  say indent2 'No to exclude them (Default)'
  say ' '
  say indent2 'Abbreviations in CAPs'
  say ' '
  say indent  'Be careful the generated dataset name does not exceed 44'
  say indent   'characters as then it will be invalid.'
  say copies('-',72)
  exit 0

Build_DSN_HLQ:
  /* ----------------------------------- *
  | Construct the output dataset prefix |
  * ----------------------------------- */
  parse value dater.ix with yy'.'ddd .
  dsn_date = right(yy,2)''ddd
  parse value timer.ix with hh':'mm':'.
  if hh < 10 then hh = right(hh+100,2)
  dsn_time = hh''mm
  /* Suggest using job submission or start time */
  if dopt = null then do
    sdsfdsn = hlq'.'qual'.D'dsn_date'.T'dsn_time
  end
  else do
    sdsfdsn = hlq'.'jobid.ix
  end
  return
