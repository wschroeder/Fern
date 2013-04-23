Fern - XML tree creator using a functional DSL
==============================================================================

SYNOPSIS
------------------------------------------------------------------------------
    // <div random="lala"></div>
    var xml = render_tag(tag('div', {random: 'lala'}));

    // <div class="foo"><div class="bar"><div></div></div></div>
    xml = render_tag(
        tag('div', {class: 'foo'},
            tag('div', {class: 'bar'},
                tag('div'))));

    // <div class="foo" name="foofoo">Test</div>
    xml = render_tag(
        tag('div', ['class', 'foo',
                    'name',  'foofoo'],
            'Test')
    );

    // <bar />
    xml = render_tag(empty_element_tag('bar'));

    // xml eq '<bar />', and @metadata is undef
    var [xml, metadata] = empty_element_tag('bar')();

    // tag() returns a function
    var template = tag('div',
                       tag('span', function () { return [arguments[0]] } ),
                       tag('span', function () { return [arguments[1]] } ));

    // <div><span>Hello</span><span>World</span></div>
    xml = render_tag(template('Hello', 'World'));

    // <div><span>Goodbye</span><span>Cave</span></div>
    xml = render_tag(template('Goodbye', 'Cave'));

    // Custom Template
    function custom_tag (obj, p1, p2) {
        return function () {
            return (
                render_tag(
                    tag('span',
                        'Class (' . obj.class . ') and Param 1 (' . p1 . ') and Param 2 (' . p2 . ')')),
                {data => 5}
            );
        };
    }

    // xml          = <div><span>Class (this-class) and Param 1 (3) and Param 2 (test)</span></div>
    // metadata     = {data => 5}
    [xml, metadata] = tag('div',
                          custom_tag({class: 'this-class'}, 3, 'test'));


DESCRIPTION
------------------------------------------------------------------------------
Fern is a protocol for XML generation using a pure functional approach, where
nested XML tags are equivalent to nested functions.  Any language that
supports first-class functions can implement Fern, and Fern's approach to
generation is extensible.

Since an XML tree is represented in Fern as a function, you can write parts of
your XML in your own functions, use native looping constructs, and so on.


MOTIVATION
------------------------------------------------------------------------------
A typical templating approach is that of creating a string template with
special escape tags and its own language, similar to PHP.  Examples in Perl
include Template::Toolkit and Mason.  The drawback is having to learn another
language, and it is often a language with amazing limitations compared to
general languages.  Some web developers claim that this is okay, that you do
not want a lot of messy logic in the middle of your HTML construction.  I like
to construct web pages as a system of nested components, so I have moved away
from the simplistic template approach.  I have found nothing but difficulty
when trying to modularize my template code in large applications with these
approaches.

