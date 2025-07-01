AH! NOW I REALLY REALLY get it!

## Purpose of the script `s3_compare-configs.sh`

The script needs to work correctly in ALL cases:
Right after running s2_extract-configs.sh (like now):
Runtime → Extracted should be identical (because we just extracted)
Source → Extracted shows any manual changes
But in future runs (without running s2 first):
Runtime → Extracted might show differences if someone made changes in the container since the last extraction
Source → Extracted still shows manual changes from when we last extracted
So we should keep both comparisons and do them properly:
"Source → Extracted": Compare source files with extracted files
"Runtime → Extracted": For normal files, compare container files with extracted files. For generated files (like alertmanager.yml), compare what would be generated from options.json with extracted files.


