#*:
#  cmd-arg-module
#     - "CmdArg";
#     isa module;
#  .
#

use strict;
use warnings;
use sort ('stable');


#*:
#  cmd-arg-key-spec.ctor
#     - "CmdArg::KeySpec";
#     in-module(cmd-arg-module);
#     isa abstract-class;
#     descr:
#        "Describes the behavior associated with a keyword.";
#  .
#
package CmdArg::KeySpec;

#*:
#  cmd-arg-key-spec.ctor
#     member-of(public-access, cmd-arg-key-spec);
#     isa ctor;
#     descr:
#        "Number of parameters is variable. All arguments passed will be
#        stored.";
#  .
#
sub ctor {
   my $class = shift(@_);

   if ($class eq __PACKAGE__) {
      die(__PACKAGE__ . ' is an abstract class.');
   }

   my $this = {};
   bless($this, __PACKAGE__);

   $this->{(__PACKAGE__ . '.args')} = [@_];

   return $this;
}

#*:
#  cmd-arg-key-spec.args
#     - "args";
#     member-of(public-access, cmd-arg-key-spec);
#     isa function;
#     return-type-info: "arrayref";
#     descr:
#        "Arguments passed to {^ #cmd-arg-key-spec.ctor}. Adding or removing
#        elements from the returned {! arrayref} has no effect.";
#  .
#
sub args {
   my $this = shift(@_);

   return [@{$this->{(__PACKAGE__ . '.args')}}];
}

1;


#*:
#  cmd-arg-unit
#     - "CmdArg::Unit";
#     in-module(cmd-arg-module);
#     subclass-of(cmd-arg-key-spec);
#     descr:
#        "Stores a function that, when an associated keyword is encountered, is
#        called with no arguments.";
#  .
#
package CmdArg::Unit;

use parent ('-norequire', 'CmdArg::KeySpec');

#*:
#  cmd-arg-unit.ctor
#     member-of(public-access, cmd-arg-unit);
#     isa ctor;
#  .
#  cmd-arg-unit.ctor.fn
#     - "fn";
#     param-of(1, cmd-arg-unit);
#     type-info: "coderef";
#     descr:
#        "Function to be stored.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($fn) = @_;

   my $this = __PACKAGE__->SUPER::ctor($fn);
   bless($this, __PACKAGE__);

   return $this;
}

1;


#*:
#  cmd-arg-boolean
#     - "CmdArg::Boolean";
#     in-module(cmd-arg-module);
#     subclass-of(cmd-arg-key-spec);
#     descr:
#        "Stores a function that, when an associated keyword is encountered, is
#        called with a boolean argument ({! 1} or {! 0}) depending on a
#        predefined set of symbols.";
#  .
#
package CmdArg::Boolean;

use parent ('-norequire', 'CmdArg::KeySpec');

#*:
#  cmd-arg-boolean.ctor
#     member-of(public-access, cmd-arg-boolean);
#     isa ctor;
#  .
#  cmd-arg-boolean.ctor.true-symbols
#     - "trueSymbols";
#     param-of(1, cmd-arg-boolean);
#     type-info: "arrayref";
#     descr:
#        "{! arrayref} of strings that are considered to be {! true} on the
#        command line.";
#  .
#  cmd-arg-boolean.ctor.false-symbols
#     - "falseSymbols";
#     param-of(2, cmd-arg-boolean);
#     type-info: "arrayref";
#     descr:
#        "{! arrayref} of strings that are considered to be {! false} on the
#        command line. This and {^ #cmd-arg-boolean.ctor.true-symbols} must be
#        mutually exclusive.";
#  .
#  cmd-arg-boolean.ctor.fn
#     - "fn";
#     param-of(3, cmd-arg-boolean);
#     type-info: "coderef";
#     descr:
#        "Function to be stored.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($trueSymbols, $falseSymbols, $fn) = @_;

   my $this = __PACKAGE__->SUPER::ctor($trueSymbols, $falseSymbols, $fn);
   bless($this, __PACKAGE__);

   foreach my $trueSymbol (@{$trueSymbols}) {
      if (scalar(grep {$_ eq $trueSymbol} @{$falseSymbols}) > 0) {
         die('True and false symbols are not mutually exclusive');
      }
   }

   return $this;
}

1;


#*:
#  cmd-arg-set
#     - "CmdArg::Set";
#     in-module(cmd-arg-module);
#     subclass-of(cmd-arg-key-spec);
#     descr:
#        "Stores a scalar reference that, when an associated keyword is
#        encountered, is set to {! 1} (to indicate {! true}).";
#  .
#
package CmdArg::Set;

use parent ('-norequire', 'CmdArg::KeySpec');

