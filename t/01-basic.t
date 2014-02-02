# test TBX-Basic conversion

use strict;
use warnings;
use Test::More 0.88;
plan tests => 1 + blocks() + blocks('log');
use Test::NoWarnings;
use Test::XML;
use Test::Base;
filters_delay; # necessary for testing logs
use Log::Any::Test;
use Log::Any qw($log);
use Convert::TBX::Basic 'basic2min';

sub convert {
    my ($tbx) = @_;
    $log->clear();
    my $min = basic2min(\$tbx, 'EN', 'DE');
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
    $log->clear();
    $block->run_filters;
    is_xml($block->basic, $block->min, $block->name);
    if($block->log){
        is_deeply(get_msgs(), $block->log, $block->name . ' (logs)')
            or note explain get_msgs();
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
    <languages source="EN" target="DE"/>
  </header>
  <body/>
</TBX>

=== terms
--- basic
<martif type="TBX-Basic" xml:lang="en-US">
    <martifHeader>
        <fileDesc>
            <sourceDesc>
                <p>Some random description.</p>
            </sourceDesc>
        </fileDesc>
    </martifHeader>
    <text>
        <body>
            <termEntry id="c5">
                <langSet xml:lang="EN">
                    <tig>
                        <term>e-mail</term>
                    </tig>
                </langSet>
                <langSet xml:lang="DE">
                    <tig>
                        <term>email</term>
                    </tig>
                </langSet>
            </termEntry>
        </body>
    </text>
</martif>

--- min
<TBX dialect="TBX-Min">
  <header>
    <description>
        Some random description.
    </description>
    <languages source="EN" target="DE"/>
  </header>
  <body>
    <entry id="c5">
      <langGroup xml:lang="EN">
        <termGroup>
          <term>e-mail</term>
        </termGroup>
      </langGroup>
      <langGroup xml:lang="DE">
        <termGroup>
          <term>email</term>
        </termGroup>
      </langGroup>
    </entry>
  </body>
</TBX>

=== only convert specified language sets
The output should only have the EN entry,
which is specified as the source language.
FR, which was not specified, should be ignored.
--- basic
<martif type="TBX-Basic" xml:lang="en-US">
    <martifHeader>
        <fileDesc>
            <sourceDesc>
                <p>Some random description.</p>
            </sourceDesc>
        </fileDesc>
    </martifHeader>
    <text>
        <body>
            <termEntry id="c5">
                <langSet xml:lang="EN">
                    <tig>
                        <term>e-mail</term>
                    </tig>
                </langSet>
                <langSet xml:lang="FR">
                    <tig>
                        <term>courriel</term>
                    </tig>
                </langSet>
            </termEntry>
        </body>
    </text>
</martif>

--- min
<TBX dialect="TBX-Min">
  <header>
    <description>
        Some random description.
    </description>
    <languages source="EN" target="DE"/>
  </header>
  <body>
    <entry id="c5">
      <langGroup xml:lang="EN">
        <termGroup>
          <term>e-mail</term>
        </termGroup>
      </langGroup>
    </entry>
  </body>
</TBX>

--- log
could not find langSets for language(s): de

=== only convert specified language sets (none found)
--- basic
<martif type="TBX-Basic" xml:lang="en-US">
    <martifHeader>
        <fileDesc>
            <sourceDesc>
                <p>Some random description.</p>
            </sourceDesc>
        </fileDesc>
    </martifHeader>
    <text>
        <body>
            <termEntry id="c5">
                <langSet xml:lang="DQ">
                    <tig>
                        <term>e-mail</term>
                    </tig>
                </langSet>
                <langSet xml:lang="BK">
                    <tig>
                        <term>email</term>
                    </tig>
                </langSet>
            </termEntry>
        </body>
    </text>
</martif>

--- min
<TBX dialect="TBX-Min">
  <header>
    <description>
        Some random description.
    </description>
    <languages source="EN" target="DE"/>
  </header>
  <body>
  </body>
</TBX>

--- log
element /martif/text/body/termEntry not converted
could not find langSets for language(s): de, en
