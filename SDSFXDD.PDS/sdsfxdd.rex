  /* --------------------  rexx procedure  -------------------- */
  ver = '2.00'
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
  |               DATE(date) +                                 |
  |               UNit(unit) +                                 |
  |               DIsp(disp) +                                 |
  |               REPort(report) +                             |
  |               OUTstem(outstem) +                           |
  |               STORclas(storclas) +                         |
  |               MGMTclas(mgmtclas) +                         |
  |               DATAclas(dataclas) +                         |
  |               VOLume(volume) +                             |
  |               WAIt(wait) +                                 |
  |               TRace(trace)                                  |
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
  |            unit - default to SYSDA, may specify any        |
  |                   unit type valid for your installation    |
  |            disp - default to NEW, may be OLD, SHR, or MOD  |
  |                                                            |
  |            *** Qual may be no more than 8 characters       |
  |                and must conform to z/OS dataset naming     |
  |                                                            |
  |            *** Suffix may be no more than 7 characters     |
  |                and must conform to z/OS dataset naming     |
  |                                                            |
  |            *** Unit may be no more than 8 characters       |
  |                and must be a valid UNIT esoteric symbol    |
  |                                                            |
  |            *** Disp must be one of NEW, OLD, SHR, or MOD   |
  |                No abbreviations are permitted              |
  |                                                            |
  |  The output datasets will have this prefix:                |
  |                                                            |
  |  For DATE not specified:                                   |
  |     hlq'.'qual'.D'yyddd'.T'hhmm'.'step'.'dd'.'suffix       |
  |  For DATE specified with any value:                        |
  |     hlq'.'qual'.'jobid'.'step'.'dd'.'suffix                |
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
  |        A maximum of 27 duplicate names can be created.     |
  |        Extensions are '.A' through '.Z' and then '.$'.     |
  |        Extensions repeat after 27 so all beyond 27 will    |
  |        fail for duplicate dataset name.                    |
  |                                                            |
  | Dependencies:  Address SDSF support is required            |
  |                                                            |
  | Author:    Lionel B. Dyck                                  |
  |                                                            |
  | History:  (most recent on top)                             |
  |    v2.00   2026/11/23 LBD - Add REPORT, OUTStem, SMS,      |
  |                             WAIT, and TRACE options        |
  |                           - Add DD/STEP/PROCSTEP masks      |
  |                           - Improve validation and cleanup |
  |                           - Add allocation safeguards       |
  |    v1.07   2026/11/23 PJF - Add UNIT and DISP parameters   |
  |                           - Use Qualifier in dataset name  |
  |                             when DATE argument is used     |
  |                           - Change some variable names     |
  |                             that are also reserved words   |
  |                             like option and value          |
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
  | Copyright (c) 2021-2026 under the MIT License              |
  | https://mit-license.org                                    |
  * ---------------------------------------------------------- */
  arg inoptions

  parse source . . myname .

  say myname 'Version:' ver date() time()

  /* --------------- *
  | Define defaults |
  * --------------- */
  parse value '' with null duplicates itsme
  ddn = 'sd'time('s')
  api_on = 'NO'
  matchcount = 0

  /* ---- *custom* ---- *
   | Site Customization |
   | Prod: SDSF         |
   |       EJES         |
   * ------------------ */
   prod = 'SDSF'

  /* ---------------------- *
  | Check for help request |
  * ---------------------- */
  if wordpos('?',inoptions) > 0 then call tutor

  /* -------------------------------- *
  | Determine which keywords we have |
  * -------------------------------- */
  parse value '' with ddname jobname stepname suffix qual list ,
    owner dopt sys hlq procstep unit disp report outstem ,
    storclas mgmtclas dataclas volume wait trace
  do while inoptions <> ''
    parse var inoptions option '(' optval ')' inoptions
    option = strip(option)
    upper option
    optval = strip(optval)
    if pos('(',optval) > 0 then do
       optval = optval')'
       parse value inoptions with ')' inoptions
       end
    /* say 'option='option',optval='optval */
    select
      when abbrev('DDNAME', option, 2)    then ddname   = optval
      when abbrev('JOBNAME', option, 3)   then jobname  = optval
      when abbrev('STEPNAME', option, 4)  then stepname = optval
      when abbrev('PROCSTEP', option, 4)  then procstep = optval
      when abbrev('SUFFIX', option, 3)    then suffix   = optval
      when abbrev('HLQ', option, 3)       then hlq      = optval
      when abbrev('QUALIFIER', option, 4) then qual     = optval
      when abbrev('LIST', option, 3)      then list     = optval
      when abbrev('OWNER', option, 3)     then owner    = optval
      when abbrev('DATE', option, 4)      then dopt     = optval
      when abbrev('SYSTEM', option, 3)    then sys      = optval
      when abbrev('PRODUCT', option, 4)   then prod     = optval
      when abbrev('UNIT', option, 2)      then unit     = optval
      when abbrev('DISP', option, 2)      then disp     = optval
      when abbrev('REPORT', option, 3)    then report   = optval
      when abbrev('OUTSTEM', option, 3)   then outstem  = optval
      when abbrev('STORCLAS', option, 4)  then storclas = optval
      when abbrev('MGMTCLAS', option, 4)  then mgmtclas = optval
      when abbrev('DATACLAS', option, 4)  then dataclas = optval
      when abbrev('VOLUME', option, 3)    then volume   = optval
      when abbrev('WAIT', option, 2)      then wait     = optval
      when abbrev('TRACE', option, 2)     then trace    = optval
      when abbrev('VERSION', option, 3)   then call show_version
      otherwise do
        say 'Invalid option "'option'"'
        call cleanup_and_exit 8
      end
    end
  end


  /* ----------------------------------- *
  | Validate the QUAL, default to X     |
  * ----------------------------------- */
  if qual = null then qual = 'X'
  else if length(qual) > 8 then do
    say 'Qualifier must not exceed 8 characters'
    call cleanup_and_exit 8
  end
  if \validate_dsn_component(qual) then do
    say 'Qualifier "'qual'" contains invalid dataset-name characters'
    call cleanup_and_exit 8
  end

  /* ----------------------------------- *
  | Validate the UNIT, default to SYSDA |
  * ----------------------------------- */
  if unit = null then
     unit = 'SYSDA'
  else do
     upper unit
     if length(unit) > 8 then do
        say 'UNIT must not exceed 8 characters'
        call cleanup_and_exit 8
     end
     if \validate_dsn_component(unit) then do
        say 'UNIT "'unit'" contains invalid dataset-name characters'
        call cleanup_and_exit 8
     end
  end

  /* ----------------------------------- *
  | Validate the DISP, default to NEW   |
  * ----------------------------------- */
  if disp = null then
     disp = 'NEW'
  else do
     upper disp
     if length(disp) <> 3 | pos(disp, 'NEW OLD MOD SHR') = 0 then do
        say disp 'is not a valid DISP value'
        call cleanup_and_exit 8
     end
  end

  /* --------------------------- *
  | Test for List specification |
  * --------------------------- */
  if list = null then list = 'YES'
  upper list
  if list <> 'YES' & list <> 'NO' & list <> 'RETURN' then do
    say 'LIST must be YES, NO, or RETURN'
    call cleanup_and_exit 8
  end

  if report = null then report = 'NO'
  else do
    upper report
    if report <> 'YES' & report <> 'NO' then do
      say 'REPORT must be YES or NO'
      call cleanup_and_exit 8
    end
  end

  if trace = null then trace = 'NO'
  else do
    upper trace
    if trace <> 'YES' & trace <> 'NO' then do
      say 'TRACE must be YES or NO'
      call cleanup_and_exit 8
    end
  end

  if wait = null then wait = 0
  else if datatype(wait) <> 'NUM' | wait < 0 then do
    say 'WAIT must be a non-negative number of seconds'
    call cleanup_and_exit 8
  end

  if jobname  = null then call tutor
  if stepname = null then call tutor
  if ddname   = null then call tutor
  if hlq = null then do
    if sysvar('syspref') /= null
    then hlq = sysvar('syspref')
    else hlq = sysvar('sysuid')
  end
  upper hlq jobname stepname procstep ddname owner sys qual suffix ,
    prod storclas mgmtclas dataclas volume
  if \validate_dsn_name(hlq) then do
    say 'HLQ "'hlq'" is not a valid dataset-name qualifier'
    call cleanup_and_exit 8
  end
  if storclas <> null & (length(storclas) > 8 | ,
     \validate_dsn_component(storclas)) then do
    say 'STORCLAS "'storclas'" is invalid'
    call cleanup_and_exit 8
  end
  if mgmtclas <> null & (length(mgmtclas) > 8 | ,
     \validate_dsn_component(mgmtclas)) then do
    say 'MGMTCLAS "'mgmtclas'" is invalid'
    call cleanup_and_exit 8
  end
  if dataclas <> null & (length(dataclas) > 8 | ,
     \validate_dsn_component(dataclas)) then do
    say 'DATACLAS "'dataclas'" is invalid'
    call cleanup_and_exit 8
  end
  if volume <> null & (length(volume) > 6 | ,
     \validate_dsn_component(volume)) then do
    say 'VOLUME "'volume'" is invalid'
    call cleanup_and_exit 8
  end

  /* -------------------------------------------------------- *
  | Test suffix for less than 7 so that the generated dsname |
  | won't be more than 44 characters.                        |
  * -------------------------------------------------------- */
  if length(suffix) > 7 then do
    say 'Suffix is invalid as it is longer than the allowed 7 characters'
    call cleanup_and_exit 8
  end
  if suffix <> null & suffix <> 'NONE' & \validate_dsn_component(suffix) then do
    say 'Suffix "'suffix'" contains invalid dataset-name characters'
    call cleanup_and_exit 8
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
  say 'unit:     ' unit
  say 'disp:     ' disp
  say 'report:   ' report
  say 'outstem:  ' outstem
  say 'storclas: ' storclas
  say 'mgmtclas: ' mgmtclas
  say 'dataclas: ' dataclas
  say 'volume:   ' volume
  say 'wait:     ' wait
  say 'trace:    ' trace

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
  if itsme = 1 then do
     if wait > 0
     then address 'SYSCALL' 'SLEEP ('wait')'
     else address 'SYSCALL' 'SLEEP (1)'
  end

  /* --------------- *
  | Inform the user |
  * --------------- */
  say 'Processing Job:' jobname
  say 'StepName:      '  stepname
  if procstep /= null then
     say 'PROCStep:      '  procstep
  say 'DDName:        ' ddname
  say 'Suffix:        ' suffix

  if outstem <> null then do
    if \validate_rexx_symbol(outstem) then do
      say 'OUTStem "'outstem'" is not a valid Rexx stem name'
      call cleanup_and_exit 8
    end
    interpret outstem'.0=0'
  end

  if trace = 'YES' then
    say 'TRACE: Starting product' prod 'jobname' jobname ,
      'stepname' stepname 'procstep' procstep 'ddname' ddname

  /* ----------------- *
  | Begin the Process |
  * ----------------- */
  if prod = 'SDSF'
     then rc = ISFCALLS('ON')
     else rc = EJESISFX('ON')
  if rc = 0 then api_on = 'YES'
  else do
     say 'Unable to initialize' prod 'support - rc:' rc
     call cleanup_and_exit rc
  end
  isfprefix = '*'
  isfdest   = ''
  if owner = null
  then isfowner  = ''
  else isfowner  = owner
  if trace = 'YES' then say 'TRACE: ISFEXEC ST' jobname
  Address SDSF "ISFEXEC ST" jobname
  lrc=rc
  if lrc<>0 then do
    say 'SDSF Error encountered - rc:' lrc
    do i = 1 to isfmsg2.0
      say isfmsg2.i
    end
    call cleanup_and_exit lrc
  end

  if jname.0 = 0 then do
    say jname.0 'jobs found matching the provided jobname' jobname
    call cleanup_and_exit 0
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
        if \match_mask(j_stepn.idd,stepname) then iterate
        if procstep /= null then
        if procstep /= '*' then
        if \match_mask(j_procs.idd,procstep) then iterate
        if ddname /= '*' then
        if \match_mask(j_ddname.idd,ddname) then iterate

        outdsn = "'"sdsfdsn'.'j_stepn.idd'.'j_ddname.idd''suf"'"

        do forever
           if sysdsn(outdsn) = 'OK' then do
              if disp = 'NEW' then do
                 parse value outdsn with "'"outdsn"'"
                 ext = get_ext(outdsn)
                 if ext = '!' then do
                    say ' '
                    say 'Error. More than 27 duplicate dataset names' ,
                      'created.'
                    say ' '
                    say 'Generated dataset name:' outdsn
                    if dopt <> null then ,
                       say 'Suggest not using DATE parameter or using' ,
                         'unique SUF value for each extraction.'
                    else ,
                       say 'Suggest using' ,
                         'unique SUF value for each extraction.'
                    say ' '
                    call cleanup_and_exit 16
                 end
              end
              else leave
           end
           else leave
        end

        if length(outdsn) > 46 then do
           say ' '
           say 'Error. The generated output dataset name exceeds 44' ,
             'characters.'
           say ' '
           say 'Generated dataset name:' outdsn
           say 'Suggest reducing the size of the QUAL, the size of' ,
             'the SUF, or setting SUF to NONE.'
           say ' '
           call cleanup_and_exit 16
        end

        if report = 'YES' then do
          say 'REPORT:'
          say '    Step:    ' j_stepn.idd
          if procstep /= null then
             say '    ProcStep:' j_procs.idd
          say '    DD:      ' j_ddname.idd
          say '    DISP:    ' disp
          say '    Dataset: ' outdsn
          call record_output_dataset outdsn
          matchcount = matchcount + 1
          iterate
        end

        say myname': Extracting:'
        say '    Step:    ' j_stepn.idd
        if procstep /= null then
           say '    ProcStep:' j_procs.idd
        say '    DD:      ' j_ddname.idd
        say '    DISP:    ' disp
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

        lrecl = strip(j_lrecl.idd)
        reccnt = strip(j_reccnt.idd)
        if datatype(lrecl) <> 'NUM' | lrecl <= 0 then lrecl = 0
        if datatype(reccnt) <> 'NUM' | reccnt <= 0 then reccnt = 1
        if lrecl > 0 then blksize = (32760%lrecl)*lrecl
        else blksize = 32760
        if blksize <= 0 then blksize = 32760
        dspace = ((reccnt*lrecl)%56000)+1
        if dspace < 1 then dspace = 1

        recfm = strip(left(j_recfm.idd,1) substr(j_recfm.idd,2,1) ,
          substr(j_recfm.idd,3,1))
        if left(recfm,1) /= 'U' & substr(recfm,2,1) /= 'B' then
          recfm = left(j_recfm.idd,1) 'B' substr(j_recfm.idd,3,1)

        call validate_target_dataset outdsn, disp, recfm, lrecl

        /* Alloc based on DISP parameter */
        if disp = 'NEW' then do
           alloccmd = 'Alloc f('ddn') new blksize('blksize') tracks' ,
             'ds('outdsn') unit('unit')'
           if storclas <> null then alloccmd = alloccmd 'storclas('storclas')'
           if mgmtclas <> null then alloccmd = alloccmd 'mgmtclas('mgmtclas')'
           if dataclas <> null then alloccmd = alloccmd 'dataclas('dataclas')'
           if volume <> null then alloccmd = alloccmd 'volume('volume')'
           alloccmd = alloccmd 'space('dspace','dspace')' ,
             'lrecl('lrecl') release recfm('recfm')'
        end
        else alloccmd = 'Alloc f('ddn')' disp 'ds('outdsn')'

        if trace = 'YES' then say 'TRACE: 'alloccmd
        alloccmd

        if RC <> 0 then do
          say 'Allocation of DSN' outdsn 'failed, correct input' ,
            'parameters and try again.'
          say ' '
          call cleanup_and_exit 16
        end

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
        call record_output_dataset outdsn
        matchcount = matchcount + 1
        drop in.

      end
    end
  end

  if matchcount = 0 then do
    say 'No DD entries matched the requested filters'
    call cleanup_and_exit 4
  end

  if list /= 'YES' | report = 'YES' then call done

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
  call cleanup_and_exit 0

