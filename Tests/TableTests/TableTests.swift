import XCTest
@testable
import Table
//import Combinations
import DebugKit

extension FrameStyle {
    public static var debug: Self {
        FrameStyle(
            topLeftCorner:                        "┌",
            topHorizontalSeparator:               "┅",
            topHorizontalVerticalSeparator:       "┬",
            topRightCorner:                       "┐",
            leftVerticalSeparator:                "┆",
            rightVerticalSeparator:               "┊",
            insideLeftVerticalSeparator:          "├",
            insideHorizontalSeparator:            "┄",
            insideHorizontalRowRangeSeparator:    "╌",
            insideRightVerticalSeparator:         "┤",
            insideHorizontalVerticalSeparator:    "┼",
            insideVerticalSeparator:              "╎",
            bottomLeftCorner:                     "└",
            bottomHorizontalSeparator:            "┉",
            bottomHorizontalVerticalSeparator:    "┴",
            bottomRightCorner:                    "┘"
        )
    }
}

let pangram = "The quick brown fox jumps over the lazy dog"

final class TxtTests: XCTestCase {
    func test_init() {
        do {
            let str = "Lorem ipsum."
            let txt = Txt(str)
            XCTAssertNil(txt.alignment)
            XCTAssertEqual(txt.string, str)
            XCTAssertEqual(txt.startIndex, str.startIndex)
            XCTAssertEqual(txt.endIndex, str.endIndex)
            XCTAssertNil(txt.wrapping)
        }
        do {
            let str = "Lorem ipsum."
            for alignment in Alignment.allCases {
                for wrapping in Wrapping.allCases {
                    let txt = Txt(str,
                                  alignment: alignment,
                                  wrapping: wrapping)
                    XCTAssertEqual(txt.alignment, alignment)
                    XCTAssertEqual(txt.string, str)
                    XCTAssertEqual(txt.startIndex, str.startIndex)
                    XCTAssertEqual(txt.endIndex, str.endIndex)
                    XCTAssertEqual(txt.wrapping, wrapping)
                }
            }
        }
    }
    func test_trim() {
        var t = Txt(" \n\n  " + pangram + " \n\n  ")
        t.trim([.leadingWhiteSpaces])
        XCTAssertEqual(t.string, "\n\n" + pangram + " \n\n  ")
        t.trim([.leadingNewlines])
        XCTAssertEqual(t.string, pangram + " \n\n  ")
        t.trim([.trailingNewlines, .trailingWhiteSpaces])
        XCTAssertEqual(t.string, pangram)
        t.trim([.all])
        XCTAssertEqual(t.string, pangram)
    }
    func test_trimmed() {
        let t = Txt(" \n\n  " + pangram + " \n\n  ")
        XCTAssertEqual(t.trimmed([.leadingWhiteSpaces]).string,
                       "\n\n" + pangram + " \n\n  ")
        XCTAssertEqual(t.trimmed([.leadingNewlines]).string,
                       "   " + pangram + " \n\n  ")
        XCTAssertEqual(t.trimmed([.trailingNewlines, .trailingWhiteSpaces]).string,
                       " \n\n  " + pangram)
        XCTAssertEqual(t.trimmed([.all]).string, pangram)
    }
    func test_trimAndFrag() {
        let t = Txt(" \n\n  " + pangram + " \n\n  ")
        XCTAssertEqual(t.trimAndFragment([.leadingWhiteSpaces, .trailingWhiteSpaces]),
                       [
                        Txt("", alignment: nil, wrapping: nil),
                        Txt("", alignment: nil, wrapping: nil),
                        Txt("The quick brown fox jumps over the lazy dog", alignment: nil, wrapping: nil),
                        Txt("", alignment: nil, wrapping: nil),
                        Txt("", alignment: nil, wrapping: nil)])
        XCTAssertEqual(t.trimAndFragment([.all]),
                       [
                        Txt("The quick brown fox jumps over the lazy dog", alignment: nil, wrapping: nil)
                       ])
    }
}
final class ColTests: XCTestCase {
    func test_init() {
        do {
            let str = "Column X"
            let col = Col(str)
            XCTAssertEqual(col.defaultAlignment, .topLeft)
            XCTAssertEqual(col.contentHint, .repetitive)
            XCTAssertEqual(col.header, Txt(str))
            XCTAssertEqual(col.dynamicWidth, .auto)
            XCTAssertEqual(col.defaultWrapping, .char)
        }
        do {
            let str = "Column X"
            for width in [Width.auto, .hidden, .fixed(42), .min(6), .max(3), .in(3...6), .range(5..<10)] {
                for ca in Alignment.allCases {
                    for wrapping in Wrapping.allCases {
                        for ch in [ColumnContentHint.repetitive, .unique] {
                            let col = Col(Txt(str), width: width, defaultAlignment: ca, defaultWrapping: wrapping, contentHint: ch)
                            XCTAssertEqual(col.defaultAlignment, ca)
                            XCTAssertEqual(col.contentHint, ch)
                            XCTAssertEqual(col.header, Txt(str))
                            XCTAssertEqual(col.dynamicWidth, width)
                            XCTAssertEqual(col.defaultWrapping, wrapping)
                        }
                    }
                }
            }
        }
    }
}
final class AlignmentTests: XCTestCase {
    func test_Codable() {
        do {
            for target in Alignment.allCases {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let encoded = try encoder.encode(target)
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(Alignment.self, from: encoded)
                XCTAssertEqual(target, decoded)
            }
        } catch let e {
            dump(e)
        }
    }
}
extension TextOutputStream {
    var string:String { self as! String }
}
final class TableTests : XCTestCase {
    func test_init_subsctring() {
        do {
            let s = "abcd"
            let src:[[any StringProtocol]] = [
                [
                    // Substring
                    s[s.startIndex..<s.index(s.startIndex, offsetBy: 1)],
                    // Substring
                    Substring(stringLiteral: "replaced")
                ],
                [
                    // Substring
                    s[s.firstIndex(of: "c")!..<s.firstIndex(of: "d")!],
                    // String
                    "d"
                ]
            ]
            let table = Tbl(
                title: s[...s.firstIndex(of: "d")!],
                columns: ["C1", "C2"],
                cells: src,
                lineNumberGenerator: nil
            )
            XCTAssertEqual(table.render(style: .debug),
                           """
                           ┌┅┅┅┅┅┅┅┅┅┅┐
                           ┆   abcd   ┊
                           ├┄┬┄┄┄┄┄┄┄┄┤
                           ┆C╎C2      ┊
                           ┆1╎        ┊
                           ├┄┼┄┄┄┄┄┄┄┄┤
                           ┆a╎replaced┊
                           ├┄┼┄┄┄┄┄┄┄┄┤
                           ┆c╎d       ┊
                           └┉┴┉┉┉┉┉┉┉┉┘
                           
                           """)
        }
    }
    func test_init_string() {
        do {
            let src = [["a", "b"],["c", "d"]]
            let table = Tbl(
                title: "title",
                columns: ["C1", "C2"],
                cells: src,
                lineNumberGenerator: nil
            )
            XCTAssertEqual(table.render(style: .debug),
                           """
                           ┌┅┅┅┐
                           ┆tit┊
                           ┆le ┊
                           ├┄┬┄┤
                           ┆C╎C┊
                           ┆1╎2┊
                           ├┄┼┄┤
                           ┆a╎b┊
                           ├┄┼┄┤
                           ┆c╎d┊
                           └┉┴┉┘
                           
                           """)
        }
    }
    func test_init_txt() {
        do {
            let src:[[Txt]] = [
                [Txt("a", alignment: .topCenter), "b"],
                ["c", "d"]
            ]
            let table = Tbl(
                Txt("title", alignment: .topRight),
                columns: [
                    Col(Txt("C1", alignment: .topCenter), width: 5),
                    "C2"
                ],
                cells: src,
                lineNumberGenerator: nil
            )
            XCTAssertEqual(table.render(style: .debug),
                           """
                           ┌┅┅┅┅┅┅┅┐
                           ┆  title┊
                           ├┄┄┄┄┄┬┄┤
                           ┆ C1  ╎C┊
                           ┆     ╎2┊
                           ├┄┄┄┄┄┼┄┤
                           ┆  a  ╎b┊
                           ├┄┄┄┄┄┼┄┤
                           ┆c    ╎d┊
                           └┉┉┉┉┉┴┉┘
                           
                           """)
        }
    }
    func test_noData() {
        let columns = [
            Col("Col 1", width: 1, defaultAlignment: .topLeft),
            Col("Col 2", width: 2, defaultAlignment: .topLeft),
            Col("Col 3", width: 3, defaultAlignment: .topLeft),
        ]
        do {
            let table = Tbl(nil, columns: columns, cells: [])
            XCTAssertEqual(table.render(style: .debug),
                           """
                           ┌┅┬┅┅┬┅┅┅┐
                           ┆C╎Co╎Col┊
                           ┆o╎l ╎ 3 ┊
                           ┆l╎2 ╎   ┊
                           ┆ ╎  ╎   ┊
                           ┆1╎  ╎   ┊
                           ├┄┼┄┄┼┄┄┄┤
                           └┉┴┉┉┴┉┉┉┘

                           """)
        }
        do {
            let table = Tbl(nil, columns: [], cells: [])
            XCTAssertEqual(table.render(),
                           """
                           ++
                           ++
                           
                           """
            )
        }
        do {
            let table = Tbl(cells: []) // no data, no frames
            XCTAssertEqual(table.render(options: .none),
                           """
                           
                           """
            )
        }
        do {
            let table = Tbl("Title", cells: [])
            XCTAssertEqual(table.render(style: .roundedPadded),
                           """
                           ╭───────╮
                           │ Title │
                           ├───────┤
                           ╰───────╯
                           
                           """)
        }
        do {
            let table = Tbl("Title", cells: [])
            XCTAssertEqual(table.render(style: .rounded),
                           """
                           ╭─────╮
                           │Title│
                           ├─────┤
                           ╰─────╯
                           
                           """)
        }
        do {
            let table = Tbl(cells: [])
            XCTAssertEqual(table.render(style: .debug),
                            """
                            ┌┐
                            └┘
                            
                            """)
        }
        do {
            let columns = Array(repeating: Col(width: .fixed(0)), count: 0)
            let table = Tbl(columns: columns, cells: [])
            XCTAssertEqual(table.render(style: .debug),
                            """
                            ┌┐
                            └┘
                            
                            """)
        }
        do {
            let columns = Array(repeating: Col(width: .fixed(0)), count: 1)
            let table = Tbl(columns: columns, cells: [])
            XCTAssertEqual(table.render(style: .debug),
                            """
                            ┌┐
                            ┆┊
                            ├┤
                            └┘
                            
                            """)
        }
        do {
            let columns = Array(repeating: Col(width: .fixed(0)), count: 2)
            let table = Tbl(columns: columns, cells: [])
            XCTAssertEqual(table.render(style: .debug),
                            """
                            ┌┬┐
                            ┆╎┊
                            ├┼┤
                            └┴┘
                            
                            """)
        }
        do {
            let columns = Array(repeating: Col(width: .fixed(0)), count: 2)
            let table = Tbl(columns: columns + [Col(width: .hidden)] + columns, cells: [])
            XCTAssertEqual(table.render(style: .debug),
                            """
                            ┌┬┬┬┐
                            ┆╎╎╎┊
                            ├┼┼┼┤
                            └┴┴┴┘
                            
                            """)
        }
        do {
            let columns = Array(repeating: Col(width: .fixed(10)), count: 1)
            let table = Tbl(columns: columns, cells: [])
            XCTAssertEqual(table.render(style: .debug),
                            """
                            ┌┅┅┅┅┅┅┅┅┅┅┐
                            ┆          ┊
                            ├┄┄┄┄┄┄┄┄┄┄┤
                            └┉┉┉┉┉┉┉┉┉┉┘
                            
                            """
            )
        }
        do {
            let columns = Array(repeating: Col("", width: .fixed(10)), count: 1)
            let table = Tbl(columns: columns, cells: [])
            XCTAssertEqual(table.render(style: .debug),
                            """
                            ┌┅┅┅┅┅┅┅┅┅┅┐
                            ┆          ┊
                            ├┄┄┄┄┄┄┄┄┄┄┤
                            └┉┉┉┉┉┉┉┉┉┉┘
                            
                            """
            )
        }
        do {
            let columns = Array(repeating: Col(width: .fixed(10)), count: 1)
            let table = Tbl(columns: columns, cells: [[]])
            XCTAssertEqual(table.render(style: .debug),
                            """
                            ┌┅┅┅┅┅┅┅┅┅┅┐
                            ┆          ┊
                            └┉┉┉┉┉┉┉┉┉┉┘
                            
                            """
            )
        }
        do {
            let columns = Array(repeating: Col(width: .fixed(10)), count: 1)
            let table = Tbl(columns: columns, cells: [[""]])
            XCTAssertEqual(table.render(style: .debug),
                            """
                            ┌┅┅┅┅┅┅┅┅┅┅┐
                            ┆          ┊
                            └┉┉┉┉┉┉┉┉┉┉┘
                            
                            """
            )
        }
        do {
            let columns = Array(repeating: Col("", width: .fixed(10)), count: 1)
            let table = Tbl(columns: columns, cells: [[""]])
            XCTAssertEqual(table.render(style: .debug),
                            """
                            ┌┅┅┅┅┅┅┅┅┅┅┐
                            ┆          ┊
                            ├┄┄┄┄┄┄┄┄┄┄┤
                            ┆          ┊
                            └┉┉┉┉┉┉┉┉┉┉┘
                            
                            """
            )
        }
        do {
            let table = Tbl("Title", columns: ["#", "#", "#", "#"], cells: [])
            XCTAssertEqual(table
                .render(style: .debug),
                           """
                           ┌┅┅┅┅┅┅┅┐
                           ┆ Title ┊
                           ├┄┬┄┬┄┬┄┤
                           ┆#╎#╎#╎#┊
                           ├┄┼┄┼┄┼┄┤
                           └┉┴┉┴┉┴┉┘

                           """)
        }
        do {
            let table = Tbl("Title", columns: ["#", "", "#"], cells: [])
            XCTAssertEqual(table
                .render(style: .debug),
                           """
                           ┌┅┅┅┅┐
                           ┆Titl┊
                           ┆ e  ┊
                           ├┄┬┬┄┤
                           ┆#╎╎#┊
                           ├┄┼┼┄┤
                           └┉┴┴┉┘
                           
                           """)
        }
        do {
            let table = Tbl("Title", columns: ["#", "", "#"], cells: [])
            XCTAssertEqual(table
                .render(style: .debug),
                           """
                           ┌┅┅┅┅┐
                           ┆Titl┊
                           ┆ e  ┊
                           ├┄┬┬┄┤
                           ┆#╎╎#┊
                           ├┄┼┼┄┤
                           └┉┴┴┉┘
                           
                           """)
        }
        do {
            let src:[[Txt]] = []
            let columns = [
                Col("Hash", width: .auto, defaultAlignment: .bottomLeft, defaultWrapping: .word, contentHint: .unique),
                Col("Value", width: .auto, defaultAlignment: .bottomRight, defaultWrapping: .word, contentHint: .unique),
                Col("Unit", width: .auto, defaultAlignment: .bottomLeft, defaultWrapping: .word, contentHint: .unique),
            ]
            
            let table = Tbl("title", columns: columns, cells: src)
            XCTAssertEqual(table
                .render(style: .debug, options: .all),
                           """
                           ┌┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┐
                           ┆     title     ┊
                           ├┄┄┄┄┬┄┄┄┄┄┬┄┄┄┄┤
                           ┆Hash╎Value╎Unit┊
                           ├┄┄┄┄┼┄┄┄┄┄┼┄┄┄┄┤
                           └┉┉┉┉┴┉┉┉┉┉┴┉┉┉┉┘
                           
                           """
            )
        }
        do {
            let src:[[Txt]] = []
            let columns = [
                Col("Hash", width: .auto, defaultAlignment: .bottomLeft, defaultWrapping: .word, contentHint: .unique),
                Col("Value", width: .auto, defaultAlignment: .bottomRight, defaultWrapping: .word, contentHint: .unique),
                Col("Unit", width: .auto, defaultAlignment: .bottomLeft, defaultWrapping: .word, contentHint: .unique),
            ]
            
            let table = Tbl("title", columns: columns, cells: src)
            XCTAssertEqual(table
                .render(style: .debug, options: .all),
                           """
                           ┌┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┐
                           ┆     title     ┊
                           ├┄┄┄┄┬┄┄┄┄┄┬┄┄┄┄┤
                           ┆Hash╎Value╎Unit┊
                           ├┄┄┄┄┼┄┄┄┄┄┼┄┄┄┄┤
                           └┉┉┉┉┴┉┉┉┉┉┴┉┉┉┉┘
                           
                           """
            )
        }
    }
    func test_singleEmptyDataRow() {
        let columns = [
            Col("Col 1", width: 1, defaultAlignment: .topLeft),
            Col("Col 2", width: 2, defaultAlignment: .topLeft),
            Col(Txt("Col 3"), width: 3, defaultAlignment: .topLeft),
        ]
        do {
            let table = Tbl("Title", columns: columns, cells: [[]])
            XCTAssertEqual(table.render(style: .debug),
                           """
                           ┌┅┅┅┅┅┅┅┅┐
                           ┆ Title  ┊
                           ├┄┬┄┄┬┄┄┄┤
                           ┆C╎Co╎Col┊
                           ┆o╎l ╎ 3 ┊
                           ┆l╎2 ╎   ┊
                           ┆ ╎  ╎   ┊
                           ┆1╎  ╎   ┊
                           ├┄┼┄┄┼┄┄┄┤
                           ┆ ╎  ╎   ┊
                           └┉┴┉┉┴┉┉┉┘
                           
                           """)
        }
        do {
            let table = Tbl(nil, columns: columns, cells: [[]])
            XCTAssertEqual(table.render(style: .debug),
                           """
                           ┌┅┬┅┅┬┅┅┅┐
                           ┆C╎Co╎Col┊
                           ┆o╎l ╎ 3 ┊
                           ┆l╎2 ╎   ┊
                           ┆ ╎  ╎   ┊
                           ┆1╎  ╎   ┊
                           ├┄┼┄┄┼┄┄┄┤
                           ┆ ╎  ╎   ┊
                           └┉┴┉┉┴┉┉┉┘

                           """)
        }
        do {
            let table = Tbl(nil, columns: [], cells: [[]])
            XCTAssertEqual(table.render(),
                           """
                           ++
                           ++
                           
                           """
            )
        }
        do {
            let table = Tbl(columns: [], cells: [[]])
            XCTAssertEqual(table.render(options: .none),
                           """
                           
                           """
            )
        }
        do {
            let table = Tbl("Title", columns: [], cells: [[]])
            XCTAssertEqual(table.render(style: .debug),
                           """
                           ┌┅┅┅┅┅┐
                           ┆Title┊
                           ├┄┄┄┄┄┤
                           └┉┉┉┉┉┘
                           
                           """)
        }
        do {
            let table = Tbl("Title", cells: [])
            XCTAssertEqual(table.render(style: .debug),
                           """
                           ┌┅┅┅┅┅┐
                           ┆Title┊
                           ├┄┄┄┄┄┤
                           └┉┉┉┉┉┘
                           
                           """)
        }
    }
    func test_missingColumns() {
        do {
            // We have more data cells per row than defined columns.
            // Tbl will automatically create missing default columns
            // (with width = .auto, defaultAlignment: .topLeft,
            // defaultWrapping: .char)
            // In this test table columns 1-3 are created automatically
            // demonstrating the 'width' and 'defaultAlignment'
            let cells:[[Txt]] = [
                ["ab", "cd", "e", "fgh"],
            ]
            let table = Tbl("Title", columns: [Col("#", width: 1)], cells: cells)
            XCTAssertEqual(table.render(style: .debug),
                           """
                           ┌┅┅┅┅┅┅┅┅┅┅┐
                           ┆  Title   ┊
                           ├┄┬┄┄┬┄┬┄┄┄┤
                           ┆#╎  ╎ ╎   ┊
                           ├┄┼┄┄┼┄┼┄┄┄┤
                           ┆a╎cd╎e╎fgh┊
                           ┆b╎  ╎ ╎   ┊
                           └┉┴┉┉┴┉┴┉┉┉┘
                           
                           """)
        }
    }
    func test_dynamicColWidths() {
        do {
            let widths:[Width] = [
                .auto, .hidden, .collapsed, .fixed(2), .min(2), .max(3), .range(2..<4), .in(2...3)
            ]
            let expected:[String] = [
                // .auto
                
                """
                ┌┅┅┅┅┐
                ┆auto┊
                ├┄┄┄┄┤
                ┆#   ┊
                ├┄┄┄┄┤
                ┆1   ┊
                ├┄┄┄┄┤
                ┆1234┊
                └┉┉┉┉┘
                
                """,
                // .hidden
                """
                ┌┅┅┅┅┅┅┐
                ┆hidden┊
                ├┄┄┄┄┄┄┤
                └┉┉┉┉┉┉┘
                
                """,
                // .collapsed
                """
                ┌┐
                ┆┊
                ├┤
                ┆┊
                ├┤
                ┆┊
                ├┤
                ┆┊
                └┘
                
                """,
                // .fixed(2)
                """
                ┌┅┅┐
                ┆fi┊
                ┆xe┊
                ┆d ┊
                ├┄┄┤
                ┆# ┊
                ├┄┄┤
                ┆1 ┊
                ├┄┄┤
                ┆12┊
                ┆34┊
                └┉┉┘
                
                """,
                // .min(2)
                """
                ┌┅┅┅┅┐
                ┆min ┊
                ├┄┄┄┄┤
                ┆#   ┊
                ├┄┄┄┄┤
                ┆1   ┊
                ├┄┄┄┄┤
                ┆1234┊
                └┉┉┉┉┘
                
                """,
                // .max(3)
                """
                ┌┅┅┅┐
                ┆max┊
                ├┄┄┄┤
                ┆#  ┊
                ├┄┄┄┤
                ┆1  ┊
                ├┄┄┄┤
                ┆123┊
                ┆4  ┊
                └┉┉┉┘
                
                """,
                // .range(2..<3)
                """
                ┌┅┅┅┐
                ┆ran┊
                ┆ge ┊
                ├┄┄┄┤
                ┆#  ┊
                ├┄┄┄┤
                ┆1  ┊
                ├┄┄┄┤
                ┆123┊
                ┆4  ┊
                └┉┉┉┘
                
                """,
                // .in(2...3)
                """
                ┌┅┅┅┐
                ┆in ┊
                ├┄┄┄┤
                ┆#  ┊
                ├┄┄┄┤
                ┆1  ┊
                ├┄┄┄┤
                ┆123┊
                ┆4  ┊
                └┉┉┉┘
                
                """,
            ]
            let cells:[[Txt]] = [
                ["1"], ["1234"],
            ]
            //XCTAssertEqual(widths.count, expected.count, "Test inconsistency detected")
            for (i,(w,e)) in zip(0...,zip(widths, expected)) {
                let col = Col(
                    "#", width: w,
                    defaultAlignment: .topLeft,
                    defaultWrapping: .char,
                    contentHint: .unique
                )
                let table = Tbl(Txt("\(w)"), columns: [col], cells: cells)
                XCTAssertEqual(table.render(style: .debug), e, "\(i) FAILED")
            }
        }
        do {
            let col = Col(
                "#", width: .range(2..<4),
                defaultAlignment: .topLeft,
                defaultWrapping: .char,
                contentHint: .unique
            )
            XCTAssertEqual(Tbl("Title", columns: [col], cells: [["1"]]).render(style: .debug),
                           """
                           ┌┅┅┐
                           ┆Ti┊
                           ┆tl┊
                           ┆e ┊
                           ├┄┄┤
                           ┆# ┊
                           ├┄┄┤
                           ┆1 ┊
                           └┉┉┘
                           
                           """
            )
            XCTAssertEqual(Tbl("Title", columns: [col], cells: [["12"]]).render(style: .debug),
                           """
                           ┌┅┅┐
                           ┆Ti┊
                           ┆tl┊
                           ┆e ┊
                           ├┄┄┤
                           ┆# ┊
                           ├┄┄┤
                           ┆12┊
                           └┉┉┘
                           
                           """
            )
            XCTAssertEqual(Tbl("Title", columns: [col], cells: [["123"]]).render(style: .debug),
                           """
                           ┌┅┅┅┐
                           ┆Tit┊
                           ┆le ┊
                           ├┄┄┄┤
                           ┆#  ┊
                           ├┄┄┄┤
                           ┆123┊
                           └┉┉┉┘
                           
                           """
            )
            XCTAssertEqual(Tbl("Title", columns: [col], cells: [["1234"]]).render(style: .debug),
                           """
                           ┌┅┅┅┐
                           ┆Tit┊
                           ┆le ┊
                           ├┄┄┄┤
                           ┆#  ┊
                           ├┄┄┄┤
                           ┆123┊
                           ┆4  ┊
                           └┉┉┉┘
                           
                           """
            )
        }
        do {
            let col = Col(
                "#", width: .in(2...3),
                defaultAlignment: .topLeft,
                defaultWrapping: .char,
                contentHint: .unique
            )
            XCTAssertEqual(Tbl("Title", columns: [col], cells: [["1"]]).render(style: .debug),
                           """
                           ┌┅┅┐
                           ┆Ti┊
                           ┆tl┊
                           ┆e ┊
                           ├┄┄┤
                           ┆# ┊
                           ├┄┄┤
                           ┆1 ┊
                           └┉┉┘
                           
                           """
            )
            XCTAssertEqual(Tbl("Title", columns: [col], cells: [["12"]]).render(style: .debug),
                           """
                           ┌┅┅┐
                           ┆Ti┊
                           ┆tl┊
                           ┆e ┊
                           ├┄┄┤
                           ┆# ┊
                           ├┄┄┤
                           ┆12┊
                           └┉┉┘
                           
                           """
            )
            XCTAssertEqual(Tbl("Title", columns: [col], cells: [["123"]]).render(style: .debug),
                           """
                           ┌┅┅┅┐
                           ┆Tit┊
                           ┆le ┊
                           ├┄┄┄┤
                           ┆#  ┊
                           ├┄┄┄┤
                           ┆123┊
                           └┉┉┉┘
                           
                           """
            )
            XCTAssertEqual(Tbl("Title", columns: [col], cells: [["1234"]]).render(style: .debug),
                           """
                           ┌┅┅┅┐
                           ┆Tit┊
                           ┆le ┊
                           ├┄┄┄┤
                           ┆#  ┊
                           ├┄┄┄┤
                           ┆123┊
                           ┆4  ┊
                           └┉┉┉┘
                           
                           """
            )
        }
    }
    func test_CollapsedColumns() {
        do {
            let table = Tbl(columns: [Col("Collapsed", width: .collapsed)], cells: [])
            XCTAssertEqual(table.render(style: .debug),
                           """
                           ┌┐
                           ┆┊
                           ├┤
                           └┘
                           
                           """)
        }
        do {
            let table = Tbl("Title",
                            columns: [Col("#", width: .collapsed), Col("Collapsed", width: .collapsed), Col("Collapsed", width: .collapsed)],
                            cells: [])
            XCTAssertEqual(table.render(style: .debug),
                           """
                           ┌┅┅┐
                           ┆Ti┊
                           ┆tl┊
                           ┆e ┊
                           ├┬┬┤
                           ┆╎╎┊
                           ├┼┼┤
                           └┴┴┘
                           
                           """)
        }
        do {
            let table = Tbl("Title", columns: [Col("Collapsed", width: .collapsed)], cells: [[]])
            XCTAssertEqual(table.render(style: .debug),
                           """
                           ┌┐
                           ┆┊
                           ├┤
                           ┆┊
                           ├┤
                           ┆┊
                           └┘
                           
                           """)
        }
        do {
            let table = Tbl("Title",
                             columns: [Col("Same as collapsed", width: .fixed(0))],
                             cells: [["cell"]])
            XCTAssertEqual(table.render(style: .rounded),
                           """
                           ╭╮
                           ││
                           ├┤
                           ││
                           ├┤
                           ││
                           ╰╯
                           
                           """)
        }
        do {
            let cols = Array(repeating: Col("Collapsed", width: .fixed(0)), count: 3)
            let table = Tbl("Title", columns: cols, cells: [["cell"]])
            XCTAssertEqual(table.render(style: .rounded),
                           """
                           ╭──╮
                           │Ti│
                           │tl│
                           │e │
                           ├┬┬┤
                           ││││
                           ├┼┼┤
                           ││││
                           ╰┴┴╯
                           
                           """)
        }
        do {
            let cols = Array(repeating: Col("Collapsed", width: .fixed(0)), count: 3)
            let table = Tbl("Title", columns: cols, cells: [["cell"], ["a", "b", "c", "d"]])
            XCTAssertEqual(table.render(style: .rounded),
                           """
                           ╭────╮
                           │Titl│
                           │ e  │
                           ├┬┬┬─┤
                           ││││ │
                           ├┼┼┼─┤
                           ││││ │
                           ├┼┼┼─┤
                           ││││d│
                           ╰┴┴┴─╯
                           
                           """)
        }
    }
    func test_singleNonEmptyDataRow() {
        let columns = [
            Col("Col 1", width: 1, defaultAlignment: .topLeft),
            Col("Col 2", width: 2, defaultAlignment: .topLeft),
            Col(Txt("Col 3"), width: 3, defaultAlignment: .topLeft),
        ]
        do {
            let table = Tbl("Title", columns: columns, cells: [[""]])
            XCTAssertEqual(table.render(style: .rounded).string,
                           """
                           ╭────────╮
                           │ Title  │
                           ├─┬──┬───┤
                           │C│Co│Col│
                           │o│l │ 3 │
                           │l│2 │   │
                           │ │  │   │
                           │1│  │   │
                           ├─┼──┼───┤
                           │ │  │   │
                           ╰─┴──┴───╯
                           
                           """)
        }
        do {
            let table = Tbl("Title", columns: columns, cells: [["#"]])
            XCTAssertEqual(table.render(style: .rounded).string,
                           """
                           ╭────────╮
                           │ Title  │
                           ├─┬──┬───┤
                           │C│Co│Col│
                           │o│l │ 3 │
                           │l│2 │   │
                           │ │  │   │
                           │1│  │   │
                           ├─┼──┼───┤
                           │#│  │   │
                           ╰─┴──┴───╯
                           
                           """)
        }
    }
    func test_autoColumns() {
        do {
            let table = Tbl("Title", columns: [], cells: [])
            XCTAssertEqual(table.render(),
                           """
                           +-----+
                           |Title|
                           +-----+
                           +-----+

                           """)
        }
        do {
            let data:[[Txt]] = [["#"]]
            let table = Tbl("Title", cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +-+
                           |T|
                           |i|
                           |t|
                           |l|
                           |e|
                           +-+
                           |#|
                           +-+

                           """)
        }
        do {
            let data:[[Txt]] = [["Quick brown fox..."]]
            let table = Tbl("Title", cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------------+
                           |      Title       |
                           +------------------+
                           |Quick brown fox...|
                           +------------------+

                           """)
        }
        do {
            let data:[[Txt]] = [["Quick brown fox..."]]
            let table = Tbl(cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------------+
                           |Quick brown fox...|
                           +------------------+

                           """)
        }
        do {
            let data:[[Txt]] = [["Quick brown fox", "jumps over the lazy dog"]]
            let table = Tbl(cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +---------------+-----------------------+
                           |Quick brown fox|jumps over the lazy dog|
                           +---------------+-----------------------+

                           """)
        }
        do {
            let data:[[Txt]] = [
                ["Value 1", "Value 2", ""],
                ["A", "B"],
                ["", "", "Hidden"],
                ["C", "D", "", ""],
                []
            ]
            let columns:[Col] = [
                Col(Txt("Header A"), width: .auto, defaultAlignment: .bottomLeft, defaultWrapping: .char, contentHint: .unique),
                Col(Txt("Header B"), width: 4, defaultAlignment: .bottomLeft, defaultWrapping: .char, contentHint: .unique),
                Col(Txt("Hidden"), width: .hidden, defaultAlignment: .bottomLeft, defaultWrapping: .char, contentHint: .unique),
                Col(Txt(""), width: .hidden, defaultAlignment: .bottomLeft, defaultWrapping: .char, contentHint: .unique),
                ]
            let table = Tbl("Title", columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |   Title    |
                           +-------+----+
                           |Header |Head|
                           |A      |er B|
                           +-------+----+
                           |       |Valu|
                           |Value 1|e 2 |
                           +-------+----+
                           |A      |B   |
                           +-------+----+
                           |       |    |
                           +-------+----+
                           |C      |D   |
                           +-------+----+
                           |       |    |
                           +-------+----+
                           
                           """)
        }
        do {
            let data:[[Txt]] = [
                ["Value 1", "Value 2", ""],
                ["A", "B"],
                ["", "", "Hidden"],
                ["C", "D", "", ""],
                []
            ]
            let columns:[Col] = [
                Col(Txt("Header A"), width: .auto, defaultAlignment: .bottomLeft, defaultWrapping: .char, contentHint: .unique),
                Col(Txt("Header B"), width: 4, defaultAlignment: .bottomLeft, defaultWrapping: .char, contentHint: .unique),
                Col(Txt("Hidden"), width: .hidden, defaultAlignment: .bottomLeft, defaultWrapping: .char, contentHint: .unique),
                Col(Txt(""), width: .auto, defaultAlignment: .bottomLeft, defaultWrapping: .char, contentHint: .unique),
                ]
            let table = Tbl("Title", columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +-------------+
                           |    Title    |
                           +-------+----++
                           |Header |Head||
                           |A      |er B||
                           +-------+----++
                           |       |Valu||
                           |Value 1|e 2 ||
                           +-------+----++
                           |A      |B   ||
                           +-------+----++
                           |       |    ||
                           +-------+----++
                           |C      |D   ||
                           +-------+----++
                           |       |    ||
                           +-------+----++

                           """)
        }
    }
    func test_autofillMissingDataCells() {
        do {
            let data:[[Txt]] = [["A"], ["B", "C"], ["D", "E", "F"]]
            let columns = [Col("Col1", width: 4),
                           Col("Col2", width: 4, defaultAlignment: .topRight),
                           Col("Col3", width: 4)]
            let table = Tbl(columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +----+----+----+
                           |Col1|Col2|Col3|
                           +----+----+----+
                           |A   |    |    |
                           +----+----+----+
                           |B   |   C|    |
                           +----+----+----+
                           |D   |   E|F   |
                           +----+----+----+

                           """)
        }
    }
    func test_leftAndRightPadding() {
        do {
            let data:[[Txt]] = [["#"]]
            let columns = [Col("Col1", width: 4)]
            let table = Tbl("Ttle", columns: columns, cells: data)
            XCTAssertEqual(table.render(leftPad: "[L]", rightPad: "[R]"),
                           """
                           [L]+----+[R]
                           [L]|Ttle|[R]
                           [L]+----+[R]
                           [L]|Col1|[R]
                           [L]+----+[R]
                           [L]|#   |[R]
                           [L]+----+[R]

                           """)
        }
    }
    func test_addAutoColumnsForExcessDataCells() {
        do {
            let data:[[Txt]] = [["#", "##", "###"]]
            let columns = [Col("Col1", width: 4), Col("Col2", width: 4, defaultAlignment: .topRight)]
            let table = Tbl(columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +----+----+---+
                           |Col1|Col2|   |
                           +----+----+---+
                           |#   |  ##|###|
                           +----+----+---+

                           """)
        }
    }
    func test_autoColumnWidth() {
        do {
            // Column widths must automatically adjust to fit the
            // full content of the data (maximum width of the
            // data elements in the column).
            let data:[[Txt]] = [["#", "##", "######"]]
            let columns = [Col("Col1"), Col("Col2"), Col("Col3")]
            let table = Tbl("Title", columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +-----------+
                           |   Title   |
                           +-+--+------+
                           |C|Co|Col3  |
                           |o|l2|      |
                           |l|  |      |
                           |1|  |      |
                           +-+--+------+
                           |#|##|######|
                           +-+--+------+

                           """)
        }
    }
    func test_horizontalAlignment() {
        do {
            let columns = Alignment.allCases.map({ Col(Txt("\($0)"), width: 3, defaultAlignment: $0) })
            let data:[[Txt]] = [Array(repeating: Txt("#"), count: columns.count)]
            let table = Tbl(columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +---+---+---+---+---+---+---+---+---+
                           |top|top|top|bot|bot|bot|mid|mid|mid|
                           |Lef|Rig|Cen|tom|tom|tom|dle|dle|dle|
                           |t  | ht|ter|Lef|Rig|Cen|Lef|Rig|Cen|
                           |   |   |   |t  | ht|ter|t  | ht|ter|
                           +---+---+---+---+---+---+---+---+---+
                           |#  |  #| # |#  |  #| # |#  |  #| # |
                           +---+---+---+---+---+---+---+---+---+

                           """)
        }
    }
    func test_verticalAlignment() {
        do {
            let columns = Alignment.allCases.map({ Col(Txt("\($0)"),width: 3, defaultAlignment: $0) })
            let data:[[Txt]] = [["123"] + Array(repeating: Txt("#"), count: columns.count)]
            let table = Tbl(columns: [Col(width: 1)] + columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +-+---+---+---+---+---+---+---+---+---+
                           | |top|top|top|bot|bot|bot|mid|mid|mid|
                           | |Lef|Rig|Cen|tom|tom|tom|dle|dle|dle|
                           | |t  | ht|ter|Lef|Rig|Cen|Lef|Rig|Cen|
                           | |   |   |   |t  | ht|ter|t  | ht|ter|
                           +-+---+---+---+---+---+---+---+---+---+
                           |1|#  |  #| # |   |   |   |   |   |   |
                           |2|   |   |   |   |   |   |#  |  #| # |
                           |3|   |   |   |#  |  #| # |   |   |   |
                           +-+---+---+---+---+---+---+---+---+---+

                           """)
        }
    }
    func test_wrappingChar() {
        do {
            // Wrpping taken from column's definition
            let data = [[Txt(pangram)]]
            let table = Tbl(columns: [Col(width: 12, defaultWrapping: .char)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |The quick br|
                           |own fox jump|
                           |s over the l|
                           |azy dog     |
                           +------------+

                           """)
        }
        do {
            // Wrpping taken from Txt
            let data = [[Txt(pangram, wrapping: .char)]]
            let table = Tbl(columns: [Col(width: 12, defaultWrapping: .cut)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |The quick br|
                           |own fox jump|
                           |s over the l|
                           |azy dog     |
                           +------------+

                           """)
        }
        do {
            // Wrpping defined at column level, overidden by Txt
            let data = [[Txt(pangram, wrapping: .char)]]
            let table = Tbl(columns: [Col(width: 12, defaultWrapping: .word)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |The quick br|
                           |own fox jump|
                           |s over the l|
                           |azy dog     |
                           +------------+

                           """)
        }
    }
    func test_wrappingCut() {
        do {
            // Wrpping taken from column's definition
            let data = [[Txt(pangram)]]
            let table = Tbl(columns: [Col(width: 12, defaultWrapping: .cut)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |The q…zy dog|
                           +------------+

                           """)
        }
        do {
            // Wrpping taken from Txt
            let data = [[Txt(pangram, wrapping: .cut)]]
            let table = Tbl(columns: [Col(width: 12)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |The q…zy dog|
                           +------------+

                           """)
        }
        do {
            // Wrpping defined at column level, overidden by Txt
            let data = [[Txt(pangram, wrapping: .cut)]]
            let table = Tbl(columns: [Col(width: 12, defaultWrapping: .word)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |The q…zy dog|
                           +------------+

                           """)
        }
        do {
            // Special case - column dynamicWidth = 1
            let data = [[Txt(pangram)]]
            let table = Tbl(columns: [Col(width: 1, defaultWrapping: .cut)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +-+
                           |…|
                           +-+

                           """)
        }
        do {
            // Special case - column dynamicWidth = 2
            let data = [[Txt(pangram)]]
            let table = Tbl(columns: [Col(width: 2, defaultWrapping: .cut)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +--+
                           |T…|
                           +--+

                           """)
        }
        do {
            // Special case - column dynamicWidth = 3
            let data = [[Txt(pangram)]]
            let table = Tbl(columns: [Col(width: 3, defaultWrapping: .cut)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +---+
                           |T…g|
                           +---+

                           """)
        }
    }
    func test_wrappingWord() {
        do {
            // Wrpping taken from column's definition
            let data = [[Txt(pangram)]]
            let table = Tbl(columns: [Col(width: 12, defaultWrapping: .word)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |The quick   |
                           |brown fox   |
                           |jumps over  |
                           |the lazy dog|
                           +------------+

                           """)
        }
        do {
            // Wrpping taken from Txt
            let data = [[Txt(pangram, wrapping: .word)]]
            let table = Tbl(columns: [Col(width: 16)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |The quick brown |
                           |fox jumps over  |
                           |the lazy dog    |
                           +----------------+

                           """)
        }
        do {
            // Wrpping defined at column level, overidden by Txt
            // Notes:
            //     - Spaces at the column width positions are removed (as below: "Quick" "brown")
            //     - Words which are too long to fit are "forcibly" wrapped at
            //       character boundary (as below: "jumpe" "d")
            let data = [[Txt(pangram, wrapping: .word)]]
            let table = Tbl(columns: [Col(width: 5, defaultWrapping: .char)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +-----+
                           |The  |
                           |quick|
                           |brown|
                           |fox  |
                           |jumps|
                           |over |
                           |the  |
                           |lazy |
                           |dog  |
                           +-----+

                           """)
        }
        do {
            // Wrpping taken from Txt
            let data = [[Txt("RawDefinition(\"def\", width: 5, symbol: $dir!, fieldNumber: 253, value: [1, 2, 3])", wrapping: .word)]]
            let table = Tbl(columns: [Col(width: 9, defaultAlignment: .topLeft)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +---------+
                           |RawDefini|
                           |tion("def|
                           |", width:|
                           |5,       |
                           |symbol:  |
                           |$dir!,   |
                           |fieldNumb|
                           |er: 253, |
                           |value:   |
                           |[1, 2,   |
                           |3])      |
                           +---------+

                           """)
        }
    }
    func test_frameStyles() {
        do {
            let styles:[FrameStyle] = [.default, .rounded, .roundedPadded,
                                          .singleSpace, .squared, .squaredDouble]
            let expected = [
                """
                +---+
                | * |
                +-+-+
                |1|2|
                +-+-+
                |3|4|
                +-+-+

                """,
                """
                ╭───╮
                │ * │
                ├─┬─┤
                │1│2│
                ├─┼─┤
                │3│4│
                ╰─┴─╯

                """,
                """
                ╭───────╮
                │   *   │
                ├───┬───┤
                │ 1 │ 2 │
                ├───┼───┤
                │ 3 │ 4 │
                ╰───┴───╯
                
                """,
                "     \n  *  \n     \n 1 2 \n     \n 3 4 \n     \n",
                """
                ┌───┐
                │ * │
                ├─┬─┤
                │1│2│
                ├─┼─┤
                │3│4│
                └─┴─┘

                """,
                """
                ╔═══╗
                ║ * ║
                ╠═╦═╣
                ║1║2║
                ╠═╬═╣
                ║3║4║
                ╚═╩═╝

                """,
            ]
            XCTAssertEqual(styles.count, expected.count)
            for (i,style) in styles.enumerated() {
                let table = Tbl("*", cells: [["1", "2"],["3", "4"]])
                XCTAssertEqual(table.render(style: style), expected[i])
            }
        }
    }
    func test_frameRenderingOptions() {
        do {
            let combinations:[FramingOptions] = (0...63)
                .map({ FramingOptions(rawValue: $0) })
            let expected:[[String]] = [
                [ //
                    "* ",
                    "AB",
                    "12",
                    "34"
                ],
                [ // topFrame
                    "--",
                    "* ",
                    "AB",
                    "12",
                    "34"
                ],
                [ // bottomFrame
                    "* ",
                    "AB",
                    "12",
                    "34",
                    "--"
                ],
                [ // topFrame, bottomFrame
                    "--",
                    "* ",
                    "AB",
                    "12",
                    "34",
                    "--"
                ],
                [ // leftFrame
                    "|* ",
                    "|AB",
                    "|12",
                    "|34"
                ],
                [ // topFrame, leftFrame
                    "+--",
                    "|* ",
                    "|AB",
                    "|12",
                    "|34"
                ],
                [ // bottomFrame, leftFrame
                    "|* ",
                    "|AB",
                    "|12",
                    "|34",
                    "+--"
                ],
                [ // topFrame, bottomFrame, leftFrame
                    "+--",
                    "|* ",
                    "|AB",
                    "|12",
                    "|34",
                    "+--"
                ],
                [ // rightFrame
                    "* |",
                    "AB|",
                    "12|",
                    "34|"
                ],
                [ // topFrame, rightFrame
                    "--+",
                    "* |",
                    "AB|",
                    "12|",
                    "34|"
                ],
                [ // bottomFrame, rightFrame
                    "* |",
                    "AB|",
                    "12|",
                    "34|",
                    "--+"
                ],
                [ // topFrame, bottomFrame, rightFrame
                    "--+",
                    "* |",
                    "AB|",
                    "12|",
                    "34|",
                    "--+"
                ],
                [ // leftFrame, rightFrame
                    "|* |",
                    "|AB|",
                    "|12|",
                    "|34|"
                ],
                [ // topFrame, leftFrame, rightFrame
                    "+--+",
                    "|* |",
                    "|AB|",
                    "|12|",
                    "|34|"
                ],
                [ // bottomFrame, leftFrame, rightFrame
                    "|* |",
                    "|AB|",
                    "|12|",
                    "|34|",
                    "+--+"
                ],
                [ // topFrame, bottomFrame, leftFrame, rightFrame
                    "+--+",
                    "|* |",
                    "|AB|",
                    "|12|",
                    "|34|",
                    "+--+"
                ],
                [ // insideHorizontalFrame
                    "* ",
                    "--",
                    "AB",
                    "--",
                    "12",
                    "--",
                    "34"
                ],
                [ // topFrame, insideHorizontalFrame
                    "--",
                    "* ",
                    "--",
                    "AB",
                    "--",
                    "12",
                    "--",
                    "34"
                ],
                [ // bottomFrame, insideHorizontalFrame
                    "* ",
                    "--",
                    "AB",
                    "--",
                    "12",
                    "--",
                    "34",
                    "--"
                ],
                [ // topFrame, bottomFrame, insideHorizontalFrame
                    "--",
                    "* ",
                    "--",
                    "AB",
                    "--",
                    "12",
                    "--",
                    "34",
                    "--"
                ],
                [ // leftFrame, insideHorizontalFrame
                    "|* ",
                    "+--",
                    "|AB",
                    "+--",
                    "|12",
                    "+--",
                    "|34"
                ],
                [ // topFrame, leftFrame, insideHorizontalFrame
                    "+--",
                    "|* ",
                    "+--",
                    "|AB",
                    "+--",
                    "|12",
                    "+--",
                    "|34"
                ],
                [ // bottomFrame, leftFrame, insideHorizontalFrame
                    "|* ",
                    "+--",
                    "|AB",
                    "+--",
                    "|12",
                    "+--",
                    "|34",
                    "+--"
                ],
                [ // topFrame, bottomFrame, leftFrame, insideHorizontalFrame
                    "+--",
                    "|* ",
                    "+--",
                    "|AB",
                    "+--",
                    "|12",
                    "+--",
                    "|34",
                    "+--"
                ],
                [ // rightFrame, insideHorizontalFrame
                    "* |",
                    "--+",
                    "AB|",
                    "--+",
                    "12|",
                    "--+",
                    "34|"
                ],
                [ // topFrame, rightFrame, insideHorizontalFrame
                    "--+",
                    "* |",
                    "--+",
                    "AB|",
                    "--+",
                    "12|",
                    "--+",
                    "34|"
                ],
                [ // bottomFrame, rightFrame, insideHorizontalFrame
                    "* |",
                    "--+",
                    "AB|",
                    "--+",
                    "12|",
                    "--+",
                    "34|",
                    "--+"
                ],
                [ // topFrame, bottomFrame, rightFrame, insideHorizontalFrame
                    "--+",
                    "* |",
                    "--+",
                    "AB|",
                    "--+",
                    "12|",
                    "--+",
                    "34|",
                    "--+"
                ],
                [ // leftFrame, rightFrame, insideHorizontalFrame
                    "|* |",
                    "+--+",
                    "|AB|",
                    "+--+",
                    "|12|",
                    "+--+",
                    "|34|"
                ],
                [ // topFrame, leftFrame, rightFrame, insideHorizontalFrame
                    "+--+",
                    "|* |",
                    "+--+",
                    "|AB|",
                    "+--+",
                    "|12|",
                    "+--+",
                    "|34|"
                ],
                [ // bottomFrame, leftFrame, rightFrame, insideHorizontalFrame
                    "|* |",
                    "+--+",
                    "|AB|",
                    "+--+",
                    "|12|",
                    "+--+",
                    "|34|",
                    "+--+"
                ],
                [ // topFrame, bottomFrame, leftFrame, rightFrame, insideHorizontalFrame
                    "+--+",
                    "|* |",
                    "+--+",
                    "|AB|",
                    "+--+",
                    "|12|",
                    "+--+",
                    "|34|",
                    "+--+"
                ],
                [ // insideVerticalFrame
                    " * ",
                    "A|B",
                    "1|2",
                    "3|4"
                ],
                [ // topFrame, insideVerticalFrame
                    "---",
                    " * ",
                    "A|B",
                    "1|2",
                    "3|4"
                ],
                [ // bottomFrame, insideVerticalFrame
                    " * ",
                    "A|B",
                    "1|2",
                    "3|4",
                    "-+-"
                ],
                [ // topFrame, bottomFrame, insideVerticalFrame
                    "---",
                    " * ",
                    "A|B",
                    "1|2",
                    "3|4",
                    "-+-"
                ],
                [ // leftFrame, insideVerticalFrame
                    "| * ",
                    "|A|B",
                    "|1|2",
                    "|3|4"
                ],
                [ // topFrame, leftFrame, insideVerticalFrame
                    "+---",
                    "| * ",
                    "|A|B",
                    "|1|2",
                    "|3|4"
                ],
                [ // bottomFrame, leftFrame, insideVerticalFrame
                    "| * ",
                    "|A|B",
                    "|1|2",
                    "|3|4",
                    "+-+-"
                ],
                [ // topFrame, bottomFrame, leftFrame, insideVerticalFrame
                    "+---",
                    "| * ",
                    "|A|B",
                    "|1|2",
                    "|3|4",
                    "+-+-"
                ],
                [ // rightFrame, insideVerticalFrame
                    " * |",
                    "A|B|",
                    "1|2|",
                    "3|4|"
                ],
                [ // topFrame, rightFrame, insideVerticalFrame
                    "---+",
                    " * |",
                    "A|B|",
                    "1|2|",
                    "3|4|"
                ],
                [ // bottomFrame, rightFrame, insideVerticalFrame
                    " * |",
                    "A|B|",
                    "1|2|",
                    "3|4|",
                    "-+-+"
                ],
                [ // topFrame, bottomFrame, rightFrame, insideVerticalFrame
                    "---+",
                    " * |",
                    "A|B|",
                    "1|2|",
                    "3|4|",
                    "-+-+"
                ],
                [ // leftFrame, rightFrame, insideVerticalFrame
                    "| * |",
                    "|A|B|",
                    "|1|2|",
                    "|3|4|"
                ],
                [ // topFrame, leftFrame, rightFrame, insideVerticalFrame
                    "+---+",
                    "| * |",
                    "|A|B|",
                    "|1|2|",
                    "|3|4|"
                ],
                [ // bottomFrame, leftFrame, rightFrame, insideVerticalFrame
                    "| * |",
                    "|A|B|",
                    "|1|2|",
                    "|3|4|",
                    "+-+-+"
                ],
                [ // topFrame, bottomFrame, leftFrame, rightFrame, insideVerticalFrame
                    "+---+",
                    "| * |",
                    "|A|B|",
                    "|1|2|",
                    "|3|4|",
                    "+-+-+"
                ],
                [ // insideHorizontalFrame, insideVerticalFrame
                    " * ",
                    "-+-",
                    "A|B",
                    "-+-",
                    "1|2",
                    "-+-",
                    "3|4"
                ],
                [ // topFrame, insideHorizontalFrame, insideVerticalFrame
                    "---",
                    " * ",
                    "-+-",
                    "A|B",
                    "-+-",
                    "1|2",
                    "-+-",
                    "3|4"
                ],
                [ // bottomFrame, insideHorizontalFrame, insideVerticalFrame
                    " * ",
                    "-+-",
                    "A|B",
                    "-+-",
                    "1|2",
                    "-+-",
                    "3|4",
                    "-+-"
                ],
                [ // topFrame, bottomFrame, insideHorizontalFrame, insideVerticalFrame
                    "---",
                    " * ",
                    "-+-",
                    "A|B",
                    "-+-",
                    "1|2",
                    "-+-",
                    "3|4",
                    "-+-"
                ],
                [ // leftFrame, insideHorizontalFrame, insideVerticalFrame
                    "| * ",
                    "+-+-",
                    "|A|B",
                    "+-+-",
                    "|1|2",
                    "+-+-",
                    "|3|4"
                ],
                [ // topFrame, leftFrame, insideHorizontalFrame, insideVerticalFrame
                    "+---",
                    "| * ",
                    "+-+-",
                    "|A|B",
                    "+-+-",
                    "|1|2",
                    "+-+-",
                    "|3|4"
                ],
                [ // bottomFrame, leftFrame, insideHorizontalFrame, insideVerticalFrame
                    "| * ",
                    "+-+-",
                    "|A|B",
                    "+-+-",
                    "|1|2",
                    "+-+-",
                    "|3|4",
                    "+-+-"
                ],
                [ // topFrame, bottomFrame, leftFrame, insideHorizontalFrame, insideVerticalFrame
                    "+---",
                    "| * ",
                    "+-+-",
                    "|A|B",
                    "+-+-",
                    "|1|2",
                    "+-+-",
                    "|3|4",
                    "+-+-"
                ],
                [ // rightFrame, insideHorizontalFrame, insideVerticalFrame
                    " * |",
                    "-+-+",
                    "A|B|",
                    "-+-+",
                    "1|2|",
                    "-+-+",
                    "3|4|"
                ],
                [ // topFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                    "---+",
                    " * |",
                    "-+-+",
                    "A|B|",
                    "-+-+",
                    "1|2|",
                    "-+-+",
                    "3|4|"
                ],
                [ // bottomFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                    " * |",
                    "-+-+",
                    "A|B|",
                    "-+-+",
                    "1|2|",
                    "-+-+",
                    "3|4|",
                    "-+-+"
                ],
                [ // topFrame, bottomFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                    "---+",
                    " * |",
                    "-+-+",
                    "A|B|",
                    "-+-+",
                    "1|2|",
                    "-+-+",
                    "3|4|",
                    "-+-+"
                ],
                [ // leftFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                    "| * |",
                    "+-+-+",
                    "|A|B|",
                    "+-+-+",
                    "|1|2|",
                    "+-+-+",
                    "|3|4|"
                ],
                [ // topFrame, leftFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                    "+---+",
                    "| * |",
                    "+-+-+",
                    "|A|B|",
                    "+-+-+",
                    "|1|2|",
                    "+-+-+",
                    "|3|4|"
                ],
                [ // bottomFrame, leftFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                    "| * |",
                    "+-+-+",
                    "|A|B|",
                    "+-+-+",
                    "|1|2|",
                    "+-+-+",
                    "|3|4|",
                    "+-+-+"
                ],
                [ // topFrame, bottomFrame, leftFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                    "+---+",
                    "| * |",
                    "+-+-+",
                    "|A|B|",
                    "+-+-+",
                    "|1|2|",
                    "+-+-+",
                    "|3|4|",
                    "+-+-+"
                ],
            ]
            XCTAssertEqual(combinations.count, expected.count)
            for (i, opt) in combinations.enumerated() {
                let table = Tbl("*", columns: [Col("A"),Col("B")], cells: [["1", "2"],["3", "4"]])
                // Next line: correct answer generator ;-)
                // print("[ // \(opt.optionsInEffect)\n" + table.render().split(separator: "\n").map({ "\"\($0)\"" }).joined(separator: ",\n") + "\n],")
                XCTAssertEqual(
                    table.render(options: opt),
                    expected[i].joined(separator: "\n") + "\n")
            }
        }
    }
    func test_frameRenderingOptions2() {
        do {
            let combinations:[FramingOptions] = (0...63)
                .map({ FramingOptions(rawValue: $0) })
            let expected:[[String]] = [
                [ //
                "Title",
                "ACE  ",
                "123  ",
                "45end"
                ],
                [ // topFrame
                "─────",
                "Title",
                "ACE  ",
                "123  ",
                "45end"
                ],
                [ // bottomFrame
                "Title",
                "ACE  ",
                "123  ",
                "45end",
                "─────"
                ],
                [ // topFrame, bottomFrame
                "─────",
                "Title",
                "ACE  ",
                "123  ",
                "45end",
                "─────"
                ],
                [ // leftFrame
                "│Title",
                "│ACE  ",
                "│123  ",
                "│45end"
                ],
                [ // topFrame, leftFrame
                "╭─────",
                "│Title",
                "│ACE  ",
                "│123  ",
                "│45end"
                ],
                [ // bottomFrame, leftFrame
                "│Title",
                "│ACE  ",
                "│123  ",
                "│45end",
                "╰─────"
                ],
                [ // topFrame, bottomFrame, leftFrame
                "╭─────",
                "│Title",
                "│ACE  ",
                "│123  ",
                "│45end",
                "╰─────"
                ],
                [ // rightFrame
                "Title│",
                "ACE  │",
                "123  │",
                "45end│"
                ],
                [ // topFrame, rightFrame
                "─────╮",
                "Title│",
                "ACE  │",
                "123  │",
                "45end│"
                ],
                [ // bottomFrame, rightFrame
                "Title│",
                "ACE  │",
                "123  │",
                "45end│",
                "─────╯"
                ],
                [ // topFrame, bottomFrame, rightFrame
                "─────╮",
                "Title│",
                "ACE  │",
                "123  │",
                "45end│",
                "─────╯"
                ],
                [ // leftFrame, rightFrame
                "│Title│",
                "│ACE  │",
                "│123  │",
                "│45end│"
                ],
                [ // topFrame, leftFrame, rightFrame
                "╭─────╮",
                "│Title│",
                "│ACE  │",
                "│123  │",
                "│45end│"
                ],
                [ // bottomFrame, leftFrame, rightFrame
                "│Title│",
                "│ACE  │",
                "│123  │",
                "│45end│",
                "╰─────╯"
                ],
                [ // topFrame, bottomFrame, leftFrame, rightFrame
                "╭─────╮",
                "│Title│",
                "│ACE  │",
                "│123  │",
                "│45end│",
                "╰─────╯"
                ],
                [ // insideHorizontalFrame
                "Title",
                "─────",
                "ACE  ",
                "─────",
                "123  ",
                "─────",
                "45end"
                ],
                [ // topFrame, insideHorizontalFrame
                "─────",
                "Title",
                "─────",
                "ACE  ",
                "─────",
                "123  ",
                "─────",
                "45end"
                ],
                [ // bottomFrame, insideHorizontalFrame
                "Title",
                "─────",
                "ACE  ",
                "─────",
                "123  ",
                "─────",
                "45end",
                "─────"
                ],
                [ // topFrame, bottomFrame, insideHorizontalFrame
                "─────",
                "Title",
                "─────",
                "ACE  ",
                "─────",
                "123  ",
                "─────",
                "45end",
                "─────"
                ],
                [ // leftFrame, insideHorizontalFrame
                "│Title",
                "├─────",
                "│ACE  ",
                "├─────",
                "│123  ",
                "├─────",
                "│45end"
                ],
                [ // topFrame, leftFrame, insideHorizontalFrame
                "╭─────",
                "│Title",
                "├─────",
                "│ACE  ",
                "├─────",
                "│123  ",
                "├─────",
                "│45end"
                ],
                [ // bottomFrame, leftFrame, insideHorizontalFrame
                "│Title",
                "├─────",
                "│ACE  ",
                "├─────",
                "│123  ",
                "├─────",
                "│45end",
                "╰─────"
                ],
                [ // topFrame, bottomFrame, leftFrame, insideHorizontalFrame
                "╭─────",
                "│Title",
                "├─────",
                "│ACE  ",
                "├─────",
                "│123  ",
                "├─────",
                "│45end",
                "╰─────"
                ],
                [ // rightFrame, insideHorizontalFrame
                "Title│",
                "─────┤",
                "ACE  │",
                "─────┤",
                "123  │",
                "─────┤",
                "45end│"
                ],
                [ // topFrame, rightFrame, insideHorizontalFrame
                "─────╮",
                "Title│",
                "─────┤",
                "ACE  │",
                "─────┤",
                "123  │",
                "─────┤",
                "45end│"
                ],
                [ // bottomFrame, rightFrame, insideHorizontalFrame
                "Title│",
                "─────┤",
                "ACE  │",
                "─────┤",
                "123  │",
                "─────┤",
                "45end│",
                "─────╯"
                ],
                [ // topFrame, bottomFrame, rightFrame, insideHorizontalFrame
                "─────╮",
                "Title│",
                "─────┤",
                "ACE  │",
                "─────┤",
                "123  │",
                "─────┤",
                "45end│",
                "─────╯"
                ],
                [ // leftFrame, rightFrame, insideHorizontalFrame
                "│Title│",
                "├─────┤",
                "│ACE  │",
                "├─────┤",
                "│123  │",
                "├─────┤",
                "│45end│"
                ],
                [ // topFrame, leftFrame, rightFrame, insideHorizontalFrame
                "╭─────╮",
                "│Title│",
                "├─────┤",
                "│ACE  │",
                "├─────┤",
                "│123  │",
                "├─────┤",
                "│45end│"
                ],
                [ // bottomFrame, leftFrame, rightFrame, insideHorizontalFrame
                "│Title│",
                "├─────┤",
                "│ACE  │",
                "├─────┤",
                "│123  │",
                "├─────┤",
                "│45end│",
                "╰─────╯"
                ],
                [ // topFrame, bottomFrame, leftFrame, rightFrame, insideHorizontalFrame
                "╭─────╮",
                "│Title│",
                "├─────┤",
                "│ACE  │",
                "├─────┤",
                "│123  │",
                "├─────┤",
                "│45end│",
                "╰─────╯"
                ],
                [ // insideVerticalFrame
                "  Title  ",
                "A│C││E  │",
                "1│2││3  │",
                "4│5││end│"
                ],
                [ // topFrame, insideVerticalFrame
                "─────────",
                "  Title  ",
                "A│C││E  │",
                "1│2││3  │",
                "4│5││end│"
                ],
                [ // bottomFrame, insideVerticalFrame
                "  Title  ",
                "A│C││E  │",
                "1│2││3  │",
                "4│5││end│",
                "─┴─┴┴───┴"
                ],
                [ // topFrame, bottomFrame, insideVerticalFrame
                "─────────",
                "  Title  ",
                "A│C││E  │",
                "1│2││3  │",
                "4│5││end│",
                "─┴─┴┴───┴"
                ],
                [ // leftFrame, insideVerticalFrame
                "│  Title  ",
                "│A│C││E  │",
                "│1│2││3  │",
                "│4│5││end│"
                ],
                [ // topFrame, leftFrame, insideVerticalFrame
                "╭─────────",
                "│  Title  ",
                "│A│C││E  │",
                "│1│2││3  │",
                "│4│5││end│"
                ],
                [ // bottomFrame, leftFrame, insideVerticalFrame
                "│  Title  ",
                "│A│C││E  │",
                "│1│2││3  │",
                "│4│5││end│",
                "╰─┴─┴┴───┴"
                ],
                [ // topFrame, bottomFrame, leftFrame, insideVerticalFrame
                "╭─────────",
                "│  Title  ",
                "│A│C││E  │",
                "│1│2││3  │",
                "│4│5││end│",
                "╰─┴─┴┴───┴"
                ],
                [ // rightFrame, insideVerticalFrame
                "  Title  │",
                "A│C││E  ││",
                "1│2││3  ││",
                "4│5││end││"
                ],
                [ // topFrame, rightFrame, insideVerticalFrame
                "─────────╮",
                "  Title  │",
                "A│C││E  ││",
                "1│2││3  ││",
                "4│5││end││"
                ],
                [ // bottomFrame, rightFrame, insideVerticalFrame
                "  Title  │",
                "A│C││E  ││",
                "1│2││3  ││",
                "4│5││end││",
                "─┴─┴┴───┴╯"
                ],
                [ // topFrame, bottomFrame, rightFrame, insideVerticalFrame
                "─────────╮",
                "  Title  │",
                "A│C││E  ││",
                "1│2││3  ││",
                "4│5││end││",
                "─┴─┴┴───┴╯"
                ],
                [ // leftFrame, rightFrame, insideVerticalFrame
                "│  Title  │",
                "│A│C││E  ││",
                "│1│2││3  ││",
                "│4│5││end││"
                ],
                [ // topFrame, leftFrame, rightFrame, insideVerticalFrame
                "╭─────────╮",
                "│  Title  │",
                "│A│C││E  ││",
                "│1│2││3  ││",
                "│4│5││end││"
                ],
                [ // bottomFrame, leftFrame, rightFrame, insideVerticalFrame
                "│  Title  │",
                "│A│C││E  ││",
                "│1│2││3  ││",
                "│4│5││end││",
                "╰─┴─┴┴───┴╯"
                ],
                [ // topFrame, bottomFrame, leftFrame, rightFrame, insideVerticalFrame
                "╭─────────╮",
                "│  Title  │",
                "│A│C││E  ││",
                "│1│2││3  ││",
                "│4│5││end││",
                "╰─┴─┴┴───┴╯"
                ],
                [ // insideHorizontalFrame, insideVerticalFrame
                "  Title  ",
                "─┬─┬┬───┬",
                "A│C││E  │",
                "─┼─┼┼───┼",
                "1│2││3  │",
                "─┼─┼┼───┼",
                "4│5││end│"
                ],
                [ // topFrame, insideHorizontalFrame, insideVerticalFrame
                "─────────",
                "  Title  ",
                "─┬─┬┬───┬",
                "A│C││E  │",
                "─┼─┼┼───┼",
                "1│2││3  │",
                "─┼─┼┼───┼",
                "4│5││end│"
                ],
                [ // bottomFrame, insideHorizontalFrame, insideVerticalFrame
                "  Title  ",
                "─┬─┬┬───┬",
                "A│C││E  │",
                "─┼─┼┼───┼",
                "1│2││3  │",
                "─┼─┼┼───┼",
                "4│5││end│",
                "─┴─┴┴───┴"
                ],
                [ // topFrame, bottomFrame, insideHorizontalFrame, insideVerticalFrame
                "─────────",
                "  Title  ",
                "─┬─┬┬───┬",
                "A│C││E  │",
                "─┼─┼┼───┼",
                "1│2││3  │",
                "─┼─┼┼───┼",
                "4│5││end│",
                "─┴─┴┴───┴"
                ],
                [ // leftFrame, insideHorizontalFrame, insideVerticalFrame
                "│  Title  ",
                "├─┬─┬┬───┬",
                "│A│C││E  │",
                "├─┼─┼┼───┼",
                "│1│2││3  │",
                "├─┼─┼┼───┼",
                "│4│5││end│"
                ],
                [ // topFrame, leftFrame, insideHorizontalFrame, insideVerticalFrame
                "╭─────────",
                "│  Title  ",
                "├─┬─┬┬───┬",
                "│A│C││E  │",
                "├─┼─┼┼───┼",
                "│1│2││3  │",
                "├─┼─┼┼───┼",
                "│4│5││end│"
                ],
                [ // bottomFrame, leftFrame, insideHorizontalFrame, insideVerticalFrame
                "│  Title  ",
                "├─┬─┬┬───┬",
                "│A│C││E  │",
                "├─┼─┼┼───┼",
                "│1│2││3  │",
                "├─┼─┼┼───┼",
                "│4│5││end│",
                "╰─┴─┴┴───┴"
                ],
                [ // topFrame, bottomFrame, leftFrame, insideHorizontalFrame, insideVerticalFrame
                "╭─────────",
                "│  Title  ",
                "├─┬─┬┬───┬",
                "│A│C││E  │",
                "├─┼─┼┼───┼",
                "│1│2││3  │",
                "├─┼─┼┼───┼",
                "│4│5││end│",
                "╰─┴─┴┴───┴"
                ],
                [ // rightFrame, insideHorizontalFrame, insideVerticalFrame
                "  Title  │",
                "─┬─┬┬───┬┤",
                "A│C││E  ││",
                "─┼─┼┼───┼┤",
                "1│2││3  ││",
                "─┼─┼┼───┼┤",
                "4│5││end││"
                ],
                [ // topFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                "─────────╮",
                "  Title  │",
                "─┬─┬┬───┬┤",
                "A│C││E  ││",
                "─┼─┼┼───┼┤",
                "1│2││3  ││",
                "─┼─┼┼───┼┤",
                "4│5││end││"
                ],
                [ // bottomFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                "  Title  │",
                "─┬─┬┬───┬┤",
                "A│C││E  ││",
                "─┼─┼┼───┼┤",
                "1│2││3  ││",
                "─┼─┼┼───┼┤",
                "4│5││end││",
                "─┴─┴┴───┴╯"
                ],
                [ // topFrame, bottomFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                "─────────╮",
                "  Title  │",
                "─┬─┬┬───┬┤",
                "A│C││E  ││",
                "─┼─┼┼───┼┤",
                "1│2││3  ││",
                "─┼─┼┼───┼┤",
                "4│5││end││",
                "─┴─┴┴───┴╯"
                ],
                [ // leftFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                "│  Title  │",
                "├─┬─┬┬───┬┤",
                "│A│C││E  ││",
                "├─┼─┼┼───┼┤",
                "│1│2││3  ││",
                "├─┼─┼┼───┼┤",
                "│4│5││end││"
                ],
                [ // topFrame, leftFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                "╭─────────╮",
                "│  Title  │",
                "├─┬─┬┬───┬┤",
                "│A│C││E  ││",
                "├─┼─┼┼───┼┤",
                "│1│2││3  ││",
                "├─┼─┼┼───┼┤",
                "│4│5││end││"
                ],
                [ // bottomFrame, leftFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                "│  Title  │",
                "├─┬─┬┬───┬┤",
                "│A│C││E  ││",
                "├─┼─┼┼───┼┤",
                "│1│2││3  ││",
                "├─┼─┼┼───┼┤",
                "│4│5││end││",
                "╰─┴─┴┴───┴╯"
                ],
                [ // topFrame, bottomFrame, leftFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame
                "╭─────────╮",
                "│  Title  │",
                "├─┬─┬┬───┬┤",
                "│A│C││E  ││",
                "├─┼─┼┼───┼┤",
                "│1│2││3  ││",
                "├─┼─┼┼───┼┤",
                "│4│5││end││",
                "╰─┴─┴┴───┴╯"
                ],
            ]
            XCTAssertEqual(combinations.count, expected.count)
            for (i, opt) in combinations.enumerated() {
                let columns = [
                    Col("A"),
                    Col("B-hidden", width: .hidden),
                    Col("C"),
                    Col("D-zero", width: .fixed(0)),
                    Col("E"),
                    Col("F-zero", width: .fixed(0)),
                ]
                let cells:[[Txt]] = [
                    ["1", "hidden", "2", "zero width", "3"],
                    ["4", "hidden", "5", "zero width", "end", "f"]
                ]
                let table = Tbl("Title", columns: columns, cells: cells)
                // Next line: correct answer generator ;-)
                //print("[ // \(opt.optionsInEffect)\n" + table.render().split(separator: "\n").map({ "\"\($0)\"" }).joined(separator: ",\n") + "\n],")
                XCTAssertEqual(
                    table.render(style: .rounded, options: opt),
                    expected[i].joined(separator: "\n") + "\n")
            }
        }
    }
    func test_titleAlignment() {
        // NOTE: Titles have only horizontal alignment.
        // From titles point of view .topLeft == .bottomLeft == .middleLeft
        // ...and so on...
        do {
            // Default is "middleCenter" with "word" wrapping
            // Title narrower than column content
            let table = Tbl("Title", columns: [Col(width: 16)], cells: [[Txt(pangram)]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |     Title      |
                           +----------------+
                           |The quick brown |
                           |fox jumps over t|
                           |he lazy dog     |
                           +----------------+

                           """)
        }
        do {
            // Default is "middleCenter" with "word" wrapping
            // Title wider than column content
            let table = Tbl("English-language pangram — a sentence that contains all of the letters of the English alphabet.", columns: [Col(width: 16)], cells: [[Txt(pangram)]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |English-language|
                           |  pangram — a   |
                           | sentence that  |
                           |contains all of |
                           | the letters of |
                           |  the English   |
                           |   alphabet.    |
                           +----------------+
                           |The quick brown |
                           |fox jumps over t|
                           |he lazy dog     |
                           +----------------+

                           """)
        }
        do {
            // Default is "middleCenter" with "word" wrapping
            // Left aligned
            let table = Tbl(Txt("Title", alignment: .topLeft), columns: [Col(width: 16)], cells: [[Txt(pangram)]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |Title           |
                           +----------------+
                           |The quick brown |
                           |fox jumps over t|
                           |he lazy dog     |
                           +----------------+

                           """)
        }
        do {
            // Default is "middleCenter" with "word" wrapping
            // Right aligned
            let table = Tbl(Txt("Title", alignment: .bottomRight), columns: [Col(width: 16)], cells: [[Txt(pangram)]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |           Title|
                           +----------------+
                           |The quick brown |
                           |fox jumps over t|
                           |he lazy dog     |
                           +----------------+

                           """)
        }
        do {
            // Default is "middleCenter" with "word" wrapping
            // Left aligned
            let table = Tbl(Txt("Title wider than column width", alignment: .middleLeft), columns: [Col(width: 16)], cells: [[Txt(pangram)]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |Title wider than|
                           |column width    |
                           +----------------+
                           |The quick brown |
                           |fox jumps over t|
                           |he lazy dog     |
                           +----------------+

                           """)
        }
        do {
            // Default is "middleCenter" with "word" wrapping
            // Right aligned
            let table = Tbl(Txt("Title wider than column width", alignment: .bottomRight), columns: [Col(width: 16)], cells: [[Txt(pangram)]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |Title wider than|
                           |    column width|
                           +----------------+
                           |The quick brown |
                           |fox jumps over t|
                           |he lazy dog     |
                           +----------------+

                           """)
        }
    }
    func test_columnHeaderAlignment() {
        do {
            let expected:[String] = [
                // topLeft
                """
                +-+---+
                |1|#  |
                |2|   |
                |3|   |
                +-+---+
                +-+---+

                """,
                // topRight
                """
                +-+---+
                |1|  #|
                |2|   |
                |3|   |
                +-+---+
                +-+---+

                """,
                // topCenter
                """
                +-+---+
                |1| # |
                |2|   |
                |3|   |
                +-+---+
                +-+---+

                """,
                // bottomLeft
                """
                +-+---+
                |1|   |
                |2|   |
                |3|#  |
                +-+---+
                +-+---+

                """,
                // bottomRight
                """
                +-+---+
                |1|   |
                |2|   |
                |3|  #|
                +-+---+
                +-+---+

                """,
                // bottomCenter
                """
                +-+---+
                |1|   |
                |2|   |
                |3| # |
                +-+---+
                +-+---+

                """,
                // middleLeft
                """
                +-+---+
                |1|   |
                |2|#  |
                |3|   |
                +-+---+
                +-+---+

                """,
                // middleRight
                """
                +-+---+
                |1|   |
                |2|  #|
                |3|   |
                +-+---+
                +-+---+

                """,
                // middleCenter
                """
                +-+---+
                |1|   |
                |2| # |
                |3|   |
                +-+---+
                +-+---+

                """,
            ]
            XCTAssertEqual(Alignment.allCases.count, expected.count)
            for (i,alignment) in Alignment.allCases.enumerated() {
                let columns = [Col("123", width: 1), Col(Txt("#", alignment: alignment), width: 3)]
                let table = Tbl(columns: columns, cells: [])
                XCTAssertEqual(table.render(), expected[i])
            }
        }
    }
    func test_columnHide() {
        do {
            // Columns can be hidden with Width.hidden
            let data:[[Txt]] = [
                ["#"],
                ["@", "@@"],
                ["*", "**", "******"]
            ]
            let columns = [Col("Col1"), Col("Col2", width: .hidden), Col("Col3")]
            let table = Tbl("Title", columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +--------+
                           | Title  |
                           +-+------+
                           |C|Col3  |
                           |o|      |
                           |l|      |
                           |1|      |
                           +-+------+
                           |#|      |
                           +-+------+
                           |@|      |
                           +-+------+
                           |*|******|
                           +-+------+

                           """)
        }
        do {
            // Columns can be hidden with Width.hidden
            let data:[[Txt]] = [["#", "##", "######"],["*", "**", "******"]]
            let columns = [Col("Col1", width: .hidden), Col("Col2", width: .hidden), Col("Col3")]
            let table = Tbl("Title", columns: columns, cells: data)
            XCTAssertEqual(table.render(style: .squared),
                           """
                           ┌──────┐
                           │Title │
                           ├──────┤
                           │Col3  │
                           ├──────┤
                           │######│
                           ├──────┤
                           │******│
                           └──────┘
                           
                           """)
        }
        do {
            // Columns can be hidden with Width.hidden
            let data:[[Txt]] = [["#", "##", "######"],["*", "**", "******"]]
            let columns = [Col("Col1", width: .hidden), Col("Col2", width: .hidden), Col("Col3", width: .hidden)]
            let table = Tbl("Title", columns: columns, cells: data)
            XCTAssertEqual(table.render(style: .squared),
                           """
                           ┌─────┐
                           │Title│
                           ├─────┤
                           └─────┘
                           
                           """)
        }
        do {
            // Columns can be hidden with Width.hidden
            let data:[[Txt]] = [["#", "##", "######"],["*", "**", "******"]]
            let columns = [Col("Col1", width: .hidden), Col("Col2", width: .hidden), Col("Col3", width: .hidden)]
            let table = Tbl(columns: columns, cells: data)
            XCTAssertEqual(table.render(style: .squared),
                           """
                           ┌┐
                           └┘

                           """
            )
        }
    }
    func test_csv() {
        do {
            let expected:[String] = [
            """
            A;Hidden;C;
            1;2;3;
            4;5;;
            
            """,
            
            """
            A;C;
            1;3;
            4;;
            
            """,
            
            """
            1;2;3;
            4;5;;
            
            """,
            
            """
            1;3;
            4;;
            
            """,
            ]
            let table = Tbl("*",
                            columns: [Col("A"),Col("Hidden", width: .hidden),
                                      Col("C")],
                            cells: [["1", "2", "3"],["4", "5"]])
            var i = 0
            for withHeaders in [true, false] {
                for includeHidden in [true, false] {
                    guard expected.indices.contains(i) else {
                        XCTFail("Test case internal error. Missing expected data.")
                        continue
                    }
                    XCTAssertEqual(expected[i],
                                   table.csv(delimiter: ";", withColumnHeaders: withHeaders, includingHiddenColumns: includeHidden))
                    i += 1
                }
            }
        }
        do {
            let expected:[String] = [
            """
            ;;;
            1;2;3;
            4;5;;
            
            """,
            
            """
            ;;;
            1;2;3;
            4;5;;

            """,
            
            """
            1;2;3;
            4;5;;
            
            """,
            
            """
            1;2;3;
            4;5;;
            
            """,
            ]
            let table = Tbl("*", columns: [], cells: [["1", "2", "3"],["4", "5"]])
            var i = 0
            for withHeaders in [true, false] {
                for includeHidden in [true, false] {
                    guard expected.indices.contains(i) else {
                        XCTFail("Test case internal error. Missing expected data.")
                        continue
                    }
                    /*
                    print(
                        table.csv(
                            delimiter: ";",
                            withColumnHeaders: withHeaders,
                            includingHiddenColumns: includeHidden
                        )
                    )*/
                    XCTAssertEqual(expected[i],
                                   table.csv(delimiter: ";", withColumnHeaders: withHeaders, includingHiddenColumns: includeHidden))
                    i += 1
                }
            }
        }
    }
    func test_columnMin() {
        do {
            let data:[[Txt]] = [["#", "##", "#########"], ["###", "##", "#"]]
            let columns = [Col("Col1", width: .min(4)), Col("Col2", width: .min(3)), Col("Col3", width: .min(2))]
            let table = Tbl("title",columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------------+
                           |      title       |
                           +----+---+---------+
                           |Col1|Col|Col3     |
                           |    |2  |         |
                           +----+---+---------+
                           |#   |## |#########|
                           +----+---+---------+
                           |### |## |#        |
                           +----+---+---------+
                           
                           """
            )
        }
        do {
            let data:[[Txt]] = [["#", "##", "#####\n####"], ["###", "##", "#"]]
            let columns = [Col("Col1", width: .min(4)), Col("Col2", width: .min(3)), Col("Col3", width: .min(2))]
            let table = Tbl("title",columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +--------------+
                           |    title     |
                           +----+---+-----+
                           |Col1|Col|Col3 |
                           |    |2  |     |
                           +----+---+-----+
                           |#   |## |#####|
                           |    |   |#### |
                           +----+---+-----+
                           |### |## |#    |
                           +----+---+-----+
                           
                           """
            )
        }
        do {
            let data:[[Txt]] = [["#", "##", "###"]]
            let columns = [Col(width: .min(4)), Col(width: .min(3)), Col(width: .min(2))]
            let table = Tbl(columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +----+---+---+
                           |#   |## |###|
                           +----+---+---+
                           
                           """
            )
        }
        do {
            let data:[[Txt]] = [["#", "##", "###"]]
            let columns = [Col(width: .min(4)), Col(width: .min(3)), Col(width: .min(2))]
            let table = Tbl("With title longer than columns", columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           | With title |
                           |longer than |
                           |  columns   |
                           +----+---+---+
                           |#   |## |###|
                           +----+---+---+
                           
                           """
            )
        }
    }
    func test_columnMax() {
        do {
            let data:[[Txt]] = [["#", "##", "###"]]
            let columns = [Col("Col1", width: .max(4)), Col("Col2", width: .max(3)), Col("Col3", width: .max(2))]
            let table = Tbl(columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +-+--+--+
                           |C|Co|Co|
                           |o|l2|l3|
                           |l|  |  |
                           |1|  |  |
                           +-+--+--+
                           |#|##|##|
                           | |  |# |
                           +-+--+--+

                           """
            )
        }
        do {
            let data:[[Txt]] = [["#", "##", "###"]]
            let columns = [Col(width: .max(4)), Col(width: .max(3)), Col(width: .max(2))]
            let table = Tbl(columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +-+--+--+
                           |#|##|##|
                           | |  |# |
                           +-+--+--+
                           
                           """
            )
        }
    }
    func test_columnRange() {
        do {
            let data:[[Txt]] = [["#", "##", "###", "####", "######"]]
            let columns = [Col("Col1", width: .range(0..<1)), // == 0
                           Col("Col2", width: .in(0...0)), // == 0
                           Col("Col3", width: .fixed(0)), // == 0
                           Col("Col4", width: .in(4...4)), // == 4
                           Col("Col5", width: .range(5..<6)), // == 5
            ]
            let table = Tbl(columns: columns, cells: data)
            XCTAssertEqual(table.render(style: .rounded),
                           """
                           ╭┬┬┬────┬─────╮
                           ││││Col4│Col5 │
                           ├┼┼┼────┼─────┤
                           ││││####│#####│
                           ││││    │#    │
                           ╰┴┴┴────┴─────╯
                           
                           """
            )
        }
        do {
            let data:[[Txt]] = [["#", "##", "###"]]
            let columns = [Col("Col1", width: .range(3..<5)),
                           Col("Col2", width: .in(2...3)),
                           Col("Col3", width: .in(1...3))]
            let table = Tbl(columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +---+--+---+
                           |Col|Co|Col|
                           |1  |l2|3  |
                           +---+--+---+
                           |#  |##|###|
                           +---+--+---+
                           
                           """
            )
        }
        do {
            let data:[[Txt]] = [["#", "#", "##", "###"], ["", "##", "#####", "####"]]
            let columns = [Col(width: .range(3..<5)),
                           Col(width: .range(3..<5)),
                           Col(width: .in(2...3)),
                           Col(width: .range(1..<3))]
            let table = Tbl(columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +---+---+---+--+
                           |#  |#  |## |##|
                           |   |   |   |# |
                           +---+---+---+--+
                           |   |## |###|##|
                           |   |   |## |##|
                           +---+---+---+--+
                           
                           """
            )
        }
        do {
            let data:[[Txt]] = [["#", "#", "##", "###", "###"], ["", "##", "#####", "####", "####"]]
            let columns = [Col(width: .range(3..<5)),
                           Col(width: Width(range: 3..<5)),
                           Col(width: .in(2...3), defaultAlignment: .bottomCenter),
                           Col(width: Width(range: 2...2), defaultAlignment: .bottomRight),
                           Col(width: .range(1..<3))]
            let table = Tbl(columns: columns, cells: data)
            XCTAssertEqual(table.render(style: .roundedPadded),
                           """
                           ╭─────┬─────┬─────┬────┬────╮
                           │ #   │ #   │     │ ## │ ## │
                           │     │     │ ##  │  # │ #  │
                           ├─────┼─────┼─────┼────┼────┤
                           │     │ ##  │ ### │ ## │ ## │
                           │     │     │ ##  │ ## │ ## │
                           ╰─────┴─────┴─────┴────┴────╯
                           
                           """
            )
        }
    }
    func test_hiddenVsZeroWidth() {
        do {
            // Zero width
            let cells:[[Txt]] = [
                ["a", "b", "c"],
                ["d", "e"],
                ["f"]
            ]
            let cols = [
                Col("A"),
                Col("B", width: .fixed(0)),
                Col("C"),
                Col("D"),
            ]
            let t = Tbl("Table Title",
                        columns: cols,
                        cells: cells)
            XCTAssertEqual(t.render(),
                           """
                           +-----+
                           |Table|
                           |Title|
                           +-++-++
                           |A||C||
                           +-++-++
                           |a||c||
                           +-++-++
                           |d|| ||
                           +-++-++
                           |f|| ||
                           +-++-++
                           
                           """
            )
        }
        do {
            // Hidden
            let cells:[[Txt]] = [
                ["a", "b", "c"],
                ["d", "e"],
                ["f"]
            ]
            let cols = [
                Col("A"),
                Col("B", width: .hidden),
                Col("C"),
                Col("D"),
            ]
            let t = Tbl("Table Title",
                        columns: cols,
                        cells: cells)
            XCTAssertEqual(t.render(),
                           """
                           +----+
                           |Tabl|
                           | e  |
                           |Titl|
                           | e  |
                           +-+-++
                           |A|C||
                           +-+-++
                           |a|c||
                           +-+-++
                           |d| ||
                           +-+-++
                           |f| ||
                           +-+-++
                           
                           """
            )
        }
    }
    func test_ExpressibleByIntegerLiteralCol() {
        do {
            let test:Col = 42
            let expected:Col = Col(nil,
                                   width: Width.fixed(42),
                                   defaultAlignment: .topLeft,
                                   defaultWrapping: .char,
                                   contentHint: .repetitive)
            XCTAssertEqual(test, expected)
        }
    }
    func test_Tricky() {
        do {
            let cells:[[Txt]] = [
                ["a", "b", "c"],
                ["d", "e"],
                ["f"]
            ]
            let cols = [
                Col("#"),
                Col("Year"),
                Col("Model"),
                Col("X"),
                Col("Y"),
                Col("W"),
            ]
            let t = Tbl("Table Title",
                        columns: cols,
                        cells: cells)
            XCTAssertEqual(t.render(),
                           """
                           +--------+
                           | Table  |
                           | Title  |
                           +-+-+-++++
                           |#|Y|M||||
                           | |e|o||||
                           | |a|d||||
                           | |r|e||||
                           | | |l||||
                           +-+-+-++++
                           |a|b|c||||
                           +-+-+-++++
                           |d|e| ||||
                           +-+-+-++++
                           |f| | ||||
                           +-+-+-++++
                           
                           """
            )
        }
    }
    func test_Codable() throws {
        let expected =
        """
        ╭──────────────────────╮
        │   Summer Olympics    │
        ├────┬─────────┬───────┤
        │Year│Host     │Country│
        ├────┼─────────┼───────┤
        │1952│Helsinki │Finland│
        ├────┼─────────┼───────┤
        │1956│Stockholm│Sweden │
        ├────┼─────────┼───────┤
        │1960│Rome     │Italy  │
        ╰────┴─────────┴───────╯

        """
        do {
            let col = Col(
                "Year",
                width: .auto,
                trimming: [.inlineConsecutiveNewlines, .trailingNewlines]
            )
            //print(col.trimming)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encoded = try encoder.encode(col)
            //print(String(bytes: encoded, encoding: .utf8)!)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Col.self, from: encoded)
            XCTAssertEqual(col, decoded)
        }
        do {
            let cols = [
                Col("Year", width: .auto, trimming: [.inlineConsecutiveNewlines, .trailingNewlines]),
                Col("Host", width: .in(5...25), defaultWrapping: .word),
                Col("Country"),
            ]
            let cells:[[Txt]] = [
                ["1952", "Helsinki", "Finland"],
                ["1956", "Stockholm", "Sweden"],
                ["1960", "Rome", "Italy"],
            ]
            let table = Tbl("Summer Olympics", columns: cols, cells: cells)
            XCTAssertEqual(table.render(style: .rounded), expected)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encoded = try encoder.encode(table)
            //print(String(bytes: encoded, encoding: .utf8)!)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Tbl.self, from: encoded)
            XCTAssertEqual(table, decoded)
            XCTAssertEqual(decoded.render(style: .rounded), expected)
        }
        do {
            let elements = FrameStyle.rounded
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let encoded = try encoder.encode(elements)
            //print(String(bytes: encoded, encoding: .utf8)!)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(FrameStyle.self, from: encoded)
            XCTAssertEqual(elements, decoded)
        }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let decoder = JSONDecoder()

            let cells:[[Txt]] = [
                [Txt("Abc"), Txt("What?", alignment: .topRight, wrapping: .char)],
                [Txt("Automatic\ncolumn\nwidth with proper\nnewline handling"), Txt("Quick brown fox")]
            ]
            let columns = [
                Col(Txt("Auto column", alignment: .bottomCenter),
                    defaultAlignment: .topLeft, defaultWrapping: .cut),
                Col("Fixed column", width: .fixed(10),
                    defaultAlignment: .middleCenter, defaultWrapping: .word),
            ]
            let table:Tbl = Tbl(
                Txt("Title\n-*-\nwith newlines"),
                columns: columns,
                cells: cells
            )
            //print(table.render())

            let encoded = try encoder.encode(table)

            /*if let utf8 = String(data: encoded, encoding: .utf8) {
                print(utf8)
            }*/

            let decoded = try decoder.decode(Tbl.self, from: encoded)
            //print(type(of: decoded))
            //print(decoded.render())
            
            XCTAssertEqual(table.self, decoded.self)
            XCTAssertEqual(table, decoded)
            XCTAssertEqual(table.render(style: .roundedPadded,
                                        options: .all),
                           decoded.render(style: .roundedPadded,
                                          options: .all))
        }
    }
    func test_obeyNewline() {
        do {
            // Newline handling
            // Txt elements are first splitted into separate elements at each newline.
            // After separation, wrapping is applied individually on each separated element.
            let textWithNewline = Txt("Quick brown\nfox jumps over the lazy dog")
            let table = Tbl(Txt("Title wider than column width", alignment: .middleLeft), columns: [Col(width: 16)],
                            cells: [[textWithNewline]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |Title wider than|
                           |column width    |
                           +----------------+
                           |Quick brown     |
                           |fox jumps over t|
                           |he lazy dog     |
                           +----------------+
                           
                           """)
        }
        do {
            // Newline handling
            // Txt elements are first splitted into separate elements at each newline.
            // After separation, wrapping is applied individually on each separated element.
            let textWithNewline = Txt("Quick brown\nfox jumps\nover the lazy dog")
            let table = Tbl(Txt("Title wider than column width", alignment: .middleLeft), columns: [Col(width: 16)],
                            cells: [[textWithNewline]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |Title wider than|
                           |column width    |
                           +----------------+
                           |Quick brown     |
                           |fox jumps       |
                           |over the lazy do|
                           |g               |
                           +----------------+
                           
                           """)
        }
        do {
            // Newline handling
            // Txt elements are first splitted into separate elements at each newline.
            // After separation, wrapping is applied individually on each separated element.
            let textWithNewline = Txt("Quick brown\nfox jumps\n\nover the lazy dog")
            let table = Tbl(Txt("Title wider than column width", alignment: .middleLeft), columns: [Col(width: 16)],
                            cells: [[textWithNewline]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |Title wider than|
                           |column width    |
                           +----------------+
                           |Quick brown     |
                           |fox jumps       |
                           |                |
                           |over the lazy do|
                           |g               |
                           +----------------+
                           
                           """)
        }
        do {
            // Newline handling
            // Txt elements are first splitted into separate elements at each newline.
            // After separation, wrapping is applied individually on each separated element.
            let textWithNewline = Txt("Quick brown\nfox jumps\n\nover the lazy dog")
            let table = Tbl(Txt("Title wider than column width", alignment: .middleLeft),
                            columns: [Col(width: 16, defaultAlignment: .topRight)],
                            cells: [[textWithNewline]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |Title wider than|
                           |column width    |
                           +----------------+
                           |     Quick brown|
                           |       fox jumps|
                           |                |
                           |over the lazy do|
                           |               g|
                           +----------------+
                           
                           """)
        }
        do {
            // Newline handling
            // Txt elements are first splitted into separate elements at each newline.
            // After separation, wrapping is applied individually on each separated element.
            let textWithNewline = Txt("\n\nQuick brown\nfox jumps\n\nover the lazy dog\n\n", alignment: .middleCenter)
            let table = Tbl(Txt("Title wider than column width", alignment: .middleLeft),
                            columns: [Col(width: 16)],
                            cells: [[textWithNewline]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |Title wider than|
                           |column width    |
                           +----------------+
                           |                |
                           |                |
                           |  Quick brown   |
                           |   fox jumps    |
                           |                |
                           |over the lazy do|
                           |       g        |
                           |                |
                           |                |
                           +----------------+
                           
                           """)
        }
        do {
            // Newline handling
            // Txt elements are first splitted into separate elements at each newline.
            // After separation, wrapping is applied individually on each separated element.
            let textWithNewline = Txt("\n\nQuick brown\nfox jumps\n\nover the lazy dog\n\n", alignment: .middleCenter, wrapping: .word)
            let table = Tbl(Txt("Title wider than column width", alignment: .middleLeft),
                            columns: [Col(width: 16)],
                            cells: [[textWithNewline]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |Title wider than|
                           |column width    |
                           +----------------+
                           |                |
                           |                |
                           |  Quick brown   |
                           |   fox jumps    |
                           |                |
                           | over the lazy  |
                           |      dog       |
                           |                |
                           |                |
                           +----------------+
                           
                           """)
        }
        do {
            // Newline handling
            // Txt elements are first splitted into separate elements at each newline.
            // After separation, wrapping is applied individually on each separated element.
            let textWithNewline = Txt("\n\nQuick brown\nfox jumps\n\nover the lazy dog\n\n", alignment: .middleCenter, wrapping: .cut)
            let table = Tbl(Txt("Title wider than column width", alignment: .middleLeft),
                            columns: [Col(width: 16)],
                            cells: [[textWithNewline]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |Title wider than|
                           |column width    |
                           +----------------+
                           |                |
                           |                |
                           |  Quick brown   |
                           |   fox jumps    |
                           |                |
                           |over th…lazy dog|
                           |                |
                           |                |
                           +----------------+
                           
                           """)
        }
        do {
            // Newline handling
            // Txt elements are first splitted into separate elements at each newline.
            // After separation, wrapping is applied individually on each separated element.
            let textWithNewline = Txt("\n\nQuick brown\nfox jumps\n\nover the lazy dog\n\n", alignment: .middleCenter, wrapping: .cut)
            let table = Tbl(Txt("Title obeys\nnewlines as well", alignment: .middleLeft, wrapping: .word),
                            columns: [Col(width: 16)],
                            cells: [[textWithNewline]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |Title obeys     |
                           |newlines as well|
                           +----------------+
                           |                |
                           |                |
                           |  Quick brown   |
                           |   fox jumps    |
                           |                |
                           |over th…lazy dog|
                           |                |
                           |                |
                           +----------------+
                           
                           """)
        }
        do {
            // Newline handling
            // Txt elements are first splitted into separate elements at each newline.
            // After separation, wrapping is applied individually on each separated element.
            let textWithNewline = Txt("\n\nQuick brown\nfox jumps\n\nover the lazy dog\n\n", alignment: .middleCenter, wrapping: .cut)
            let table = Tbl(Txt("Title obeys\nnewlines as well", alignment: .middleLeft, wrapping: .word),
                            columns: [Col(width: .auto)],
                            cells: [[textWithNewline]])
            XCTAssertEqual(table.render(),
                           """
                           +-----------------+
                           |Title obeys      |
                           |newlines as well |
                           +-----------------+
                           |                 |
                           |                 |
                           |   Quick brown   |
                           |    fox jumps    |
                           |                 |
                           |over the lazy dog|
                           |                 |
                           |                 |
                           +-----------------+
                           
                           """)
        }
    }
    func test_renderRange() {
        var src:[[Txt]] = []
        for i in 0..<3 {
            var row:[Txt] = []
            for j in 0..<3 {
                row.append(Txt("r\(i)c\(j)"))
            }
            src.append(row)
        }
        let columns = [Col("AB"),"C","D"]
        let tbl = Tbl("Title", columns: columns, cells: src)
        do {
            var s:String = ""
            tbl.render(style: .squared, rows: [0..<1], to: &s)
            XCTAssertEqual(s,
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │AB  │C   │D   │
                           ├────┼────┼────┤
                           │r0c0│r0c1│r0c2│
                           └────┴────┴────┘
                           
                           """
            )
        }
        do {
            var s:String = ""
            tbl.render(style: .squared, rows: [0..<2], to: &s)
            XCTAssertEqual(s,
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │AB  │C   │D   │
                           ├────┼────┼────┤
                           │r0c0│r0c1│r0c2│
                           ├────┼────┼────┤
                           │r1c0│r1c1│r1c2│
                           └────┴────┴────┘
                           
                           """
            )
        }
        do {
            var s:String = ""
            tbl.render(style: .squared, rows: [1..<2], to: &s)
            XCTAssertEqual(s,
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │AB  │C   │D   │
                           ├────┼────┼────┤
                           │r1c0│r1c1│r1c2│
                           └────┴────┴────┘
                           
                           """
            )
        }
        do {
            var s:String = ""
            tbl.render(style: .squared, rows: [2..<3], to: &s)
            XCTAssertEqual(s,
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │AB  │C   │D   │
                           ├────┼────┼────┤
                           │r2c0│r2c1│r2c2│
                           └────┴────┴────┘
                           
                           """
            )
        }
        do {
            var s:String = ""
            tbl.render(style: .squared, rows: [2..<2], to: &s)
            XCTAssertEqual(s,
                           """
                           ┌──────┐
                           │Title │
                           ├──┬─┬─┤
                           │AB│C│D│
                           ├──┼─┼─┤
                           └──┴─┴─┘
                           
                           """
            )
        }
        do {
            // Corner case -> multiple 'empty' ranges given.
            var s:String = ""
            tbl.render(style: .squared, rows: [0..<0, 1..<1, 2..<2], to: &s)
            XCTAssertEqual(s,
                           """
                           ┌──────┐
                           │Title │
                           ├──┬─┬─┤
                           │AB│C│D│
                           ├──┼─┼─┤
                           ├╌╌┼╌┼╌┤
                           ├╌╌┼╌┼╌┤
                           └──┴─┴─┘
                           
                           """
            )
        }
        do {
            XCTAssertEqual(tbl.render(style: .squared, rows: [0..<3]),
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │AB  │C   │D   │
                           ├────┼────┼────┤
                           │r0c0│r0c1│r0c2│
                           ├────┼────┼────┤
                           │r1c0│r1c1│r1c2│
                           ├────┼────┼────┤
                           │r2c0│r2c1│r2c2│
                           └────┴────┴────┘
                           
                           """
            )
            XCTAssertEqual(tbl.render(style: .squared),
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │AB  │C   │D   │
                           ├────┼────┼────┤
                           │r0c0│r0c1│r0c2│
                           ├────┼────┼────┤
                           │r1c0│r1c1│r1c2│
                           ├────┼────┼────┤
                           │r2c0│r2c1│r2c2│
                           └────┴────┴────┘

                           """
            )
        }
        do {
            XCTAssertEqual(tbl.render(style: .squared, rows: [0..<1, 2..<3]),
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │AB  │C   │D   │
                           ├────┼────┼────┤
                           │r0c0│r0c1│r0c2│
                           ├╌╌╌╌┼╌╌╌╌┼╌╌╌╌┤
                           │r2c0│r2c1│r2c2│
                           └────┴────┴────┘
                           
                           """
            )
        }
    }
    func test_autoLineNumbers() {
        class HexFormatter : Formatter {
            override func string(for obj: Any?) -> String? {
                guard let i = obj as? Int else {
                    return nil
                }
                return String(format: "0x%08x:", i)
            }
        }
        let cells :[[Txt]] = "abcdefghijklmnopqrstuvwxyz"
            .map({ [Txt("Letter \($0)"),
                    Txt($0.description)]
            })
        do {
            // Automatic line numbers are visible when Tbl is
            // initialized with 'withAutomaticLineNumberingStartingFrom'
            let table = Tbl(Txt("Testing automatic line numbers for \(cells.count) rows"),
                             cells: cells, lineNumberGenerator: { i in
                return Txt((i+1).description)
            })
            // No custom line number formatter set, use default
            // which is just plain numbers, aligned .bottomRight
            
            XCTAssertEqual(table.render(rows: [0..<2, 24..<cells.count]),
                           """
                           +-------------+
                           |   Testing   |
                           |  automatic  |
                           |line numbers |
                           | for 26 rows |
                           +--+--------+-+
                           |1 |Letter a|a|
                           +--+--------+-+
                           |2 |Letter b|b|
                           +~~+~~~~~~~~+~+
                           |25|Letter y|y|
                           +--+--------+-+
                           |26|Letter z|z|
                           +--+--------+-+
                           
                           """
            )
        }
        do {
            // Automatic line numbers are visible when Tbl is
            // initialized with 'withAutomaticLineNumberingStartingFrom'
            // Let's offset our line numbers by 99
            let table = Tbl(Txt("Testing automatic line numbers for \(cells.count) rows"),
                             cells: cells, lineNumberGenerator: { i in
                return Txt((i+99).description)
            })

            // No custom line number formatter set, use default
            // which is just plain numbers, aligned .bottomRight
            
            XCTAssertEqual(table.render(rows: [0..<2, 24..<cells.count]),
                           """
                           +--------------+
                           |   Testing    |
                           |automatic line|
                           |numbers for 26|
                           |     rows     |
                           +---+--------+-+
                           |99 |Letter a|a|
                           +---+--------+-+
                           |100|Letter b|b|
                           +~~~+~~~~~~~~+~+
                           |123|Letter y|y|
                           +---+--------+-+
                           |124|Letter z|z|
                           +---+--------+-+
                           
                           """
            )
        }
        do {
            // Automatic line numbers are visible when Tbl is
            // initialized with 'withAutomaticLineNumberingStartingFrom'
            // Let's offset our line numbers by 99
            let lineNumberGenerator = { i in
                let f = NumberFormatter()
                f.numberStyle = .ordinal
                return Txt(f.string(for: i+99) ?? "?")
            }
            let table = Tbl(Txt("Testing automatic line numbers for \(cells.count) rows"),
                            cells: cells, lineNumberGenerator: lineNumberGenerator)
            // Set formatter to NumberFormatter, with bit weird numbering style
            XCTAssertEqual(table.render(rows: [0..<2, 24..<cells.count]),
                           """
                           +----------------+
                           |    Testing     |
                           | automatic line |
                           | numbers for 26 |
                           |      rows      |
                           +-----+--------+-+
                           |99th |Letter a|a|
                           +-----+--------+-+
                           |100th|Letter b|b|
                           +~~~~~+~~~~~~~~+~+
                           |123rd|Letter y|y|
                           +-----+--------+-+
                           |124th|Letter z|z|
                           +-----+--------+-+
                           
                           """
            )
        }
        do {
            let randomBytes = [
                "f4", "a4", "61", "fc", "06", "f0", "a8", "6a",
                "cd", "b0", "ac", "7a", "5b", "8e", "ce", "8a",
                "bb", "ee", "13", "27", "ab", "b2", "ec", "ed",
                "b7", "e2", "e5", "25", "62", "9c", "99", "d9",
                "ab", "bc", "31", "d2", "c3", "7b", "14", "12",
                "9c", "fc", "af", "cf", "de", "bb", "3d", "11",
                "95", "45", "43", "98", "36", "14", "7d", "12",
                "9f", "44", "84", "7a", "8f", "3b"
            ].map({ Txt($0) })
            var cells:[[Txt]] = []
            let step = 16
            for line in stride(from: 0, to: randomBytes.count, by: step) {
                cells.append(Array(randomBytes[line..<Swift.min(randomBytes.count, line + step)]))
            }
            let lineNumberGenerator = { i in
                return Txt(String(format: "0x%08x:", i * step))
            }
            let table = Tbl(Txt("Hexdump", alignment: .bottomLeft),
                             cells: cells,
                             lineNumberGenerator: lineNumberGenerator)
            // Set formatter to NumberFormatter, with completely unexpected
            // numbering style. Automatic line numbering implementation assumes
            // that the required column width for the very last row number is
            // the widest column width required to present line numbers. For
            // most of the use cases this works well, but as this test demonstrates,
            // things can be weird and that assumption doesn't always hold true.
            // Because of this, automatic line number column wrapping is set
            // to '.cut' (to keep automatic line numbering vertical height at 1)
            let answer = [
                "Hexdump                                                    ",
                "0x00000000: f4 a4 61 fc 06 f0 a8 6a cd b0 ac 7a 5b 8e ce 8a",
                "0x00000010: bb ee 13 27 ab b2 ec ed b7 e2 e5 25 62 9c 99 d9",
                "0x00000020: ab bc 31 d2 c3 7b 14 12 9c fc af cf de bb 3d 11",
                "0x00000030: 95 45 43 98 36 14 7d 12 9f 44 84 7a 8f 3b      ",
                ""
            ].joined(separator: "\n")
            XCTAssertEqual(table.render(style: .singleSpace,
                                        options: .insideVerticalFrame),
                           answer)
        }
        do {
            let lineNumberGenerator = { i in
                // By default line numbers are aligned to bottom right
                // Let's override it
                return Txt((Int(i)*i).description,
                           alignment: .topLeft) // <- override is here
            }
            let table = Tbl(Txt("Override line number column alignment"),
                             cells: cells,
                             lineNumberGenerator: lineNumberGenerator)
            XCTAssertEqual(table.render(rows: [0..<3, 23..<cells.count]),
                           """
                           +--------------+
                           |Override line |
                           |number column |
                           |  alignment   |
                           +---+--------+-+
                           |0  |Letter a|a|
                           +---+--------+-+
                           |1  |Letter b|b|
                           +---+--------+-+
                           |4  |Letter c|c|
                           +~~~+~~~~~~~~+~+
                           |529|Letter x|x|
                           +---+--------+-+
                           |576|Letter y|y|
                           +---+--------+-+
                           |625|Letter z|z|
                           +---+--------+-+
                           
                           """
            )
        }
    }
    func test_lineNumbersWithNewLines() {
        let columns = [
            Col(Txt("#", alignment: .bottomCenter), width: .auto),
            Col(
                Txt("Pangram", alignment: .bottomRight, wrapping: .cut),
                width: 16,
                defaultAlignment: .topRight,
                defaultWrapping: .word,
                trimming: [],
                contentHint: .unique),
        ]
        let cells:[[Txt]] = [
            [Txt(pangram)],
            [Txt(String(pangram.reversed()))],
            [Txt(pangram, wrapping: .cut), "extra"],
        ]
        let myLnGen:(Int) -> Txt = { i in
            return Txt(String(format: "Line\n%d", i + 1), alignment: i % 2 == 0 ? .bottomLeft : .bottomRight)
        }
        let tbl = Tbl(
            Txt("Well known pangrams from around the world"),
            columns: columns,
            cells: cells,
            lineNumberGenerator: myLnGen
        )
        tbl.debugMask = []//[.telemetry, .info, .debug]
        let rendered = tbl.render(style: .debug)//, rows: [0..<3, 1..<cells.count]))
        let expected =
                """
                ┌┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┐
                ┆ Well known pangrams from  ┊
                ┆     around the world      ┊
                ├┄┄┄┄┬┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┬┄┄┄┄┄┤
                ┆ #  ╎         Pangram╎     ┊
                ├┄┄┄┄┼┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┼┄┄┄┄┄┤
                ┆    ╎ The quick brown╎     ┊
                ┆Line╎  fox jumps over╎     ┊
                ┆1   ╎    the lazy dog╎     ┊
                ├┄┄┄┄┼┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┼┄┄┄┄┄┤
                ┆    ╎    god yzal eht╎     ┊
                ┆Line╎  revo spmuj xof╎     ┊
                ┆   2╎ nworb kciuq ehT╎     ┊
                ├┄┄┄┄┼┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┼┄┄┄┄┄┤
                ┆Line╎The qui…lazy dog╎extra┊
                ┆3   ╎                ╎     ┊
                └┉┉┉┉┴┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┉┴┉┉┉┉┉┘
                
                """
        XCTAssertEqual(rendered, expected)
    }
    func test_README() {
        do {
            let cells:[[Txt]] = [
                ["123",
                 Txt("x", alignment: .topLeft),
                 Txt("x", alignment: .topCenter),
                 Txt("x", alignment: .topRight)],
                ["123",
                 Txt("x", alignment: .middleLeft),
                 Txt("x", alignment: .middleCenter),
                 Txt("x", alignment: .middleRight)],
                ["123",
                 Txt("x", alignment: .bottomLeft),
                 Txt("x", alignment: .bottomCenter),
                 Txt("x", alignment: .bottomRight)],
            ]
            let width:Width = 5
            
            let cols = [
                Col("#", width: 1, defaultAlignment: .topLeft),
                Col("Col 1", width: width, defaultAlignment: .bottomCenter),
                Col("Col 2", width: width, defaultAlignment: .bottomCenter),
                Col("Col 3", width: width, defaultAlignment: .bottomCenter),
            ]
            let table = Tbl("Table title",
                            columns: cols,
                            cells: cells)
            
            print(table.render(style: .roundedPadded))
            // Produces ->
            //╭───────────────────────────╮
            //│        Table title        │
            //├───┬───────┬───────┬───────┤
            //│ # │ Col 1 │ Col 2 │ Col 3 │
            //├───┼───────┼───────┼───────┤
            //│ 1 │ x     │   x   │     x │
            //│ 2 │       │       │       │
            //│ 3 │       │       │       │
            //├───┼───────┼───────┼───────┤
            //│ 1 │       │       │       │
            //│ 2 │ x     │   x   │     x │
            //│ 3 │       │       │       │
            //├───┼───────┼───────┼───────┤
            //│ 1 │       │       │       │
            //│ 2 │       │       │       │
            //│ 3 │ x     │   x   │     x │
            //╰───┴───────┴───────┴───────╯
            XCTAssertEqual(table.render(style: .roundedPadded),
                           """
                           ╭───────────────────────────╮
                           │        Table title        │
                           ├───┬───────┬───────┬───────┤
                           │ # │ Col 1 │ Col 2 │ Col 3 │
                           ├───┼───────┼───────┼───────┤
                           │ 1 │ x     │   x   │     x │
                           │ 2 │       │       │       │
                           │ 3 │       │       │       │
                           ├───┼───────┼───────┼───────┤
                           │ 1 │       │       │       │
                           │ 2 │ x     │   x   │     x │
                           │ 3 │       │       │       │
                           ├───┼───────┼───────┼───────┤
                           │ 1 │       │       │       │
                           │ 2 │       │       │       │
                           │ 3 │ x     │   x   │     x │
                           ╰───┴───────┴───────┴───────╯
                           
                           """
            )
        }
        do {
            let table = Tbl("Summer Olympics") {

                Columns {
                    Col("Year", width: 4)
                    Col("Host", width: .in(5...25), defaultWrapping: .word)
                    Col("Country")
                }
                
                Rows {
                    ["1952", "Helsinki", "Finland"]
                    ["1956", "Stockholm", "Sweden"]
                    ["1960", "Rome", "Italy"]
                }
            }
            print(table.render(style: .rounded))
            //╭──────────────────────╮
            //│   Summer Olympics    │
            //├────┬─────────┬───────┤
            //│Year│Host     │Country│
            //├────┼─────────┼───────┤
            //│1952│Helsinki │Finland│
            //├────┼─────────┼───────┤
            //│1956│Stockholm│Sweden │
            //├────┼─────────┼───────┤
            //│1960│Rome     │Italy  │
            //╰────┴─────────┴───────╯
            XCTAssertEqual(table.render(style: .rounded),
                           """
                           ╭──────────────────────╮
                           │   Summer Olympics    │
                           ├────┬─────────┬───────┤
                           │Year│Host     │Country│
                           ├────┼─────────┼───────┤
                           │1952│Helsinki │Finland│
                           ├────┼─────────┼───────┤
                           │1956│Stockholm│Sweden │
                           ├────┼─────────┼───────┤
                           │1960│Rome     │Italy  │
                           ╰────┴─────────┴───────╯
                           
                           """
            )
        }
    }
    func test_contentHint_unique_bug() {
        do {
            let cells:[[Txt]] = [["Quick brown\nfox", "jumped\nover"], ["the\nlazy", "dog."]]
            let c = [Col(width: 9, defaultWrapping: .char, contentHint: .unique),
                     Col(width: 4, defaultWrapping: .word, contentHint: .unique)]
            let t = Tbl("title",columns: c, cells: cells)
            //print(t.render(style: .roundedPadded))
            XCTAssertEqual(t.render(style: .roundedPadded),
                           """
                           ╭──────────────────╮
                           │      title       │
                           ├───────────┬──────┤
                           │ Quick bro │ jump │
                           │ wn        │ ed   │
                           │ fox       │ over │
                           ├───────────┼──────┤
                           │ the       │ dog. │
                           │ lazy      │      │
                           ╰───────────┴──────╯
                           
                           """)
        }
    }
    func test_word2_wrapping() {
        do {
            let qbf = "\n \nQu\nick brown  fox jum-\n\n\n\nped over the l a z y dog.\n"
            let cells:[[Txt]] = [
                [Txt(qbf, alignment: .topLeft), Txt(qbf, alignment: .topRight)],
                [Txt(qbf, alignment: .bottomRight), Txt(qbf, alignment: .bottomLeft)],
            ]
            let c = [
                Col(width: 9, defaultWrapping: .char, contentHint: .unique),
                Col(width: .hidden, defaultWrapping: .char, contentHint: .unique),
                Col(width: .auto, defaultWrapping: .char, contentHint: .unique)
            ]
            let t = Tbl("title",columns: c, cells: cells)
            let rendered = t.render(style: .roundedPadded)
            XCTAssertEqual(rendered,
                           """
                           ╭──────────────╮
                           │    title     │
                           ├───────────┬──┤
                           │           │  │
                           │           │  │
                           │ Qu        │  │
                           │ ick brown │  │
                           │   fox jum │  │
                           │ -         │  │
                           │           │  │
                           │           │  │
                           │           │  │
                           │ ped over  │  │
                           │ the l a z │  │
                           │  y dog.   │  │
                           │           │  │
                           ├───────────┼──┤
                           │           │  │
                           │           │  │
                           │        Qu │  │
                           │ ick brown │  │
                           │   fox jum │  │
                           │         - │  │
                           │           │  │
                           │           │  │
                           │           │  │
                           │ ped over  │  │
                           │ the l a z │  │
                           │    y dog. │  │
                           │           │  │
                           ╰───────────┴──╯
                           
                           """)
        }
    }
    func test_columnRow() {
        do {
            let cols = [
                Col("Abc"),
                Col(Txt("Min 7", alignment: .bottomCenter), width: .min(7)),
                Col("Max 2", width: .max(2)),
                Col("Triplet", width: 3, defaultAlignment: .bottomCenter, defaultWrapping: .char),
                Col("Rnge", width: .range(2..<5), defaultAlignment: .middleCenter),
                Col(Txt("In", alignment: .bottomRight), width: .in(3...6)),
            ]
            let cells = [
                [Txt("Auto"), Txt("min"), Txt("maximum"), Txt("tripletto"), Txt("Range"), Txt("12345678")]
            ]
            let t = Tbl("Title", columns: cols, cells: cells)
            XCTAssertEqual(t.render(style: .debug),
                           """
                           ┌┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┐
                           ┆             Title             ┊
                           ├┄┄┄┄┬┄┄┄┄┄┄┄┬┄┄┬┄┄┄┬┄┄┄┄┬┄┄┄┄┄┄┤
                           ┆Abc ╎       ╎Ma╎Tri╎    ╎      ┊
                           ┆    ╎       ╎x ╎ple╎Rnge╎      ┊
                           ┆    ╎ Min 7 ╎2 ╎ t ╎    ╎    In┊
                           ├┄┄┄┄┼┄┄┄┄┄┄┄┼┄┄┼┄┄┄┼┄┄┄┄┼┄┄┄┄┄┄┤
                           ┆Auto╎min    ╎ma╎   ╎    ╎123456┊
                           ┆    ╎       ╎xi╎tri╎Rang╎78    ┊
                           ┆    ╎       ╎mu╎ple╎ e  ╎      ┊
                           ┆    ╎       ╎m ╎tto╎    ╎      ┊
                           └┉┉┉┉┴┉┉┉┉┉┉┉┴┉┉┴┉┉┉┴┉┉┉┉┴┉┉┉┉┉┉┘
                           
                           """
            )
        }
        do {
            let cols = [
                Col("Abc"),
                Col(Txt("Min 7", alignment: .bottomCenter), width: .min(7)),
                Col("Max 2", width: .max(2)),
                Col("Triplet", width: 3, defaultAlignment: .bottomCenter, defaultWrapping: .char),
                Col("Rnge", width: .range(2..<5), defaultAlignment: .middleCenter),
                Col(Txt("In", alignment: .bottomRight), width: .in(3...6)),
            ]
            let cells = [
                [Txt("Auto"), Txt("12345678"), Txt("m"), Txt("tripletto"), Txt("R"), Txt("1")]
            ]
            let t = Tbl("Title", columns: cols, cells: cells)
            XCTAssertEqual(t.render(style: .debug),
                           """
                           ┌┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┐
                           ┆          Title           ┊
                           ├┄┄┄┄┬┄┄┄┄┄┄┄┄┬┄┬┄┄┄┬┄┄┬┄┄┄┤
                           ┆Abc ╎        ╎M╎   ╎  ╎   ┊
                           ┆    ╎        ╎a╎   ╎Rn╎   ┊
                           ┆    ╎        ╎x╎Tri╎ge╎   ┊
                           ┆    ╎        ╎ ╎ple╎  ╎   ┊
                           ┆    ╎ Min 7  ╎2╎ t ╎  ╎ In┊
                           ├┄┄┄┄┼┄┄┄┄┄┄┄┄┼┄┼┄┄┄┼┄┄┼┄┄┄┤
                           ┆Auto╎12345678╎m╎tri╎  ╎1  ┊
                           ┆    ╎        ╎ ╎ple╎R ╎   ┊
                           ┆    ╎        ╎ ╎tto╎  ╎   ┊
                           └┉┉┉┉┴┉┉┉┉┉┉┉┉┴┉┴┉┉┉┴┉┉┴┉┉┉┘
                           
                           """
            )
        }
        do {
            let cols = [
                Col("Abc"),
                Col(Txt("Min 7", alignment: .bottomCenter), width: .min(7)),
                Col("Max 2", width: .max(2)),
                Col("Triplet", width: 3, defaultAlignment: .bottomCenter, defaultWrapping: .char),
                Col("Rnge", width: .range(2..<5), defaultAlignment: .middleCenter),
                Col(Txt("In", alignment: .bottomRight), width: .in(3...6)),
            ]
            let t = Tbl("Title", columns: cols, cells: [])
            XCTAssertEqual(t.render(style: .debug),
                           """
                           ┌┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┅┐
                           ┆           Title           ┊
                           ├┄┄┄┬┄┄┄┄┄┄┄┬┄┄┬┄┄┄┬┄┄┄┄┬┄┄┄┤
                           ┆Abc╎       ╎Ma╎Tri╎    ╎   ┊
                           ┆   ╎       ╎x ╎ple╎Rnge╎   ┊
                           ┆   ╎ Min 7 ╎2 ╎ t ╎    ╎ In┊
                           ├┄┄┄┼┄┄┄┄┄┄┄┼┄┄┼┄┄┄┼┄┄┄┄┼┄┄┄┤
                           └┉┉┉┴┉┉┉┉┉┉┉┴┉┉┴┉┉┉┴┉┉┉┉┴┉┉┉┘
                           
                           """
            )
        }
    }
    func test_renx_hex() {
        let hexGen:(Int) -> Txt = { n in
            let addr = n * 16
            let str = String(format: "0x%06x", addr)
            return Txt(str)
        }
        let cells:[[Txt]] =
        (0..<16).map({ l in
            let ra = (0..<16).map({ m in (16 * l) + m })
            //                print(ra)
            return [
                Txt(ra.map({ String(format: "%02x", $0) }).joined(separator: ":")),
                Txt(ra.map({
                    let c = Character(UnicodeScalar($0)!)
                    return (c.isLetter || c.isNumber || c.isPunctuation) ? Character(UnicodeScalar($0)!).description : "." }).joined())
            ]
        })
        
        let expected:String = [
            "                                 Hexdump                                 ",
            "0x000000 00:01:02:03:04:05:06:07:08:09:0a:0b:0c:0d:0e:0f ................",
            "0x000010 10:11:12:13:14:15:16:17:18:19:1a:1b:1c:1d:1e:1f ................",
            "0x000020 20:21:22:23:24:25:26:27:28:29:2a:2b:2c:2d:2e:2f .!\"#.%&'()*.,-./",
            "0x000030 30:31:32:33:34:35:36:37:38:39:3a:3b:3c:3d:3e:3f 0123456789:;...?",
            "0x000040 40:41:42:43:44:45:46:47:48:49:4a:4b:4c:4d:4e:4f @ABCDEFGHIJKLMNO",
            "0x000050 50:51:52:53:54:55:56:57:58:59:5a:5b:5c:5d:5e:5f PQRSTUVWXYZ[\\]._",
            "0x000060 60:61:62:63:64:65:66:67:68:69:6a:6b:6c:6d:6e:6f .abcdefghijklmno",
            "0x000070 70:71:72:73:74:75:76:77:78:79:7a:7b:7c:7d:7e:7f pqrstuvwxyz{.}..",
            "0x000080 80:81:82:83:84:85:86:87:88:89:8a:8b:8c:8d:8e:8f ................",
            "0x000090 90:91:92:93:94:95:96:97:98:99:9a:9b:9c:9d:9e:9f ................",
            "0x0000a0 a0:a1:a2:a3:a4:a5:a6:a7:a8:a9:aa:ab:ac:ad:ae:af .¡.....§..ª«....",
            "0x0000b0 b0:b1:b2:b3:b4:b5:b6:b7:b8:b9:ba:bb:bc:bd:be:bf ..²³.µ¶·.¹º»¼½¾¿",
            "0x0000c0 c0:c1:c2:c3:c4:c5:c6:c7:c8:c9:ca:cb:cc:cd:ce:cf ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏ",
            "0x0000d0 d0:d1:d2:d3:d4:d5:d6:d7:d8:d9:da:db:dc:dd:de:df ÐÑÒÓÔÕÖ.ØÙÚÛÜÝÞß",
            "0x0000e0 e0:e1:e2:e3:e4:e5:e6:e7:e8:e9:ea:eb:ec:ed:ee:ef àáâãäåæçèéêëìíîï",
            "0x0000f0 f0:f1:f2:f3:f4:f5:f6:f7:f8:f9:fa:fb:fc:fd:fe:ff ðñòóôõö.øùúûüýþÿ",
        ].joined(separator: "\n") + "\n"
        let rendered = cells.render(
            title: "Hexdump",
            style: .singleSpace,
            options: .insideVerticalFrame,
            lineNumberGenerator: hexGen
        )
        XCTAssertEqual(rendered, expected)
    }

    func test_wordsx() {
        do {
            XCTAssertEqual(wordsx("Summer Olympics", to: 0), [])
            XCTAssertEqual(wordsx("Summer Olympics", to: 5), ["Summe", "r", "Olymp", "ics"])
            XCTAssertEqual(wordsx("Summer Olympics", to: 12), ["Summer","Olympics"])
            XCTAssertEqual(wordsx("Summer Olympics", to: 40), ["Summer Olympics"])
        }
    }
}
final class WidthTests : XCTestCase {
    func test_init() {
        do {
            //XCTAssertEqual(Width(-1), Width.fixed(-1))
            XCTAssertEqual(Width(0), Width.fixed(0))
            XCTAssertEqual(Width(1024), Width.fixed(1024))
            XCTAssertTrue(Width.fixed(0).isVisible)
            XCTAssertTrue(Width.fixed(1024).isVisible)
            //XCTAssertEqual(Width(1025), Width.fixed(1025))
            
            XCTAssertTrue(Width.auto.isVisible)
            XCTAssertTrue(Width.min(0).isVisible)
            XCTAssertTrue(Width.max(0).isVisible)
            XCTAssertTrue(Width.range(0..<1024).isVisible)
            XCTAssertTrue(Width.in(0...1024).isVisible)
            XCTAssertFalse(Width.hidden.isVisible)
        }
        /*
        do {
            let tests:[(Int,Int)] = [(-2,-2), (-1, -1), (0,0), (1,1)]
            for (test,expect) in tests {
                let w:Width = Width(test)
                XCTAssertEqual(expect, w.value)
            }
        }
        do {
            let i:Int = 42
            let R:Range = i ..< i+1
            let C:ClosedRange = i ... i+1

            XCTAssertEqual(Width.fixed(i), 42)
            XCTAssertEqual(Width.fixed(i).value, i)
            XCTAssertEqual(Width.min(i).value, 42)
            if case let Width.min(j) = Width.min(i) {
                XCTAssertEqual(j, i)
            }
            
            XCTAssertEqual(Width.max(i).value, i)
            if case let Width.max(j) = Width.max(i) {
                XCTAssertEqual(j, i)
            }
            
            XCTAssertEqual(Width.range(i ..< (i+1)).value, -5)
            if case let Width.range(r) = Width.range(i ..< (i+1)) {
                XCTAssertEqual(R, r)
                XCTAssertEqual(r.lowerBound, i)
                XCTAssertEqual(r.upperBound, i+1)
            }

            XCTAssertEqual(Width.in(i ... (i+1)).value, -6)
            if case let Width.in(c) = Width.in(i ... (i+1)) {
                XCTAssertEqual(C, c)
                XCTAssertEqual(c.lowerBound, i)
                XCTAssertEqual(c.upperBound, i+1)
            }
        }*/
    }
}
final class DSLTests : XCTestCase {
    func test_DSL() {
        let expected_rounded =
        """
        ╭──────────────────────╮
        │   Summer Olympics    │
        ├────┬─────────┬───────┤
        │Year│Host     │Country│
        ├────┼─────────┼───────┤
        │1952│Helsinki │Finland│
        ├────┼─────────┼───────┤
        │1956│Stockholm│Sweden │
        ├────┼─────────┼───────┤
        │1960│Rome     │Italy  │
        ╰────┴─────────┴───────╯

        """
        let expected_rounded_no_columns =
        """
        ╭──────────────────────╮
        │   Summer Olympics    │
        ├────┬─────────┬───────┤
        │1952│Helsinki │Finland│
        ├────┼─────────┼───────┤
        │1956│Stockholm│Sweden │
        ├────┼─────────┼───────┤
        │1960│Rome     │Italy  │
        ╰────┴─────────┴───────╯

        """
        let expected_default =
        """
        +----------------------+
        |   Summer Olympics    |
        +----+---------+-------+
        |Year|Host     |Country|
        +----+---------+-------+
        |1952|Helsinki |Finland|
        +----+---------+-------+
        |1956|Stockholm|Sweden |
        +----+---------+-------+
        |1960|Rome     |Italy  |
        +----+---------+-------+
        
        """
        let expected_default_no_columns =
        """
        +----------------------+
        |   Summer Olympics    |
        +----+---------+-------+
        |1952|Helsinki |Finland|
        +----+---------+-------+
        |1956|Stockholm|Sweden |
        +----+---------+-------+
        |1960|Rome     |Italy  |
        +----+---------+-------+
        
        """
        do {
            let table = Tbl(Txt("Summer Olympics")) {

                Columns {
                    Col("Year", width: .auto)
                    Col("Host", width: .in(5...25), defaultWrapping: .word)
                    Col("Country")
                }

                Rows {
                    ["1952", "Helsinki", "Finland"]
                    ["1956", "Stockholm", "Sweden"]
                    ["1960", "Rome", "Italy"]
                }
            }
            XCTAssertEqual(table.render(style: .rounded), expected_rounded)
        }
        do {
            let table = Tbl("Summer Olympics") {

                Columns {
                    Col("Year", width: .auto)
                    Col("Host", width: .in(5...25), defaultWrapping: .word)
                    Col("Country")
                }
                
                Rows {
                    Row("1952", "Helsinki", "Finland")
                    Row("1956", "Stockholm", "Sweden")
                    Row("1960", "Rome", "Italy")
                }
            }
            XCTAssertEqual(table.render(style: .rounded), expected_rounded)
        }
        do {
            let table = Tbl("Summer Olympics") {

                Columns {
                    Col("Year", width: .auto)
                    Col("Host", width: .in(5...25), defaultWrapping: .word)
                    Col("Country")
                }

                Rows {
                    [
                        [Txt("1952"), Txt("Helsinki"), Txt("Finland")],
                        [Txt("1956"), Txt("Stockholm"), Txt("Sweden")],
                        [Txt("1960"), Txt("Rome"), Txt("Italy")]
                    ]
                }
            }
            XCTAssertEqual(table.render(style: .rounded), expected_rounded)
        }
        do {
            let table = Tbl("Summer Olympics") {

                Columns {
                    Col("Year", width: .auto)
                    Col("Host", width: .in(5...25), defaultWrapping: .word)
                    Col("Country")
                }

                Rows {
                    ["1952", "Helsinki", "Finland"]
                    ["1956", "Stockholm", "Sweden"]
                    ["1960", "Rome", "Italy"]
                }
            }
            XCTAssertEqual(table.render(), expected_default)
        }
        do {
            let table = Tbl("Summer Olympics") {

                Columns {
                    Col("Year", width: .auto)
                    Col("Host", width: .in(5...25), defaultWrapping: .word)
                    Col("Country")
                }

                Rows {
                    ["1952", "Helsinki", "Finland"]
                    ["1956", "Stockholm", "Sweden"]
                    ["1960", "Rome", "Italy"]
                }
            }
            XCTAssertEqual(table.render(style: .rounded), expected_rounded)
        }
        do {
            let table = Tbl("Summer Olympics") {

                Columns {
                    Col("Year", width: .auto)
                    Col("Host", width: .in(5...25), defaultWrapping: .word)
                    Col("Country")
                }

                Rows {
                    ["1952", "Helsinki", "Finland"]
                    ["1956", "Stockholm", "Sweden"]
                    ["1960", "Rome", "Italy"]
                }
            }
            XCTAssertEqual(table.render(), expected_default)
        }
        do {
            let table = Tbl("Summer Olympics") {

                Rows {
                    ["1952", "Helsinki", "Finland"]
                    ["1956", "Stockholm", "Sweden"]
                    ["1960", "Rome", "Italy"]
                }
            }
            XCTAssertEqual(table.render(), expected_default_no_columns)
        }
        do {
            let table = Tbl("Summer Olympics") {

                Rows {
                    [
                        [Txt("1952"), Txt("Helsinki"), Txt("Finland")],
                        [Txt("1956"), Txt("Stockholm"), Txt("Sweden")],
                        [Txt("1960"), Txt("Rome"), Txt("Italy")]
                    ]
                }
            }
            XCTAssertEqual(table.render(style: .rounded), expected_rounded_no_columns)
        }
        do {
            let table = Tbl("Summer Olympics") {

                Rows {
                    [
                        [Txt("1952"), Txt("Helsinki"), Txt("Finland")],
                        [Txt("1956"), Txt("Stockholm"), Txt("Sweden")],
                        [Txt("1960"), Txt("Rome"), Txt("Italy")]
                    ]
                }
            }
            XCTAssertEqual(table.render(style: .rounded), expected_rounded_no_columns)
        }
        do {
            let table = Tbl("Summer Olympics") {

                Rows {
                    [
                        [Txt("1952"), Txt("Helsinki"), Txt("Finland")],
                        [Txt("1956"), Txt("Stockholm"), Txt("Sweden")],
                        [Txt("1960"), Txt("Rome"), Txt("Italy")]
                    ]
                }
            }
            XCTAssertEqual(table.render(), expected_default_no_columns)
        }
        do {
            let table = Tbl(nil) {
                Rows {
                    [
                        [Txt("1952"), Txt("Helsinki"), Txt("Finland")],
                        [Txt("1956"), Txt("Stockholm"), Txt("Sweden")],
                        [Txt("1960"), Txt("Rome"), Txt("Italy")]
                    ]
                }
            }
            XCTAssertEqual(table.render(style: .squared),
                            """
                            ┌────┬─────────┬───────┐
                            │1952│Helsinki │Finland│
                            ├────┼─────────┼───────┤
                            │1956│Stockholm│Sweden │
                            ├────┼─────────┼───────┤
                            │1960│Rome     │Italy  │
                            └────┴─────────┴───────┘

                            """)
        }
        do {
            let table = Tbl(nil) {
                
                Columns {
                    Col("Year", width: .auto)
                    Col("Host", width: .in(5...25), defaultWrapping: .word)
                    Col("Country")
                }
                Rows {
                    Array<[Txt]>()
                }
            }
            XCTAssertEqual(table.render(style: .squared),
                            """
                            ┌────┬─────┬───────┐
                            │Year│Host │Country│
                            ├────┼─────┼───────┤
                            └────┴─────┴───────┘

                            """)
        }
    }
}
final class StringExtensionTests : XCTestCase {
    /*
    func test_halign() {
        XCTAssertEqual("#".halign(.bottomRight, width: 3), "  #")
        XCTAssertEqual("#".halign(.topLeft, width: 3), "#  ")
        XCTAssertEqual("#".halign(.middleCenter, width: 3), " # ")
        XCTAssertEqual("abcd".halign(.middleCenter, width: 3), "abc")
    }*/
    func test_trim() {
        do {
            let head = "  \n\n"
            let body = "abc  \n\n xyz"
            let tail = "  \n\n"
            let s = head + body + tail
            
            // Test for correctness
            for i in 0..<64 {
                let o = TrimmingOptions(rawValue: i)
                let expected_head:String = {
                    switch TrimmingOptions(rawValue: o.rawValue & 3) {
                    case [.leadingWhiteSpaces]: return "\n\n"
                    case [.leadingNewlines]: return "  "
                    case [.leadingWhiteSpaces, .leadingNewlines]: return ""
                    default: return head
                    }
                }()
                let expected_body:String = {
                    switch TrimmingOptions(rawValue: o.rawValue & 12) {
                    case [.inlineConsecutiveWhiteSpaces]: return "abc \n\n xyz"
                    case [.inlineConsecutiveNewlines]: return "abc  \n xyz"
                    case [.inlineConsecutiveWhiteSpaces, .inlineConsecutiveNewlines]: return "abc \n xyz"
                    default: return body
                    }
                }()
                let expected_tail:String = {
                    switch TrimmingOptions(rawValue: o.rawValue & 48) {
                    case [.trailingWhiteSpaces]: return "\n\n"
                    case [.trailingNewlines]: return "  "
                    case [.trailingWhiteSpaces, .trailingNewlines]: return ""
                    default: return tail
                    }
                }()
                XCTAssertEqual(s.trim(o), expected_head + expected_body + expected_tail)
            }

            // Get a feel of the performance
            /*
             let t0 = DispatchTime.now().uptimeNanoseconds
             for _ in 0..<10_000 {
             for i in 0..<64 {
             let p = s.trim(String.TrimmingOptions(rawValue: i))
             }
             }
             let t1 = DispatchTime.now().uptimeNanoseconds
             print(t1 - t0)
             // DEBUG  : 1837715667 ns
             // RELEASE:  450813791 ns <- ~4x faster than DEBUG (~700 ns / invocation)
             */

            XCTAssertEqual("".trim([
                .leadingNewlines, .leadingWhiteSpaces, .inlineConsecutiveNewlines,
                .inlineConsecutiveWhiteSpaces, .trailingNewlines, .trailingWhiteSpaces]),
                           "")

            XCTAssertEqual(" ".trim([
                .leadingNewlines, .inlineConsecutiveNewlines,
                .inlineConsecutiveWhiteSpaces, .trailingNewlines]),
                           " ")

            XCTAssertEqual("  \n a  \n\nx  \n ".trim(.all), "a \nx")
        }
        do {
            let s = " \n\n Quick\nbrown  fox\n\njumped over the lazy dog.  \n "
            let opts = [
                TrimmingOptions(rawValue: 0),
                [.leadingWhiteSpaces],
                [.trailingWhiteSpaces],
                [.leadingWhiteSpaces, .trailingWhiteSpaces],
                [.inlineConsecutiveWhiteSpaces],
                [.inlineConsecutiveNewlines],
                [.inlineConsecutiveWhiteSpaces, .inlineConsecutiveNewlines],
                [.leadingNewlines],
                [.trailingNewlines],
                [.all]
            ]
            let expected = [
                " \n\n Quick\nbrown  fox\n\njumped over the lazy dog.  \n ",
                "\n\nQuick\nbrown  fox\n\njumped over the lazy dog.  \n ",
                " \n\n Quick\nbrown  fox\n\njumped over the lazy dog.\n",
                "\n\nQuick\nbrown  fox\n\njumped over the lazy dog.\n",
                " \n\n Quick\nbrown fox\n\njumped over the lazy dog.  \n ",
                " \n\n Quick\nbrown  fox\njumped over the lazy dog.  \n ",
                " \n\n Quick\nbrown fox\njumped over the lazy dog.  \n ",
                "  Quick\nbrown  fox\n\njumped over the lazy dog.  \n ",
                " \n\n Quick\nbrown  fox\n\njumped over the lazy dog.   ",
                "Quick\nbrown fox\njumped over the lazy dog.",
            ]
            for (o,e) in zip(opts,expected) {
                let t:String = s.trim(o)
                XCTAssertEqual(t, e)
            }
        }
    }
    func test_String_trim_and_frag() {
        let s = " \n\n Quick\nbrown  fox\n\njumped over the lazy dog.  \n "
        let opts = [
            TrimmingOptions(rawValue: 0),
            [.leadingWhiteSpaces],
            [.trailingWhiteSpaces],
            [.leadingWhiteSpaces, .trailingWhiteSpaces],
            [.inlineConsecutiveWhiteSpaces],
            [.inlineConsecutiveNewlines],
            [.inlineConsecutiveWhiteSpaces, .inlineConsecutiveNewlines],
            [.leadingNewlines],
            [.trailingNewlines],
            [.all]
        ]
        let expected = [
            [" ", "", " Quick", "brown  fox", "", "jumped over the lazy dog.  ", " "],
            ["", "", "Quick", "brown  fox", "", "jumped over the lazy dog.  ", " "],
            [" ", "", " Quick", "brown  fox", "", "jumped over the lazy dog.", ""],
            ["", "", "Quick", "brown  fox", "", "jumped over the lazy dog.", ""],
            [" ", "", " Quick", "brown fox", "", "jumped over the lazy dog.  ", " "],
            [" ", "", " Quick", "brown  fox", "jumped over the lazy dog.  ", " "],
            [" ", "", " Quick", "brown fox", "jumped over the lazy dog.  ", " "],
            ["  Quick", "brown  fox", "", "jumped over the lazy dog.  ", " "],
            [" ", "", " Quick", "brown  fox", "", "jumped over the lazy dog.   "],
            ["Quick", "brown fox", "jumped over the lazy dog."],
        ]
        for (o,e) in zip(opts,expected) {
            let t:[String] = s.trimAndFrag(o)
            print("\(s, visibleWhitespaces: true, quoted: true),")
            print("\(t)")
            XCTAssertEqual(t, e)
        }
    }
    func test_trim_doc() {
        let data:[(String, TrimmingOptions, String)] = [
            (" abc\n", .leadingWhiteSpaces, "abc\n"),
            ("\n \nabc\n", .leadingNewlines, " abc\n"),
            ("a b  c", .inlineConsecutiveWhiteSpaces, "a b c"),
            (" a\n\nbc\n", .inlineConsecutiveNewlines, " a\nbc\n"),
            (" abc  ", .trailingWhiteSpaces, " abc"),
            (" abc\n ", .trailingNewlines, " abc "),
            ("  \n\na  b\n\nc\n ", .all, "a b\nc"),
        ]
        for (l,o,r) in data {
            XCTAssertEqual(l.trim(o), r)
            let ll = l
                .replacingOccurrences(of: "\n", with: "\\n")
            let rr = r
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
                .replacingOccurrences(of: "\n", with: "\\n")
            let oo = o.description
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
                .split(separator: "|")
                .map({ ".\($0)" })
            //.joined(separator: ",")
            print("\"\(ll)\".trim(\(oo.count > 1 ? "[\(oo.joined(separator: ", "))]" : oo.first!)) // \"\(rr)\"")
        }
    }
}
final class TxtExtensionTests : XCTestCase {
    let pangram = "The quick brown fox jumps over the lazy dog"

    func test_halign() {
        XCTAssertEqual(
            Txt("#")
                .halign(
                    defaultAlignment: .bottomRight,
                    defaultWrapping: .char,
                    width: 3
                ),
            ["  #"]
        )

        XCTAssertEqual(
            Txt("#")
                .halign(
                    defaultAlignment: .topLeft,
                    defaultWrapping: .char,
                    width: 3
                ),
            ["#  "]
        )

        XCTAssertEqual(
            Txt("#")
                .halign(
                    defaultAlignment: .middleCenter,
                    defaultWrapping: .char,
                    width: 3
                ),
            [" # "]
        )

        XCTAssertEqual(
            Txt("abcd")
                .halign(
                    defaultAlignment: .middleCenter,
                    defaultWrapping: .char,
                    width: 3
                ),
            ["abc", " d "]
        )

        XCTAssertEqual(
            Txt("abcd")
                .halign(
                    defaultAlignment: .bottomLeft,
                    defaultWrapping: .char,
                    width: 3
                ),
            ["abc", "d  "]
        )

        XCTAssertEqual(
            Txt("abcd")
                .halign(
                    defaultAlignment: .topRight,
                    defaultWrapping: .char,
                    width: 3
                ),
            ["abc", "  d"]
        )
    }
}
internal class ArrayExtensionTests : XCTestCase {
    func test_valign() {
        let pangram = "The quick brown fox jumps over the lazy dog"

        // Follows the defaultAlignment as Txt itself
        // doesn't have alignment set.
        do {
            let a:Alignment = .topRight
            XCTAssertEqual(
                Txt(pangram)
                    .halign(defaultAlignment: a, defaultWrapping: .char, width: 5)
                    .valign(a),
                ["The q", "uick ", "brown", " fox ",
                 "jumps", " over", " the ", "lazy ",
                 "  dog"]
            )
        }
        // Follows the defaultAlignment as Txt itself
        // doesn't have alignment set.
        do {
            let a:Alignment = .topRight
            XCTAssertEqual(
                Txt(pangram)
                    .halign(defaultAlignment: a, defaultWrapping: .char, width: 5)
                    .valign(a, height: 10),
                ["The q", "uick ", "brown", " fox ",
                 "jumps", " over", " the ", "lazy ",
                 "  dog", "     "]
            )
        }
        do {
            let a:Alignment = .topLeft
            XCTAssertEqual(
                // Follows the Txt's alignment
                Txt(pangram, alignment: .middleCenter, wrapping: .char)
                    .halign(defaultAlignment: a, defaultWrapping: .char, width: 5)
                    .valign(a),
                ["The q", "uick ", "brown", " fox ",
                 "jumps", " over", " the ", "lazy ",
                 " dog "]
            )
        }
    }
}
internal class Playground : XCTestCase {
    func test_renx() {
        let columns = [
            Col(Txt("#", alignment: .bottomCenter)),
            Col(Txt("Tight"), width: .in(4...6),
                defaultAlignment: .middleCenter,
                defaultWrapping: .word,
                trimming: .all,
                contentHint: .unique),
            Col(Txt("Wide"), width: .in(8...12),
                defaultAlignment: .bottomRight,
                defaultWrapping: .word,
                trimming: [.leadingWhiteSpaces, .trailingWhiteSpaces],
                contentHint: .unique)
        ]
        let cells:[[Txt]] = [
            ["Quick brown fox jumped over the lazy dog.",
             "  Quick brown fox\njumped over the lazy dog.  "],
            [],
            [" \n Quick brown fox\n\njumped over the lazy dog. \n",
             "Quick brown fox jumped over the lazy dog."],
            ["EOF", "End Of File"],
        ]
        let mask = DebugTopicSet([.all])

        let t = Tbl("Quick brown title jumped over the lazy columns.",
                    columns: columns,
                    cells: cells,
                    lineNumberGenerator: Table.defaultLnGen
        )
        t.debugMask = mask
        print(t.render(style: .roundedPadded, rows: [(0..<1), (2..<4)]))
    }
    func test_cache() {
        let cells:[[Txt]] = [
            [Txt(pangram), Txt(pangram)],
            [Txt(pangram), Txt([pangram, pangram].joined(separator: "\n"))],
            [Txt(pangram), Txt(pangram)],
            [Txt(pangram), Txt(pangram)],
        ]
        let cols = [
            Col(),
            Col(width: .min(10), defaultAlignment: .bottomLeft, defaultWrapping: .word),
            Col(width: .max(10), defaultAlignment: .bottomLeft, defaultWrapping: .word),
        ]
        let tbl = Tbl(#function, columns: cols, cells: cells, lineNumberGenerator: defaultLnGen)
        tbl.debugMask = [.cache]
        print(tbl.render(style: .roundedPadded))
    }
}
final class FramingOptionsTests : XCTestCase {
    func test_optionsInEffect() {
        XCTAssertEqual(FramingOptions.all.optionsInEffect,
                       "topFrame, bottomFrame, leftFrame, rightFrame, insideHorizontalFrame, insideVerticalFrame")
        XCTAssertEqual(FramingOptions.none.optionsInEffect, "")
        XCTAssertEqual(FramingOptions.inside.optionsInEffect,
                       "insideHorizontalFrame, insideVerticalFrame")
        XCTAssertEqual(FramingOptions.outside.optionsInEffect,
                       "topFrame, bottomFrame, leftFrame, rightFrame")
        XCTAssertEqual(FramingOptions.all.rawValue, 63)
    }
    func test_FrameElement() {
        let expected:[(Int,String)] = [
            (0, "topFrame"),
            (1, "bottomFrame"),
            (2, "leftFrame"),
            (3, "rightFrame"),
            (4, "insideHorizontalFrame"),
            (5, "insideVerticalFrame"),
        ]
        XCTAssertEqual(expected.count, FramingOptions.FrameElement.allCases.count)
        for (e,i) in zip(expected, FramingOptions.FrameElement.allCases) {
            XCTAssertEqual(i.index, e.0)
            XCTAssertEqual(i.rawValue, e.1)
        }
    }
}
#if canImport(ArgumentParser)
import ArgumentParser
//extension FramingOptions : ExpressibleByArgument {
//    public init?(argument: String) {
//        return nil
//    }
//}
import ArgumentParser
extension FramingOptions.FrameElement : ExpressibleByArgument {}

extension FramingOptionsTests {
    func test_args() {
        struct ArgModel : ParsableCommand {
            @Option(name: .customShort("f"),
                    parsing: ArrayParsingStrategy.upToNextOption,
                    help: ArgumentHelp(stringLiteral: "Framing options."))
            var opts:[FramingOptions.FrameElement]
            @Flag(help: "Be verbose") var verbose:Bool = false
            func run() throws {
                let optValue = opts.reduce(0, { $0 | (1 << $1.index) })
                let framingOptions:FramingOptions = FramingOptions(rawValue: optValue)
                let expected:[FramingOptions.FrameElement] = [.topFrame, .bottomFrame]
                XCTAssertEqual(opts, expected)
                XCTAssertEqual(framingOptions, FramingOptions(expected))
            }
        }
        ArgModel.main(["-f", "topFrame", "bottomFrame", "--verbose"])
        ArgModel.main(["--verbose", "-f", "topFrame", "bottomFrame"])
        ArgModel.main(["-f", "topFrame", "--verbose", "-f", "bottomFrame"])
    }
}
#endif