#*:
#  cmd-arg-set.ctor
#     member-of(public-access, cmd-arg-set);
#     isa ctor;
#  .
#  cmd-arg-set.ctor.ptr
#     - "ptr";
#     param-of(1, cmd-arg-set);
#     type-info: "scalarref";
#     descr:
#        "Scalar reference to be stored.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($ptr) = @_;

   my $this = __PACKAGE__->SUPER::ctor($ptr);
   bless($this, __PACKAGE__);

   return $this;
}

1;


#*:
#  cmd-arg-clear
#     - "CmdArg::Clear";
#     in-module(cmd-arg-module);
#     subclass-of(cmd-arg-key-spec);
#     descr:
#        "Stores a scalar reference that, when an associated keyword is
#        encountered, is set to {! 0} (to indicate {! false}).";
#  .
#
package CmdArg::Clear;

use parent ('-norequire', 'CmdArg::KeySpec');

#*:
#  cmd-arg-clear.ctor
#     member-of(public-access, cmd-arg-clear);
#     isa ctor;
#  .
#  cmd-arg-clear.ctor.ptr
#     - "ptr";
#     param-of(1, cmd-arg-clear);
#     type-info: "scalarref";
#     descr:
#        "Scalar reference to be stored.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($ptr) = @_;

   my $this = __PACKAGE__->SUPER::ctor($ptr);
   bless($this, __PACKAGE__);

   return $this;
}

1;


#*:
#  cmd-arg-string
#     - "CmdArg::String";
#     in-module(cmd-arg-module);
#     subclass-of(cmd-arg-key-spec);
#     descr:
#        "Stores a function that, when an associated keyword is encountered, is
#        called with one argument as string.";
#  .
#
package CmdArg::String;

use parent ('-norequire', 'CmdArg::KeySpec');

#*:
#  cmd-arg-string.ctor
#     member-of(public-access, cmd-arg-string);
#     isa ctor;
#  .
#  cmd-arg-string.ctor.fn
#     - "fn";
#     param-of(1, cmd-arg-string);
#     type-info: "coderef";
#     descr:
#        "Function to be stored.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($fn) = @_;

   my $this = __PACKAGE__->SUPER::ctor($fn);
   bless($this, __PACKAGE__);

   return $this;
}

1;


#*:
#  cmd-arg-set-string
#     - "CmdArg::SetString";
#     in-module(cmd-arg-module);
#     subclass-of(cmd-arg-key-spec);
#     descr:
#        "Stores a scalar reference that, when an associated keyword is
#        encountered, is set to the command-line argument as string.";
#  .
#
package CmdArg::SetString;

use parent ('-norequire', 'CmdArg::KeySpec');

#*:
#  cmd-arg-set-string.ctor
#     member-of(public-access, cmd-arg-set-string);
#     isa ctor;
#  .
#  cmd-arg-set-string.ctor.ptr
#     - "ptr";
#     param-of(1, cmd-arg-set-string);
#     type-info: "scalarref";
#     descr:
#        "Scalar reference to be stored.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($ptr) = @_;

   my $this = __PACKAGE__->SUPER::ctor($ptr);
   bless($this, __PACKAGE__);

   return $this;
}

1;


#*:
#  cmd-arg-number-integer
#     - "CmdArg::Integer";
#     in-module(cmd-arg-module);
#     subclass-of(cmd-arg-key-spec);
#     descr:
#        "Stores a function that, when an associated keyword is encountered, is
#        called with one argument as integer (that was truncated toward {! 0}
#        using the {! int} function).";
#  .
#
package CmdArg::Integer;

use parent ('-norequire', 'CmdArg::KeySpec');

#*:
#  cmd-arg-integer.ctor
#     member-of(public-access, cmd-arg-integer);
#     isa ctor;
#  .
#  cmd-arg-integer.ctor.fn
#     - "fn";
#     param-of(1, cmd-arg-integer);
#     type-info: "coderef";
#     descr:
#        "Function to be stored.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($fn) = @_;

   my $this = __PACKAGE__->SUPER::ctor($fn);
   bless($this, __PACKAGE__);

   return $this;
}

1;


#*:
#  cmd-arg-set-integer
#     - "CmdArg::SetInteger";
#     in-module(cmd-arg-module);
#     subclass-of(cmd-arg-key-spec);
#     descr:
#        "Stores a scalar reference that, when an associated keyword is
#        encountered, is set to the command-line argument as integer (that was
#        truncated toward {! 0} using the {! int} function).";
#  .
#
package CmdArg::SetInteger;

use parent ('-norequire', 'CmdArg::KeySpec');

#*:
#  cmd-arg-set-integer.ctor
#     member-of(public-access, cmd-arg-set-integer);
#     isa ctor;
#  .
#  cmd-arg-set-integer.ctor.ptr
#     - "ptr";
#     param-of(1, cmd-arg-set-integer);
#     type-info: "scalarref";
#     descr:
#        "Scalar reference to be stored.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($ptr) = @_;

   my $this = __PACKAGE__->SUPER::ctor($ptr);
   bless($this, __PACKAGE__);

   return $this;
}