cleanup_and_exit: Procedure expose prod api_on trace
  arg exit_rc
  if api_on = 'YES' then do
    if trace = 'YES' then say 'TRACE: Disconnecting' prod
    if prod = 'SDSF'
    then rc = ISFCALLS('OFF')
    else rc = EJESISFX('OFF')
  end
  exit exit_rc

record_output_dataset: Procedure expose outstem null
  arg dsn
  if outstem = null then return
  dsn = strip(dsn)
  if left(dsn,1) = "'" & right(dsn,1) = "'" then
    dsn = substr(dsn,2,length(dsn)-2)
  interpret 'count='outstem'.0+1'
  interpret outstem'.0=count'
  interpret outstem'.'count'="'dsn'"'
  return

validate_target_dataset: Procedure expose trace prod api_on null
  arg dsn, disp_name, source_recfm, source_lrecl
  dsn_plain = strip(dsn)
  if left(dsn_plain,1) = "'" & right(dsn_plain,1) = "'" then
    dsn_plain = substr(dsn_plain,2,length(dsn_plain)-2)
  if disp_name = 'SHR' then do
    say 'DISP(SHR) is not supported for extracting data.'
    say 'Use DISP(NEW), DISP(OLD), or DISP(MOD).'
    call cleanup_and_exit 16
  end
  if disp_name = 'OLD' | disp_name = 'MOD' then do
    catalog_rc = sysdsn("'"dsn_plain"'")
    if catalog_rc <> 'OK' then do
      say 'Dataset' dsn_plain 'does not exist for DISP('disp_name')'
      call cleanup_and_exit 16
    end
  end
  if disp_name = 'MOD' & sysvar('sysenv') = 'FORE' then do
    address TSO "LISTDSI('"dsn_plain"')"
    if rc = 0 then do
      existing_recfm = strip(sysrecfm)
      existing_lrecl = strip(syslrecl)
      if existing_lrecl <> null & datatype(existing_lrecl) = 'NUM' then
      if source_lrecl > 0 & existing_lrecl <> source_lrecl then do
        say 'MOD target LRECL 'existing_lrecl,
          'does not match source LRECL 'source_lrecl
        call cleanup_and_exit 16
      end
      if existing_recfm <> null & left(existing_recfm,1) <> ,
        left(source_recfm,1) then do
        say 'MOD target RECFM 'existing_recfm,
          'does not match source RECFM 'source_recfm
        call cleanup_and_exit 16
      end
    end
  end
  return

