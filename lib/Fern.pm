package Fern::Tag;
use strict;
use warnings;
use Scalar::Util (qw(blessed));

use overload
    '""' => sub { return $_[0]->{text} },
    'eq' => sub { return $_[0] . '' eq $_[1] . '' },
    'ne' => sub { return $_[0] . '' ne $_[1] . '' };

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    $name =~ s/.*://;   # strip fully-qualified portion

    return if $name eq 'DESTROY';

    if ($self->{tags}->{$name}) {
        return $self->{tags}->{$name}->($self, @_);
    }

    my $attribute_hash = shift;
    my @content = @_;
    if (!ref($attribute_hash) || ref($attribute_hash) ne 'HASH') {
        if ($attribute_hash) {
            unshift @content, $attribute_hash;
        }
        $attribute_hash = {};
    }

    return Fern::new_tag($self, "<$name" .
           (keys %$attribute_hash ? ' ' . join(' ', map { $_ . '="' . $attribute_hash->{$_} . '"' } keys %$attribute_hash) : '') .
           ">" .
           (@content ? join('', @content) : '') .
           "</$name>");
}

package Fern;
use strict;
use warnings;

sub new {
    my ($class, $xml_space) = @_;
    my $new_tag = Fern->new_tag();

    if (defined($xml_space) && $xml_space eq 'xhtml') {
        for my $tag_name (qw(
            br
            hr
            input
        ))
        {
            $class->make_solo_tag($new_tag, $tag_name);
        }
    }

    return $new_tag;
}

sub new_tag {
    my $class = shift;
    my $text = shift;
    my $self = ref($class) ? { %$class } : {text => '', tags => {}};
    if (defined($text)) {
        $self->{text} .= $text;
    }
    return bless($self, 'Fern::Tag');
}

sub make_custom_tag {
    my $class = shift;
    my $tag_obj = shift;
    my $tag_name = shift;
    my $code_ref = shift;
    $tag_obj->{tags}->{$tag_name} = $code_ref;
    return $tag_obj;
}

sub make_solo_tag {
    my $class = shift;
    my $tag_obj = shift;
    my $tag_name = shift;
    Fern->make_custom_tag($tag_obj, $tag_name, sub {
        my $tag_obj = shift;
        my $attribute_hash = shift;
        my @content = @_;
        if (!ref($attribute_hash) || ref($attribute_hash) ne 'HASH') {
            if ($attribute_hash) {
                unshift @content, $attribute_hash;
            }
            $attribute_hash = {};
        }

        return Fern::new_tag($tag_obj, "<$tag_name" .
               (keys %$attribute_hash ? ' ' . join(' ', map { $_ . '="' . $attribute_hash->{$_} . '"' } keys %$attribute_hash) : '') .
               (@content ? ">" : " />") .
               (@content ? join('', @content) . "</$tag_name>" : ''));
    });
    return $tag_obj;
}

1;

