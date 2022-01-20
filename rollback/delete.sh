#!/bin/bash
cd #livepath/#proj/#change/public_html

if [ -d "vendor" ] && [ -d "images" ]; then
    find . -maxdepth 1 ! -name "vendor" ! -name "images" ! -name "." ! -name "localconfig" ! -name "robots.txt" ! -name "sitemap.xml" ! -name "cache" -exec rm -rf {} \;
fi
