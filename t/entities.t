use strict;
use warnings;
use Test::Most;
use XML::PP;

my $parser = XML::PP->new;

my $xml = <<'XML';
<root title="Tom &amp; Jerry">
  &lt;hello&gt; &amp; welcome &quot;friend&quot; &apos;pal&apos;
</root>
XML

my $tree = $parser->parse($xml);

is $tree->{name}, 'root', 'Root tag is correct';

# Check decoded attribute
is $tree->{attributes}{title}, 'Tom & Jerry', 'Attribute entities decoded';

# Check decoded text node
my $text = $tree->{children}[0]{text};
is $text, '<hello> & welcome "friend" \'pal\'', 'Text entities decoded';

done_testing();
