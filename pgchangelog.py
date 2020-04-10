#!/usr/bin/env python
"""
    Find interesting fragments in PostgreSQL changelog.
"""

import argparse
import datetime
import re
import sys
import urllib2
import csv
from bs4 import BeautifulSoup


def pg_major_version_now():
    return str(datetime.datetime.now().year - 2008)


def pg_minor_version_now(major):
    if '.' in major:
        tag = 'REL{}_STABLE'.format(major.replace('.', '_'))
    else:
        tag = 'REL_{}_STABLE'.format(major)
    url = 'https://raw.githubusercontent.com/postgres/postgres/{}/configure'.format(
        tag)
    doc = urllib2.urlopen(url)

    for line in doc:
        m = re.match("PACKAGE_VERSION='{}\.([0-9]+)'".format(major), line)
        if m:
            return int(m.group(1))


def process_changelog(major, minor=None, regex='.', args=None):
    if minor is None:
        version = major
    else:
        version = major + '.' + minor
    release_notes_url = 'https://www.postgresql.org/docs/current/static/release-{}.html'
    url = release_notes_url.format(version.replace('.', '-'))
    doc = urllib2.urlopen(url)
    soup = BeautifulSoup(doc, 'lxml')
    for p in soup.find_all(name='p', string=re.compile(regex, re.IGNORECASE)):
        emit(version, url, p.get_text(), args)


def emit(version, url, text, args):
    if args.bold:
        text = re.sub(args.regex, r'<b>\g<0></b>', text)
    if args.csv:
        cw = csv.writer(sys.stdout)
        cw.writerow([version, url, text.encode('utf-8')])
    else:  # text output
        print('=== Quote from {} ==='.format(url))
        print(text.encode('utf-8'))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--major', type=str,
                        help='Major PostgreSQL version, eg. 9.5 or 10', default=None)
    parser.add_argument('--minor', type=int,
                        help='Minor PostgreSQL version, eg. 1 or 21', default=None)
    parser.add_argument('--regex', type=str,
                        help='Search pattern', default='.')
    parser.add_argument('--bold', action='store_true',
                        help='Highlight <b>found</b> <b>terms</b>')
    parser.add_argument('--csv', action='store_true',
                        help='Generate CSV output')
    args = parser.parse_args()

    major = args.major or pg_major_version_now()

    if args.minor is None:
        process_changelog(major=major, minor=None, regex=args.regex, args=args)
        for m in range(1, pg_minor_version_now(major)):
            process_changelog(
                major=major,
                minor=str(m),
                regex=args.regex,
                args=args)
    else:
        process_changelog(
            major=major,
            minor=str(args.minor),
            regex=args.regex,
            args=args)

    sys.exit()


if __name__ == "__main__":
    main()
