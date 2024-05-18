%error-verbose

%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


#define CHEAT 0
#define HONEST 1
#define UNDEF 2

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


int current_result = -1;
int found_strategy = 0;
char* startegy_name;
int last_move = UNDEF;


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

%token S_BEGIN S_END SEQ EQUAL LESS LESSEQ GREATER GREATEREQ PLUS MINUS DEF ASSIGN WHILE IF ELSE PRINT RANDOM STRATEGY RETURN LAST
%token <i> VAR
%token <x> INT


%nonassoc else_priority
%nonassoc ELSE


%left SEQ

%%

prog : stmt	{ program_stmts = $1; program_vars = NULL; }


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
	| def
	|assign
	| stmt SEQ stmt
		{ $$ = make_stmt(SEQ,NULL,NULL,$1,$3,NULL); }
	| WHILE expr S_BEGIN stmt S_END
		{ $$ = make_stmt(WHILE,NULL,$2,$4,NULL,NULL); }
	| PRINT VAR
		{ $$ = make_stmt(PRINT,find_var($2),NULL,NULL,NULL,NULL); }
	| IF expr S_BEGIN stmt S_END	%prec else_priority
		{ $$ = make_stmt(IF,NULL,$2,$4,NULL,NULL); }
	| IF expr S_BEGIN stmt S_END SEQ ELSE S_BEGIN stmt S_END
		{ $$ = make_stmt(ELSE,NULL,$2,$4,$9,NULL); }
	| STRATEGY VAR S_BEGIN stmt S_END
		{ $$ = make_stmt(STRATEGY,make_var($2),NULL,$4,NULL,NULL); }
	| RETURN expr
		{ $$ = make_stmt(RETURN,NULL,$2,NULL,NULL,NULL); }


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
	| LAST {$$ = make_expr(LAST,NULL,NULL,NULL,NULL);}
	| RANDOM INT
		{ $$ = make_expr(RANDOM,NULL,NULL,make_expr(INT,$2,NULL,NULL,NULL),NULL); }


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
		case LESS : return eval(e->left) < eval(e->right);
		case LESSEQ : return eval(e->left) <= eval(e->right);
		case GREATER : return eval(e->left) > eval(e->right);
		case GREATEREQ : return eval(e->left) >= eval(e->right);
		case LAST : return last_move;
		case RANDOM : return rand() % (eval(e->left));
	}
}

void print_var (var *v)
{
	printf("%s = %d\n", v->name, v->value);
}

void execute (stmt *s)
{
	switch(s->type)
	{
		case STRATEGY:
			if(!found_strategy)
			{
				if (strcmp(startegy_name, s->var->name) == 0)
				{
					found_strategy = 1;
				}
				execute(s->left);
			}
			break;
		case RETURN:
			current_result = eval(s->expr);
			return;
			break;
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

int execute_strategy(char* name, int last)
{
	found_strategy = 0;
	startegy_name = name;
	last_move = last;
	current_result = UNDEF;
	// printf("Strategy %s :  \n", name);
	execute(program_stmts);
	if(found_strategy == 0)
	{
		printf("Strategy %s not found\n", name);
	}
	// printf("Strategy Result : %d\n", current_result);
	return current_result;
}


void strategy_fight(char* name1, char* name2)
{
	int last1 = UNDEF;
	int last2 = UNDEF;
	int points1 = 0;
	int points2 = 0;

	int steps = 10;
	int rewardHH = 3;
	int rewardHC = 0;
	int rewardCH = 5;
	int rewardCC = 1;

	for (int i = 0; i < steps; ++i)
	{
		int templast1 = last1;
		int templast2 = last2;
		last1 = execute_strategy(name1, templast2);
		last2 = execute_strategy(name2, templast1);
		if(last1 == HONEST)
		{
			if(last2 == HONEST)
			{
				points1 += rewardHH;
				points2 += rewardHH;
			}
			else
			{
				points1 += rewardHC;
				points2 += rewardCH;
			}
		}
		else
		{
			if(last2 == HONEST)
			{
				points1 += rewardCH;
				points2 += rewardHC;
			}
			else
			{
				points1 += rewardCC;
				points2 += rewardCC;
			}
		}
	}

	printf("Results : \n %s : %d points\n%s : %d points\n", name1, points1, name2, points2);
}

/****************************************************************************/


void remove_leading_newline(char *str)
{
	if (str[0] == '\n') 
	{
		memmove(str, str + 1, strlen(str));
	}
}


int main (int argc, char **argv)
{
	srand(time(NULL));
	char sname1[300];
	char sname2[300];

	init();
	if (argc <= 1) { yyerror("no file specified"); exit(1); }
	yyin = fopen(argv[1],"r");
	if (!yyparse())
		{
			while(1)
			{
				printf("\n\n");
				scanf("%[^,],%s", sname1, sname2);
				remove_leading_newline(sname1);
				remove_leading_newline(sname2);
				strategy_fight(sname1, sname2);
			}
		}
	// if (!yyparse()) printf("\nSuccess\n"); else printf("\nFailure\n");
	return 0;
}
