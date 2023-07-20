/// Table column type

public struct Col : Equatable, Codable {
    /// Column header text
    ///
    /// `nil` means no column header text
    ///
    /// Use `header` attributes to control how
    /// column header is positioned and displayed in the header cell.
    /// Header alignment does not affect the actual data cell
    /// alignment or wrapping defined by `columnAlignment`
    /// and `wrapping`)

    public let header:Txt?

    /// Column width

    internal (set) public var width:Width

    /// Column default alignment
    ///
    /// Use `defaultAlignment` alignment for this column
    /// when cell doesn't have alignment defined.

    public let defaultAlignment:Alignment

    /// Column default wrapping
    ///
    /// Use `defaultWrapping` wrapping for this column
    /// when cell doesn't have wrapping defined.

    public let defaultWrapping:Wrapping

    /// Column data content hint
    ///
    /// Column data content hint can improve table rendering speeds
    /// when column cell data is known to have repetitive cells. Default
    /// value is `.repetitive`
    ///
    /// - Note: Leaving this value to .repetitive when all column cells are
    /// unique will not have an extra negative impact on rendering speed,
    /// but will un-necessarily consume more memory during render.

    public let contentHint:ColumnContentHint

    /// Initialize table column

    public init(_ header:Txt? = nil,
                width:Width = .auto,
                defaultAlignment:Alignment = .topLeft,
                defaultWrapping:Wrapping = .char,
                contentHint:ColumnContentHint = .repetitive) {
        self.header = header
        self.width = width
        self.defaultAlignment = defaultAlignment
        self.defaultWrapping = defaultWrapping
        self.contentHint = contentHint
    }
}
extension Col : ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    /// Initialize table column from string literal
    ///
    /// - Parameters:
    ///     - stringLiteral: Column text
    ///
    /// - Note: Rest of the column attributes are initialized with
    /// their default values.
    ///
    /// Default values:
    /// - width: `.auto`
    /// - defaultAlignment: `.topLeft`
    /// - defaultWrapping: `.char`
    /// - contentHint: `.repetitive`

    public  init(stringLiteral value: String) {
        self.init(Txt(value))
    }
}
extension Col : ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int

    /// Initialize table column from integer literal
    ///
    /// - Parameters:
    ///     - integerLiteral: Column text
    ///
    /// - Note: Rest of the column attributes are initialized with
    /// their default values.
    ///
    /// Default values:
    /// - header: `nil`
    /// - defaultAlignment: `.topLeft`
    /// - defaultWrapping: `.char`
    /// - contentHint: `.repetitive`

    public init(integerLiteral value: Int) {
        self.init(width: Width.value(value))
    }
}
extension Col {
    /// Initialize table column

    public init(_ string:String,
                width:Width = .auto,
                align:Alignment = .topLeft,
                wrapping:Wrapping = .char,
                contentHint:ColumnContentHint = .repetitive) {
        self.init(Txt(string), width: width, defaultAlignment: align, defaultWrapping: wrapping, contentHint: contentHint)
    }
}
public enum ColumnContentHint : Equatable, Codable {
    /// Content cells are known to be unique
    case unique
    /// Content cells are known to be repetitive (not completely unique)
    case repetitive
}
