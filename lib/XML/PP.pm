package XML::PP;

use strict;
use warnings;

our $VERSION = '0.01';

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub parse {
    my ($self, $xml) = @_;
    $xml =~ s/^\s+|\s+$//g;  # Trim
    return _parse_node(\$xml);
}

sub _parse_node {
    my ($xml_ref) = @_;

    $$xml_ref =~ s/^<(\w+)>// or return;
    my $tag = $1;
    my @children;

    while (1) {
        if ($$xml_ref =~ s/^<\/$tag>//) {
            last;
        }
        elsif ($$xml_ref =~ /^<\w+>/) {
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

    return {
        name     => $tag,
        children => \@children,
    };
}

1;
