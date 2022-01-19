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

@objc open class ChatBlobTextMessageCell: ChatBlobMessageCell, ZSWTappableLabelTapDelegate, ZSWTappableLabelLongPressDelegate {    
    internal var _captionLabel: ZSWTappableLabel?
    
    open override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            return getAccessibilityCustomActions()
        }
        set {
            super.accessibilityCustomActions = newValue
        }
    }
    
    private let canOpenPhoneLinks = UIApplication.shared.canOpenURL(URL(string: "tel:0")!)
    
    override public init!(style: UITableViewCell.CellStyle, reuseIdentifier: String!, transparent: Bool) {
        super.init(style: style, reuseIdentifier: reuseIdentifier, transparent: transparent)
        self.isAccessibilityElement = true
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func tappableLabel(_ tappableLabel: ZSWTappableLabel, tappedAt idx: Int, withAttributes attributes: [NSAttributedString.Key : Any] = [:]) {
        if let attribute = attributes[NSAttributedString.Key(rawValue: "NSTextCheckingResult")] {
            handleTapResult(result: attribute)
        }
        
    }
    
    public func tappableLabel(_ tappableLabel: ZSWTappableLabel, longPressedAt idx: Int, withAttributes attributes: [NSAttributedString.Key : Any] = [:]) {
        if let attribute = attributes[NSAttributedString.Key(rawValue: "NSTextCheckingResult")] {
            handleLongPressResult(result: attribute)
        }
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isEditing {
            return self
        }
        return super.hitTest(point, with: event)
    }
    
    open override func previewViewController(for previewingContext: UIViewControllerPreviewing!, viewControllerForLocation location: CGPoint) -> UIViewController! {
        guard let regionInfo = _captionLabel?.tappableRegionInfo(forPreviewingContext: previewingContext, location: location) else {
            return nil
        }

        let result = regionInfo.attributes[NSAttributedString.Key(rawValue: "NSTextCheckingResult")]
        if result.self is NSTextCheckingResult {
            let checkingResult = result as! NSTextCheckingResult
            if checkingResult.url != nil, checkingResult.resultType == .link && !checkingResult.url!.absoluteString.hasPrefix("mailto:") {
                let url = checkingResult.url
                if url?.scheme == "http" || url?.scheme == "https" {
                    regionInfo.configure(previewingContext: previewingContext)
                    let safari = ThreemaSafariViewController.init(url: url!)
                    safari.url = url!
                    return safari
                }
            }
        }
        return nil
    }
    
    /**
    Retun a menu if tapped object was a link.
     Will return nil if nothing was found
    */
    @available(iOS 13.0, *)
    open func contextMenuForLink(_ indexPath: IndexPath!, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let convertedPoint = _captionLabel?.convert(point, from: chatVc.chatContent) else { return nil }
        if let regionInfo = _captionLabel?.checkIsPointAction(convertedPoint) {
            if let checkingResult = regionInfo[NSAttributedString.Key(rawValue: "NSTextCheckingResult")] as? NSTextCheckingResult {
                if checkingResult.url != nil, checkingResult.resultType == .link && !checkingResult.url!.absoluteString.hasPrefix("mailto:") {
                    guard let url = checkingResult.url else {
                        return nil
                    }
                    
                    if url.scheme == "http" || url.scheme == "https" {
                        let safariViewController = ThreemaSafariViewController.init(url: url)
                        safariViewController.url = url
                        return UIContextMenuConfiguration(identifier: indexPath as NSCopying?, previewProvider: { () -> UIViewController? in
                            return safariViewController
                        }) { (suggestedActions) -> UIMenu? in
                            var menuItems = [UIAction]()
                            let copyImage = UIImage.init(systemName: "doc.on.doc.fill", compatibleWith: self.traitCollection)
                            let action = UIAction(title: BundleUtil.localizedString(forKey: "copy"), image: copyImage, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off) { (action) in
                                UIPasteboard.general.string = self.displayString(for: url)
                            }
                            menuItems.append(action)
                            return UIMenu(title: "", image: nil, identifier: .application, options: .displayInline, children: menuItems)
                        }
                    }
                }
            }
        }
        return nil
    }
    
    class open func calculateCaptionHeight(scaledSize: CGSize, fileMessage: FileMessage) -> CGFloat {
        let imageInsets = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
        
        if let caption = fileMessage.caption, caption.count > 0 {
            let x: CGFloat = 30.0
            
            let maxSize = CGSize.init(width: scaledSize.width - x, height: CGFloat.greatestFiniteMagnitude)
            var textSize: CGSize?
            let captionTextNSString = NSString.init(string: caption)
            
            if UserSettings.shared().disableBigEmojis && captionTextNSString.isOnlyEmojisMaxCount(3) {
                var dummyLabelEmoji: ZSWTappableLabel? = nil
                if dummyLabelEmoji == nil {
                    dummyLabelEmoji = ChatTextMessageCell.makeAttributedLabel(withFrame: CGRect.init(x: (x/2), y: 0.0, width: maxSize.width, height: maxSize.height))
                }
                dummyLabelEmoji!.font = ChatTextMessageCell.emojiFont()
                dummyLabelEmoji?.attributedText = NSAttributedString.init(string: caption, attributes: [NSAttributedString.Key.font: ChatMessageCell.emojiFont()!])
                textSize = dummyLabelEmoji?.sizeThatFits(maxSize)
                textSize!.height = textSize!.height + 23.0
            } else {
                var dummyLabel: ZSWTappableLabel? = nil
                if dummyLabel == nil {
                    dummyLabel = ChatTextMessageCell.makeAttributedLabel(withFrame: CGRect.init(x: (x/2), y: 0.0, width: maxSize.width, height: maxSize.height))
                }
                dummyLabel!.font = ChatTextMessageCell.textFont()
                let attributed = TextStyleUtils.makeAttributedString(from: caption, with: dummyLabel!.font, textColor: Colors.fontNormal(), isOwn: true, application: UIApplication.shared)
                let formattedAttributeString = NSMutableAttributedString.init(attributedString: (dummyLabel!.applyMarkup(for: attributed))!)
                dummyLabel?.attributedText = TextStyleUtils.makeMentionsAttributedString(for: formattedAttributeString, textFont: dummyLabel!.font!, at: dummyLabel!.textColor.withAlphaComponent(0.4), messageInfo: Int32(fileMessage.isOwn!.intValue), application: UIApplication.shared)
                textSize = dummyLabel?.sizeThatFits(maxSize)
                textSize!.height = textSize!.height + 23.0
            }
            return textSize!.height
        } else {
            return imageInsets.top + imageInsets.bottom
        }
    }
    
    @objc override open func speakMessage(_ menuController: UIMenuController) {
        if _captionLabel?.text != nil {
            let utterance: AVSpeechUtterance = AVSpeechUtterance.init(string: accessibilityLabelForContent())
            let syn = AVSpeechSynthesizer.init()
            syn.speak(utterance)
        }
    }
}

