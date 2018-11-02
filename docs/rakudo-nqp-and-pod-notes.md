# Notes and hints for working with Rakudo NQP and Pod

## Traps for the Perl 6 programmer

+ **DO NOT use '$0' in match results** - The Perl 6 shorthand for a match variable '**$0**' doesn't
  work in NQP. Instead, use **$/[0]** for the zeroeth match. 
  Note the parser will be very confused otherwise and it currently cannot point to the error.
  
  
+ **DO NOT use 'nqp::say'** - The routine '**say**' is an NQP built-in and it does not need
  the '**nqp::**' prefix. You can sometimes get away with using '**nqp::say**' but, when you least
  expect it, the parser will fail without a helpful error message.

+ **DO use 'nqp::die'** - As opposed to '**say**', '**die**' does need to be qualified with '**nqp::**'.
  If used without the '**nqp::**' prefix, you sometimes may get a very unhelpful error message.
  
+ **BE WARNED about '$\<some-match-var>' inside a sub with a '$/' arg** - Use the full syntax for
  a match variable ('**/$<some-match-var**') for more reliable (or at least self-documenting) results.
  
+ **BE WARNED about '$\<a-match-var>' versus '$\<a-match-var>\*\*1'** - The first form will result in a
  scalar object while the '\*\*' form will result in an array.  Either form may be appropriate
  for the situation, but proper handling will vary for each.

+ **BE WARNED about "return if (...)" statements** - Sometimes they  work and sometimes not. But the
  failure message is usually good enough to find the offending code.
  
For example, all these failed:
 
```
return if !nqp::elems(@arr);
return unless nqp::elems(@arr);
```
but this finally worked:

```
if !nqp::elems(@arr) {
    return;
}
```
  
## Pod block text content handling

Text inside pod blocks that are contents rather than markup is comprised of
intermixed text and formatting code characters. Newlines and contiguous
whitespace may or may not be significant depending upon the general block type
(abbreviated, paragraph, delimited, or declarator) or block identifier (e.g.,
code, input, output, defn, comment, or data).

The content as it is parsed in Grammar.nqp is first broken into individual
characters which are then assigned to one of three token groups: regular text, text with
formatting code, and text that is to be unchanged from its input form
(code, input, and output).

The regular text and intermingled formatted text are then divided into two more
categories: text that will form one or more paragraphs and text that is part
of a table.  Ultimately, each paragraph of text should be grouped into the
@contents array of a single Pod::Block::Para, but not all pod handling per S26
has been fully implemented.

Some notable, not-yet-implemented (NYI) features (in order of one dev's TODO list)

1. NYI: %config :numbered aliasing with '#' for paragraph or delimited blocks

2. NYI: pod data blocks

3. NYI: formatting code in defn block terms

4. NYI: formatting code in table cells

5. NYI: pod configuration aliasing

6. NYI: formatting code in declarator blocks

7. NYI: consistent use of the Pod::Block::Para as the leaf parent of all regular text

8. NYI: pod configuration lines

9. NYI: Pod::Ambient class

10. NYI: nested delimited comment blocks

11. NYI: configuration data on continuation lines are not always handled correctly

Anyone wanting to work on any of the NYI items please coordinate on IRC #perl6-dev to
avoid duplicate efforts.  Most of the items are being worked on in a generally logical
order of need and knowledge gained during the process of implementing pod features.

## The <pod_textcontent> token

The token **pod_textcontent** is the match object for regular text and formatted code as
described above. It is the source of the final contents object for regular text containers
except for the table blocks which will be discussed separately. It has a corresponding action
method.

Tracing the pod class building code is tedious and not well documented. Tokens in the grammar
are often made early, along with other objects, and attached to that token's match object's .ast
attribute which is then used later in another object.  The developer who wants to change the called .ast
code in that other object (which may be in the grammar, actions, or src/Perl6/Pod.nqp) has to refer
back to the original make point to see its format before doing any changes--not fun!
There is an ongoing effort to better document the process for later developers.

Following is the start of a table to show the grammar tokens that have action methods.

| Grammar tokens  | Action method? | Pod sub? |
| ---         | ---         | ---     |
| pod_textcontent | yes

## :numbered aliasing

S26 allows for the '#' character (Unicode name **NUMBER SIGN**), as the first word in a block, 
to turn on the **:numbered** %config key; in that case the '#' will be removed from the data.
The user can allow a '#' to be recognized as data by either (1) setting the %config numbered
key to false, typically with the **:!numbered** form, or (2) using the **V** formatting code
around the '#' in the data like this: **V<#>**.

Proper handling of this feature requires changing the block's %config hash after the block data have been
parsed or possibly changing the parsing of the first block data word due to the presence of **:!numbered** in
the %config hash. Another problem is how to handle duplicate or incompatible %config keys and values.

The easiest case to handle is the abbreviated block which cannot have explicit %config data and for
which the :numbered alias is most useful. Examples of the abbreviated blocks most likely to
use this option are the **=item**, **=head**, and **=defn** types.

The '#' turns on the **:numbered** configuration in all these cases:

```
=item # foo bar

=item #
foo bar

=item
#
foo bar
```

Following are examples of situations in other block types that are
not good practice but have to be handled gracefully:

```
=for para :!numbered
# foo bar
```

The **:!numbered** is interpreted to mean accepting the '#' as part of block data.

```
=for para :numbered
# foo bar
```

The '#' means the same as the **:numbered** option: the renderer should number the
paragraph and the two **:numbered** keys (one explict and one implicit) are redundant.