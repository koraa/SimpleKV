/**
 * Author: Karolin Varner
 * Date 6/20/2012
 * 
 * This File is used to parse and generate the simplekv format described in simplekv.spec.
 * 
 * ************************************************************************************
 * 
 * SimpleKV - The Simple Key-Value format
 * Written in 2012 by Karolin Varner karo@cupdev.net
 * 
 * The Project SimpleKV includes this file and any related content and in particular the software libraries and the SimpleKV specification bundled with this project.
 * This file is part of SimpleKV.
 * 
 * To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to SimpleKV to the public domain worldwide.  is distributed without any warranty.
 * You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

//////////////////////////////////////////////
// CONSTANTS

var PARSE_ALLOWED_PRE      = [' ', '\t', '\n'].map( function(s){return s.charCodeAt(0);} );
var PARSE_SPERATORS_PLAIN  = [' ', '\t'].map( function(s){return s.charCodeAt(0);} );
var PARSE_SPERATOR_MARK    = ':'.charCodeAt(0);
var PARSE_KV_SPERATOR    = '\n'.charCodeAt(0);

//////////////////////////////////////////////
// StringBuffer Class

/**
 * The StringBuffer is used to quickly construct a 
 */
function StringBuffer(buf) {
    if (buf == null)
	this.buffer = [];
    else
	this.buffer = buf;
}
StringBuffer.prototype.append = function append(string){
    this.buffer.push(string);
    return this;
};

StringBuffer.prototype.toString = function toString(){    
    return this.buffer.join('');
}

//////////////////////////////////////////////
// TextRef Class

/**
 * The text ref class is used store a substring as a reference not as itself.
 * This behaivour can be used to minimize the memory footprint of your application.
 * The integrity of the str and ref components cannot be garanteed, use toString to get the string.
 */
function TextRef(text, a, b) {
    this.ref = text;
    this.a   = a;
    this.b   = b;
    this.str = null;
}

TextRef.prototype.toString = function() {
    if (this.str == null) {
	this.str = this.ref.substring(this.a, this.b);
	this.ref = null; // TODO: Is explicit nullification needed?
    }
    return 
};

//////////////////////////////////////////////
// Util

function contains(ar, s) {
    for (var i = 0; i < ar.length; i++)
	if (ar[i] == s)
	    return true;
    return false;
}

//////////////////////////////////////////////
// PARSER

function parse_check_kv(c, cnum) {
    if (c == PARSE_KV_SPERATOR) {
	console.error("Syntax error (did not expect newline) while parsing a simplekv at char ", cnum,
		      "Key: ", curpair[0]);
	return true;
    }
    return false;
}

function parse_check_eot(c, cnum) {
    if (cnum < text.length)
	console.error("Syntax error (did not expect EOT) while parsing a simplekv at char ", cnum,
		      "Key: ", curpair[0]);
	return true;
    }
    return false;
}

function parse(text) {
    /*
     * This function is basicaly a finit-state machine.
     * It has four states:
     *  1. Pre key
     *  2. In key
     *  3. In seperator
     *  4. In Value
     * For every K/V-Pair the machine runs through every state.
     * In the transit from one state to onenother a mark is set (-> curpair).
     * In the transit 4->1 the current markset is being pusht to the output stack (->out).
     * 
     * Finally the out-stack is converted to real strings, the multipledefinitions are squashed to arrays
     * and the entire thing is returned as a string.
     * 
     * In the code
     * - The machine is the 'big' for loop
     * - The states are the little (commented) for loops
     * - The transitions are marked pritty obious
     * - The finalization is on the bottom
     */
    var out = [];

    out:
    for (var cnum = 0,c = null;; cnum++) {
	// [K, V]
	var curpair = [textref(text), textref(text)];

	// BEFORE K/V PAIR
	// - Iterate until key is found
	// - Abort if EOT
	for (; contains(PARSE_ALLOWED_PRE, text.charCodeAt(cnum)); cnum++) {
	    if (cnum < text.length) // Abort if at EOT
		break out;
	}
	
	// FOUND KEY <===================== MARK
	curpair[0].a = cnum;
	    
	// INSIDE KEY
	// - Iterate untill SEP-char (PARSE_SEP_PLAIN or PARSE_SEP_MARK)
	// - Discard line/pair of K/V seperator is found; Print error
	// - Abort if EOT is reached; Print error
	for (cnum++; ! (contains(PARSE_SPERATORS_PLAIN, c) || c == PARSE_SPERATOR_MARK); cnum++, c = text.charCodeAt(cnum)) {
	    if (parse_check_kv(c, cnum))
		continue out;
	    if (parse_check_eot(c, cnum))
		break out;
	}

	// KEY END <===================== MARK
	curpair[0].b = cnum;

	// INSIDE SEPERATOR
	// - Iterate as long as there are PARSE_SEP_PLAIN
	// - End iteration if PARSE_SEP_MARK is found, but ignore it
	// - Discard line/pair of K/V seperator is found; Print error
	// - Abort if EOT is reached; Print error
	for (cnum++; contains(PARSE_SPERATORS_PLAIN, c); cnum++, c = text.charCodeAt(cnum)) {
	    if (parse_check_kv(c, cnum))
		continue out;
	    if (parse_check_eot(c, cnum))
		break out;
	}´
	if (c == PARSE_SEP_MARK)
	    cnum++;


	// VAL BEGIN  <===================== MARK
	curpair[1].a = cnum;

	// INSIDE VALUE
	// - Iterate as long as PARSE_KV_SEP or EOT are reached
	for (cnum++; c != PARSE_KV_SPERATOR && cnum < text.length; cnum++, c = text.charCodeAt(cnum));

	// VAL END  <===================== MARK
	curpair[1].b = cnum;

	// Finalize
	out.push(curpair);
    }

    // Finally // TODO: This appears suboptimal
    var d = new Object();

    for (var i = 0; i < out.length; i++) {
	var k = out[i][0].toString();
	var v = out[i][1].toString();
	
	if (k in d) {
	    if (! (d[k] instanceof Array))
		d[k] = [d[k]];
	    d[k].push(v);
	} else {
	    d[k] = v;
	}
    }

    return d;
}