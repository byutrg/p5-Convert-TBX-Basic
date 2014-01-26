package Convert::TBX::Basic;
use strict;
use warnings;
use XML::Twig;
use autodie;
use Path::Tiny;
use Carp;
use TBX::Min;
use TBX::Min::ConceptEntry;
use TBX::Min::LangGroup;
use TBX::Min::TermGroup;
use Try::Tiny;
use Exporter::Easy (
	OK => ['basic2min']
);

my %status_map = (
    'preferredTerm-admn-sts' => 'preferred',
    'admittedTerm-admn-sts' => 'admitted',
    'deprecatedTerm-admn-sts' => 'notRecommended',
    'supersededTerm-admn-st' => 'obsolete'
);

unless (caller){
    require Data::Dumper;
    print basic2min(@ARGV)->as_xml;

}

# ABSTRACT: Convert TBX-Basic data into TBX-Min
=head1 SYNOPSIS

    use Convert::TBX::Basic 'basic2min';
    print basic2min('/path/to/file.tbx')->as_xml;

=head1 DESCRIPTION

TBX-Basic is a subset of TBX-Default which is meant to contain a
smaller number of data categories suitable for most needs. To some
users, however, TBX-Basic can still be too complicated. This module
allows you to convert TBX-Basic into TBX-Min, a minimal, DCT-style
dialect that stresses human-readability and bare-bones simplicity.

=head2 MODULE STATUS

This is alpha-quality code. Please don't use it for production yet.
It's further development is funded and currently a high priority for
the TBX steering committee and BYU TRG.

=head1 METHODS

=head2 C<basic2min>

Given TBX-Basic input, this method returns a roughly equivalent
TBX::Min object. The input may be either a string
containing a file name or a scalar ref containing the actual TBX-Basic
document as a string.

Obviously TBX-Min allows much less structured information than
TBX-Basic, so the conversion must be somewhat lossy. Data categories
that do not exist in TBX-Min will simply be pasted as a note, prefixed
with the name of the category and a colon. In the future,
this function will provide a report of some kind to indicate which data
is preserved and which is merely pasted as a note.

=cut
sub basic2min {
    my ($data) = @_;

    if(!$data){
        croak 'missing required data argument';
    }

    my $fh = _get_handle($data);

    # build a twig out of the input document
    my $twig = XML::Twig->new(
        # pretty_print    => 'nice', #this seems to affect other created twigs, too
        # output_encoding => 'UTF-8',
        do_not_chain_handlers => 1,
        keep_spaces     => 0,

        # these store new conceptEntries, langGroups and termGroups
        start_tag_handlers => {
            termEntry => \&_conceptStart,
            langSet => \&_langStart,
            tig => \&_termGrpStart,
        },

        TwigHandlers    => {
        	# header attributes
            title => \&_title,
            sourceDesc => \&_source_desc,
            'titleStmt/note' => \&_source_desc,

            # becomes part of the current TBX::Min::ConceptEntry object
            'descrip[@type="subjectField"]' => sub {
                shift->{tbx_min_concepts}->[-1]->subject_field($_->text)
            },

            # these become attributes of the current TBX::Min::TermGroup object
            'termNote[@type="administrativeStatus"]' => \&_status,
            term => sub {shift->{tbx_min_current_term_grp}->term($_->text)},
            'termNote[@type="partOfSpeech"]' => sub {
                shift->{tbx_min_current_term_grp}->part_of_speech($_->text)},
            note => sub {
            	shift->{tbx_min_current_term_grp}->note($_->text)},
            'admin[@type="customerSubset"]' => sub {
                shift->{tbx_min_current_term_grp}->customer($_->text)},

            # the information which cannot be converted faithfully
            # gets added as a note, with its data category prepended
            'tig/admin' => \&_as_note,
            'tig/descrip' => \&_as_note,
            termNote => \&_as_note,
        }
    );

    # use handlers to process individual tags, then grab the result
    $twig->parse($fh);

    my $min = TBX::Min->new();
    my $concepts = $twig->{tbx_min_concepts} || [];
    $min->add_concept($_) for (@$concepts);
    $min->id($twig->{tbx_min_att}{id});
    $min->description($twig->{tbx_min_att}{description});
    $min->source_lang($twig->{tbx_min_att}{source_lang});
    $min->target_lang($twig->{tbx_min_att}{target_lang});
    return $min;
}

