/// Table column type
/*
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
 
 /// Column dynamic width
 
 internal (set) public var dynamicWidth:Width
 
 /// Column fixed width
 
 public var width:Int?
 
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
 self.dynamicWidth = width
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
 self.init(width: Width.fixed(value))
 }
 }
 extension Col {
 /// Initialize table column
 
 public init(_ string:String,
 width:Width = .auto,
 defaultAlignment:Alignment = .topLeft,
 defaultWrapping:Wrapping = .char,
 contentHint:ColumnContentHint = .repetitive) {
 self.init(Txt(string), width: width, defaultAlignment: defaultAlignment, defaultWrapping: defaultWrapping, contentHint: contentHint)
 }
 }*/
public enum ColumnContentHint : Equatable, Codable {
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
public struct Col : Equatable, Codable {
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
        self.init(Txt(string), width: width, defaultAlignment: defaultAlignment, defaultWrapping: defaultWrapping, contentHint: contentHint)
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
/*
extension FixedCol : CustomStringConvertible {
    var description: String {
        "\(type(of: self))(\(header), \(defaultAlignment), \(defaultWrapping), \(trimming), \(width), \(ref), \(isHidden))"
    }
}*/
extension Array where Array.Element == Col {
    /// Perform `Col` to `FixedCol` conversion.
    ///
    /// Collects and returns also other cell data related
    /// information like `minRowElementCount` and
    /// `maxRowElementCount`.
    internal func collectTableInfo(using data:[[Txt]],
                      cellDataContainsNewlines:Bool = false,
                          lineNumberGenerator:((Int) -> Txt)?) -> (columns:[FixedCol], minRowElementCount:Int, maxRowElementCount:Int, rowElementCountHistogram:[Int:Int]) {

        var rowElementCountHistogram:[Int:Int] = [:]
        /*
        for (columnIndex, column) in self.enumerated() {
            // Minimum width for this cell
            var lo:Int = {
                switch column.dynamicWidth {
                case .min(let v): return v
                case .range(let r): return r.lowerBound
                case .in(let r): return r.lowerBound
                default: return 0
                }
            }()
            // Calculate the optimal column widths for dynamic
            // width columns from cell data. A single pass through
            // cell data is needed.
            var hi = lo
            for row in using {
                minRowElementCount = Swift.min(minRowElementCount, row.count)
                maxRowElementCount = Swift.max(maxRowElementCount, row.count)
                rowElementCountHistogram[row.count, default: 0] += 1
                // Optimization: continue, if current row has
                // fewer cells than what the current recalc index is.
                guard row.count > columnIndex else { continue }
                let cell = row[columnIndex]

                // Are we expecting cell data to contain newlines
                if cellDataContainsNewlines {
                    // yes, cell data may contain newlines
                    // now, split the column cell at newlines
                    // and find out the lower and upper range
                    // of these row cell fragments
                    cell
                        .split(separator: "\n", omittingEmptySubsequences: false)
                        .forEach({
                            lo = Swift.min(lo, $0.count)
                            hi = Swift.max(hi, $0.count)
                        })
                }
                else {
                    // no, cell data does not contain newlines
                    // quickly find out the lower and upper range
                    // for this row cell
                    lo = Swift.min(lo, cell.count)
                    hi = Swift.max(hi, cell.count)
                }
            }
            print("[\(columnIndex)] min ... max = \(lo) ... \(hi)")
            
            // Set the actual column width, based on the
            // given column dynamicWidth definitions and calculations
            // from cell data
            let fixed:Int
            switch column.dynamicWidth {
            case .min(let min):
                fixed = Swift.max(min, hi)
            case .max(let max):
                fixed = Swift.min(max, hi)
            case .in(let closedRange):
                fixed = Swift.max(Swift.min(closedRange.upperBound, hi), closedRange.lowerBound)
            case .range( let range):
                fixed = Swift.max(Swift.min(range.upperBound - 1, hi), range.lowerBound)
            case .auto:
                fixed = Swift.max(0, hi)
            case .fixed(let v):
                fixed = v
            case .collapsed:
                fixed = 0
            case .hidden:
                continue
            }
            let fixedCol = FixedCol(
                ColumnBase(
                    column.header,
                    defaultAlignment: column.defaultAlignment,
                    defaultWrapping: column.defaultWrapping,
                    contentHint: column.contentHint
                ),
                width: fixed,
                ref: columnIndex,
                hidden: column.dynamicWidth == .hidden
            )

            tmp.append(fixedCol)
        }
        */
        var dict:[Int:Col] = Dictionary<Int,Col>(
            uniqueKeysWithValues: enumerated().map({ $0 })
        )
        var columnFixedWidth:[Int:Int] = [:]
        let defCol = Col(width: .auto, defaultAlignment: .topLeft, defaultWrapping: .char)
        var minRowElementCount:Int = Int.max
        var maxRowElementCount:Int = Int.min
        for (_, row) in data.enumerated() {
            minRowElementCount = Swift.min(minRowElementCount, row.count)
            maxRowElementCount = Swift.max(maxRowElementCount, row.count)
            rowElementCountHistogram[row.count, default: 0] += 1
            if dict.count < maxRowElementCount {
                (dict.count..<maxRowElementCount).forEach { dict[$0] = defCol }
            }
            for (ci,cell) in row.enumerated() {
                var lo:Int = {
                    switch dict[ci]!.dynamicWidth {
                    case .min(let v): return v
                    case .range(let r): return r.lowerBound
                    case .in(let r): return r.lowerBound
                    default: return 0
                    }
                }()
                var hi = 0
                // Are we expecting cell data to contain newlines
                if cellDataContainsNewlines {
                    // yes, cell data may contain newlines
                    // now, split the column cell at newlines
                    // and find out the lower and upper range
                    // of these row cell fragments
                    cell
                        .split(separator: "\n", omittingEmptySubsequences: false)
                        .forEach({
                            lo = Swift.min(lo, $0.count)
                            hi = Swift.max(hi, $0.count)
                        })
                }
                else {
                    // no, cell data does not contain newlines
                    // quickly find out the lower and upper range
                    // for this row cell
                    lo = Swift.min(lo, cell.count)
                    hi = Swift.max(hi, cell.count)
                }
                switch dict[ci]!.dynamicWidth {
                case .min(let min):
                    columnFixedWidth[ci] = Swift
                        .max(columnFixedWidth[ci, default: 0],
                             Swift.max(min, hi))
                case .max(let max):
                    columnFixedWidth[ci] = Swift
                        .max(columnFixedWidth[ci, default: 0],
                             Swift.min(max, hi))
                case .in(let closedRange):
                    columnFixedWidth[ci] = Swift
                        .max(columnFixedWidth[ci, default: 0],
                             Swift.max(Swift.min(closedRange.upperBound, hi), closedRange.lowerBound))
                case .range( let range):
                    columnFixedWidth[ci] = Swift
                        .max(columnFixedWidth[ci, default: 0],
                             Swift.max(Swift.min(range.upperBound - 1, hi), range.lowerBound))
                case .auto:
                    columnFixedWidth[ci] = Swift
                        .max(columnFixedWidth[ci, default: 0],
                             Swift.max(0, hi))
                case .fixed(let v):
                    columnFixedWidth[ci] = v
                case .collapsed:
                    columnFixedWidth[ci] = 0
                case .hidden:
                    continue
                }
            }
        }
        if maxRowElementCount <= 0 {
            return (enumerated().map({
                guard let header = $0.element.header else {
                    return (FixedCol($0.element, width: 0, ref: $0.offset, hidden: $0.element.dynamicWidth == .hidden))
                }
                let l = header.string.maxFragmentWidth(separator: "\n")
                let w:Int = $0.element.dynamicWidth.value(limitedBy: l)
                return FixedCol(
                    $0.element,
                    width: w,
                    ref: $0.offset,
                    hidden: $0.element.dynamicWidth == .hidden
                )
            }), 0, 0, [:])
        }

        var result:[FixedCol] = columnFixedWidth
            .sorted(by: { $0.key < $1.key })
            .map({
                FixedCol(
                    dict[$0.key]!,
                    width: $0.value,
                    ref: $0.key,
                    hidden: dict[$0.key]!.dynamicWidth == .hidden
                )
            })

        // Insert additional line number column (at index 0)
        // if lineNumberGenerator function is defined.
        //
        // This implementation is a compromise between 'line
        // numbers will always fit vertically on a single
        // line' and 'don't waste time in generating all line
        // numbers in advance just to know their widths'.
        //
        // Required column width is calculated with the
        // assumption that last line number is the one requiring
        // the longest column width. This assumption can of course
        // be wrong in some cases and will result to a column
        // width which is too narrow. In those cases, line number
        // doesn't fit on a single line, but will be fragmented
        // over multiple lines (vertically).
        if let lnGen = lineNumberGenerator {
            let lastLineNumber = lnGen(data.count)
            let fragments = lastLineNumber
                .split(separator: "\n",
                       maxSplits: lastLineNumber.string.count,
                       omittingEmptySubsequences: false)
            var requiredWidth:Int = 0
            fragments.forEach({
                requiredWidth = Swift.max(requiredWidth, $0.count)
            })
            
            let autoLNcolumn = FixedCol(
                ColumnBase(
                    defaultAlignment: .bottomRight,
                    defaultWrapping: .cut,
                    contentHint: .unique
                ),
                width: requiredWidth,
                ref: -1,
                hidden: false
            )
            result.insert(autoLNcolumn, at: 0)
        }
        
        return (result, minRowElementCount, maxRowElementCount, rowElementCountHistogram)
    }
}
/*
 internal struct FixedCol {
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
 
 let width:Int
 
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
 
 public init(header: Txt?, width: Int,
 defaultAlignment: Alignment = .topLeft,
 defaultWrapping: Wrapping = .char,
 contentHint: ColumnContentHint = .repetitive) {
 self.header = header
 self.width = width
 self.defaultAlignment = defaultAlignment
 self.defaultWrapping = defaultWrapping
 self.contentHint = contentHint
 }
 public init(dynamicColumn: Col, width: Int) {
 self.header = dynamicColumn.header
 self.width = width
 self.defaultAlignment = dynamicColumn.defaultAlignment
 self.defaultWrapping = dynamicColumn.defaultWrapping
 self.contentHint = dynamicColumn.contentHint
 }
 }
 */
