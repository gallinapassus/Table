/// Table frame style
///
/// Defines the individual table frame building blocks.
/// Provides simple validation of elements to produce
/// coherent table frames.
///
/// Custom styles can be created as extensions.

public struct FrameStyle : Equatable, Codable {
    public let topLeftCorner:                     String
    public let topHorizontalSeparator:            String
    public let topHorizontalVerticalSeparator:    String
    public let topRightCorner:                    String
    public let leftVerticalSeparator:             String
    public let rightVerticalSeparator:            String
    public let insideLeftVerticalSeparator:       String
    public let insideHorizontalSeparator:         String
    public let insideHorizontalRowRangeSeparator: String
    public let insideRightVerticalSeparator:      String
    public let insideHorizontalVerticalSeparator: String
    public let insideVerticalSeparator:           String
    public let bottomLeftCorner:                  String
    public let bottomHorizontalSeparator:         String
    public let bottomHorizontalVerticalSeparator: String
    public let bottomRightCorner:                 String
    public init(
        topLeftCorner:                     String,
        topHorizontalSeparator:            String,
        topHorizontalVerticalSeparator:    String,
        topRightCorner:                    String,
        leftVerticalSeparator:             String,
        rightVerticalSeparator:            String,
        insideLeftVerticalSeparator:       String,
        insideHorizontalSeparator:         String,
        insideHorizontalRowRangeSeparator: String,
        insideRightVerticalSeparator:      String,
        insideHorizontalVerticalSeparator: String,
        insideVerticalSeparator:           String,
        bottomLeftCorner:                  String,
        bottomHorizontalSeparator:         String,
        bottomHorizontalVerticalSeparator: String,
        bottomRightCorner:                 String
    ) {
        Self.validate(
            topLeftCorner                    ,
            topHorizontalSeparator           ,
            topHorizontalVerticalSeparator   ,
            topRightCorner                   ,
            leftVerticalSeparator            ,
            rightVerticalSeparator           ,
            insideLeftVerticalSeparator      ,
            insideHorizontalSeparator        ,
            insideHorizontalRowRangeSeparator,
            insideRightVerticalSeparator     ,
            insideHorizontalVerticalSeparator,
            insideVerticalSeparator          ,
            bottomLeftCorner                 ,
            bottomHorizontalSeparator        ,
            bottomHorizontalVerticalSeparator,
            bottomRightCorner
        )
        self.topLeftCorner                     = topLeftCorner
        self.topHorizontalSeparator            = topHorizontalSeparator
        self.topHorizontalVerticalSeparator    = topHorizontalVerticalSeparator
        self.topRightCorner                    = topRightCorner
        self.leftVerticalSeparator             = leftVerticalSeparator
        self.rightVerticalSeparator            = rightVerticalSeparator
        self.insideLeftVerticalSeparator       = insideLeftVerticalSeparator
        self.insideHorizontalSeparator         = insideHorizontalSeparator
        self.insideHorizontalRowRangeSeparator = insideHorizontalRowRangeSeparator
        self.insideRightVerticalSeparator      = insideRightVerticalSeparator
        self.insideHorizontalVerticalSeparator = insideHorizontalVerticalSeparator
        self.insideVerticalSeparator           = insideVerticalSeparator
        self.bottomLeftCorner                  = bottomLeftCorner
        self.bottomHorizontalSeparator         = bottomHorizontalSeparator
        self.bottomHorizontalVerticalSeparator = bottomHorizontalVerticalSeparator
        self.bottomRightCorner                 = bottomRightCorner
    }

