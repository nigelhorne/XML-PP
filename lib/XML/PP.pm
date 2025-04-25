package XML::PP;

use strict;
use warnings;
use File::Spec;
use Cwd 'abs_path';
use Readonly;

our $VERSION = '0.01';

use Exporter 'import';
our @EXPORT_OK = qw(parse_xml_with_dtd_and_namespace);

Readonly my $TAG_NAME => qr/[A-Za-z_][\w.\-:]*/;

sub parse_xml_with_dtd_and_namespace {
    my ($xml, $entities, $base_dir, $visited) = @_;
    $visited ||= {};

    print "Parsing XML with DTD and namespace...\n";

    # Extract DOCTYPE and load external DTDs
    if ($xml =~ /<!DOCTYPE\s+($TAG_NAME)(.*?)>/s) {
        my $doctype = $1;
        my $rest    = $2;
        if ($rest =~ /SYSTEM\s+"([^"]+)"/) {
            my $dtd_path = $1;
            my $dtd_file = File::Spec->rel2abs($dtd_path, $base_dir);
            die "Circular include detected\n" if $visited->{$dtd_file}++;
            open my $fh, '<', $dtd_file or die "Can't open DTD file $dtd_file: $!";
            my $dtd = do { local $/; <$fh> };
            close $fh;
            while ($dtd =~ /<!ENTITY\s+(\w+)\s+"([^"]+)">/g) {
                $entities->{$1} = $2;
            }
        }
    }

    $xml = parse_xml_entities($xml, $entities);

    my ($tag, $tree) = _parse_element_with_namespaces($xml);

    print "Parsed tag: $tag\n";
    print "Parsed tree: " . (defined $tree ? _tree_to_string($tree) : "undefined") . "\n";

    my $wrapped = { $tag => [$tree] };
    $wrapped->{_attrs} = $tree->{_attrs} if $tree->{_attrs};
    return ($tag, $wrapped);
}

sub parse_xml_entities {
    my ($xml, $entities) = @_;
    my %builtin = map { $_ => 1 } qw(lt gt amp quot apos);

    print "Processing entities...\n";
    $xml =~ s/&([\w]+);/
        exists($entities->{$1}) && !$builtin{$1} ? $entities->{$1} : "&$1;"
    /ge;

    return $xml;
}

sub _parse_element_with_namespaces {
    my ($xml) = @_;

    print "Parsing element with namespaces...\n";

    # Clean the XML string by removing XML and DOCTYPE declarations
    $xml =~ s/\A\s*<\?xml.*?\?>\s*//s;
    $xml =~ s/\A\s*<!DOCTYPE.*?>\s*//s;
    $xml =~ s/^\s+|\s+$//g;

    # Match the outermost tag
    return unless $xml =~ m{<($TAG_NAME)\b([^>]*)>(.*?)</\1>}s;
    my ($tag, $attrs_str, $inner) = ($1, $2, $3);
    print "Tag: $tag, Attributes: $attrs_str, Inner content: $inner\n";

    # Parse attributes
    my %attrs;
    while ($attrs_str =~ /([A-Za-z_][\w.\-:]*?)="([^"]*?)"/g) {
        $attrs{$1} = $2;
    }

    my $tree = {};
    $tree->{_attrs} = \%attrs if %attrs;  # Ensure that _attrs is always included

    my $pos = 0;
    while ($inner =~ m{<($TAG_NAME)\b([^>]*)>(.*?)</\1>}sg) {
        my ($child_tag, $child_attrs_str, $child_inner) = ($1, $2, $3);
        print "Child tag: $child_tag, Attributes: $child_attrs_str, Inner content: $child_inner\n";

        # Parse child attributes
        my %child_attrs;
        while ($child_attrs_str =~ /([A-Za-z_][\w.\-:]*?)="([^"]*?)"/g) {
            $child_attrs{$1} = $2;
        }

        my $child = {};
        $child->{_attrs} = \%child_attrs if %child_attrs;
        $child->{_text} = decode_text($child_inner) if $child_inner =~ /\S/;

        # Ensure that all tags, including namespaced, are stored as arrays
        my $child_key = $child_tag;  # Use the full tag name for namespaced elements
        $tree->{$child_key} ||= [];  # Always initialize as an array reference
        push @{ $tree->{$child_key} }, $child;

        $pos = pos($inner);
    }

    # Handle any remaining content
    my $remaining = substr($inner, $pos // 0);
    print "Remaining content: $remaining\n";

    # Handle XInclude
    if ($remaining =~ /<xi:include\s+href="([^"]+)"\s*\/?>/) {
        my $href = $1;
        print "XInclude href: $href\n";
        (my $included_tag = $href) =~ s/\..*?$//;
        $tree->{$included_tag} = [{ _text => "Stub content from $href" }];
    } elsif ($remaining =~ /<!\[CDATA\[(.*?)\]\]>/s) {
        $tree->{_text} = $1;
    } elsif ($remaining =~ /\S/) {
        $tree->{_text} = decode_text($remaining);
    }

    return ($tag, $tree);
}


sub decode_text {
    my ($text) = @_;
    print "Decoding text: $text\n";
    $text =~ s/<!\[CDATA\[(.*?)\]\]>/\$1/g;
    $text =~ s/&lt;/</g;
    $text =~ s/&gt;/>/g;
    $text =~ s/&amp;/&/g;
    $text =~ s/&quot;/"/g;
    $text =~ s/&apos;/'/g;
    $text =~ s/^\s+|\s+$//g;
    return $text;
}

sub _tree_to_string {
    my ($tree) = @_;
    return unless $tree;
    return join(", ", map { "$_=" . (ref $tree->{$_} ? "[" . join(", ", @{$tree->{$_}}) . "]" : $tree->{$_}) } keys %$tree);
}

1;

