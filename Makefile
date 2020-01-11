# Version 0.2.0

all: versions init benchmarks



versions:
	pxi --version
	#
	gawk --version | head -1
	#
	jq --version
	#
	mlr --version
	#
	-fx --version
	#



init: data/2019-small.jsonl data/2019-big.jsonl data/2019-small.csv data/2019-big.csv

data/2019-small.jsonl:
	#
	# Initializing data files. This is done only once and may take a while!
	#
	mkdir -p data
	touch data/2019-small.jsonl
	for ((i=1546300800;i<=1577836799;i++)); do printf '{"time":%d}\n' $$i >> data/2019-small.jsonl; done

data/2019-big.jsonl: data/2019-small.jsonl
	pxi "({time}) => { const d = new Date(time * 1000); return {time, year: d.getFullYear(), month: d.getUTCMonth() + 1, day: d.getUTCDate(), hours: d.getUTCHours(), minutes: d.getUTCMinutes(), seconds: d.getUTCSeconds()} }" < data/2019-small.jsonl > data/2019-big.jsonl

data/2019-small.csv: data/2019-small.jsonl
	pxi --to csv < data/2019-small.jsonl > data/2019-small.csv

data/2019-big.csv: data/2019-big.jsonl
	pxi --to csv < data/2019-big.jsonl > data/2019-big.csv



clean:
	rm -rf data



benchmarks: json json2csv csv csv2json



json: json-1 json-2 json-3 json-4

json-1: json-1-pxi json-1-gawk json-1-jq json-1-fx

json-1-pxi:
	#
	# json-1: Select an attribute on small JSON objects
	#
	/usr/bin/time -lp pxi 'json => json.time' < data/2019-small.jsonl > /tmp/pxi.jsonl
	#

json-1-gawk:
	/usr/bin/time -lp gawk -F ':|}' '{print $$2}' < data/2019-small.jsonl > /tmp/gawk.jsonl
	#
	diff --brief --report-identical-files /tmp/gawk.jsonl /tmp/pxi.jsonl
	#

json-1-jq:
	/usr/bin/time -lp jq '.time' < data/2019-small.jsonl > /tmp/jq.jsonl
	#
	diff --brief --report-identical-files /tmp/jq.jsonl /tmp/pxi.jsonl
	#

json-1-fx:
	/usr/bin/time -lp fx 'json => json.time' < data/2019-small.jsonl > /tmp/fx.jsonl
	#
	diff --brief --report-identical-files /tmp/fx.jsonl /tmp/pxi.jsonl
	#



json-2: json-2-pxi json-2-gawk json-2-jq json-2-fx

json-2-pxi:
	#
	# json-2: Select an attribute on large JSON objects
	#
	/usr/bin/time -lp pxi 'json => json.time' < data/2019-big.jsonl > /tmp/pxi.jsonl
	#

json-2-gawk:
	/usr/bin/time -lp gawk -F ':|,' '{print $$2}' < data/2019-big.jsonl > /tmp/gawk.jsonl
	#
	diff --brief --report-identical-files /tmp/gawk.jsonl /tmp/pxi.jsonl
	#

json-2-jq:
	/usr/bin/time -lp jq '.time' < data/2019-big.jsonl > /tmp/jq.jsonl
	#
	diff --brief --report-identical-files /tmp/jq.jsonl /tmp/pxi.jsonl
	#

json-2-fx:
	/usr/bin/time -lp fx 'json => json.time' < data/2019-big.jsonl > /tmp/fx.jsonl
	#
	diff --brief --report-identical-files /tmp/fx.jsonl /tmp/pxi.jsonl
	#



json-3: json-3-pxi json-3-gawk json-3-mlr json-3-jq json-3-fx

json-3-pxi:
	#
	# json-3: Pick a single attribute on small JSON objects
	#
	/usr/bin/time -lp pxi '({time}) => ({time})' < data/2019-small.jsonl > /tmp/pxi.jsonl
	#

json-3-gawk:
	/usr/bin/time -lp gawk -F ':|}' '{print "{\"time\":"$$2"}"}' < data/2019-small.jsonl > /tmp/gawk.jsonl
	#
	diff --brief --report-identical-files /tmp/gawk.jsonl /tmp/pxi.jsonl
	#