Get_Ext: Procedure expose ext duplicates outdsn
  arg dsn
  dsn = translate(dsn,' ','.')
  ext = word(dsn,words(dsn))
  if length(ext) = 1 then
    dsn = subword(dsn,1,words(dsn)-1)
  str = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ$'
  p = pos(ext,str)
  if p = 0 then ext = 'A'
  else if p = length(str) then ext = '!' /* This will create invalid DSN */
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

match_mask: Procedure expose null
  arg value, mask
  value = translate(strip(value))
  mask = translate(strip(mask))
  if mask = null then return value = null
  if left(mask,1) = '*' then do
    if length(mask) = 1 then return 1
    restmask = substr(mask,2)
    if match_mask(value,restmask) then return 1
    if value <> null then
      if match_mask(substr(value,2),mask) then return 1
    return 0
  end
  if value = null then return 0
  if left(mask,1) = '?' | left(mask,1) = left(value,1) then
    return match_mask(substr(value,2),substr(mask,2))
  return 0

validate_dsn_component: Procedure expose null
  arg component
  component = strip(component)
  if component = null | length(component) > 8 then return 0
  if pos(left(component,1),'-') = 1 | ,
     pos(right(component,1),'-') = 1 then return 0
  valid = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789$#@-'
  do i = 1 to length(component)
    if pos(substr(component,i,1),valid) = 0 then return 0
  end
  return 1

