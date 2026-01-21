#!/bin/bash
# Wrapper script to run Antora PDF generation with correct PATH

# Add local bundle bin directory to PATH
export PATH="$PWD/vendor/bundle/ruby/3.4.0/bin:$PATH"

# Run antora with the provided arguments
exec antora "$@"
