#!/bin/bash

for dir in infra; do
	cd $dir
	echo "performing 'terraform init and validate' for $dir"
	terraform init
	terraform validate
	cd ..
done
