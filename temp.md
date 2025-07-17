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

The script is meant to report no changes if no manual changes happended. But any manual change to any of the three versions (source, runtime, extracted) has to be reported.

## prom2influx

I want to change this addon in the following way

- prometheus shall be replaced by influxdb open source 2.x (newest version of 2)
- alertmanager shall be replaced by grafana alerting <https://grafana.com/docs/grafana/latest/alerting/>
- All the prometheus related stuff shall go away and be totally removed from the code
  - Prometheus
  - Karma
  - Alertmanager
  - Blackbox exporter

All other functionality shall be corresponding to the old behaviour. so for example

- The Web UI of influxdb shall be in the index.html


ETX
