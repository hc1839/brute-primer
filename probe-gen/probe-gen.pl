#!/usr/bin/env perl

#  Regardless of probe sense, region start is always less than region end.

use strict;
use warnings;
use sort ('stable');

use File::Basename ('dirname');
use File::Spec;

use lib (
   File::Spec->rel2abs('../common/base', dirname(__FILE__)),
   File::Spec->rel2abs('../common/biology', dirname(__FILE__))
);


package BruteForceProbesXsltFn;

use XML::LibXML (':libxml');

our $probeCandidates = [];

sub probeIds {
   return XML::LibXML::NodeList->new(
      map {XML::LibXML::Text->new("$_")} (0..$#{$probeCandidates})
   );
}

sub probeName {
   my $probeId = $_[0]->value();

   return XML::LibXML::Literal->new($probeCandidates->[$probeId]{'name'});
}

sub probeSequence {
   my $probeId = $_[0]->value();

   return XML::LibXML::Literal->new($probeCandidates->[$probeId]{'sequence'});
}

sub probeRegionStart {
   my $probeId = $_[0]->value();

   return XML::LibXML::Number->new($probeCandidates->[$probeId]{'region-start'});
}

sub probeSense {
   my $probeId = $_[0]->value();

   return XML::LibXML::Literal->new($probeCandidates->[$probeId]{'sense'});
}

1;


package TntblastProbeXsltFn;

use XML::LibXML (':libxml');

our $probeRecords = [];

sub probeRecordIds {
   return XML::LibXML::NodeList->new(
      map {XML::LibXML::Text->new("$_")} (0..$#{$probeRecords})
   );
}

sub probeName {
   my $probeRecordId = $_[0]->value();

   return XML::LibXML::Literal->new($probeRecords->[$probeRecordId]{'name'});
}

sub probeRegionStart {
   my $probeRecordId = $_[0]->value();

   return XML::LibXML::Number->new($probeRecords->[$probeRecordId]{'region-start'});
}

sub probeRegionLength {
   my $probeRecordId = $_[0]->value();

   return XML::LibXML::Number->new($probeRecords->[$probeRecordId]{'region-length'});
}

sub probeSense {
   my $probeRecordId = $_[0]->value();

   return XML::LibXML::Literal->new($probeRecords->[$probeRecordId]{'sense'});
}

sub probeMeltingTemperature {
   my $probeRecordId = $_[0]->value();

   return XML::LibXML::Number->new($probeRecords->[$probeRecordId]{'melting-temperature'});
}

1;


package main;

use File::Basename ('dirname');
use File::Spec;
use File::Temp ('tempfile');

use URI::file;
use XML::LibXML (':libxml');
use XML::LibXSLT;

$XML::LibXSLT::USE_LIBXML_DATA_TYPES = 1;

use CmdArg ('parseArgv');
use NucleicAcid('reverseComplementSequence');
use Sequence('extractSeq');
use TntblastParser;

use constant ('TSV_XSL_PATH', File::Spec->rel2abs('../common/base/tsv.xsl', dirname(__FILE__)));
use constant ('BRUTE_FORCE_PROBES_XSL_PATH', File::Spec->rel2abs('probe-gen.xsl', dirname(__FILE__)));
use constant ('TNTBLAST_PROBES_XSL_PATH', File::Spec->rel2abs('tntblast-probes.xsl', dirname(__FILE__)));
use constant ('CONSISTENT_PROBES_XQ_PATH', File::Spec->rel2abs('consistent-probes.xq', dirname(__FILE__)));

my $stdout;
open($stdout, '>&', STDOUT);

my $stderr;
open($stderr, '>&', STDERR);

my $sequenceName = '';
my $probeSearchRegion = [];   # Zero-based start and end indexes as a pair.
my $probeSense = '';   # Sense of probe with respect to the search sequence ('+' or '-').
my $probeLengthRange = [];
my $minProbeMeltTemp = 50.0;
my $sequenceFastaPath = '';
my $outputProbesPath = undef;   # undef indicates standard output.
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
         ['-region'],
         CmdArg::String->ctor(
            sub {
               if ($_[0] !~ /\d+\.{2}\d+/) {
                  die($_[0] . ' is not a valid search region');
               }

               # Note the change from one- to zero-based indexes.
               $probeSearchRegion = [map {int($_) - 1} split(qr/\.{2}/, $_[0], 2)];
            }
         ),
         'range',
         "Search region, specified as 'start..end' in one-based indexes."
      ],
      [
         ['-sense'],
         CmdArg::Symbol->ctor(['plus', 'minus'], sub {$probeSense = ($_[0] eq 'plus' ? '+' : '-');}),
         'strand',
         "Sense of probe ('plus' or 'minus') with respect to the search sequence."
      ],
      [
         ['-length-range'],
         CmdArg::String->ctor(
            sub {
               if ($_[0] !~ /\d+\.{2}\d+/) {
                  die($_[0] . ' is not a valid length range');
               }

               $probeLengthRange = [map {int($_)} split(qr/\.{2}/, $_[0], 2)];
            }
         ),
         'range',
         "Range of the probe lengths, specified as 'min..max'."
      ],
      [
         ['-min-melt-temp'],
         CmdArg::SetReal->ctor(\$minProbeMeltTemp),
         'temp',
         "Default: 50.0. Minimum melting temperature, in Celsius, of the probe candidates."
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
               $outputProbesPath = File::Spec->rel2abs($_[0]);
            }
         ),
         'path',
         "Output file path. If this option is not specified, then the probe candidates are printed to standard output. If specified, then the path must not already exist."
      ],
      [
         ['-out-format'],
         CmdArg::SetInteger->ctor(\$outputFormat),
         'type',
         "Output probe candidates in a particular format. <type> can be 0 (XML, the default) or 1 (TSV)."
      ]
   )
];

