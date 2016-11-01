use strict;
use warnings;
use sort ('stable');

use feature ('state');


package NucleicAcid;

use Exporter ('import');
use File::Basename ('dirname');
use File::Spec;

use XML::LibXML (':libxml');

use constant ('BASE_SYMBOLS_XML_PATH', 'nucleotide-symbols.xml');

our @EXPORT_OK = (
   'nucleobaseComplement',
   'reverseComplementSequence'
);

sub nucleobaseComplement {
   my ($base, $isRna) = @_;

   state $dom = XML::LibXML->load_xml('location' => File::Spec->rel2abs(BASE_SYMBOLS_XML_PATH, dirname(__FILE__)));

   my $domNode;

   my $complement;
   my $isLowercase;
   my %basePartners;

   my $exp;

   if ($base !~ /^\s*$/ and length($base) == 1) {
      $isLowercase = ($base eq uc($base) ? 0 : 1);
   }
   else {
      die('Base must be a one-character, non-whitespace string');
   }

   ## Change to uppercase for querying.
   $base = uc($base);

   if ($base eq 'T' and $isRna) {
      die("First argument is '${_[0]}', but the second argument indicates RNA");
   }

   if ($base eq 'U' and $isRna) {
      ## Change U to T for querying.
      $base = 'T';
   }

   $exp = '/*/variable[@symbol = "<<VAR1>>"]/complement/text()';
   $exp =~ s/\Q<<VAR1>>\E/${base}/g;
   $domNode = [$dom->findnodes($exp)]->[0];

   if (not defined($domNode)) {
      die($_[0] . ' is not a valid nucleobase symbol');
   }

   $complement = $domNode->data();

   if ($complement eq 'T' and $isRna) {
      $complement = 'U';
   }

   if ($isLowercase) {
      $complement = lc($complement);
   }

   return $complement;
}

sub reverseComplementSequence {
   my ($sequence, $isRna) = @_;

   my $complement;

   if (not ($isRna == 0 or $isRna == 1)) {
      die('Second argument must be either 0 or 1');
   }

   $complement = join('', (map {nucleobaseComplement($_, $isRna)} split(qr//, $sequence)));
   $complement = reverse($complement);

   return $complement;
}

1;
