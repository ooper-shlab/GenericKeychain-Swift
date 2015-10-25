//
//  DetailViewController.swift
//  GenericKeychain
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/5/9.
//
//
/*
     File: DetailViewController.h
     File: DetailViewController.m
 Abstract:
 Controller for editing text view data.

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

private let kUsernameSection = 0
private let kPasswordSection = 1
private let kAccountNumberSection = 2
private let kShowCleartextSection = 3

@objc(DetailViewController)
class DetailViewController:  UIViewController, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var textFieldController: EditorController!
    var passwordItem: KeychainItemWrapper?
    var accountNumberItem: KeychainItemWrapper?
    
    // Defined UI constants.
    private let kPasswordTag	= 2	// Tag table view cells that contain a text field to support secure text entry.
    
    class func titleForSection(section: Int) -> String? {
        switch section {
        case kUsernameSection: return NSLocalizedString("Username", comment: "")
        case kPasswordSection: return NSLocalizedString("Password", comment: "")
        case kAccountNumberSection: return NSLocalizedString("Account Number", comment: "")
        default:
            return nil
        }
    }
    
    class func secAttrForSection(section: Int) -> String? {
        switch section {
        case kUsernameSection: return kSecAttrAccount as String
        case kPasswordSection: return kSecValueData as String
        case kAccountNumberSection: return kSecValueData as String
        default:
            return nil
        }
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Title displayed by the navigation controller.
        self.title = "Keychain"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func awakeFromNib() {
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.view.backgroundColor = UIColor.groupTableViewBackgroundColor()
    }
    
    func switchAction(sender: UISwitch) {
        var cell = self.tableView.cellForRowAtIndexPath(
            NSIndexPath(forRow: 0, inSection: kPasswordSection))
        var textField = cell!.contentView.viewWithTag(kPasswordTag) as! UITextField
        textField.secureTextEntry = !sender.on
        
        cell = self.tableView.cellForRowAtIndexPath(
            NSIndexPath(forRow: 0, inSection: kAccountNumberSection))
        textField = cell!.contentView.viewWithTag(kPasswordTag) as! UITextField
        textField.secureTextEntry = !sender.on
    }
    
    // Action sheet delegate method.
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        self.actionSheetClickedButtonAtIndex(buttonIndex)
    }
    func actionSheetClickedButtonAtIndex(buttonIndex: Int) {
        // the user clicked one of the OK/Cancel buttons
        if buttonIndex == 0 {
            passwordItem?.resetKeychainItem()
            accountNumberItem?.resetKeychainItem()
            self.tableView.reloadData()
        }
    }
    
    @IBAction func resetKeychain(_: AnyObject) {
        // open a dialog with an OK and cancel button
        if #available(iOS 8.0, *) {
            let alert = UIAlertController(title: nil, message: "Reset Generic Keychain Item?", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Destructive, handler: {
                _ in self.actionSheetClickedButtonAtIndex(0)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: {
                _ in self.actionSheetClickedButtonAtIndex(1)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            let actionSheet = UIActionSheet(title: "Reset Generic Keychain Item?",
                delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: "OK")
            actionSheet.actionSheetStyle = .Default
            actionSheet.showInView(self.view)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.reloadData()
    }
    
    //MARK: -
    //MARK: <UITableViewDelegate, UITableViewDataSource> Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // 4 sections, one for each property and one for the switch
        return 4
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Only one row for each section
        return 1
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return (section == kAccountNumberSection) ? 48.0 : 0.0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return DetailViewController.titleForSection(section)
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        var title: String? = nil
        
        if section == kAccountNumberSection {
            title = NSLocalizedString("AccountNumberShared", comment: "")
        }
        
        return title
    }
    
    // Customize the appearance of table view cells.
    func tableView(aTableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let kUsernameCellIdentifier =	"UsernameCell"
        let kPasswordCellIdentifier =	"PasswordCell"
        let kSwitchCellIdentifier =	"SwitchCell"
        
        var cell: UITableViewCell? = nil
        
        switch indexPath.section {
        case kUsernameSection:
            cell = aTableView.dequeueReusableCellWithIdentifier(kUsernameCellIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .Default, reuseIdentifier: kUsernameCellIdentifier)
            }
            
            cell!.textLabel!.text = passwordItem?.objectForKey(DetailViewController.secAttrForSection(indexPath.section)!) as! String?
            cell!.accessoryType = self.editing ? .DisclosureIndicator : .None
            
        case kPasswordSection, kAccountNumberSection:
            let textField: UITextField
            
            cell = aTableView.dequeueReusableCellWithIdentifier(kPasswordCellIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .Default, reuseIdentifier: kPasswordCellIdentifier)
                
                textField = UITextField(frame: CGRectInset(cell!.contentView.bounds, 10, 10))
                textField.tag = kPasswordTag
                textField.font = UIFont.systemFontOfSize(17.0)
                
                // prevent editing
                textField.enabled = false
                
                // display contents as bullets rather than text
                textField.secureTextEntry = true
                
                cell!.contentView.addSubview(textField)
            } else {
                textField = cell!.contentView.viewWithTag(kPasswordTag) as! UITextField
            }
            
            let wrapper = (indexPath.section == kPasswordSection) ? passwordItem : accountNumberItem
            textField.text = wrapper!.objectForKey(DetailViewController.secAttrForSection(indexPath.section)!) as! String?
            cell!.accessoryType = self.editing ? .DisclosureIndicator : .None
            
        case kShowCleartextSection:
            cell = aTableView.dequeueReusableCellWithIdentifier(kSwitchCellIdentifier)
            if cell == nil {
                cell = UITableViewCell(style: .Default, reuseIdentifier: kSwitchCellIdentifier)
                
                cell!.textLabel!.text = NSLocalizedString("Show Cleartext", comment: "")
                cell!.selectionStyle = .None
                
                let switchCtl = UISwitch(frame: CGRectMake(194, 8, 94, 27))
                switchCtl.addTarget(self, action: "switchAction:", forControlEvents: .ValueChanged)
                cell!.contentView.addSubview(switchCtl)
            }
            
        default:
            fatalError("invalid section value")
        }
        
        return cell!
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section != kShowCleartextSection {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            let secAttr = DetailViewController.secAttrForSection(indexPath.section)!
            textFieldController.textControl.placeholder = DetailViewController.titleForSection(indexPath.section)
            textFieldController.textControl.secureTextEntry = (indexPath.section == kPasswordSection || indexPath.section == kAccountNumberSection)
            if (indexPath.section == kUsernameSection || indexPath.section == kPasswordSection) {
                textFieldController.keychainItemWrapper = passwordItem
            } else {
                textFieldController.keychainItemWrapper = accountNumberItem
            }
            textFieldController.textValue = textFieldController.keychainItemWrapper.objectForKey(secAttr) as! String?
            textFieldController.editedFieldKey = secAttr
            textFieldController.title = DetailViewController.titleForSection(indexPath.section)
            
            self.navigationController?.pushViewController(textFieldController, animated: true)
        }
    }
    
}