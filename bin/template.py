#! /usr/bin/env python
import jinja2
import sys
import re
import os


KEY_REGEX = re.compile('([A-Z]+)=(\w+)')


def main():
    args = sys.argv[1:]
    if len(args) < 1:
        raise Exception('args too short {}'.format(args))

    template_file = args[0]
    keyword_args = args[1:]

    if not os.path.exists(template_file):
        raise Exception('File {} does not exist'.format(template_file))

    context = {}
    for arg in keyword_args:
        match = KEY_REGEX.match(arg)
        if match:
            (key, val) = match.groups()
            context[key] = val

    with open(template_file, 'r') as reader:
        text = reader.read()
        print jinja2.Template(text).render(context)


if __name__ == '__main__':
    main()
