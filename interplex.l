%option noyywrap

%{

// TODO :
// TEXT buggé commentaie (ex: TEXT MINUS TEXT)
// SEQ apparait entre if et else
// Double SEQ

#define DEBUG


#ifdef DEBUG
#define DEBUG_PRINT(token) printf(token);
#else
#define DEBUG_PRINT(token) 
#endif


#ifdef DEBUG

#define S_BEGIN 1
#define S_END 2
#define START_COMMENT 3
#define END_COMMENT 4
#define SEQ 5
#define EQUAL 6
#define LESS 7
#define PLUS 8
#define MINUS 9
#define DEF 10
#define ASSIGN 11
#define WHILE 12
#define IF 13
#define ELSE 14
#define PRINT 15
#define RANDOM 16
#define STRATEGY 17
#define RETURN 18
#define VAR 19
#define INT 20


#endif

int current_line_indent = 0;
int indent_level = 0;
int is_commenting = 0;

int uncomment_to_print = 0;


char* stored_var;
int is_var_to_print = 0;
int has_seq_been_printed = 0;
int has_var_been_stored = 0;

%}

DIG	[0-9]


%s indent
%s normal

%%



<indent>"\t" { current_line_indent++ ;}

<indent>. {
			unput(*yytext);
			if(current_line_indent < indent_level)
			{
				indent_level--;
				DEBUG_PRINT("S_END "); return S_END;
			}
			else if(uncomment_to_print)
			{
				uncomment_to_print--;
				DEBUG_PRINT("END_COMMENT "); return END_COMMENT;
			}
			else if(current_line_indent > indent_level)
			{
				BEGIN normal;
				DEBUG_PRINT("S_BEGIN "); return S_BEGIN;
			}
			else
			{
				BEGIN normal;
				DEBUG_PRINT("SEQ "); return SEQ;
			}
		  }


<normal>"\n" {
		if(is_commenting)
		{
			is_commenting = 0;
			uncomment_to_print++;
		}
		indent_level =  current_line_indent;
		current_line_indent = 0;
		BEGIN indent;
	 }


<normal>"#"	{ is_commenting = 1; DEBUG_PRINT("START_COMMENT "); return START_COMMENT; }

<normal>"==" { DEBUG_PRINT("EQUAL "); return EQUAL; }
<normal>"<="	{DEBUG_PRINT("LESS "); return LESS; }
<normal>"+"	{ DEBUG_PRINT("PLUS "); return PLUS; }
<normal>"-"	{ DEBUG_PRINT("MINUS "); return MINUS; }

<normal>"def"	{ is_var_to_print = 1; has_seq_been_printed = 0; has_var_been_stored = 0; DEBUG_PRINT("DEF "); return DEF; }
<normal>"="	{ DEBUG_PRINT("ASSIGN "); return ASSIGN; }

<normal>"while"	{ DEBUG_PRINT("WHILE "); return WHILE; }
<normal>"if"	{ DEBUG_PRINT("IF "); return IF; }
<normal>"else"	{ DEBUG_PRINT("ELSE "); return ELSE; }

<normal>"print"	{ DEBUG_PRINT("PRINT "); return PRINT; }
<normal>"Random"	{ DEBUG_PRINT("RANDOM "); return RANDOM; }

<normal>"Strategy"	{ DEBUG_PRINT("STRATEGY "); return STRATEGY; }
<normal>"return"	{ DEBUG_PRINT("RETURN "); return RETURN; }


<normal>{DIG}+	{
					#ifndef DEBUG
						yylval.x = atoi(yytext); 
					#endif
					DEBUG_PRINT("INT "); return INT;
				}
<normal>"Cheat"	{
					#ifndef DEBUG
						yylval.x = 0; 
					#endif
					DEBUG_PRINT("INT "); return INT;
				}
<normal>"Honest" {
					#ifndef DEBUG
						yylval.x = 1; 
					#endif
					DEBUG_PRINT("INT "); return INT;
				}
<normal>"false"	{
					#ifndef DEBUG
						yylval.x = 0; 
					#endif
					DEBUG_PRINT("INT "); return INT;
				}
<normal>"true"	{
					#ifndef DEBUG
						yylval.x = 1; 
					#endif
					DEBUG_PRINT("INT "); return INT;
				}


<normal>[a-z_][a-z0-9_]* { 	if(is_commenting)
							{
								DEBUG_PRINT("TEXT "); return *yytext;
							}
							else
							{
								has_var_been_stored = 1;
								stored_var = yytext;
								#ifndef DEBUG
									yylval.i = strdup(yytext);
								#endif
								DEBUG_PRINT("VAR "); return VAR;
							} 
						}


<normal>.	{
		if(is_var_to_print && has_var_been_stored)
		{
			unput(*yytext);
			if(has_seq_been_printed)
			{
				is_var_to_print = 0;
				#ifndef DEBUG
					yylval.i = strdup(stored_var);
				#endif
				DEBUG_PRINT("VAR "); return VAR;
			}
			else
			{
				has_seq_been_printed = 1;
				DEBUG_PRINT("SEQ "); return SEQ;
			}
		}
		return *yytext;
	}




<<EOF>> { 
					if(current_line_indent > 0 || indent_level > 0)
					{
						current_line_indent--;
						indent_level--;
						DEBUG_PRINT("S_END ");
						return S_END;
					}
					return 0;
				}

%%

#ifdef DEBUG

int main (int argc, char **argv)
{
	if (argc > 1) yyin = fopen(argv[1],"r");
	BEGIN normal;
	for (int i = 0; i < 100; ++i)
	{
		yylex();
	}
	puts("");
}


#endif