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

    # extract DOCTYPE and load external DTDs
    if ($xml =~ /<!DOCTYPE\s+($TAG_NAME)(.*?)>/s) {
        my $doctype = $1;
        my $rest    = $2;
        if ($rest =~ /SYSTEM\s+"([^"]+)"/) {
            my $dtd_path = $1;
            my $dtd_file = File::Spec->rel2abs($dtd_path, $base_dir);
            die "Circular include detected: $dtd_file\n" if $visited->{$dtd_file}++;
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
    return ($tag, $tree);
}

sub parse_xml_entities {
    my ($xml, $entities) = @_;
    my %builtin = map { $_ => 1 } qw(lt gt amp quot apos);

    $xml =~ s/&([\w]+);/
        exists($entities->{$1}) && !$builtin{$1} ? $entities->{$1} : "&$1;"
    /ge;

    return $xml;
}

sub _parse_element_with_namespaces {
    my ($xml) = @_;

    $xml =~ s/\A\s*<\?xml.*?\?>\s*//s;
    $xml =~ s/\A\s*<!DOCTYPE.*?>\s*//s;
    $xml =~ s/^\s+|\s+\$//g;
    return unless $xml =~ m{<($TAG_NAME)\b([^>]*)>(.*?)</\1>}s;

    my ($tag, $attrs_str, $inner) = ($1, $2, $3);
    my %attrs;
    while ($attrs_str =~ /([A-Za-z_][\w.\-:]*?)="([^"]*?)"/g) {
        $attrs{$1} = $2;
    }

    my $tree = {};
    $tree->{_attrs} = \%attrs if %attrs;

    my $pos = 0;
    while ($inner =~ m{<($TAG_NAME)\b([^>]*)>(.*?)</\1>}sg) {
        my ($child_tag, $child_attrs_str, $child_inner) = ($1, $2, $3);
        my %child_attrs;
        while ($child_attrs_str =~ /([A-Za-z_][\w.\-:]*?)="([^"]*?)"/g) {
            $child_attrs{$1} = $2;
        }
        my $child = {};
        $child->{_attrs} = \%child_attrs if %child_attrs;
        $child->{_text} = decode_text($child_inner) if $child_inner =~ /\S/;
        push @{ $tree->{$child_tag} ||= [] }, $child;

        $pos = pos($inner);
    }

    my $remaining = substr($inner, $pos // 0);

    # Capture remaining text or CDATA
    if ($remaining =~ /<!\[CDATA\[(.*?)\]\]>/s) {
        $tree->{_text} = $1;
    } elsif ($remaining =~ /<xi:include\s+href="([^"]+)"\s*\/?>/) {
        $tree->{'xi:include'} = { href => $1 };
    } elsif ($remaining =~ /\S/) {
        $tree->{_text} = decode_text($remaining);
    }

    return ($tag, $tree);
}

sub decode_text {
    my ($text) = @_;
    $text =~ s/<!\[CDATA\[(.*?)\]\]>/\$1/g;
    $text =~ s/&lt;/</g;
    $text =~ s/&gt;/>/g;
    $text =~ s/&amp;/&/g;
    $text =~ s/&quot;/"/g;
    $text =~ s/&apos;/'/g;
    $text =~ s/^\s+|\s+\$//g;
    return $text;
}

1;
