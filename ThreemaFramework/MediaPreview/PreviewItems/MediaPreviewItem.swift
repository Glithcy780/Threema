//  _____ _
// |_   _| |_  _ _ ___ ___ _ __  __ _
//   | | | ' \| '_/ -_) -_) '  \/ _` |_
//   |_| |_||_|_| \___\___|_|_|_\__,_(_)
//
// Threema iOS Client
// Copyright (c) 2020-2022 Threema GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License, version 3,
// as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import Foundation
import CocoaLumberjackSwift

protocol MediaPreviewItemProtocol : PreviewItemProtocol {
    func getThumbnail(onCompletion: (UIImage) -> Void)
    func requestAsset()
    func freeMemory()
}

@objc open class MediaPreviewItem: NSObject {
    var sendAsFile: Bool = false
    var caption: String?
    
    open var filename: String?
    open  var uti: String?
    open var thumbnail: UIImage?
    
    open var itemUrl: URL?
    open var originalAsset: Any?
    
    public let semaphore = DispatchSemaphore(value: 0)
    public let thumbnailSemaphore = DispatchSemaphore(value: 0)
    public var memoryConstrained = false
    
    public override init() {
        super.init()
    }
    
    init(itemUrl : URL) {
        self.itemUrl = itemUrl
    }
    
    open func requestAsset() {
        // Do nothing - A general item might not have an asset
    }
    
    func getThumbnail(onCompletion: (UIImage) -> Void) {
        if self.thumbnail == nil {
            self.thumbnailSemaphore.wait()
            self.thumbnailSemaphore.signal()
        }
        guard let image = self.thumbnail else {
            return
        }
        onCompletion(image)
    }
    
    func getThumbnail() -> UIImage? {
        if self.thumbnail == nil {
            self.thumbnailSemaphore.wait()
            self.thumbnailSemaphore.signal()
        }
        guard let thumbnail = self.thumbnail else {
            return nil
        }
        return thumbnail
    }
    
    func getAccessiblityDescription() -> String? {
        return nil
    }
    
    func removeItem() {
        guard let url = self.itemUrl else {
            return
        }
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            DDLogError("Could not remove item because \(error.localizedDescription)")
        }
    }
    
    func freeMemory() {
        self.thumbnail = nil
    }
}
