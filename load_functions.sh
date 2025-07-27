#!/bin/bash

# Load functions in the pipeline from the workspace directory
if [ -d ./tooling/functions ]; then
	for file in ./tooling/functions/*.sh; do
        source $file
	done
fi