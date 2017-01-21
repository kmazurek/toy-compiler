%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void yyerror(const char *err_msg);
extern int yylex();
extern int yyparse();

extern char* yytext;
extern FILE *yyin;

extern int line_number;
%}

%union {
  int bool_value;
  signed long long int 	int_value;
  char* string_value;
}

%error-verbose

%token AND ASSIGN DO ELSE END EXIT IF NOT OR PRINT READ SEPARATOR START THEN WHILE

%token <bool_value> TRUE_VAL FALSE_VAL
%token <int_value> NUMBER
%token <string_value> IDENT

%left '+' '-' '*' '/' '%'
%left "=" "<" ">" "<=" ">="
%left '(' ')'

%start program

%%

program: instructions;

instructions: instructions instruction
	| instruction
;

instruction: EXIT SEPARATOR
	| START instructions END SEPARATOR
	| while_statement
	| if_statement
	| assign_statement SEPARATOR
	| input_statement SEPARATOR
	| output_statement SEPARATOR
;

num_operator: '+' | '-' | '*' | '/' | '%';

num_expression: NUMBER
	| num_expression num_operator num_expression
	| IDENT
;

bool_operator: AND | OR;
bool_relation: "=" | "<" | ">" | "<=" | ">=";

bool_expression: TRUE_VAL
	| FALSE_VAL
	| NOT bool_expression
	| bool_expression bool_operator bool_expression
	| num_expression bool_relation num_expression
;

while_statement: WHILE bool_expression DO instructions
	| DO instructions WHILE bool_expression
;

if_statement: IF bool_expression THEN instructions
	| IF bool_expression THEN instructions ELSE instructions
;

assign_statement: IDENT ASSIGN num_expression;

input_statement: READ IDENT;

output_statement: PRINT num_expression;

// snazzle:
// 	snazzle NUMBER      	{ fprintf(stdout, "found a number: %lld\n", $2); }
// 	| snazzle IDENT			{ fprintf(stdout, "found a string: %s\n", $2); }
// 	| NUMBER            	{ fprintf(stdout, "found a number: %lld\n", $1); }
// 	| IDENT         		{ fprintf(stdout, "found a string: %s\n", $1); }
// 	;

%%

void yyerror(const char* err_msg)
{
  fprintf(stderr, "%s: %s on line %d\n", err_msg, yytext, line_number);
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
