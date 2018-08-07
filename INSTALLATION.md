# Veldspar - Installation

## Currently Ubuntu 16.04.5 only (probably works on others!):

### Pre-requisits

The following modules:
clang,libicu-dev,libcurl3,libssl-dev,sqlite3,libsqlite3-dev,libcurl3-dev,uuid-dev,libpython-dev,git

```
#linux-swift-install
sudo apt-get -y update
sudo apt-get -y upgrade
sudo apt-get -y install clang libicu-dev libcurl3 libssl-dev sqlite3 libsqlite3-dev libcurl3-dev uuid-dev libpython-dev git
```



Swift 4.1.3 from swift.org.
https://swift.org/builds/swift-4.1.3-release/ubuntu1604/swift-4.1.3-RELEASE/swift-4.1.3-RELEASE-ubuntu16.04.tar.gz

The following script downloads Swift and jams it into /usr.  Best done on a sandbox VM.  
```
cd ~/
wget https://swift.org/builds/swift-4.1.3-release/ubuntu1604/swift-4.1.3-RELEASE/swift-4.1.3-RELEASE-ubuntu16.04.tar.gz
tar -xvf swift-4.1.3-RELEASE-ubuntu16.04.tar.gz
cd swift-4.1.3-RELEASE-ubuntu16.04
sudo cp -R usr/* /usr
cd ~/
rm -rf swift-4.1.3-RELEASE-ubuntu16.04
rm swift-4.1.3-RELEASE-ubuntu16.04.tar.gz
```

Clone Veldspar, build it, and stuff it into the ~/.Veldspar directory.
```
cd ~/
git clone https://github.com/editfmah/veldspar.git
cd veldspar

swift build -c release
mkdir ~/.Veldspar

cd .build
cd release

cp veldspard ~/.Veldspar/veldspard
cp miner ~/.Veldspar/miner
cp simplewallet ~/.Veldspar/simplewallet
```

# Or ......

Download a virtualbox image with swift and Veldspar already built and ready to go.

magnet:?xt=urn:btih:BCDE8B5895FF580D66F615A54BBB467B9DA1FB8B&dn=Veldspar-Ubuntu-Swift-v0.0.5.zip&tr=udp%3a%2f%2ftracker.coppersurfer.tk%3a6969%2fannounce&tr=udp%3a%2f%2ftracker.open-internet.nl%3a6969%2fannounce&tr=udp%3a%2f%2fexodus.desync.com%3a6969%2fannounce&tr=udp%3a%2f%2ftracker.opentrackr.org%3a1337%2fannounce&tr=udp%3a%2f%2ftracker.internetwarriors.net%3a1337%2fannounce&tr=udp%3a%2f%2f9.rarbg.to%3a2710%2fannounce&tr=udp%3a%2f%2fpublic.popcorn-tracker.org%3a6969%2fannounce

Username: veldspar
Password: Veldspar1 

* please change the password if exposing to the internet


