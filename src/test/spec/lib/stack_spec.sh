FNNAME=bash-utils.stack LNAME=${FNNAME#*.}.sh PDIR=src/main/lib
LDIR=$(cd $PDIR >/dev/null && pwd)
STACK_NM=MyStack
CLONED_STACK_NM=${STACK_NM}Clone

declare -A MethodDefns=(
  [new]="class "
  [exists]="class "
  [push]="inst "
  [pop]="inst "
  [top]="inst "
  [peek]="inst "
  [walk]="inst "
  [seek]="inst "
  [depth]="inst "
  [is-empty]="inst "
  [fatal-error]="class "
  [clone]="inst"
  [delete]="inst"
)
%const CLASS_METHODS: "new exists fatal-error"
%const INST_METHODS: "push pop top peek walk seek depth is-empty clone delete"

Context 'pre-load & load'
  It "should be sourceable without error or output"
    When run . $PDIR/$LNAME
    The status should be success
  End

  Describe 'class interface definition'
    Parameters:dynamic
      for m in $CLASS_METHODS $INST_METHODS ; do
        %data $m
      done
    End

    Example "$FNNAME.$1() is implemented"
      When call source $PDIR/$LNAME
      The value "$(type -t $FNNAME.$1 2>&1)" should equal 'function'
    End
  End
End

Include $PDIR/$LNAME

Context 'New/empty stack operations'
  It "BP: $FNNAME.new() fails wuth no stack name"
    When run $FNNAME.new
    The status should not be success
    The stderr should equal "no stack name"
  End

  It "BP: $FNNAME.exists() reports non-existant stack correctly"
    When run $FNNAME.exists $STACK_NM
    The status should be success
    The stdout should equal n
  End

  Describe 'new stack'
    It 'created successfully'
      When call $FNNAME.new $STACK_NM
      The variable $STACK_NM should be exported
    End

    Describe 'created correctly'
      prep-it() { $FNNAME.new $STACK_NM ; }
      BeforeEach 'prep-it'

      Describe "instance interface definition"
        Parameters:dynamic
          for m in $INST_METHODS ; do
            %data $m
          done
        End

        Example "$STACK_NM.$1() is implemented"
          When call true
          The value "$(type -t $STACK_NM.$1 2>&1)" should equal 'function'
        End
      End

      It "BP: $FNNAME.new() fails for extant stack"
        When run $FNNAME.new $STACK_NM
        The status should not be success
        The stderr should equal "new: stack exists: $STACK_NM"
      End

      Describe "$FNNAME.exists reports extant stack correctly"
        It "$FNNAME.exists()"
          When call $FNNAME.exists $STACK_NM
          The stdout should equal y
        End
      End

      FuncName=$STACK_NM.depth

      Describe "$FuncName()"
        It "$FuncName()"
          When run $FuncName
          The stdout should equal 0
        End
      End

      FuncName=$STACK_NM.is-empty

      Describe "$FuncName()"
        It "$FuncName()"
          When call $FuncName
          The stdout should equal y
        End
      End

      Describe 'empty stack access behaviours'
        Parameters:matrix
          pop top peek seek update
          fatal warn
        End
          
        It "$STACK_NM.$1 - BASH_SOURCE_STACK_EMPTY_STACK=$2()"
          BASH_SOURCE_STACK_EMPTY_STACK=$2

          test $1 = seek && args="nm=val"

          When run $STACK_NM.$1 ${args:-}
          test $2 = fatal && success=not

          stderr="$1: cannot call on an empty stack ($STACK_NM)"

          The status should ${success:-} be success
          The stderr should equal "$stderr"
          The stdout should equal "${stdout:-}"
        End
      End

      FuncName=$STACK_NM.push

      Describe "$FuncName()"
        #prep-it() { $FNNAME.new $STACK_NM ; }

        It "$FuncName() warns correctly (nothing to push)"
          When call $FuncName
          The status should be success
          The stderr should equal "push: nothing to push"
          The value "$($STACK_NM.depth)" should equal 0
        End

        It "$FuncName() updates correctly"
          When call $STACK_NM.push 'a value'
          The status should be success
          The value "$($STACK_NM.depth)" should equal 1
        End
      End
    End
  End
End
      
Context 'clone operations'
  FuncName=$STACK_NM.clone

  Describe "$FuncName() - bad paths"

    prep-it() { $FNNAME.new $STACK_NM ; }

    BeforeEach 'prep-it'

    It "fails with no target stack name"
      When run $FuncName
      The status should not be success
      The stderr should equal "clone: no stack name"
    End

    It "fails with clone to itself"
      When run $FuncName $STACK_NM
      The status should not be success
      The stderr should equal "clone: stack exists: $STACK_NM"
    End

    It "$FuncName() succeeds with extant, but empty, stack"
      When call $FuncName $CLONED_STACK_NM
      The value "$($FNNAME.exists $CLONED_STACK_NM 2>&1)" should equal y
    End
  End

  prep-it() { $FNNAME.new $STACK_NM ; $STACK_NM.clone $CLONED_STACK_NM ; }

  BeforeEach 'prep-it'

  Describe 'cloned stack interface definition'
    Parameters:dynamic
      for m in $INST_METHODS ; do
        %data $m
      done
    End

    Example "$CLONED_STACK_NM.$1() is implemented"
      When call true
      The value "$(type -t $CLONED_STACK_NM.$1)" should equal function
    End
  End

  It "BP: $FuncName() fails with no target stack name"
    When run $FuncName
    The status should not be success
    The stderr should equal "clone: no stack name"
  End

  It "$STACK_NM.is-equal $CLONED_STACK_NM - zero length/depth"
    When call $STACK_NM.is-equal $CLONED_STACK_NM
    #When call $STACK_NM.is-equal $CLONED_STACK_NM
    The status should be success
    The stdout should equal y
  End
End

Describe 'Pre-initialising creation'
  FuncName=$FNNAME.new
  Args="one two three four"
  
  Context "$FuncName $STACK_NM $Args"
    It "creates successfully"
      When call $FuncName $STACK_NM $Args
      The status should be success
    End

    Describe 'successful updates - simple args'
      prep-it() {
        $FuncName $STACK_NM $Args
      }

      BeforeEach 'prep-it'

      It "$STACK_NM.depth"
        When call $STACK_NM.depth
        The stdout should equal 4
      End

      It "$STACK_NM.top"
        When call $STACK_NM.top
        The stdout should equal four
      End

      It "$STACK_NM.update top"
        When call $STACK_NM.update top
        The value "$($STACK_NM.top)" should equal top
      End
    End

    Describe ' updates - composite args'
      prep-it() {
        $FuncName $STACK_NM arg0 "arg 1" arg2 "arg 3"
      }

      BeforeEach 'prep-it'


      It "$STACK_NM.depth"
        When call $STACK_NM.depth
        The stdout should equal 4
      End

      It "$STACK_NM.top"
        When call $STACK_NM.top
        The stdout should equal 'arg 3'
      End

      It "$STACK_NM.peek 1"
        When call $STACK_NM.peek 1
        The stdout should equal arg2
      End

      It "$STACK_NM.update top"
        When call $STACK_NM.update top
        The value "$($STACK_NM.top)" should equal top
      End

      It "$STACK_NM.seek 'arrg 1' - returns empty list"
        When call $STACK_NM.seek 'arrg 1'
        The stdout should equal 'declare -a found=()'
      End

      It "$STACK_NM.seek 'arg 1' - returns one element"
        When call $STACK_NM.seek 'arg 1'
        The stdout should equal 'declare -a found=([0]="arg 1")'
      End

      tmp=$SHELLSPEC_TMPBASE/walk
      walk-it() { $STACK_NM.walk > $tmp ; }

      It "$STACK_NM.walk"
        When call walk-it
        %logger "$(wc -l $tmp) - $(< $tmp)"
        The value "$(< $tmp)" should include "
arg 3
arg2
arg 1
arg0"
      End

      walk-it() { $STACK_NM.walk -r > $tmp ; }

      It "$STACK_NM.walk -r"
        When call walk-it
        The value "$(< $tmp)" should include "
arg0
arg 1
arg2
arg 3"
      End
    End
  End
End

#### END OF FILE
