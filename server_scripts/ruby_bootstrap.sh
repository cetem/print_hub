#!/bin/bash

# Load ruby env
source /usr/local/share/chruby/chruby.sh
chruby 2.1.3

ruby -r rubygems $*
