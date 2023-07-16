[![Tests](https://github.com/gallinapassus/Table/actions/workflows/table-ci.yml/badge.svg)](https://github.com/gallinapassus/Table/actions/workflows/table-ci.yml)

# Table
Simple table

```swift
import Table

let cells:[[Txt]] = [
    ["123", Txt("x", align: .topLeft), Txt("x", align: .topCenter), Txt("x", align: .topRight)],
    ["123", Txt("x", align: .middleLeft), Txt("x", align: .middleCenter), Txt("x", align: .middleRight)],
    ["123", Txt("x", align: .bottomLeft), Txt("x", align: .bottomCenter), Txt("x", align: .bottomRight)],
]
let width:Width = 5

let cols = [
    Col("#", width: 1, alignment: .topLeft),
    Col("Col 1", width: width, alignment: .bottomCenter),
    Col("Col 2", width: width, alignment: .bottomCenter),
    Col("Col 3", width: width, alignment: .bottomCenter),
]
let table = Tbl("Table title",
                columns: cols,
                cells: cells,
                frameStyle: .roundedPadded)

var t = ""
table.render(into: &t)
print(t)
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
```

Another simple table with DSL (domain specific language).

```swift
import Table

let table = Tbl("Summer Olympics") {
                
    FrameStyle.rounded
    FrameRenderingOptions.all
    
    Columns {
        Col("Year", width: .auto)
        Col("Host", width: .in(5...25), wrapping: .word)
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
```