#*:
#  cmd-arg-real
#     - "CmdArg::Real";
#     in-module(cmd-arg-module);
#     subclass-of(cmd-arg-key-spec);
#     descr:
#        "Stores a function that, when an associated keyword is encountered, is
#        called with one argument as real number.";
#  .
#
package CmdArg::Real;

use parent ('-norequire', 'CmdArg::KeySpec');

#*:
#  cmd-arg-real.ctor
#     member-of(public-access, cmd-arg-real);
#     isa ctor;
#  .
#  cmd-arg-real.ctor.fn
#     - "fn";
#     param-of(1, cmd-arg-real);
#     type-info: "coderef";
#     descr:
#        "Function to be stored.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($fn) = @_;

   my $this = __PACKAGE__->SUPER::ctor($fn);
   bless($this, __PACKAGE__);

   return $this;
}

1;


#*:
#  cmd-arg-set-real
#     - "CmdArg::SetReal";
#     in-module(cmd-arg-module);
#     subclass-of(cmd-arg-key-spec);
#     descr:
#        "Stores a scalar reference that, when an associated keyword is
#        encountered, is set to the command-line argument as real number.";
#  .
#
package CmdArg::SetReal;

use parent ('-norequire', 'CmdArg::KeySpec');

#*:
#  cmd-arg-set-real.ctor
#     member-of(public-access, cmd-arg-set-real);
#     isa ctor;
#  .
#  cmd-arg-set-real.ctor.ptr
#     - "ptr";
#     param-of(1, cmd-arg-set-real);
#     type-info: "scalarref";
#     descr:
#        "Scalar reference to be stored.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($ptr) = @_;

   my $this = __PACKAGE__->SUPER::ctor($ptr);
   bless($this, __PACKAGE__);

   return $this;
}

1;


#*:
#  cmd-arg-tuple
#     - "CmdArg::Tuple";
#     in-module(cmd-arg-module);
#     subclass-of(cmd-arg-key-spec);
#     descr:
#        "Stores an {! arrayref} of {^ #cmd-arg-key-spec} such that several
#        command-line arguments are taken when an associated keyword is
#        encountered.";
#  .
#
package CmdArg::Tuple;

use parent ('-norequire', 'CmdArg::KeySpec');

#*:
#  cmd-arg-tuple.ctor
#     member-of(public-access, cmd-arg-tuple);
#     isa ctor;
#  .
#  cmd-arg-tuple.ctor.spec-list
#     - "specList";
#     param-of(1, cmd-arg-tuple);
#     type-info: "arrayref";
#     descr:
#        "{! arrayref} of {^ #cmd-arg-key-spec} to be stored.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($specList) = @_;

   my $this = __PACKAGE__->SUPER::ctor($specList);
   bless($this, __PACKAGE__);

   return $this;
}

1;


#*:
#  cmd-arg-symbol
#     - "CmdArg::Symbol";
#     in-module(cmd-arg-module);
#     subclass-of(cmd-arg-key-spec);
#     descr:
#        "Stores a function that, when an associated keyword is encountered, is
#        called with a command-line argument that is an element of a predefined
#        set of strings.";
#  .
#
package CmdArg::Symbol;

use parent ('-norequire', 'CmdArg::KeySpec');

#*:
#  cmd-arg-symbol.ctor
#     member-of(public-access, cmd-arg-symbol);
#     isa ctor;
#  .
#  cmd-arg-symbol.ctor.symbols
#     - "symbols";
#     param-of(1, cmd-arg-symbol);
#     type-info: "arrayref";
#     descr:
#        "{! arrayref} of strings that are valid as a command-line argument.";
#  .
#  cmd-arg-symbol.ctor.fn
#     - "fn";
#     param-of(2, cmd-arg-symbol);
#     type-info: "coderef";
#     descr:
#        "Function to be stored.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($symbols, $fn) = @_;

   my $this = __PACKAGE__->SUPER::ctor($symbols, $fn);
   bless($this, __PACKAGE__);

   return $this;
}

1;


#*:
#  cmd-arg-rest
#     - "CmdArg::Rest";
#     in-module(cmd-arg-module);
#     subclass-of(cmd-arg-key-spec);
#     descr:
#        "Stores a function that, when an associated keyword is encountered, is
#        called with one argument as string for each of the remaining
#        command-line arguments.";
#  .
#
package CmdArg::Rest;

use parent ('-norequire', 'CmdArg::KeySpec');

#*:
#  cmd-arg-rest.ctor
#     member-of(public-access, cmd-arg-rest);
#     isa ctor;
#  .
#  cmd-arg-rest.ctor.fn
#     - "fn";
#     param-of(1, cmd-arg-rest);
#     type-info: "coderef";
#     descr:
#        "Function to be stored.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($fn) = @_;

   my $this = __PACKAGE__->SUPER::ctor($fn);
   bless($this, __PACKAGE__);

   return $this;
}

