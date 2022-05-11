# stack.sh
## Description
This is a pure bash(1) implementation of a general purpose stack ... implementing, as it does, the standard + a couple of additional operations as bash(1) functions.
## Functions
### bash-utils.stack.exists()

#### Description
Function to create a new entry on the stack - if it's not the first then it also updates the current entry with the line number at which the new file is 'called` before add ing the new entry

#### Args

- $1  - name for the new stack 
- $2  - optional structure definition


#### Variables
$IncludeStack

### bash-utils.stack.update()

#### Description
"instance" method to update the value of the given/default element in-situ.

#### Opts

* -n INT  - specify the index of the stack element to be updated - as an integer between 0 & <STACK>.depth()

#### Returns
Returns:

#### Variables
Variables:

### bash-utils.stack.push()

#### Description
Called first for any sourced file, this routine records the given attribs for the lib and then saves them on the top of the included stack.

#### Opts

* -n INT  - specify the index of the stack element to be updated - as an integer between 0 & <STACK>.depth()

#### Returns
$IncludeStack updated for the given nm & path

#### Variables
$IncludeStack

### bash-utils.stack.peek()

#### Description
Routine to return the given/default element

#### Opts

* -n INT  - specify the index of the stack element to be updated - as an integer between 0 & <STACK>.depth()

#### Returns
The requested attrib set.

#### Variables
$IncludeStack

### bash-utils.stack.pop()

#### Description
Pops the top element off the include stack - assuming that... * the stack isn't empty - the caller is expected to assert this via prior call to bash-utils.stack.is-empty(). * if the element to be popped is of interest to the caller, then the caller has already called bash-utils.bash-utils.top() to inspect/retrieve it.

#### Opts

* -n INT  - specify the index of the stack element to be updated - as an integer between 0 & <STACK>.depth()

#### Returns
$IncludeStack updated for the given nm & path

#### Variables
$IncludeStack

### bash-utils.stack.depth()

#### Description
Pops the top element(s) off the include stack - assumes that if if the element(s) to be popped are of interest to the caller, then the caller has already called bash-utils.bash-utils.top() to inspect/retrieve them.

#### Opts

* -n INT  - specify the index of the stack element to be updated - as an integer between 0 & <STACK>.depth()

#### Returns
$IncludeStack updated for the given nm & path

#### Variables
$IncludeStack

### bash-utils.stack.top()

#### Description
Pops the top element(s) off the include stack - assumes that if if the element(s) to be popped are of interest to the caller, then the caller has already called bash-utils.bash-utils.top() to inspect/retrieve them.

#### Opts

* -n INT  - specify the index of the stack element to be updated - as an integer between 0 & <STACK>.depth()

#### Returns
$IncludeStack updated for the given nm & path

#### Variables
$IncludeStack

### bash-utils.stack.walk()

#### Description
Function to create a new entry on the stack - if it's not the first then it also updates the current entry with the line number at which the new file is 'called` before add ing the new entry

#### Opts

* -r  - reverse the direction of the walk i.e. tail to top, default - top to tail

#### Args

- $1  - new element


#### Variables
$IncludeStack

### bash-utils.stack.seek.compare-element()

#### Description
Element comparison method used as the default by the bash-utils.stack.seek() method (see below) - implements a simple string comparison. default/given comparison function.

#### Args

- $1  - The search criteria i.e. the condition to be satisfied by elements on the returned list. 
- $2  - a stack element (as a string).


#### Returns
On STDOUT, 'y' iff the criteria is satisfied, 'n' otherwise.

### bash-utils.stack.seek()

#### Description
"Instance" method to seek out all stack elements satisfying the default/given comparison function.

#### Opts

* -c STR  - the name of an alternative comparison function, default - bash-utils.stack.seek.compare-element. The function is called with 2 args 1 - a stack element as a string. 2 - the search criteria (also as a string). It must return [yn] on STDOUT depending on whether the element satisfies the search criteria (as implemented in the function).

#### Args

- $*      - The search criteria i.e. the condition to be satisfied by elements on the returned list.


#### Returns
An eval(1)able string which, when eval(1)led, results in an array, found, containing a list of of elements each of which satisfies the criteria implemented in/by the comparison function.

#### Variables
$stack

### bash-utils.stack.is-empty()

#### Description
Pops the top element(s) off the include stack - assumes that if if the element(s) to be popped are of interest to the caller, then the caller has already called bash-utils.bash-utils.top() to inspect/retrieve them.

#### Returns
On STDOUT - 'y' iff the instance is empty, 'n' otherwise.

#### Variables
$stack

### bash-utils.stack.clone()

#### Description
Function to create a new entry on the stack - if it's not the first then it also updates the current entry with the line number at which the new file is 'called` before add ing the new entry

#### Args

- $1  - new element


#### Variables
$IncludeStack

### bash-utils.stack.new()

#### Description
Function to create a new entry on the stack - if it's not the first then it also updates the current entry with the line number at which the new file is 'called` before add ing the new entry

#### Args

- $1  - name of the new stack. 
- $*  - optional initial stack contents - one element per arg


#### Variables
$stack name

### bash-utils.stack.is-equal()

#### Description
Function to create a new entry on the stack - if it's not the first then it also updates the current entry with the line number at which the new file is 'called` before add ing the new entry

#### Args

- $1  - name of the new stack. 
- $2  - optional end of stack marker string.


#### Variables
$IncludeStack

### bash-utils.stack.delete()

#### Description
Class & instance sensitive function to delete either a stack or a stack - deletes the given stack when called on the class, merely deleting the given element(s) when called on an instance.

#### Args

- $1  - name of the new stack. 
- $2  - optional end of stack marker string.


#### Variables
$IncludeStack

## Author
D. C. Pointon FIAP MBCS
## Date
May 2022
