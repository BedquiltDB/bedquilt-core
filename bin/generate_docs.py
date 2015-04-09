#! /usr/bin/env python

import string
import inspect
import pybedquilt
import os
import re
from pprint import pprint


TARGET_FILE_PATH = 'docs/api_docs.md'
SOURCE_FILE_PATH = 'sql/bedquilt.sql'
MAGIC_LINE = '---- ---- ---- ----'


FUNCTION_NAME_REGEX = 'FUNCTION ([a-z_]+)\('
LANGUAGE_REGEX = 'LANGUAGE ([a-z]+)'
RETURNS_REGEX = 'RETURNS ([a-z\s]+) AS'
PARAMS_REGEX = 'FUNCTION [a-z_]+\(([a-z_, ]+)'

def main():
    # BedquiltClient
    with open(SOURCE_FILE_PATH, 'r') as source_file:
        source = source_file.read()

    source_blocks = blocks(source)
    function_blocks = []

    for block in source_blocks:
        if 'CREATE OR REPLACE FUNCTION' in block and '-- #' not in block:
            function_blocks.append(block)

    details = [parse(x) for x in function_blocks]

    pprint(details)



    return

    final_string = (
"""

## BedquiltClient

{}

## BedquiltCollection

{}

""".format(
    "\n".join(map(to_md, client_docs)),
    "\n".join(map(to_md, collection_docs))
)
    )

    contents = None
    with open(TARGET_FILE_PATH, 'r') as target:
        contents = target.readlines()

    final_contents = []
    for line in contents:
        if line.strip() != MAGIC_LINE.strip():
            final_contents.append(line)
        else:
            final_contents.append(MAGIC_LINE)
            final_contents.append('\n')
            break

    for line in final_string.splitlines():
        final_contents.append(line)
        final_contents.append('\n')

    with open(TARGET_FILE_PATH, 'w') as target:
        target.writelines(final_contents)


# Helpers
def md_escape(st):
    return st.replace('_', '\_')


def blocks(st):
    return re.split('\n{3,}', st)



def get_re(exp, st):
    result = None
    r = re.search(exp, st)
    if r:
        g = r.groups()
        if g:
            result = g[0]
    return result


def parse(st):

    function_name = get_re(FUNCTION_NAME_REGEX, st)
    language = get_re(LANGUAGE_REGEX, st)
    return_type = get_re(RETURNS_REGEX, st)
    params_string = get_re(PARAMS_REGEX, st)
    params = None
    if params_string:
        params = params_string.split(', ')
        params = [param.split(' ') for param in params]

    return {
        'name': function_name,
        'language': language,
        'params': params,
        'returns': return_type
    }


def to_md(doc):
    return (
"""

### {}

```
{}
```
""".format(md_escape(doc['name']), doc['docstring'])
    )


# Run if main
if __name__ == '__main__':
    main()
