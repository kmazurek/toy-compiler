%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

extern char* strdup(char* s);

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
      struct expr* arg1;
      struct expr* arg2;
    } op;
  };
};

unsigned var_number = 0;

struct kv_pair {
    struct kv_pair* next;
    unsigned index;
    char* key;
    long long int value;
};

#define HASHSIZE 101
static struct kv_pair* hashtab[HASHSIZE];

unsigned hash(char* s) {
    unsigned hashval;

    for (hashval = 0; *s != '\0'; s++)
      hashval = *s + 31 * hashval;

    return hashval % HASHSIZE;
}

struct kv_pair* hashtab_lookup(char* s) {
    struct kv_pair* kv;
    for (kv = hashtab[hash(s)]; kv != NULL; kv = kv->next)
        if (strcmp(s, kv->key) == 0)
          return kv;

    return NULL;
}

struct kv_pair* hashtab_put(char* key, long long int value) {
    struct kv_pair* kv;
    unsigned hashval;
    if ((kv = hashtab_lookup(key)) == NULL) {
        kv = (struct kv_pair *) malloc(sizeof(*kv));

        if (kv == NULL || (kv->key = strdup(key)) == NULL)
          return NULL;

        hashval = hash(key);
        kv->index = var_number;
        kv->key = key;
        kv->next = hashtab[hashval];
        kv->value = value;
        hashtab[hashval] = kv;

        ++var_number;
    }

    return kv;
}

char* get_var_address(char* var_name) {
	unsigned index = hashtab_lookup(var_name)->index;
	char buffer[12];
    snprintf(buffer, sizeof buffer, "$%d", index);
    return strdup(buffer);
}

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
	char num_oper;
	long long int value;
	char* string_value;
	struct expr* expr_value;
}

%error-verbose

%token AND ASSIGN DO ELSE END EXIT IF NOT OR PRINT READ SEPARATOR START THEN WHILE

%token <value> NUMBER TRUE_VAL FALSE_VAL
%token <string_value> IDENT
%token <num_oper> NUM_OPERATOR

%type <expr_value> num_expression

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

num_expression: NUMBER {
		$$ = (struct expr*)malloc(sizeof(struct expr));
		$$->type = constant;
		$$->value = $1;
	}
	| num_expression NUM_OPERATOR num_expression {
		$$ = (struct expr*)malloc(sizeof(struct expr));
		$$->type = operation;
		$$->op.arg1 = $1;
		$$->op.operator = $2;
		$$->op.arg2 = $3;
	}
	| IDENT {
		$$ = (struct expr*)malloc(sizeof(struct expr));
		$$->type = identifier;
		$$->name = $1;
	}
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

assign_statement: IDENT ASSIGN num_expression
	{
		long long int value = evaluate($3);
		hashtab_put($1, value);
	}
;

input_statement: READ IDENT { fprintf(output_file, "READ\n"); };

output_statement: PRINT num_expression {
	fprintf(output_file, "PRINT %s\n", get_var_address($2->name));
};

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

	int lhs_arg=0, rhs_arg=0;

	switch (expr->type) {
		case constant:
			return expr->value;
		case identifier:
			return (hashtab_lookup(expr->name))->value;
		case operation:
			if(expr->op.arg1 != NULL) lhs_arg=evaluate(expr->op.arg1);
	 		if(expr->op.arg2 != NULL) rhs_arg=evaluate(expr->op.arg2);

			switch (expr->op.operator) {
				case '+': return lhs_arg+rhs_arg;
	   			case '-': return lhs_arg-rhs_arg;
	   			case '*': return lhs_arg*rhs_arg;
	   			case '/': return lhs_arg/rhs_arg;
	   			case '%': return lhs_arg%rhs_arg;
			}
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
