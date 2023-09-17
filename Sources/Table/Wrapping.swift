
public enum Wrapping : UInt8, RawRepresentable, Codable, CaseIterable, Hashable {

    /// Wrap at word boundaries
    case word // Prefer wrapping at word boundary (whenever possible)
    /// Wrap at character boundaries
    case char // Wrap at character boundary
    /// Forcibly cut the cell content to fit given width
    case cut  // Disable wrapping, forcibly fit to column width
}
extension Wrapping : CustomStringConvertible {
    public var description: String {
        switch self {
        case .char: return "char"
        case .cut: return "cut"
        case .word: return "word"
//        case .word2: return "word2"
        }
    }
}
