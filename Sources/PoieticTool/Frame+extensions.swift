//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 29/06/2023.
//

// Extensions to the Frame objects that are tool specific. They might
// be moved later to the Core if considered generally useful.
//
import PoieticCore
import PoieticFlows

extension FrameBase {
    public func object(named name: String) -> ObjectSnapshot? {
        for object in snapshots {
            guard let component: ExpressionComponent = object[ExpressionComponent.self] else {
                continue
            }
            if component.name == name {
                return object
            }
        }
        return nil
    }
    
    /// Get an object by a string reference - the string might be an object name
    /// or object ID.
    ///
    /// First the string is converted to object ID and an object with the given
    /// ID is searched for. If not found, then all named objects are searched
    /// and the first one with given name is returned. If multiple objects
    /// have the same name, then one is returned arbitrarily. Subsequent
    /// calls to the method with the same name do not guarantee that
    /// the same object will be returned if multiple objects have the same name.
    ///
    public func object(stringReference: String) -> ObjectSnapshot? {
        if let id = ObjectID(stringReference), contains(id) {
            return object(id)!
        }
        else if let snapshot = object(named: stringReference) {
            return snapshot
        }
        else {
            return nil
        }

    }
}

extension MutableFrame {
    public func setAttribute(_ id: ObjectID,
                             value: ForeignValue,
                             forKey key: AttributeKey) throws {
        let orig = self.object(id)!
        let object = self.mutableObject(id)
        try object.setAttribute(value: value, forKey: key)

        let value2 = object.attribute(forKey: key)!
    }
}
