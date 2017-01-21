%{
#include "aug_parser.h"
%}

%x COMMENT

sl_comment_open "//"
ml_comment_open "/*"
ml_comment_close "*/"

digit			[0-9]
sign_opt 		('+'|'-')?
number 			{sign_opt}({digit}+)

identifier 		[a-zA-Z][a-zA-Z{digit}]*
endl 			\n
whitespace 		[ \t]+

separator 		';'
assignment 		":="

and_op 			"and"
or_op 			"or"
not_op 			"not"

do_op 			"do"
else_op 		"else"
if_op 			"if"
then_op			"then"
while_op		"while"

print_op		"print"
read_op			"read"

start_op		"start"
end_op			"end"
exit_op			"exit"

%%

{sl_comment_open}.* 			{}
{ml_comment_open} 				{ BEGIN(COMMENT); }
<COMMENT>{ml_comment_close} 	{ BEGIN(INITIAL); }
<COMMENT>(.|{endl}) 			{}

{and_op}						{ return AND; }
{not_op}						{ return NOT; }
{or_op}							{ return OR; }

{do_op}							{ return DO; }
{else_op}						{ return ELSE; }
{if_op}							{ return IF; }
{then_op}						{ return THEN; }
{while_op}						{ return WHILE; }

{print_op}						{ return PRINT; }
{read_op}						{ return READ; }

{end_op}						{ return END; }
{exit_op}						{ return EXIT; }
{start_op}						{ return START; }

[ \t\n]           				;
{separator}						{ return SEPARATOR; }
{number}+ 						{ yylval.int_value = atoi(yytext); return NUMBER; }
{identifier}      				{ yylval.string_value = strdup(yytext); return IDENT; }
{assignment}					{ return ASSIGN; }

%%
