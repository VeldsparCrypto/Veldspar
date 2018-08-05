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
wget https://swift.org/builds/swift-4.1.3-release/ubuntu1604/swift-4.1.3-RELEASE/swift-4.1.3-RELEASE-ubuntu16.04.tar.gz
tar -xvf swift-4.1.3-RELEASE-ubuntu16.04.tar.gz
cd swift-4.1.3-RELEASE-ubuntu16.04
cp -R usr/* /usr
cd ~/
rm -rf swift-4.1.3-RELEASE-ubuntu16.04
rm swift-4.1.3-RELEASE-ubuntu16.04.tar.gz
```

Clone Veldspar, build it, and stuff it into the ~/.Veldspar directory.
```
git clone https://github.com/editfmah/veldspar.git
cd veldspar

#swift build -c release -Xswiftc -static-stdlib
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

https://www.dropbox.com/s/7rqn4kg3qhsxwx3/VeldsparHost-Swift.zip?dl=0

