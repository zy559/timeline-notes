import XCTest
@testable import TimelineNotes

final class MediaGridLayoutHelperTests: XCTestCase {

    func testSingleImageHasOneColumn() {
        XCTAssertEqual(MediaGridLayoutHelper.columns(for: 1), 1)
    }

    func testTwoImagesHaveTwoColumns() {
        XCTAssertEqual(MediaGridLayoutHelper.columns(for: 2), 2)
    }

    func testThreeImagesHaveThreeColumns() {
        XCTAssertEqual(MediaGridLayoutHelper.columns(for: 3), 3)
    }

    func testFiveImagesHaveThreeColumns() {
        XCTAssertEqual(MediaGridLayoutHelper.columns(for: 5), 3)
    }

    func testZeroImagesHasZeroColumns() {
        XCTAssertEqual(MediaGridLayoutHelper.columns(for: 0), 0)
    }
}
