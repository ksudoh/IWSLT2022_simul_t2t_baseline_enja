#!/usr/bin/env python3

import sys
from xml.sax.saxutils import unescape

for line in sys.stdin:
    print ( unescape (line.rstrip("\r\n")) )
