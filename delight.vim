" Vim syntax file
" Language:     Delight
" Maintainer:   Peter Massey-Plantinga
" URL:          https://github.com/pplantinga/delight
" Last Change:  2014-03-02
" Filenames:    *.delight
" Version:      0.1
"
if exists("b:current_syntax")
  finish
endif

" Check if option is enabled
function! s:Enabled(name)
  return exists(a:name) && {a:name}
endfunction

"
" Keywords
"

syn keyword delightDebug         unittest assert deprecated debug
syn keyword delightScopeDecl     public protected private export package
syn keyword delightScopeIdent    enter exit body success failure
syn keyword delightStatement     break continue return print passthrough new
syn keyword delightStorageClass  auto static override abstract ref scope
syn keyword delightStorageClass  synchronized immutable lazy
syn keyword delightStructure     class enum struct this super
syn keyword delightFunction      function method procedure
syn keyword delightRepeat        for while
syn keyword delightConditional   if else switch case default where
syn keyword delightImport        import from as
syn keyword delightException     try except finally raise
syn keyword delightOperator      and is not or in to by
syn match delightOperator        'has key'
syn match delightOperator        'more than'
syn match delightOperator        'less than'
syn match delightOperator        'equal to'

"
" Comments
"
" Block comments work only with tabs and up to 3 levels. It will take someone
" more experienced than me to make a more general whitespace-indented comment.
"

syn match   delightComment	"#.*$" display contains=delightTodo
syn region  delightComment  start="^#" end="^[^\t ]"me=e-1 display contains=delightTodo
syn region  delightComment  start="^\t#" end="^\t\?[^\t]"me=e-1 display contains=delightTodo
syn region  delightComment  start="^\t\t#" end="^\t\{0,2}[^\t]"me=e-1 display contains=delightTodo
syn region  delightComment  start="^\t\t\t#" end="^\t\{0,3}[^\t]"me=e-1 display contains=delightTodo
syn keyword delightTodo contained TODO FIXME TEMP REFACTOR REVIEW HACK BUG XXX

" Mixing spaces and tabs also may be used for pretty formatting multiline
" statements
if s:Enabled("g:delight_highlight_indent_errors")
  syn match delightIndentError	"^\s*\%( \t\|\t \)\s*\S"me=e-1 display
endif

" Trailing space errors
if s:Enabled("g:delight_highlight_space_errors")
  syn match delightSpaceError	"\s\+$" display
endif

"
" Types
"

syn keyword delightType byte ubyte short ushort int uint long ulong cent ucent
syn keyword delightType void bool Object
syn keyword delightType float double real
syn keyword delightType short int uint long ulong float
syn keyword delightType char wchar dchar string wstring dstring
syn keyword delightType ireal ifloat idouble creal cfloat cdouble
syn keyword delightType size_t ptrdiff_t sizediff_t equals_t hash_t

"
" Strings
"
" Escape sequences (oct,specal char,hex,wchar, character entities \&xxx;)
" These are not contained because they are considered string literals.
syn match dEscSequence	"\\\(\o\{1,3}\|[\"\\'\\?ntbrfva]\|u\x\{4}\|U\x\{8}\|x\x\x\)"
syn match dEscSequence	"\\&[^;& \t]\+;"

syn region delightString	start=+"+ end=+"+ skip=+\\\\\|\\"+ contains=dEscSequence,@Spell
syn region delightString	start=+`+ end=+`+ contains=@Spell

"
" Chars
"
syn match delightCharacter	"'\\.'" contains=dEscSequence
syn match delightCharacter	"'[^\\]'"

"
" Numbers
"
syn case ignore

syn match delightDec		display "\<\d[0-9_]*\>"

"floating point number, with dot, optional exponent
syn match delightFloat	display "\<\d[0-9_]*\.[0-9_]*\(e[-+]\=[0-9_]\+\)\=[fl]\=i\="
"floating point number, without dot, with exponent
syn match delightFloat	display "\<\d[0-9_]*e[-+]\=[0-9_]\+[fl]\=\>"

syn case match

"
" Constants
"
syn keyword delightBoolean TRUE FALSE
syn keyword delightConstant NULL

"
" Defs
"

hi def link delightDebug            Statement
hi def link delightScopeDecl        StorageClass
hi def link delightScopeIdent       Identifier
hi def link delightStorageClass     StorageClass
hi def link delightStatement        Statement
hi def link delightStructure        Structure
hi def link delightImport           Include
hi def link delightFunction         Function
hi def link delightConditional      Conditional
hi def link delightRepeat           Repeat
hi def link delightException        Exception
hi def link delightOperator         Operator
hi def link delightType             Type

hi def link delightComment          Comment
hi def link delightTodo             Todo

hi def link delightString           String
hi def link delightCharacter        Character
hi def link delightConstant         Constant
hi def link delightBoolean          Boolean
hi def link delightBinary           Number
hi def link delightDec              Number
hi def link delightHex              Number
hi def link delightOctal            Number
hi def link delightFloat            Float
hi def link delightHexFloat         Float

let b:current_syntax = "delight"
