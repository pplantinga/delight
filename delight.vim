" Vim syntax file
" Language:     Delight
" Maintainer:   Peter Massey-Plantinga
" URL:          https://github.com/pplantinga/delight
" Last Change:  2014-01-28
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

syn keyword delightStatement     break continue return
syn keyword delightFunction      function method procedure
syn keyword delightRepeat        for while
syn keyword delightConditional   if else
syn keyword delightImport        import
syn keyword delightException     try catch finally
syn keyword delightOperator      and in is not or more less than equal to

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
syn region delightString	start=+"+ end=+"[cwd]\=+ skip=+\\\\\|\\"+ contains=dEscSequence,@Spell

"
" Numbers
"
syn case ignore

syn match delightDec		display "\<\d[0-9_]*\(u\=l\=\|l\=u\=\)\>"

" Hex number
syn match delightHex		display "\<0x[0-9a-f_]\+\(u\=l\=\|l\=u\=\)\>"

syn match delightOctal	display "\<0[0-7_]\+\(u\=l\=\|l\=u\=\)\>"
" flag an octal number with wrong digits
syn match delightOctalError	display "\<0[0-7_]*[89][0-9_]*"

" binary numbers
syn match delightBinary	display "\<0b[01_]\+\(u\=l\=\|l\=u\=\)\>"

"floating point without the dot
syn match delightFloat	display "\<\d[0-9_]*\(fi\=\|l\=i\)\>"
"floating point number, with dot, optional exponent
syn match delightFloat	display "\<\d[0-9_]*\.[0-9_]*\(e[-+]\=[0-9_]\+\)\=[fl]\=i\="
"floating point number, starting with a dot, optional exponent
syn match delightFloat	display "\(\.[0-9_]\+\)\(e[-+]\=[0-9_]\+\)\=[fl]\=i\=\>"
"floating point number, without dot, with exponent
"syn match delightFloat	display "\<\d\+e[-+]\=\d\+[fl]\=\>"
syn match delightFloat	display "\<\d[0-9_]*e[-+]\=[0-9_]\+[fl]\=\>"

"floating point without the dot
syn match delightHexFloat	display "\<0x[0-9a-f_]\+\(fi\=\|l\=i\)\>"
"floating point number, with dot, optional exponent
syn match delightHexFloat	display "\<0x[0-9a-f_]\+\.[0-9a-f_]*\(p[-+]\=[0-9_]\+\)\=[fl]\=i\="
"floating point number, without dot, with exponent
syn match delightHexFloat	display "\<0x[0-9a-f_]\+p[-+]\=[0-9_]\+[fl]\=i\=\>"

syn cluster delightTokens add=dDec,dHex,dOctal,dOctalError,dBinary,dFloat,dHexFloat

syn case match

"
" Booleans
"
syn keyword delightBoolean TRUE FALSE

"
" Defs
"

hi def link delightStatement        Statement
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
hi def link delightBoolean          Boolean
hi def link delightBinary           Number
hi def link delightDec              Number
hi def link delightHex              Number
hi def link delightOctal            Number
hi def link delightFloat            Float
hi def link delightHexFloat         Float

let b:current_syntax = "delight"
