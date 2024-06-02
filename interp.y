
%{

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>


#define CHEAT 0
#define HONEST 1
#define UNDEF 2
#define MAX_POP 100000

int yylex();

void yyerror(char *s)
{
	fflush(stdout);
}


typedef struct var
{
	char *name;
	int value;
	struct var *next;
} var;

typedef struct expr
{
	int type;
	int value;
	var *var;
	struct expr *left, *right;
} expr;

typedef struct stmt
{
	int type;
	var *var;
	expr *expr;
	struct stmt *left, *right;
	int value;
} stmt;

typedef struct stmtlist
{
	struct stmt *stmt;
	struct stmtlist *next;
} stmtlist;



typedef struct {
    char *strat;
    int health;
    int points;
} individual;



var *program_vars;
stmt *program_stmts;
stmtlist *strategies;


stmtlist* make_stmtlist (stmt *s)
{
	stmtlist *l = malloc(sizeof(stmtlist));
	l->stmt = s;
	l->next = NULL;
	return l;
}

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
			stmt *left, stmt *right, int value)
{
	stmt *s = malloc(sizeof(stmt));
	s->type = type;
	s->var = var;
	s->expr = expr;
	s->left = left;
	s->right = right;
	s->value = value;
	return s;
}



int strategy_nb = 0;

int current_result = -1;
int last_move = UNDEF;

int strategy_1_points;
int strategy_2_points;



int duration = 1;
int rewardHH = 3;
int rewardHC = 0;
int rewardCH = 5;
int rewardCC = 1;

int meetings = 10000;
int intervals = 100;
int initial = 1000;
int life = 10;
int spawn = 180;
int mutation = 10;



individual population[MAX_POP];
int population_size;
int total_weight = 0;


%}


%union {
	char *i;
	var *v;
	expr *e;
	stmt *s;
	int x;
}

%type <s> def
%type <e> expr
%type <s> stmt assign

%token S_BEGIN S_END SEQ EQUAL LESS LESSEQ GREATER GREATEREQ PLUS MINUS DEF ASSIGN WHILE IF ELSE PRINT RANDOM STRATEGY RETURN LAST ASSIGNC CONSTANTS
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
		
		$$ = make_stmt(0,NULL,NULL,NULL,NULL, 0);
	}

stmt : 
	| def
	|assign
	| stmt SEQ stmt
		{ $$ = make_stmt(SEQ,NULL,NULL,$1,$3, 0); }
	| WHILE expr S_BEGIN stmt S_END
		{ $$ = make_stmt(WHILE,NULL,$2,$4,NULL, 0); }
	| PRINT VAR
		{ $$ = make_stmt(PRINT,find_var($2),NULL,NULL,NULL, 0); }
	| IF expr S_BEGIN stmt S_END	%prec else_priority
		{ $$ = make_stmt(IF,NULL,$2,$4,NULL, 0); }
	| IF expr S_BEGIN stmt S_END ELSE S_BEGIN stmt S_END
		{ $$ = make_stmt(ELSE,NULL,$2,$4,$8, 0); }
	| STRATEGY VAR S_BEGIN stmt S_END
		{
			stmt *s = make_stmt(STRATEGY,make_var($2),NULL,$4,NULL, 1);
			$$ = s;
			stmtlist *slist = make_stmtlist(s);
			slist->next = strategies;
			strategies = slist;
			strategy_nb++;
		}
	| STRATEGY VAR INT S_BEGIN stmt S_END
		{
			stmt *s = make_stmt(STRATEGY,make_var($2),NULL,$5,NULL, $3);
			$$ = s;
			stmtlist *slist = make_stmtlist(s);
			slist->next = strategies;
			strategies = slist;
			strategy_nb++;
		}
	| RETURN expr
		{ $$ = make_stmt(RETURN,NULL,$2,NULL,NULL, 0); }
	| CONSTANTS S_BEGIN stmt S_END
			{ $$ = make_stmt(CONSTANTS,NULL,NULL,$3,NULL, 0); }

