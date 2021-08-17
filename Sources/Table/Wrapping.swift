
public enum Wrapping : UInt8, RawRepresentable {
    case word // Prefer wrapping at word boundary (if possible)
    case char // Wrap at character boundary
    case cut  // Disable wrapping, forcibly cut to given space
    public static let `default`:Wrapping = .char
}
