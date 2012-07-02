/* ****** TOKEN VARIABLES ***** */
%lex

M     :

LFSEP "\n"
KVSEP " "

SPACE [^\S{LFSEP}]

/* ******* TOKENS ************* */
%%

^\s+"#"[^\n]* /* Ignore comments ate the beginning of the line*/
^\s+          /* Ignore space before expressions */


{KVSEP}	               return 'KV_SEP';
{LFSEP}                return 'LF_SEP';

"key"                  return 'KEY';
"value"                return 'VALUE'; 

<<EOF>>                return 'EOF';

/* ******* OPERATOR PRECEDENCE * */
/lex

%left KV_SEP
%left LF_SEP

/* ******* GRAMMAR ************* */
%%

simplekv
    : kvlist EOF
        { 
	    return null;
	    console.log("EOF"); 
            var r = {};
            for (var i = $1.length-1; i >= 0; i--) {
                var k = $1[0], v = $1[1];
                var slot = r[k];

                if (slot == null)
                    r[k] = v;
                else if (slot instanceof Array)
                    slot.push(v);
                else
                    r[k] = [slot, v];
            }
            return r;
        }
    ;


kvlist
    : kvpair EOF
        { console.log("kvlist 1"); $$ = [$1]; }
    | kvpair LF_SEP kvlist
        { console.log("kvlist 2"); $$ = $3.concat($1); }
    ;

kvpair
    : KEY KV_SEP VALUE
        { console.log("kvpair"); $$ = [$1, $3]; }
    ;