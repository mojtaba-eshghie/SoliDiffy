#!/bin/bash

# Function to display default options
show_default_options() {
    echo "No command given."
    echo "Available Options:"
    echo "-C <2>  Set system property (-c property value)."
    echo "-v      Verbose mode"
    echo "--help  Display help (this screen)."
    echo ""
    echo "Available Commands:"
    echo "* webdiff: Web diff client"
    echo "* cluster: Extract action clusters"
    echo "* dotdiff: A dot diff client"
    echo "* htmldiff: Dump diff as HTML in stdout"
    echo "* list: List matchers, generators, clients and properties"
    echo "* parse: Parse file and dump result."
    echo "* swingdiff: A swing diff client"
    echo "* textdiff: Dump actions in a textual format."
    echo "* axmldiff: Dump annotated xml tree"
}

# Check if any parameters are provided
if [ $# -eq 0 ]; then
    show_default_options
else
    # Pass the parameters to the gumtree command
    gumtree "$@"
fi