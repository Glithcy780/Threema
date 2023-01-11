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

import CocoaLumberjackSwift
import Foundation

@objc open class ChatContactInfoSystemMessageCell: UITableViewCell {
    
    private var _systemMessage: SystemMessage?
    private var _msgText = UILabel()
    private var _msgBackground = UIImageView()
    private var _threemaTypeIcon = UIImageView()

    private let _iconSize: CGFloat = 26.0
    private let _iconY: CGFloat = 12.0
    
    @objc override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = .clear
        
        var fontSize = roundf(UserSettings.shared().chatFontSize * 13 / 16.0)
        if fontSize < Float(kSystemMessageMinFontSize) {
            fontSize = Float(kSystemMessageMinFontSize)
        }
        else if fontSize > Float(kSystemMessageMaxFontSize) {
            fontSize = Float(kSystemMessageMaxFontSize)
        }
        
        _msgBackground.clearsContextBeforeDrawing = false
        _msgBackground.backgroundColor = Colors.backgroundContactInfoSystemMessage
        _msgBackground.autoresizingMask = .flexibleWidth
        _msgBackground.layer.cornerRadius = 5
        contentView.addSubview(_msgBackground)
        
        _threemaTypeIcon.image = ThreemaUtility.otherThreemaTypeIcon
        _threemaTypeIcon.accessibilityIgnoresInvertColors = true
        _threemaTypeIcon.frame = CGRect(x: 20.0, y: _iconY, width: _iconSize, height: _iconSize)
        contentView.addSubview(_threemaTypeIcon)
        
        _msgText.frame = CGRect(x: 20.0, y: 21, width: contentView.frame.size.width - 40.0, height: 20.0)
        _msgText.font = UIFont.boldSystemFont(ofSize: CGFloat(roundf(fontSize)))
        _msgText.textColor = Colors.white
        _msgText.numberOfLines = 0
        _msgText.textAlignment = .left
        _msgText.autoresizingMask = .flexibleWidth
        _msgText.backgroundColor = .clear

        contentView.addSubview(_msgText)
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ChatContactInfoSystemMessageCell {
    // MARK: Override functions
    
    @objc open class func height(for message: BaseMessage!, forTableWidth tableWidth: CGFloat) -> CGFloat {
        let systemMessage = message as! SystemMessage
        let maxSize = CGSize(width: tableWidth - 26.0 - 8.0, height: CGFloat.greatestFiniteMagnitude)
        let text = systemMessage.format()

        var dummySystemLabel: UILabel?
        if dummySystemLabel == nil {
            dummySystemLabel = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: maxSize.width, height: maxSize.height))
        }

        var fontSize = roundf(UserSettings.shared().chatFontSize * 13 / 16.0)
        if fontSize < Float(kSystemMessageMinFontSize) {
            fontSize = Float(kSystemMessageMinFontSize)
        }
        else if fontSize > Float(kSystemMessageMaxFontSize) {
            fontSize = Float(kSystemMessageMaxFontSize)
        }

        dummySystemLabel!.font = UIFont.boldSystemFont(ofSize: CGFloat(roundf(fontSize)))
        dummySystemLabel!.numberOfLines = 3
        dummySystemLabel!.text = text
        
        let height = (dummySystemLabel?.sizeThatFits(maxSize).height)!
        
        let threemaTypeIcon = UIImageView()
        threemaTypeIcon.image = ThreemaUtility.otherThreemaTypeIcon
        if height > threemaTypeIcon.frame.size.height {
            return height
        }
        else {
            return threemaTypeIcon.frame.size.height
        }
    }
    
    @objc override open func layoutSubviews() {
        let messageTextWidth = layoutMarginsGuide.layoutFrame.size.width - 32.0
        let textSize = _msgText.sizeThatFits(CGSize(width: messageTextWidth, height: CGFloat.greatestFiniteMagnitude))
        super.layoutSubviews()
        
        let bgSideMargin: CGFloat = 8.0
        let bgTopOffset: CGFloat = 6.0
        let bgHeightMargin: CGFloat = bgTopOffset * 2

        let backgroundWidth: CGFloat = bgSideMargin + _iconSize + bgSideMargin + textSize.width + bgSideMargin
        let backgroundX: CGFloat = (frame.size.width - backgroundWidth) / 2
        
        if textSize.height > _iconSize {
            _msgBackground.frame = CGRect(
                x: backgroundX,
                y: _iconY - bgTopOffset,
                width: backgroundWidth,
                height: textSize.height + bgHeightMargin
            )
            _threemaTypeIcon.frame = CGRect(
                x: backgroundX + bgSideMargin,
                y: _iconY + (textSize.height / 2) - (_iconSize / 2),
                width: _iconSize,
                height: _iconSize
            )
            _msgText.frame = CGRect(
                x: backgroundX + bgSideMargin + _iconSize + bgSideMargin,
                y: _iconY,
                width: textSize.width,
                height: textSize.height
            )
        }
        else {
            _msgBackground.frame = CGRect(
                x: backgroundX,
                y: _iconY - bgTopOffset,
                width: backgroundWidth,
                height: _iconSize + bgHeightMargin
            )
            _threemaTypeIcon.frame = CGRect(
                x: backgroundX + bgSideMargin,
                y: _iconY,
                width: _iconSize,
                height: _iconSize
            )
            _msgText.frame = CGRect(
                x: backgroundX + bgSideMargin + _iconSize + bgSideMargin,
                y: _iconY + (_iconSize / 2) - (textSize.height / 2),
                width: textSize.width,
                height: textSize.height
            )
        }
        _msgText.textColor = Colors.white
    }
    
    @objc func setMessage(systemMessage: SystemMessage) {
        _msgText.text = systemMessage.format()
    }
    
    @objc open func getContextMenu(_ indexPath: IndexPath!, point: CGPoint) -> UIContextMenuConfiguration! {
        nil
    }
}
