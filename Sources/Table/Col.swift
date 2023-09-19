public enum ColumnContentHint : String, Equatable, Codable, CaseIterable {
    /// Content cells are known to be unique
    case unique
    /// Content cells are known to be repetitive (not completely unique)
    case repetitive
}

/// Internal table column type which has column width calculated
/// based on table cell data.
internal struct ColumnBase : Equatable, Codable {

    internal (set) public var dynamicWidth:Width

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
    
    /// Cell data trimming options for the column
    ///
    /// Trim each cell (on this column) according to `TrimmingOptions`.
    /// By default, cells are not trimmed.
    public let trimming:TrimmingOptions
    
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
    
    public init(
        _ header:Txt? = nil,
        dynamicWidth:Width = .auto,
        defaultAlignment:Alignment = .topLeft,
        defaultWrapping:Wrapping = .char,
        trimming:TrimmingOptions = [],
        contentHint:ColumnContentHint = .repetitive) {
        self.header = header
        self.defaultAlignment = defaultAlignment
        self.defaultWrapping = defaultWrapping
        self.trimming = trimming
        self.contentHint = contentHint
        self.dynamicWidth = dynamicWidth
    }
}
public struct Col : Equatable {
    private let _base:ColumnBase
    public var dynamicWidth:Width { _base.dynamicWidth }
    public var header:Txt? { _base.header }
    public var defaultAlignment:Alignment { _base.defaultAlignment }
    public var defaultWrapping:Wrapping { _base.defaultWrapping }
    public var trimming:TrimmingOptions { _base.trimming }
    public var contentHint:ColumnContentHint { _base.contentHint }
    public init(_ header:Txt? = nil,
                width:Width = .auto,
                defaultAlignment:Alignment = .topLeft,
                defaultWrapping:Wrapping = .char,
                trimming:TrimmingOptions = [],
                contentHint:ColumnContentHint = .repetitive) {
        self._base = ColumnBase(header,
                                dynamicWidth: width,
                                defaultAlignment: defaultAlignment,
                                defaultWrapping: defaultWrapping,
                                trimming: trimming,
                                contentHint: contentHint)
    }
}
extension Col : Codable {
    enum CodingKeys : CodingKey {
        case header, width, defaultAlignment, defaultWrapping, trimming, contentHint
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(header, forKey: .header)
        try container.encode(dynamicWidth, forKey: .width)
        try container.encode(defaultAlignment, forKey: .defaultAlignment)
        try container.encode(defaultWrapping, forKey: .defaultWrapping)
        try container.encode(trimming, forKey: .trimming)
        try container.encode(contentHint, forKey: .contentHint)
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let header = try container.decode(Txt.self, forKey: .header)
        let dynamicWidth = try container.decode(Width.self, forKey: .width)
        let defaultAlignment = try container.decode(Alignment.self, forKey: .defaultAlignment)
        let defaultWrapping = try container.decode(Wrapping.self, forKey: .defaultWrapping)
        let trimming = try container.decode(TrimmingOptions.self, forKey: .trimming)
        let contentHint = try container.decode(ColumnContentHint.self, forKey: .contentHint)
        self.init(
            header,
            width: dynamicWidth,
            defaultAlignment: defaultAlignment,
            defaultWrapping: defaultWrapping,
            trimming: trimming,
            contentHint: contentHint
        )
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
    /// - trimming: `[]`
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
    /// - trimming: `[]`
    /// - contentHint: `.repetitive`
    
    public init(integerLiteral value: Int) {
        self.init(width: Width.fixed(value))
    }
}
extension Col {
    /// Initialize table column
    
    public init(_ string:String,
                width:Width = .auto,
                defaultAlignment:Alignment = .topLeft,
                defaultWrapping:Wrapping = .char,
                trimming:TrimmingOptions = [],
                contentHint:ColumnContentHint = .repetitive) {
        self.init(Txt(string), width: width, defaultAlignment: defaultAlignment, defaultWrapping: defaultWrapping, trimming: trimming, contentHint: contentHint)
    }
}
internal struct FixedCol {
    private let _base:ColumnBase
    public var header:Txt? { _base.header }
    public var defaultAlignment:Alignment { _base.defaultAlignment }
    public var defaultWrapping:Wrapping { _base.defaultWrapping }
    public var trimming:TrimmingOptions { _base.trimming }
    public var contentHint:ColumnContentHint { _base.contentHint }
    public var dynamicWidth:Width { _base.dynamicWidth }
    public let isHidden:Bool
    public var isVisible:Bool { !isHidden }
    public var isLineNumber:Bool { ref < 0 }
    public let width:Int
    public let ref:Int
    public init(_ base: ColumnBase, width: Int, ref:Int, hidden:Bool) {
        self._base = base
        self.width = width
        self.ref = ref
        self.isHidden = hidden
    }
    public init(_ col: Col, width: Int, ref:Int, hidden:Bool) {
        self._base = ColumnBase(
            col.header,
            dynamicWidth: col.dynamicWidth,
            defaultAlignment: col.defaultAlignment,
            defaultWrapping: col.defaultWrapping,
            contentHint: col.contentHint
        )
        self.width = width
        self.ref = ref
        self.isHidden = hidden
    }
}
extension FixedCol : Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(_base.trimming)
        hasher.combine(width)
    }
}
