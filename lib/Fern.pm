package Fern;
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(tag empty_element_tag render_tag_atom);

sub _parse_attributes_and_content {
    my $attributes = shift;
    my @content = @_;

    if (!ref($attributes) || (ref($attributes) ne 'HASH' && ref($attributes) ne 'ARRAY')) {
        if ($attributes) {
            unshift @content, $attributes;
        }
        $attributes = {};
    }

    return ($attributes, @content);
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

sub _stringify_attribute_array {
    my ($attribute_array, @params) = @_;
    return '' if !@$attribute_array;
    return ' ' . join(' ', map { _stringify_key_value_pair($attribute_array->[2 * $_], $attribute_array->[2 * $_ + 1], @params) } (0 .. @$attribute_array / 2 - 1));
}

sub _stringify_attributes {
    my ($attributes, @params) = @_;
    if (ref($attributes) eq 'HASH') {
        return _stringify_attribute_hash($attributes, @params);
    }
    else {
        return _stringify_attribute_array($attributes, @params);
    }
}

sub _stringify_content {
    my ($content, @params) = @_;
    return (@$content ? join('', map {render_tag_atom($_, @params)} @$content) : '');
}

sub empty_element_tag {
    my $tag_name       = shift;
    my ($attributes, @content) = _parse_attributes_and_content(@_);

    return sub {
        my $stringified_content = _stringify_content(\@content, @_);
        if ($stringified_content) {
            "<$tag_name" .  _stringify_attributes($attributes, @_) .  ">$stringified_content</$tag_name>";
        }
        else {
            "<$tag_name" .  _stringify_attributes($attributes, @_) .  " />";
        }
    };
}

sub tag {
    my $tag_name       = shift;
    my ($attributes, @content) = _parse_attributes_and_content(@_);

    return sub {
        "<$tag_name" .  _stringify_attributes($attributes, @_) .  ">" .
        _stringify_content(\@content, @_) .
        "</$tag_name>"
    };
}

1;

