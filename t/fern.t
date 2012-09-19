use strict;
use warnings;
use Test::Most;
use Fern;

my $t = Fern->$new();

is(defined($t) ? 1 : 0, 1, 'We created the toplevel Fern object');

for my $tag_name (qw(
    br
    hr
    input
))
{
    is($t->$make_solo_tag($tag_name)->$tag_name(), '<' . $tag_name . ' />', $tag_name);
}

for my $tag_name (qw(
    a
    abbr
    acronym
    address
    area
    b
    base
    bdo
    big
    blockquote
    body
    button
    caption
    cite
    code
    col
    colgroup
    dd
    del
    div
    dfn
    dl
    dt
    em
    fieldset
    form
    h1
    h2
    h3
    h4
    h5
    h6
    head
    html
    i
    img
    ins
    kbd
    label
    legend
    li
    link
    map
    meta
    noscript
    object
    ol
    optgroup
    option
    p
    param
    pre
    q
    samp
    script
    select
    small
    span
    strong
    style
    sub
    sup
    table
    tbody
    td
    textarea
    tfoot
    th
    thead
    title
    tr
    tt
    ul
    var
))
{
    is($t->$tag_name(), '<' . $tag_name . '></' . $tag_name . '>', $tag_name);
}

is($t->div('foo')->div('bar'), '<div>foo</div><div>bar</div>', 'Chaining');
is($t->div({random => 'lala'}), '<div random="lala"></div>', 'Attributes');
is($t->div({class => 'foo'}, $t->div({class => 'bar'}, $t->div())), '<div class="foo"><div class="bar"><div></div></div></div>', 'Containment');

my $got =
    $t->div({class => 'modal hide fade imp-error-modal'},
        $t->div({class => 'modal-header'},
            $t->button({type => 'button', class => 'close', 'data-dismiss' => 'modal'}, '×')
              ->h3('A JavaScript error has occurred'))
          ->div({class => 'modal-body'},
            $t->p("Please click the &quot;Open RT&quot; button to open an RT window and submit the error.",
                "Add to the ticket how we can reproduce this error.")
              ->h4('Error Info')
              ->pre('info'))
          ->div({class => 'modal-footer'},
            $t->a({href => '#', class => 'btn', 'data-dismiss' => 'modal'},
                'Ignore')
              ->a({href => '#', class => 'btn btn-primary'},
                'Open RT')))
    ;

my $expected = '<div class="modal hide fade imp-error-modal"><div class="modal-header"><button .*>×</button><h3>A JavaScript error has occurred</h3></div><div class="modal-body"><p>Please click the &quot;Open RT&quot; button to open an RT window and submit the error.Add to the ticket how we can reproduce this error.</p><h4>Error Info</h4><pre>info</pre></div><div class="modal-footer"><a .*>Ignore</a><a .*>Open RT</a></div></div>';

like($got, qr{$expected}, 'Complex example');

is($t->foo(), '<foo></foo>', 'foo tag (not solo)');

$t->$make_solo_tag('bar');
is($t->bar(), '<bar />', 'bar tag (solo)');

$t->$make_custom_tag('template', sub {
    my ($self, $obj, $p1, $p2) = @_;
    return $self->span('Class (' . $obj->{class} . ') and Param 1 (' . $p1 . ') and Param 2 (' . $p2 . ')');
});

is($t->template({class => 'this-class'}, 3, 'test'), '<span>Class (this-class) and Param 1 (3) and Param 2 (test)</span>', 'Custom template');

is($t->div('bar')->template({class => 'foo'}, 'this', 'that')->bar(), '<div>bar</div><span>Class (foo) and Param 1 (this) and Param 2 (that)</span><bar />', 'Custom template plays nicely in chain');

is($t->div(1 == 1 ? $t->div() : $t->span()), '<div><div></div></div>', 'Dynamic tag tree 1');
is($t->div(1 == 0 ? $t->div() : $t->span()), '<div><span></span></div>', 'Dynamic tag tree 2');

is($t->VERSION, '<VERSION></VERSION>', 'special perl name "VERSION" works');

done_testing;

