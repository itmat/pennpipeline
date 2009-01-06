i couldn't install the new tpp on mustard cause there were dependancy issues.  so instead i used this work around...

for an IPI database, i ran this sed script:

sed -i 's/^>\(IPI:\)\([^| .]*\)\(.*\)$/>\2 \1\2\3/' databaseFile 

then i used the normal make_decoy.pl script to reverse the modified IPI database.  

also in mascot, i had to change the accession string and description parse rules as follows:

Rule to parse accession string: ">\(IPI[^| .]*\)" 
Rule to parse description string: ">IPI[0-9]{8} [^ ]* \(.*\)" 

and if i put the reversed database into mascot:

Rule to parse accession string: ">\([REV_]*IPI[^| .]*\)" 
Rule to parse description string: ">[REV_]*IPI[0-9]{8} [^ ]* \(.*\)" 


