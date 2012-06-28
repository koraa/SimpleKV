#
# This file is part of SimpleKV.
#
# To the extent possible under law, the author(s) have dedicated all copyright and related and neighboring rights to SimpleKV to the public domain worldwide.  is distributed without any warranty.
# You should have received a copy of the CC0 Public Domain Dedication along with this software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>.
#

#####################
# Bootstrap

simplekv = require '../simplekv'


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
            
SMALL   = crange 'a','z'
CAPS    = crange 'A','Z'
NUMBERS = crange '0','9'
PUNCT   = ['.',',',':',';' ,'!','?']
SPECIAL = ['"','§','$','%' ,'&','/', \
           '(',')','=','\'','+','*', \
           '~','-','_','…' ,'·','–', \
           '`','~','¸','\\','}','}', \
           '{','|',']','¡' ,'>','<', \
           '«','@']
SPACE   = [' ', '\r', 't']

WORD    = ['-', '_'].concat SMALL, CAPS,  NUMBERS
LINE    = [        ].concat WORD,  PUNCT, SPECIAL, SPACE
ALL     = ['\n'    ].concat LINE

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
rand_str = (len=betw(), chars=ALL) ->
    (rand_ar len, (-> at_rand chars )).join('')


##
# Generate an array filled with the output of the generate fun
##
rand_ar = (len=betw(), gen=rand_str) ->
    gen(i) for i in [0..len]

##
# Generate a random dict
##
rand_dict = (len=betw(), kn=betw(), vn=betw(), kc=WORD, vc=WORD) ->
    d = {}
    for i in [0..len]
        k = rand_str kn, kc
        k = rand_str kn, kc until k not of d
        d[k] = rand_str vn, vc
    d

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
# Datagen

##
# Default infoset for the K/V randomizer 
s_kv_s = [
    [1,0,0],
    [0,1,0],
    [1,0,1],
    [1,1,0],
    [0,1,1],
    [1,1,1]
]
shuffle_kv = (i, k, v, s=s_kv_s) ->
    ##
    # Generates an SimpleKV instruction,
    # based on the args.
    # k, v are Keyand Value
    # s, i are used for lazy generation:
    # The instruction depens on an format tuple,
    # that defines what elements of the seperator are used:
    # MARK, SPACE, MARK2
    # S is the array containing these states, i the intger
    # of the element to use in s.
    # Modulo will be used to keep i in bound
    ##
    [
        # Random stuff before the pair
        rand_str(betw(), simplekv.PARSE_ALLOWED_PRE),
        # The Key
         k,
        # First seperator mark
        simplekv.PARSE_SPERATOR_MARK if s[i % s.length][0],
        # Space between marks
        rand_str(betw(1, 100), simplekv.PARSE_SPERATORS_PLAIN) if s[i % s.length][1],
        # Second mark (cares for amiguity)
        (if s[i % s.length][2]                      \
          || v[0] == simplekv.PARSE_SPERATOR_MARK   \
          || v[0] in simplekv.PARSE_SPERATORS_PLAIN
            simplekv.PARSE_SPERATOR_MARK),
        # The value
        v,
        # EO KV
        simplekv.PARSE_KV_SPERATOR,
        # Random stuff at the end
        rand_str(betw(), simplekv.PARSE_ALLOWED_PRE)
    ].join("")

gen_kv = (d, i=betw()) ->
    [shuffle_kv(i, k, v) for k,v in d].join("")

#####################
# Test

describe "SimpleKV", (->

    # Custom matchers
    beforeEach (->
        @addMatchers
            toBeEmpty: ->
                @message = -> "Expected #{@actual} to be empty"
                @actual.length == 0
            toFitLength: (exp) ->
                @message = -> "Expected #{@actual} to be #{exp} long"
                @actual.length == exp
            toMatchDict: (exp) ->
                @message = -> "Expected #{@actual} to dict-match #{exp}"
                for k,v in @actual
                    return false if exp[k] != v
                true
            toMatchArray: (exp) ->
                @message = -> "Expected #{@actual} to array-match #{exp}"
                return false if exp.length != @actual.length
                for x in [0..(@actual.length -1)]
                    return false if exp[x] != @actual[x]
                true
    )

    describe "Meta", (->
        it "pipe", ->
            a = pipe 2,
                ((x) -> x * 2)
                ((x) -> x + 5)
                ((x) -> x + 1000)
            expect(a).toEqual  2 * 2 + 5 + 1000

        they "to_ar", [
                [22, [22]],
                [[42], [42]],
                [[1,2,3,4,5,"asdf"],
                    [1,2,3,4,5,"asdf"]] ],
            (r) ->
                expect(to_ar r[0]).toMatchArray r[1]


        they "crange", [
                [
                    ['A', 'G', 'X', 'U', '2', '8', 'a', 'b']
                    ['A', 'B', 'C', 'D', 'E', 'F', 'G', \
                     'X', 'W', 'V', 'U',                \
                     '2', '3', '4', '5', '6', '7', '8',
                     'a', 'b']]],
            (r) ->
                expect(crange r[0]).toMatchArray  r[1]


        last = -1
        multi = 0
        they "betw", betw, 32, (x) -> 
            expect(x).toBeSmallerThan 101
            expect(x).toBeGreaterThan -1
            if x != last
                multi++
            last = x
        it "betw-changed", -> excpect(multi).toBeGreaterThan 0

        last = -1
        multi = 0
        they "at_rand", (-> at_rand [10..100]), 32, (x) -> 
            expect(x).toBeSmallerThan 101
            expect(x).toBeGreaterThan -1
            if x != last
                multi++
            last = x
        it "at_rand-changed", -> excpect(multi).toBeGreaterThan 0

        it "rand_str 0", -> expect(rand_ar 5, ["O"]).toBeEqual "OOOOO"
        it "rand_str 2", -> expect(rand_ar 5, ["O", "X"]).toMatch /^(O|X){5}$/    
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

    # TODO: ADD ITERATOR TESTS

    describe "Parse", (->

        it "zero_byte", (->
            o = simplekv.parse ""
            expect(o).toBeEmpty()
        )

        they "empty", (-> rand_str betw(), simplekv.PARSE_ALLOWED_PRE), 16, (->
            o = simplekv.parse ""
            expect(o).toBeEmpty()
        )

        they "single", ((i) -> shuffle_kv i, "foo", "bar"), 12, ((t)->
            expect(simplekv.parse t).toMatchDict {foo: "bar"}
        )

        dgen = ((i)->
            d = rand_dict betw(), betw(), WORD, LINE
            [d, gen_kv(d, i)]
        )
        they "data", dgen, 48, ((t)->
            console.log t[1]
            expect(simplekv.parse t[1]).toMatchDict t[0]
        )
    )
)