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

magnet:?xt=urn:btih:8249D9707969D0D0B0667E9866A535393322A174&dn=Veldspar-Ubuntu-Swift-v0.0.3.zip&tr=udp%3a%2f%2fpublic.popcorn-tracker.org%3a6969%2fannounce&tr=http%3a%2f%2f182.176.139.129%3a6969%2fannounce&tr=http%3a%2f%2f5.79.83.193%3a2710%2fannounce&tr=http%3a%2f%2f91.218.230.81%3a6969%2fannounce&tr=udp%3a%2f%2ftracker.ilibr.org%3a80%2fannounce&tr=http%3a%2f%2fatrack.pow7.com%2fannounce&tr=http%3a%2f%2fbt.henbt.com%3a2710%2fannounce&tr=http%3a%2f%2fmgtracker.org%3a2710%2fannounce&tr=http%3a%2f%2fmgtracker.org%3a6969%2fannounce&tr=http%3a%2f%2fopen.touki.ru%2fannounce.php&tr=http%3a%2f%2fp4p.arenabg.ch%3a1337%2fannounce&tr=http%3a%2f%2fpow7.com%3a80%2fannounce&tr=http%3a%2f%2fretracker.krs-ix.ru%3a80%2fannounce&tr=http%3a%2f%2fsecure.pow7.com%2fannounce&tr=http%3a%2f%2ft1.pow7.com%2fannounce&tr=http%3a%2f%2ft2.pow7.com%2fannounce&tr=http%3a%2f%2fthetracker.org%3a80%2fannounce&tr=http%3a%2f%2ftorrentsmd.com%3a8080%2fannounce&tr=http%3a%2f%2ftracker.bittor.pw%3a1337%2fannounce&tr=http%3a%2f%2ftracker.dutchtracking.com%3a80%2fannounce&tr=http%3a%2f%2ftracker.dutchtracking.nl%3a80%2fannounce&tr=http%3a%2f%2ftracker.edoardocolombo.eu%3a6969%2fannounce&tr=http%3a%2f%2ftracker.ex.ua%3a80%2fannounce&tr=http%3a%2f%2ftracker.kicks-ass.net%3a80%2fannounce&tr=http%3a%2f%2ftracker1.wasabii.com.tw%3a6969%2fannounce&tr=http%3a%2f%2ftracker2.itzmx.com%3a6961%2fannounce&tr=http%3a%2f%2fwww.wareztorrent.com%3a80%2fannounce&tr=udp%3a%2f%2f62.138.0.158%3a6969%2fannounce&tr=udp%3a%2f%2feddie4.nl%3a6969%2fannounce&tr=udp%3a%2f%2fexplodie.org%3a6969%2fannounce&tr=udp%3a%2f%2fshadowshq.eddie4.nl%3a6969%2fannounce&tr=udp%3a%2f%2fshadowshq.yi.org%3a6969%2fannounce&tr=udp%3a%2f%2ftracker.eddie4.nl%3a6969%2fannounce&tr=udp%3a%2f%2ftracker.mg64.net%3a2710%2fannounce&tr=udp%3a%2f%2ftracker.sktorrent.net%3a6969&tr=udp%3a%2f%2ftracker2.indowebster.com%3a6969%2fannounce&tr=udp%3a%2f%2ftracker4.piratux.com%3a6969%2fannounce&tr=http%3a%2f%2fatrack.pow7.com%2fannounce&tr=http%3a%2f%2fbt.henbt.com%3a2710%2fannounce&tr=http%3a%2f%2fmgtracker.org%3

Username: veldspar
Password: Veldspar1 

* please change the password if exposing to the internet


