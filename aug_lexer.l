%{
#include "aug_parser.h"
%}

OP	"+"|"-"|"*"|"/"|"%"
BRACKET	"("|")"
DIGIT	[0-9]
SEPARATOR ";"

%%

[ \t\n]           	;
[0-9]+ 				{ yylval.int_value = atoi(yytext); return INT; }
[a-zA-Z0-9]+      	{ yylval.string_value = strdup(yytext); return STRING; }

%%
