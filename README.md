# Table
Simple table

```
let data:[[Txt]] = [
    ["123", Txt("x", .topLeft), Txt("x", .topCenter), Txt("x", .topRight)],
    ["123", Txt("x", .middleLeft), Txt("x", .middleCenter), Txt("x", .middleRight)],
    ["123", Txt("x", .bottomLeft), Txt("x", .bottomCenter), Txt("x", .bottomRight)],
]
let width:Width = 5

let cols = [
    Col(header: "#", width: 1, alignment: .topLeft),
    Col(header: "Col 1", width: width, alignment: .bottomCenter),
    Col(header: "Col 2", width: width, alignment: .bottomCenter),
    Col(header: "Col 3", width: width, alignment: .bottomCenter),
]
let table = Tbl("Table title",
                columns: cols,
                data: data,
                frameStyle: .roundedPadded)
var t = ""
table.render(into: &t)
print(t)
// Produces ->
//╭───────────────────────────────────╮
//│            Table title            │
//├─────┬─────────┬─────────┬─────────┤
//│  #  │  Col 1  │  Col 2  │  Col 3  │
//├─────┼─────────┼─────────┼─────────┤
//│  1  │  x      │    x    │      x  │
//│  2  │         │         │         │
//│  3  │         │         │         │
//├─────┼─────────┼─────────┼─────────┤
//│  1  │         │         │         │
//│  2  │  x      │    x    │      x  │
//│  3  │         │         │         │
//├─────┼─────────┼─────────┼─────────┤
//│  1  │         │         │         │
//│  2  │         │         │         │
//│  3  │  x      │    x    │      x  │
//╰─────┴─────────┴─────────┴─────────╯
```
