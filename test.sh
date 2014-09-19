#!/bin/sh
targetDir="/Applications/World of Warcraft/Interface/AddOns/TabardTell/"
files="TabardTell.lua TabardTell.toc TabardTell.xml"

for f in $files 
do
diff "$targetDir"$f "src/$f"
cp -v "src/$f" "$targetDir"
done

