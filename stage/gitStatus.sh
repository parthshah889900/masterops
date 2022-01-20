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
filename=changedfiles.txt
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

printf "%s\n" "${arrayDelete[@]}" > ../artifact/deletefiles.txt


packageChange=`git diff --name-only $lastGitCommit $lastServerCommit -- package.json`

if [ "$packageChange" = "package.json" ] || [ ! -d node_modules ]; then 
    npm install
fi

gulp default
find . -type f -not -iname '*.php' -exec cp --parents \{\} #path/#project/#branch/artifact/ \;