json-3-mlr:
	#
	/usr/bin/time -lp mlr --json cut -f time < data/2019-small.jsonl > /tmp/mlr.jsonl
	#
	pxi < /tmp/mlr.jsonl | diff --brief --report-identical-files - /tmp/pxi.jsonl
	#

json-3-jq:
	/usr/bin/time -lp jq -c '{time:.time}' < data/2019-small.jsonl > /tmp/jq.jsonl
	#
	pxi -c jsonObj < /tmp/jq.jsonl | diff --brief --report-identical-files - /tmp/pxi.jsonl
	#

json-3-fx:
	/usr/bin/time -lp fx '({time}) => ({time})' < data/2019-small.jsonl > /tmp/fx.jsonl
	#
	pxi -c jsonObj < /tmp/fx.jsonl | diff --brief --report-identical-files - /tmp/pxi.jsonl
	#



json-4: json-4-pxi json-4-gawk json-4-mlr json-4-jq json-4-fx

json-4-pxi:
	#
	# json-4: Pick a single attribute on large JSON objects
	#
	/usr/bin/time -lp pxi '({time}) => ({time})' < data/2019-big.jsonl > /tmp/pxi.jsonl
	#

json-4-gawk:
	/usr/bin/time -lp gawk -F ':|,' '{print "{\"time\":"$$2"}"}' < data/2019-big.jsonl > /tmp/gawk.jsonl
	#
	diff --brief --report-identical-files /tmp/gawk.jsonl /tmp/pxi.jsonl
	#

json-4-mlr:
	#
	# For reasons unknown to me, mlr fails without error on the whole input file.
	# This is why 20,000,000 lines are processed first, followed by the remaining lines.
	#
	head -20000000 data/2019-big.jsonl | /usr/bin/time -lp mlr --json cut -f time > /tmp/mlr.jsonl
	tail +20000001 data/2019-big.jsonl | /usr/bin/time -lp mlr --json cut -f time >> /tmp/mlr.jsonl
	#
	pxi < /tmp/mlr.jsonl | diff --brief --report-identical-files - /tmp/pxi.jsonl
	#

json-4-jq:
	/usr/bin/time -lp jq -c '{time:.time}' < data/2019-big.jsonl > /tmp/jq.jsonl
	#
	pxi -c jsonObj < /tmp/jq.jsonl | diff --brief --report-identical-files - /tmp/pxi.jsonl
	#

json-4-fx:
	/usr/bin/time -lp fx '({time}) => ({time})' < data/2019-big.jsonl > /tmp/fx.jsonl
	#
	pxi -c jsonObj < /tmp/fx.jsonl | diff --brief --report-identical-files - /tmp/pxi.jsonl
	#



json2csv: json2csv-1 json2csv-2

json2csv-1: json2csv-1-pxi json2csv-1-mlr json2csv-1-jq

json2csv-1-pxi:
	#
	# json2csv-1: Convert a small JSON to CSV format
	#
	/usr/bin/time -lp pxi --to csv < data/2019-small.jsonl > /tmp/pxi.csv
	#

json2csv-1-mlr:
	#
	/usr/bin/time -lp mlr --j2c filter 'true' < data/2019-small.jsonl > /tmp/mlr.csv
	#
	diff --brief --report-identical-files /tmp/mlr.csv /tmp/pxi.csv
	#

json2csv-1-jq:
	/usr/bin/time -lp jq -r '[.[]] | @csv' < data/2019-small.jsonl > /tmp/jq.csv
	#
	tail +2 /tmp/pxi.csv | diff --brief --report-identical-files - /tmp/jq.csv
	#



json2csv-2: json2csv-2-pxi json2csv-2-mlr json2csv-2-jq

json2csv-2-pxi:
	#
	# json2csv-2: Convert a large JSON to CSV format
	#
	/usr/bin/time -lp pxi --to csv < data/2019-big.jsonl > /tmp/pxi.csv
	#

json2csv-2-mlr:
	#
	# For reasons unknown to me, mlr fails without error on the whole input file.
	# This is why 20,000,000 lines are processed first, followed by the remaining lines.
	#
	head -20000000 data/2019-big.jsonl | /usr/bin/time -lp mlr --j2c filter 'true' > /tmp/mlr.csv
	tail +20000001 data/2019-big.jsonl | /usr/bin/time -lp mlr --headerless-csv-output --j2c filter 'true' >> /tmp/mlr.csv
	#
	diff --brief --report-identical-files /tmp/mlr.csv /tmp/pxi.csv
	#