    private static func validate(
        _ topLeftCorner:                     String,
        _ topHorizontalSeparator:            String,
        _ topHorizontalVerticalSeparator:    String,
        _ topRightCorner:                    String,
        _ leftVerticalSeparator:             String,
        _ rightVerticalSeparator:            String,
        _ insideLeftVerticalSeparator:       String,
        _ insideHorizontalSeparator:         String,
        _ insideHorizontalRowRangeSeparator: String,
        _ insideRightVerticalSeparator:      String,
        _ insideHorizontalVerticalSeparator: String,
        _ insideVerticalSeparator:           String,
        _ bottomLeftCorner:                  String,
        _ bottomHorizontalSeparator:         String,
        _ bottomHorizontalVerticalSeparator: String,
        _ bottomRightCorner:                 String
    ) {
        let pairs = [
            (topLeftCorner, bottomLeftCorner),
            (topLeftCorner, leftVerticalSeparator),
            (topLeftCorner, insideLeftVerticalSeparator),

            (topRightCorner, bottomRightCorner),
            (topRightCorner, rightVerticalSeparator),
            (topRightCorner, insideRightVerticalSeparator),

            (topHorizontalSeparator, bottomHorizontalSeparator),
            (topHorizontalSeparator, insideHorizontalSeparator),
            (insideHorizontalSeparator, insideHorizontalRowRangeSeparator),

            (leftVerticalSeparator, insideLeftVerticalSeparator),

            (rightVerticalSeparator, insideRightVerticalSeparator),

            (topHorizontalVerticalSeparator, bottomHorizontalVerticalSeparator),
            (topHorizontalVerticalSeparator, insideHorizontalVerticalSeparator),
        ]
        for (l,r) in pairs {
            precondition(l.count == r.count, "\(FrameStyle.self) \"\(l)\" and \"\(r)\" have different string lengths and would produce misaligned frame.")
        }
        for mustBeSingleChar in [topHorizontalSeparator, insideHorizontalSeparator, insideHorizontalRowRangeSeparator, bottomHorizontalSeparator] {
            precondition(mustBeSingleChar.count == 1, "\(FrameStyle.self) \"\(mustBeSingleChar)\" length must be 1.")
        }
    }
    public func topLeftCorner(for options:FramingOptions) -> String {
        options.contains([.leftFrame, .topFrame]) ? topLeftCorner : ""
    }
    public func topHorizontalSeparator(for options:FramingOptions) -> String {
        (options.contains(.topFrame) || options.contains(.inside)) ? topHorizontalSeparator : " "
    }
    public func topHorizontalVerticalSeparator(for options:FramingOptions) -> String {
        options.contains([.topFrame, .inside]) || options.contains(.inside) ? topHorizontalVerticalSeparator : ""
    }
    public func topRightCorner(for options:FramingOptions) -> String {
        options.contains([.rightFrame, .topFrame]) ? topRightCorner : ""
    }
    public func leftVerticalSeparator(for options:FramingOptions) -> String {
        options.contains(.leftFrame) ? leftVerticalSeparator : ""
    }
    public func rightVerticalSeparator(for options:FramingOptions) -> String {
        options.contains(.rightFrame) ? rightVerticalSeparator : ""
    }
    public func insideLeftVerticalSeparator(for options:FramingOptions) -> String {
        options.contains(.leftFrame) ? insideLeftVerticalSeparator : ""
    }
    public func insideHorizontalSeparator(for options:FramingOptions) -> String {
        (options.contains(.insideHorizontalFrame) || options.contains(.leftFrame) || options.contains(.rightFrame)) ? insideHorizontalSeparator : " "
    }
    public func insideHorizontalRowRangeSeparator(for options:FramingOptions) -> String {
        (options.contains(.insideHorizontalFrame) || options.contains(.leftFrame) || options.contains(.rightFrame)) ? insideHorizontalRowRangeSeparator : " "
    }
    public func insideRightVerticalSeparator(for options:FramingOptions) -> String {
        options.contains(.rightFrame) ? insideRightVerticalSeparator : ""
    }
    public func insideHorizontalVerticalSeparator(for options:FramingOptions) -> String {
        options.contains(.insideHorizontalFrame) && options.contains(.insideVerticalFrame) ?
            insideHorizontalVerticalSeparator : ""
    }
    public func insideVerticalSeparator(for options:FramingOptions) -> String {
        options.contains(.insideVerticalFrame) ? insideVerticalSeparator : ""
    }
    public func bottomLeftCorner(for options:FramingOptions) -> String {
        options.contains([.leftFrame, .bottomFrame]) ? bottomLeftCorner : ""
    }
    public func bottomHorizontalSeparator(for options:FramingOptions) -> String {
        options.contains(.bottomFrame) ? bottomHorizontalSeparator : " "
    }
    public func bottomHorizontalVerticalSeparator(for options:FramingOptions) -> String {
        options.contains([.bottomFrame, .insideVerticalFrame]) ? bottomHorizontalVerticalSeparator : ""
    }
    public func bottomRightCorner(for options:FramingOptions) -> String {
        options.contains([.rightFrame, .bottomFrame]) ? bottomRightCorner : ""
    }
}
extension FrameStyle {
    public static var `default`:Self {
        FrameStyle(
            topLeftCorner:                        "+",
            topHorizontalSeparator:               "-",
            topHorizontalVerticalSeparator:       "+",
            topRightCorner:                       "+",
            leftVerticalSeparator:                "|",
            rightVerticalSeparator:               "|",
            insideLeftVerticalSeparator:          "+",
            insideHorizontalSeparator:            "-",
            insideHorizontalRowRangeSeparator:    "~",
            insideRightVerticalSeparator:         "+",
            insideHorizontalVerticalSeparator:    "+",
            insideVerticalSeparator:              "|",
            bottomLeftCorner:                     "+",
            bottomHorizontalSeparator:            "-",
            bottomHorizontalVerticalSeparator:    "+",
            bottomRightCorner:                    "+"
        )
    }
    public static var ascii:Self {
        `default`
    }
    public static var singleSpace:Self {
        FrameStyle(
            topLeftCorner:                        " ",
            topHorizontalSeparator:               " ",
            topHorizontalVerticalSeparator:       " ",
            topRightCorner:                       " ",
            leftVerticalSeparator:                " ",
            rightVerticalSeparator:               " ",
            insideLeftVerticalSeparator:          " ",
            insideHorizontalSeparator:            " ",
            insideHorizontalRowRangeSeparator:    " ",
            insideRightVerticalSeparator:         " ",
            insideHorizontalVerticalSeparator:    " ",
            insideVerticalSeparator:              " ",
            bottomLeftCorner:                     " ",
            bottomHorizontalSeparator:            " ",
            bottomHorizontalVerticalSeparator:    " ",
            bottomRightCorner:                    " "
        )
    }
    public static var squaredDouble:Self {
        FrameStyle(
            topLeftCorner:                        "╔",
            topHorizontalSeparator:               "═",
            topHorizontalVerticalSeparator:       "╦",
            topRightCorner:                       "╗",
            leftVerticalSeparator:                "║",
            rightVerticalSeparator:               "║",
            insideLeftVerticalSeparator:          "╠",
            insideHorizontalSeparator:            "═",
            insideHorizontalRowRangeSeparator:    "─",
            insideRightVerticalSeparator:         "╣",
            insideHorizontalVerticalSeparator:    "╬",
            insideVerticalSeparator:              "║",
            bottomLeftCorner:                     "╚",
            bottomHorizontalSeparator:            "═",
            bottomHorizontalVerticalSeparator:    "╩",
            bottomRightCorner:                    "╝"
        )
    }
    public static var squared: Self {
        FrameStyle(
            topLeftCorner:                        "┌",
            topHorizontalSeparator:               "─",
            topHorizontalVerticalSeparator:       "┬",
            topRightCorner:                       "┐",
            leftVerticalSeparator:                "│",
            rightVerticalSeparator:               "│",
            insideLeftVerticalSeparator:          "├",
            insideHorizontalSeparator:            "─",
            insideHorizontalRowRangeSeparator:    "╌",
            insideRightVerticalSeparator:         "┤",
            insideHorizontalVerticalSeparator:    "┼",
            insideVerticalSeparator:              "│",
            bottomLeftCorner:                     "└",
            bottomHorizontalSeparator:            "─",
            bottomHorizontalVerticalSeparator:    "┴",
            bottomRightCorner:                    "┘"
        )
    }
    public static var rounded: Self {
        FrameStyle(
            topLeftCorner:                        "╭",
            topHorizontalSeparator:               "─",
            topHorizontalVerticalSeparator:       "┬",
            topRightCorner:                       "╮",
            leftVerticalSeparator:                "│",
            rightVerticalSeparator:               "│",
            insideLeftVerticalSeparator:          "├",
            insideHorizontalSeparator:            "─",
            insideHorizontalRowRangeSeparator:    "╌",
            insideRightVerticalSeparator:         "┤",
            insideHorizontalVerticalSeparator:    "┼",
            insideVerticalSeparator:              "│",
            bottomLeftCorner:                     "╰",
            bottomHorizontalSeparator:            "─",
            bottomHorizontalVerticalSeparator:    "┴",
            bottomRightCorner:                    "╯"
        )
    }
    public static var roundedPadded: Self {
        FrameStyle(
            topLeftCorner:                        "╭─",
            topHorizontalSeparator:               "─",
            topHorizontalVerticalSeparator:       "─┬─",
            topRightCorner:                       "─╮",
            leftVerticalSeparator:                "│ ",
            rightVerticalSeparator:               " │",
            insideLeftVerticalSeparator:          "├─",
            insideHorizontalSeparator:            "─",
            insideHorizontalRowRangeSeparator:    "╌",
            insideRightVerticalSeparator:         "─┤",
            insideHorizontalVerticalSeparator:    "─┼─",
            insideVerticalSeparator:              " │ ",
            bottomLeftCorner:                     "╰─",
            bottomHorizontalSeparator:            "─",
            bottomHorizontalVerticalSeparator:    "─┴─",
            bottomRightCorner:                    "─╯"
        )
    }
}
