[![Tests](https://github.com/gallinapassus/Table/actions/workflows/table-ci.yml/badge.svg)](https://github.com/gallinapassus/Table/actions/workflows/table-ci.yml)

# Table
Simple table

```swift
import Table

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
```

Another simple table using DSL.

```swift
import Table

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
```
