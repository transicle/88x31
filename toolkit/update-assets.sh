#!/bin/bash

git clone https://github.com/transicle/88x31-Button-Scraper
cd 88x31-Button-Scraper
pip install -r ./requirements.txt
python ./main.py
mv 88x31.tar.gz ../
cd ..
tar -xzf 88x31.tar.gz -C assets --strip-components=1
rm 88x31.tar.gz
rm -rf 88x31-Button-Scraper