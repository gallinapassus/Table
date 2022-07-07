public struct FrameStyle : Equatable, Codable {
    public let topLeftCorner:                     String
    public let topHorizontalSeparator:            String
    public let topHorizontalVerticalSeparator:    String
    public let topRightCorner:                    String
    public let leftVerticalSeparator:             String
    public let rightVerticalSeparator:            String
    public let insideLeftVerticalSeparator:       String
    public let insideHorizontalSeparator:         String
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

            (leftVerticalSeparator, insideLeftVerticalSeparator),

            (rightVerticalSeparator, insideRightVerticalSeparator),

            (topHorizontalVerticalSeparator, bottomHorizontalVerticalSeparator),
            (topHorizontalVerticalSeparator, insideHorizontalVerticalSeparator),
        ]
        for (l,r) in pairs {
            precondition(l.count == r.count, "\(FrameStyle.self) \"\(l)\" and \"\(r)\" have different string lengths and would produce misaligned frame.")
        }
        for mustBeSingleChar in [topHorizontalSeparator, insideHorizontalSeparator, bottomHorizontalSeparator] {
            precondition(mustBeSingleChar.count == 1, "\(FrameStyle.self) \"\(mustBeSingleChar)\" length must be 1.")
        }
    }
    public func topLeftCorner(for options:FrameRenderingOptions) -> String {
        options.contains([.leftFrame, .topFrame]) ? topLeftCorner : ""
    }
    public func topHorizontalSeparator(for options:FrameRenderingOptions) -> String {
        (options.contains(.topFrame) || options.contains(.inside)) ? topHorizontalSeparator : " "
    }
    public func topHorizontalVerticalSeparator(for options:FrameRenderingOptions) -> String {
        options.contains([.topFrame, .inside]) || options.contains(.inside) ? topHorizontalVerticalSeparator : ""
    }
    public func topRightCorner(for options:FrameRenderingOptions) -> String {
        options.contains([.rightFrame, .topFrame]) ? topRightCorner : ""
    }
    public func leftVerticalSeparator(for options:FrameRenderingOptions) -> String {
        options.contains(.leftFrame) ? leftVerticalSeparator : ""
    }
    public func rightVerticalSeparator(for options:FrameRenderingOptions) -> String {
        options.contains(.rightFrame) ? rightVerticalSeparator : ""
    }
    public func insideLeftVerticalSeparator(for options:FrameRenderingOptions) -> String {
        options.contains(.leftFrame) ? insideLeftVerticalSeparator : ""
    }
    public func insideHorizontalSeparator(for options:FrameRenderingOptions) -> String {
        (options.contains(.insideHorizontalFrame) || options.contains(.leftFrame) || options.contains(.rightFrame)) ? insideHorizontalSeparator : " "
    }
    public func insideRightVerticalSeparator(for options:FrameRenderingOptions) -> String {
        options.contains(.rightFrame) ? insideRightVerticalSeparator : ""
    }
    public func insideHorizontalVerticalSeparator(for options:FrameRenderingOptions) -> String {
        options.contains(.insideHorizontalFrame) && options.contains(.insideVerticalFrame) ?
            insideHorizontalVerticalSeparator : ""
    }
    public func insideVerticalSeparator(for options:FrameRenderingOptions) -> String {
        options.contains(.insideVerticalFrame) ? insideVerticalSeparator : ""
    }
    public func bottomLeftCorner(for options:FrameRenderingOptions) -> String {
        options.contains([.leftFrame, .bottomFrame]) ? bottomLeftCorner : ""
    }
    public func bottomHorizontalSeparator(for options:FrameRenderingOptions) -> String {
        options.contains(.bottomFrame) ? bottomHorizontalSeparator : " "
    }
    public func bottomHorizontalVerticalSeparator(for options:FrameRenderingOptions) -> String {
        options.contains([.bottomFrame, .insideVerticalFrame]) ? bottomHorizontalVerticalSeparator : ""
    }
    public func bottomRightCorner(for options:FrameRenderingOptions) -> String {
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
