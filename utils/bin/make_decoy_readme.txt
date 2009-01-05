USAGE
----------
%>   perl make_decoy.pl db_filename > new_db_filename


For an IPI database, preprocess with:

sed -i 's/^>\(IPI:\)\([^| .]*\)\(.*\)$/>\2 \1\2\3/' databaseFile 

before processing with make_decoy.pl

For SEQUEST, upload the resulting database to S:\sequest\database and copy to nodes using the Bioworks cluster manager tool.


For MASCOT, upload the database to the server as usual an configure with the following regular expresssions:

Rule to parse accession string: ">\([REV_]*IPI[^| .]*\)" 
Rule to parse description string: ">[REV_]*IPI[0-9]{8} [^ ]* \(.*\)" 


