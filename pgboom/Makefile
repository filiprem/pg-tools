all: devcheck README.md

devcheck: pgboom
	autopep8 --in-place --aggressive $<
	python3 -m pylint $<

README.md: README.md.in pgboom
	perl -pe 's{__USAGE__}{qx(python3 pgboom -h)}e' < $< > $@
