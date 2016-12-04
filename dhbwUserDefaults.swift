//
//  dhbwUserDefaults.swift
//  DHBW Stuttgart
//
//  Created by Yannik Ehlert on 18.11.16.
//  Copyright © 2016 Yannik Ehlert. All rights reserved.
//

import Foundation

extension UserDefaults {
    func set(_ value: Any?, forKey defaultName: DHBWSettingsKeys) {
        set(value, forKey: defaultName.rawValue)
    }
    func set(_ value:Bool, forKey defaultName: DHBWSettingsKeys) {
        set(value, forKey: defaultName.rawValue)
    }
    func set(_ value:Float,forKey defaultName:DHBWSettingsKeys) {
        set(value, forKey: defaultName.rawValue)
    }
    func set(_ value:Int, forKey defaultName:DHBWSettingsKeys) {
        set(value, forKey: defaultName.rawValue)
    }
    func set(_ value:Double, forKey defaultName:DHBWSettingsKeys) {
        set(value, forKey: defaultName.rawValue)
    }
    func set(_ value:URL?, forKey defaultName:DHBWSettingsKeys) {
        set(value, forKey: defaultName.rawValue)
    }
    func setValue(_ value:Any?,forKey defaultName:DHBWSettingsKeys) {
        setValue(value, forKey: defaultName.rawValue)
    }
    func array(forKey defaultName:DHBWSettingsKeys) -> [Any]? {
        return UserDefaults.def2.array(forKey: defaultName.rawValue)
    }
    
    func bool(forKey defaultName: DHBWSettingsKeys) -> Bool {
        return UserDefaults.def2.bool(forKey: defaultName.rawValue)
    }
    func data(forKey defaultName:DHBWSettingsKeys) -> Data? {
        return UserDefaults.def2.data(forKey: defaultName.rawValue)
    }
    func dictionary(forKey defaultName:DHBWSettingsKeys) -> [String:Any]? {
        return UserDefaults.def2.dictionary(forKey: defaultName.rawValue)
    }
    func float(forKey defaultName:DHBWSettingsKeys) -> Float {
        return UserDefaults.def2.float(forKey: defaultName.rawValue)
    }
    func integer(forKey defaultName:DHBWSettingsKeys) -> Int {
        return UserDefaults.def2.integer(forKey: defaultName.rawValue)
    }
    func object(forKey defaultName:DHBWSettingsKeys) -> Any? {
        return UserDefaults.def2.object(forKey: defaultName.rawValue)
    }
    func value(forKey defaultName:DHBWSettingsKeys) -> Any? {
        return UserDefaults.def2.value(forKey: defaultName.rawValue)
    }
    func stringArray(forKey defaultName: DHBWSettingsKeys) -> [String]? {
        return UserDefaults.def2.stringArray(forKey: defaultName.rawValue)
    }
    func string(forKey defaultName:DHBWSettingsKeys) -> String? {
        return UserDefaults.def2.string(forKey: defaultName.rawValue)
    }
    func double(forKey defaultName:DHBWSettingsKeys) -> Double {
        return UserDefaults.def2.double(forKey: defaultName.rawValue)
    }
    func url(forKey defaultName:DHBWSettingsKeys) -> URL? {
        return UserDefaults.def2.url(forKey: defaultName.rawValue)
    }
    func removeObject(forKey defaultName:DHBWSettingsKeys) {
        UserDefaults.def2.removeObject(forKey: defaultName.rawValue)
    }
}
