public struct FrameElements {

    public var topLeftCorner:                     String
    public var topHorizontalSeparator:            String
    public var topHorizontalVerticalSeparator:    String
    public var topRightCorner:                    String
    public var leftVerticalSeparator:             String
    public var rightVerticalSeparator:            String
    public var insideLeftVerticalSeparator:       String
    public var insideHorizontalSeparator:         String
    public var insideRightVerticalSeparator:      String
    public var insideHorizontalVerticalSeparator: String
    public var insideVerticalSeparator:           String
    public var bottomLeftCorner:                  String
    public var bottomHorizontalSeparator:         String
    public var bottomHorizontalVerticalSeparator: String
    public var bottomRightCorner:                 String
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
            precondition(l.count == r.count, "\(FrameElements.self) \"\(l)\" and \"\(r)\" have different string lengths and would produce misaligned frame.")
        }
        for mustBeSingleChar in [topHorizontalSeparator, insideHorizontalSeparator, bottomHorizontalSeparator] {
            precondition(mustBeSingleChar.count == 1, "\(FrameElements.self) \"\(mustBeSingleChar)\" length must be 1.")
        }
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
}
extension FrameElements {
    public static var squared: Self {
        FrameElements(
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
        FrameElements(
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
        FrameElements(
            topLeftCorner:                        "╭──",
            topHorizontalSeparator:               "─",
            topHorizontalVerticalSeparator:       "──┬──",
            topRightCorner:                       "──╮",
            leftVerticalSeparator:                "│  ",
            rightVerticalSeparator:               "  │",
            insideLeftVerticalSeparator:          "├──",
            insideHorizontalSeparator:            "─",
            insideRightVerticalSeparator:         "──┤",
            insideHorizontalVerticalSeparator:    "──┼──",
            insideVerticalSeparator:              "  │  ",
            bottomLeftCorner:                     "╰──",
            bottomHorizontalSeparator:            "─",
            bottomHorizontalVerticalSeparator:    "──┴──",
            bottomRightCorner:                    "──╯"
        )
    }
}
extension FrameElements {
    public static var `default`:Self {
        FrameElements(
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
        FrameElements(
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
}

