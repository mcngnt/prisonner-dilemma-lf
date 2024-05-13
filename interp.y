%error-verbose

%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int yylex();

void yyerror(char *s)
{
	fflush(stdout);
	fprintf(stderr, "%s\n", s);
}

/***************************************************************************/
/* Data structures for storing a programme.                                */

typedef struct var	// a variable
{
	char *name;
	int value;
	struct var *next;
} var;

typedef struct varlist	// variable reference (used for print statement)
{
	struct var *var;
	struct varlist *next;
} varlist;

typedef struct expr	// boolean expression
{
	int type;
	int value;
	var *var;
	struct expr *left, *right;
} expr;

typedef struct stmt	// command
{
	int type;	// ASSIGN, ';', WHILE, PRINT, IF
	var *var;
	expr *expr;
	struct stmt *left, *right;
	varlist *list;
} stmt;

/****************************************************************************/
/* All data pertaining to the programme are accessible from these two vars. */

var *program_vars;
stmt *program_stmts;

/****************************************************************************/
/* Functions for settting up data structures at parse time.                 */

var* make_var (char *s)
{
	var *v = malloc(sizeof(var));
	v->name = s;
	v->value = 0;
	v->next = NULL;
	return v;
}

var* find_var (char *s)
{
	var *v = program_vars;
	while (v && strcmp(v->name,s)) v = v->next;
	if (!v) { yyerror("undeclared variable"); exit(1); }
	return v;
}

varlist* make_varlist (char *s)
{
	var *v = find_var(s);
	varlist *l = malloc(sizeof(varlist));
	l->var = v;
	l->next = NULL;
	return l;
}

expr* make_expr (int type,int value, var *var, expr *left, expr *right)
{
	expr *e = malloc(sizeof(expr));
	e->type = type;
	e->value = value;
	e->var = var;
	e->left = left;
	e->right = right;
	return e;
}

stmt* make_stmt (int type, var *var, expr *expr,
			stmt *left, stmt *right, varlist *list)
{
	stmt *s = malloc(sizeof(stmt));
	s->type = type;
	s->var = var;
	s->expr = expr;
	s->left = left;
	s->right = right;
	s->list = list;
	return s;
}


%}

/****************************************************************************/

/* types used by terminals and non-terminals */

%union {
	char *i;
	var *v;
	varlist *l;
	expr *e;
	stmt *s;
	int x;
}

%type <s> def
%type <e> expr
%type <s> stmt assign

%token S_BEGIN S_END START_COMMENT END_COMMENT SEQ EQUAL LESS PLUS MINUS DEF ASSIGN WHILE IF ELSE PRINT RANDOM STRATEGY RETURN LAST UNDEF
%token <i> VAR
%token <x> INT

%left SEQ

%%

prog : stmt	{ program_stmts = $1; program_vars = NULL; }


// declist	: VAR			{ $$ = make_var($1); }
// 	| declist ',' VAR	{ ($$ = make_var($3))->next = $1; }

def : DEF VAR
    {
        if(!program_vars)
        {
        	program_vars = make_var($2);
        }
        else
        {
        	var* v = program_vars;
        	while(v->next)
        	{
        		v = v->next;
        	}
        	v->next = make_var($2);
        }
        
        $$ = make_stmt(0,NULL,NULL,NULL,NULL,NULL);
    }

stmt : 
	| def {}
	|assign
	| stmt SEQ stmt
		{ $$ = make_stmt(SEQ,NULL,NULL,$1,$3,NULL); }
	| WHILE expr S_BEGIN stmt S_END
		{ $$ = make_stmt(WHILE,NULL,$2,$4,NULL,NULL); }
	| PRINT VAR
		{ $$ = make_stmt(PRINT,find_var($2),NULL,NULL,NULL,NULL); }
	| IF expr S_BEGIN stmt S_END SEQ ELSE S_BEGIN stmt S_END
		{ $$ = make_stmt(ELSE,NULL,$2,$4,$9,NULL); }
	| IF expr S_BEGIN stmt S_END
		{ $$ = make_stmt(IF,NULL,$2,$4,NULL,NULL); }


assign	: VAR ASSIGN expr
		{
			$$ = make_stmt(ASSIGN,find_var($1),$3,NULL,NULL,NULL);
		}


expr : VAR		{ $$ = make_expr(0,0,find_var($1),NULL,NULL); }
	| INT		{ $$ = make_expr(INT,$1,NULL,NULL,NULL); }
	| expr PLUS expr { $$ = make_expr(PLUS,NULL,NULL,$1,$3); }
	| expr MINUS expr { $$ = make_expr(MINUS,NULL,NULL,$1,$3); }
	| expr LESS expr { $$ = make_expr(LESS,NULL,NULL,$1,$3); }
	| expr EQUAL expr { $$ = make_expr(EQUAL,NULL,NULL,$1,$3); }
	| '(' expr ')'	{ $$ = $2; }

%%

#include "interplex.c"

/****************************************************************************/
/* programme interpreter      :                                             */

int eval (expr *e)
{
	switch (e->type)
	{
		case 0: return e->var->value;
		case INT : return e->value;
		case PLUS : return eval(e->left) + eval(e->right);
		case MINUS : return eval(e->left) - eval(e->right);
		case EQUAL : return eval(e->left) == eval(e->right);
		case LESS : return eval(e->left) <= eval(e->right);
	}
}

void print_var (var *v)
{
	printf("%s = %d  ", v->name, v->value);
}

void execute (stmt *s)
{
	switch(s->type)
	{
		case ASSIGN:
			s->var->value = eval(s->expr);
			break;
		case SEQ:
			execute(s->left);
			execute(s->right);
			break;
		case WHILE:
			while (eval(s->expr)) execute(s->left);
			break;
		case PRINT: 
			print_var(s->var);
			puts("");
			break;
		case IF:
			if (eval(s->expr)) execute(s->left);
			break;
		case ELSE:
			if (eval(s->expr)) execute(s->left);
			else execute(s->right);
			break;
	}
}

/****************************************************************************/

int main (int argc, char **argv)
{
	init();
	if (argc <= 1) { yyerror("no file specified"); exit(1); }
	yyin = fopen(argv[1],"r");
	if (!yyparse()) execute(program_stmts);
	// if (!yyparse()) printf("\nSuccess\n"); else printf("\nFailure\n");
	return 0;
}
