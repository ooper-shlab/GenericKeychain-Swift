//
//  KeychainItemWrapper.swift
//  GenericKeychain
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/30.
//
//
/*
     File: KeychainItemWrapper.h
     File: KeychainItemWrapper.m
 Abstract:
 Objective-C wrapper for accessing a single keychain item.

  Version: 1.2

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2010 Apple Inc. All Rights Reserved.

*/

import UIKit
import Security

/*
The KeychainItemWrapper class is an abstraction layer for the iPhone Keychain communication. It is merely a
simple wrapper to provide a distinct barrier between all the idiosyncracies involved with the Keychain
CF/NS container objects.
*/
@objc(KeychainItemWrapper)
class KeychainItemWrapper: NSObject {
    var keychainItemData: NSMutableDictionary!		// The actual keychain item data backing store.
    var genericPasswordQuery = NSMutableDictionary()	// A placeholder for the generic keychain item query used to locate the item.
    
    /*
    
    These are the default constants and their respective types,
    available for the kSecClassGenericPassword Keychain Item class:
    
    kSecAttrAccessGroup			-		CFStringRef
    kSecAttrCreationDate		-		CFDateRef
    kSecAttrModificationDate    -		CFDateRef
    kSecAttrDescription			-		CFStringRef
    kSecAttrComment				-		CFStringRef
    kSecAttrCreator				-		CFNumberRef
    kSecAttrType                -		CFNumberRef
    kSecAttrLabel				-		CFStringRef
    kSecAttrIsInvisible			-		CFBooleanRef
    kSecAttrIsNegative			-		CFBooleanRef
    kSecAttrAccount				-		CFStringRef
    kSecAttrService				-		CFStringRef
    kSecAttrGeneric				-		CFDataRef
    
    See the header file Security/SecItem.h for more details.
    
    */
    
    /*
    The decision behind the following two methods (secItemFormatToDictionary and dictionaryToSecItemFormat) was
    to encapsulate the transition between what the detail view controller was expecting (NSString *) and what the
    Keychain API expects as a validly constructed container class.
    */
    
    // Designated initializer.
    init(identifier: String, accessGroup: String?) {
        super.init()
        // Begin Keychain search setup. The genericPasswordQuery leverages the special user
        // defined attribute kSecAttrGeneric to distinguish itself between other generic Keychain
        // items which may be included by the same application.
        
        genericPasswordQuery[kSecClass as NSString] = kSecClassGenericPassword
        genericPasswordQuery[kSecAttrGeneric as NSString] = identifier
        
        // The keychain access group attribute determines if this item can be shared
        // amongst multiple apps whose code signing entitlements contain the same keychain access group.
        if accessGroup != nil {
            #if arch(i386) || arch(x86_64)
                // Ignore the access group if running on the iPhone simulator.
                //
                // Apps that are built for the simulator aren't signed, so there's no keychain access group
                // for the simulator to check. This means that all apps can see all keychain items when run
                // on the simulator.
                //
                // If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
                // simulator will return -25243 (errSecNoAccessForItem).
            #else
                genericPasswordQuery[kSecAttrAccessGroup as NSString] = accessGroup
            #endif
        }
        
        // Use the proper search constants, return only the attributes of the first match.
        genericPasswordQuery[kSecMatchLimit as NSString] = kSecMatchLimitOne
        genericPasswordQuery[kSecReturnAttributes as NSString] = kCFBooleanTrue
        
        let tempQuery = NSDictionary(dictionary: genericPasswordQuery)
        
        var outCFDictionary: AnyObject?
        var outDictionary: NSDictionary?
        
        if SecItemCopyMatching(tempQuery, &outCFDictionary) != noErr {
            // Stick these default values into keychain item if nothing found.
            self.resetKeychainItem()
            
            // Add the generic attribute and the keychain access group.
            keychainItemData[kSecAttrGeneric as NSString] = identifier
            if accessGroup != nil {
                #if arch(i386) || arch(x86_64)
                    // Ignore the access group if running on the iPhone simulator.
                    //
                    // Apps that are built for the simulator aren't signed, so there's no keychain access group
                    // for the simulator to check. This means that all apps can see all keychain items when run
                    // on the simulator.
                    //
                    // If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
                    // simulator will return -25243 (errSecNoAccessForItem).
                #else
                    keychainItemData[kSecAttrAccessGroup as NSString] = accessGroup
                #endif
            }
        } else {
            outDictionary = (outCFDictionary as! NSMutableDictionary?)
            // load the saved data from Keychain.
            self.keychainItemData = self.secItemFormatToDictionary(outDictionary)
        }
        
    }
    
    
    func setObject(inObject: AnyObject?, forKey key: NSCopying) {
        if inObject != nil {
            let currentObject: AnyObject? = keychainItemData[key]
            if currentObject !== inObject {
                keychainItemData[key] = inObject
                self.writeToKeychain()
            }
        }
    }
    
    func objectForKey(key: NSCopying) -> AnyObject? {
        return keychainItemData[key]
    }
    