1;


#*:
#  cmd-arg-opt-spec
#     - "CmdArg::OptSpec";
#     in-module(cmd-arg-module);
#     isa class;
#     descr:
#        "Specification of a command-line option.";
#  .
#
package CmdArg::OptSpec;

#*:
#  cmd-arg-opt-spec.ctor
#     member-of(public-access, cmd-arg-opt-spec);
#     isa ctor;
#  .
#  cmd-arg-opt-spec.ctor.keywords
#     - "keywords";
#     param-of(1, cmd-arg-opt-spec.ctor);
#     type-info: "arrayref";
#     descr:
#        "{! arrayref} of keywords as strings associated the command-line
#        option. A keyword must start with a hyphen and can be composed of
#        alphanumeric characters, underscore, or hyphen. No two strings can be
#        equal (case-sensitive).";
#  .
#  cmd-arg-opt-spec.ctor.key-spec
#     - "keySpec";
#     param-of(2, cmd-arg-opt-spec.key-ctor);
#     type-info: <#cmd-arg-key-spec>;
#     descr:
#        "{^ #cmd-arg-key-spec} that describes the behavior associated with {^
#        #cmd-arg-opt-spec.ctor.keyword}.";
#  .
#  cmd-arg-opt-spec.ctor.arg-name
#     - "argName";
#     param-of(3, cmd-arg-opt-spec.ctor);
#     type-info: "string";
#     descr:
#        "Name of the argument of the command-line option to be used in the
#        help message. For {^ #cmd-arg-opt-spec.ctor.spec} is {^
#        #cmd-arg-unit}, {^ #cmd-arg-set}, or {^ #cmd-arg-clear}, a zero-length
#        string is expected. For {^ #cmd-arg-opt-spec.ctor.spec} is {^
#        #cmd-arg-tuple} or {^ #cmd-arg-rest}, an ellipsis ({! "..."}) is
#        expected. All other {^ #cmd-arg-key-spec} members require a name
#        composed of alphanumeric characters, underscore, or hyphen and that
#        starts with an alphabetical character or an underscore.";
#  .
#  cmd-arg-opt-spec.ctor.doc
#     - "doc";
#     param-of(4, cmd-arg-opt-spec.ctor);
#     type-info: "string";
#     descr:
#        "Brief description of the command-line option.";
#  .
#
sub ctor {
   my $class = shift(@_);
   my ($keywords, $keySpec, $argName, $doc) = @_;

   $keywords = [@{$keywords}];
   $argName .= '';
   $doc .= '';

   my $this = {};
   bless($this, __PACKAGE__);

   if (scalar(grep {$_ !~ /^-/} @{$keywords}) > 0) {
      die('At least one keyword does not start with a hyphen');
   }

   if (scalar(grep {$_ !~ /^[\w\-]+$/} @{$keywords}) > 0) {
      die('At least one keyword is not composed of alphanumeric characters, underscore, or hyphen');
   }

   foreach my $keyword (@{$keywords}) {
      if (scalar(grep {$_ eq $keyword} @{$keywords}) > 1) {
         die($keyword . ' is repeated');
      }
   }

   if (scalar(grep {$keySpec->isa($_)} ('CmdArg::Unit', 'CmdArg::Set', 'CmdArg::Clear')) > 0) {
      if ($argName ne '') {
         die('Argument name given');
      }
   }
   elsif (scalar(grep {$keySpec->isa($_)} ('CmdArg::Tuple', 'CmdArg::Rest')) > 0) {
      if ($argName ne '...') {
         die('Argument name given to a variable number of command-line arguments');
      }
   }
   else {
      if ($argName !~ /^[[:alpha:]_][\w\-]*$/) {
         die($argName . ' is not a valid name for a command-line argument');
      }
   }

   $this->{(__PACKAGE__ . '.keywords')} = $keywords;
   $this->{(__PACKAGE__ . '.keySpec')} = $keySpec;
   $this->{(__PACKAGE__ . '.argName')} = $argName;
   $this->{(__PACKAGE__ . '.doc')} = $doc;

   return $this;
}

#*:
#  cmd-arg-opt-spec.keywords
#     - "keywords";
#     member-of(public-access, cmd-arg-opt-spec);
#     isa function;
#     return-type-info: "arrayref";
#     descr:
#        "See {^ #cmd-arg-opt-spec.ctor.keyword}. Modifying the returned {!
#        arrayref} has no effect.";
#  .
#
sub keywords {
   my $this = shift(@_);

   return [@{$this->{(__PACKAGE__ . '.keywords')}}];
}

#*:
#  cmd-arg-opt-spec.key-spec
#     - "keySpec";
#     member-of(public-access, cmd-arg-opt-spec);
#     isa function;
#     return-type-info: <#cmd-arg-key-spec>;
#     descr:
#        "See {^ #cmd-arg-opt-spec.ctor.key-spec}.";
#  .
#
sub keySpec {
   my $this = shift(@_);

   return $this->{(__PACKAGE__ . '.keySpec')};
}