assign	: 
		VAR ASSIGN expr
		{
			$$ = make_stmt(ASSIGN,find_var($1),$3,NULL,NULL, 0);
		}
		| VAR ASSIGNC INT
		{
			if (strcmp($1, "duration") == 0)
			{
				duration = $3;
			}
			if (strcmp($1, "rewardCC") == 0)
			{
				rewardCC = $3;
			}
			if (strcmp($1, "rewardCH") == 0)
			{
				rewardCH = $3;
			}
			if (strcmp($1, "rewardHC") == 0)
			{
				rewardHC = $3;
			}
			if (strcmp($1, "rewardHH") == 0)
			{
				rewardHH = $3;
			}
			if (strcmp($1, "rewardHH") == 0)
			{
				rewardHH = $3;
			}
			if (strcmp($1, "meetings") == 0)
			{
				meetings = $3;
			}
			if (strcmp($1, "intervals") == 0)
			{
				intervals = $3;
			}
			if (strcmp($1, "initial") == 0)
			{
				initial = $3;
			}
			if (strcmp($1, "life") == 0)
			{
				life = $3;
			}
			if (strcmp($1, "spawn") == 0)
			{
				spawn = $3;
			}
			if (strcmp($1, "mutation") == 0)
			{
				mutation = $3;
			}
		}


expr : VAR		{ $$ = make_expr(0,0,find_var($1),NULL,NULL); }
	| INT		{ $$ = make_expr(INT,$1,0,NULL,NULL); }
	| expr PLUS expr { $$ = make_expr(PLUS,0,NULL,$1,$3); }
	| expr MINUS expr { $$ = make_expr(MINUS,0,NULL,$1,$3); }
	| expr LESS expr { $$ = make_expr(LESS,0,NULL,$1,$3); }
	| expr LESSEQ expr { $$ = make_expr(LESSEQ,0,NULL,$1,$3); }
	| expr GREATER expr { $$ = make_expr(GREATER,0,NULL,$1,$3); }
	| expr GREATEREQ expr { $$ = make_expr(GREATEREQ,0,NULL,$1,$3); }
	| expr EQUAL expr { $$ = make_expr(EQUAL,0,NULL,$1,$3); }
	| '(' expr ')'	{ $$ = $2; }
	| LAST {$$ = make_expr(LAST,0,NULL,NULL,NULL);}
	| RANDOM INT
		{ $$ = make_expr(RANDOM,$2,NULL,NULL,NULL); }


%%

#include "interplex.c"






int eval (expr *e)
{
	if(e == NULL)
	{
		return 0;
	}
	int e1 = eval(e->left);
	switch (e->type)
	{
		case 0:
			// printf("VAL(%d)", e->var->value);
			return e->var->value;
			break;
		case INT :
			// printf("INT(%d)", e->value);
			return e->value;
			break;
		case PLUS :
			// printf(" + ");
			return e1 + eval(e->right);
			break;
		case MINUS :
			// printf(" - ");
			return e1 - eval(e->right);
			break;
		case EQUAL :
			// printf(" == ");
			return e1 == eval(e->right);
			break;
		case LESS :
			// printf(" < ");
			return e1 < eval(e->right);
			break;
		case LESSEQ :
			// printf(" <= ");
			return e1 <= eval(e->right);
			break;
		case GREATER :
			// printf(" > ");
			return e1 > eval(e->right);
			break;
		case GREATEREQ :
			// printf(" >= ");
			return e1 >= eval(e->right);
			break;
		case LAST :
			// printf("LAST");
			return last_move;
			break;
		case RANDOM :
			return rand() % e->value;
			break;
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
		case RETURN:
			// printf("RETURN\t \n");
			current_result = eval(s->expr);
			break;
		case ASSIGN:
			// printf("ASSIGN\t ");
			s->var->value = eval(s->expr);
			break;
		case SEQ:
			// printf("SEQ(\n");
			execute(s->left);
			// printf(",\n");
			execute(s->right);
			// printf("\n)");
			break;
		case WHILE:
			while (eval(s->expr))
			{
				execute(s->left);
			}
			break;
		case PRINT: 
			print_var(s->var);
			puts("");
			break;
		case IF:
			// printf("IF(\n");
			if (eval(s->expr))
			{
				// printf(")\n{\n");
				execute(s->left);
				// printf("}\n");
			}
			// printf(")\n");
			break;
		case ELSE:
			// printf("IF(\n");
			if (eval(s->expr))
			{
				// printf(")\n{");
				execute(s->left);
				// printf("}\n");
			}
			else
			{
				// printf(")\nELSE\n{");
				execute(s->right);
				// printf("}\n");
			}
			break;
	}
}

