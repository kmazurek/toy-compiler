%{
#include "aug_parser.h"
%}

%x COMMENT

sl_comment_open "//"
ml_comment_open "/*"
ml_comment_close "*/"

num_operator "+" | "-" | "*" | "/" | "%"
bool_operator "and" | "or"
relation_operator "=" | "<" | "<=" | ">" | ">="

OP	"+"|"-"|"*"|"/"|"%"
bracket	"("|")"
digit	[0-9]
sign_opt ("+"|"-")?
number {sign_opt}({digit}+)
separator ";"
identifier [a-zA-Z][a-zA-Z{digit}]*
endl \n
whitespace [ \t]+
assignment ":="

%%

{sl_comment_open}.* 		{}
{ml_comment_open} 			{ BEGIN(COMMENT); }
<COMMENT>{ml_comment_close} { BEGIN(INITIAL); }
<COMMENT>(.|{endl}) 			{}

{number}+ 				{ yylval.int_value = atoi(yytext); return NUMBER; }
{assignment}			{ return ASSIGN; }
{identifier}      		{ yylval.string_value = strdup(yytext); return IDENT; }
{separator}				{ return SEPARATOR; }
[ \t\n]           		;

%%
