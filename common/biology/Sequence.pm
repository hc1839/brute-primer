#*:
#  sequence-module
#     - "Sequence";
#     isa module;
#  .
#

use strict;
use warnings;
use sort ('stable');


#*:
#  sequence
#     - "Sequence";
#     in-module(sequence-module);
#     isa package;
#     descr:
#        "Functions that manipulate nucleic acid or protein sequences.";
#  .
#
package Sequence;

use Exporter ('import');

our @EXPORT_OK = (
   'extractSeq'
);

#*:
#  sequence.extract-seq
#     - "extractSeq";
#     member-of(public-access, sequence);
#     isa function; isa static;
#     descr:
#        "Extracts a region from a sequence stored in Pearson FASTA file.";
#  .
#  sequence.extract-seq.file-path
#     - "filePath";
#     param-of(1, sequence.extract-seq);
#     type-info: "string";
#     descr:
#        "Path to the sequence file in Pearson FASTA format.";
#  .
#  sequence.extract-seq.seq-name
#     - "seqName";
#     param-of(2, sequence.extract-seq);
#     type-info: "string";
#     descr:
#        "Name of the sequence for which the region is to be extracted. It is
#        the portion of the defline after the angle bracket and before the
#        first space.";
#  .
#  sequence.extract-seq.start
#     - "start";
#     param-of(3, sequence.extract-seq);
#     type-info: "integer";
#     descr:
#        "Zero-based index of the first nucleobase of the region to be
#        extracted.";
#  .
#  sequence.extract-seq.length
#     - "length";
#     param-of(4, sequence.extract-seq);
#     type-info: "integer";
#     descr:
#        "Length of the region to be extracted.";
#  .
#
sub extractSeq {
   my ($filePath, $seqName, $start, $length) = @_;

   $filePath .= '';
   $seqName .= '';
   $start = int($start);
   $length = int($length);

   if (!defined(-f $filePath)) {
      die($filePath . ' does not exist or is not a file');
   }

   if ($seqName eq '' or $seqName =~ /\s/) {
      die('Sequence name cannot be a zero-length string and cannot have spaces');
   }

   if ($start < 0) {
      die('Start index cannot be less than zero');
   }

   if ($length < 1) {
      die('Length of the region cannot be less than one');
   }

   my $fh;
   open($fh, '<', $filePath);

   # Find the sequence with the given name.
   while (my $line = <$fh>) {
      chomp($line);

      if ($line =~ /^\>${seqName}(\s+|$)/) {
         last;
      }
   }

   my $regionSeq = '';

   # Cumulative length of sequence chunks that have been iterated. Each line is
   # one chunk.
   my $cumChunkLength = 0;

   while (my $line = <$fh>) {
      chomp($line);

      if ($line =~ /^\>/) {
         last;
      }

      my $chunkSeq = $line;
      $chunkSeq =~ s/^\s+|\s+$//g;
      $cumChunkLength += length($chunkSeq);

      if ($cumChunkLength > $start and $regionSeq eq '') {
         $regionSeq = substr($chunkSeq, length($chunkSeq) - ($cumChunkLength - $start));
      }
      elsif ($cumChunkLength > $start and $regionSeq ne '') {
         $regionSeq .= $chunkSeq;
      }

      if ($cumChunkLength >= $start + $length) {
         substr($regionSeq, length($regionSeq) - ($cumChunkLength - ($start + $length))) = '';
         close($fh);

         return $regionSeq;
      }
   }

   close($fh);
   die('Region out of range');
}

1;
