import XCTest
import Table

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
}
final class ColTests: XCTestCase {
    func test_init() {
        do {
            let str = "Column X"
            let col = Col(str)
            XCTAssertEqual(col.defaultAlignment, .topLeft)
            XCTAssertEqual(col.contentHint, .repetitive)
            XCTAssertEqual(col.header, Txt(str))
            XCTAssertEqual(col.width, .auto)
            XCTAssertEqual(col.defaultWrapping, .char)
        }
        do {
            let str = "Column X"
            for width in [Width.auto, .hidden, .value(42), .min(6), .max(3), .in(3...6), .range(5..<10)] {
                for ca in Alignment.allCases {
                    for wrapping in Wrapping.allCases {
                        for ch in [ColumnContentHint.repetitive, .unique] {
                            let col = Col(Txt(str), width: width, defaultAlignment: ca, defaultWrapping: wrapping, contentHint: ch)
                            XCTAssertEqual(col.defaultAlignment, ca)
                            XCTAssertEqual(col.contentHint, ch)
                            XCTAssertEqual(col.header, Txt(str))
                            XCTAssertEqual(col.width, width)
                            XCTAssertEqual(col.defaultWrapping, wrapping)
                        }
                    }
                }
            }
        }
    }
}
final class AlignmentTests: XCTestCase {
//    func test_Default() {
//        XCTAssertEqual(Alignment.default, Alignment.topLeft)
//        for c in Alignment.allCases.dropFirst() {
//            XCTAssertFalse(Alignment.default == c)
//        }
//    }
    func test_Codable() {
        do {
            for target in Alignment.allCases /*+ [.default]*/ {
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
final class TableTests: XCTestCase {
    let pangram = "Quick brown fox jumps over the lazy dog"
    func test_noData() {
        var data:[[Txt]] = []
        let columns = [
            Col("Col 1", width: 1, defaultAlignment: .topLeft),
            Col("Col 2", width: 2, defaultAlignment: .topLeft),
            Col(Txt("Col 3"), width: 3, defaultAlignment: .topLeft),
        ]
        
        do {
            let table = Tbl("Title", columns: columns, cells: data)
            XCTAssertEqual(table.render(style: .rounded).string,
                           """
                           ╭────────╮
                           │ Title  │
                           ├─┬──┬───┤
                           │C│Co│Col│
                           │o│l │3  │
                           │l│2 │   │
                           │1│  │   │
                           ├─┼──┼───┤
                           ╰─┴──┴───╯
                           
                           """)
        }
        do {
            data = [[]]
            let table = Tbl("Title", columns: columns, cells: data)
            XCTAssertEqual(table.render(style: .rounded),
                           """
                           ╭────────╮
                           │ Title  │
                           ├─┬──┬───┤
                           │C│Co│Col│
                           │o│l │3  │
                           │l│2 │   │
                           │1│  │   │
                           ├─┼──┼───┤
                           ╰─┴──┴───╯
                           
                           """)
        }
        do {
            data = []
            let table = Tbl(nil, columns: columns, cells: data)
            XCTAssertEqual(table.render(style: .rounded),
                           """
                           ╭─┬──┬───╮
                           │C│Co│Col│
                           │o│l │3  │
                           │l│2 │   │
                           │1│  │   │
                           ├─┼──┼───┤
                           ╰─┴──┴───╯

                           """)
        }
        do {
            data = [[]]
            let table = Tbl(nil, columns: columns, cells: data)
            XCTAssertEqual(table.render(style: .rounded),
                           """
                           ╭─┬──┬───╮
                           │C│Co│Col│
                           │o│l │3  │
                           │l│2 │   │
                           │1│  │   │
                           ├─┼──┼───┤
                           ╰─┴──┴───╯

                           """)
        }
        do {
            let table = Tbl(nil, columns: [], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           ++
                           ++
                           
                           """
            )
        }
        do {
            let table = Tbl(columns: [], cells: data)
            XCTAssertEqual(table.render(options: .none),
                           """
                           
                           """
            )
        }
        do {
            let table = Tbl("Title", columns: [], cells: data)
            XCTAssertEqual(table.render(style: .roundedPadded),
                           """
                           ╭──╮
                           │  │
                           ├──┤
                           ╰──╯
                           
                           """)
        }
        do {
            let expected:[String] = [
                """
                ┌┐
                └┘

                """,
                """
                ┌┐
                └┘
                
                """,
                """
                ┌┬┐
                └┴┘
                
                """,
                """
                ┌┬┬┐
                └┴┴┘
                
                """,
            ]
            for i in 0...3 {
                let columns = Array(repeating: Col(width: .value(0)), count: i)
                let table = Tbl(columns: columns, cells: [[]])
                XCTAssertEqual(table.render(style: .squared), expected[i])
            }
        }
        do {
            let expected:[String] = [
                """
                ┌┐
                └┘

                """,
                """
                ┌┐
                ││
                ├┤
                └┘
                
                """,
                """
                ┌┬┐
                │││
                ├┼┤
                └┴┘
                
                """,
                """
                ┌┬┬┐
                ││││
                ├┼┼┤
                └┴┴┘
                
                """,
            ]
            for i in 0...3 {
                let columns = Array(repeating: Col("#", width: .value(0)), count: i)
                let table = Tbl(columns: columns, cells: [[]])
                XCTAssertEqual(table.render(style: .squared), expected[i])
            }
        }
        do {
            let table = Tbl("Title", columns: ["#", "#", "#", "#"], cells: [])
            XCTAssertEqual(table
                .render(style: .rounded, options: .all),
                           """
                           ╭───╮
                           │Tit│
                           │le │
                           ├┬┬┬┤
                           │││││
                           ├┼┼┼┤
                           ╰┴┴┴╯

                           """)
        }
        do {
            let src:[[Txt]] = []
            let columns = [
                Col("Hash", width: .min(1), defaultAlignment: .bottomLeft, defaultWrapping: .word, contentHint: .unique),
                Col("Value", width: .auto, defaultAlignment: .bottomRight, defaultWrapping: .word, contentHint: .unique),
                Col("Unit", width: .auto, defaultAlignment: .bottomLeft, defaultWrapping: .word, contentHint: .unique),
            ]
            
            let table = Tbl("title", columns: columns, cells: src)
            XCTAssertEqual(table
                .render(style: .roundedPadded, options: .all),
                           """
                           ╭─────────╮
                           │  title  │
                           ├───┬──┬──┤
                           │ H │  │  │
                           │ a │  │  │
                           │ s │  │  │
                           │ h │  │  │
                           ├───┼──┼──┤
                           ╰───┴──┴──╯
                           
                           """
            )
        }

    }
    func test_autoColumns() {
        
        do {
            let table = Tbl("Title", columns: [], cells: [])
            XCTAssertEqual(table.render(),
                           """
                           ++
                           ||
                           ++
                           ++

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
                           +-------+----+
                           |C      |D   |
                           +-------+----+
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
                           +-------+----++
                           |C      |D   ||
                           +-------+----++
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
    func test_doNotShowDataInExcessColumns() {
        do {
            // Ignore "excess" data elements which don't
            // have column defined.
            // Example: Define just two columns while
            // data contains elements for three.
            // In the test below, "###" must not be shown
            let data:[[Txt]] = [["#", "##", "###"]]
            let columns = [Col("Col1", width: 4), Col("Col2", width: 4, defaultAlignment: .topRight)]
            let table = Tbl(columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +----+----+
                           |Col1|Col2|
                           +----+----+
                           |#   |  ##|
                           +----+----+

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
                           |Quick brown |
                           |fox jumps ov|
                           |er the lazy |
                           |dog         |
                           +------------+

                           """)
        }
        do {
            // Wrpping taken from Txt
            let data = [[Txt(pangram, wrapping: .char)]]
            let table = Tbl(columns: [Col(width: 12)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |Quick brown |
                           |fox jumps ov|
                           |er the lazy |
                           |dog         |
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
                           |Quick brown |
                           |fox jumps ov|
                           |er the lazy |
                           |dog         |
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
                           |Quick …y dog|
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
                           |Quick …y dog|
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
                           |Quick …y dog|
                           +------------+

                           """)
        }
        do {
            // Special case - column width = 1
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
            // Special case - column width = 2
            let data = [[Txt(pangram)]]
            let table = Tbl(columns: [Col(width: 2, defaultWrapping: .cut)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +--+
                           |Q…|
                           +--+

                           """)
        }
        do {
            // Special case - column width = 3
            let data = [[Txt(pangram)]]
            let table = Tbl(columns: [Col(width: 3, defaultWrapping: .cut)], cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +---+
                           |Q…g|
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
                           |Quick       |
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
                           |Quick brown     |
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
                           |Quick|
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
                           |",       |
                           |width: 5,|
                           |symbol:  |
                           |$dir!,   |
                           |fieldNumb|
                           |er: 253, |
                           |value:   |
                           |[1,      |
                           |2, 3])   |
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
                    Col("D-zero", width: .value(0)),
                    Col("E"),
                    Col("F-zero", width: .value(0)),
                ]
                let cells:[[Txt]] = [["1", "hidden", "2", "zero width", "3"],["4", "hidden", "5", "zero width", "end", "f"]]
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
                           |Quick brown fox |
                           |jumps over the l|
                           |azy dog         |
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
                           |   pangram —    |
                           |a sentence that |
                           |  contains all  |
                           | of the letters |
                           | of the English |
                           |   alphabet.    |
                           +----------------+
                           |Quick brown fox |
                           |jumps over the l|
                           |azy dog         |
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
                           |Quick brown fox |
                           |jumps over the l|
                           |azy dog         |
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
                           |Quick brown fox |
                           |jumps over the l|
                           |azy dog         |
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
                           |Quick brown fox |
                           |jumps over the l|
                           |azy dog         |
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
                           |Quick brown fox |
                           |jumps over the l|
                           |azy dog         |
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
                let table = Tbl(columns: columns, cells: [[]])
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
                           ┌┐
                           ││
                           ├┤
                           └┘
                           
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
            let table = Tbl("*", columns: [],
                            strings: [["1", "2", "3"],["4", "5"]])
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
    }
    func test_columnMin() {
        do {
            let data:[[Txt]] = [["#", "##", "#########"], ["###", "##", "#"]]
            let columns = [Col("Col1", width: .min(4)), Col("Col2", width: .min(3)), Col("Col3", width: .min(2))]
            let table = Tbl("title",columns: columns, cells: data)
            XCTAssertEqual(table.render(),
                           """
                           +-----------+
                           |   title   |
                           +----+---+--+
                           |Col1|Col|Co|
                           |    |2  |l3|
                           +----+---+--+
                           |#   |## |##|
                           |    |   |##|
                           |    |   |##|
                           |    |   |##|
                           |    |   |# |
                           +----+---+--+
                           |### |## |# |
                           +----+---+--+
                           
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
                           |    With    |
                           |title longer|
                           |than columns|
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
                           Col("Col3", width: .value(0)), // == 0
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
            let cells:[[String]] = [
                ["a", "b", "c"],
                ["d", "e"],
                ["f"]
            ]
            let cols = [
                Col("A"),
                Col("B", width: .value(0)),
                Col("C"),
                Col("D"),
            ]
            let t = Tbl("Table Title",
                        columns: cols,
                        strings: cells)
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
            let cells:[[String]] = [
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
                        strings: cells)
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
                                   width: Width.value(42),
                                   defaultAlignment: .topLeft,
                                   defaultWrapping: .char,
                                   contentHint: .repetitive)
            XCTAssertEqual(test, expected)
        }
    }
    func test_Tricky() {
        do {
            let cells:[[String]] = [
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
                        strings: cells)
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
                [Txt("Abc"), Txt("What?")],
                [Txt("Automatic\ncolumn\nwidth with proper\nnewline handling"), Txt("Quick brown fox")]
            ]
            let columns = [
                Col(Txt("Auto column", alignment: .bottomCenter),
                    defaultAlignment: .topLeft, defaultWrapping: .cut),
                Col("Fixed column", width: .value(10),
                    defaultAlignment: .middleCenter, defaultWrapping: .word),
            ]
            let table = Tbl(Txt("Title\n-*-\nwith newlines"),
                            columns: columns,
                            cells: cells)
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
                           |      over      |
                           |  the lazy dog  |
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
                           |over the…azy dog|
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
                           |over the…azy dog|
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
        do {
            func gendata(_ cc:Int, _ rc:Int, _ seed:String) -> [[Txt]] {
                var data:[[Txt]] = []
                for _ in 0..<rc {
                    var row:[Txt] = []
                    for _ in 0..<cc {
                        let s = (0...(6...20).randomElement()!)
                            .map({ _ in seed.randomElement()! })
                            .map({ String($0) })
                            .joined()
                        row.append(Txt(s))
                    }
                    data.append(row)
                }
                return data
            }
            let cc = (2...6).randomElement()!
            let rc = 5_000
            // Cell data with newlines
            let withNewLines = gendata(cc, rc, "abcdefg\n")
            let noNewLines = withNewLines
                .map({
                    $0.map({
                        Txt($0.string.replacingOccurrences(of: "\n", with: ""))
                    })
                })

            // Define all auto column widths
            let autocol = Array(repeating: Col("Column", width: .auto),
                                count: cc)

            // cellsMayHaveNewlines optimization promise is:
            // for data without newlines & with one or more
            // autocolumns setting cellsMayHaveNewlines to
            // false IS faster than leaving it to true
            //let r = 0..<3
            let o1:UInt64
            let o2:UInt64
            let o3:UInt64
            let o4:UInt64
            do {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let tbl = Tbl("noNewLines / false", columns: autocol, cells: noNewLines)
                tbl.cellsMayHaveNewlines = false
                let _ = tbl.render()
                let t1 = DispatchTime.now().uptimeNanoseconds
                //print(tbl.render(rows: r))
                o1 = (t1 - t0) / 1_000_000
            }
            do {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let tbl = Tbl("noNewLines / true", columns: autocol, cells: noNewLines)
                tbl.cellsMayHaveNewlines = true
                let _ = tbl.render()
                let t1 = DispatchTime.now().uptimeNanoseconds
                //print(tbl.render(rows: r))
                o2 = (t1 - t0) / 1_000_000
            }
            do {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let tbl = Tbl("withNewLines / false", columns: autocol, cells: withNewLines)
                tbl.cellsMayHaveNewlines = false
                let _ = tbl.render()
                let t1 = DispatchTime.now().uptimeNanoseconds
                //print(tbl.render(rows: r))
                o3 = (t1 - t0) / 1_000_000
            }
            do {
                let t0 = DispatchTime.now().uptimeNanoseconds
                let tbl = Tbl("withNewLines / true", columns: autocol, cells: withNewLines)
                tbl.cellsMayHaveNewlines = true
                let _ = tbl.render()
                let t1 = DispatchTime.now().uptimeNanoseconds
                //print(tbl.render(rows: r))
                o4 = (t1 - t0) / 1_000_000
            }

            XCTAssertEqual([o1, o2, o3, o4], [o1, o2, o3, o4].sorted())
        }
    }
    func test_renderRange() {
        var src:[[String]] = []
        for i in 0..<3 {
            var row:[String] = []
            for j in 0..<3 {
                row.append("r\(i)c\(j)")
            }
            src.append(row)
        }
        let columns = "ABC".map({ Col(String($0)) })
        let tbl = Tbl("Title", columns: columns, strings: src)
        do {
            var s:TextOutputStream = ""
            tbl.render(style: .squared, rows: [0..<1], to: &s)
            XCTAssertEqual(s as! String,
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │A   │B   │C   │
                           ├────┼────┼────┤
                           │r0c0│r0c1│r0c2│
                           └────┴────┴────┘
                           
                           """
            )
        }
        do {
            var s:TextOutputStream = ""
            tbl.render(style: .squared, rows: 0..<2, to: &s)
            XCTAssertEqual(s as! String,
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │A   │B   │C   │
                           ├────┼────┼────┤
                           │r0c0│r0c1│r0c2│
                           ├────┼────┼────┤
                           │r1c0│r1c1│r1c2│
                           └────┴────┴────┘
                           
                           """
            )
        }
        do {
            var s:TextOutputStream = ""
            tbl.render(style: .squared, rows: 1..<2, to: &s)
            XCTAssertEqual(s as! String,
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │A   │B   │C   │
                           ├────┼────┼────┤
                           │r1c0│r1c1│r1c2│
                           └────┴────┴────┘
                           
                           """
            )
        }
        do {
            var s:TextOutputStream = ""
            tbl.render(style: .squared, rows: 2..<3, to: &s)
            XCTAssertEqual(s as! String,
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │A   │B   │C   │
                           ├────┼────┼────┤
                           │r2c0│r2c1│r2c2│
                           └────┴────┴────┘
                           
                           """
            )
        }
        do {
            var s:TextOutputStream = ""
            tbl.render(style: .squared, rows: 2..<2, to: &s)
            XCTAssertEqual(s as! String,
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │A   │B   │C   │
                           ├────┼────┼────┤
                           └────┴────┴────┘
                           
                           """
            )
        }
        do {
            // Corner case -> multiple 'empty' ranges given.
            var s:TextOutputStream = ""
            tbl.render(style: .squared, rows: [0..<0, 1..<1, 2..<2], to: &s)
            XCTAssertEqual(s as! String,
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │A   │B   │C   │
                           ├────┼────┼────┤
                           ├╌╌╌╌┼╌╌╌╌┼╌╌╌╌┤
                           ├╌╌╌╌┼╌╌╌╌┼╌╌╌╌┤
                           └────┴────┴────┘
                           
                           """
            )
        }
        do {
            XCTAssertEqual(tbl.render(frameStyle: .squared, rows: 0..<3),
                           """
                           ┌──────────────┐
                           │    Title     │
                           ├────┬────┬────┤
                           │A   │B   │C   │
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
                           │A   │B   │C   │
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
                           │A   │B   │C   │
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
                            cells: cells)
            table.lineNumberGenerator = { i in
                return Txt((i+1).description)
            }
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
                           | 1|Letter a|a|
                           +--+--------+-+
                           | 2|Letter b|b|
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
                            cells: cells)
            table.lineNumberGenerator = { i in
                return Txt((i+99).description)
            }

            // No custom line number formatter set, use default
            // which is just plain numbers, aligned .bottomRight
            
            XCTAssertEqual(table.render(rows: [0..<2, 24..<cells.count]),
                           """
                           +--------------+
                           |   Testing    |
                           |  automatic   |
                           | line numbers |
                           | for 26 rows  |
                           +---+--------+-+
                           | 99|Letter a|a|
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
            let table = Tbl(Txt("Testing automatic line numbers for \(cells.count) rows"),
                            cells: cells)
            table.lineNumberGenerator = { i in
                let f = NumberFormatter()
                f.numberStyle = .ordinal
                return Txt(f.string(for: i+99) ?? "?")
            }
            // Set formatter to NumberFormatter, with bit weird numbering style
            XCTAssertEqual(table.render(rows: [0..<2, 24..<cells.count]),
                           """
                           +----------------+
                           |    Testing     |
                           |   automatic    |
                           |  line numbers  |
                           |  for 26 rows   |
                           +-----+--------+-+
                           | 99th|Letter a|a|
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
            let table = Tbl(Txt("Hexdump", alignment: .bottomLeft), cells: cells)
            // Set formatter to NumberFormatter, with completely unexpected
            // numbering style. Automatic line numbering implementation assumes
            // that the required column width for the very last row number is
            // the widest column width required to present line numbers. For
            // most of the use cases this works well, but as this test demonstrates,
            // things can be weird and that assumption doesn't always hold true.
            // Because of this, automatic line number column wrapping is set
            // to '.cut' (to keep automatic line numbering vertical height at 1)
            table.lineNumberGenerator = { i in
                return Txt(String(format: "0x%08x:", i * step))
            }
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
            let table = Tbl(Txt("Override line number column alignment"), cells: cells)
            table.lineNumberGenerator = { i in
                // By default line numbers are aligned to bottom right
                // Let's override it
                return Txt((i*i).description,
                           alignment: .topLeft) // <- override is here
            }
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
    func test_encodingDecoding() throws {
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
            print(table.render())
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
}
final class WidthTests: XCTestCase {
    func test_init() {
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

            XCTAssertEqual(Width.value(i), 42)
            XCTAssertEqual(Width.value(i).value, i)
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
        }
    }
}
final class DSLTests: XCTestCase {
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
    }
}
final class TablePerformanceTests: XCTestCase {
    // MARK: -
    // MARK: Performance tests
    lazy var perfDataSource:[[Txt]] = {
        let src = [
            ["A blessing in disguise", "by itself"],
            ["A dime a dozen", "by itself"],
            ["Beat around the bush", "as part of the sentence"],
            ["Better late than never", "by itself"],
            ["Bite the bullet", "as part of the sentence"],
            ["Break a leg", "as part of the sentence"],
            ["Call it a day", "by itself"],
            ["Cutting corners", "by itself"],
            ["Easy does it"], // <- second column data missing intentionally
            ["Get out of hand", "by itself"],
            ["Get something out of your system", "by itself"],
            ["Get your act together", "as part of the sentence"],
            ["Give someone the benefit of the doubt", "as part of the sentence"],
            ["Go back to the drawing board", "as part of the sentence"],
            ["Hang in there", "by itself"],
            ["Hit the sack", "as part of the sentence"]
        ]
        var result:[[Txt]] = []
        for i in 0..<2000 {
            for (j,arr) in src.enumerated() {
                result.append(arr.map({ Txt("[\(i),\(j)]" + $0) }))
            }
        }
        return result
    }()
    // MacBook Pro (15-inch, 2016)
    // Processor 2,9 GHz Quad-Core Intel Core i7
    // Memory 16GB 2133 MHz LPDDR3
    // Radeon Pro 460 4GB, Intel HD Graphics 530 1536 MB
    // macOS Big Sur 11.5.2
    // Xcode version 12.5.1 (12E507)
    // Apple Swift version 5.4.2 (swiftlang-1205.0.28.2 clang-1205.0.19.57)
    func testPerformanceCharWrapping() {
        var data:[[Txt]] = []
        for _ in 0..<2 {
            data.append(contentsOf: perfDataSource)
        }

        let cols = [
            Col(width: 8, defaultAlignment: .topLeft, defaultWrapping: .char, contentHint: .unique),
            Col(width: 6, defaultAlignment: .topCenter, defaultWrapping: .char, contentHint: .repetitive),
        ]
        // Idicative performance metrics (of release build) with above setup:
        // average should be within the range of 0,630...0,650 seconds

        measure {
            // Tbl.init is intentionally included as part of the
            // work is done there.
            _ = Tbl("Title", columns: cols, cells: data).render()
        }
    }
    func testPerformanceCutWrapping() {
        var data:[[Txt]] = []
        for _ in 0..<2 {
            data.append(contentsOf: perfDataSource)
        }

        let cols = [
            Col(width: 8, defaultAlignment: .topLeft, defaultWrapping: .cut, contentHint: .unique),
            Col(width: 6, defaultAlignment: .topCenter, defaultWrapping: .cut, contentHint: .repetitive),
        ]
        // Idicative performance metrics (of release build) with above setup:
        // average should be within the range of 0,350...0,370 seconds

        measure {
            // Tbl.init is intentionally included as part of the
            // work is done there.
            _ = Tbl("Title", columns: cols, cells: data).render()
        }
    }
    func testPerformanceWordWrapping() {
        var data:[[Txt]] = []
        for _ in 0..<2 {
            data.append(contentsOf: perfDataSource)
        }

        let cols = [
            Col(width: 8, defaultAlignment: .topLeft, defaultWrapping: .word, contentHint: .unique),
            Col(width: 6, defaultAlignment: .topCenter, defaultWrapping: .word, contentHint: .repetitive),
        ]
        // Idicative performance metrics (of release build) with above setup:
        // average should be within the range of 1,750...1,850 seconds

        measure {
            // Tbl.init is intentionally included as part of the
            // work is done there.
            _ = Tbl("Title", columns: cols, cells: data).render()
        }
    }
    func testPerformance() {
        let cols = [
            Col(width: 8, defaultAlignment: .topLeft, defaultWrapping: .word, contentHint: .unique),
            Col(width: 6, defaultAlignment: .topCenter, defaultWrapping: .word, contentHint: .repetitive),
        ]
        var data:[[Txt]] = []
        for _ in 0..<5 {
            data.append(contentsOf: perfDataSource)
        }
        let t0 = DispatchTime.now().uptimeNanoseconds
        let tbl = Tbl("Title", columns: cols, cells: data)
        let t1 = DispatchTime.now().uptimeNanoseconds
        _ = tbl.render()
        let t2 = DispatchTime.now().uptimeNanoseconds
        let initialize_ms = (t1 - t0) / 1_000_000
        let render_ms = (t2 - t1) / 1_000_000

        let cells:[[Txt]] = [
            [Txt("init()"), Txt(initialize_ms.description)],
            [Txt("render()"), Txt(render_ms.description)]
        ]
        let columns = [Col("Method", defaultAlignment: .bottomLeft),
                       Col("ms", defaultAlignment: .bottomRight)]
        
        let t = Tbl("Performance\n\nTable with \(columns.count) columns and \(data.count) rows",
                    columns: columns, cells: cells)
        print(t.render(style: .roundedPadded))
    }
}
