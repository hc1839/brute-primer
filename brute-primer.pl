#!/usr/bin/env perl

use strict;
use warnings;
use sort ('stable');

use File::Basename ('dirname');
use File::Spec;

use lib (
   File::Spec->rel2abs('common/base', dirname(__FILE__)),
   File::Spec->rel2abs('common/biology', dirname(__FILE__))
);

use Cwd ('abs_path');
use File::Temp ('tempfile');

use URI::file;
use XML::LibXML (':libxml');
use XML::LibXSLT;

$XML::LibXSLT::USE_LIBXML_DATA_TYPES = 1;

use CmdArg ('parseArgv');

use constant ('TSV_XSL_PATH', File::Spec->rel2abs('common/base/tsv.xsl', dirname(__FILE__)));
use constant ('BRUTE_FORCE_PROBES_CMD_PATH', File::Spec->rel2abs('probe-gen/probe-gen.pl', dirname(__FILE__)));
use constant ('PRIMER_COMBINATIONS_XQ_PATH', File::Spec->rel2abs('primer-combinations.xq', dirname(__FILE__)));

my $stdout;
open($stdout, '>&', STDOUT);

my $stderr;
open($stderr, '>&', STDERR);

my $sequenceName = '';
my $fwdPrimerSearchRegion = [];
my $revPrimerSearchRegion = [];
my $primerLengthRange = [];
my $sequenceFastaPath = '';
my $outputPrimerPairsPath = undef;   # undef indicates standard output.
my $outputFormat = 0;

my $optSpecs = [
   map {
      CmdArg::OptSpec->ctor($_->[0], $_->[1], $_->[2], $_->[3])
   } (
      [
         ['-entry'],
         CmdArg::SetString->ctor(\$sequenceName),
         'name',
         "Name of the sequence for which the region is to be searched."
      ],
      [
         ['-fwd-region'],
         CmdArg::String->ctor(
            sub {
               if ($_[0] !~ /\d+\.{2}\d+/) {
                  die($_[0] . ' is not a valid search region');
               }

               # Note the change from one- to zero-based indexes.
               $fwdPrimerSearchRegion = [map {int($_) - 1} split(qr/\.{2}/, $_[0], 2)];
            }
         ),
         'range',
         "Search region for the forward primer, specified as 'start..end' in
         one-based indexes. Forward primers generated will have the same sense
         as the reference sequence. End index must be less than the start index
         specified in the -rev-region option."
      ],
      [
         ['-rev-region'],
         CmdArg::String->ctor(
            sub {
               if ($_[0] !~ /\d+\.{2}\d+/) {
                  die($_[0] . ' is not a valid search region');
               }

               # Note the change from one- to zero-based indexes.
               $revPrimerSearchRegion = [map {int($_) - 1} split(qr/\.{2}/, $_[0], 2)];
            }
         ),
         'range',
         "Search region for the reverse primer, specified as 'start..end' in
         one-based indexes. Reverse primers generated will have the opposite
         sense as the reference sequence. Start index must be greater than the
         end index specified in the -fwd-region option."
      ],
      [
         ['-length-range'],
         CmdArg::String->ctor(
            sub {
               if ($_[0] !~ /\d+\.{2}\d+/) {
                  die($_[0] . ' is not a valid length range');
               }

               $primerLengthRange = [map {int($_)} split(qr/\.{2}/, $_[0], 2)];
            }
         ),
         'range',
         "Range of the primer lengths, specified as 'min..max'."
      ],
      [
         ['-sequence'],
         CmdArg::String->ctor(
            sub {
               $sequenceFastaPath = File::Spec->rel2abs($_[0]);
            }
         ),
         'path',
         "Path to the sequence file in Pearson FASTA format."
      ],
      [
         ['-out'],
         CmdArg::String->ctor(
            sub {
               $outputPrimerPairsPath = File::Spec->rel2abs($_[0]);
            }
         ),
         'path',
         "Output file path. If this option is not specified, then the probe
         candidates are printed to standard output. If specified, then the path
         must not already exist."
      ],
      [
         ['-out-format'],
         CmdArg::SetInteger->ctor(\$outputFormat),
         'type',
         "Output probe candidates in a particular format. <type> can be 0 (XML,
         the default) or 1 (TSV)."
      ]
   )
];

parseArgv(
   ['', @ARGV],
   $optSpecs,
   sub {die('Anonymous arguments are not allowed');},
   "Generate primer candidates that are consistent and unique according to predictions made by thermonucleotideBLAST. " .
      "Options that do not have a default argument are required.",
   ""
);

if ($sequenceName eq '') {
   die('Sequence name is required');
}

if ($sequenceName !~ /\S+/) {
   die('Name of sequence must be composed of non-whitespace characters');
}

if (scalar(@{$fwdPrimerSearchRegion}) == 0) {
   die('Forward primer search region is required');
}

# Caution: Zero- versus one-based indexes.
if (!($fwdPrimerSearchRegion->[0] >= 0 and $fwdPrimerSearchRegion->[1] >= 0)) {
   die('Forward primer search region is one-based');
}

if ($fwdPrimerSearchRegion->[0] > $fwdPrimerSearchRegion->[1]) {
   die('Start is greater than end in the forward primer search region');
}

if (scalar(@{$revPrimerSearchRegion}) == 0) {
   die('Reverse primer search region is required');
}