#*:
#  cmd-arg-opt-spec.arg-name
#     - "argName";
#     member-of(public-access, cmd-arg-opt-spec);
#     isa function;
#     return-type-info: "string";
#     descr:
#        "See {^ #cmd-arg-opt-spec.ctor.arg-name}.";
#  .
#
sub argName {
   my $this = shift(@_);

   return $this->{(__PACKAGE__ . '.argName')};
}

#*:
#  cmd-arg-opt-spec.doc
#     - "doc";
#     member-of(public-access, cmd-arg-opt-spec);
#     isa function;
#     return-type-info: "string";
#     descr:
#        "See {^ #cmd-arg-opt-spec.ctor.doc}.";
#  .
#
sub doc {
   my $this = shift(@_);

   return $this->{(__PACKAGE__ . '.doc')};
}

1;


#*:
#  cmd-arg
#     - "CmdArg";
#     in-module(cmd-arg-module);
#     isa package;
#     descr:
#        "Functions for parsing command-line arguments.";
#  .
#
package CmdArg;

use Exporter ('import');

# Column widths to be used when no help option is provided.
use constant ('COL_BORDER_WIDTH_DEFAULT', 10);
use constant ('DOC_COL_WIDTH_DEFAULT', 60);

our @EXPORT_OK = (
   'helpMessage',
   'parseArgv'
);

#*:
#  cmd-arg._word-wrap
#     - "_wordWrap";
#     member-of(private-access, cmd-arg);
#     isa function; isa static;
#     return-type-info: "arrayref of strings";
#     descr:
#        "{! arrayref} of strings such that each string is no longer than a
#        given length unless a single word exceeds the given length. Two words
#        are separated by at least one space. Trailing spaces are removed.";
#  .
#  cmd-arg._word-wrap.text
#     - "text";
#     param-of(1, cmd-arg._word-wrap);
#     type-info: "string";
#     descr:
#        "Text to be wrapped.";
#  .
#  cmd-arg._word-wrap.width
#     - "width";
#     param-of(2, cmd-arg._word-wrap);
#     type-info: "integer";
#     descr:
#        "Width of the wrapped text. Must be greater than zero.";
#  .
#
sub _wordWrap {
   my ($text, $width) = @_;

   $text .= '';
   $width = int($width);

   if ($width <= 0) {
      die('Width of wrapped text must be positive');
   }

   $text =~ s/\s+$//g;

   if (length($text) <= $width or $text !~ /\s/) {
      return [$text];
   }
   elsif ($text =~ /\n/) {
      return [map {@{_wordWrap($_, $width)}} split(qr/\n/, $text)];
   }
   else {
      # In this code block, a whitespace must exist and cannot be a newline.
      my $lastPos = 0;

      while ($text =~ /\s+/g) {
         if ($-[0] <= $width) {
            $lastPos = $-[0];
         }
         else {
            last;
         }
      }

      my $remainingText = substr($text, $lastPos);
      $remainingText =~ s/^\s+//g;

      if ($remainingText eq '') {
         return [substr($text, 0, $lastPos)];
      }
      else {
         return [substr($text, 0, $lastPos), @{_wordWrap($remainingText, $width)}];
      }
   }
}

