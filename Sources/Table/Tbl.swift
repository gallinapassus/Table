import Foundation

public struct Tbl {
    public let data:[[Txt]]
    public let columns:[Col]
    public let title:Txt?
    public let frameStyle:FrameElements
    public let frameRenderingOptions:FrameRenderingOptions
    private var actualColumns:[Col] = []
    private let hasData:Bool
    private let hasVisibleColumns:Bool
    private let hasHeaderLabels:Bool
    private let hasTitle:Bool
    public init(_ title:Txt? = nil, columns: [Col] = [], data:[[Txt]],
                frameStyle:FrameElements = .default,
                frameRenderingOptions:FrameRenderingOptions = .all) {
        if columns.isEmpty {
            // Let's treat empty column set as "automatic columns"
            let maxColCount = data.reduce(0, { Swift.max($0, $1.count) })
            if maxColCount == 0 {
                // Actually, there is no data either, let's fake one
                self.columns = [Col(width: .auto, alignment: .topLeft)]
            }
            else {
                self.columns = Array(repeating: Col(width: .auto, alignment: .topLeft), count: maxColCount)
            }
        }
        else {
            // Silently cut-off the excess columns as
            // Tbl supports only UInt16.max columns.
            self.columns = Array(columns.prefix(Int(UInt16.max)))
        }
        self.data = data
        self.hasData = !data.isEmpty
        self.title = title
        self.frameStyle = frameStyle
        self.frameRenderingOptions = frameRenderingOptions

        // Calculate column widths for autowidth columns
        self.actualColumns = Tbl.calculateAutowidths(for: self.columns, from: data)
        self.hasVisibleColumns = !actualColumns.allSatisfy({ $0.width == .hidden })
        self.hasHeaderLabels =   !actualColumns.allSatisfy({ $0.header == nil })
        self.hasTitle = title != nil
    }
    private static func calculateAutowidths(for columns:[Col], from data: [[Txt]]) -> [Col] {
        // Figure out actual column widths (for columns which have
        // specified width as 0 => autowidth)
        if columns.allSatisfy({ $0.width > 0 }) {
            // No autowidths or hidden columns defined, use columns as they are
            return columns
        }
        else {
            // One or more columns are autowidth column -or- hidden column
            var tmp = columns
            let recalc = columns.enumerated().compactMap({ columns[$0.offset].width.rawValue > Width.auto.rawValue ? nil : $0.offset })
            for i in recalc {
                for r in data {
                    guard r.count > i else { continue }
                    let m = Swift.max(tmp[i].width.rawValue, r[i].count)
                    tmp[i].width = .value(m)
                }
                if tmp[i].width == .auto {
                    if let hdr = columns[i].header {
                        let smrt = Swift.min(hdr.count, columns.reduce(0, { $0 + ($1.header?.count ?? 0) }) / columns.count)
                        tmp[i].width = .value(Swift.max(1, smrt))
                    }
                    else {
                        tmp[i].width = 0
                    }
                }
            }
            return tmp
        }
    }
    public init(_ title:String, columns: [Col], data:[[Txt]],
                frameStyle:FrameElements = .default,
                frameRenderingOptions:FrameRenderingOptions = .all) {
        self.init(Txt(title, alignment: .middleCenter), columns: columns, data: data,
                  frameStyle: frameStyle, frameRenderingOptions: frameRenderingOptions)
    }
    private class FrameElement : ExpressibleByStringLiteral, Collection, CustomStringConvertible {
        typealias StringLiteralType = String
        public typealias Index = String.Index
        var string:String = ""
        required init(stringLiteral value:StringLiteralType) {
            self.string = value
        }
        public func append(_ other:StringLiteralType) {
            string.append(other)
        }
        public func index(after i: String.Index) -> String.Index {
            string.index(after: i)
        }
        public subscript(position: String.Index) -> String.Element {
            string[position]
        }
        public var startIndex: String.Index {
            string.startIndex
        }
        public var endIndex: String.Index {
            string.endIndex
        }
        var description: String { string }
    }
    private var titleColumnWidth:Int {
        let w = Swift.max(0, actualColumns
            .reduce(0, { $0 + $1.width.rawValue }) +
                            ((actualColumns
                                .filter({ $0.width > .hidden }).count - 1) *
                frameStyle.insideVerticalSeparator.element(for: frameRenderingOptions).count))
        if w == 0 {
            return title?.count ?? 0
        }
        else {
            return w
        }
    }
    public func render(into: inout String, leftPad:String = "", rightPad:String = "") {
        let lPad = leftPad
            .filter({ $0.isNewline == false })
        let rPad = rightPad
            .filter({ $0.isNewline == false })


        // Assign elements before entering "busy" loop,
        // so that they are not evaluated each iteration
        let leftVerticalSeparator = frameStyle.leftVerticalSeparator.element(for: frameRenderingOptions)
        let rightVerticalSeparator = frameStyle.rightVerticalSeparator.element(for: frameRenderingOptions)
        let l = "\(lPad)\(leftVerticalSeparator)"
        let r = "\(rightVerticalSeparator)\(rPad)\n"
        let insideVerticalSeparator = frameStyle.insideVerticalSeparator.element(for: frameRenderingOptions)

        // Top frame
        if frameRenderingOptions.contains(.topFrame),
           (hasTitle || hasVisibleColumns || (hasVisibleColumns && hasData)) {
            into.append(lPad)
            into.append(frameStyle.topLeftCorner.element(for: frameRenderingOptions))
            if hasTitle {
                into.append(
                    String(repeating: frameStyle.topHorizontalSeparator.element(for: frameRenderingOptions),
                           count: titleColumnWidth)
                )
            }
            else if (hasHeaderLabels && hasVisibleColumns) || hasData {
                into.append(
                    actualColumns.map({
                        String(repeating: frameStyle.topHorizontalSeparator.element(for: frameRenderingOptions),
                               count: $0.width.rawValue)
                    }).joined(separator: frameStyle.topHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                )
            }
            into.append(frameStyle.topRightCorner.element(for: frameRenderingOptions))
            into.append("\(rPad)\n")
        }


        // Title
        if let title = title {
            let alignedTitle = title.fragment(for: Col(width: .value(titleColumnWidth), alignment: title.alignment ?? .middleCenter, wrapping: title.wrapping ?? .word, contentHint: .unique))
                //.fragment(fallback: .middleCenter, width: titleColumnWidth, wrapping: .word)
                //.verticallyAligned

            for fragment in alignedTitle.lines {
                into.append(
                    lPad +
                        frameStyle.leftVerticalSeparator.element(for: frameRenderingOptions) +
                        fragment +
                        frameStyle.rightVerticalSeparator.element(for: frameRenderingOptions) +
                        "\(rPad)\n")
            }


            // Divider between title and column headers -or-
            // divider between title and data

            if frameRenderingOptions.contains(.insideHorizontalFrame),
               (hasVisibleColumns && hasHeaderLabels) || hasData || hasTitle {
                into.append(lPad)
                into.append(frameStyle.insideLeftVerticalSeparator.element(for: frameRenderingOptions))
                if hasVisibleColumns && (hasHeaderLabels || hasData) {
                    into.append(
                        actualColumns.filter({ $0.width > .hidden }).map({
                            String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                                   count: $0.width.rawValue)
                        }).joined(separator: frameStyle.topHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                    )
                }
                else {
                    into.append(
                        String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                               count: titleColumnWidth)
                    )
                }
                into.append(frameStyle.insideRightVerticalSeparator.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
        }




        // Column headers
        if hasHeaderLabels, hasVisibleColumns {

            let alignedColumnHeaders = actualColumns
                .filter({ $0.width > .hidden })
                .compactMap({ column in
                    return (column.header ?? Txt("")).fragment(for: column)
                })
                .dropFirst(0) // <= Convert Array to ArraySlice
                .alignVertically
            for f in alignedColumnHeaders {
                into.append(lPad)
                into.append(frameStyle.leftVerticalSeparator.element(for: frameRenderingOptions))
                into.append(f.joined(separator: frameStyle.insideVerticalSeparator.element(for: frameRenderingOptions)))
                into.append(frameStyle.rightVerticalSeparator.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }



            // Divider, before data
            if frameRenderingOptions.contains(.insideHorizontalFrame) {
                into.append(lPad)
                into.append(frameStyle.insideLeftVerticalSeparator.element(for: frameRenderingOptions))
                if hasHeaderLabels && hasVisibleColumns {
                    into.append(
                        actualColumns.filter({ $0.width > .hidden }).map({
                            String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                                   count: $0.width.rawValue)
                        }).joined(separator: frameStyle.insideHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                    )
                }
                else if title != nil {
                    if hasVisibleColumns {
                        into.append(
                            actualColumns.filter({ $0.width > .hidden }).map({
                                String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                                       count: $0.width.rawValue)
                            }).joined(separator: frameStyle.topHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                        )
                    }
                    else {
                        into.append(
                            String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                                   count: titleColumnWidth)
                        )
                    }
                }
                into.append(frameStyle.insideRightVerticalSeparator.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
        }



        guard hasVisibleColumns, data.count > 0 else {
            return // No columns to display -or- no data
        }
        // Data rows
        var cache:[UInt32:[Int:HorizontallyAligned]] = [:]
        var cacheHits:Int = 0
        var cacheMisses:Int = 0
        // Assign elements before entering "busy" loop,
        // so that they are not evaluated each iteration
//        let leftVerticalSeparator = frameStyle.leftVerticalSeparator.element(for: frameRenderingOptions)
//        let rightVerticalSeparator = frameStyle.rightVerticalSeparator.element(for: frameRenderingOptions)
//        let l = lPad + leftVerticalSeparator
//        let r = rightVerticalSeparator + rPad + "\n"
//        let insideVerticalSeparator = frameStyle.insideVerticalSeparator.element(for: frameRenderingOptions)
        let lastValidIndex = data.index(before: data.endIndex)
        let actualVisibleColumns = actualColumns.filter({ $0.width != .hidden })
        let actualVisibleColumnCount = actualVisibleColumns.count
        let visibleColumnIndexes = actualColumns
            .enumerated()
            .filter({ $0.element.width > .hidden })
            .map({ $0.offset })
            .prefix(Swift.min(actualVisibleColumnCount, Int(UInt16.max)))
        // Main loop to render row/column data
        /*
        var cost1:UInt64 = 0
        var cost2:UInt64 = 0
        var cost3:UInt64 = 0
         */
        for (i,row) in data.enumerated() {
            //let a0 = DispatchTime.now().uptimeNanoseconds
            var columnized:ArraySlice<HorizontallyAligned> = []
            let maxHeight:Int = visibleColumnIndexes
                .filter { $0 < row.count }
                .map {
                    if actualColumns[$0].contentHint == .repetitive {

                        // Combine width & alignment
                        let u32:UInt32 = (UInt32(actualColumns[$0].width.rawValue) << 16) +
                            UInt32(row[$0].alignment?.rawValue ?? actualColumns[$0].alignment.rawValue)

                        if let fromCache = cache[u32]?[row[$0].string.hashValue] {
                            columnized.append(fromCache)
                            cacheHits += 1
                            return fromCache.lines.count
                        }
                        else {
                            let fragmented = row[$0].fragment(for: actualColumns[$0])
                            // Write to cache
                            cache[u32, default:[:]][row[$0].string.hashValue] = fragmented
                            columnized.append(fragmented)
                            cacheMisses += 1
                            return fragmented.lines.count
                        }
                    }
                    else {
                        let fragmented = row[$0].fragment(for: actualColumns[$0])
                        columnized.append(fragmented)
                        return fragmented.lines.count
                    }
                }
                .reduce(0, { Swift.max($0, $1) })
            let missingColumnCount = Swift.max(0, actualVisibleColumnCount - columnized.count)
            let currentCount = columnized.count
            //let a1 = DispatchTime.now().uptimeNanoseconds
//            print(row.map { $0.string },
//                  "missingColumnCount", missingColumnCount,
//                  actualColumns.map { $0.width.rawValue },
//                  columnized.map { $0.lines }, terminator: " -> ")
            for k in 0..<missingColumnCount {
                let len = actualVisibleColumns[currentCount + k].width.rawValue
                let emptyLineFragment = String(repeating: " ", count: len)
                columnized.append(
                    HorizontallyAligned(lines: Array(repeating: emptyLineFragment, count: maxHeight),
                                        alignment: .topLeft,
                                        width: actualColumns[currentCount + k].width)
                )
            }
//            print(columnized.map { $0.lines }.transposed())

            //let a2 = DispatchTime.now().uptimeNanoseconds
            for columnData in columnized.prefix(actualColumns.count).alignVertically {
                into.append(l + columnData.joined(separator: insideVerticalSeparator) + r)
            }
            if i != lastValidIndex, frameRenderingOptions.contains(.insideHorizontalFrame) {
                into.append(lPad)
                into.append(frameStyle.insideLeftVerticalSeparator.element(for: frameRenderingOptions))
                into.append(
                    actualColumns.filter({ $0.width > .hidden }).map({
                        String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                               count: $0.width.rawValue)
                    }).joined(separator: frameStyle.insideHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                )
                into.append(frameStyle.insideRightVerticalSeparator.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
            /*
            let a3 = DispatchTime.now().uptimeNanoseconds
            cost1 += (a1 - a0)
            cost2 += (a2 - a1)
            cost3 += (a3 - a2)
             */
        }

        // Bottom frame
        if frameRenderingOptions.contains(.bottomFrame) {
            into.append(lPad)
            into.append(frameStyle.bottomLeftCorner.element(for: frameRenderingOptions))
            if hasVisibleColumns {
                if data.count > 0 {
                    into.append(
                        actualColumns.filter({ $0.width > .hidden }).map({
                            String(repeating: frameStyle.bottomHorizontalSeparator.element(for: frameRenderingOptions),
                                   count: $0.width.rawValue)
                        }).joined(separator: frameStyle.bottomHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                    )
                }
                else {
                    into.append(
                        String(repeating: frameStyle.bottomHorizontalSeparator.element(for: frameRenderingOptions),
                               count: titleColumnWidth)
                    )
                }
            }
            else {
                into.append(
                    String(repeating: frameStyle.bottomHorizontalSeparator.element(for: frameRenderingOptions),
                           count: titleColumnWidth)
                )
            }
            into.append(frameStyle.bottomRightCorner.element(for: frameRenderingOptions))
            into.append("\(rPad)\n")
        }
        /*
        print("missing column count cost", Double(cost1) / 1_000_000, "ms")
        print("           maxHeight cost", Double(cost2) / 1_000_000, "ms")
        print("              output cost", Double(cost3) / 1_000_000, "ms")
         */
    }
    public func render(leftPad:String = "", rightPad:String = "") -> String {
        var result = ""
        render(into: &result, leftPad: leftPad, rightPad: rightPad)
        return result
    }
}
