//
//  dhbwDualisManager.swift
//  DHBW Stuttgart
//
//  Created by Yannik Ehlert on 06.12.16.
//  Copyright © 2016 Yannik Ehlert. All rights reserved.
//

import Foundation
import Alamofire

public class dhbwDualisManager {
    
    private class dualisInternalUrls {
        private init() {
            
        }
        static var dualisHome = ""
        static var dualisExamResults = ""
        static var dualisSchedule = ""
    }
    public class dualisUserInformation {
        private init() {
            
        }
        public static var dualisName = ""
    }
    
    private static var dualisUrl = "https://dualis.dhbw.de"
    private static var dualisAuthenticated = false
    private static var dualisLoginUrl: String {
        return dhbwDualisManager.dualisUrl + "/scripts/mgrqcgi"
    }
    public static var isAuthenticated: Bool {
        return dualisAuthenticated
    }
    public static func login(completionHandler: @escaping (CredentialValidationError) -> Void) {
        Alamofire.request(dhbwDualisManager.dualisUrl).responseString { response in
            guard var responseString = response.result.value else {
                completionHandler(.unknownError)
                return
            }
            responseString = responseString.replacingOccurrences(of: "\0", with: "")
            if responseString.range(of: "<meta http-equiv=\"refresh\" content=\"0; URL=") == nil {
                completionHandler(.unknownError)
                return
            }
            let url = dhbwDualisManager.dualisUrl + responseString.components(separatedBy: "<meta http-equiv=\"refresh\" content=\"0; URL=")[1].components(separatedBy: "\"")[0]
            dhbwDualisManager.setToken(url: url, completionHandler: completionHandler)
            //dhbwDualisManager.authenticate()
        }
    }
    private static func setToken(url loginUrl: String, completionHandler: @escaping (CredentialValidationError) -> Void) {
        Alamofire.request(loginUrl).responseString { response in
            guard let headerFields = response.response?.allHeaderFields else {
                completionHandler(.unknownError)
                return
            }
            guard let refreshValue = headerFields["REFRESH"] as? String else {
                completionHandler(.unknownError)
                return
            }
            let newUrl = dhbwDualisManager.dualisUrl + refreshValue.replacingOccurrences(of: "0;URL=", with: "")
            Alamofire.request(newUrl).responseString { response2 in
                if response2.result.isSuccess {
                    dhbwDualisManager.authenticate(completionHandler: completionHandler)
                }
            }
        }
    }
    private static func authenticate(completionHandler: @escaping (CredentialValidationError) -> Void) {
        var postData = [ String : String ]()
        postData["usrname"] = SharedSettings.shared.lehreUsernameWithMail
        postData["pass"] = SharedSettings.shared.lehrePassword
        postData["APPNAME"] = "CampusNet"
        postData["PRGNAME"] = "LOGINCHECK"
        postData["ARGUMENTS"] = "clino,usrname,pass,menuno,menu_type,browser,platform"
        postData["clino"] = "000000000000001"
        postData["menuno"] = "000324"
        postData["menu_type"] = "classic"
        postData["browser"] = ""
        postData["platform"] = ""
        
        Alamofire.request(dhbwDualisManager.dualisLoginUrl, method: .post, parameters: postData, encoding: URLEncoding.httpBody).responseString { loginResult in
            guard let headerFields = loginResult.response?.allHeaderFields else {
                completionHandler(.unknownError)
                return
            }
            guard let refreshValue = headerFields["REFRESH"] as? String else {
                completionHandler(.unknownError)
                return
            }
            let newUrl = dhbwDualisManager.dualisUrl + refreshValue.replacingOccurrences(of: "0; URL=", with: "")
            Alamofire.request(newUrl).responseString { response in
                guard let headerFields = response.response?.allHeaderFields else {
                    completionHandler(.unknownError)
                    return
                }
                guard let refreshValue2 = headerFields["REFRESH"] as? String else {
                    completionHandler(.unknownError)
                    return
                }
                let newUrl2 = dhbwDualisManager.dualisUrl + refreshValue2.replacingOccurrences(of: "0;URL=", with: "")
                Alamofire.request(newUrl2).responseString { response2 in
                    if response2.result.isSuccess {
                        guard let htmlSite = response2.result.value else {
                            completionHandler(.unknownError)
                            return
                        }
                        if htmlSite.range(of: " navLink\" href=\"") == nil {
                            completionHandler(.unknownError)
                            return
                        }
                        var comps = htmlSite.components(separatedBy: " navLink\" href=\"")
                        comps.remove(at: 0)
                        for url in comps {
                            let dualisUrl = url.components(separatedBy: "\"")[0].removingHtmlEntities!
                            if dualisUrl.range(of: "MLSSTART") != nil {
                                dualisInternalUrls.dualisHome = dhbwDualisManager.dualisUrl + dualisUrl
                            } else if dualisUrl.range(of: "COURSERESULTS") != nil {
                                dualisInternalUrls.dualisExamResults = dhbwDualisManager.dualisUrl + dualisUrl
                            } else if dualisUrl.range(of: "SCHEDULER") != nil {
                                dualisInternalUrls.dualisSchedule = dhbwDualisManager.dualisUrl + dualisUrl
                            }
                        }
                        dualisUserInformation.dualisName = htmlSite.components(separatedBy: "<span class=\"loginDataName\" id=\"loginDataName\"><b>Name<span class=\"colon\">:</span> </b>")[1].components(separatedBy: "</span>")[0]
                        dhbwDualisManager.dualisAuthenticated = true
                        completionHandler(.success)
                    }
                }
            }
        }
    }
    public static func examResults(completionHandler: @escaping (dualisExamCallback) -> Void) {
        if !dhbwDualisManager.dualisAuthenticated {
            fatalError("Not authenticated on Dualis!")
        }
        Alamofire.request(dualisInternalUrls.dualisExamResults).responseString(encoding: String.Encoding.utf8) { response in
            guard let result = response.result.value else {
                completionHandler(dualisExamCallback(success: false))
                return
            }
            let semestersHtml = result.components(separatedBy: "<select id=\"semester\" name=\"semester\"")[1].components(separatedBy: "</select>")[0]
            var semesters = [ String : String ]()
            var semComps = semestersHtml.components(separatedBy: "<option value=")
            semComps.remove(at: 0)
            for component in semComps {
                let id = component.components(separatedBy: "\"")[1]
                let name = component.components(separatedBy: ">")[1].components(separatedBy: "<")[0]
                semesters[name] = id
            }
            
            let unitsHtml = result.components(separatedBy: "<table class=\"nb list\">")[1].components(separatedBy: "</table>")[0]
            var units = [ dualisUnit ]()
            var unitComps = unitsHtml.components(separatedBy: "<tr >")
            unitComps.remove(at: 0)
            for component in unitComps {
                let number = component.components(separatedBy: "<td class=\"tbdata\">")[1].components(separatedBy: "</td>")[0]
                let name = component.components(separatedBy: "<td class=\"tbdata\">")[2].components(separatedBy: "</td>")[0]
                let finalGrade = component.components(separatedBy: "<td class=\"tbdata_numeric\" style=\"vertical-align:top;\">")[1].components(separatedBy: "</td>")[0].removingHtmlEntities!.trimmingCharacters(in: .whitespacesAndNewlines)
                let credits = component.components(separatedBy: "<td class=\"tbdata_numeric\">")[1].components(separatedBy: "</td>")[0].removingHtmlEntities!.trimmingCharacters(in: .whitespacesAndNewlines)
                let malusPoints = component.components(separatedBy: "<td class=\"tbdata_numeric\">")[2].components(separatedBy: "</td>")[0].removingHtmlEntities!.trimmingCharacters(in: .whitespacesAndNewlines)
                let status = component.components(separatedBy: "<td class=\"tbdata_numeric\">")[2].components(separatedBy: "<td class=\"tbdata\">")[1].components(separatedBy: "</td>")[0].removingHtmlEntities!.trimmingCharacters(in: .whitespacesAndNewlines)
                let linkResults = component.components(separatedBy: "dl_popUp(\"")[1].components(separatedBy: "\"")[0]
                let unit = dualisUnit(number: number, name: name, finalGrade: finalGrade, credits: credits, malusPoints: malusPoints, status: status, linkResults: linkResults)
                units.append(unit)
            }
            
            completionHandler(dualisExamCallback(semesters: semesters, units: units))
        }
    }
    private init() {
        
    }
    
    public class dualisUnit {
        public var number = ""
        public var name = ""
        public var finalGrade: String? = nil
        public var credits = ""
        public var malusPoints: String? = nil
        public var status: String? = nil
        public var linkResults = ""
        public init(number: String, name: String, finalGrade: String?, credits: String, malusPoints: String?, status: String?, linkResults: String) {
            self.number = number
            self.name = name
            if finalGrade != "" {
                self.finalGrade = finalGrade
            }
            self.finalGrade = finalGrade
            self.credits = credits
            if malusPoints != "" {
                self.malusPoints = malusPoints
            }
            if status != "" {
                self.status = status
            }
            self.linkResults = linkResults
        }
    }
    
    public class dualisExamCallback {
        var semesters : [ String : String ]? = nil
        var units : [ dualisUnit ]? = nil
        var success = true
        
        public init(success: Bool = true, semesters : [ String : String ]? = nil, units: [ dualisUnit ]? = nil) {
            self.semesters = semesters
            self.units = units
        }
    }
}