I was then strongly attracted to template engines such as Common Lisp's
CL-WHO.  Lisp and other compiling languages make these DSLs fast, but they
have the problem of requiring special symbols to break out or to break back
into the DSL (CL-WHO's symbols: str, fmt, esc, htm).  In interpreted
languages, the special language DSLs tend to be slow and restrictive.  For
example, modules using Perl's Template::Declare do not mix nicely with Moose,
and the only means of abstraction is more templates that you have to register.

Other options basically boil down to string concatenation/replace tricks.

Finally, I have run into only one unpolished templating engine in the Lisp
world that dared to tackle the metadata problem.  What is metadata?  When you
use a particular component, it may require special JavaScript.  Unless you use
that component, you do not need to include the JavaScript.  In a complex
enough dynamic web page, you need a convenient way to communicate requirements
to a root site wrapper, such as JavaScript, additional CSS, meta keywords and
configurations, and page title.

I wanted something elegant, something minimal, something that does not require
me to join a religion, something without the problems above, and something I
can use in my server as well as in JavaScript.  Fern is that vision.


CUSTOM TAGS OR TEMPLATES
------------------------------------------------------------------------------
Fern does not come with a predefined set of known tags; instead, you can use
any tag with any case you want, even those which might break XML standards.

You can create custom templates by writing a function that generates a
function that returns the display string and a list of metadata.  For example:

    // Custom Template
    function custom_tag (obj, p1, p2) {
        return function () {
            return (
                render_tag(
                    tag('span',
                        'Class (' . obj.class . ') and Param 1 (' . p1 . ') and Param 2 (' . p2 . ')')),
                {data => 5}
            );
        };
    }

    // xml          = <div><span>Class (this-class) and Param 1 (3) and Param 2 (test)</span></div>
    // metadata     = {data => 5}
    [xml, metadata] = tag('div',
                          custom_tag({class: 'this-class'}, 3, 'test'));


Because we honored the [xml, metadata1, metadata2, ...] return convention for
our generated function, we can nest our function within other Fern tags.


METADATA
------------------------------------------------------------------------------
When you use a particular component, it may require the inclusion of
additional special JavaScript.  Unless you use that component, you do not need
to include the JavaScript linkage.  In a complex enough dynamic web page, you
need a convenient way to communicate requirements to a root template wrapper,
such as JavaScript links, additional CSS, meta keywords and configurations,
and page title.

Fern leaves it up to you how you want to handle arbitrary metadata, how to
construct your root template wrapper with that information.  However, it will
happily pass along your arbitrary metadata from nested children components to
the toplevel.


FUNCTIONS
------------------------------------------------------------------------------

### tag_function = tag(name, attributes, content1, content2, ...)

  The tag function generates a function (tag_function) that, when called,
  will return [xml].  The attributes dictionary is optional.

      var tag_function = tag('div', 'hello');
      var [xml] = tag_function();
      xml == '<div>hello</div>';


  You may pass parameters to the tag_function call.

      tag_function('foo', 4)


  Here is how to use the passed parameters:

      var tag_function = tag('div',
                             tag('span',
                                 function () { return [arguments[0]] },
                                 ' and ',
                                 function () { return [arguments[1]] }));
      var [xml] = tag_function('foo', 4);
      xml == '<div><span>foo and 4</span></div>';


  One advantage of embedding functions is that we can apply additional
  transformations to the passed-in parameters.  The functions may be custom
  template functions.

#### name
  The name of the tag, case sensitive.

      render_tag(tag('foo')) eq '<foo></foo>'


#### attributes
  An optional dictionary or array of key-value pairs that will be attributes
  of a tag element.  Dictionaries of attributes are closer to how XML is
  intended to work in that attributes may be in any order, but for those times
  you need explicit control over attribute ordering, you can use an array.

      render_tag(tag('foo', { color: 'red', size: 4 }))
      // <foo size="4" color="red"></foo>

      render_tag(tag('foo', [ 'color', 'red', 'size', 4 ]))
      // <foo color="red" size="4"></foo>


#### content1, content2, ...
  An optional array of content that appears between the start and end tags.
  You may pass in strings, numbers, and Fern-style functions.

      render_tag(tag('foo', 4, 5, 'and'))
      // <foo>45and</foo>


#### tag_function
  The function generated by the tag function.  When executed, tag_function
  returns [xml, metadata1, metadata2, ...].  You can use the utility
  render_tag to only return the XML string.

      var [xml, metadata] = tag_function('foo', 4);
      var just_the_xml = render_tag(tag_function, 'foo', 4);


  You may pass parameters to the tag_function call.

      tag_function('foo', 4)


  Here is how to use the passed parameters:

      var tag_function = tag('div',
                             tag('span',
                                 function () { return [arguments[0]] },
                                 ' and ',
                                 function () { return [arguments[1]] }));
      var [xml] = tag_function('foo', 4);
      xml == '<div><span>foo and 4</span></div>';


### tag_function = empty_element_tag(name, attributes, content1, content2, ...)

  The empty_element_tag function is in every way the same as the tag function,
  except when no content is passed in, the resulting XML string is in empty
  element form.

      var tag_function = empty_element_tag('div', 'hello');
      var [xml] = tag_function();
      xml == '<div>hello</div>';

      render_tag(empty_element_tag('div')) == '<div />';
      render_tag(empty_element_tag('div', {id: 'foo'})) == '<div id="foo" />';


### render_tag(tag_function, extra_parameters, ...)

  Returns the XML string from the tag_function.

      var [xml] = tag('div')();
      xml == render_tag(tag('div'));
      xml == '<div></div>';


#### tag_function
  The function generated by the tag function.


#### extra_parameters, ...
  Optional arguments for the tag_function.

      var tag_function = tag('div',
                             tag('span',
                                 function () { return [arguments[0]] },
                                 ' and ',
                                 function () { return [arguments[1]] }));
      var [xml] = tag_function('foo', 4);
      xml == '<div><span>foo and 4</span></div>';


### render_tag_and_metadata(tag_function, extra_parameters, ...)

  Returns the XML string and metadata from the tag_function.

      var [xml, metadata1, metadata2] = render_tag_and_metadata(tag('div'));

      // This returns the same thing.
      tag('div')();


#### tag_function
  The function generated by the tag function.


#### extra_parameters, ...
  Optional arguments for the tag_function.  Note the use of metadata in this
  example:

      var tag_function = tag('div',
                             tag('span',
                                 function () { return [arguments[0], 'apple'] },
                                 ' and ',
                                 function () { return [arguments[1], 'banana'] }));
      var [xml, metadata1, metadata2] = render_tag_and_metadata(tag_function('foo', 4));
      xml == tag_function('foo', 4)[0];
      xml == '<div><span>foo and 4</span></div>';
      metadata1 == 'apple';
      metadata2 == 'banana';


AUTHOR
------------------------------------------------------------------------------
Fern, the design specification and implementation, are creations of William
Schroeder during work at The Genome Institute at Washington University School
of Medicine (Richard K. Wilson, PI).


LICENSE AND COPYRIGHT
------------------------------------------------------------------------------
Copyright (C) 2002-2013 Washington University in St. Louis, MO.

This sofware is licensed under the same terms as Perl.
