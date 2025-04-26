# NAME

XML::PP - A simple XML parser

# VERSION

Version 0.01

# SYNOPSIS

    use XML::PP;

    my $parser = XML::PP->new;
    my $xml = '<note id="1"><to priority="high">Tove</to><from>Jani</from><heading>Reminder</heading><body importance="high">Don\'t forget me this weekend!</body></note>';
    my $tree = $parser->parse($xml);

    print $tree->{name};  # 'note'
    print $tree->{children}[0]->{name};   # 'to'

# DESCRIPTION

You almost certainly do not need this module,
for most tasks use [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple) or [XML::LibXML](https://metacpan.org/pod/XML%3A%3ALibXML).
`XML::PP` exists only for the most lightweight of scenarios where you can't get one of the above modules to install,
for example,
CI/CD machines running Windows that get stuck with [https://stackoverflow.com/questions/11468141/cant-load-c-strawberry-perl-site-lib-auto-xml-libxml-libxml-dll-for-module-x](https://stackoverflow.com/questions/11468141/cant-load-c-strawberry-perl-site-lib-auto-xml-libxml-libxml-dll-for-module-x).

`XML::PP` is a simple, lightweight XML parser written in pure Perl.
It does not rely on external libraries like `XML::LibXML` and is suitable for small XML parsing tasks.
This module supports basic XML document parsing, including namespace handling, attributes, and text nodes.

# METHODS

## new

    my $parser = XML::PP->new();
    my $parser = XML::PP->new(strict => 1);
    my $parser = XML::PP->new(warn_on_error => 1);

Creates a new `XML::PP` object.

- `strict` - If set to true, the parser dies when it encounters unknown entities or unescaped ampersands.
- `warn_on_error` - If true, the parser emits warnings for unknown or malformed XML entities. This is enabled automatically if `strict` is enabled.

## parse

        my $tree = $parser->parse($xml_string);

Parses the XML string and returns a tree structure representing the XML content. The returned structure is a hash reference with the following fields:

- `name` - The tag name of the node.
- `ns` - The namespace prefix (if any).
- `ns_uri` - The namespace URI (if any).
- `attributes` - A hash reference of attributes.
- `children` - An array reference of child nodes (either text nodes or further elements).

## \_parse\_node

    my $node = $self->_parse_node($xml_ref, $nsmap);

Recursively parses an individual XML node.
This method is used internally by the `parse` method.
It handles the parsing of tags, attributes, text nodes, and child elements.
It also manages namespaces and handles self-closing tags.

# AUTHOR

Nigel Horne, `<njh at nigelhorne.com>`

# SEE ALSO

- [XML::LibXML](https://metacpan.org/pod/XML%3A%3ALibXML)
- [XML::Simple](https://metacpan.org/pod/XML%3A%3ASimple)

# SUPPORT

This module is provided as-is without any warranty.

# LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

- Personal single user, single computer use: GPL2
- All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.