int execute_strategy(char* name, int last)
{
	last_move = last;
	stmtlist *currstrat = strategies;
	while(currstrat != NULL)
	{
		if (strcmp(name, currstrat->stmt->var->name) == 0)
		{
			// printf("%s : \n", currstrat->stmt->var->name);
			execute(currstrat->stmt->left);
			// printf("----------\n");
			return current_result;
		}
		currstrat = currstrat->next;
	}
	printf("Strategy %s not found\n", name);
	return UNDEF;
}


void strategy_fight(char* name1, char* name2, int print_results)
{
	int last1 = UNDEF;
	int last2 = UNDEF;
	int points1 = 0;
	int points2 = 0;

	for (int i = 0; i < duration; ++i)
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
	strategy_1_points = points1;
	strategy_2_points = points2;
	if (print_results)
	{
		printf("Results : \n %s : %d points\n%s : %d points\n", name1, points1, name2, points2);
	}
}

char* random_strategy()
{
	int rand_weight = rand() % total_weight;
	int weight_sum = 0;
	stmtlist *currstrat = strategies;
	while(currstrat != NULL)
	{
		weight_sum += currstrat->stmt->value;
	    if (rand_weight < weight_sum)
	    {
	    	return currstrat->stmt->var->name;
	        break;
	    }
		currstrat = currstrat->next;
	}
	return NULL;
}


void initialize_population()
{
    stmtlist *currstrat = strategies;
	while(currstrat != NULL)
	{
		total_weight += currstrat->stmt->value;
		currstrat = currstrat->next;
	}

    for (int i = 0; i < initial; i++)
    {
    	population[i].strat = random_strategy();
        population[i].health = life;
        population[i].points = 0;
    }
    population_size = initial;
}


void handle_meeting(int idx1, int idx2)
{
    strategy_fight(population[idx1].strat, population[idx2].strat, 0);
    population[idx1].points += strategy_1_points;
    population[idx2].points += strategy_2_points;

    population[idx1].health--;
    population[idx2].health--;

    if (population[idx1].health <= 0)
    {
    	population[idx1] = population[population_size - 1];
        population_size--;
    }

    if (population[idx2].health <= 0)
    {
    	population[idx2] = population[population_size - 1];
        population_size--;
    }
}

void handle_reproduction(int idx)
{
    int spawn_threshold = spawn;

    if (population[idx].health > 0 && population[idx].points >= spawn_threshold)
    {
        population[idx].points -= spawn_threshold;
        int spawn_idx = population_size++;
        population[spawn_idx].strat = population[idx].strat;
        population[spawn_idx].health = life;
        population[spawn_idx].points = 0;

        if (rand() % 100 < mutation)
        {
            population[spawn_idx].strat = random_strategy();
        }
    }
}

void print_statistics(int interval)
{
    printf("Interval %d: Population size = %d\n", interval, population_size);

    stmtlist *currstrat = strategies;
	while(currstrat != NULL)
	{
		int count = 0;

		for (int i = 0; i < population_size; ++i)
		{
			if (strcmp(population[i].strat, currstrat->stmt->var->name) == 0)
			{
                count++;
            }
		}

		printf("%s : %d\n", currstrat->stmt->var->name, count);

		currstrat = currstrat->next;
	}

	printf("----------\n\n");
    // for (int i = 0; i < population_size; ++i)
    // {
    // 	printf("Individual %d : Strat : %s | Life : %d | Points %d\n", i, population[i].strat, population[i].health, population[i].points);
    // }

}

void run_simulation()
{
    for (int interval = 0; interval < intervals; interval++)
    {
        for (int meeting = 0; meeting < meetings; meeting++)
        {
            int idx1 = rand() % population_size;
            int idx2 = rand() % population_size;

            while (idx1 == idx2)
            {
                idx2 = rand() % population_size;
            }

            handle_meeting(idx1, idx2);
            handle_reproduction(idx1);
            handle_reproduction(idx2);

            if(population_size <= 1)
            {
            	return;
            }
        }
        print_statistics(interval);
    }
}


void simulate_population()
{
	initialize_population();
	run_simulation();
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
			printf("Population Simulation : \n");
			simulate_population();
			printf("\n\n\nTo make two startegies fight each other write Strat1,Start2 : \n\n");
			while(1)
			{
				printf("\n\n");
				scanf("%[^,],%s", sname1, sname2);
				remove_leading_newline(sname1);
				remove_leading_newline(sname2);
				strategy_fight(sname1, sname2, 1);
			}
		}
	return 0;
}