#*:
#  cmd-arg._invoke-spec
#     - "_invokeSpec";
#     member-of(private-access, cmd-arg);
#     isa function; isa static;
#     return-type-info: "undef";
#     descr:
#        "Invokes a {^ #cmd-arg-key-spec} using the appropriate number, if any,
#        of command-line arguments.";
#  .
#  cmd-arg._invoke-spec.spec
#     - "spec";
#     param-of(1, cmd-arg._invoke-spec);
#     type-info: <#cmd-arg-key-spec>;
#     descr:
#        "{^ #cmd-arg-key-spec} to be invoked.";
#  .
#  cmd-arg._invoke-spec.cmd-args
#     - "cmdArgs";
#     param-of(2, cmd-arg._invoke-spec);
#     type-info: "arrayref";
#     descr:
#        "{! arrayref} of command-line arguments as strings. The first few
#        elements, if any, will be removed and used for invoking {^
#        #cmd-arg._invoke-spec.spec}. The number of elements that are removed
#        depends on the subclass of {^ #cmd-arg._invoke-spec.spec}.";
#  .
#
sub _invokeSpec {
   my ($spec, $cmdArgs) = @_;

   if ($spec->isa('CmdArg::Unit')) {
      $spec->args()->[0]->();
      return;
   }
   elsif ($spec->isa('CmdArg::Boolean')) {
      if (scalar(@{$cmdArgs}) >= 1 and $cmdArgs->[0] !~ /^-/) {
         my $optArg = shift(@{$cmdArgs});

         foreach my $pair ([$spec->args()->[0], 1], [$spec->args()->[1], 0]) {
            if (scalar(grep {$_ eq $optArg} @{$pair->[0]}) > 0) {
               $spec->args()->[2]->($pair->[1]);
               return;
            }
         }

         die($optArg . ' is not a valid symbol');
      }
      else {
         die('No command-line argument given to a Boolean option');
      }
   }
   elsif ($spec->isa('CmdArg::Set')) {
      ${$spec->args()->[0]} = 1;
      return;
   }
   elsif ($spec->isa('CmdArg::Clear')) {
      ${$spec->args()->[0]} = 0;
      return;
   }
   elsif ($spec->isa('CmdArg::String')) {
      if (scalar(@{$cmdArgs}) >= 1 and $cmdArgs->[0] !~ /^-/) {
         $spec->args()->[0]->(shift(@{$cmdArgs}) . '');
         return;
      }
      else {
         die('No command-line argument given to a String option');
      }
   }
   elsif ($spec->isa('CmdArg::SetString')) {
      if (scalar(@{$cmdArgs}) >= 1 and $cmdArgs->[0] !~ /^-/) {
         ${$spec->args()->[0]} = shift(@{$cmdArgs}) . '';
         return;
      }
      else {
         die('No command-line argument given to a SetString option');
      }
   }
   elsif ($spec->isa('CmdArg::Integer')) {
      if (scalar(@{$cmdArgs}) >= 1 and $cmdArgs->[0] !~ /^-/) {
         $spec->args()->[0]->(int(shift(@{$cmdArgs})));
         return;
      }
      else {
         die('No command-line argument given to a Integer option');
      }
   }
   elsif ($spec->isa('CmdArg::SetInteger')) {
      if (scalar(@{$cmdArgs}) >= 1 and $cmdArgs->[0] !~ /^-/) {
         ${$spec->args()->[0]} = int(shift(@{$cmdArgs}));
         return;
      }
      else {
         die('No command-line argument given to a SetInteger option');
      }
   }
   elsif ($spec->isa('CmdArg::Real')) {
      if (scalar(@{$cmdArgs}) >= 1 and $cmdArgs->[0] !~ /^-/) {
         $spec->args()->[0]->(shift(@{$cmdArgs}) * 1);
         return;
      }
      else {
         die('No command-line argument given to a Real option');
      }
   }
   elsif ($spec->isa('CmdArg::SetReal')) {
      if (scalar(@{$cmdArgs}) >= 1 and $cmdArgs->[0] !~ /^-/) {
         ${$spec->args()->[0]} = shift(@{$cmdArgs}) * 1;
         return;
      }
      else {
         die('No command-line argument given to a SetReal option');
      }
   }
   elsif ($spec->isa('CmdArg::Tuple')) {
      my $specs = [@{$spec->args()->[0]}];

      if (scalar(@{$specs}) > 0) {
         _invokeSpec(shift(@{$specs}), $cmdArgs);
         _invokeSpec(CmdArg::Tuple->ctor($specs), $cmdArgs);
         return;
      }
      else {
         return;
      }
   }
   elsif ($spec->isa('CmdArg::Symbol')) {
      if (scalar(@{$cmdArgs}) >= 1 and $cmdArgs->[0] !~ /^-/) {
         my $optArg = shift(@{$cmdArgs});

         if (scalar(grep {$_ eq $optArg} @{$spec->args()->[0]}) > 0) {
            $spec->args()->[1]->($optArg . '');
            return;
         }
         else {
            die($optArg . ' is not a valid command-line argument');
         }
      }
      else {
         die('No command-line argument given to a Symbol option');
      }
   }
   elsif ($spec->isa('CmdArg::Rest')) {
      if (scalar(@{$cmdArgs}) == 0) {
         return;
      }
      else {
         if ($cmdArgs->[0] !~ /^-/) {
            $spec->args()->[0]->(shift(@{$cmdArgs}) . '');
            _invokeSpec($spec, $cmdArgs);
            return;
         }
         else {
            die($cmdArgs->[0] . ' is a keyword');
         }
      }
   }
   else {
      die('Invalid spec');
   }
}

