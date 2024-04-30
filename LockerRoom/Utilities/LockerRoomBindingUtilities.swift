//
//  LockerRoomBindingUtilities.swift
//  LockerRoom
//
//  Created by Nolan Astrein on 4/29/24.
//

import SwiftUI

// TODO:
// When a `String` property of an `@Observable` class (with an emtpy string intial value) is bound to a `TextField`,
// the property receives a `didSet` callback for the initial empty string and any additional characters typed into
// the `TextField`. Therefore, if a single character is type into the `TextField` there are two preceived changes
// to the observeable property but sometimes the `View` observing this property will only re-render its body once.
// An issue can occur where a `View` is marked dirty after the first setting of the observed property resulting in
// a re-rendering of its body but the `View` is not marked dirty after the second setting of the observed property
// when it actually contains the update value. The following `Binding` extension deduplicates updates to a `Binding`
// when the underlying value has not changed to prevent that first no-op property set from marking the `View` dirty.
extension Binding where Value: Equatable {
    var deduplicatedBinding: Binding<Value> {
        Binding(
            get: {
                self.wrappedValue
            },
            set: { newValue in
                if newValue != self.wrappedValue {
                    self.wrappedValue = newValue
                }
            }
        )
    }
}
