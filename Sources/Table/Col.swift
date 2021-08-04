
public struct Col {
    public let header:Txt?
    internal (set) public var width:Width
    public let alignment:Alignment
    public let wrapping:Wrapping
    public let contentHint:ColumnContentHint
    public init(header:Txt?, width:Width = .auto,
                alignment:Alignment,
                wrapping:Wrapping = .default,
                contentHint:ColumnContentHint = .repetitive) {
        self.header = header
        self.width = width
        self.alignment = alignment
        self.wrapping = wrapping
        self.contentHint = contentHint
    }
}

public enum ColumnContentHint {
    case unique, repetitive
}
