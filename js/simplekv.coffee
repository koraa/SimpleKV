#
# Author: Michael Varner
# Date 6/20/2012
# 
# This File is used to parse and generate the simplekv format described in simplekv.spec.
# 
################################
# 
# SimpleKV - The Simple Key-Value format
# Written in 2012 by Michael Varner musikmichael@web.de
# 
# The Project SimpleKV includes this file and any related content and in particular the software libraries and the SimpleKV specification bundled with this project.
# This file is part of SimpleKV.
# 
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to SimpleKV to the public domain worldwide.  is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
#

#######################
# CONSTANTS

PARSE_ALLOWED_PRE     = (s.charCodeAt(0) for s in [' ', '\t', '\n'])
PARSE_SPERATORS_PLAIN = (s.charCodeAt(0) for s in [' ', '\t'])
PARSE_SPERATOR_MARK   = ':'.charCodeAt 0
PARSE_KV_SPERATOR     = '\n'.charCodeAt 0

#######################
# Classes

##
# The StrBuf is used to quickly construct a 
##
class StrBuf
    constructor: (@buf=[]) ->
    append: (s) -> @buf.push s
    toString: -> @buf.join ''

##
# The text ref class is used store a substring as a reference not as itself.
# This behaivour can be used to minimize the memory footprint of your application.
# The integrity of the str and ref components cannot be garanteed, use toString to get the string.
##
class StrRef
    constructor: (@ref, @a, @b, @str) ->
    toString: -> @str ?= @ref.substring @a, this.b

##
# The string iterator is used to iterate over a string like a stream
##
class StrIter
    constructor: (@ref, @pt=-1) ->
    cur: -> @cur ?= @ref[@pt]
    next: -> @cur ?= @ref[++@pt]
    pref: -> @cur ?= @ref[--@pt]
    at: (i) -> @ref[i]
    rel_at: (i) -> @at(@pt + i)
    peek_next: -> @rel_at(1)
    peek_prev: -> @rel_at(-1)
    i_cur: -> @cur ?= @ref.charCodeAt @pt
    i_next: -> @cur ?= @ref.charCodeAt ++@pt
    i_pref: -> @cur ?= @ref.charCodeAt --@pt
    i_at: (i) -> @ref.charCodeAt[i]
    i_rel_at: (i) -> @i_at(@pt + i)
    i_peek_next: -> @i_rel_at(1)
    i_peek_prev: -> @i_rel_at(-1)
    eot: -> (do @cur)? && @ref > 0

#######################
# PARSER

parse_check_kv = (buf) -> 
    if (buf.i_cur() == PARSE_KV_SPERATOR)
        console.error("Syntax error (did not expect newline) while parsing a simplekv at char ", buf.ref)
        return true
    else
        return false


parse_check_eot = (buf) ->
    if buf.eot()
        console.error "Syntax error (did not expect EOT) while parsing a simplekv at char ", buf.ref
        return true
    false

parse = (text) ->
    # This function is basicaly a finit-state machine.
    # It has four states:
    #  1. Pre key
    #  2. In key
    #  3. In seperator
    #  4. In Value
    # For every K/V-Pair the machine runs through every state.
    # In the transit from one state to onenother a mark is set (-> curpair).
    # In the transit 4->1 the current markset is being pusht to the output stack (->ret).
    # 
    # Finally the ret-stack is converted to real strings, the multipledefinitions are squashed to arrays
    # and the entire thing is returned as a string.
    # 
    # In the code
    # - The machine is the 'big' for loop
    # - The states are the little (commented) for loops
    # - The transitions are marked pritty obious
    # - The finalization is on the bottom
    ret = []

    buf = new StrIter(text)
    while true
        # INIT
        curpair = [new StrRef text, new StrRef text];

        # BEFORE K/V PAIR
        # - Iterate until key is found
        # - Abort if EOT
        while buf.i_next() in PARSE_ALLOWED_PRE
            abort = buf.eot() # Abort if at EOT
        break if abort
                
        # FOUND KEY <===================== MARK
        curpair[0].a = buf.ref
            
        # INSIDE KEY
        # - Iterate untill SEP-char (PARSE_SEP_PLAIN or PARSE_SEP_MARK)
        # - Discard line/pair of K/V seperator is found; Print error
        # - Abort if EOT is reached; Print error
        until (buf.i_next() in PARSE_SPERATORS_PLAIN || buf.i_cur() == PARSE_SPERATOR_MARK)
            nextl = parse_check_kv buf
            abort = parse_check_eot buf
        break if abort
        continue if nextl

        # KEY END <===================== MARK
        curpair[0].b = buf.ref;

        # INSIDE SEPERATOR
        # - Iterate as long as there are PARSE_SEP_PLAIN
        # - End iteration if PARSE_SEP_MARK is found, but ignore it
        # - Discard line/pair of K/V seperator is found; Print error
        # - Abort if EOT is reached; Print error
        while buf.i_next() in PARSE_SPERATORS_PLAIN
            nextl = parse_check_kv buf
            abort = parse_check_eot buf
        break if abort
        continue if nextl
            
        buf.i_next() if  c == PARSE_SEP_MARK


        # VAL BEGIN  <===================== MARK
        curpair[1].a = buf.ref;

        # INSIDE VALUE
        # - Iterate as long as PARSE_KV_SEP or EOT are reached
        while buf.i_next() != PARSE_KV_SPERATOR and not buf.eot()
            ;

        # VAL END  <===================== MARK
        curpair[1].b = buf.ref;

        # Finalize
        ret.push curpair;

    # Finally # TODO: This appears suboptimal
    for [k, v] in ([key.toString(), value.toString()] for [key, value] in ret)
        if (k in d)
            d[k] = [d[k]] unless d[k] instanceof Array
            d[k].push(v)
        else
            d[k] = v;
