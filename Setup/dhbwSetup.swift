//
//  dhbwSetup.swift
//  DHBW Stuttgart
//
//  Created by Yannik Ehlert on 05.12.16.
//  Copyright © 2016 Yannik Ehlert. All rights reserved.
//

#if os(iOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif
import Alamofire

class dhbwSetup {
    static func fetchCourseList(callback : @escaping ((Error?, [ Dhbw_Servercommunication_Course ]?) -> Void)) {
        dhbwClassesUpdate.updateCourses { courses, error in
            callback(error, courses)
        }
    }
    static func validateCredentials(username: String, password: String, callback : @escaping ((CredentialValidationError?) -> Void)) {
        if username.characters.count <= 24 {
            callback(.invalidUsername)
            return
        }
        if username.substring(from: username.index(username.endIndex, offsetBy: -24)) != "@lehre.dhbw-stuttgart.de" {
            callback(.invalidUsername)
            return
        }
        
        #if os(iOS)
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        #endif
        Alamofire.request("https://elearning.dhbw-stuttgart.de/moodle/auth/shibboleth/index.php").responseString { response in
            var params = [ String : Any ]()
            params["j_username"] = username
            params["j_password"] = password
            Alamofire.request(SharedSettings.shared.samlLoginUrl, method: .post, parameters: params, encoding: URLEncoding.httpBody).responseString { response2 in
                #if os(iOS)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                #endif
                
                guard let responseString = response2.result.value else {
                    callback(.unknownError)
                    return
                }
                if responseString.range(of: "you must press the Continue button once to proceed.") != nil {
                    callback(nil)
                } else {
                    callback(.wrongCredentials)
                }
            }
        }
    }
    static func setNewCourse(_ course: String, callback: @escaping ((Error?) -> Void)) {
        SharedSettings.shared.kurs = course
        dhbwClassesUpdate.updateLectures { error in
            callback(error)
        }
    }
}

public enum CredentialValidationError: Error {
    case invalidUsername
    case wrongCredentials
    case unknownError
    case success
}
