#basic test file

use strict;
use warnings;
use Test::More;
plan tests => 1;
use Test::NoWarnings;
use Convert::TBX::Basic;
use FindBin qw($Bin);
use Path::Tiny;

my $corpus_dir = path($Bin, 'corpus');
my $basic = Convert::TBX::Basic->new();