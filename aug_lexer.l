%{
#include "aug_parser.h"
%}

%x COMMENT

sl_comment_open "//"
ml_comment_open "/*"
ml_comment_close "*/"

identifier [a-zA-Z][a-zA-Z{digit}]*
sign_opt ("+"|"-")?
number {sign_opt}({digit}+)

num_operator "+" | "-" | "*" | "/" | "%"
bool_operator "and" | "or"
relation_operator "=" | "<" | "<=" | ">" | ">="

whitespace [ \t]+
EOL \n

OP	"+"|"-"|"*"|"/"|"%"
BRACKET	"("|")"
DIGIT	[0-9]
SEPARATOR ";"

%%

{sl_comment_open}.* 		{}
{ml_comment_open} 			{ BEGIN(COMMENT); }
<COMMENT>{ml_comment_close} { BEGIN(INITIAL); }
<COMMENT>(.|{EOL}) 			{}

[ \t\n]           	;
[0-9]+ 				{ yylval.int_value = atoi(yytext); return INT; }
[a-zA-Z0-9]+      	{ yylval.string_value = strdup(yytext); return STRING; }

%%
