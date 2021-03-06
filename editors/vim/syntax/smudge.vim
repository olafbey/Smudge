" Vim syntax file
" Language: smudge
" Maintainer: Nate Bragg <Nate_Bragg@bose.com>
" Latest Revision: April 25th, 2017

if version < 600
  syn clear
elseif exists("b:current_syntax")
  finish
endif

let s:id = "\\v(\\\"[-_0-9A-Za-z \t!#$%&'()*+,./{|}~[\\\\\\]\\^`<>;=]+\\\"|[-_0-9A-Za-z]+)"

syn match smudgeComment "//.*$"
syn match smudgeCommentAfterState "//.*$" contained contains=smudgeComment nextgroup=smudgeArrow,smudgeEventList,smudgeEnterSideEffectList,smudgeCommentAfterState skipwhite skipempty
execute 'syn match smudgeState "'.s:id.'" contained contains=NONE nextgroup=smudgeArrow,smudgeEventList,smudgeEnterSideEffectList,smudgeCommentAfterState skipwhite skipempty'
execute 'syn match smudgeStateName "'.s:id.'" contained'
syn match smudgeDash "-\((\_[^)]\{-})\)\?-" contained contains=smudgeSideEffectList
syn match smudgeCommentAfterArrow "//.*$" contained contains=smudgeComment nextgroup=smudgeStateName,smudgeCommentAfterArrow skipwhite skipempty
syn match smudgeArrow "-\((\_[^)]\{-})\)\?->" contained contains=smudgeSideEffectList nextgroup=smudgeStateName,smudgeCommentAfterArrow skipwhite skipempty
syn match smudgeCommentAfterEvent "//.*$" contained contains=smudgeComment nextgroup=smudgeDash,smudgeArrow,smudgeCommentAfterEvent skipwhite skipempty
execute 'syn match smudgeEvent "'.s:id.'" contained contains=NONE nextgroup=smudgeDash,smudgeArrow,smudgeCommentAfterEvent skipwhite skipempty'
execute 'syn match smudgeEventName "'.s:id.'" contained'
execute 'syn match smudgeQualifiedEventName "'.s:id.'\." contained nextgroup=smudgeEventName'
syn match smudgeFunction "@[_A-Za-z][_0-9A-Za-z]*" contained
syn match smudgeCommentAfterEnterSideEffect "//.*$" contained contains=smudgeComment nextgroup=smudgeEventList,smudgeCommentAfterEnterSideEffect skipwhite skipempty
syn region smudgeStateList matchgroup=smudgeStateContainer start="{" end="}" fold contained contains=smudgeState,smudgeComment
syn match smudgeCommentAfterEventList "//.*$" contained contains=smudgeComment nextgroup=smudgeSideEffectList,smudgeCommentAfterEventList skipwhite skipempty
syn region smudgeEventList matchgroup=smudgeEventContainer start="\[" end="]" fold contained contains=smudgeEvent,smudgeComment nextgroup=smudgeSideEffectList,smudgeCommentAfterEventList skipwhite skipempty
syn region smudgeSideEffectList matchgroup=smudgeSideEffectContainer start="(" end=")" fold contained contains=smudgeFunction,smudgeEventName,smudgeQualifiedEventName,smudgeComment
syn region smudgeEnterSideEffectList matchgroup=smudgeSideEffectContainer start="(" end=")" fold contained contains=smudgeFunction,smudgeEventName,smudgeQualifiedEventName,smudgeComment nextgroup=smudgeEventList,smudgeCommentAfterEnterSideEffect skipwhite skipempty
syn match smudgeCommentAfterStateMachine "//.*$" contained contains=smudgeComment nextgroup=smudgeStateList,smudgeCommentAfterStateMachine skipwhite skipempty
execute 'syn match smudgeStateMachine "'.s:id.'" nextgroup=smudgeStateList,smudgeCommentAfterStateMachine skipwhite skipempty'
syn match smudgePragma "^#[-_0-9A-Za-z]\+\(\(=\|\( \|\t\)\+\).*\)\?$" nextgroup=smudgePragma,smudgeStateMachine,smudgeCommentAfterPragma skipwhite skipempty
syn match smudgeCommentAfterPragma "//.*$" contained contains=smudgeComment nextgroup=smudgePragma,smudgeStateMachine,smudgeCommentAfterPragma skipwhite skipempty

syn sync fromstart

" Define the default highlighting.
" For version 5.7 and earlier: only when not done already
" For version 5.8 and later: only when an item doesn't have highlighting yet
if version >= 508 || !exists("did_hs_syntax_inits")
  if version < 508
    let did_hs_syntax_inits = 1
    command -nargs=+ HiLink hi link <args>
  else
    command -nargs=+ HiLink hi def link <args>
  endif

  HiLink smudgeComment Comment
  HiLink smudgeArrow Operator
  HiLink smudgeDash Operator
  HiLink smudgeStateContainer Operator
  HiLink smudgeEventContainer Operator
  HiLink smudgeSideEffectContainer Operator
  HiLink smudgeState Structure
  HiLink smudgeStateName Structure
  HiLink smudgeEvent Identifier
  HiLink smudgeEventName Identifier
  HiLink smudgeFunction Number
  HiLink smudgePragma PreProc

  delcommand HiLink
endif

let b:current_syntax = "smudge"
