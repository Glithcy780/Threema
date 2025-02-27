//  _____ _
// |_   _| |_  _ _ ___ ___ _ __  __ _
//   | | | ' \| '_/ -_) -_) '  \/ _` |_
//   |_| |_||_|_| \___\___|_|_|_\__,_(_)
//
// Threema iOS Client
// Copyright (c) 2022-2024 Threema GmbH
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

import XCTest
@testable import ThreemaFramework

class ContactStoreTests: XCTestCase {

    private var databaseMainCnx: DatabaseContext!

    override func setUpWithError() throws {
        // Necessary for ValidationLogger
        AppGroup.setGroupID("group.ch.threema") // THREEMA_GROUP_IDENTIFIER @"group.ch.threema"

        let (_, mainCnx, _) = DatabasePersistentContext.devNullContext()
        databaseMainCnx = DatabaseContext(mainContext: mainCnx, backgroundContext: nil)
    }

    func testAddWorkContactWithIdentity() throws {
        let expectedIdentity = "TESTER01"
        let expectedPublicKey = MockData.generatePublicKey()
        let expectedFirstName = "Test"
        let expectedLastName = "Tester"

        let userSettingsMock = UserSettingsMock()
        let em = EntityManager(databaseContext: databaseMainCnx, myIdentityStore: MyIdentityStoreMock())
        let contactStore = ContactStore(userSettings: userSettingsMock, entityManager: em)

        let identity = contactStore.addWorkContact(
            with: expectedIdentity,
            publicKey: expectedPublicKey,
            firstname: expectedFirstName,
            lastname: expectedLastName,
            acquaintanceLevel: .direct,
            entityManager: em,
            contactSyncer: nil
        )

        XCTAssertEqual(expectedIdentity, identity)
        let contactEntity = try XCTUnwrap(em.entityFetcher.contact(for: identity))
        XCTAssertEqual(expectedPublicKey, contactEntity.publicKey)
        XCTAssertEqual(expectedFirstName, contactEntity.firstName)
        XCTAssertEqual(expectedLastName, contactEntity.lastName)
        XCTAssertTrue(userSettingsMock.workIdentities.contains(expectedIdentity))
        XCTAssertTrue(userSettingsMock.profilePictureRequestList.contains(where: { $0 as? String == expectedIdentity }))
    }

    func testUpdateContactWithIdentity() throws {
        let expectedIdentity = "TESTER01"
        let expectedPublicKey = MockData.generatePublicKey()
        let expectedFirstName = "Dirsty"

        let dbPreparer = DatabasePreparer(context: databaseMainCnx.current)
        dbPreparer.save {
            let contact = dbPreparer.createContact(
                publicKey: expectedPublicKey,
                identity: expectedIdentity,
                verificationLevel: 0
            )
            contact.imageData = Data([0])
        }

        let em = EntityManager(databaseContext: databaseMainCnx, myIdentityStore: MyIdentityStoreMock())

        let contactStore = ContactStore(
            userSettings: UserSettingsMock(),
            entityManager: em
        )
        contactStore.updateContact(
            withIdentity: expectedIdentity,
            avatar: nil,
            firstName: expectedFirstName,
            lastName: nil
        )

        let contactEntity = try XCTUnwrap(em.entityFetcher.contact(for: expectedIdentity))
        XCTAssertEqual(expectedIdentity, contactEntity.identity)
        XCTAssertEqual(expectedPublicKey, contactEntity.publicKey)
        XCTAssertNil(contactEntity.imageData)
        XCTAssertEqual(expectedFirstName, contactEntity.firstName)
        XCTAssertNil(contactEntity.lastName)
    }
    
    func testUpdateContactStatus() throws {
        let expectedIdentity = "TESTER01"
        let expectedPublicKey = MockData.generatePublicKey()
        let expectedStatus = kStateActive

        let dbPreparer = DatabasePreparer(context: databaseMainCnx.current)
        var savedContact: ContactEntity?
        dbPreparer.save {
            savedContact = dbPreparer.createContact(
                publicKey: expectedPublicKey,
                identity: expectedIdentity,
                verificationLevel: 0,
                state: NSNumber(value: kStateInactive)
            )
        }

        let em = EntityManager(databaseContext: databaseMainCnx, myIdentityStore: MyIdentityStoreMock())

        let contactStore = ContactStore(
            userSettings: UserSettingsMock(),
            entityManager: em
        )
        
        XCTAssertEqual(kStateInactive, savedContact?.state?.intValue)
        
        contactStore.updateStateToActive(for: savedContact!, entityManager: em)

        let contactEntity = try XCTUnwrap(em.entityFetcher.contact(for: expectedIdentity))
        XCTAssertEqual(expectedIdentity, contactEntity.identity)
        XCTAssertEqual(expectedPublicKey, contactEntity.publicKey)
        XCTAssertNil(contactEntity.firstName)
        XCTAssertNil(contactEntity.lastName)
        XCTAssertEqual(expectedStatus, contactEntity.state?.intValue)
    }
}
