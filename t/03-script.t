# make sure that basic2min works correctly
# note that this will only work after adding ../lib to perl's
# include path, like with prove -l
use strict;
use warnings;

use Test::More 0.88 tests => 3;
use Test::LongString;
use Test::XML;
use Data::Section::Simple 'get_data_section';
use FindBin '$Bin';
use Path::Tiny;
use Capture::Tiny 'capture';
use Devel::FindPerl qw(find_perl_interpreter);

my $PERL  = find_perl_interpreter() || die "can't find perl!\n";
$PERL = $^X if $PERL ne $^X;
my $script_path = path( $Bin, qw(.. bin basic2min) )->realpath;
my $include_path = path($Bin, qw(.. lib))->realpath;
my $data_path = path($Bin, qw(corpus basic_sample.tbx));

my ($stdout, $stderr) = capture {
    system(qq{$PERL}, qq{-I"$include_path"},
        qq{$script_path}, qq{$data_path}, 'en', 'fr');
};

ok($? == 0, 'process exited successfully')
  or note $stderr;

my $data = get_data_section();
is_xml($stdout, $data->{xml}, 'correct TBX output');
is_string_nows($stderr, $data->{log}, 'correct log output');

__DATA__
@@ xml
<TBX dialect="TBX-Min">
  <header>
    <id>TBX-Basic Sample File</id>
    <description>This document is a sample TBX-Basic document instance showing various types of
          terminological entries. The entries in this file are for demonstration purposes
          only and do not reflect actual terminology data. Any references to real
          companies are fabricated for demonstration purposes only.
This is a sample TBX-Basic file from the Translation Research Group (tbxconvert.gevterm.net).
        Address any enquiries to akmtrg@gmail.com.</description>
    <languages source="en" target="fr"/>
  </header>
  <body>
    <termEntry id="c5">
      <langSet xml:lang="en">
        <tig>
          <term>e-mail</term>
        </tig>
      </langSet>
      <langSet xml:lang="fr">
        <tig>
          <term>courriel</term>
        </tig>
      </langSet>
    </termEntry>
    <termEntry id="c6">
      <langSet xml:lang="en">
        <tig>
          <term>federated database</term>
          <note>context:Users and applications interface with the federated
              database managed by the federated server. </note>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
      </langSet>
      <langSet xml:lang="fr">
        <tig>
          <term>base de donnees federee</term>
          <note>context:Une base de donnees federee est une base de donnees
              repartie heterogene constituee de donnees federees, et necessite donc
              une architecture qui permet la communication entre les differentes
              sources de donnees. </note>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
      </langSet>
    </termEntry>
    <termEntry id="c7">
      <langSet xml:lang="en">
        <tig>
          <term>progressive lens</term>
          <termStatus>preferred</termStatus>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
        <tig>
          <term>progressive addition lens</term>
          <note>termType:fullForm</note>
          <termStatus>admitted</termStatus>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
        <tig>
          <term>PAL</term>
          <note>termType:acronym</note>
          <termStatus>notRecommended</termStatus>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
        <tig>
          <term>progressive power lens</term>
          <termStatus>admitted</termStatus>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
        <tig>
          <term>graduated lens</term>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
      </langSet>
      <langSet xml:lang="fr">
        <tig>
          <term>lentille progressive</term>
          <note>grammaticalGender:feminine</note>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
      </langSet>
    </termEntry>
    <termEntry id="c1">
      <subjectField>manufacturing</subjectField>
      <langSet xml:lang="en">
        <tig>
          <term>scheduled operation</term>
          <customer>IBM</customer>
          <note>termType:fullForm
grammaticalGender:masculine
geographicalUsage:Canada
termLocation:menuItem
source:IBM
projectSubset:Tivoli Storage Manager</note>
          <termStatus>preferred</termStatus>
          <partOfSpeech>verb</partOfSpeech>
        </tig>
      </langSet>
    </termEntry>
    <termEntry id="c2">
      <subjectField>manufacturing</subjectField>
      <langSet xml:lang="en">
        <tig>
          <term>unscheduled operation</term>
          <customer>SAX Manufacturing</customer>
          <note>termType:fullForm
grammaticalGender:masculine
geographicalUsage:en-US
termLocation:radioButton
context:Unscheduled operations should be recorded in a log.
source:Manufacturing Process Manual V2
projectSubset:Service department
source:Manufacturing Process Manual V2
projectSubset:Service department
2007-07-22
2007-07-23
This is a sample entry with some data categories at the term or
              language level</note>
          <termStatus>admitted</termStatus>
          <partOfSpeech>noun</partOfSpeech>
        </tig>
      </langSet>
    </termEntry>
  </body>
</TBX>

