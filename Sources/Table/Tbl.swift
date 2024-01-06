import Foundation
import DebugKit

/// Maximum number of table columns.
///
/// Current maximum column count is set to be equal to `UInt16.max`.
internal let maxColumnCount:Int = Int(UInt16.max)

// MARK: Globals
/// Default line number generator
///
/// Generates default line numbers (base-10). Default
/// line number generator generates line numbers starting
/// from 1.
///
/// - Note: `lineNumberGenerator` function is called for
/// each line (on given row ranges) with line number as argument.

public let defaultLnGen:(Int) -> Txt = { n in
    return Txt((1 + n).description)
}
extension DebugTopic {
    // Topics
    internal static let info = DebugTopic(level: 0, "info")
    internal static let warning = DebugTopic(level: 1, "warning")
    internal static let error = DebugTopic(level: 2, "error")
    internal static let telemetry = DebugTopic(level: 3, "telemetry")
    internal static let cache = DebugTopic(level: 4, "cache")
    internal static let columns = DebugTopic(level: 5, "columns")
    internal static let cells = DebugTopic(level: 6, "cells")
    // A allTopics "mask" including all topics
    internal static let allTopics:DebugTopicSet = [
        .info, .warning, .error, .telemetry, .cache, .columns, .cells
    ]
}
// MARK: -

/// Table class
///
/// `Tbl` class encapsulates required data to represent trivial tables.
///
/// Example (using DSL)
///
///```swift
///import Table
///
///let table = Tbl("Summer Olympics") {
///
///    Columns {
///        Col("Year", width: 4)
///        Col("Host", width: .in(5...25), defaultWrapping: .word)
///        Col("Country")
///    }
///
///    Rows {
///        ["1952", "Helsinki", "Finland"]
///        ["1956", "Stockholm", "Sweden"]
///        ["1960", "Rome", "Italy"]
///    }
///}
///print(table.render(style: .rounded))
/////╭──────────────────────╮
/////│   Summer Olympics    │
/////├────┬─────────┬───────┤
/////│Year│Host     │Country│
/////├────┼─────────┼───────┤
/////│1952│Helsinki │Finland│
/////├────┼─────────┼───────┤
/////│1956│Stockholm│Sweden │
/////├────┼─────────┼───────┤
/////│1960│Rome     │Italy  │
/////╰────┴─────────┴───────╯
///```
public final class Tbl {
    /// Table cell data
    public let cells:[[Txt]]
    /// Table column definitions.
    public let columns:[Col]
    /// Table title
    public let title:Txt?
    
    /// Customizable line number generator
    ///
    /// If this function is defined, `Tbl` will automatically insert an additional
    /// column (to position 0). Column will not have a header and it has a
    /// `defaultColumnAlignment` set to bottom right (which can be
    /// overridden by the returned `Txt` if needed).
    ///
    /// This function will be called once for each row  selected for rendering.

    private let lineNumberGenerator:((Int)->Txt)?

    public var debugMask:DebugTopicSet = []
    
    /// Initializes table
    ///
    /// - Parameters:
    ///     - title: Table title
    ///     - columns: Table column definitions
    ///     - cells: Table cell data
    ///     - lineNumberGenerator: Customisable line number generator

    public init(_ title:Txt? = nil,
                columns: [Col] = [],
                cells:[[Txt]],
                lineNumberGenerator:((Int)->Txt)? = nil) {
        
        precondition(columns.count <= maxColumnCount, "Maximum column count is limited to \(maxColumnCount).")

        self.cells = cells
        self.title = title
        self.columns = columns
        self.lineNumberGenerator = lineNumberGenerator

        dbg(.info, debugMask, prefix: "\(type(of: self))", "\(columns.count) columns")
        dbg(.info, debugMask, prefix: "\(type(of: self))", "\(cells.reduce(0, { $0 + $1.count })) cells")
    }

    /// Initializes table
    ///
    /// - Parameters:
    ///     - title: Table title
    ///     - columns: Table column definitions
    ///     - cells: Table cell data

    public convenience init(_ title:String,
                            columns: [Col] = [],
                            cells:[[Txt]],
                            lineNumberGenerator:((Int)->Txt)? = nil) {
        self.init(
            Txt(title, alignment: .bottomCenter, wrapping: .word),
            columns: columns,
            cells: cells,
            lineNumberGenerator: lineNumberGenerator
        )
    }
    /// TnlBuilder initializer
    ///
    /// - Parameters:
    ///     - title: Table title

    public convenience init(
        _ title:Txt?,
        @TblBuilder _ makeTable: () -> ([Col], [[Txt]])) {
            let (columns, cells) = makeTable()
            self.init(title, columns: columns, cells: cells)
    }

    /// Calculates table title width
    ///
    /// Title width depends on `FrameStyle`, `FramingOptions` and columns.
    ///
    /// - Parameters:
    ///     - style: Frame style
    ///     - options: Framing options
    ///     - for: Array of FixedCols

    private func titleCellWidth(style:FrameStyle,
                                options:FramingOptions,
                                for columns:[FixedCol]) -> Int {
        let ivsLen = style.insideVerticalSeparator(for: options).count
        let titleCellWidth = columns.reduce(0, { $0 + $1.width }) + ((columns.count - 1) * ivsLen)
        return titleCellWidth
    }

