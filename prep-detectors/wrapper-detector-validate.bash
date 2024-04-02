#!/bin/bash

for f in detectors/*.conf; do
	./detector-validate.bash $f
done; unset f

