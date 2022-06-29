# md-from-sh.sh 

---

## Synopsis

    [bash] md-from-sh.sh FILE 


---

## Description

This is a pure bash(1) script to generate markdown from a well defined & understood format of the accompanying shell script comments. 


---

## Opts


-n  - some short opt
--opt  - some long opt


---

## Args

- $1  - the name of a file for which to  generate the markdown.


---

## Notes

This script is predicated on target bash files following pre-determined formatted comment _block_s where each block comprises one, or more, _section_s - each section matching `# <keyword/title>:+(\ )[<string>]` - `<string>` is here defined as a string that may, or may not, be continued over multiple lines where the continuation lines all use the prefix `# <keyword/title>:\ `. The minimum prefix for empty continuation lines must match `# ` i.e. a hash (`#`) + at least one trailing space character 

Blocks are terminated by one of the following... 
- a line matching `####+(#)` i.e. for, or more, consecutive hash(`#`) characters. 
- any line whose first 2 characters are not `# \ `
- a function declaration - denoting the end of a function block.

The format is via comments observing the RE '# ' ' ' keyword ':' string. The following comprise the designated/recognized keywords c/w a brief description of their purpose:: 
- File        - specifies the title of the generated page.
- Description - identifies descriptive narrative for either thefile (as a script) or function(s) therein. 
- Author      - Identifies the author
- Date        - ... and the date the file was created
- Opts        - identify the/any options - short &/or long
- Args        - identify the/any arguments 
- Variables   - identify any global variables consumed by thescript 
- To Do       - a descriptive narrative describing any forecastchanges 
- Notes       - supplementary notes
- `[-*] `     - signifies a simple list entry
- `$VAR`      - signifies an entry in an `Env Vars` list.
- empty line  - any line matching `# +` signifies a newparagraph unless it's at the end of a list - of which it marks the end. 

In lists... 
- Any text at, or greater than, the indent of the list start_keyword_ (see above) is treated as a continuation of the current/previous list text. 

The ordering of the headings within the generated _MarkDown_ is determined by the `` variable i.e. it's completely independant of the order in which the headings are defined in the script 

Everything other than function definitions are expected in the header block - the end of which is define by a line matching `#####+`. 


---

## Files

etc/md-from-sh.sh 


---

## To Do

None. 


---

## Author

D. C. Pointon FIAP MBCS (pointo1d at gmail dot com) 


---

## Date

June 2022 



---
END OF DOCUMENT