extension ChatBlobTextMessageCell {
    // MARK: Private functions
    
    private func handleTapResult(result: Any) {
        if result.self is Contact {
            chatVc.mentionTapped(result)
        }
        else if result.self is NSString || result.self is String {
            let resultString = result as! String
            
            if resultString == "meContact" {
                chatVc.mentionTapped(resultString)
            }
        }
        else if result.self is NSTextCheckingResult {
            openLink(with: result as! NSTextCheckingResult)
        }
    }
    
    @objc private func openLink(with urlResult: NSTextCheckingResult) {
        if urlResult.resultType == .link {
            IDNSafetyHelper.safeOpen(url: urlResult.url!, viewController: self.chatVc)
        }
        else if urlResult.resultType == .phoneNumber {
            callPhoneNumber(phoneNumber: urlResult.phoneNumber!)
        }
    }
    
    private func callPhoneNumber(phoneNumber: String) {
        let cleanString = phoneNumber.replacingOccurrences(of: "\u{00a0}", with: "")

        
        if let url = URL.init(string: String(format: "tel:%@", cleanString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func handleLongPressResult(result: Any) {
        if result.self is NSString || result.self is String {
            return
        }
        else if result.self is Contact {
            chatVc.mentionTapped(result)
        }
        else if result.self is NSTextCheckingResult {
            let checkingResult = result as! NSTextCheckingResult
            
            if checkingResult.resultType == .link {
                if let actionUrl = checkingResult.url {
                    let actionSheet = NonFirstResponderActionSheet.init(title: displayString(for: actionUrl), message: nil, preferredStyle: .actionSheet)
                    actionSheet.addAction(UIAlertAction.init(title: BundleUtil.localizedString(forKey: "open"), style: .default, handler: { (action) in
                        IDNSafetyHelper.safeOpen(url: actionUrl, viewController: self.chatVc)
                    }))
                    actionSheet.addAction(UIAlertAction.init(title: BundleUtil.localizedString(forKey: "copy"), style: .default, handler: { (action) in
                        UIPasteboard.general.string = self.displayString(for: actionUrl)
                    }))
                    actionSheet.addAction(UIAlertAction.init(title: BundleUtil.localizedString(forKey: "cancel"), style: .cancel, handler: nil))
                    
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        actionSheet.popoverPresentationController?.sourceView = self
                        actionSheet.popoverPresentationController?.sourceRect = self.bounds
                    }
                    
                    chatVc.chatBar.resignFirstResponder()
                    chatVc.present(actionSheet, animated: true, completion: nil)
                }
            }
            else if checkingResult.resultType == .phoneNumber {
                if let actionPhone = checkingResult.phoneNumber {
                    let actionSheet = NonFirstResponderActionSheet.init(title: actionPhone, message: nil, preferredStyle: .actionSheet)
                    actionSheet.addAction(UIAlertAction.init(title: BundleUtil.localizedString(forKey: "call"), style: .default, handler: { (action) in
                        self.callPhoneNumber(phoneNumber: actionPhone)
                    }))
                    actionSheet.addAction(UIAlertAction.init(title: BundleUtil.localizedString(forKey: "copy"), style: .default, handler: { (action) in
                        UIPasteboard.general.string = actionPhone
                    }))
                    actionSheet.addAction(UIAlertAction.init(title: BundleUtil.localizedString(forKey: "cancel"), style: .cancel, handler: nil))
                    
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        actionSheet.popoverPresentationController?.sourceView = self
                        actionSheet.popoverPresentationController?.sourceRect = self.bounds
                    }
                    
                    chatVc.chatBar.resignFirstResponder()
                    chatVc.present(actionSheet, animated: true, completion: nil)
                }
            }
        }
    }
    
    private func displayString(for url: URL) -> String {
        return url.absoluteString.replacingOccurrences(of: "mailto:", with: "")
    }
    
    private func getAccessibilityCustomActions() -> [UIAccessibilityCustomAction] {
        if _captionLabel == nil {
            return []
        }
        if _captionLabel!.accessibilityElements == nil {
            return []
        }
        
        var actions = super.accessibilityCustomActions
        var indexCounter = 0
        
        if _captionLabel!.accessibilityElementCount() > 0 {
            for i in 0..._captionLabel!.accessibilityElementCount() - 1 {
                if let element = _captionLabel!.accessibilityElement(at: i) as? UIAccessibilityElement {
                    if element.accessibilityLabel != nil, element.accessibilityLabel! != "." && element.accessibilityLabel! != "@" {
                        if self.checkTextResult(text: element.accessibilityLabel!) != nil {
                            let openString = "\(BundleUtil.localizedString(forKey: "open") ): \(element.accessibilityLabel!)"
                            let linkAction = UIAccessibilityCustomAction.init(name: openString, target: self, selector: #selector(openLink(with:)))
                            actions?.insert(linkAction, at: indexCounter)
                            indexCounter += 1
                            
                            let shareString = "\(BundleUtil.localizedString(forKey: "share") ): \(element.accessibilityLabel!)"
                            let shareAction = UIAccessibilityCustomAction.init(name: shareString, target: self, selector: #selector(shareLink))
                            actions?.insert(shareAction, at: indexCounter)
                            indexCounter += 1
                        } else {
                            let mentionString = "\(BundleUtil.localizedString(forKey: "details") ): \(element.accessibilityLabel!)"
                            let mentionAction = UIAccessibilityCustomAction.init(name: mentionString, target: self, selector: #selector(openMentions(action:)))
                            actions?.insert(mentionAction, at: indexCounter)
                            indexCounter += 1
                        }
                    }
                }
            }
        }
        
        return actions!
    }
    
    @objc private func shareLink(action: UIAccessibilityCustomAction) -> Bool {
        let urlResult = checkTextResult(text: action.name)
        
        if urlResult?.resultType == .link {
            let activityViewController = ActivityUtil.activityViewController(withActivityItems: [urlResult!.url], applicationActivities: [])
            chatVc.present(activityViewController, animated: true, from: self)
        }
        else if urlResult?.resultType == .phoneNumber {
            let activityViewController = ActivityUtil.activityViewController(withActivityItems: [urlResult!.phoneNumber], applicationActivities: [])
            chatVc.present(activityViewController, animated: true, from: self)
        }
        
        return true
    }

    private func checkTextResult(text: String) -> NSTextCheckingResult? {
        var textCheckingTypes: NSTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
        
        if canOpenPhoneLinks {
            textCheckingTypes |= NSTextCheckingResult.CheckingType.phoneNumber.rawValue
        }
        
        var urlResult: NSTextCheckingResult? = nil
        let detector = try! NSDataDetector(types: textCheckingTypes)
        detector.enumerateMatches(in: text, options: [], range: NSRange(location: 0, length: text.count)) { (result, flags, stop) in
            urlResult = result
        }
        return urlResult
    }
    
    @objc private func openMentions(action: UIAccessibilityCustomAction) -> Bool {
        let identity = action.name.replacingOccurrences(of: "\(BundleUtil.localizedString(forKey: "details")) @", with: "")
        if identity == BundleUtil.localizedString(forKey: "me") {
            handleTapResult(result: "meContact")
        } else {
            if let contact = ContactStore.shared()?.contact(forIdentity: identity) {
                handleTapResult(result: contact)
            }
        }
        return true
    }
}
