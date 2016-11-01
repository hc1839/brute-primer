#*:
#  tntblast-parser-module
#     - "TntblastParser";
#     isa module;
#  .
#

use strict;
use warnings;
use sort ('stable');

#*:
#  tntblast-parser
#     - "TntblastParser";
#     in-module(tntblast-parser-module);
#     isa class;
#     descr:
#        "Abstract class for parsing tntblast verbose output file.";
#  .
#
package TntblastParser;

#*:
#  tntblast-parser.ctor
#     - "ctor";
#     member-of(public-access, tntblast-parser);
#     isa ctor;
#  .
#
sub ctor {
   my $class = shift(@_);

   if ($class eq __PACKAGE__) {
      die(__PACKAGE__ . ' is an abstract class.');
   }

   my $this = {};

   bless($this, __PACKAGE__);
   return $this;
}

#*:
#  tntblast-parser.get-record
#     - "getRecord";
#     member-of(public-access, tntblast-parser);
#     isa virtual-function;
#     return-type-info: "hashref";
#     descr:
#        "Gets the next record, which is one alignment for one primer/probe. If
#        there are more than one alignment for one primer/probe, then each
#        alignment is considered to be one record. Returns {! undef} if there
#        are no more records.
#
#        Modifying the returned hash does nothing.";
#  .
#
sub getRecord;

#*:
#  tntblast-parser.finish
#     - "finish";
#     member-of(public-access, tntblast-parser);
#     isa virtual-function;
#     return-type-info: "undef";
#     descr:
#        "Ends parsing.";
#  .
sub finish;

1;

#*:
#  tntblast-probe-parser
#     - "TntblastProbeParser";
#     in-module(tntblast-parser-module);
#     subclass-of(public-access, tntblast-parser);
#     descr:
#        "Parses tntblast probe output file.";
#  .
#
package TntblastProbeParser;

use parent ('TntblastParser');

use File::Spec;
use Scalar::Util ('openhandle');

#*:
#  tntblast-probe-parser.ctor
#     - "ctor";
#     member-of(public-access, tntblast-probe-parser);
#     isa ctor;
#  .
#  tntblast-probe-parser.ctor.file-path
#     - "filePath";
#     param-of(1, tntblast-probe-parser.ctor);
#     descr:
#        "Path to probe output file.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($filePath) = @_;

   my $this = __PACKAGE__->SUPER::ctor();

   $filePath = File::Spec->rel2abs($filePath);

   if (!-f $filePath) {
      die($filePath . ' does not exist or is not a file.');
   }

   my $fh;
   open($fh, '<', $filePath);

   $this->{(__PACKAGE__ . '.fh')} = $fh;

   bless($this, __PACKAGE__);
   return $this;
}

#*:
#  tntblast-probe-parser.get-record
#     - "getRecord";
#     member-of(public-access, tntblast-probe-parser);
#     overrides(tntblast-parser.get-record);
#     descr:
#        "The following fields are parsed and stored in the returned hash.
#        {{ul -}
#           - {! name}: probe name.
#           - {! melting-temperature}: melting temperature of the probe.
#           - {! region-start}: one-based start position of annealing region of
#           the probe. Start is always less than end.
#           - {! region-length}: length of annealing region of the probe.
#           - {! sense}: polarity of the probe relative to the sequence.
#        }";
#  .
#
sub getRecord {
   my $this = shift(@_);
   my $fh = $this->{(__PACKAGE__ . '.fh')};

   if (!openhandle($fh)) {
      die('File handle closed.');
   }

   my $record = {};

   while (my $line = <$fh>) {
      chomp($line);

      if ($line =~ /^\s*name\s*=\s*(.+?)\s*$/i) {
         $record->{'name'} = $1;
         next;
      }

      if ($line =~ /^\s*probe\s+tm\s*=\s*(.+?)\s*$/i) {
         $record->{'melting-temperature'} = $1 * 1;
         next;
      }

      if ($line =~ /^\s*probe\s+range\s*=\s*(\d+)\s*\.{2,}\s*(\d+)\s*$/i) {
         my ($start_oneBased, $end_oneBased) = map {$_ * 1 + 1} ($1, $2);

         $record->{'region-start'} = $start_oneBased;
         $record->{'region-length'} = $end_oneBased + 1 - $start_oneBased;
         next;
      }

      if ($line =~ /^\s*probe\s+contained\s+in\s+/i) {
         $line =~ /\(\s*(.+?)\s*\)\s*$/;
         $record->{'sense'} = $1;
         next;
      }

      if ($line =~ /^\s*$/) {
         # If there is data in the record, then a blank line indicates end of
         # record. Otherwise, it is a trailing blank line from the previous
         # record and is ignored.
         if (scalar(keys(%{$record})) > 0) {
            return $record;
         }
      }
   }

   if (scalar(keys(%{$record})) > 0) {
      return $record;
   }
   else {
      return;
   }
}

