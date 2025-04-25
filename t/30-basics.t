use strict;
use warnings;
use Test::Most;
use XML::PP;

my $xml = <<'XML';
<note id="n1">
    <to priority="high">Tove</to>
    <from>Jani</from>
    <heading>Reminder</heading>
    <body importance="low">Don't forget me this weekend!</body>
</note>
XML

my $parser = XML::PP->new;
my $tree = $parser->parse($xml);

ok($tree, 'Parser returned a tree');
is($tree->{name}, 'note', 'Top-level tag is <note>');
is($tree->{attributes}{id}, 'n1', 'note has id attribute');
is(scalar @{$tree->{children}}, 4, 'note has 4 children');

my ($to, $from, $heading, $body) = @{$tree->{children}};

is($to->{name}, 'to', 'First child is <to>');
is($to->{attributes}{priority}, 'high', '<to> has priority attribute');
is($to->{children}[0]{text}, 'Tove', '<to> contains "Tove"');

is($from->{name}, 'from', 'Second child is <from>');
is($from->{children}[0]{text}, 'Jani', '<from> contains "Jani"');

is($heading->{name}, 'heading', 'Third child is <heading>');
is($heading->{children}[0]{text}, 'Reminder', '<heading> contains "Reminder"');

is($body->{name}, 'body', 'Fourth child is <body>');
is($body->{attributes}{importance}, 'low', '<body> has importance attribute');
is($body->{children}[0]{text}, "Don't forget me this weekend!", '<body> content matches');

my $with_self_closing = <<'XML';
<document>
    <line break="true" />
    <text>Hello</text>
</document>
XML

my $doc = $parser->parse($with_self_closing);
ok($doc, 'Parsed document with self-closing tag');
is($doc->{name}, 'document', 'Root is <document>');
is(scalar @{$doc->{children}}, 2, '<document> has 2 children');

my ($line, $text) = @{$doc->{children}};
is($line->{name}, 'line', 'First child is <line>');
is($line->{attributes}{break}, 'true', '<line> has break attribute');
is(scalar @{$line->{children}}, 0, '<line> has no children');

is($text->{name}, 'text', 'Second child is <text>');
is($text->{children}[0]{text}, 'Hello', '<text> content matches');

done_testing();
