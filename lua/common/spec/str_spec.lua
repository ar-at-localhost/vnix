local str = require("str")

describe("str.pad_right", function()
  it("should pad string on the right with spaces by default", function()
    assert.are.equal("hi   ", str.pad_right("hi", 5))
  end)

  it("should return exact string when length equals target", function()
    assert.are.equal("hello", str.pad_right("hello", 5))
  end)

  it("should use custom padding character", function()
    assert.are.equal("hi...", str.pad_right("hi", 5, "."))
  end)

  it("should handle empty string", function()
    assert.are.equal("   ", str.pad_right("", 3))
  end)

  it("should handle nil input", function()
    assert.are.equal("   ", str.pad_right(nil, 3))
  end)

  it("should return string as-is when longer than target", function()
    assert.are.equal("hello", str.pad_right("hello", 3))
  end)
end)

describe("str.pad_left", function()
  it("should pad string on the left with spaces by default", function()
    assert.are.equal("   hi", str.pad_left("hi", 5))
  end)

  it("should return exact string when length equals target", function()
    assert.are.equal("hello", str.pad_left("hello", 5))
  end)

  it("should use custom padding character", function()
    assert.are.equal("000hi", str.pad_left("hi", 5, "0"))
  end)

  it("should handle empty string", function()
    assert.are.equal("   ", str.pad_left("", 3))
  end)

  it("should return string as-is when longer than target", function()
    assert.are.equal("hello", str.pad_left("hello", 3))
  end)
end)

describe("str.pad (center)", function()
  it("should center pad with odd total padding", function()
    assert.are.equal(" hi  ", str.pad("hi", 5))
  end)

  it("should center pad with even total padding", function()
    assert.are.equal("  hi  ", str.pad("hi", 6))
  end)

  it("should return exact string when length equals target", function()
    assert.are.equal("hi", str.pad("hi", 2))
  end)

  it("should ellipsify when string is longer than target", function()
    assert.are.equal("h...", str.pad("hello", 4))
  end)

  it("should return truncated ellipsis when target <= ellipsis length", function()
    assert.are.equal("..", str.pad("hello", 2, nil, ".."))
  end)

  it("should use custom padding character", function()
    assert.are.equal(".hi..", str.pad("hi", 5, "."))
  end)

  it("should use custom ellipsis string", function()
    assert.are.equal("hello ", str.pad("hello", 6, nil, ">>"))
  end)

  it("should handle empty string", function()
    assert.are.equal(" ", str.pad("", 1))
    assert.are.equal("   ", str.pad("", 3))
  end)

  it("should truncate to ellipsis when longer than target", function()
    assert.are.equal("...", str.pad("hello", 3))
  end)
end)
