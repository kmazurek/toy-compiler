%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* funkcje i zmienne z flexa */
extern int yylex();
extern int yyparse();

extern FILE *yyin;

void yyerror(const char *err_msg);
%}

%union {
  signed long long int 	int_value;
  char* string_value;
}

%error-verbose

%token <int_value> NUMBER
%token <string_value> IDENT
%token AND ASSIGN DO ELSE END EXIT IF NOT PRINT READ SEPARATOR START THEN WHILE

%%

program: instructions;

while_statement: WHILE expression DO instructions
	| DO instructions WHILE expression
;

if_statement: IF expression THEN instructions
	| IF expression THEN instructions ELSE instructions
;

assign_statement: IDENT ASSIGN expression;

input_statement: READ IDENT;

output_statement: PRINT expression;

instruction: EXIT
	| START instruction_chain END
	| while_statement
	| if_statement
	| assign_statement
	| input_statement
	| output_statement
;

instruction_chain: instruction_chain instruction SEPARATOR
	| instruction
;

instructions:
	| instructions instruction SEPARATOR
;

expression: NUMBER
	| IDENT
	| expression '=' expression
	| expression '<' expression
	| expression '>' expression
	| expression "<=" expression
	| expression ">=" expression
	| expression '+' expression
	| expression '-' expression
	| expression '*' expression
	| expression '/' expression
	| expression '%' expression
;

// snazzle:
// 	snazzle NUMBER      	{ fprintf(stdout, "found a number: %lld\n", $2); }
// 	| snazzle IDENT			{ fprintf(stdout, "found a string: %s\n", $2); }
// 	| NUMBER            	{ fprintf(stdout, "found a number: %lld\n", $1); }
// 	| IDENT         		{ fprintf(stdout, "found a string: %s\n", $1); }
// 	;

%%

void yyerror(const char* err_msg)
{
  fprintf(stderr, "Parse error: %s\n", err_msg);
  exit(1);
}

int main(int argc, char** args) {
	FILE* file;

	if (argc == 2) {
		file = fopen(args[1], "r");
		if (!file) {
			fprintf(stderr, "failed to open file %s\n", args[1]);
			return -1;
		}
	}

	yyin = file;

	do {
		yyparse();
	} while (!feof(yyin));

	return 0;
}
