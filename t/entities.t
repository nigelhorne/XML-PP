use strict;
use warnings;
use Test::Most;
use XML::PP;

my $parser = XML::PP->new;

# Basic named and numeric entities
my $xml = <<'XML';
<root title="Tom &amp; Jerry &#39;Cartoon&#39;">
  &lt;hello&gt; &amp; welcome &quot;friend&quot; &apos;pal&apos; &#x41;&#65;
</root>
XML

my $tree = $parser->parse($xml);
is $tree->{name}, 'root', 'Root tag is correct';
is $tree->{attributes}{title}, q{Tom & Jerry 'Cartoon'}, 'Attribute entities decoded (named + numeric)';
is $tree->{children}[0]{text}, q{<hello> & welcome "friend" 'pal' AA}, 'Text entities decoded (named + numeric)';

# Malformed entities (unknown)
my $malformed_entity_xml = '<root title="Tom &unknown;">Bad entity</root>';
my $tree2 = $parser->parse($malformed_entity_xml);
ok defined($tree2), 'Parser did not crash on unknown entity';
is $tree2->{attributes}{title}, 'Tom &unknown;', 'Unknown entity left untouched';

# Unescaped ampersands (technically invalid XML)
my $bad_ampersand_xml = '<root title="Tom & Jerry">Invalid amp</root>';
my $tree3 = $parser->parse($bad_ampersand_xml);
ok defined($tree3), 'Parser did not crash on unescaped ampersand';
is $tree3->{attributes}{title}, 'Tom & Jerry', 'Unescaped ampersand left as-is (permissive)';

done_testing;

