import XCTest
import Table

final class TableTests: XCTestCase {
    let pangram = "Quick brown fox jumps over the lazy dog"
    func test_noData() {
        let data:[[Txt]] = []
        let columns = [
            Col("Col 1", width: 1, alignment: .topLeft),
            Col("Col 2", width: 2, alignment: .topLeft),
            Col(Txt("Col 3"), width: 3, alignment: .topLeft),
        ]
        do {
            let table = Tbl("Title", columns: columns, data: data)
            XCTAssertEqual(table.render(),
                           """
                           +--------+
                           | Title  |
                           +-+--+---+
                           |C|Co|Col|
                           |o|l |3  |
                           |l|2 |   |
                           |1|  |   |
                           +-+--+---+

                           """)
        }
        do {
            let table = Tbl(nil, columns: columns, data: data)
            XCTAssertEqual(table.render(),
                           """
                           +-+--+---+
                           |C|Co|Col|
                           |o|l |3  |
                           |l|2 |   |
                           |1|  |   |
                           +-+--+---+

                           """)
        }
        do {
            let table = Tbl(nil, columns: [], data: data)
            XCTAssertEqual(table.render(),
                           """
                           ++
                           ++

                           """)
        }
        do {
            let table = Tbl("Title", columns: [], data: data)
            XCTAssertEqual(table.render(),
                           """
                           +-----+
                           |Title|
                           +-----+

                           """)
        }
    }
    func test_autoColumns() {
        do {
            let table = Tbl("Title", columns: [], data: [])
            XCTAssertEqual(table.render(),
                           """
                           +-----+
                           |Title|
                           +-----+

                           """)
        }
        do {
            let data:[[Txt]] = [["#"]]
            let table = Tbl("Title", data: data)
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
            let table = Tbl("Title", data: data)
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
            let table = Tbl(data: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------------+
                           |Quick brown fox...|
                           +------------------+

                           """)
        }
        do {
            let data:[[Txt]] = [["Quick brown fox", "jumps over the lazy dog"]]
            let table = Tbl(data: data)
            XCTAssertEqual(table.render(),
                           """
                           +---------------+-----------------------+
                           |Quick brown fox|jumps over the lazy dog|
                           +---------------+-----------------------+

                           """)
        }
    }
    func test_autofillMissingDataCells() {
        do {
            let data:[[Txt]] = [["#"], ["#", "#"], ["#", "#", "#"]]
            let columns = [Col("Col1", width: 4),
                           Col("Col2", width: 4, alignment: .topRight),
                           Col("Col3", width: 4)]
            let table = Tbl(columns: columns, data: data)
            XCTAssertEqual(table.render(),
                           """
                           +----+----+----+
                           |Col1|Col2|Col3|
                           +----+----+----+
                           |#   |    |    |
                           +----+----+----+
                           |#   |   #|    |
                           +----+----+----+
                           |#   |   #|#   |
                           +----+----+----+

                           """)
        }
    }
    func test_leftAndRightPadding() {
        do {
            let data:[[Txt]] = [["#"]]
            let columns = [Col("Col1", width: 4)]
            let table = Tbl("Ttle", columns: columns, data: data)
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
            let columns = [Col("Col1", width: 4), Col("Col2", width: 4, alignment: .topRight)]
            let table = Tbl(columns: columns, data: data)
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
            let table = Tbl("Title", columns: columns, data: data)
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
            let columns = Alignment.allCases.map({ Col(Txt("\($0)"), width: 3, alignment: $0) })
            let data:[[Txt]] = [Array(repeating: Txt("#"), count: columns.count)]
            let table = Tbl(columns: columns, data: data)
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
            let columns = Alignment.allCases.map({ Col(Txt("\($0)"),width: 3, alignment: $0) })
            let data:[[Txt]] = [["123"] + Array(repeating: Txt("#"), count: columns.count)]
            let table = Tbl(columns: [Col(width: 1)] + columns, data: data)
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
            let table = Tbl(columns: [Col(width: 12, wrapping: .char)], data: data)
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
            let table = Tbl(columns: [Col(width: 12)], data: data)
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
            let table = Tbl(columns: [Col(width: 12, wrapping: .word)], data: data)
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
            let table = Tbl(columns: [Col(width: 12, wrapping: .cut)], data: data)
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
            let table = Tbl(columns: [Col(width: 12)], data: data)
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
            let table = Tbl(columns: [Col(width: 12, wrapping: .word)], data: data)
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
            let table = Tbl(columns: [Col(width: 1, wrapping: .cut)], data: data)
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
            let table = Tbl(columns: [Col(width: 2, wrapping: .cut)], data: data)
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
            let table = Tbl(columns: [Col(width: 3, wrapping: .cut)], data: data)
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
            let table = Tbl(columns: [Col(width: 12, wrapping: .word)], data: data)
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
            let table = Tbl(columns: [Col(width: 16)], data: data)
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
            let table = Tbl(columns: [Col(width: 5, wrapping: .char)], data: data)
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
            let table = Tbl(columns: [Col(width: 9, alignment: .topLeft)], data: data)
            XCTAssertEqual(table.render(),
                           """
                           +---------+
                           |RawDefini|
                           |tion(    |
                           |"def",   |
                           |width: 5,|
                           |symbol:  |
                           |$dir! ,  |
                           |fieldNumb|
                           |er: 253, |
                           |value:   |
                           |[ 1,     |
                           |2, 3] )  |
                           +---------+

                           """)
        }
    }
    func test_frameStyles() {
        do {
            let styles:[FrameElements] = [.default, .rounded, .roundedPadded,
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
                ╭───────────╮
                │     *     │
                ├─────┬─────┤
                │  1  │  2  │
                ├─────┼─────┤
                │  3  │  4  │
                ╰─────┴─────╯

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
                let table = Tbl("*", data: [["1", "2"],["3", "4"]], frameStyle: style)
                XCTAssertEqual(table.render(), expected[i])
            }
        }
    }
    func test_frameRenderingOptions() {
        do {
            let combinations:[FrameRenderingOptions] = (0...63).map({ FrameRenderingOptions(rawValue: $0) })
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
                let table = Tbl("*", columns: [Col("A"),Col("B")], data: [["1", "2"],["3", "4"]], frameRenderingOptions: opt)
                // Next line: correct answer generator ;-)
                // print("[ // \(opt.optionsInEffect)\n" + table.render().split(separator: "\n").map({ "\"\($0)\"" }).joined(separator: ",\n") + "\n],")
                XCTAssertEqual(table.render(), expected[i].joined(separator: "\n") + "\n")
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
            let table = Tbl("Title", columns: [Col(width: 16)], data: [[Txt(pangram)]])
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
            let table = Tbl("English-language pangram — a sentence that contains all of the letters of the English alphabet.", columns: [Col(width: 16)], data: [[Txt(pangram)]])
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |    English-    |
                           |    language    |
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
            let table = Tbl(Txt("Title", alignment: .topLeft), columns: [Col(width: 16)], data: [[Txt(pangram)]])
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
            let table = Tbl(Txt("Title", alignment: .bottomRight), columns: [Col(width: 16)], data: [[Txt(pangram)]])
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
            let table = Tbl(Txt("Title wider than column width", alignment: .middleLeft), columns: [Col(width: 16)], data: [[Txt(pangram)]])
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
            let table = Tbl(Txt("Title wider than column width", alignment: .bottomRight), columns: [Col(width: 16)], data: [[Txt(pangram)]])
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
                let table = Tbl(columns: columns, data: [[]])
                XCTAssertEqual(table.render(), expected[i])
            }
        }
    }
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
        for i in 0..<2000 { // Generate 32000 unique rows
            for (j,arr) in src.enumerated() {
                result.append(arr.map({ Txt("[\(i),\(j)]" + $0) }))
            }
        }
        return result
    }()
    // MARK: -
    // MacBook Pro (15-inch, 2016)
    // Processor 2,9 GHz Quad-Core Intel Core i7
    // Memory 16GB 2133 MHz LPDDR3
    // Radeon Pro 460 4GB, Intel HD Graphics 530 1536 MB
    // macOS Big Sur 11.5.2
    // Xcode version 12.5.1 (12E507)
    // Apple Swift version 5.4.2 (swiftlang-1205.0.28.2 clang-1205.0.19.57)

    func testPerformanceCharWrapping() {
        var data:[[Txt]] = []
        for _ in 0..<2 { // 64000 rows
            data.append(contentsOf: perfDataSource)
        }

        let cols = [
            Col(width: 8, alignment: .topLeft, wrapping: .char, contentHint: .unique),
            Col(width: 6, alignment: .topCenter, wrapping: .char, contentHint: .repetitive),
        ]
        // Idicative performance metrics (of release build) with above setup:
        // average should be within the range of 0,620...0,655 seconds

        measure {
            // Tbl.init is intentionally included as part of the
            // work is done there.
            _ = Tbl("Title", columns: cols, data: data).render()
        }
    }
    func testPerformanceCutWrapping() {
        var data:[[Txt]] = []
        for _ in 0..<2 { // 50000 rows, two columns
            data.append(contentsOf: perfDataSource)
        }

        let cols = [
            Col(width: 8, alignment: .topLeft, wrapping: .cut, contentHint: .unique),
            Col(width: 6, alignment: .topCenter, wrapping: .cut, contentHint: .repetitive),
        ]
        // Idicative performance metrics (of release build) with above setup:
        // average should be within the range of 0,330...0,340 seconds

        measure {
            // Tbl.init is intentionally included as part of the
            // work is done there.
            _ = Tbl("Title", columns: cols, data: data).render()
        }
    }
    func testPerformanceWordWrapping() {
        var data:[[Txt]] = []
        for _ in 0..<2 { // 50000 rows, two columns
            data.append(contentsOf: perfDataSource)
        }

        let cols = [
            Col(width: 8, alignment: .topLeft, wrapping: .word, contentHint: .unique),
            Col(width: 6, alignment: .topCenter, wrapping: .word, contentHint: .repetitive),
        ]
        // Idicative performance metrics (of release build) with above setup:
        // average should be within the range of 1,750...1,810 seconds

        measure {
            // Tbl.init is intentionally included as part of the
            // work is done there.
            _ = Tbl("Title", columns: cols, data: data).render()
        }
    }
}
