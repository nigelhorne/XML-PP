use strict;
use warnings;

use Data::Dumper;
use Test::Most;
use XML::PP;

my $xml = <<'XML';
<note>
    <to>Tove</to>
    <from>Jani</from>
    <heading>Reminder</heading>
    <body>Don't forget me this weekend!</body>
</note>
XML

my $parser = XML::PP->new;
my $tree = $parser->parse($xml);

diag(Data::Dumper->new([$tree])->Dump()) if($ENV{'TEST_VERBOSE'});

ok($tree, 'Parser returned a tree');
is($tree->{name}, 'note', 'Top-level tag is <note>');
is(scalar @{$tree->{children}}, 4, 'note has 4 children');

my ($to, $from, $heading, $body) = @{$tree->{children}};

is($to->{name}, 'to', 'First child is <to>');
is($to->{children}[0]{text}, 'Tove', '<to> contains "Tove"');

is($from->{name}, 'from', 'Second child is <from>');
is($from->{children}[0]{text}, 'Jani', '<from> contains "Jani"');

is($heading->{name}, 'heading', 'Third child is <heading>');
is($heading->{children}[0]{text}, 'Reminder', '<heading> contains "Reminder"');

is($body->{name}, 'body', 'Fourth child is <body>');
is($body->{children}[0]{text}, "Don't forget me this weekend!", '<body> content matches');

done_testing;
