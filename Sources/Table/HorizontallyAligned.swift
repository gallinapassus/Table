
internal class HorizontallyAligned : Codable {
    let lines:[String]
    let alignment:Alignment
    let width:Width
    let wrapping:Wrapping?
    internal init(lines: [String], alignment: Alignment, width: Width = .auto, wrapping:Wrapping? = .default) {
        self.lines = lines
        self.alignment = alignment
        self.width = width
        self.wrapping = wrapping
    }
}
