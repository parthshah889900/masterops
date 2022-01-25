#!/bin/sh
## http://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux
Want_To_Encrypt=$1
repo_folder_name=$2
DIRNAME=$3
CONFIRM_ENCRYPT_TYPE=$4
EXPIRE_ON=$5
branch=$6

if [ $Want_To_Encrypt = "y" ]; then
	if [ $CONFIRM_ENCRYPT_TYPE = "p" ]; then
		TEMP_DIRECTORY_NAME=tmp_dir
		PROJECT_PARTIAL_SOURCE=./projects/$DIRNAME/$branch/partial
		TEMP_DIRECTORY_SOURCE=./projects/$DIRNAME/$branch/tmp_dir

		if [ ! -d  $PROJECT_PARTIAL_SOURCE ]; then
			exit
		fi

		if [ ! -d  $TEMP_DIRECTORY_SOURCE ]; then
			mkdir $TEMP_DIRECTORY_SOURCE
		else
			if [ $TEMP_DIRECTORY_SOURCE != "" ]; then
				rm -rf $TEMP_DIRECTORY_SOURCE/*
			fi
		fi

		DELETE_EXCLUDE_DIRECTORY_FILE_LIST=`cat script_files/exclude_file_list_cmd`
		# STRING_LENGTH=${#DELETE_EXCLUDE_DIRECTORY_FILE_LIST}
		cd $PROJECT_PARTIAL_SOURCE
		find . -type d -name ".svn" -exec rm -rf {} \; 2>/dev/null
		find * -name '*.php' -exec cp --parents \{\} ../$TEMP_DIRECTORY_NAME/ \; 2>/dev/null
		if [  -f ../$TEMP_DIRECTORY_NAME/templates/include/macros.php ]; then
			rm ../$TEMP_DIRECTORY_NAME/templates/include/macros.php
		fi

		# delete standard directory which needs to ignore during encoding

		# if [  $STRING_LENGTH > 0 ]; then
		cd ../$TEMP_DIRECTORY_NAME
		rm -rf $DELETE_EXCLUDE_DIRECTORY_FILE_LIST
		# fi

		# Move to root folder directory
		cd ../../../..

		if [ $EXPIRE_ON = "NEVER" ]; then
			EXPIRYDATE='2035-12-30'
		else
			EXPIRYDATE=$EXPIRE_ON
		fi
		/usr/local/ioncube10/ioncube_encoder5_10.2/bin/ioncube_encoder72_10.2_64 --binary --merge-target --ignore-deprecated-warnings --ignore-strict-warnings --add-comment "Software written by OnPrintShop Team" --message-if-no-loader "'No Loader is installed. Please contact support.'" --expire-on $EXPIRYDATE $TEMP_DIRECTORY_SOURCE/* --into $PROJECT_PARTIAL_SOURCE/ 
		cd $PROJECT_PARTIAL_SOURCE
		find * -name '*.php' -exec cp --parents \{\} ../artifact/ \;
		cd ..
	        rm -rf partial
        	mkdir partial
		exit
	fi
	if [ $CONFIRM_ENCRYPT_TYPE != "f" ]; then
		exit
	fi

	if [ $CONFIRM_ENCRYPT_TYPE = "f" ]; then
		TEMP_DIRECTORY_NAME=tmp_dir
		PROJECT_FULL_SOURCE=./projects/$DIRNAME/$branch/full
		TEMP_DIRECTORY_SOURCE=./projects/$DIRNAME/$branch/tmp_dir

		cd ./projects/$DIRNAME/$branch/$repo_folder_name
		find * -name '*.php' -exec cp --parents \{\} ../full/ \;
		
		cd
		COPY_DIRECTORY_FILE_LIST=`cat script_files/encode_file_list_cmd`

		cd $PROJECT_FULL_SOURCE
		find . -type d -name ".svn" -exec rm -rf {} \; 2>/dev/null
		find $COPY_DIRECTORY_FILE_LIST -name '*.php' -exec cp --parents \{\} ../$TEMP_DIRECTORY_NAME/ \; 2>/dev/null
		
		if [  -f ../$TEMP_DIRECTORY_NAME/templates/include/macros.php ]; then
			rm ../$TEMP_DIRECTORY_NAME/templates/include/macros.php
		fi
		cd ../../../..



		if [ $EXPIRE_ON = "NEVER" ]; then
			EXPIRYDATE='2035-12-30'
		else
			EXPIRYDATE=$EXPIRE_ON
		fi

		/usr/local/ioncube10/ioncube_encoder5_10.2/bin/ioncube_encoder72_10.2_64 --binary --merge-target --ignore-deprecated-warnings --ignore-strict-warnings --add-comment "Software written by OnPrintShop Team" --message-if-no-loader "'No Loader is installed. Please contact support.'" --expire-on $EXPIRYDATE $TEMP_DIRECTORY_SOURCE/* --into $PROJECT_FULL_SOURCE/
		cd $PROJECT_FULL_SOURCE
		find * -name '*.php' -exec cp --parent \{\} ../artifact/ \;
		
		cd ..
        rm -rf full
        mkdir full
	fi
fi

if [ $Want_To_Encrypt = "n" ]; then
	TEMP_DIRECTORY_NAME=tmp_dir
	PROJECT_PARTIAL_SOURCE=./projects/$DIRNAME/$branch/partial
	TEMP_DIRECTORY_SOURCE=./projects/$DIRNAME/$branch/tmp_dir

	if [ ! -d  $PROJECT_PARTIAL_SOURCE ]; then
		exit
	fi

	if [ ! -d  $TEMP_DIRECTORY_SOURCE ]; then
		mkdir $TEMP_DIRECTORY_SOURCE
	else
		if [ $TEMP_DIRECTORY_SOURCE != "" ]; then
			rm -rf $TEMP_DIRECTORY_SOURCE/*
		fi
	fi

	cd $PROJECT_PARTIAL_SOURCE
	find * -name '*.php' -exec cp --parents \{\} ../artifact/ \;
	cd ..
	rm -rf partial
	mkdir partial
	exit
fi