@@ log
element /martif/martifHeader/encodingDesc/p not converted
element /martif/martifHeader/encodingDesc not converted
element /martif/text/body/termEntry[2]/langSet/tig/descrip pasted in note
element /martif/text/body/termEntry[2]/langSet[2]/tig/descrip pasted in note
element /martif/text/body/termEntry[3]/descripGrp/descrip not converted
element /martif/text/body/termEntry[3]/descripGrp/admin not converted
element /martif/text/body/termEntry[3]/descripGrp not converted
element /martif/text/body/termEntry[3]/langSet/tig[2]/termNote[2] pasted in note
element /martif/text/body/termEntry[3]/langSet/tig[3]/termNote[2] pasted in note
element /martif/text/body/termEntry[3]/langSet[2]/tig/termNote[2] pasted in note
element /martif/text/body/termEntry[4]/descripGrp/descrip not converted
element /martif/text/body/termEntry[4]/descripGrp/admin not converted
element /martif/text/body/termEntry[4]/descripGrp not converted
element /martif/text/body/termEntry[4]/transacGrp/transac not converted
element /martif/text/body/termEntry[4]/transacGrp/transacNote not converted
element /martif/text/body/termEntry[4]/transacGrp/date not converted
element /martif/text/body/termEntry[4]/transacGrp[2]/transac not converted
element /martif/text/body/termEntry[4]/transacGrp[2]/transacNote not converted
element /martif/text/body/termEntry[4]/transacGrp[2]/date not converted
element /martif/text/body/termEntry[4]/note not converted
element /martif/text/body/termEntry[4]/ref not converted
element /martif/text/body/termEntry[4]/xref not converted
element /martif/text/body/termEntry[4]/xref[2] not converted
element /martif/text/body/termEntry[4]/langSet/tig/termNote[2] pasted in note
element /martif/text/body/termEntry[4]/langSet/tig/termNote[3] pasted in note
element /martif/text/body/termEntry[4]/langSet/tig/termNote[5] pasted in note
element /martif/text/body/termEntry[4]/langSet/tig/termNote[6] pasted in note
element /martif/text/body/termEntry[4]/langSet/tig/descripGrp/descrip not converted
element /martif/text/body/termEntry[4]/langSet/tig/descripGrp/admin not converted
element /martif/text/body/termEntry[4]/langSet/tig/descripGrp not converted
element /martif/text/body/termEntry[4]/langSet/tig/admin[2] pasted in note
element /martif/text/body/termEntry[4]/langSet/tig/admin[3] pasted in note
element /martif/text/body/termEntry[5]/langSet/descrip not converted
element /martif/text/body/termEntry[5]/langSet/tig/termNote pasted in note
element /martif/text/body/termEntry[5]/langSet/tig/termNote[2] pasted in note
element /martif/text/body/termEntry[5]/langSet/tig/termNote[4] pasted in note
element /martif/text/body/termEntry[5]/langSet/tig/termNote[6] pasted in note
element /martif/text/body/termEntry[5]/langSet/tig/descrip pasted in note
element /martif/text/body/termEntry[5]/langSet/tig/admin[2] pasted in note
element /martif/text/body/termEntry[5]/langSet/tig/admin[3] pasted in note
element /martif/text/body/termEntry[5]/langSet/tig/admin[5] pasted in note
element /martif/text/body/termEntry[5]/langSet/tig/admin[6] pasted in note
element /martif/text/body/termEntry[5]/langSet/tig/transacGrp/transac not converted
element /martif/text/body/termEntry[5]/langSet/tig/transacGrp/transacNote not converted
element /martif/text/body/termEntry[5]/langSet/tig/transacGrp/date pasted in note
element /martif/text/body/termEntry[5]/langSet/tig/transacGrp[2]/transac not converted
element /martif/text/body/termEntry[5]/langSet/tig/transacGrp[2]/transacNote not converted
element /martif/text/body/termEntry[5]/langSet/tig/transacGrp[2]/date pasted in note
element /martif/text/body/termEntry[5]/langSet/tig/ref not converted
element /martif/text/body/termEntry[5]/langSet/tig/xref not converted
element /martif/text/back/refObjectList/refObject/item not converted
element /martif/text/back/refObjectList/refObject/item[2] not converted
element /martif/text/back/refObjectList/refObject/item[3] not converted
element /martif/text/back/refObjectList/refObject not converted
element /martif/text/back/refObjectList/refObject[2]/item not converted
element /martif/text/back/refObjectList/refObject[2]/item[2] not converted
element /martif/text/back/refObjectList/refObject[2]/item[3] not converted
element /martif/text/back/refObjectList/refObject[2] not converted
element /martif/text/back/refObjectList not converted
element /martif/text/back not converted