parseArgv(
   ['', @ARGV],
   $optSpecs,
   sub {die('Anonymous arguments are not allowed');},
   "Generate probe candidates that are consistent and unique according to predictions made by thermonucleotideBLAST. Options that do not have a default argument are required.",
   ""
);

if ($sequenceName eq '') {
   die('Sequence name is required');
}

if ($sequenceName !~ /\S+/) {
   die('Name of sequence must be composed of non-whitespace characters');
}

if (scalar(@{$probeSearchRegion}) == 0) {
   die('Probe search region is required');
}

# Caution: Zero- versus one-based indexes.
if (!($probeSearchRegion->[0] >= 0 and $probeSearchRegion->[1] >= 0)) {
   die('Probe search region is one-based');
}

if ($probeSearchRegion->[0] > $probeSearchRegion->[1]) {
   die('Start is greater than end');
}

if ($probeSense eq '') {
   die('Probe sense is required');
}

if (scalar(@{$probeLengthRange}) == 0) {
   die('Probe length range is required');
}

if ($probeLengthRange->[0] <= 0 or $probeLengthRange->[1] <= 0) {
   die('Probe length must be positive');
}

if ($probeLengthRange->[0] > $probeLengthRange->[1]) {
   die('Minimum probe length is greater than maximum probe length');
}

if ($probeLengthRange->[1] > $probeSearchRegion->[1] + 1 - $probeSearchRegion->[0]) {
   die('Maximum probe length is greater than the search region');
}

if ($sequenceFastaPath eq '') {
   die('Path to sequence file is required');
}
elsif (!-f $sequenceFastaPath) {
   die($sequenceFastaPath . ' does not exist or is not a file');
}

if (defined($outputProbesPath) and -e $outputProbesPath) {
   die($outputProbesPath . ' exists');
}

if (!($outputFormat == 0 or $outputFormat == 1)) {
   die('Invalid output format type');
}

my $regionSequence = uc(extractSeq($sequenceFastaPath, $sequenceName, $probeSearchRegion->[0], $probeSearchRegion->[1] + 1 - $probeSearchRegion->[0]));

$BruteForceProbesXsltFn::probeCandidates = [];
my $probeCnt = 1;

# Generate probe candidates of varying lengths.
print(STDERR 'Generating probe candidates...' . "\n");

for (my $probeLength = $probeLengthRange->[0]; $probeLength != $probeLengthRange->[1] + 1; ++$probeLength) {
   for (my $probeSequenceStart = 0; $probeSequenceStart != length($regionSequence) - $probeLength + 1; ++$probeSequenceStart) {
      my $probeName = ($probeSense eq '+' ? 'fwd' : 'rev') . '-probe-' . $probeCnt;
      my $probeSequence = substr($regionSequence, $probeSequenceStart, $probeLength);

      if ($probeSense eq '-') {
         $probeSequence = NucleicAcid::reverseComplementSequence($probeSequence, 0);
      }

      push(@{$BruteForceProbesXsltFn::probeCandidates}, {
         'name' => $probeName,
         'sequence' => $probeSequence,
         'region-start' => $probeSequenceStart + $probeSearchRegion->[0] + 1,   # Note the change back to one-based index.
         'sense' => $probeSense
      });

      ++$probeCnt;
   }
}

# Store the probe candidates in XML.
my $sourceDoc = XML::LibXML::Document->new('1.0', 'UTF-8');
my $stylesheet = XML::LibXSLT->new()->parse_stylesheet(
   XML::LibXML->load_xml('location' => BRUTE_FORCE_PROBES_XSL_PATH)
);

map {
   $stylesheet->register_function('urn:local', $_->[0], $_->[1])
} (
   ['probeIds', \&BruteForceProbesXsltFn::probeIds],
   ['probeName', \&BruteForceProbesXsltFn::probeName],
   ['probeSequence', \&BruteForceProbesXsltFn::probeSequence],
   ['probeRegionStart', \&BruteForceProbesXsltFn::probeRegionStart],
   ['probeSense', \&BruteForceProbesXsltFn::probeSense]
);

my $xslTransform = $stylesheet->transform($sourceDoc);

my (undef, $bruteForceProbesPath) = tempfile('SUFFIX' => '.xml', 'OPEN' => 0);
$stylesheet->output_file($xslTransform, $bruteForceProbesPath);

