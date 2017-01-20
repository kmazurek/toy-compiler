%{
	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>

	int yylex();
	void yyerror( char* );
	extern char* yytext;
%}

%token IDENTIFIER
%token NUMBER

%%

statement: IDENTIFIER '=' expression
		|	expression				{ printf("= %d\n", $1); }
		;

expression: NUMBER '+' NUMBER	{ $$ = $1 + $3; }
		|	NUMBER '-' NUMBER	{ $$ = $1 - $3; }
		|	NUMBER				{ $$ = $1; }
		;

%%

int main() {
   
   yyparse();
   return 0;
}
