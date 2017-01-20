%{
	// This is the definition section. Here's where we put all the headers etc.
	#include "aug_parser.h"
	extern int yylval;
%}

%x COMMENT

sl_comment_open "//"
ml_comment_open "/*"
ml_comment_close "*/"

digit [0-9]
identifier [a-zA-Z][a-zA-Z{digit}]*
sign_opt ("+"|"-")?
number {sign_opt}({digit}+)

num_operator "+" | "-" | "*" | "/" | "%"
bool_operator "and" | "or"
relation_operator "=" | "<" | "<=" | ">" | ">="

whitespace [ \t]+
EOL \n

%%

{sl_comment_open}.* 		{}
{ml_comment_open} 			{ BEGIN(COMMENT); }
<COMMENT>{ml_comment_close} { BEGIN(INITIAL); }
<COMMENT>(.|{EOL}) 			{}

{number}					{ yylval = atoi(yytext); return NUMBER; }
{whitespace}				;
\n 							return 0;
. 							return yytext[0];

%%

int main(int argc, char** argv) {
	if (argc > 1) {
		FILE *file;
		file = fopen(argv[1], "r");

		if (!file) {
			fprintf(stderr,"could not open %s\n",argv[1]);
			exit(1);
		}

		yyin = file;
	}

	yylex();
	return 0;
}