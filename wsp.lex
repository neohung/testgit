%{
	#include "wsp.tab.h"
%}

%x req cfg

%%
<req>\r\n\r\n					{ BEGIN(0); }
<*>[\r\n\t]+					;
<*>[ ]+							{ return SPACE; }

GET								{ BEGIN(req); return REQ_START; }
<req>(\/[a-zA-Z0-9]*)+			{ return REQ_PATH; }
<req>HTTP\/1\.1					{ return REQ_HTTP_VER; }
<req>[a-zA-Z\-]+:				{ BEGIN(cfg); yytext[yyleng - 1] = 0; yylval.sval = strdup(yytext); return REQ_KEY; }
<cfg>[^\r\n\t ]*				{ BEGIN(req); yylval.sval = strdup(yytext); return REQ_VALUE; }
%%
