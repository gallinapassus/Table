
public enum Wrapping : UInt8, RawRepresentable, Codable, CaseIterable {

    /// Wrap at word boundaries
    case word // Prefer wrapping at word boundary (if possible)

    /// Wrap at character boundaries
    case char // Wrap at character boundary

    /// Disable wrapping, forcibly cut the cell content to fit given width
    case cut  // Disable wrapping, forcibly cut to given space
}
