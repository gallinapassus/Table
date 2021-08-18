import XCTest
import Table

final class TableTests: XCTestCase {
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
            let data:[[Txt]] = [["Quick brown fox", "jumped over the lazy dog."]]
            let table = Tbl(data: data)
            XCTAssertEqual(table.render(),
                           """
                           +---------------+-------------------------+
                           |Quick brown fox|jumped over the lazy dog.|
                           +---------------+-------------------------+

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
                           |Rig|Lef|Cen|tom|tom|tom|dle|dle|dle|
                           | ht|t  |ter|Rig|Lef|Cen|Rig|Lef|Cen|
                           |   |   |   | ht|t  |ter| ht|t  |ter|
                           +---+---+---+---+---+---+---+---+---+
                           |  #|#  | # |  #|#  | # |  #|#  | # |
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
                           | |Rig|Lef|Cen|tom|tom|tom|dle|dle|dle|
                           | | ht|t  |ter|Rig|Lef|Cen|Rig|Lef|Cen|
                           | |   |   |   | ht|t  |ter| ht|t  |ter|
                           +-+---+---+---+---+---+---+---+---+---+
                           |1|  #|#  | # |   |   |   |   |   |   |
                           |2|   |   |   |   |   |   |  #|#  | # |
                           |3|   |   |   |  #|#  | # |   |   |   |
                           +-+---+---+---+---+---+---+---+---+---+

                           """)
        }
    }
    func test_wrappingChar() {
        do {
            // Wrpping taken from column's definition
            let data = [[Txt("Quick brown fox jumped over the lazy dog.")]]
            let table = Tbl(columns: [Col(width: 12, wrapping: .char)], data: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |Quick brown |
                           |fox jumped o|
                           |ver the lazy|
                           |dog.        |
                           +------------+

                           """)
        }
        do {
            // Wrpping taken from Txt
            let data = [[Txt("Quick brown fox jumped over the lazy dog.", wrapping: .char)]]
            let table = Tbl(columns: [Col(width: 12)], data: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |Quick brown |
                           |fox jumped o|
                           |ver the lazy|
                           |dog.        |
                           +------------+

                           """)
        }
        do {
            // Wrpping defined at column level, overidden by Txt
            let data = [[Txt("Quick brown fox jumped over the lazy dog.", wrapping: .char)]]
            let table = Tbl(columns: [Col(width: 12, wrapping: .word)], data: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |Quick brown |
                           |fox jumped o|
                           |ver the lazy|
                           |dog.        |
                           +------------+

                           """)
        }
    }
    func test_wrappingCut() {
        do {
            // Wrpping taken from column's definition
            let data = [[Txt("Quick brown fox jumped over the lazy dog.")]]
            let table = Tbl(columns: [Col(width: 12, wrapping: .cut)], data: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |Quick … dog.|
                           +------------+

                           """)
        }
        do {
            // Wrpping taken from Txt
            let data = [[Txt("Quick brown fox jumped over the lazy dog.", wrapping: .cut)]]
            let table = Tbl(columns: [Col(width: 12)], data: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |Quick … dog.|
                           +------------+

                           """)
        }
        do {
            // Wrpping defined at column level, overidden by Txt
            let data = [[Txt("Quick brown fox jumped over the lazy dog.", wrapping: .cut)]]
            let table = Tbl(columns: [Col(width: 12, wrapping: .word)], data: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |Quick … dog.|
                           +------------+

                           """)
        }
        do {
            // Special case - column width = 1
            let data = [[Txt("Quick brown fox jumped over the lazy dog.")]]
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
            let data = [[Txt("Quick brown fox jumped over the lazy dog.")]]
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
            let data = [[Txt("Quick brown fox jumped over the lazy dog.")]]
            let table = Tbl(columns: [Col(width: 3, wrapping: .cut)], data: data)
            XCTAssertEqual(table.render(),
                           """
                           +---+
                           |Q….|
                           +---+

                           """)
        }
    }
    func test_wrappingWord() {
        do {
            // Wrpping taken from column's definition
            let data = [[Txt("Quick brown fox jumped over the lazy dog.")]]
            let table = Tbl(columns: [Col(width: 12, wrapping: .word)], data: data)
            XCTAssertEqual(table.render(),
                           """
                           +------------+
                           |Quick brown |
                           |fox jumped  |
                           |over the    |
                           |lazy dog.   |
                           +------------+

                           """)
        }
        do {
            // Wrpping taken from Txt
            let data = [[Txt("Quick brown fox jumped over the lazy dog.", wrapping: .word)]]
            let table = Tbl(columns: [Col(width: 16)], data: data)
            XCTAssertEqual(table.render(),
                           """
                           +----------------+
                           |Quick brown     |
                           |fox jumped over |
                           |the lazy dog.   |
                           +----------------+

                           """)
        }
        do {
            // Wrpping defined at column level, overidden by Txt
            // Notes:
            //     - Spaces at the column width positions are removed (as below: "Quick" "brown")
            //     - Words which are too long to fit are "forcibly" wrapped at
            //       character boundary (as below: "jumpe" "d")
            let data = [[Txt("Quick brown fox jumped over the lazy dog.", wrapping: .word)]]
            let table = Tbl(columns: [Col(width: 5, wrapping: .char)], data: data)
            XCTAssertEqual(table.render(),
                           """
                           +-----+
                           |Quick|
                           |brown|
                           |fox  |
                           |jumpe|
                           |d    |
                           |over |
                           |the  |
                           |lazy |
                           |dog. |
                           +-----+

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
        // TODO
    }
    func test_columnHeaderAlignment() {
        // TODO
    }
    func testPerformance() {
        var data:[[Txt]] = []
        let rnd = ["by itself", "as part of the sentence"]
        let sentences = [
            ["A blessing in disguise", rnd.randomElement()!],
            ["A dime a dozen", rnd.randomElement()!],
            ["Beat around the bush", rnd.randomElement()!],
            ["Better late than never", rnd.randomElement()!],
            ["Bite the bullet", rnd.randomElement()!],
            ["Break a leg", rnd.randomElement()!],
            ["Call it a day", rnd.randomElement()!],
            ["Cut somebody some slack", rnd.randomElement()!],
            ["Cutting corners", rnd.randomElement()!],
            ["Easy does it", rnd.randomElement()!],
            ["Get out of hand", rnd.randomElement()!],
            ["Get something out of your system", rnd.randomElement()!],
            ["Get your act together", rnd.randomElement()!],
            ["Give someone the benefit of the doubt", rnd.randomElement()!],
            ["Go back to the drawing board", rnd.randomElement()!],
            ["Hang in there", rnd.randomElement()!],
            ["Hit the sack", rnd.randomElement()!],
        ]

        for _ in 0..<50000 {
            let cols:[Txt] = sentences.randomElement()!.map { Txt($0, alignment: Alignment.allCases.randomElement()!) }
            data.append(cols)
        }
        let cols = [
            Col(width: 8, alignment: .topLeft, contentHint: .unique),
            Col(width: 6, alignment: .topCenter, contentHint: .repetitive),
        ]
        // Release version times:
        // average: 0.788 -> print(..., to: &into)
        // average: 0.668 -> into.append()
        // average: 0.639 -> transposed() tweak
        // average: 0.415 -> .char wrapping as default
        measure {
            let table = Tbl("Title", columns: cols, data: data)
            var t = ""
            table.render(into: &t)
        }
    }
}
