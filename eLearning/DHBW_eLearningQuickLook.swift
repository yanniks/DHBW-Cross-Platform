//
//  DHBW_eLearningQuickLook.swift
//  DHBW Stuttgart
//
//  Created by Yannik Ehlert on 31.10.16.
//  Copyright © 2016 Yannik Ehlert. All rights reserved.
//

#if os(iOS)
import QuickLook

extension DHBW_eLearningWebView: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
    /*!
     * @abstract Returns the number of items that the preview controller should preview.
     * @param controller The Preview Controller.
     * @result The number of items.
     */
    @available(iOS 4.0, *)
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        if downloadedFile == nil {
            return 0
        }
        return 1
    }
    
    /*!
     * @abstract Returns the item that the preview controller should preview.
     * @param panel The Preview Controller.
     * @param index The index of the item to preview.
     * @result An item conforming to the QLPreviewItem protocol.
     */
    @available(iOS 4.0, *)
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let downloadedFile = downloadedFile else {
            return URL(string: "") as! QLPreviewItem
        }
        return downloadedFile as QLPreviewItem
    }
}
#endif
