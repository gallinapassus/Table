
public enum Wrapping : UInt8, RawRepresentable {
    case word // Prefer wrapping at word boundary (if possible)
    case char // Wrap at character boundary
    case fit  // Disable wrapping, forcibly fit to given space (may cut off excess content)
    public static let `default`:Wrapping = .char
}
