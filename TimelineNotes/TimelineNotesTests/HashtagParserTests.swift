import XCTest
@testable import TimelineNotes

final class HashtagParserTests: XCTestCase {

    func testExtractsSimpleHashtag() {
        let result = HashtagParser.extractHashtags(from: "Hello #world")
        XCTAssertEqual(result, ["world"])
    }

    func testExtractsMultipleHashtags() {
        let result = HashtagParser.extractHashtags(from: "#hello #world test")
        XCTAssertEqual(result, ["hello", "world"])
    }

    func testExtractsChineseHashtags() {
        let result = HashtagParser.extractHashtags(from: "今天 #天气 不错 #生活")
        XCTAssertEqual(result, ["天气", "生活"])
    }

    func testExtractsHashtagsWithUnderscores() {
        let result = HashtagParser.extractHashtags(from: "Check #hello_world tag")
        XCTAssertEqual(result, ["hello_world"])
    }

    func testNoHashtagsReturnsEmpty() {
        let result = HashtagParser.extractHashtags(from: "Plain text without tags")
        XCTAssertEqual(result, [])
    }

    func testHashtagsAreLowercased() {
        let result = HashtagParser.extractHashtags(from: "Hello #WORLD")
        XCTAssertEqual(result, ["world"])
    }

    func testTextStartingWithHash() {
        let result = HashtagParser.extractHashtags(from: "#tag at start")
        XCTAssertEqual(result, ["tag"])
    }
}
