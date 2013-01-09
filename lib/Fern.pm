package Fern;
use strict;
use warnings;
use Scalar::Util (qw(blessed));
use base qw(Exporter);
our @EXPORT = qw(tag empty_element_tag render_tag_atom);

sub _parse_attributes_and_content {
    my $attribute_hash = shift;
    my @content = @_;

    if (!ref($attribute_hash) || ref($attribute_hash) ne 'HASH') {
        if ($attribute_hash) {
            unshift @content, $attribute_hash;
        }
        $attribute_hash = {};
    }

    return ($attribute_hash, @content);
}

sub render_tag_atom {
    my ($atom, @params) = @_;
    return ref($atom) && ref($atom) eq 'CODE' ? $atom->(@params) : $atom;
}

sub _stringify_key_value_pair {
    my ($key, $value, @params) = @_;
    return $key . '="' . render_tag_atom($value, @params) . '"';
}

sub _stringify_attribute_hash {
    my ($attribute_hash, @params) = @_;
    return '' if (!keys %$attribute_hash);
    return ' ' . join(' ', map { _stringify_key_value_pair($_, $attribute_hash->{$_}, @params) } keys %$attribute_hash);
}

sub _stringify_content {
    my ($content, @params) = @_;
    return (@$content ? join('', map {render_tag_atom($_, @params)} @$content) : '');
}

sub empty_element_tag {
    my $tag_name       = shift;
    my ($attribute_hash, @content) = _parse_attributes_and_content(@_);

    return sub {
        my $stringified_content = _stringify_content(\@content, @_);
        if ($stringified_content) {
            "<$tag_name" .  _stringify_attribute_hash($attribute_hash, @_) .  ">$stringified_content</$tag_name>";
        }
        else {
            "<$tag_name" .  _stringify_attribute_hash($attribute_hash, @_) .  " />";
        }
    };
}

sub tag {
    my $tag_name       = shift;
    my ($attribute_hash, @content) = _parse_attributes_and_content(@_);

    return sub {
        "<$tag_name" .  _stringify_attribute_hash($attribute_hash, @_) .  ">" .
        _stringify_content(\@content, @_) .
        "</$tag_name>"
    };
}

1;

