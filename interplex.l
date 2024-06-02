%option noyywrap

%{

// TODO :
// SEQ apparait entre if et else
// Double SEQ

// #define DEBUG


#ifdef DEBUG
#define DEBUG_PRINT(token) printf(token);
#else
#define DEBUG_PRINT(token) 
#endif

// #define DEBUG_PRINT(token) printf("%s%d | ",token, *yytext);


// #define DEBUG_PRINT(token) printf("%s",token);


#ifdef DEBUG

#define S_BEGIN 1
#define S_END 2
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
#define LAST 21
#define LESSEQ 22
#define GREATER 23
#define GREATEREQ 24
#define ASSIGNC 25
#define CONSTANTS 26

#endif

int current_line_indent = 0;
int indent_level = 0;


char* stored_var;
int is_var_to_print = 0;
int has_seq_been_printed = 0;
int has_var_been_stored = 0;

int has_else_end_been_printed = 0;

int setting_constants = 0;


%}

DIG	[0-9]


%x normal
%s indent

%%



<indent>"\t" { current_line_indent++ ;}

<indent>"#" {
	unput(*yytext);
	current_line_indent = 0;
	BEGIN normal;
}




<indent>"else" {
	if(has_else_end_been_printed == 0)
	{
		unput('e');unput('s');unput('l');unput('e');
		has_else_end_been_printed = 1;
		indent_level--;
		DEBUG_PRINT("S_END2 "); return S_END;
	}
	else
	{
		has_else_end_been_printed = 0;
		BEGIN normal;
		DEBUG_PRINT("ELSE "); return ELSE;
	}

}



<indent>. {
			unput(*yytext);
			if(current_line_indent < indent_level)
			{
				indent_level--;
				DEBUG_PRINT("S_END1 "); return S_END;
			}
			else if(current_line_indent > indent_level)
			{
				BEGIN normal;
				DEBUG_PRINT("S_BEGIN "); return S_BEGIN;
			}
			else
			{
				BEGIN normal;
				if(*yytext != '#')
				{
					DEBUG_PRINT("SEQ2 "); return SEQ;
				}
			}
		  }


<normal>"\n" {
		indent_level =  current_line_indent;
		current_line_indent = 0;
		BEGIN indent;
	 }

<normal>";" {}

<normal>"#"[^\n]*"\n"	{ unput('\n'); }


<normal>"==" { DEBUG_PRINT("EQUAL "); return EQUAL; }
<normal>"<"	{DEBUG_PRINT("LESS "); return LESS; }
<normal>"<="	{DEBUG_PRINT("LESSEQ "); return LESSEQ; }
<normal>">"	{DEBUG_PRINT("GREATER "); return GREATER; }
<normal>">="	{DEBUG_PRINT("GREATEREQ "); return GREATEREQ; }
<normal>"+"	{ DEBUG_PRINT("PLUS "); return PLUS; }
<normal>"-"	{ DEBUG_PRINT("MINUS "); return MINUS; }

<normal>"def"	{ is_var_to_print = 1; has_seq_been_printed = 0; has_var_been_stored = 0; DEBUG_PRINT("DEF "); return DEF; }
<normal>"="	{ if (setting_constants)
			  {
			  	DEBUG_PRINT("ASSIGNC "); return ASSIGNC;
			  }
			  else
			  {
			  	DEBUG_PRINT("ASSIGN "); return ASSIGN;
			  }

}

<normal>"while"	{ DEBUG_PRINT("WHILE "); return WHILE; }
<normal>"if"	{ DEBUG_PRINT("IF "); return IF; }
<normal>"else"	{ DEBUG_PRINT("ELSE "); return ELSE; }

<normal>"print"	{ DEBUG_PRINT("PRINT "); return PRINT; }
<normal>"Random"	{ DEBUG_PRINT("RANDOM "); return RANDOM; }

<normal>"Strategy"	{ DEBUG_PRINT("STRATEGY "); return STRATEGY; }
<normal>"Constants"	{ setting_constants = 1;DEBUG_PRINT("CONSTANTS "); return CONSTANTS; }
<normal>"return"	{ DEBUG_PRINT("RETURN "); return RETURN; }

<normal>"last"	{ DEBUG_PRINT("LAST "); return LAST; }


<normal>{DIG}+	{
					#ifndef DEBUG
						yylval.x = atoi(yytext); 
					#endif
					DEBUG_PRINT("INT "); return INT;
				}

<normal>"Undef"	{ 
	#ifndef DEBUG
		yylval.x = 2; 
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


<normal>[a-zA-Z_][a-zA-Z0-9_]* { 	
							if(!has_var_been_stored)
							{
								has_var_been_stored = 1;
								stored_var = strdup(yytext);
							}
							#ifndef DEBUG
								yylval.i = strdup(yytext);
							#endif
							DEBUG_PRINT("VAR1 "); return VAR; 
						}


<normal>.	{
		if(is_var_to_print && has_var_been_stored)
		{
			unput(*yytext);
			if(has_seq_been_printed)
			{
				is_var_to_print = 0;
				#ifndef DEBUG
					yylval.i = stored_var;
				#endif
				DEBUG_PRINT("VAR2 "); return VAR;
			}
			else
			{
				has_seq_been_printed = 1;
				DEBUG_PRINT("SEQ1 "); return SEQ;
			}
		}
	}



<<EOF>> { 
			if(current_line_indent > 0 || indent_level > 0)
			{
				current_line_indent--;
				indent_level--;
				DEBUG_PRINT("S_END "); return S_END;
			}
			else
			{
				// DEBUG_PRINT("\n");
				return 0;
			}
		}

%%


void init()
{
    BEGIN normal;
}

#ifdef DEBUG

int main (int argc, char **argv)
{
	init();
	if (argc > 1) yyin = fopen(argv[1],"r");
	for (int i = 0; i < 1000; ++i)
	{
		yylex();
	}
	puts("");
}


#endif