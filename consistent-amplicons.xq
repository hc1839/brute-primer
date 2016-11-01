declare variable $tntblastRecordsUrl external;
declare variable $primerCombinationsUrl external;

declare variable $tntblastRecords := doc($tntblastRecordsUrl)/*/*;
declare variable $primerCombinations := doc($primerCombinationsUrl)/*/*;

element consistent-amplicons {

for $primerPairName in distinct-values($tntblastRecords/name)
let $tntblastRecord := $tntblastRecords[name = $primerPairName]
let $primerCombination := $primerCombinations[name = $primerPairName]
where
   count($tntblastRecord) = 1 and
   $tntblastRecord/region-start = $primerCombination/region-start and
   $tntblastRecord/region-length = $primerCombination/region-length
return element primer-pair {
   $tntblastRecord/*,
   $primerCombination/fwd-primer-sequence,
   $primerCombination/rev-primer-sequence
}

}