    // Initializes and resets the default generic keychain item data.
    func resetKeychainItem() {
        var junk = noErr
        if keychainItemData == nil {
            self.keychainItemData = NSMutableDictionary()
        } else if keychainItemData != nil {
            let tempDictionary = self.dictionaryToSecItemFormat(keychainItemData)
            junk = SecItemDelete(tempDictionary)
            assert(junk == noErr || junk == errSecItemNotFound, "Problem deleting current dictionary.")
        }
        
        // Default attributes for keychain item.
        keychainItemData[kSecAttrAccount as NSString] = ""
        keychainItemData[kSecAttrLabel as NSString] = ""
        keychainItemData[kSecAttrDescription as NSString] = ""
        
        // Default data for keychain item.
        keychainItemData[kSecValueData as NSString] = ""
    }
    
    private func dictionaryToSecItemFormat(dictionaryToConvert: NSDictionary) -> NSMutableDictionary {
        // The assumption is that this method will be called with a properly populated dictionary
        // containing all the right key/value pairs for a SecItem.
        
        // Create a dictionary to return populated with the attributes and data.
        let returnDictionary = NSMutableDictionary(dictionary: dictionaryToConvert)
        
        // Add the Generic Password keychain item class attribute.
        returnDictionary[kSecClass as NSString] = kSecClassGenericPassword
        
        // Convert the NSString to NSData to meet the requirements for the value type kSecValueData.
        // This is where to store sensitive data that should be encrypted.
        let passwordString = dictionaryToConvert[kSecValueData as NSString] as! String?
        returnDictionary[kSecValueData as NSString] = passwordString?.dataUsingEncoding(NSUTF8StringEncoding)
        
        return returnDictionary
    }
    
    private func secItemFormatToDictionary(var dictionaryToConvert: NSDictionary?) -> NSMutableDictionary {
        // The assumption is that this method will be called with a properly populated dictionary
        // containing all the right key/value pairs for the UI element.
        
        // Create a dictionary to return populated with the attributes and data.
        if dictionaryToConvert == nil { dictionaryToConvert = NSDictionary() }
        let returnDictionary = NSMutableDictionary(dictionary: dictionaryToConvert!)
        
        // Add the proper search key and class attribute.
        returnDictionary[kSecReturnData as NSString] = kCFBooleanTrue
        returnDictionary[kSecClass as NSString] = kSecClassGenericPassword
        
        // Acquire the password data from the attributes.
        var passwordCFData: AnyObject?
        var passwordData: NSData?
        if SecItemCopyMatching(returnDictionary, &passwordCFData) == noErr {
            passwordData = (passwordCFData as! NSData?)
            // Remove the search, class, and identifier key/value, we don't need them anymore.
            returnDictionary.removeObjectForKey(kSecReturnData)
            
            // Add the password to the dictionary, converting from NSData to NSString.
            let password = NSString(bytes: passwordData!.bytes, length: passwordData!.length,
                encoding: NSUTF8StringEncoding)
            returnDictionary[kSecValueData as NSString] = password
        } else {
            // Don't do anything if nothing is found.
            assert(false, "Serious error, no matching item found in the keychain.\n")
        }
        
        
        return returnDictionary
    }
    
    // Updates the item in the keychain, or adds it if it doesn't exist.
    private func writeToKeychain() {
        var cfAttributes: AnyObject?
        var attributes: NSDictionary?
        var result: OSStatus = noErr
        
        if SecItemCopyMatching(genericPasswordQuery, &cfAttributes) == noErr {
            attributes = cfAttributes as! NSDictionary?
            // First we need the attributes from the Keychain.
            if attributes == nil { attributes = NSDictionary() }
            let updateItem: NSMutableDictionary = NSMutableDictionary(dictionary: attributes!)
            // Second we need to add the appropriate search key/values.
            updateItem[kSecClass as NSString] = genericPasswordQuery[kSecClass as NSString]
            
            // Lastly, we need to set up the updated attribute list being careful to remove the class.
            let tempCheck = self.dictionaryToSecItemFormat(keychainItemData)
            tempCheck.removeObjectForKey(kSecClass)
            
            #if arch(i386) || arch(x86_64)
                // Remove the access group if running on the iPhone simulator.
                //
                // Apps that are built for the simulator aren't signed, so there's no keychain access group
                // for the simulator to check. This means that all apps can see all keychain items when run
                // on the simulator.
                //
                // If a SecItem contains an access group attribute, SecItemAdd and SecItemUpdate on the
                // simulator will return -25243 (errSecNoAccessForItem).
                //
                // The access group attribute will be included in items returned by SecItemCopyMatching,
                // which is why we need to remove it before updating the item.
                tempCheck.removeObjectForKey(kSecAttrAccessGroup)
            #endif
            
            // An implicit assumption is that you can only update a single item at a time.
            
            result = SecItemUpdate(updateItem, tempCheck)
            assert(result == noErr, "Couldn't update the Keychain Item.")
        } else {
            // No previous item found; add the new one.
            result = SecItemAdd(self.dictionaryToSecItemFormat(keychainItemData), nil)
            assert(result == noErr, "Couldn't add the Keychain Item.")
        }
    }
    
}