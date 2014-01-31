package Convert::TBX::Basic;
use strict;
use warnings;
use XML::Twig;
use autodie;
use Path::Tiny;
use Carp;
use Log::Any '$log';
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
    print ${ basic2min(@ARGV)->as_xml };
}

# ABSTRACT: Convert TBX-Basic data into TBX-Min
=head1 SYNOPSIS

    use Convert::TBX::Basic 'basic2min';
    # create a TBX-Min document from the TBX-Basic file, using EN
    # as the source language and DE as the target language
    print ${ basic2min('/path/to/file.tbx', 'EN', 'DE')->as_xml };

=head1 DESCRIPTION

TBX-Basic is a subset of TBX-Default which is meant to contain a
smaller number of data categories suitable for most needs. To some
users, however, TBX-Basic can still be too complicated. This module
allows you to convert TBX-Basic into TBX-Min, a minimal, DCT-style
dialect that stresses human-readability and bare-bones simplicity.

=head1 METHODS

=head2 C<basic2min>

Given TBX-Basic input and the source and target languages, this method
returns a L<TBX::Min> object containing a rough equivalent of the
specified data. The source and target languages are necessary because
TBX-Basic can contain many languages, while TBX-Min must contain
exactly 2 languages. The TBX-Basic data may be either a string
containing a file name or a scalar ref containing the actual TBX-Basic
document as a string.

Obviously TBX-Min allows much less structured information than
TBX-Basic, so the conversion must be lossy. C<< <termNote> >>s,
C<< <descrip> >>, and C<< <admins> >>s will be converted if there is a
correspondence with TBX-Min, but those with C<type> attribute values
with no correspondence in TBX-Min will simply be pasted as a note,
prefixed with the name of the category and a colon. This is only
possible for elements at the term level (children of a
C<< <termEntry> >> element) because TBX-Min only allows notes inside of
its C<< <termGrp> >> elements.

As quite a bit of data can be packed into a single C<< <note> >>
element, the result can be quite messy. L<Log::Any> is used to record
1) the elements which are stuffed into a note and 2) the elements that
are skipped altogether during the conversion process, both at the
info level.

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

        # these store new entries, langGroups and termGroups
        start_tag_handlers => {
            termEntry => \&_entry_start,
            langSet => \&_langStart,
            tig => \&_termGrpStart,
        },

        TwigHandlers    => {
        	# header attributes
            title => \&_title,
            sourceDesc => \&_source_desc,
            'titleStmt/note' => \&_title_note,

            # becomes part of the current TBX::Min::ConceptEntry object
            'descrip[@type="subjectField"]' => sub {
                shift->{tbx_min_entries}->[-1]->subject_field($_->text)
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
            'tig//admin' => \&_as_note,
            'tig//descrip' => \&_as_note,
            'tig//transac' => \&_as_note,
            termNote => \&_as_note,

            # add no-op handlers for twig not needing conversion
            'sourceDesc/p' => sub {},
            titleStmt => sub {},
            fileDesc => sub {},
            martifHeader => sub {},
            text => sub {},
            body => sub {},
            martif => sub {},

            # log anything that wasn't converted
            _default_ => \&_log_missed,
        }
    );

    # use handlers to process individual tags, then grab the result
    $twig->parse($fh);

    my $min = TBX::Min->new();
    my $entries = $twig->{tbx_min_entries} || [];
    $min->add_entry($_) for (@$entries);
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

sub _title_note {
    my ($twig, $node) = @_;
    $twig->{tbx_min_att}{description} .= $node->text . "\n";
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
    $log->info('element ' . $node->xpath . ' pasted in note')
        if $log->is_info;
	return 1;
}

# add a new entry to the list of those found in this file
sub _entry_start {
    my ($twig, $node) = @_;
    my $entry = TBX::Min::Entry->new();
    if($node->att('id')){
        $entry->id($node->att('id'));
    }else{
        carp 'found entry missing id attribute';
    }
    push @{ $twig->{tbx_min_entries} }, $entry;
    return 1;
}

#just set the subject_field of the current entry
sub _subjectField {
    my ($twig, $node) = @_;
    $twig->{tbx_min_entries}->[-1]->
        subject_field($node->text);
    return 1;
}

# Create a new LangGroup, add it to the current entry,
# and set it as the current LangGroup.
sub _langStart {
    my ($twig, $node) = @_;
    my $lang = TBX::Min::LangGroup->new();
    if($node->att('xml:lang')){
        $lang->code($node->att('xml:lang'));
    }else{
        carp 'found langGroup missing xml:lang attribute';
    }

    $twig->{tbx_min_entries}->[-1]->add_lang_group($lang);
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

# log that an element was not converted
sub _log_missed {
    my ($twig, $node) = @_;
    $log->info('element ' . $node->xpath . ' not converted')
        if $log->is_info();
    return;
}

# return a string for representing an element, possibly including an id
# and a type attribute value
sub _element_string {
    my ($el) = @_;
    my $name = $el->tag;
    my @qualifier;
    if(my $type = $el->att('type')){
        push @qualifier, $type;
    }
    if(my $id = $el->id || $el->att('id')){
        push @qualifier, $id;
    }
    if(@qualifier){
        return "$name (" . join(';', @qualifier) . ')';
    }
    return $name;
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


