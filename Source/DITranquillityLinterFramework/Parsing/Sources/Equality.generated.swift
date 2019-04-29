// Generated using Sourcery 0.13.1 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// swiftlint:disable vertical_whitespace


extension AssociatedValue {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? AssociatedValue else { return false }
        if self.localName != rhs.localName { return false }
        if self.externalName != rhs.externalName { return false }
        if self.typeName != rhs.typeName { return false }
        if self.annotations != rhs.annotations { return false }
        return true
    }
}
extension ClosureType {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? ClosureType else { return false }
        if self.name != rhs.name { return false }
        if self.parameters != rhs.parameters { return false }
        if self.returnTypeName != rhs.returnTypeName { return false }
        if self.`throws` != rhs.`throws` { return false }
        return true
    }
}
extension DictionaryType {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? DictionaryType else { return false }
        if self.name != rhs.name { return false }
        if self.valueTypeName != rhs.valueTypeName { return false }
        if self.keyTypeName != rhs.keyTypeName { return false }
        return true
    }
}
extension EnumCase {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? EnumCase else { return false }
        if self.name != rhs.name { return false }
        if self.rawValue != rhs.rawValue { return false }
        if self.associatedValues != rhs.associatedValues { return false }
        if self.annotations != rhs.annotations { return false }
        return true
    }
}
extension GenericTypeParameter {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? GenericTypeParameter else { return false }
        if self.typeName != rhs.typeName { return false }
        return true
    }
}
extension Method {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Method else { return false }
        if self.name != rhs.name { return false }
        if self.selectorName != rhs.selectorName { return false }
        if self.parameters != rhs.parameters { return false }
        if self.returnTypeName != rhs.returnTypeName { return false }
        if self.`throws` != rhs.`throws` { return false }
        if self.`rethrows` != rhs.`rethrows` { return false }
        if self.accessLevel != rhs.accessLevel { return false }
        if self.isStatic != rhs.isStatic { return false }
        if self.isClass != rhs.isClass { return false }
        if self.isFailableInitializer != rhs.isFailableInitializer { return false }
        if self.annotations != rhs.annotations { return false }
        if self.definedInTypeName != rhs.definedInTypeName { return false }
        if self.attributes != rhs.attributes { return false }
        return true
    }
}
extension MethodParameter {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? MethodParameter else { return false }
        if self.argumentLabel != rhs.argumentLabel { return false }
        if self.name != rhs.name { return false }
        if self.typeName != rhs.typeName { return false }
        if self.`inout` != rhs.`inout` { return false }
        if self.defaultValue != rhs.defaultValue { return false }
        if self.annotations != rhs.annotations { return false }
        return true
    }
}
extension TupleElement {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? TupleElement else { return false }
        if self.name != rhs.name { return false }
        if self.typeName != rhs.typeName { return false }
        return true
    }
}
extension TypeName {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? TypeName else { return false }
        if self.name != rhs.name { return false }
        if self.generic != rhs.generic { return false }
        if self.isGeneric != rhs.isGeneric { return false }
        if self.attributes != rhs.attributes { return false }
        if self.tuple != rhs.tuple { return false }
        if self.array != rhs.array { return false }
        if self.dictionary != rhs.dictionary { return false }
        if self.closure != rhs.closure { return false }
        return true
    }
}
extension Typealias {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Typealias else { return false }
        if self.aliasName != rhs.aliasName { return false }
        if self.typeName != rhs.typeName { return false }
        if self.parentName != rhs.parentName { return false }
        return true
    }
}
extension Variable {
    /// :nodoc:
    override func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? Variable else { return false }
        if self.name != rhs.name { return false }
        if self.typeName != rhs.typeName { return false }
        if self.isComputed != rhs.isComputed { return false }
        if self.isStatic != rhs.isStatic { return false }
        if self.readAccess != rhs.readAccess { return false }
        if self.writeAccess != rhs.writeAccess { return false }
        if self.defaultValue != rhs.defaultValue { return false }
        if self.annotations != rhs.annotations { return false }
        if self.attributes != rhs.attributes { return false }
        if self.definedInTypeName != rhs.definedInTypeName { return false }
        return true
    }
}
