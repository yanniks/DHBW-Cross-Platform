//
//  dhbwImageHandling.swift
//  DHBW Stuttgart
//
//  Created by Yannik Ehlert on 06.12.16.
//  Copyright © 2016 Yannik Ehlert. All rights reserved.
//

import Foundation
import Alamofire

extension NSNotification.Name {
    static let DHBWUserImageChanged = Notification.Name("DHBWUserImageChanged")
}

class dhbwImageHandling {
    private static var _shared : dhbwImageHandling! = nil
    
    public static var shared: dhbwImageHandling {
        if _shared == nil {
            _shared = dhbwImageHandling()
        }
        return _shared
    }
    func getImage() {
        Alamofire.request("https://elearning.dhbw-stuttgart.de/moodle/auth/shibboleth/index.php").responseString { response in
            var params = [ String : Any ]()
            params["j_username"] = SharedSettings.shared.lehreUsernameWithMail
            params["j_password"] = SharedSettings.shared.lehrePassword
            Alamofire.request(SharedSettings.shared.samlLoginUrl, method: .post, parameters: params, encoding: URLEncoding.httpBody).responseString { response2 in
                guard let responseString = response2.result.value else {
                    return
                }
                if responseString.range(of: "name=\"RelayState\" value=\"") == nil || responseString.range(of: "name=\"SAMLResponse\" value=\"") == nil || responseString.range(of: "<form action=\"") == nil {
                    return
                }
                var dataSet = [ String : String ]()
                dataSet["RelayState"] = responseString.components(separatedBy: "name=\"RelayState\" value=\"")[1].components(separatedBy: "\"")[0].removingHtmlEntities
                dataSet["SAMLResponse"] = responseString.components(separatedBy: "name=\"SAMLResponse\" value=\"")[1].components(separatedBy: "\"")[0].removingHtmlEntities
                let action = responseString.components(separatedBy: "<form action=\"")[1].components(separatedBy: "\"")[0].removingHtmlEntities
                guard let urlAction = action else {
                    return
                }
                Alamofire.request(urlAction, method: .post, parameters: dataSet, encoding: URLEncoding.httpBody).responseString { authenticationResponse in
                    Alamofire.request("https://elearning.dhbw-stuttgart.de/moodle/user/profile.php").responseString { profileResponse in
                        guard let profileHtml = profileResponse.result.value else {
                            return
                        }
                        if profileHtml.range(of: "<img src=\"https://elearning.dhbw-stuttgart.de/moodle/pluginfile.php") == nil {
                            SharedSettings.shared.userImage = nil
                            return
                        }
                        let imageUrl = "https://elearning.dhbw-stuttgart.de/moodle/pluginfile.php" + profileHtml.components(separatedBy: "<img src=\"https://elearning.dhbw-stuttgart.de/moodle/pluginfile.php")[1].components(separatedBy: "\"")[0]
                        Alamofire.request(imageUrl).responseData { imageResponse in
                            guard let imageData = imageResponse.data else {
                                SharedSettings.shared.userImage = nil
                                return
                            }
                            if let image = UIImage(data: imageData) {
                                SharedSettings.shared.userImage = image
                                NotificationCenter.default.post(name: .DHBWUserImageChanged, object: nil)
                            } else {
                                SharedSettings.shared.userImage = nil
                            }
                        }
                    }
                }
                #if os(iOS)
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                #endif
            }
        }
    }
    private init() {
        
    }
}
