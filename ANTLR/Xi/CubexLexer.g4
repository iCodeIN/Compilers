lexer grammar CubexLexer;

TYPE : [A-Z][a-zA-Z0-9_]*; 
NAME : [a-z][a-zA-Z0-9_]*;
WS : [ \t\n\r]+ -> skip;
INT : [-]?([1-9][0-9]*|[0]);
BOOL : 'true' | 'false'; 
// Need to add support for ''
COMMENT : [#].*?[\n\r] -> skip;
STRING : [^\n\r\t]+;
