# SDSFXDD
Extract Spool Files to Datasets using SDSF - Generalized

## Overview
This utility, written in REXX, is intended to be invoked as a batch job step
within individual jobs to extract SYSOUT files from the JES Spool into z/OS
datasets (similar to the SDSF XDC line command).

The command is generalized so the user has flexibility in numerous places with
the singluar exception that the generated dataset name  **must** not exceed
the z/OS limit of 44 characters.

## Syntax

```
%sdsfxdd JOBname(jobname(jobid)) +
   STEPname(stepname) +
   DDname(ddname) +
   HLQ(high-level-qualifier) +
   QUALifier(qualifier) +
   SUFfix(suffix) +
   LISt(list) +
   OWNer(owner) +
   SYStem(sys) +
   DATE(date)
```

Note: Abbreviations are in CAPs.

 | Keyword | Explanation |
 | --- | --- |
 | JOB   | Specify the JOB name to be processed.   <br />  jobname(jobid) for a specific job <br />  or  jobname for all jobs with the same jobname <br />  or jobname* for all jobs starting with jobname |
 | STEP | Specify the Stepname to be processed <br /> stepname or * for all steps <br /> ***Note*** that PROC Step names are not considered at this time |
 | DD | Specify the DDname to be processed <br /> ddname or * for all ddnames <br /> masking is not supported at this time |
 | OWNER | Specify the owning userid <br /> or default to ALL users |
 | DATE | if non-blank then use JOBID <br> or default to job creation date and time |
 | HLQ | Specify the 1st level qualifier for the generated dataset names <br /> the default  will be the users USERID or PREFIX <br />
 | QUAL | Specify the 2nd level qualifier for the generated dataset names <br /> the 1st qualifier will be the users USERID or PREFIX <br />
 | SUF | Specify the ***optional*** dataset suffix for the generated datasets <br />The default is no suffix or you can specify SUF(NONE) <br /> The suffix is limited to 7 characters |
 | LIST | Defines what the code does when it completes <br /> YES if under ISPF to display a dataset list (ISPF 3.4) of the datasets <br /> NO (default) to just exit |
 | SYS | Specify if the System generated files (JESMSGLG, JESYSMSG, and JESJCL) are to be included <br /> YES or NO |

 ## Notes:

 1. The generated dataset name must never exceed the z/OS limit of 44 characters. This may require having a small QUAL and no SUF.
 2. The generated dataset name will have a format of: hlq.qual.Dyyddd.Thhdd.stepname.ddname.suffix
 3. If the Step is within a PROC the PROC stepname is ignored
 4. If all jobs or all steps are processed there is a potential of duplicate stepname and ddname combinations. When this happens the dataset name will be suffixed with a .A up to .B. This suffix will increment withn the duplicate stepname and ddname.
 5. If the job is active and the spool dataset is NOT blocked then messages at the top of the data will provide the user
     with that information so they know that it is possible that some spool data may not have been written to the spool
     and may still be in the spool buffer.

 ## Disclaimer

 This is a work in progress and comes with **no** warranty or guarantee of any kind. Use it at your own risk.

 ## License

The MIT License (MIT)
Copyright © 2021-2022 <copyright holders>

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the Software), to deal in the Software without restriction, including without
limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial
portions of the Software.

THE SOFTWARE IS PROVIDED AS IS, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

