%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* funkcje i zmienne z flexa */
int yylex();
void yyerror( char* );
extern char* yytext;

%}

%union {
  int		i;
}

%left '+' '-'
%left '*' '/' '%'
%left UNARY_MINUS UNARY_PLUS


%token <i>	NUM
%token <i>	SEP

%type <i>	num num_expr expr

%start expr

%%

expr		: expr num_expr SEP { printf("wynik = %d\n", $2);}
		| { /* empty */ }
		;
num		: NUM { $$=$1;}
		;
num_expr	: num { $$=$1;}
		| '-' num_expr %prec UNARY_MINUS { $$=-$2;}
		| '+' num_expr %prec UNARY_PLUS  { $$=$2;}
		| num_expr '+' num_expr { $$=$1+$3;}
		| num_expr '-' num_expr { $$=$1-$3;}
		| num_expr '*' num_expr { $$=$1*$3;}
		| num_expr '/' num_expr { $$=$1/$3;}
		| num_expr '%' num_expr { $$=$1%$3;}
		| '(' num_expr ')' { $$=$2;}
		;

%%

void yyerror( char* s )
{
  fprintf(stderr,"niespodziewany token: '%s'\n",yytext);
  exit(1);
}

int main() {
   
   yyparse();
   return 0;
}