validate_dsn_name: Procedure expose null
  arg dsn
  dsn = strip(dsn)
  if dsn = null | length(dsn) > 44 then return 0
  do while dsn <> null
    parse var dsn component '.' dsn
    if \validate_dsn_component(component) then return 0
  end
  return 1

validate_rexx_symbol: Procedure expose null
  arg symbol
  symbol = strip(symbol)
  if symbol = null then return 0
  first = substr(symbol,1,1)
  if pos(first,'ABCDEFGHIJKLMNOPQRSTUVWXYZ_#$@') = 0 then return 0
  valid = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_#$@'
  do i = 2 to length(symbol)
    if pos(substr(symbol,i,1),valid) = 0 then return 0
  end
  return 1

show_version: Procedure expose ver myname
  say myname 'Version:' ver
  exit 0

Tutor: Procedure expose myname
  say ' '
  say copies('-',72)
  indent = copies(' ',8)
  indent2 = copies(' ',12)
  say myname 'will extract files from the JES SPOOL',
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
  say indent 'REPort(Yes or No)'
  say indent2 'Yes to report matching DDs and names without extracting'
  say indent2 'No is the default'
  say indent 'OUTstem(stemname)'
  say indent2 'Optional stem populated with generated/extracted dataset names'
  say indent 'STORclas(storclas), MGMTclas(mgmtclas), DATAclas(dataclas)'
  say indent2 'Optional SMS attributes for DISP(NEW)'
  say indent 'VOLume(volume)'
  say indent2 'Optional volume for DISP(NEW)'
  say indent 'WAIt(seconds)'
  say indent2 'Seconds to wait for active-job spool updates'
  say indent 'TRace(Yes or No)'
  say indent2 'Yes to display diagnostic command and initialization messages'
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
  else if qual <> null then do
    sdsfdsn = hlq'.'qual'.'jobid.ix
  end
  else do
    sdsfdsn = hlq'.'jobid.ix
  end
  return
