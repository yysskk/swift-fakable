/// Resolves the default value `fake()` uses for a parameter of a given type.
///
/// The same rules apply to a struct's stored properties and to an enum case's
/// associated values, so both paths go through here.
enum DefaultValue {
    static func resolve(type: String, isOptional: Bool) -> String {
        if isOptional {
            return "nil"
        }

        switch type {
        case "String":
            return "\"\""
        case "Int", "Int8", "Int16", "Int32", "Int64",
            "UInt", "UInt8", "UInt16", "UInt32", "UInt64":
            return "0"
        case "Double", "Float", "CGFloat":
            return "0.0"
        case "Bool":
            return "false"
        default:
            // Dictionary check must come before Array check
            if type.hasPrefix("[") && type.contains(":") && type.hasSuffix("]") {
                return "[:]"
            }
            if type.hasPrefix("[") && type.hasSuffix("]") {
                return "[]"
            }
            // For other types (structs, enums, etc.), try to use .fake()
            // If the type doesn't have .fake(), users can provide explicit default values
            return ".fake()"
        }
    }

    static func resolve(for property: StoredProperty) -> String {
        resolve(type: property.type, isOptional: property.isOptional)
    }

    static func resolve(for parameter: EnumCaseParameter) -> String {
        resolve(type: parameter.type, isOptional: parameter.isOptional)
    }
}