# Caution: Zero- versus one-based indexes.
if (!($revPrimerSearchRegion->[0] >= 0 and $revPrimerSearchRegion->[1] >= 0)) {
   die('Reverse primer search region is one-based');
}

if ($revPrimerSearchRegion->[0] > $revPrimerSearchRegion->[1]) {
   die('Start is greater than end in the reverse primer search region');
}

if ($fwdPrimerSearchRegion->[1] >= $revPrimerSearchRegion->[0]) {
   die('Start index of the reverse primer search region must be greater than the end index of the forward primer search region.');
}

if (scalar(@{$primerLengthRange}) == 0) {
   die('Primer length range is required');
}

if ($primerLengthRange->[0] <= 0 or $primerLengthRange->[1] <= 0) {
   die('Primer length must be positive');
}

if ($primerLengthRange->[0] > $primerLengthRange->[1]) {
   die('Minimum primer length is greater than maximum probe length');
}

if ($primerLengthRange->[1] > $fwdPrimerSearchRegion->[1] + 1 - $fwdPrimerSearchRegion->[0]) {
   die('Maximum probe length is greater than the forward primer search region');
}

if ($primerLengthRange->[1] > $revPrimerSearchRegion->[1] + 1 - $revPrimerSearchRegion->[0]) {
   die('Maximum probe length is greater than the reverse primer search region');
}

if ($sequenceFastaPath eq '') {
   die('Path to sequence file is required');
}
elsif (!-f $sequenceFastaPath) {
   die($sequenceFastaPath . ' does not exist or is not a file');
}

if (defined($outputPrimerPairsPath) and -e $outputPrimerPairsPath) {
   die($outputPrimerPairsPath . ' exists');
}

if (!($outputFormat == 0 or $outputFormat == 1)) {
   die('Invalid output format type');
}

my $fwdPrimersPath = '';
my $revPrimersPath = '';

close(STDOUT);
close(STDERR);

# Generate primer candidates.
foreach my $tuple ([$fwdPrimerSearchRegion, 'plus', \$fwdPrimersPath], [$revPrimerSearchRegion, 'minus', \$revPrimersPath]) {
   my ($searchRegion, $primerSense, $primersPath_ref) = @{$tuple};

   if ($primerSense eq 'plus') {
      print($stderr 'Generating forward primer candidates...' . "\n");
   }
   else {
      print($stderr 'Generating reverse primer candidates...' . "\n");
   }

   (undef, $$primersPath_ref) = tempfile('SUFFIX' => '.xml', 'OPEN' => 0);
   my $cmd = "perl @{[abs_path(BRUTE_FORCE_PROBES_CMD_PATH)]} -entry ${sequenceName} -region @{[join('..', @{$searchRegion})]} -sense ${primerSense} -length-range @{[join('..', @{$primerLengthRange})]} -sequence ${sequenceFastaPath} -out ${$primersPath_ref} -out-format 0";
   qx($cmd);
}

open(STDOUT, '>&', $stdout);
open(STDERR, '>&', $stderr);

# Combine primer candidates.
print(STDERR 'Combining forward and reverse primer candidates...' . "\n");

my $cmd = "zorba --indent --external-variable fwdPrimersUrl:=@{[URI::file->new_abs($fwdPrimersPath)->as_string()]} --external-variable revPrimersUrl:=@{[URI::file->new_abs($revPrimersPath)->as_string()]} @{[(PRIMER_COMBINATIONS_XQ_PATH)]}";
my $primerXmlString = qx($cmd);

unlink($fwdPrimersPath);
unlink($revPrimersPath);

if (XML::LibXML->load_xml('string' => $primerXmlString)->exists('/*/*')) {
   if ($outputFormat == 0) {
      if (defined($outputPrimerPairsPath)) {
         my $outFh;
         open($outFh, '>', $outputPrimerPairsPath);
         print($outFh $primerXmlString . "\n");
         close($outFh);
      }
      else {
         print(STDOUT $primerXmlString . "\n");
      }
   }
   else {
      # Output as TSV.
      my $sourceDoc = XML::LibXML->load_xml('string' => $primerXmlString);
      my $stylesheet = XML::LibXSLT->new()->parse_stylesheet(
         XML::LibXML->load_xml('location' => TSV_XSL_PATH)
      );

      my $fieldNames = [
         'name',
         'region-start',
         'region-length',
         'fwd-primer-sequence',
         'rev-primer-sequence',
         'melting-temperature-fwd',
         'melting-temperature-rev'
      ];

      map {
         $stylesheet->register_function('urn:local', $_->[0], $_->[1])
      } (
         ['records', sub {return $sourceDoc->findnodes('/*/primer-pair');}],
         ['cells', sub {return $_[0]->[0]->findnodes(join(' | ', @{$fieldNames}));}]
      );

      my $xslTransform = $stylesheet->transform($sourceDoc);

      my $outTsv = '#' . join("\t", @{$fieldNames}) . "\n";
      $outTsv .= $stylesheet->output_as_bytes($xslTransform);

      if (defined($outputPrimerPairsPath)) {
         my $outFh;
         open($outFh, '>', $outputPrimerPairsPath);
         print($outFh $outTsv);
         close($outFh);
      }
      else {
         print(STDOUT $outTsv);
      }
   }

   print(STDERR 'Complete.' . "\n");
}
else {
   print(STDERR 'WARNING: No reasonable primer pairs can be generated.' . "\n");
}
