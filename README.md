[![Tests](https://github.com/gallinapassus/Table/actions/workflows/table-ci.yml/badge.svg)](https://github.com/gallinapassus/Table/actions/workflows/table-ci.yml)
![Version](https://img.shields.io/static/v1?label=Version&message=0.0.4&color=green)

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