sub _get_handle {
    my ($data) = @_;
    my $fh;
    if((ref $data) eq 'SCALAR'){
        open $fh, '<', $data; ## no critic(RequireBriefOpen)
    }else{
        $fh = path($data)->filehandle('<');
    }
    return $fh;
}

######################
### XML TWIG HANDLERS
######################
# all of the twig handlers store state on the XML::Twig object. A bit kludgy,
# but it works.

sub _title {
    my ($twig, $node) = @_;
	$twig->{tbx_min_att}{id} = $node->text;
	return 0;
}

sub _source_desc {
    my ($twig, $node) = @_;
    for my $p($node->children('p')){
	    $twig->{tbx_min_att}{description} .= $node->text . "\n";
    }
    return 0;
}

# remove whitespace and convert to TBX-Min picklist value
sub _status {
	my ($twig, $node) = @_;
	my $status = $node->text;
	$status =~ s/[\s\v]//g;
    $twig->{tbx_min_current_term_grp}->status($status_map{$status});
    return 0;
}

# turn the node info into a note labeled with the type
sub _as_note {
	my ($twig, $node) = @_;
	my $grp = $twig->{tbx_min_current_term_grp};
	my $note = $grp->note() || '';
	$grp->note($note . "\n" .
		$node->att('type') . ':' . $node->text);
	return 1;
}

# add a new concept entry to the list of those found in this file
sub _conceptStart {
    my ($twig, $node) = @_;
    my $concept = TBX::Min::ConceptEntry->new();
    if($node->att('id')){
        $concept->id($node->att('id'));
    }else{
        carp 'found conceptEntry missing id attribute';
    }
    push @{ $twig->{tbx_min_concepts} }, $concept;
    return 1;
}

#just set the subject_field of the current concept
sub _subjectField {
    my ($twig, $node) = @_;
    $twig->{tbx_min_concepts}->[-1]->
        subject_field($node->text);
    return 1;
}

# Create a new LangGroup, add it to the current concept,
# and set it as the current LangGroup.
sub _langStart {
    my ($twig, $node) = @_;
    my $lang = TBX::Min::LangGroup->new();
    if($node->att('xml:lang')){
        $lang->code($node->att('xml:lang'));
    }else{
        carp 'found langGroup missing xml:lang attribute';
    }

    $twig->{tbx_min_concepts}->[-1]->add_lang_group($lang);
    $twig->{tbx_min_current_lang_grp} = $lang;
    return 1;
}

# Create a new termGroup, add it to the current langGroup,
# and set it as the current termGroup.
sub _termGrpStart {
    my ($twig) = @_;
    my $term = TBX::Min::TermGroup->new();
    $twig->{tbx_min_current_lang_grp}->add_term_group($term);
    $twig->{tbx_min_current_term_grp} = $term;
    return 1;
}

1;

=head1 CAVEATS

Currently the output document is invalid because it does not add
source and target languages. In the future, these will probably
have to be provided by the user, or another program which scans
a TBX-Basic file and finds all of the language pairings.

TBX-Basic allows for many more than 2 languages, and TBX-Min only
allows for 2 languages. Converting a TBX-Basic file with multiple
languages requires that multiple TBX-Min files be created, but that's
not currently being done. So for now, only use files with 2 languages.

Currently data not representable in TBX-Min is pasted into a note.
However, this is only done for term-level information. Other level
information is not yet converted.

=head1 TODO

Fix the above caveats.

It would be nice to preserve the C<xml:id> attributes in order
to make the conversion process more tranparent to the user.


