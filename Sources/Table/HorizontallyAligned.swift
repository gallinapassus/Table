
internal class HorizontallyAligned : Codable {
    let lines:[String]
    let alignment:Alignment
    let width:Int
    let wrapping:Wrapping?
    internal init(lines: [String], alignment: Alignment, width: Int/*Width = .auto*/, wrapping:Wrapping? = .char) {
        self.lines = lines
        self.alignment = alignment
        self.width = width
        self.wrapping = wrapping
    }
}
