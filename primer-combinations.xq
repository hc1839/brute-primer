declare variable $fwdPrimersUrl external;
declare variable $revPrimersUrl external;

declare variable $fwdPrimerRecords := doc($fwdPrimersUrl)/*/*;
declare variable $revPrimerRecords := doc($revPrimersUrl)/*/*;

element primer-combinations {

for $fwdPrimerRecord in $fwdPrimerRecords
for $revPrimerRecord in $revPrimerRecords
count $idx
return element primer-pair {
   element name {
      string-join(("primer-pair-", xs:string($idx)), "")
   },
   element region-start {
      $fwdPrimerRecord/region-start/text()
   },
   element region-length {
      xs:integer($revPrimerRecord/region-start) + xs:integer($revPrimerRecord/region-length) - xs:integer($fwdPrimerRecord/region-start)
   },
   element fwd-primer-sequence {
      $fwdPrimerRecord/sequence/text()
   },
   element rev-primer-sequence {
      $revPrimerRecord/sequence/text()
   },
   element melting-temperature-fwd {
      $fwdPrimerRecord/melting-temperature/text()
   },
   element melting-temperature-rev {
      $revPrimerRecord/melting-temperature/text()
   }
}

}
