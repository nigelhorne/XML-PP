use strict;
use warnings;
use Test::More;
use XML::PP qw(parse_xml_with_dtd_and_namespace);
use File::Temp qw(tempfile);

# Test 1: Basic XML with DTD parsing
{
    # Create a temporary DTD file
    my ($dtd_fh, $dtd_filename) = tempfile();
    print $dtd_fh <<'DTD';
<!ELEMENT note (to, from, heading, body)>
<!ELEMENT to (#PCDATA)>
<!ELEMENT from (#PCDATA)>
<!ELEMENT heading (#PCDATA)>
<!ELEMENT body (#PCDATA)>
<!ENTITY name "John Doe">
DTD
    close $dtd_fh;

    # Use the correct file path in the DOCTYPE declaration
    my $xml = <<"XML";
<!DOCTYPE note SYSTEM "$dtd_filename">
<note>
    <to>Tove</to>
    <from>Jani</from>
    <heading>Reminder</heading>
    <body>Don't forget me this weekend!</body>
</note>
XML

    my $entities = {};
    my $base_dir = '.';
    my ($tag, $tree) = parse_xml_with_dtd_and_namespace($xml, $entities, $base_dir);

    is($tag, 'note', 'Root tag is correct');
    is_deeply($tree, {
        _attrs => {},
        to => [{ _text => 'Tove' }],
        from => [{ _text => 'Jani' }],
        heading => [{ _text => 'Reminder' }],
        body => [{ _text => "Don't forget me this weekend!" }],
    }, 'Parsed tree matches expected');

    # Clean up temporary DTD file
    unlink $dtd_filename;
}

# Test 2: XML with namespaces
{
    my $xml = <<'XML';
<root xmlns:ns="http://example.com">
    <ns:child>Some data</ns:child>
</root>
XML

    my $entities = {};
    my $base_dir = '.';
    my ($tag, $tree) = parse_xml_with_dtd_and_namespace($xml, $entities, $base_dir);

    is($tag, 'root', 'Root tag is correct');
    is_deeply($tree->{'ns:child'}[0], { _text => 'Some data' }, 'Namespaced child tag parsed correctly');
}

# Test 3: XInclude with fallback
{
    my $xml = <<'XML';
<root xmlns:xi="http://www.w3.org/2001/XInclude">
    <xi:include href="included.xml" xpointer="xpointer(/root/child)"/>
</root>
XML

    my $entities = {};
    my $base_dir = '.';
    my ($tag, $tree) = parse_xml_with_dtd_and_namespace($xml, $entities, $base_dir);

    is($tag, 'root', 'Root tag is correct');
    ok(exists $tree->{child}, 'XInclude successfully included child');
}

# Test 4: Circular include detection
{
    my $xml = <<'XML';
<root xmlns:xi="http://www.w3.org/2001/XInclude">
    <xi:include href="included.xml"/>
</root>
XML

    my $entities = {};
    my $base_dir = '.';
    eval {
        my ($tag, $tree) = parse_xml_with_dtd_and_namespace($xml, $entities, $base_dir);
    };
    like($@, qr/Circular include detected/, 'Circular include detected');
}

# Test 5: CDATA parsing
{
    my $xml = <<'XML';
<root>
    <![CDATA[Some <data>]]>
</root>
XML

    my $entities = {};
    my $base_dir = '.';
    my ($tag, $tree) = parse_xml_with_dtd_and_namespace($xml, $entities, $base_dir);

    is($tag, 'root', 'Root tag is correct');
    is_deeply($tree->{_text}, 'Some <data>', 'CDATA content parsed correctly');
}

# Test 6: Entity parsing
{
    my $xml = <<'XML';
<root>
    &name;
</root>
XML

    my $entities = { name => 'John Doe' };
    my $base_dir = '.';
    my ($tag, $tree) = parse_xml_with_dtd_and_namespace($xml, $entities, $base_dir);

    is($tag, 'root', 'Root tag is correct');
    is_deeply($tree->{_text}, 'John Doe', 'Entity parsed correctly');
}

# Test 7: Multiple root tags scenario
{
    my $xml = <<'XML';
<root>
    <child>First</child>
</root>
<root>
    <child>Second</child>
</root>
XML

    my $entities = {};
    my $base_dir = '.';
    my ($tag, $tree) = parse_xml_with_dtd_and_namespace($xml, $entities, $base_dir);

    is($tag, 'root', 'Root tag is correct');
    is_deeply($tree->{child}[0]{_text}, 'First', 'First child parsed correctly');
    is_deeply($tree->{child}[1]{_text}, 'Second', 'Second child parsed correctly');
}

done_testing();

