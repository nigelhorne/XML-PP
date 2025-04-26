package XML::PP;
use strict;
use warnings;

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub parse {
    my ($self, $xml_string) = @_;
    $xml_string =~ s/^\s+|\s+$//g;
    return $self->_parse_node(\$xml_string, {});
}

sub _parse_node {
    my ($self, $xml_ref, $nsmap) = @_;

    $$xml_ref =~ s{^\s*<([^\s/>]+)([^>]*)\s*(/?)>}{}s or return;
    my ($raw_tag, $attr_string, $self_close) = ($1, $2 || '', $3);

    my ($ns, $tag) = $raw_tag =~ /^([^:]+):(.+)$/
        ? ($1, $2)
        : (undef, $raw_tag);

    my %local_nsmap = (%$nsmap);

    # First pass: xmlns declarations
    while ($attr_string =~ /(\w+)(?::(\w+))?="([^"]*)"/g) {
        my ($k1, $k2, $v) = ($1, $2, $3);
        if ($k1 eq 'xmlns' && !defined $k2) {
            $local_nsmap{''} = $v;
        } elsif ($k1 eq 'xmlns' && defined $k2) {
            $local_nsmap{$k2} = $v;
        }
    }

    # Second pass: regular attributes
    my %attributes;
    pos($attr_string) = 0;
    while ($attr_string =~ /(\w+)(?::(\w+))?="([^"]*)"/g) {
        my ($k1, $k2, $v) = ($1, $2, $3);
        next if $k1 eq 'xmlns';
        my $attr_name = defined $k2 ? "$k1:$k2" : $k1;
        $attributes{$attr_name} = $v;
    }

    my $node = {
        name       => $tag,
        ns         => $ns,
        ns_uri     => defined $ns ? $local_nsmap{$ns} : undef,
        attributes => \%attributes,
        children   => [],
    };

    # Self-closing tag
    return $node if $self_close;

    # Capture text
    if ($$xml_ref =~ s{^([^<]+)}{}s) {
        my $text = $1;
        $text =~ s/^\s+|\s+$//g;
        push @{ $node->{children} }, { text => $text } if $text ne '';
    }

    # Recursively parse children
    while ($$xml_ref =~ /^\s*<([^\/>"][^>]*)>/) {
        my $child = $self->_parse_node($xml_ref, \%local_nsmap);
        push @{ $node->{children} }, $child if $child;
    }

    # Consume closing tag
    $$xml_ref =~ s{^\s*</(?:\w+:)?$tag\s*>}{}s;

    return $node;
}

1;

