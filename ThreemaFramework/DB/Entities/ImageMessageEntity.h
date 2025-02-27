//  _____ _
// |_   _| |_  _ _ ___ ___ _ __  __ _
//   | | | ' \| '_/ -_) -_) '  \/ _` |_
//   |_| |_||_|_| \___\___|_|_|_\__,_(_)
//
// Threema iOS Client
// Copyright (c) 2012-2023 Threema GmbH
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseMessage.h"
#import "ImageData.h"
#import "BlobOrigin.h"

@interface ImageMessageEntity : BaseMessage

// Attributes
@property (nullable, nonatomic, retain) NSData *encryptionKey;
@property (nullable, nonatomic, retain) NSData *imageBlobId NS_SWIFT_NAME(imageBlobID);
@property (nullable, nonatomic, retain) NSData *imageNonce;
@property (nullable, nonatomic, retain) NSNumber *imageSize;
@property (nullable, nonatomic, retain) NSNumber *progress;

// Relationships
@property (nullable, nonatomic, retain) ImageData *image;
@property (nullable, nonatomic, retain) ImageData *thumbnail;

@end
