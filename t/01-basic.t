# test TBX-Basic conversion

use strict;
use warnings;
use Test::More;
plan tests => 1 + blocks();
use Test::NoWarnings;
use Test::XML;
use Test::Base;
use Convert::TBX::Basic 'basic2min';

sub convert {
    my ($tbx) = @_;
    my $min = basic2min(\$tbx);
    return ${ $min->as_xml };
}
filters {basic => 'convert'};

for my $block (blocks()){
    is_xml($block->basic, $block->min, $block->name)
        or note $block->basic;
}

__DATA__
=== header
--- basic
<martif type="TBX-Basic" xml:lang="en-US">
    <martifHeader>
        <fileDesc>
            <titleStmt>
                <title>Test 1</title>
                <note>Some note about the file title here...</note>
            </titleStmt>
            <sourceDesc>
                <p>Some random description.</p>
            </sourceDesc>
        </fileDesc>
    </martifHeader>
    <text>
        <body>
        </body>
    </text>
</martif>

--- min
<TBX dialect="TBX-Min">
  <header>
    <id>Test 1</id>
    <description>
        Some note about the file title here...
        Some random description.
    </description>
  </header>
  <body/>
</TBX>