#*:
#  cmd-arg.help-message
#     - "helpMessage";
#     member-of(public-access, cmd-arg);
#     isa function; isa static;
#     return-type-info: "string";
#     descr:
#        "Returns a string suitable to be printed directly to the terminal as a
#        help that contains the given list of options and their brief
#        descriptions. Consecutive spaces, including newlines, in the
#        description strings are collapsed into one space.";
#  .
#  cmd-arg.help-message.opt-specs
#     - "optSpecs";
#     param-of(1, cmd-arg.help-message);
#     type-info: "arrayref";
#     descr:
#        "{! arrayref} of {^ #cmd-arg-opt-spec}.";
#  .
#  cmd-arg.help-message.col-border-width
#     - "colBorderWidth";
#     param-of(2, cmd-arg.help-message);
#     type-info: "integer";
#     descr:
#        "Number of spaces to separate columns.";
#  .
#  cmd-arg.help-message.doc-width
#     - "docWidth";
#     param-of(3, cmd-arg.help-message);
#     type-info: "integer";
#     descr:
#        "Width, in number of characters, for the string that describes the
#        command-line option.";
#  .
#  cmd-arg.help-message.usage-msg-top
#     - "usageMsgTop";
#     param-of(4, cmd-arg.help-message);
#     type-info: "string";
#     descr:
#        "Usage description to be included at the top of the help message. It
#        is wrapped with a width of the options section.";
#  .
#  cmd-arg.help-message.usage-msg-bottom
#     - "usageMsgBottom";
#     param-of(5, cmd-arg.help-message);
#     type-info: "string";
#     descr:
#        "Usage description to be included at the bottom of the help message.
#        It is wrapped with a width of the options section.";
#  .
#
sub helpMessage {
   my ($optSpecs, $colBorderWidth, $docWidth, $usageMsgTop, $usageMsgBottom) = @_;

   $optSpecs = [@{$optSpecs}];
   $colBorderWidth = int($colBorderWidth);
   $docWidth = int($docWidth);
   $usageMsgTop .= '';
   $usageMsgBottom .= '';

   my $optDescrs = [];
   my $colWidths = [0, $docWidth];   # Width of option column is dynamically determined.

   foreach my $optSpec (@{$optSpecs}) {
      my $syntax = join('|', @{$optSpec->keywords()});
      my $argName = $optSpec->argName();

      if ($argName ne '' and $argName ne '...') {
         $syntax .= ' <' . $argName . '>';
      }

      my $keySpec = $optSpec->keySpec();
      my $type = '';

      if ($keySpec->isa('CmdArg::Unit')) {
         $type = '';
      }
      elsif ($keySpec->isa('CmdArg::Boolean')) {
         $type = 'boolean';
      }
      elsif ($keySpec->isa('CmdArg::Set')) {
         $type = '';
      }
      elsif ($keySpec->isa('CmdArg::Clear')) {
         $type = '';
      }
      elsif ($keySpec->isa('CmdArg::String') or $keySpec->isa('CmdArg::SetString')) {
         $type = 'string';
      }
      elsif ($keySpec->isa('CmdArg::Integer') or $keySpec->isa('CmdArg::SetInteger')) {
         $type = 'integer';
      }
      elsif ($keySpec->isa('CmdArg::Real') or $keySpec->isa('CmdArg::SetReal')) {
         $type = 'real';
      }
      elsif ($keySpec->isa('CmdArg::Tuple')) {
         $type = '...';
      }
      elsif ($keySpec->isa('CmdArg::Symbol')) {
         $type = 'string';
      }
      elsif ($keySpec->isa('CmdArg::Rest')) {
         $type = '...';
      }
      else {
         die('Unknown key spec type');
      }

      my $doc = $optSpec->doc();
      $doc =~ s/^\s+|\s+$//g;
      $doc =~ s/\s+/ /g;

      if ($type ne '') {
         $doc = "(${type}) " . $doc ;
      }

      $colWidths->[0] = (length($syntax) > $colWidths->[0] ? length($syntax) : $colWidths->[0]);

      push(@{$optDescrs}, [$syntax, $doc]);
   }

   foreach my $optDescr (@{$optDescrs}) {
      # Option syntax is left aligned.
      $optDescr->[0] .= ' ' x ($colWidths->[0] - length($optDescr->[0]));

      # Option doc is left aligned and wrapped.
      $optDescr->[1] =~ s/\s+/ /g;
      my $docLines = _wordWrap($optDescr->[1], $colWidths->[1]);

      for (my $i = 1; $i != $#{$docLines} + 1; ++$i) {
         $docLines->[$i] = ' ' x ($colWidths->[0] + $colBorderWidth) . $docLines->[$i];
      }

      $optDescr->[1] = join("\n", @{$docLines});
   }

   ($usageMsgTop, $usageMsgBottom) = map {
      join("\n", @{_wordWrap($_, $colWidths->[0] + $colBorderWidth + $colWidths->[1])})
   } ($usageMsgTop, $usageMsgBottom);

   my $formattedHelp = ($usageMsgTop eq '' ? '' : $usageMsgTop . "\n\n");
   $formattedHelp .= join("\n\n", map {join(' ' x $colBorderWidth, @{$_})} @{$optDescrs});
   $formattedHelp .= ($usageMsgBottom eq '' ? '' : "\n\n" . $usageMsgBottom);

   return $formattedHelp;
}

