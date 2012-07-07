 #
 # Author: Karolin Varner
 # Date 6/20/2012
 #
 # This File is used to parse and generate the simplekv format described in simplekv.spec.
 #
 ################################
 #
 # SimpleKV - The Simple Key-Value format
 # Written in 2012 by Karolin Varner karo@cupdev.net
 #
 # The Project SimpleKV includes this file and any related content and in particular the software libraries and the SimpleKV specification bundled with this project.
 # This file is part of SimpleKV.
 #
 # To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to SimpleKV to the public domain worldwide.  is distributed without any warranty.
 # You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
 #

 #######################
 # CONSTANTS

PARSE_ALLOWED_PRE     = [' ', '\t', '\n']
PARSE_SPERATORS_PLAIN = [' ', '\t']
PARSE_SPERATOR_MARK   = ':'
PARSE_KV_SPERATOR     = '\n'
PARSE_COMMENT_CHAR    = '#'

 #######################
 # Functions

split1 = (s, r) ->
    m = s.match r
    return [s] if m == null

    [
        s[...m["index"]],
        s[(m["index"] + m[0].length)...]
    ]

 # Generates an Object with two properties: num und string (n,s)
lnum = (n, s) ->
    d = new Object()
    d.n = n
    d.s = s
    return d

 # Takes a list, returns a 2dimensional list where the left column is the index+1
lnumerize = (l) ->
    (lnum i, l[i-1]) for i in [1..l.length]

 # Extracts all the values from a numerized list
denumerize = (l) ->
    e.s for e in l

 #
 # Filters a list
 # This function is built for tables like from lnumerize
 # 
lnfilter = (l, f) ->
    e for e in l when f(e.s, e.n)

 #
 # Filters a list and prints an error message if one line did not match
 # This function is built for tables like from lnumerize
 # 
 # Arguments:
 #     e - The Error message
 #     l - A table of lines and linenumbers, see =>lnum =>lnumerize
 #     f - The filter function
 #
elnfilter = (l, f, e="No value given", type="Syntax Error") ->
    lnfilter l, (x,n) ->
        return true if f(x,n)
        console.error type, "in line", n, ": ", e

 #
 # Maps the given function on all elements of the given list
 # This function is built for tables like from lnumerize
 # 
lnmap = (l, f) ->
    lnum e.n, f(e.s, e.n) for e in l

7 #######################
 # PARSER

parse = (text) ->
    # PIPELINE:
    # - Split the text at each line
    # - Strip the whitspace at the beginning of lines
    # - Remove empty lines and lines with comments
    # - Split each line into key and value
    # - Filter  all kvpairs without a value
    #
    # This piplene uses the ln* functions to always include the correct linenumbers
    # The first and last statement contain the code to numerize/denumerize the list

    lines     = lnumerize text.split PARSE_KV_SPERATOR
    stripped  = lnmap     lines,     (l) -> l.replace /^\s+/, ""
    nocomment = lnfilter  stripped,  (l) -> l[0] != PARSE_COMMENT_CHAR && l.length > 0
    dsets     = lnmap     nocomment, (l) -> split1 l, /:\s*:?|:?\s*:|\s+/
    kvpairs   = elnfilter dsets,     (p) -> p.length > 1
    kvs       = denumerize kvpairs

    # Warn about empty values
    elnfilter kvpairs, ((p) -> p[1].length > 0),
              "Empty value", "Warning"

    #
    # Put all the key value pairs in a dict. Squash all multiply invoked keys into an array
    r = {}
    for [k,v] in kvs
        curv = r[k]
        
        if  !curv?
            r[k] = v
        else if curv instanceof Array
            curv.push v
        else
            r[k] = [curv, v]
    r

parseheader = (text) ->
    sf = split1 text, /(\n[^\S\n]*){5}/

    header: parse sf[0]
    body: sf[1]

 #########################
 # Export

#ifndef BROWSER
exports.PARSE_ALLOWED_PRE     = PARSE_ALLOWED_PRE
exports.PARSE_SPERATORS_PLAIN = PARSE_SPERATORS_PLAIN
exports.PARSE_SPERATOR_MARK   = PARSE_SPERATOR_MARK
exports.PARSE_KV_SPERATOR     = PARSE_KV_SPERATOR

exports.parse = parse
exports.parseheader = parseheader
#endif