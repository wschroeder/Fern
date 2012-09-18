package Fern;
use strict;
use warnings;
use Scalar::Util (qw(blessed));
use base qw(Exporter);
our @EXPORT = qw($new $make_custom_tag $make_solo_tag);

use overload
    '""' => sub { return $_[0]->{text} },
    'eq' => sub { return $_[0] . '' eq $_[1] . '' },
    'ne' => sub { return $_[0] . '' ne $_[1] . '' };

our $new = sub {
    my $class = shift;
    my $text = shift;
    my $self = ref($class) ? { %$class } : {text => '', tags => {}};
    if (defined($text)) {
        $self->{text} .= $text;
    }
    return bless($self, __PACKAGE__);
};

our $make_custom_tag = sub {
    my $self = shift;
    my $tag_name = shift;
    my $code_ref = shift;
    $self->{tags}->{$tag_name} = $code_ref;
    return $self;
};

our $make_solo_tag = sub {
    my $self = shift;
    my $tag_name = shift;
    $self->$make_custom_tag($tag_name, sub {
        my $self = shift;
        my $attribute_hash = shift;
        my @content = @_;
        if (!ref($attribute_hash) || ref($attribute_hash) ne 'HASH') {
            if ($attribute_hash) {
                unshift @content, $attribute_hash;
            }
            $attribute_hash = {};
        }

        return $self->$new("<$tag_name" .
               (keys %$attribute_hash ? ' ' . join(' ', map { $_ . '="' . $attribute_hash->{$_} . '"' } keys %$attribute_hash) : '') .
               (@content ? ">" : " />") .
               (@content ? join('', @content) . "</$tag_name>" : ''));
    });
    return $self;
};

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

    return $self->$new("<$name" .
           (keys %$attribute_hash ? ' ' . join(' ', map { $_ . '="' . $attribute_hash->{$_} . '"' } keys %$attribute_hash) : '') .
           ">" .
           (@content ? join('', @content) : '') .
           "</$name>");
}

1;

