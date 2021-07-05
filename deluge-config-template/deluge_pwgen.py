#!/usr/bin/env python3
#
# Deluge password generator
#
# Accepts a password word as a single parameter#
# Returns string in the format of <salt>:<sha1 password hash>
#
# The existing piece of code has been reused from the official repository
# https://github.com/deluge-torrent/deluge/blob/3ec23ad96bfa205c8ae23b662c6da153efbfed3a/deluge/ui/web/auth.py
#
import hashlib
import os
import sys

new_password=''

try:
    new_password=sys.argv[1]
except IndexError:
    print ("[ERROR] input parameter is empty")
    exit (1)

salt = hashlib.sha1(os.urandom(32)).hexdigest()
s = hashlib.sha1(salt.encode('utf-8'))
s.update(new_password.encode('utf8'))

print (salt+":"+s.hexdigest())