# Transform the probe candidates from XML to TSV as input for tntBLAST.
$sourceDoc = XML::LibXML->load_xml('location' => $bruteForceProbesPath);
$stylesheet = XML::LibXSLT->new()->parse_stylesheet(
   XML::LibXML->load_xml('location' => TSV_XSL_PATH)
);

map {
   $stylesheet->register_function('urn:local', $_->[0], $_->[1])
} (
   ['records', sub {return $sourceDoc->findnodes('/*/probe');}],
   ['cells', sub {return $_[0]->[0]->findnodes('name | sequence');}]
);

$xslTransform = $stylesheet->transform($sourceDoc);

my (undef, $tntblastInputPath) = tempfile('SUFFIX' => '.tsv', 'OPEN' => 0);
$stylesheet->output_file($xslTransform, $tntblastInputPath);

# Run the probe candidates through tntBLAST.
print(STDERR 'Running the probe candidates through thermonucleotideBLAST...' . "\n");

my (undef, $tntblastOutputPath) = tempfile('SUFFIX' => '.txt', 'OPEN' => 0);
my $cmd = "tntblast -A PROBE -E ${minProbeMeltTemp} -i ${tntblastInputPath} -d ${sequenceFastaPath} -o ${tntblastOutputPath}";

close(STDOUT);
close(STDERR);
qx($cmd);
open(STDOUT, '>&', $stdout);
open(STDERR, '>&', $stderr);

unlink($tntblastInputPath);

# Parse the tntBLAST output.
my $tntblastParser = TntblastProbeParser->ctor($tntblastOutputPath);

while (my $record = $tntblastParser->getRecord()) {
   push(@{$TntblastProbeXsltFn::probeRecords}, $record);
}

$tntblastParser->finish();
unlink($tntblastOutputPath);

# Convert tntBLAST output to XML.
$sourceDoc = XML::LibXML::Document->new('1.0', 'UTF-8');
$stylesheet = XML::LibXSLT->new()->parse_stylesheet(
   XML::LibXML->load_xml('location' => TNTBLAST_PROBES_XSL_PATH)
);

map {
   $stylesheet->register_function('urn:local', $_->[0], $_->[1])
} (
   ['probeRecordIds', \&TntblastProbeXsltFn::probeRecordIds],
   ['probeName', \&TntblastProbeXsltFn::probeName],
   ['probeRegionStart', \&TntblastProbeXsltFn::probeRegionStart],
   ['probeRegionLength', \&TntblastProbeXsltFn::probeRegionLength],
   ['probeSense', \&TntblastProbeXsltFn::probeSense],
   ['probeMeltingTemperature', \&TntblastProbeXsltFn::probeMeltingTemperature]
);

$xslTransform = $stylesheet->transform($sourceDoc);

my (undef, $tntblastRecordsPath) = tempfile('SUFFIX' => '.xml', 'OPEN' => 0);
$stylesheet->output_file($xslTransform, $tntblastRecordsPath);

# Select the probe candidates that are consistent and unique in their annealing
# locations.
print(STDERR 'Selecting subset of probe candidates that are consistent and unique...' . "\n");

$cmd = "zorba --indent --external-variable tntblastRecordsUrl:=@{[URI::file->new_abs($tntblastRecordsPath)->as_string()]} --external-variable bruteForceProbesUrl:=@{[URI::file->new_abs($bruteForceProbesPath)->as_string()]} @{[(CONSISTENT_PROBES_XQ_PATH)]}";
my $probeXmlString = qx($cmd);

if ($outputFormat == 0) {
   # Output as XML.
   if (defined($outputProbesPath)) {
      my $outFh;
      open($outFh, '>', $outputProbesPath);
      print($outFh $probeXmlString . "\n");
      close($outFh);
   }
   else {
      print(STDOUT $probeXmlString . "\n");
   }
}
else {
   # Output as TSV.
   $sourceDoc = XML::LibXML->load_xml('string' => $probeXmlString);
   $stylesheet = XML::LibXSLT->new()->parse_stylesheet(
      XML::LibXML->load_xml('location' => TSV_XSL_PATH)
   );

   my $fieldNames = ['name', 'region-start', 'region-length', 'sense', 'melting-temperature', 'sequence'];

   map {
      $stylesheet->register_function('urn:local', $_->[0], $_->[1])
   } (
      ['records', sub {return $sourceDoc->findnodes('/*/probe');}],
      ['cells', sub {return $_[0]->[0]->findnodes(join(' | ', @{$fieldNames}));}]
   );

   $xslTransform = $stylesheet->transform($sourceDoc);

   my $outTsv = '#' . join("\t", @{$fieldNames}) . "\n";
   $outTsv .= $stylesheet->output_as_bytes($xslTransform);

   if (defined($outputProbesPath)) {
      my $outFh;
      open($outFh, '>', $outputProbesPath);
      print($outFh $outTsv);
      close($outFh);
   }
   else {
      print(STDOUT $outTsv);
   }
}

unlink($bruteForceProbesPath);
unlink($tntblastRecordsPath);

print(STDERR 'Complete.' . "\n");

1;
