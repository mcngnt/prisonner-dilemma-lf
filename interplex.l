%option noyywrap

%{

int current_line_indent = 0;
int indent_level = 0;
bool is_commenting = false

int s_end_to_print = 0;
int uncomment_to_print = 0;

%}

DIG	[0-9]


%s indent
%s normal

%%

<indent>"\t" { current_line_indent++ ;}

<indent>. {
			unput(*yytext);
			if(s_end_to_print)
			{
				return S_END;
			}
			else if(uncomment_to_print)
			{
				return END_COMMENT;
			}
			else if(current_line_indent > indent_level)
			{
				return S_BEGIN;
			}
			BEGIN normal;
			return SEQ;
		  }

<normal>"\n" {
		if(is_commenting)
		{
			is_commenting = false;
			uncomment_to_print++;
		}
		if(current_line_indent < indent_level)
		{
			s_end_to_print += indent_level - current_line_indent;
		}
		indent_level =  current_line_indent;
		current_line_indent = 0;
		BEGIN indent;
	 }

<normal>"#"	{ return START_COMMENT; }

<normal>"true"	{ return TRUE; }
<normal>"false"	{ return FALSE; }
<normal>"==" { return EQUAL; }
<normal>">="	{ return GREATER; }
<normal>"+"	{ return PLUS; }
<normal>"-"	{ return MINUS; }

<normal>"def"	{ return DEF; }
<normal>"="	{ return ASSIGN; }

<normal>"while"	{ return WHILE; }
<normal>"if"	{ return IF; }
<normal>"else"	{ return ELSE; }

<normal>"print"	{ return PRINT; }
<normal>"Random"	{ return RANDOM; }

<normal>"STRATEGY"	{ return STRATEGY; }
<normal>"return"	{ return RETURN; }


<normal>{DIG}+	{ yylval.i = atoi(yytext); return INT; }
<normal>"Cheat"	{ yylval.i = 0; return INT; }
<normal>"Honest"	{ yylval.i = 0; return INT; }


[a-z_][a-z0-9_]* { yylval.i = strdup(yytext); return VAR; }


.	{ return *yytext; }

%%


