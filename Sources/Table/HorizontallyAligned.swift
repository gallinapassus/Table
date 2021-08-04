
internal class HorizontallyAligned {
    let lines:[String]
    let alignment:Alignment
    let width:Width
    let wrapping:Wrapping?
    lazy var verticallyAligned:[[String]] = {
        [align(self, forHeight: lines.count)].transposed()
    }()
    internal init(lines: [String], alignment: Alignment, width: Width = .auto, wrapping:Wrapping? = .default) {
        self.lines = lines
        self.alignment = alignment
        self.width = width
        self.wrapping = wrapping
    }
}
