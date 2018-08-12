//    MIT License
//
//    Copyright (c) 2018 Veldspar Team
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation
import VeldsparCore
import CryptoSwift

class WalletContainer : Codable {
    
    var wallets: [Wallet] = []
    
    class func read(filename: String, password: String) -> WalletContainer? {
        
        // read the file in
        do {
            
            // this is where we check for the old format file & old AES implementation.  It's upgraded on write out.
            let encryptedData = try Data(contentsOf: URL(fileURLWithPath: filename))
            let aes = try AES(key: String(password.sha224().prefix(16)), iv: String(password.sha224().sha224().prefix(16))) // aes128
            let decryptedData = try aes.decrypt(Array(encryptedData))
            let walletObject = try? JSONDecoder().decode(Wallet.self, from: Data(bytes: decryptedData))
            
            if walletObject != nil {
                let wallet = WalletContainer()
                wallet.wallets.append(walletObject!)
                return wallet
            }
            
        } catch  {
            
        }
        
        // read the new format file in
        do {
            
            // this is where we check for the old format file & old AES implementation.  It's upgraded on write out.
            let encryptedData = try Data(contentsOf: URL(fileURLWithPath: filename))
            let aes = try AES(key: Data(bytes: password.bytes.sha512()).prefix(32).bytes, blockMode: BlockMode.CBC(iv: Data(bytes:password.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
            let decryptedData = try aes.decrypt(Array(encryptedData))
            let walletObject = try? JSONDecoder().decode(self, from: Data(bytes: decryptedData))
            
            if walletObject != nil {
                return walletObject
            }
            
        } catch  {
            
        }
        
        return nil
        
    }
    
    func write(filename: String, password: String) {
        
//        string serializedObject = JsonConvert.SerializeObject(this);
//        using (Aes aes = Aes.Create())
//        using (SHA512 sha = SHA512.Create())
//        {
//            aes.KeySize = 256;
//            aes.Key = sha.ComputeHash(Encoding.UTF8.GetBytes(password)).Take(32).ToArray();
//
//            aes.BlockSize = 128;
//            aes.IV = sha.ComputeHash(sha.ComputeHash(Encoding.UTF8.GetBytes(password))).Take(16).ToArray();
//
//            ICryptoTransform encryptor = aes.CreateEncryptor(aes.Key, aes.IV);
//
//            using (FileStream fileStream = File.OpenWrite(filePath))
//            using (CryptoStream cryptoStream = new CryptoStream(fileStream, encryptor, CryptoStreamMode.Write))
//            using (StreamWriter streamWriter = new StreamWriter(cryptoStream))
//            {
//                streamWriter.Write(serializedObject);
//            }
//
//        }
        
        do {
            let encodedData = try? JSONEncoder().encode(self)
            if encodedData != nil {
                let aes = try AES(key: Data(bytes: password.bytes.sha512()).prefix(32).bytes, blockMode: BlockMode.CBC(iv: Data(bytes:password.bytes.sha512().sha512()).prefix(16).bytes), padding: Padding.pkcs7)
                let ciphertext = try Data(bytes: aes.encrypt(encodedData!.bytes))
                try? ciphertext.write(to: URL(fileURLWithPath: filename))
            }
        } catch {
            print("(Wallet) failed to write wallet to disk '\(error)', serious error: exiting")
            exit(0)
        }
        
    }
    
    func balance() -> Float {
        
        var balance = Float(0.0)
        
        for w in wallets {
            balance += w.balance()
        }
        
        return balance
        
    }
    
}



