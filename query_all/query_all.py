#!/usr/bin/env python
# -*- coding: utf-8 -*-

import psycopg2
import argparse
import shutil
import logging
import sys
import os
import re
import threading

class QueryRunner(threading.Thread):

    def __init__(self, service, query, output=None, name=None):
        threading.Thread.__init__(self)
        self.name = name
        self.service = service
        self.query = query
        self.daemon=True
        self.output=output

    def run(self):
        logging.info('Starting')
        conn = psycopg2.connect('service='+self.service)

        cursor = conn.cursor()

        outstream = sys.stdout
        if self.output:
            outstream = open(self.output, 'w')

        cursor.copy_expert('COPY ({}) TO STDOUT WITH CSV'.format(self.query), outstream)
        cursor.close()
        conn.close()
        logging.info('Finished querying')

def getargs():
    parser = argparse.ArgumentParser(description='Execute given query on multiple PostgreSQL databases')
    parser.add_argument('-c','--config', dest='config', help='Read config from this file')
    parser.add_argument('-f','--file', dest='file', help='File containing the query', required=True)
    parser.add_argument('-i','--inject', dest='inject', help='File containing the ids to inject')
    parser.add_argument('-o','--output', dest='output', help='File to write the output to')
    parser.add_argument('--loglevel', help='Set the loglevel explicitly')
    parser.add_argument('services', type=str, nargs='*', help='Run on these PostgreSQL services')

    args = parser.parse_args()

    return vars(args)

def build_query(file, inject=None):
    """Build a query that can be executed by a cursor. Injects values if provided."""

    with open(file, 'r') as f:
        lines = f.readlines()

    # Remove comments and newlines, start of headings etc
    lines = [re.sub('^(.*?)--.*$', '\1', l).strip('\n \r\x01') for l in lines]

    query = ' '.join([l for l in lines if len(l) > 0])

    ## Remove trailing semicolon
    query = query.rstrip('\n\r ;')

    ids = []
    if inject:
        logging.debug('Reading ids from file {}'.format(inject))
        with open(inject, 'r') as injectfile:
            ids = injectfile.read().splitlines()

    ids = ','.join(["'{}'".format(i) for i in ids if len(i) > 0])

    query = query.format(ids=ids)

    logging.debug('Final query is: {}'.format(query))
    return query

def main():
    args = getargs()

    loglevel = (args.get('loglevel') or 'warning').upper()
    logging.basicConfig(format='%(asctime)s - %(levelname)s - %(threadName)s - %(message)s', level=loglevel)

    logging.debug(args)

    query = build_query(file=args['file'], inject=args['inject'])

    query_runners=[QueryRunner(service=a, query=query, name=a) for a in args['services']]

    fileformat=(args['output'] or '')+'.part{}'
    index = 0
    for q in query_runners:
        if args['output'] is not None:
            q.output = fileformat.format(index)
        q.start()
        index += 1

    index -= 1

    for q in query_runners:
        q.join()

    if args['output'] is not None:
        ## Concatenate all files > 0 to 0
        zerofile = fileformat.format(0)
        with open(zerofile, 'ab') as wfd:
            while index > 0:
                sourcefile=fileformat.format(index)
                logging.debug('Concatenating file {} to file {}'.format(sourcefile, zerofile))
                with open(sourcefile, 'rb') as fd:
                    shutil.copyfileobj(fd, wfd, 1024*1024*10)
                os.remove(sourcefile)
                index -= 1

        ## Rename 0 to main file
        os.rename(zerofile, args['output'])
        logging.info('Wrote output to file {}'.format(args['output']))

if __name__ == '__main__':
    main()
