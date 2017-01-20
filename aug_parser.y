%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* funkcje i zmienne z flexa */
extern int yylex();
extern int yyparse();
extern FILE *yyin;

void yyerror(char *s);
%}

%union {
  int 	int_value;
  char* string_value;

}

%token <int_value> INT
%token <string_value> STRING

%%

snazzle:
	snazzle INT      { fprintf(stdout, "found an int: '%d'\n", $2); }
	| snazzle STRING { fprintf(stdout, "found a string: '%s'\n", $2); }
	| INT            { fprintf(stdout, "found an int: '%d'\n", $1); }
	| STRING         { fprintf(stdout, "found a string: '%s'\n", $1); }
	;

%%

void yyerror(char* s)
{
  fprintf(stderr, "unexpected token\n");
  exit(1);
}

int main() {
	// open a file handle to a particular file:
	FILE *myfile = fopen("test_file", "r");
	// make sure it's valid:
	if (!myfile) {
		fprintf(stderr, "failed to open test_file\n");
		return -1;
	}
	// set lex to read from it instead of defaulting to STDIN:
	yyin = myfile;

	do {
		yyparse();
	} while (!feof(yyin));

	return 0;
}
