//
//  FileBrowserClassDHBW.swift
//  DHBW Stuttgart
//
//  Created by Yannik Ehlert on 27.10.16.
//  Copyright © 2016 Yannik Ehlert. All rights reserved.
//

#if DHBWApp
    import Foundation
    
    extension FileBrowserClass {
        func getFiles(_ url : String, callback : @escaping ([ FileserverFile ]?, Error?) -> Void) {
            ownCloudHandler.shared.getFolder(url, callback: { (files, error) -> Void in
                if let error = error {
                    callback(nil, error)
                    return
                }
                var fileOutput = [ FileserverFile ]()
                for file in files! {
                    let oFile = FileserverFile()
                    oFile.type = file.isDirectory ? .Folder : .File
                    if let id = file.ocId {
                        oFile.id = id
                    }
                    if let fileName = file.fileName, let directory = file.filePath {
                        oFile.directory = directory
                        oFile.link = directory.removingPercentEncoding! + fileName.removingPercentEncoding!
                        oFile.title = fileName.removingPercentEncoding!
                    }
                    if file.isDirectory && file.fileName != nil {
                        oFile.title = oFile.title.substring(to: oFile.title.index(before: oFile.title.endIndex))
                    }
                    fileOutput.append(oFile)
                }
                fileOutput.remove(at: 0)
                callback(fileOutput, nil)
            })
        }
        private func getDocumentPath() -> String {
            /*let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            return paths[0]*/
            return NSTemporaryDirectory()
        }
        func downloadFile(_ file : FileserverFile, callback : @escaping (URL?, Error?) -> Void, progressCallback : @escaping ((Float) -> Void)) {
            let wpath = getDocumentPath() + "/" + file.title
            ownCloudHandler.shared.downloadFile(SharedSettings.shared.ownCloudServerUrl + file.link, fileDestination: wpath, callback: { (url, error) -> Void in
                if let error = error {
                    callback(nil, error)
                    return
                }
                callback(url, nil)
            }, progressCallback: progressCallback)
        }
    }
#endif
