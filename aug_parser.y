%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* funkcje i zmienne z flexa */
extern int yylex();
extern int yyparse();

extern FILE *yyin;

void yyerror(char *err_msg);
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

void yyerror(char* err_msg)
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
