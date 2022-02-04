#!/bin/bash
cd #livepath/public_html

aws s3 cp s3://#bucket-onprintshop/#change/Backup/#datetime.zip #datetime.zip
unzip -o #datetime.zip
rm -rf #datetime.zip


echo "#!/bin/bash" >> temp.sh
echo "rm -rf delete.sh" >> temp.sh
echo "rm -rf rollback.sh" >> temp.sh
echo "rm -rf appspec.yml" >> temp.sh
chmod +x temp.sh
./temp.sh