#!/bin/bash
cd #path

path=projects/#project
if [ ! -d "$path" ]; then
	TEMP_DIRECTORY_NAME=tmp_dir
	PROJECT_FULL_SOURCE=#project/#branch/full
	PROJECT_PARTIAL_SOURCE=#project/#branch/partial
	TEMP_DIRECTORY_SOURCE=#project/#branch/$TEMP_DIRECTORY_NAME


	mkdir #project
	mkdir #project/#branch
	mkdir $PROJECT_FULL_SOURCE
	mkdir $PROJECT_PARTIAL_SOURCE
	mkdir $TEMP_DIRECTORY_SOURCE
	mkdir #project/#branch/artifact


	cd #project/#branch
	git clone #git_url

	cd #repo
	git checkout #branch
fi

if [ -d "$path" ]; then
	if [ ! -d #path/#project/#branch ]; then
		TEMP_DIRECTORY_NAME=tmp_dir
		PROJECT_FULL_SOURCE=#project/#branch/full
		PROJECT_PARTIAL_SOURCE=#project/#branch/partial
		TEMP_DIRECTORY_SOURCE=#project/#branch/$TEMP_DIRECTORY_NAME


		
		mkdir #project/#branch
		mkdir $PROJECT_FULL_SOURCE
		mkdir $PROJECT_PARTIAL_SOURCE
		mkdir $TEMP_DIRECTORY_SOURCE
		mkdir #project/#branch/artifact


		cd #project/#branch
		git clone #git_url

		cd #repo
		git checkout #branch
	fi
fi
