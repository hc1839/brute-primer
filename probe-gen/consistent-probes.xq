declare variable $tntblastRecordsUrl external;
declare variable $bruteForceProbesUrl external;

declare variable $tntblastRecords := doc($tntblastRecordsUrl)/*/*;
declare variable $bruteForceProbes := doc($bruteForceProbesUrl)/*/*;

element consistent-probes {

for $probeName in distinct-values($tntblastRecords/name)
let $tntblastRecord := $tntblastRecords[name = $probeName]
let $bruteForceProbe := $bruteForceProbes[name = $probeName]
where
   count($tntblastRecord) = 1 and
   $tntblastRecord/region-start = $bruteForceProbe/region-start and
   $tntblastRecord/region-length = string-length($bruteForceProbe/sequence) and
   $tntblastRecord/sense = $bruteForceProbe/sense
return element probe {
   $tntblastRecord/*,
   $bruteForceProbe/sequence
}

}
