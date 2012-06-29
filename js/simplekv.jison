%lex
%% /* LEXICAL */

sep                          "(:|:?\s+):?"

%%

#.*                          /* Ignore Comments */
^\s*                         /* Ignore Whitespace At beginning of line */
(?<=^\s*)\w*(?=sep)          return 'KEY';
(?=sep).*$                   return 'VALUE';
sep                          return 'SEP';
<<EOF>>                      return 'EOF';

/lex

%left SEP

%start expressions
%% /* GRAMMAR */

expressions
    : pairs EOF
        {
	    console.log($1);
	    d = {};
	    for (var i = 0; i < $1.length; i++) {
	    	var k = $1[i][0];
		var v = $1[i][1];

		if (d[k] != null)
		   d[k] = (d[k] instanceof Array ? d[k].concat(v) : [d[k], v]);
	    }

	    print(d);
	    return d;
        }
    ;

kvpairs
    : KEY SEP VALUE
        { $$ = [[$1, $3]]; }
    | kvpairs kvpairs
        { $$ = $1.concat($2); }
    ;