    /// Renders table
    ///
    /// - Parameters:
    ///   - style: Frame style
    ///   - options: Framing options
    ///   - rows: Collection of row ranges to render, default value of `nil` means all rows
    ///   - leftPad: Pad left side of the table with `String`
    ///   - rightPad: Pad right side of the table with `String`
    ///   - to: Receiver for the rendering result

    public func render(style:FrameStyle = .default,
                      options:FramingOptions = .all,
                      rows ranges:[Range<Int>]? = nil,
                      leftPad:String = "",
                      rightPad:String = "",
                      to out: inout String) {

        let t0 = DispatchTime.now().uptimeNanoseconds // NOTE: Drags in Foundation!!!
        cells.render(
            title: title,
            columns: columns,
            style: style,
            options: options,
            rows: ranges,
            leftPad: leftPad,
            rightPad: rightPad,
            to: &out,
            debugMask: debugMask,
            lineNumberGenerator: lineNumberGenerator)
        let t1 = DispatchTime.now().uptimeNanoseconds
        let ms = Double(t1-t0) / 1_000_000
        let range_count = ranges?.reduce(0, { $0 + $1.count }) ?? cells.count
        let cell_count = (ranges ?? [(0..<cells.count)])
            .reduce(0, {
                $0 + $1.reduce(0, {
                    $0 + cells[$1].count
                }
                )
            }
            )
        let ms_per_row = ms / Double(range_count)
        let ms_per_cell = ms / Double(cell_count)
        dbg(.telemetry, debugMask,
            "Total table rendering time (includes pre-formatting): \(ms) ms")
        dbg(.telemetry, debugMask,
            "Avg rendering time (\(range_count) rows): \(ms_per_row) ms/row")
        dbg(.telemetry, debugMask,
            "Avg rendering time (\(cell_count) cells): \(ms_per_cell) ms/cell")
    }

    /// Render table
    /// - Parameters:
    ///   - style: Frame style
    ///   - options: Framing options
    ///   - rows: Collection of row ranges to render, default value of `nil` means all rows
    ///   - leftPad: Pad left side of the table with `String`
    ///   - rightPad: Pad right side of the table with `String`
    /// - Returns: `String` containing rendered table

    public func render(style:FrameStyle = .default,
                       options:FramingOptions = .all,
                       rows ranges:[Range<Int>]? = nil,
                       leftPad:String = "",
                       rightPad:String = "") -> String {
        var result: String = ""
        render(style: style,
               options: options,
               rows: ranges,
               leftPad: leftPad,
               rightPad: rightPad,
               to: &result)
        return result
    }

    /// Convert table data to CSV format
    /// - Parameters:
    ///   - delimiter: Delimiter, default `;`
    ///   - withColumnHeaders: Boolean value indicating if column headers should be included
    ///   - includingHiddenColumns: Boolean value indicating if hidden columns should be included
    /// - Returns: `String` containing table data formatted as CSV

    public func csv(delimiter:String = ";", withColumnHeaders:Bool = true, includingHiddenColumns:Bool = false) -> String {
        let maxRowCellCount = cells.reduce(0, { Swift.max($0, $1.count) })
        var result = ""
        let c:[Col] = columns + Array(repeating: Col(""), count: Swift.max(0, maxRowCellCount - columns.count))
        if withColumnHeaders {
            let headers = c
                .filter({
                    if includingHiddenColumns {
                        return true
                    }
                    else {
                        return $0.dynamicWidth != .hidden
                    }
                })
                .map({ $0.header?.string ?? ""})
                .joined(separator: delimiter)
            print(headers + (headers.isEmpty ? "" : delimiter), to: &result)
        }

        for row in cells {
            var rowElements:[String] = []
            for (i,col) in row.enumerated() {
                guard c.indices.contains(i),
                      (c[i].dynamicWidth == .hidden && includingHiddenColumns == false) == false else {
                    continue
                }
                rowElements.append(col.string)
            }
            print(rowElements.joined(separator: delimiter) + String(repeating: delimiter, count: Swift.max(0, c.count - row.count)) + delimiter, to: &result)
        }
        return result
    }
}

extension Tbl : Codable {
    private enum CodingKeys : CodingKey {
        case cellsMayHaveNewlines, cells, columns, title
    }

    /// Encode table
    /// - Important: Table's `lineNumberGenerator` and `debugMask` are not encoded.

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cells, forKey: .cells)
        try container.encode(columns, forKey: .columns)
        try container.encode(title, forKey: .title)
        // NOTE: Automatic line number generator is not included in encoded object
        // TODO: Allow setting of lineNumberGenerator after init
    }
    public convenience init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let cells = try container.decode([[Txt]].self, forKey: .cells)
        let columns = try container.decode([Col].self, forKey: .columns)
        let title = try container.decode(Txt.self, forKey: .title)
        self.init(title, columns: columns, cells: cells, lineNumberGenerator: nil)
    }
}

extension Tbl : Equatable {
    /// - Note: Ignores automatic line numbering
    public static func == (lhs: Tbl, rhs: Tbl) -> Bool {
        lhs.cells == rhs.cells &&
        lhs.columns == rhs.columns &&
        lhs.title == rhs.title
    }
}