json2csv-2-jq:
	/usr/bin/time -lp jq -r '[.[]] | @csv' < data/2019-big.jsonl > /tmp/jq.csv
	#
	tail +2 /tmp/pxi.csv | diff --brief --report-identical-files - /tmp/jq.csv
	#



csv: csv-1 csv-2

csv-1: csv-1-pxi csv-1-jq csv-1-gawk csv-1-mlr

csv-1-pxi:
	#
	# csv-1: Select a column from a small csv file
	#
	/usr/bin/time -lp pxi '({time}) => ({time})' --from csv --to csv < data/2019-small.csv > /tmp/pxi.csv
	#

csv-1-mlr:
	/usr/bin/time -lp mlr --csv --rs '\n' --fs , cut -f time < data/2019-small.csv > /tmp/mlr.csv
	#
	diff --brief --report-identical-files /tmp/mlr.csv /tmp/pxi.csv
	#

csv-1-gawk:
	/usr/bin/time -lp gawk -F , '{print $$1}' < data/2019-small.csv > /tmp/gawk.csv
	#
	diff --brief --report-identical-files /tmp/gawk.csv /tmp/pxi.csv
	#

csv-1-jq:
	/usr/bin/time -lp jq -crR 'split(",") | .[0]' < data/2019-small.csv > /tmp/jq.csv
	#
	diff --brief --report-identical-files /tmp/jq.csv /tmp/pxi.csv
	#



csv-2: csv-2-pxi csv-2-jq csv-2-gawk csv-2-mlr

csv-2-pxi:
	#
	# csv-2: Select a column from a large csv file
	#
	/usr/bin/time -lp pxi '({month}) => ({month})' --from csv --to csv < data/2019-big.csv > /tmp/pxi.csv
	#

csv-2-mlr:
	/usr/bin/time -lp mlr --csv --rs '\n' --fs , cut -f month < data/2019-big.csv > /tmp/mlr.csv
	#
	diff --brief --report-identical-files /tmp/mlr.csv /tmp/pxi.csv
	#

csv-2-gawk:
	/usr/bin/time -lp gawk -F , '{print $$3}' < data/2019-big.csv > /tmp/gawk.csv
	#
	diff --brief --report-identical-files /tmp/gawk.csv /tmp/pxi.csv
	#

csv-2-jq:
	/usr/bin/time -lp jq -crR 'split(",") | .[2]' < data/2019-big.csv > /tmp/jq.csv
	#
	diff --brief --report-identical-files /tmp/jq.csv /tmp/pxi.csv
	#



csv2json: csv2json-1 csv2json-2

csv2json-1: csv2json-1-pxi csv2json-1-mlr

csv2json-1-pxi:
	#
	# csv2json-1: Convert a small CSV to JSON format
	#
	/usr/bin/time -lp pxi --from csv < data/2019-small.csv > /tmp/pxi.jsonl
	#

csv2json-1-mlr:
	#
	/usr/bin/time -lp mlr --c2j filter 'true' < data/2019-small.csv > /tmp/mlr.jsonl
	#
	pxi '({time}) => ({time: time.toString()})' < /tmp/mlr.jsonl | diff --brief --report-identical-files /tmp/pxi.jsonl -
	#



csv2json-2: csv2json-2-pxi csv2json-2-mlr

csv2json-2-pxi:
	#
	# csv2json-2: Convert a large CSV to JSON format
	#
	/usr/bin/time -lp pxi --from csv < data/2019-big.csv > /tmp/pxi.jsonl
	#

csv2json-2-mlr:
	#
	/usr/bin/time -lp mlr --c2j filter 'true' < data/2019-big.csv > /tmp/mlr.jsonl
	#
	pxi 'json => Object.keys(json).reduce((o, k) => ({...o, [k]: json[k].toString()}), {})' < /tmp/mlr.jsonl | diff --brief --report-identical-files /tmp/pxi.jsonl -
	#




ssv: ssv-1

ssv-1: ssv-1-desc ssv-1-pxi ssv-1-gawk ssv-1-diff

ssv-1-desc:
	#
	# ssv-1: 
	#