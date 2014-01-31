# test TBX-Basic conversion

use strict;
use warnings;
use Test::More;
plan tests => 1 + blocks() + blocks('log');
use Test::NoWarnings;
use Test::XML;
use Test::Base;
use Log::Any::Test;
use Log::Any qw($log);
use Convert::TBX::Basic 'basic2min';

sub convert {
    my ($tbx) = @_;
    $log->clear();
    my $min = basic2min(\$tbx);
    return ${ $min->as_xml };
}

# return an array ref of all of the messages
sub get_msgs {
    return [
        map {$_->{message}}
        grep {$_->{category} eq 'Convert::TBX::Basic'}
        @{$log->msgs}
    ];
}

filters {basic => 'convert', log => [qw(lines chomp array)]};

for my $block (blocks()){
    is_xml($block->basic, $block->min, $block->name)
        or note $block->basic;
    if($block->log){
        is_deeply($block->log, get_msgs(), $block->name . '(logs)');
    }
    # my $msgs = get_msgs();
    # local $" = "\n";
    # print "@$msgs";
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
        <encodingDesc>
            <p type="XCSURI">TBXBasicXCSV02.xcs
            </p>
        </encodingDesc>
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

--- log
element /martif/martifHeader/fileDesc/encodingDesc/p not converted
element /martif/martifHeader/fileDesc/encodingDesc not converted
