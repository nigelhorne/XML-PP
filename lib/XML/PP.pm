package XML::PP;

use strict;
use warnings;

=head1 NAME

XML::PP - A simple XML parser

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

  use XML::PP;

  my $parser = XML::PP->new;
  my $xml = '<note id="1"><to priority="high">Tove</to><from>Jani</from><heading>Reminder</heading><body importance="high">Don\'t forget me this weekend!</body></note>';
  my $tree = $parser->parse($xml);

  print $tree->{name};	# 'note'
  print $tree->{children}[0]->{name};	# 'to'

=head1 DESCRIPTION

For most tasks use L<XML::Simple> or L<XML::LibXML>.
C<XML::PP> exists only for the most lightweight of scenarios where you can't get one of the above modules to install.

C<XML::PP> is a simple, lightweight XML parser written in Perl.
It does not rely on external libraries like C<XML::LibXML> and is suitable for small XML parsing tasks.
This module supports basic XML document parsing, including namespace handling, attributes, and text nodes.

=head1 METHODS

=head2 new

  my $parser = XML::PP->new();

Creates a new XML::PP object.

=cut

# Constructor for creating a new XML::PP object
sub new {
	my ($class, %opts) = @_;
	return bless {
		strict => $opts{strict} // 0,
	}, $class;
}

=head2 parse

	my $tree = $parser->parse($xml_string);

Parses the XML string and returns a tree structure representing the XML content. The returned structure is a hash reference with the following fields:

=over 4

=item * C<name> - The tag name of the node.

=item * C<ns> - The namespace prefix (if any).

=item * C<ns_uri> - The namespace URI (if any).

=item * C<attributes> - A hash reference of attributes.

=item * C<children> - An array reference of child nodes (either text nodes or further elements).

=back

=cut

# Parse the given XML string and return the root node
sub parse {
	my ($self, $xml_string) = @_;

	$xml_string =~ s/^\s+|\s+$//g;
	return $self->_parse_node(\$xml_string, {});
}

=head2 _parse_node

  my $node = $self->_parse_node($xml_ref, $nsmap);

Recursively parses an individual XML node.
This method is used internally by the C<parse> method.
It handles the parsing of tags, attributes, text nodes, and child elements.
It also manages namespaces and handles self-closing tags.

=cut

# Internal method to parse an individual XML node
sub _parse_node {
	my ($self, $xml_ref, $nsmap) = @_;

	# Match the start of a tag (self-closing or regular)
	$$xml_ref =~ s{^\s*<([^\s/>]+)([^>]*)\s*(/?)>}{}s or return;
	my ($raw_tag, $attr_string, $self_close) = ($1, $2 || '', $3);

	# Handle possible trailing slash like <line break="yes"/>
	if ($attr_string =~ s{/\s*$}{}) {
		$self_close = 1;
	}

	my ($ns, $tag) = $raw_tag =~ /^([^:]+):(.+)$/
		? ($1, $2)
		: (undef, $raw_tag);

	my %local_nsmap = (%$nsmap);

	# XMLNS declarations
	while ($attr_string =~ /(\w+)(?::(\w+))?="([^"]*)"/g) {
		my ($k1, $k2, $v) = ($1, $2, $3);
		if ($k1 eq 'xmlns' && !defined $k2) {
			$local_nsmap{''} = $v;
		} elsif ($k1 eq 'xmlns' && defined $k2) {
			$local_nsmap{$k2} = $v;
		}
	}

	my %attributes;
	pos($attr_string) = 0;
	while ($attr_string =~ /(\w+)(?::(\w+))?="([^"]*)"/g) {
		my ($k1, $k2, $v) = ($1, $2, $3);
		next if $k1 eq 'xmlns';
		my $attr_name = defined $k2 ? "$k1:$k2" : $k1;
		$attributes{$attr_name} = $self->_decode_entities($v);
	}

	my $node = {
		name	 => $tag,
		ns		 => $ns,
		ns_uri	 => defined $ns ? $local_nsmap{$ns} : undef,
		attributes => \%attributes,
		children => [],
	};

	# Return immediately if self-closing tag
	return $node if $self_close;

	# Capture text
	if ($$xml_ref =~ s{^([^<]+)}{}s) {
		my $text = $self->_decode_entities($1);
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

# Internal helper to decode XML entities
sub _decode_entities {
	my ($self, $text) = @_;
	return undef unless defined $text;

	# Decode known named entities
	$text =~ s/&lt;/</g;
	$text =~ s/&gt;/>/g;
	$text =~ s/&amp;/&/g;
	$text =~ s/&quot;/"/g;
	$text =~ s/&apos;/'/g;

	# Decode decimal numeric entities
	$text =~ s/&#(\d+);/chr($1)/eg;

	# Decode hex numeric entities
	$text =~ s/&#x([0-9a-fA-F]+);/chr(hex($1))/eg;

	# Strict mode: check for unknown or unescaped &
	if ($self->{strict}) {
		if ($text =~ /&[^;]*;/) {
			die "Unknown or malformed XML entity in strict mode: $text";
		}
		if ($text =~ /&/) {
			die "Unescaped ampersand detected in strict mode: $text";
		}
	}

	return $text;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 SEE ALSO

=over 4

=item * L<XML::LibXML>

=item * L<XML::Simple>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
