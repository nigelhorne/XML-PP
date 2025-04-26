# NAME

XML::PP - A simple XML parser

# SYNOPSIS

    use XML::PP;
    
    my $parser = XML::PP->new;
    my $xml = '<note id="1"><to priority="high">Tove</to><from>Jani</from><heading>Reminder</heading><body importance="high">Don\'t forget me this weekend!</body></note>';
    my $tree = $parser->parse($xml);
    
    print $tree->{name}; # 'note'
    print $tree->{children}[0]->{name}; # 'to'

# DESCRIPTION

XML::PP is a simple, lightweight XML parser written in Perl. It does not rely on external libraries like \`XML::LibXML\` and is suitable for small XML parsing tasks. This module supports basic XML document parsing, including namespace handling, attributes, and text nodes.

# METHODS

## new

    my $parser = XML::PP->new;

Creates a new XML::PP object.

## parse

    my $tree = $parser->parse($xml_string);

Parses the XML string and returns a tree structure representing the XML content. The returned structure is a hash reference with the following fields:

\- \`name\` - The tag name of the node.
\- \`ns\` - The namespace prefix (if any).
\- \`ns\_uri\` - The namespace URI (if any).
\- \`attributes\` - A hash reference of attributes.
\- \`children\` - An array reference of child nodes (either text nodes or further elements).

# INTERNAL METHODS

## \_parse\_node

    my $node = $self->_parse_node($xml_ref, $nsmap);

Recursively parses an individual XML node. This method is used internally by the \`parse\` method. It handles the parsing of tags, attributes, text nodes, and child elements. It also manages namespaces and handles self-closing tags.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# COPYRIGHT AND LICENSE

This software is licensed under the same terms as Perl itself.
