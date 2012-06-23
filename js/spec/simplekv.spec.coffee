#
# Author: Michael Varner
# Date 6/22/2012
#
# This File is used to test the SimpleKV JS implementation
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

#####################
# Bootstrap

simplekv = require('../simplekv')

#####################
# Util

##
# Processing pipline
##
pipe = (fl...) ->
    fl.reduce (o, f) -> f(o)

##
# Always returns a list
# Return a single element list for objects
##
to_ar = (x) ->
    if x instanceof Array then x else [x]

##
# Convert a charcode or a list of charcodes to a comma
# seperated list of chars
##
list_ccode = (S) ->
    [ String.fromCharCode(c) for c in to_ar(S)].join(", ")

##
# Segmentate a list
##
seg = (len, li) ->
    pipe li,
        ((l) -> [0...(Math.ceil li.length / len) ].map (
            (x) -> x*len )),
        ((i) -> i.map (
            (x) -> li[x...(Math.min li.length, x+len)] ))
##
# Generate a character range
##
crange = (a...) ->
    pipe a,
        ((as) -> as.map (
            (c) -> c.charCodeAt 0 )),
        ((il) -> seg(2, il)),
        ((rs) -> ([[]].concat rs).reduce (
            (o, r) -> o.concat [r[0]..r[1]] )),
        ((ir) -> ir.map (
            (i) -> String.fromCharCode(i) ))

##
# Generate a random int in a range
##
betw = (a=0, b=100) ->
    Math.floor(a + Math.random() * b)

##
# Select a random array elem
##
at_rand = (l) ->
    l[betw(0, l.length-1)]

##
# Generate a random array
##
rand_str = (len=betw(), chars=crange('a','z','A','Z','0','1')) ->
    (rand_ar len, (-> at_rand chars )).join('')


##
# Generate an array filled with the output of the generate fun
##
rand_ar = (len=betw(), gen=rand_str) ->
    gen(i) for i in [0..len]

#####################
# Test Util

they = (mssg, data, arg...) ->
    if data instanceof Function
        [n, fun] = arg
        datagen = data
    else if data instanceof Array
        [fun] = arg
        n = data.length
        datagen = ((i) -> data[i])

    for i in [0..n]
        it mssg + " #" + i, (-> fun datagen i )

#####################
# Test

describe "SimpleKV", (->

    # Custom matchers
    beforeEach (->
        @addMatchers
            toBeEmpty: (->
                @message = (-> "Expected #{@actual} to be empty")
                @actual.length == 0
            )
            toFitLength: ((exp) ->
                @message = (-> "Expected #{@actual} to be #{exp} long")
                @actual.length == exp
            )
    )

    describe  "StrBuf", (->
        it "init empty", (->
            b = new simplekv.StrBuf

            expect(b.buf).toBeEmpty()
            expect(b.toString()).toBeEmpty()
        )

        it "init full", (->
            b = new simplekv.StrBuf(["foo", "bar"])

            expect(b.toString()).toEqual "foobar"
        )

        they "fillup", rand_ar, 8, ( (buf) ->
             b = new simplekv.StrBuf
             b.append s for s in buf

             expect(b.toString()).toEqual buf.join ""
        )
    )

    describe "StrRef", (->
        it "init empty", (->
            sr = new simplekv.StrRef

            expect(sr.toString).toThrow()
        )

        they "zerolen", (-> [betw(), rand_str()]), 8, ((I) ->
            console.log I[1]
            sr = new simplekv.StrRef I[1], I[0], I[0]

            expect(do sr.toString).toBeEmpty()
        )

        they "correct", rand_str, 16, ((str) ->
            a = betw 0,   str.length-2
            b = betw a+1, str.length

            sr = new simplekv.StrRef str, a,b

            expect(do sr.toString).not.toBeEmpty()
            expect(do sr.toString).toEqual str.substring a,b
        )

        obounds = ((prefix, vecgen) ->
            they prefix + "out of bounds", rand_str, 4, ((str) ->
                [a,b] = vecgen str

                sr = new simplekv.StrRef str, a,b

                expect(sr.toString).toThrow()
            )
        )

        obounds "L",
                ((s) -> [(betw -100, -1),
                         (betw  0,    s.length)])

        obounds "LL",
                (-> [(betw -200, -101),
                     (betw -100, -1  )])

        obounds "R",
                ((s)-> [(betw 0,          s.length),
                        (betw s.length+1, s.length+100)])

        obounds "RR",
                ((s)-> [(betw s.length+1,   s.length+100),
                        (betw s.length+101, s.length+200)])

        obounds "LR",
                ((s)-> [(betw -100,         -1),
                        (betw s.length+1, s.length+100)])
    )
)