#*:
#  cmd-arg.parse-argv
#     - "parseArgv";
#     member-of(public-access, cmd-arg);
#     isa function; isa static;
#     return-type-info: "undef";
#     descr:
#        "Parses an {! arrayref} of strings as if they are command-line
#        arguments. The functions in {^ #cmd-arg.parse-argv.opt-spec} and {^
#        #cmd-arg.parse-argv.anon-fn} are called in the same order as their
#        arguments appear on the command line.";
#  .
#  cmd-arg.parse-argv.cmd-args
#     - "cmdArgs";
#     param-of(1, cmd-arg.parse-argv);
#     type-info: "arrayref";
#     descr:
#        "{! arrayref} of command-line arguments as strings. The element with
#        index of 0 is the program name and is ignored.";
#  .
#  cmd-arg.parse-argv.opt-specs
#     - "optSpecs";
#     param-of(2, cmd-arg.parse-argv);
#     type-info: "{! arrayref} of {^ #cmd-arg-opt-spec}";
#     descr:
#        "{! arrayref} of {^ #cmd-arg-opt-spec} that each specifies the
#        behavior associated with a keyword when encountered.
#
#        If the options for {! -help} and {! --help} are not provided, then
#        they will automatically be added using {^ #cmd-arg.help-message} as
#        the function that formats the help message. If only one of such
#        options is provided, then the missing help option will be added using
#        the {^ #cmd-arg-key-spec} of the one given.";
#  .
#  cmd-arg.parse-argv.anon-fn
#     - "anonFn";
#     param-of(3, cmd-arg.parse-argv);
#     type-info: "coderef";
#     descr:
#        "One-arity function that is called on each anonymous argument, which
#        are command-line arguments that are not preceded by a keyword. The
#        return value of this function is ignored.";
#  .
#  cmd-arg.parse-argv.usage-msg-top
#     - "usageMsgTop";
#     param-of(4, cmd-arg.parse-argv);
#     type-info: "string";
#     descr:
#        "Usage description to be included at the top of the default help
#        message. This parameter is ignored if {! -help}, {! --help}, or both
#        are overridden. See {^ #cmd-arg.help-message.usage-msg-top}.";
#  .
#  cmd-arg.parse-argv.usage-msg-bottom
#     - "usageMsgBottom";
#     param-of(5, cmd-arg.parse-argv);
#     type-info: "string";
#     descr:
#        "Usage description to be included at the bottom of the default help
#        message. This parameter is ignored if {! -help}, {! --help}, or both
#        are overridden.  See {^ #cmd-arg.help-message.usage-msg-bottom}.";
#  .
#
sub parseArgv {
   my ($cmdArgs, $optSpecs, $anonFn, $usageMsgTop, $usageMsgBottom) = @_;

   $cmdArgs = [map {$_ . ''} @{$cmdArgs}];
   $optSpecs = [@{$optSpecs}];
   $usageMsgTop .= '';
   $usageMsgBottom .= '';

   # Remove the program name.
   shift(@{$cmdArgs});

   # Create a hash of key specs from the array of option specs.
   my $keySpecs = {};

   foreach my $optSpec (@{$optSpecs}) {
      foreach my $keyword (@{$optSpec->keywords()}) {
         if (!exists($keySpecs->{($keyword)})) {
            $keySpecs->{($keyword)} = $optSpec->keySpec();
         }
         else {
            die($keyword . ' is a repeated keyword');
         }
      }
   }

   # Add the help option(s) if needed.
   if (!exists($keySpecs->{'-help'}) and !exists($keySpecs->{'--help'})) {
      push(
         @{$optSpecs},
         CmdArg::OptSpec->ctor(
            ['-help', '--help'],
            CmdArg::Unit->ctor(
               sub {
                  print(helpMessage($optSpecs, COL_BORDER_WIDTH_DEFAULT, DOC_COL_WIDTH_DEFAULT, $usageMsgTop, $usageMsgBottom) . "\n");
                  exit(0);
               }
            ),
            '',
            "Display this help."
         )
      );
      $keySpecs->{'-help'} = $optSpecs->[-1]->keySpec();
      $keySpecs->{'--help'} = $keySpecs->{'-help'};
   }
   elsif (exists($keySpecs->{'-help'}) and !exists($keySpecs->{'--help'})) {
      $keySpecs->{'--help'} = $keySpecs->{'-help'};
   }
   elsif (!exists($keySpecs->{'-help'}) and exists($keySpecs->{'--help'})) {
      $keySpecs->{'-help'} = $keySpecs->{'--help'};
   }

   # Parse and process command-line options and arguments.
   while (scalar(@{$cmdArgs}) > 0) {
      my $cmdArg = shift(@{$cmdArgs});

      if ($cmdArg =~ /^-/) {
         my $keyword = $cmdArg;

         if (exists($keySpecs->{($keyword)})) {
            _invokeSpec($keySpecs->{($keyword)}, $cmdArgs);
         }
         else {
            die('Unknown keyword: ' . $keyword);
         }
      }
      else {
         $anonFn->($cmdArg);
      }
   }

   return;
}

1;
