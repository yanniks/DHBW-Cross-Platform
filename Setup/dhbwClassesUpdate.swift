//
//  dhbwClassesUpdate.swift
//  DHBW Stuttgart
//
//  Created by Yannik Ehlert on 28.03.17.
//  Copyright © 2017 Yannik Ehlert. All rights reserved.
//

import Foundation
import SwiftProtobuf
import Alamofire

private enum dhbwSocketUpdate {
    enum send: String {
        case requestLectures = "requestLectures", listCourses = "listCourses"
    }
    enum receive: String {
        case lectures = "lectures", courses = "courses"
    }
}

class dhbwClassesUpdate {
    private static var callbackLectures : ((_ error: Error?) -> Void)? = nil
    private static var callbackCourses : ((_ courses: [ Dhbw_Servercommunication_Course ]?, _ error: Error?) -> Void)? = nil
    
    private static var headers: HTTPHeaders = {
        return [ "Accept" : "application/protobuf" ]
    }()

    /**
     This class is not supposed to be initialized
     */
    private init() {}
    
    /**
    Initialize the socket connection required for all other functions in this class.
    */
    public static func createSocketConnection() {
        // DEPRECATED
    }
    /**
    Sends the update request to the webserver which replies with new payload if available.
     */
    public static func updateLectures(callback: ((_ error: Error?) -> Void)?) {
        // Send update request
        let url = SharedSettings.shared.baseWebsocketUrl + "/lectures?course=" + SharedSettings.shared.kurs
        callbackLectures = callback

        Alamofire.request(url, headers: headers).responseData { response in
            self.receiveLectures(response.data)
        }
    }
    
    /**
    Sends the update request to the webserver with replies with the current list of courses.
     */
    public static func updateCourses(callback: ((_ courses: [ Dhbw_Servercommunication_Course ]?, _ error: Error?) -> Void)?) {
        callbackCourses = callback
        var url = URL(string: SharedSettings.shared.baseWebsocketUrl)!
        url.appendPathComponent("courses")
        Alamofire.request(url, headers: headers).responseData { response in
            print(response.error)
            
            self.receiveCourses(response.data)
        }
    }

    /**
    Callback for incoming course lists
    */
    private static func receiveCourses(_ data: Data?) {
        // Convert received payload into Data object
        if let data = data {
            print(data)
            do {
                callbackCourses?(try Dhbw_Servercommunication_ServerCourseResponse(serializedData: data).courses, nil)
            } catch let error {
                print(error.localizedDescription)
                callbackCourses?([], error)
            }
            callbackCourses = nil
        }
    }

    /**
    Callback for incoming lecture schedules
    */
    private static func receiveLectures(_ data: Data?) {
        // Array to save data in
        var arrayLectures = [ [ String : String ] ]()
        
        // Convert received payload to Data object
        if let data = data {
            do {
                // Try to serialize it to ServerLectureResponse object
                let response = try Dhbw_Servercommunication_ServerLectureResponse(serializedData: data)
                // Loop through lectures to get information
                for lecture in response.lectures {
                    var dictionarySingleLecture = [ String : String ]()
                    
                    // Check if value is empty. If not, add it to dictionarySingleLecture
                    if lecture.begin != "" {
                        dictionarySingleLecture[Vorlesungen.begin.rawValue] = lecture.begin
                    }
                    if lecture.end != "" {
                        dictionarySingleLecture[Vorlesungen.end.rawValue] = lecture.end
                    }
                    if lecture.location != "" {
                        dictionarySingleLecture[Vorlesungen.location.rawValue] = lecture.location
                    }
                    if lecture.prof != "" {
                        dictionarySingleLecture[Vorlesungen.professor.rawValue] = lecture.prof
                    }
                    if lecture.title != "" {
                        dictionarySingleLecture[Vorlesungen.title.rawValue] = lecture.title
                    }
                    arrayLectures.append(dictionarySingleLecture)
                }
            } catch let error {
                // Submit error if serialization failed
                if let callback = callbackLectures {
                    callback(error)
                    callbackLectures = nil
                }
            }
        }
        
        // Serialize dictionary to JSON. This is the format that has been used before so we don't have to change anything over there.
        if let data = try? JSONSerialization.data(withJSONObject: arrayLectures, options: []) {
            def.set(String(data: data, encoding: .utf8), forKey: "json")
        }
        // Call callback if available to notify caller
        if let callback = callbackLectures {
            callback(nil)
            callbackLectures = nil
        }
    }
}
