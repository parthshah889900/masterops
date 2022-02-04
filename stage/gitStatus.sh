#!/bin/bash
branch=#branch
cd #path/#project/#branch/#repo
lastServerCommit=$(git rev-parse HEAD)
git stash
git pull
lastGitCommit=$(git rev-parse HEAD)
echo $lastGitCommit
echo $lastServerCommit
echo $'\n'
echo "Files that are changes between two commits:"
echo $'\n'

#php changed files are going into the partial
git diff --name-only $lastGitCommit $lastServerCommit -- '*.php' > changedfiles.txt
git diff --name-only $lastGitCommit $lastServerCommit . ':(exclude)*.php' > changedfiles2.txt
filename=changedfiles.txt
filename2=changedfiles2.txt

declare -a myArray
declare -a arrayDelete=()

myArray=(`cat "$filename"`)
echo "${myArray[0]}"
echo "Number of file copying:"${#myArray[@]}
for (( i = 0 ; i < ${#myArray[@]} ; i++))
do
  if [ ! -e ${myArray[$i]} ]; then
    echo ${myArray[$i]}
    arrayDelete+=("${myArray[$i]}")
  else
    echo ${myArray[$i]}
    cp --parent ${myArray[$i]} ../partial/
  fi
done

declare -a myArray2
myArray2=(`cat "$filename2"`)
declare -a arrayDelete2=()
for (( i = 0 ; i < ${#myArray2[@]} ; i++))
do
  if [ ! -e ${myArray2[$i]} ]; then
    echo ${myArray2[$i]}
    arrayDelete2+=("${myArray2[$i]}")
  fi
done

if [ "$lastGitCommit" != "$lastServerCommit" ]; then
  printf "%s\n" "${arrayDelete[@]}" > ../artifact/deletefiles.txt
  printf "%s\n" "${arrayDelete2[@]}" > ../artifact/deletefiles2.txt
fi

encryptionWant=`jq -r ".deployments.${branch}.build.encryption.wantToEncrypt" devops.json`
encryptionType=`jq -r ".deployments.${branch}.build.encryption.confirmEncryptType" devops.json`
if [ "$lastGitCommit" = "$lastServerCommit" ] && [ $encryptionWant = false ] && [ $encryptionType = f ]; then
    cp -r --parent * ../partial/
fi

packageChange=`git diff --name-only $lastGitCommit $lastServerCommit -- package.json`

if [ "$packageChange" = "package.json" ] || [ ! -d node_modules ]; then 
    npm install
fi

cacheVersionNumber=`jq -r ".deployments.${branch}.build.cacheVersion | length" devops.json`

for (( i=0; i<$cacheVersionNumber; i++ ))
do
    from=$(jq ".deployments.${branch}.build.cacheVersion[$i].from" devops.json)
    from=`echo "$from" | tr -d '"'`
    to=$(jq ".deployments.${branch}.build.cacheVersion[$i].to" devops.json)
    to=`echo "$to" | tr -d '"'`
    sed -i "s/\b$from\b/$to/g" gulpfile.js/workbox/swBase.js
done

jsChange=`git diff --name-only $lastGitCommit $lastServerCommit -- '*.js'`
cssChange=`git diff --name-only $lastGitCommit $lastServerCommit -- '*.css'`

if [ "$jsChange" != "" ] || [ "$cssChange" != "" ]; then
    gulp default
    find . -name '*.map' -exec cp --parents {} #path/#project/#branch/artifact/ \;
    find . -name '*.js' -exec cp --parents {} #path/#project/#branch/artifact/ \;
    find . -name '*.css' -exec cp --parents {} #path/#project/#branch/artifact/ \;
fi



if [ $encryptionType = p ]; then
  echo "Hello"
else
  gulp default
  find . -type f -not -iname '*.php' -exec cp --parents \{\} #path/#project/#branch/artifact/ \;
fi

# ====================================================================

git diff --name-only $lastGitCommit $lastServerCommit . ':(exclude)*.php' ':(exclude)*.js' ':(exclude)*.css' >> otherFiles.txt
filename6=otherFiles.txt
declare -a myArray6
myArray6=(`cat "$filename6"`)
for (( i = 0 ; i < ${#myArray6[@]} ; i++))
do
    cp -r --parent ${myArray6[$i]} ../artifact
done
rm -rf otherFiles.txt