package XML::PP;

use strict;
use warnings;

our $VERSION = '0.03';

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub parse {
    my ($self, $xml) = @_;
    $xml =~ s/^\s+|\s+$//g;
    return _parse_node(\$xml);
}

sub _parse_node {
    my ($xml_ref) = @_;

    # Self-closing tag
    if ($$xml_ref =~ s/^<(\w+)((?:\s+\w+="[^"]*")*)\s*\/>//) {
        my ($tag, $attr_string) = ($1, $2 || '');
        my %attributes;

        while ($attr_string =~ /(\w+)="([^"]*)"/g) {
            $attributes{$1} = $2;
        }

        my $node = {
            name       => $tag,
            attributes => \%attributes,
            children   => [],
        };
        return $node;
    }

    # Standard open/close tag
    if ($$xml_ref =~ s/^<(\w+)((?:\s+\w+="[^"]*")*)>//) {
        my ($tag, $attr_string) = ($1, $2 || '');
        my %attributes;

        while ($attr_string =~ /(\w+)="([^"]*)"/g) {
            $attributes{$1} = $2;
        }

        my @children;
        while (1) {
            if ($$xml_ref =~ s/^<\/$tag>//) {
                last;
            }
            elsif ($$xml_ref =~ /^<\w/) {
                push @children, _parse_node($xml_ref);
            }
            elsif ($$xml_ref =~ s/^([^<]+)//) {
                my $text = $1;
                $text =~ s/^\s+|\s+$//g;
                push @children, { text => $text } if $text ne '';
            }
            else {
                last;
            }
        }

        my $node = {
            name       => $tag,
            attributes => \%attributes,
            children   => \@children,
        };
        return $node;
    }

    return;
}

1;

