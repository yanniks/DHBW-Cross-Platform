//
//  SharedSettings.swift
//  DHBW Stuttgart
//
//  Created by Yannik Ehlert on 27.10.16.
//  Copyright © 2016 Yannik Ehlert. All rights reserved.
//
// This class is supposed to replace the def. variable as good as possible. The Code looks prettier and it's easier to access varaibles stored over here.
//

import Foundation

enum DHBWSettingsKeys : String {
    case mailBadgeValue = "DHBW_mailBadgeValue"
}

private enum DHBWPrivateSettingsKeys : String {
    case lehreUsername = "DHBW_lehreUsername", lehrePassword = "DHBW_lehrePassword", course = "DHBW_course", mailServerUrl = "DHBW_mailServerUrl", mailServerPort = "DHBW_mailServerPort", baseJsonUrl = "DHBW_baseJsonUrl", samlLoginUrl = "DHBW_samlLoginUrl", ownCloudServerUrl = "DHBW_ownCloudServerUrl"
}

/**
 Used for accessing and storing the users custom settings.
 */
class SharedSettings {
    private static var instance : SharedSettings! = nil
    
    // Private instanciations
    private var _lehreUsername = ""
    private var _lehrePassword = ""
    private var _mailServerPort = 993
    private var _mailServerUrl = "lehre-mail.dhbw-stuttgart.de"
    private var _kurs = ""
    private var _baseJsonUrl = "https://dhbw-appdb.azurewebsites.net/?kurs="
    private var _samlLoginUrl = "https://saml.dhbw-stuttgart.de/idp/Authn/UserPassword"
    private var _ownCloudServerUrl = "https://owncloud.dhbw-stuttgart.de"
    
    /**
     Returns the username without email, used for ownCloud authentication
     */
    public var lehreUsername : String {
        set (newVal) {
            _lehreUsername = newVal
            def.set(newVal, forKey: DHBWPrivateSettingsKeys.lehreUsername.rawValue)
        }
        get {
            return _lehreUsername
        }
    }
    /**
     Stores the URL of the ownCloud instance
     */
    public var ownCloudServerUrl : String {
        set (newVal) {
            _ownCloudServerUrl = newVal
            def.set(newVal, forKey: DHBWPrivateSettingsKeys.ownCloudServerUrl.rawValue)
        }
        get {
            return _ownCloudServerUrl
        }
    }
    /**
     Returns the SAML login URL
     */
    public var samlLoginUrl : String {
        set (newVal) {
            _samlLoginUrl = newVal
            def.set(newVal, forKey: DHBWPrivateSettingsKeys.samlLoginUrl.rawValue)
        }
        get {
            return _samlLoginUrl
        }
    }
    /**
     Returns the username used for SAML authentication
     */
    public var lehreUsernameWithMail : String {
        set (newVal) {
            _lehreUsername = newVal.replacingOccurrences(of: "@lehre.dhbw-stuttgart.de", with: "")
            def.set(newVal.replacingOccurrences(of: "@lehre.dhbw-stuttgart.de", with: ""), forKey: DHBWPrivateSettingsKeys.lehreUsername.rawValue)
        }
        get {
            return _lehreUsername + "@lehre.dhbw-stuttgart.de"
        }
    }
    /**
     Returns the password used for SAML / ownCloud authentication
     */
    public var lehrePassword : String {
        set (newVal) {
            _lehrePassword = newVal
            def.set(newVal, forKey: DHBWPrivateSettingsKeys.lehrePassword.rawValue)
        }
        get {
            return _lehrePassword
        }
    }
    /**
     Returns the base URL for fetching the calendars in JSON format.
     */
    private var baseJsonUrl : String {
        set (newVal) {
            _baseJsonUrl = newVal
            def.set(newVal, forKey: DHBWPrivateSettingsKeys.baseJsonUrl.rawValue)
        }
        get {
            return _baseJsonUrl
        }
    }
    /**
     Returns the URL for fetching the list of available courses.
     */
    public var setupJsonUrl : String {
        return _baseJsonUrl + "setup"
    }
    /**
     Returns the URL for fetching the calendar for the specified course.
     */
    public var jsonUrl : String {
        return baseJsonUrl + kurs
    }
    /**
     Returns the course the user specified in the setup process.
     */
    public var kurs : String {
        set (newVal) {
            _kurs = newVal
            def.set(newVal, forKey: DHBWPrivateSettingsKeys.course.rawValue)
        }
        get {
            return _kurs
        }
    }
    /**
     Returns the IMAP server URL used for mail communication.
     */
    public var mailServerUrl : String {
        set (newVal) {
            _mailServerUrl = newVal
            def.set(newVal, forKey: DHBWPrivateSettingsKeys.mailServerUrl.rawValue)
        }
        get {
            return _mailServerUrl
        }
    }
    /**
     Returns the port used for mail server communication.
     */
    public var mailServerPort : Int {
        set (newVal) {
            _mailServerPort = newVal
            def.set(newVal, forKey: DHBWPrivateSettingsKeys.mailServerPort.rawValue)
        }
        get {
            return _mailServerPort
        }
    }
    
    private init() {
        if let lu = def.string(forKey: DHBWPrivateSettingsKeys.lehreUsername.rawValue) {
            _lehreUsername = lu
        }
        if let lp = def.string(forKey: DHBWPrivateSettingsKeys.lehrePassword.rawValue) {
            _lehrePassword = lp
        }
        if let ms = def.string(forKey: DHBWPrivateSettingsKeys.mailServerUrl.rawValue) {
            _mailServerUrl = ms
        }
        if let mp = def.object(forKey: DHBWPrivateSettingsKeys.mailServerPort.rawValue) as? Int {
            _mailServerPort = mp
        }
        if let cs = def.string(forKey: DHBWPrivateSettingsKeys.course.rawValue) {
            _kurs = cs
        }
        if let bu = def.string(forKey: DHBWPrivateSettingsKeys.baseJsonUrl.rawValue) {
            _baseJsonUrl = bu
        }
        if let sl = def.string(forKey: DHBWPrivateSettingsKeys.samlLoginUrl.rawValue) {
            _samlLoginUrl = sl
        }
    }
    /**
     Reloads all variables from NSUserDefaults
     */
    public static func reinitialize() {
        SharedSettings.instance = SharedSettings()
    }
    
    /**
     Shared instance of SharedSettings. Use this one to access the variables.
     */
    public static var shared : SharedSettings {
        if instance == nil {
            instance = SharedSettings()
        }
        return instance
    }
}