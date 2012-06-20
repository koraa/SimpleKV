
# PREAMBLE
###################################################

This File contains the specification of the simplekv format.
The Purpose of the simplekv format is to save a number of key-value pairs.
The simplekv does not provide support for structs, dicts or arrays,
it does however provide the support for multiassignments.

# DEFINITION
###################################################

Organization:

- Each line contains one Key/value pair
- Long lines cannot be escaped
- 

The K/V Pairs:

- The structure of each key value pair is as follows:
    KEY|SEPERATOR|VALUE
- The key must be the first entity in the line (besides whitespaces)
- The key must match those expressions: /^\S*$/ AND /^[^:]*$/
    (This means it can contain any characters besides any whitespace characters and a clolon)
- The Value can contain any characters besides a linebreak (anything that starts a new line)
- The divider is defined as follows:
    - It may contain any number of whitespace (\s) characters (besides a newline)
    - It may contain up to two colons
    - The first character of the seperator is the first character that 
      can not be part of the key (any whitespace or a colon)
    - The colon is used to end-mark the seperator, if it is not the first character used
    - If no colon is used to determine the end, the first character of the value 
      is the first character that can not be part of the seperator (anything but a colon and a whitespace)

Arrays/Multiassignments:

- Simplekv provides support for multiassignments. This is simply reuse of a key.
  In libraries this feature should be implemented as a conversion to an array.

Comments:

- A comment is indicated by a '#' character as the first character (besides whitespace characters) in a line
- In case of a comment the entire line is skipped

As Header:

Simplekv can also be used as a header language, in which case a sequence of 4 empty lines will be used as a seperator.

# EXAMPLES
###################################################

These all express the same:

foo 42
foo:42
foo::42
foo  42
foo    42
foo:   42
foo   :42
foo:  :42
          foo 42

Special cases:
'fuu' ' bar' => fuu     : bar
'fuu' ':bar' => fuu     ::bar
'fuu' ': bar' => fuu    :: bar


Bad things to do (this is basicly not using the colons as start or endmarkers)

fuu :: bar => 'fuu' ': bar'
fuu:: bar  => 'fuu' ': bar'