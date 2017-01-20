%{
#include "aug_parser.h"

/* funkcja konwertuj±ca napis na liczbê */
int to_int();

%}

OP	"+"|"-"|"*"|"/"|"%"
BRACKET	"("|")"
DIGIT	[0-9]
SEPARATOR ";"
%%

{OP}		return yytext[0];
{BRACKET}	return yytext[0];
{DIGIT}+	return to_int();
{SEPARATOR}	return SEP;
\n

%%

int to_int()
{
  int i=0;
  
  yylval.i=0;
  for(;i<strlen(yytext);i++)
    if(yytext[i]!='_') yylval.i=yylval.i*10+yytext[i]-'0';
  return NUM;
}	  
