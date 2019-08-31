//
//  ViewController.swift
//  STIG Checker
//
//  Created by Gendler, Bob (Fed) on 8/22/19.
//  Copyright © 2019 Gendler, Bob (Fed). All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet var prefsTableView: NSTableView!
    @IBOutlet var dropView: DropView!
    @IBOutlet var lookupButton: NSButton!
    @IBOutlet var prefDomainField: NSTextField!
    @IBOutlet var prefKeyField: NSTextField!
    
    var prefCheck = PrefClass()
    
    var preference: [[String:String?]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dropView.delegate = self
        self.prefsTableView.delegate = self
        self.prefsTableView.dataSource = self
        
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func processPrefs(fileURL: String) {
        preference.removeAll()
        do {
            let contents = try NSString(contentsOfFile: fileURL, encoding: String.Encoding.utf8.rawValue)
            let parsedCSV: [[String]] = contents.components(separatedBy: "\n").map{ $0.components(separatedBy: ",") }
            
            for entry in parsedCSV {
                let result = prefCheck.prefCheck(domain: entry[0], key: entry[1])
                switch result.managed {
                case .Managed:
                    preference.append([
                        "Managed" : "Managed",
                        "Domain" : result.domain,
                        "Key" : result.key,
                        "Value" : result.value ?? "not right",
                        "Location" : nil
                        ])
                case .NotManaged:
                    preference.append([
                        "Managed" : "Not Managed",
                        "Domain" : result.domain,
                        "Key" : result.key,
                        "Value" : result.value,
                        "Location" : result.location!
                        ])
                case .NotFound:
                    preference.append([
                        "Managed" : "Not found or Set",
                        "Domain" : result.domain,
                        "Key": result.key,
                        "Value" : result.value,
                        "Location" : nil
                        ])
                }
            }
        } catch {
            //error
        }
        prefsTableView.reloadData()
    }
    
    func flatten(_ array: [Any]) -> [Any] {
        
        return array.reduce([Any]()) { result, current in
            switch current {
            case(let arrayOfAny as [Any]):
                return result + flatten(arrayOfAny)
            default:
                return result + [current]
            }
        }
    }
    
    
    @IBAction func lookupAction(_ sender: Any) {
        preference.removeAll()
        
        if prefKeyField.stringValue == "*" {
            let optionsArray = [(prefDomainField.stringValue as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost),
                                (prefDomainField.stringValue as CFString, kCFPreferencesAnyUser, kCFPreferencesAnyHost),
                                (prefDomainField.stringValue as CFString, kCFPreferencesCurrentUser, kCFPreferencesCurrentHost),
                                (prefDomainField.stringValue as CFString, kCFPreferencesAnyUser, kCFPreferencesCurrentHost)]
            let keys = optionsArray.compactMap { (opt1, opt2, opt3) in return CFPreferencesCopyKeyList(opt1, opt2, opt3) }
            let array_temp = flatten(keys)
            let array = array_temp as! [String]
            for key in array {
                let result = prefCheck.prefCheck(domain: prefDomainField.stringValue, key: key as! String)
                switch result.managed {
                case .Managed:
                    preference.append([
                        "Managed" : "Managed",
                        "Domain" : result.domain,
                        "Key" : result.key,
                        "Value" : result.value,
                        "Location" : nil
                        ])
                case .NotManaged:
                    preference.append([
                        "Managed" : "Not Managed",
                        "Domain" : result.domain,
                        "Key" : result.key,
                        "Value" : result.value,
                        "Location" : result.location
                        ])
                case .NotFound:
                    preference.append([
                        "Managed" : "Not found or set",
                        "Domain" : prefDomainField.stringValue,
                        "Key" : result.key ?? "",
                        "Value" : nil,
                        "Location" : nil
                        ])
                }
            }
        } else {
        
        if prefDomainField.stringValue == ""{
            preference.append([
                "Managed" : nil,
                "Domain" : "No preference domain specified",
                "Key" : nil,
                "Value" : nil,
                "Location" : nil
                ])
        } else {
            let result = prefCheck.prefCheck(domain: prefDomainField.stringValue, key: prefKeyField.stringValue)
            switch result.managed {
            case .Managed:
                preference.append([
                    "Managed" : "Managed",
                    "Domain" : result.domain,
                    "Key" : result.key,
                    "Value" : result.value,
                    "Location" : nil
                    ])
            case .NotManaged:
                preference.append([
                    "Managed" : "Not Managed",
                    "Domain" : result.domain,
                    "Key" : result.key,
                    "Value" : result.value,
                    "Location" : result.location
                    ])
            case .NotFound:
                if result.key == nil {
                    preference.append([
                        "Managed" : nil,
                        "Domain" : prefDomainField.stringValue,
                        "Key" : "Key not specificed",
                        "Value" : nil,
                        "Location" : nil
                        ])
                } else {
                    preference.append([
                        "Managed" : "Not found or set",
                        "Domain" : prefDomainField.stringValue,
                        "Key" : result.key ?? "",
                        "Value" : nil,
                        "Location" : nil
                        ])
                }
            }
            
        }
        }
        prefsTableView.reloadData()
    }
}

extension ViewController: DragViewDelegate {
    func dragView(didDragFileWith URL: String) {
        processPrefs(fileURL: URL)
        
    }
    
    
    
}


extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if let tableCell = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView {
            
            
            if tableColumn?.title == "Managed" {
                if let managed = preference[row]["Managed"] {
                    tableCell.textField?.stringValue = managed ?? ""
                    return tableCell
                }
            }
            if tableColumn?.title == "Domain" {
                if let domain = preference[row]["Domain"] {
                    tableCell.textField?.stringValue = domain ?? ""
                    return tableCell
                }
            }
            if tableColumn?.title == "Key" {
                if let key = preference[row]["Key"] {
                    tableCell.textField?.stringValue = key ?? ""
                    return tableCell
                }
            }
            if tableColumn?.title == "Value" {
                if let value = preference[row]["Value"] {
                    tableCell.textField?.stringValue = value ?? ""
                    return tableCell
                    
                    
                }
            }
            if tableColumn?.title == "Location" {
                if let location = preference[row]["Location"] {
                    tableCell.textField?.stringValue = location ?? ""
                    
                    return tableCell
                    
                }
            }
            
        }
        return nil
    }
}

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return preference.count
    }
    
}
