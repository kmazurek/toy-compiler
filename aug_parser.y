%{
#include <stdio.h>
#include <stdarg.h>
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

typedef enum {constant, identifier, expression} node_type;

struct ast_node {
  node_type type;
  union {
    long long int value;
    char* name;
    struct {
      char operator;
      struct ast_node* arg1;
      struct ast_node* arg2;
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

unsigned output_line_num = 1;

void write_to_output(const char* format, ...) {
	va_list args;

	va_start(args, format);
	fprintf(output_file, "%d ", output_line_num);
	vfprintf(output_file, format, args);
	va_end(args);

	++output_line_num;
}

char* get_var_address(char* var_name) {
	unsigned index = hashtab_lookup(var_name)->index;
	char buffer[12];
    snprintf(buffer, sizeof buffer, "$%d", index);
    return strdup(buffer);
}

void evaluate(struct ast_node*);
void evaluate_bool_rel(struct ast_node*, char*);

%}

%union {
	char num_operator;
	long long int value;
	char* string_value;
	struct ast_node* expr_value;
}

%error-verbose

%token AND ASSIGN DO ELSE END EXIT IF NOT OR PRINT READ SEPARATOR START THEN WHILE

%token <value> NUMBER TRUE_VAL FALSE_VAL
%token <string_value> IDENT
%token <num_operator> NUM_OPERATOR
%token <string_value> BOOL_RELATION

%type <expr_value> num_expression
%type <expr_value> bool_expression

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
		$$ = (struct ast_node*)malloc(sizeof(struct ast_node));
		$$->type = constant;
		$$->value = $1;
	}
	| num_expression NUM_OPERATOR num_expression {
		$$ = (struct ast_node*)malloc(sizeof(struct ast_node));
		$$->type = expression;
		$$->op.arg1 = $1;
		$$->op.operator = $2;
		$$->op.arg2 = $3;
	}
	| IDENT {
		$$ = (struct ast_node*)malloc(sizeof(struct ast_node));
		$$->type = identifier;
		$$->name = $1;
	}
;

bool_operator: AND | OR; // replace with & and | in parser and treat as an operator?

bool_expression: TRUE_VAL {
		$$ = (struct ast_node*)malloc(sizeof(struct ast_node));
		$$->type = constant;
		$$->value = 1;
	}
	| FALSE_VAL {
		$$ = (struct ast_node*)malloc(sizeof(struct ast_node));
		$$->type = constant;
		$$->value = 0;
	}
	| NOT bool_expression {
		evaluate($2);
		write_to_output("NEG\n");
	}
	| bool_expression bool_operator bool_expression {
		// TODO
	}
	| num_expression BOOL_RELATION num_expression {
		$$ = (struct ast_node*)malloc(sizeof(struct ast_node));
		$$->type = expression;
		$$->op.arg1 = $1;
		$$->op.arg2 = $3;

		evaluate_bool_rel($$, $2);
	}
;

while_statement: WHILE bool_expression DO instructions
	| DO instructions WHILE bool_expression
;

if_statement: IF bool_expression THEN instructions
	| IF bool_expression THEN instructions ELSE instructions
;

assign_statement: IDENT ASSIGN num_expression {
	evaluate($3);
	hashtab_put($1, 0);
	write_to_output("POP %s\n", get_var_address($1));
};

input_statement: READ IDENT {
	hashtab_put($2, 0);
	write_to_output("READ\n");
	write_to_output("POP %s\n", get_var_address($2));
};

output_statement: PRINT num_expression {
	write_to_output("PRINT %s\n", get_var_address($2->name));
};

%%

void yyerror(const char* err_msg) {
  fprintf(stderr, "%s: %s on line %d\n", err_msg, yytext, line_number);
  exit(1);
}

void evaluate(struct ast_node* node) {
	if (node == NULL) {
		fprintf(stderr, "Incorrect numeric expression on line %d\n", line_number);
		exit(1);
	}

	switch (node->type) {
		case constant:
			write_to_output("PUSH %lld\n", node->value);
			break;
		case identifier:
			write_to_output("PUSH %s\n", get_var_address(node->name));
			break;
		case expression:
			if(node->op.arg1 != NULL) evaluate(node->op.arg1);
	 		if(node->op.arg2 != NULL) evaluate(node->op.arg2);

			switch (node->op.operator) {
				case '+':
					write_to_output("ADD\n");
					break;
	   			case '-':
	   				write_to_output("SUB\n");
	   				break;
	   			case '*':
	   				write_to_output("MUL\n");
	   				break;
	   			case '/':
	   				write_to_output("DIV\n");
	   				break;
	   			case '%':
	   				write_to_output("REM\n");
	   				break;
			}
	}
}

void evaluate_bool_rel(struct ast_node* node, char* rel_operator) {
	if (node == NULL) {
		fprintf(stderr, "Incorrect boolean expression on line %d\n", line_number);
		exit(1);
	}

	if (node->type == expression) {
		if(node->op.arg1 != NULL) evaluate(node->op.arg1);
	 	if(node->op.arg2 != NULL) evaluate(node->op.arg2);

	 	if (strcmp(rel_operator, "=") == 0) {
	 		// JZ
	 	} else if (strcmp(rel_operator, ">") == 0) {
	 		// JLEZ
	 	} else if (strcmp(rel_operator, "<") == 0) {
	 		// JGEZ
	 	} else if (strcmp(rel_operator, ">=") == 0) {
	 		// JLZ
	 	} else if (strcmp(rel_operator, "<=") == 0) {
	 		// JGZ
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

	write_to_output("STOP");

	fclose(input_file);
	fclose(output_file);
	return 0;
}
