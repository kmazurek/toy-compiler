%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void yyerror(const char* err_msg);
extern int yylex();
extern int yyparse();

extern char* yytext;
extern FILE* yyin;

extern int line_number;

FILE* output_file;

typedef enum {constant, identifier, operation} node_type;

struct expr {
  node_type type;
  union {
    long long int value;
    char* name;
    struct {
      char operator;
      struct expr *arg1;
      struct expr *arg2;
    } operation;
  };
};

/* zmienne i funkcje pomocnicze */
long long int variables[255];    		// tablica warto¶ci zmiennych
struct expr* expressions[255];			// tablica drzew wyra¿eñ

int dict_get(char);	// pobierz warto¶æ ze s³ownika zmiennych lub wyra¿eñ
void dict_insert_var(char, int);	// wpisz now± warto¶æ do s³ownika zmiennych
void dict_insert_expr(char, struct expr*); // zapamiêtaj wyra¿enie

int evaluate(struct expr*);		// wyznacz warto¶æ wyra¿enia
void delete_expr(struct expr*); // usuñ drzewo wyra¿enia (rekursywnie)
%}

%union {
  long long int value;
  char* string_value;
}

%error-verbose

%token AND ASSIGN DO ELSE END EXIT IF NOT OR PRINT READ SEPARATOR START THEN WHILE

%token <value> NUMBER TRUE_VAL FALSE_VAL
%token <string_value> IDENT

%left '+' '-' '*' '/' '%'
%left '=' '<' '>'
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
bool_relation: '=' | '<' | '>';

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

input_statement: READ IDENT { fprintf(output_file, "READ\n"); };

output_statement: PRINT num_expression { fprintf(output_file, "PRINT\n"); };

// snazzle:
// 	snazzle NUMBER      	{ fprintf(stdout, "found a number: %lld\n", $2); }
// 	| snazzle IDENT			{ fprintf(stdout, "found a string: %s\n", $2); }
// 	| NUMBER            	{ fprintf(stdout, "found a number: %lld\n", $1); }
// 	| IDENT         		{ fprintf(stdout, "found a string: %s\n", $1); }
// 	;

%%

void yyerror(const char* err_msg) {
  fprintf(stderr, "%s: %s on line %d\n", err_msg, yytext, line_number);
  exit(1);
}

int evaluate(struct expr* expr) {
	if (expr == NULL) {
		fprintf(stderr, "Incorrect expression on line %d\n", line_number);
		exit(1);
	}
}

int main(int argc, char** args) {
	FILE* input_file;

	if (argc == 3) {
		input_file = fopen(args[1], "r");
		if (!input_file) {
			fprintf(stderr, "failed to open file %s\n", args[1]);
			return -1;
		}

		output_file = fopen(args[2], "w");
		if (!output_file) {
			fprintf(stderr, "failed to open file %s\n", args[2]);
			return -1;
		}
	}

	yyin = input_file;

	do {
		yyparse();
	} while (!feof(yyin));

	fclose(input_file);
	fclose(output_file);
	return 0;
}