#*:
#  tntblast-probe-parser.finish
#     - "finish";
#     member-of(public-access, tntblast-probe-parser);
#     overrides(tntblast-parser.finish);
#  .
sub finish {
   my $this = shift(@_);
   my $fh = $this->{(__PACKAGE__ . '.fh')};

   if (openhandle($fh)) {
      close($fh);
   }

   return;
}

#*:
#  tntblast-probe-parser.dtor
#     member-of(public-access, tntblast-probe-parser);
#     isa dtor;
#  .
#
sub DESTROY {
   my $this = shift(@_);

   $this->finish();
}

#*:
#  tntblast-primer-parser
#     - "TntblastPrimerParser";
#     in-module(tntblast-parser-module);
#     subclass-of(public-access, tntblast-parser);
#     descr:
#        "Parses tntblast primer output file.";
#  .
#
package TntblastPrimerParser;

use parent ('TntblastParser');

use File::Spec;
use Scalar::Util ('openhandle');

#*:
#  tntblast-primer-parser.ctor
#     - "ctor";
#     member-of(public-access, tntblast-primer-parser);
#     isa ctor;
#  .
#  tntblast-primer-parser.ctor.file-path
#     - "filePath";
#     param-of(1, tntblast-primer-parser.ctor);
#     descr:
#        "Path to primer output file.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($filePath) = @_;

   my $this = __PACKAGE__->SUPER::ctor();

   $filePath = File::Spec->rel2abs($filePath);

   if (!-f $filePath) {
      die($filePath . ' does not exist or is not a file.');
   }

   my $fh;
   open($fh, '<', $filePath);

   $this->{(__PACKAGE__ . '.fh')} = $fh;

   bless($this, __PACKAGE__);
   return $this;
}

#*:
#  tntblast-primer-parser.get-record
#     - "getRecord";
#     member-of(public-access, tntblast-primer-parser);
#     overrides(tntblast-parser.get-record);
#     descr:
#        "The following fields are parsed and stored in the returned hash.
#        {{ul -}
#           - {! name}: primer pair name.
#           - {! melting-temperature-fwd}: melting temperature of the forward
#           primer.
#           - {! melting-temperature-rev}: melting temperature of the reverse
#           primer.
#           - {! region-start}: one-based start position of amplicon region,
#           including primers. Start is always less than end.
#           - {! region-length}: length of amplicon region, including primers.
#        }";
#  .
#
sub getRecord {
   my $this = shift(@_);
   my $fh = $this->{(__PACKAGE__ . '.fh')};

   if (!openhandle($fh)) {
      die('File handle closed.');
   }

   my $record = {};

   while (my $line = <$fh>) {
      chomp($line);

      if ($line =~ /^\s*name\s*=\s*(.+?)\s*$/i) {
         $record->{'name'} = $1;
         next;
      }

      if ($line =~ /^\s*forward\s+primer\s+tm\s*=\s*(.+?)\s*$/i) {
         $record->{'melting-temperature-fwd'} = $1 * 1;
         next;
      }

      if ($line =~ /^\s*reverse\s+primer\s+tm\s*=\s*(.+?)\s*$/i) {
         $record->{'melting-temperature-rev'} = $1 * 1;
         next;
      }

      if ($line =~ /^\s*amplicon\s+range\s*=\s*(\d+)\s*\.{2,}\s*(\d+)\s*$/i) {
         my ($start_oneBased, $end_oneBased) = map {$_ * 1 + 1} ($1, $2);

         $record->{'region-start'} = $start_oneBased;
         $record->{'region-length'} = $end_oneBased + 1 - $start_oneBased;
         next;
      }

      if ($line =~ /^\s*$/) {
         # If there is data in the record, then a blank line indicates end of
         # record. Otherwise, it is a trailing blank line from the previous
         # record and is ignored.
         if (scalar(keys(%{$record})) > 0) {
            return $record;
         }
      }
   }

   if (scalar(keys(%{$record})) > 0) {
      return $record;
   }
   else {
      return;
   }
}

#*:
#  tntblast-primer-parser.finish
#     - "finish";
#     member-of(public-access, tntblast-primer-parser);
#     overrides(tntblast-parser.finish);
#  .
sub finish {
   my $this = shift(@_);
   my $fh = $this->{(__PACKAGE__ . '.fh')};

   if (openhandle($fh)) {
      close($fh);
   }

   return;
}

#*:
#  tntblast-primer-parser.dtor
#     member-of(public-access, tntblast-primer-parser);
#     isa dtor;
#  .
#
sub DESTROY {
   my $this = shift(@_);

   $this->finish();
}

1;
