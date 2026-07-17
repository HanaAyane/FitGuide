import XCTest
import UIKit
import ImageIO
@testable import FitGuide

@MainActor
final class PerformanceTests: XCTestCase {
    func testJSONLoadPerformance() throws {
        let store = ExerciseStore()
        let exp = expectation(description: "load")
        Task {
            await store.load()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)
        XCTAssertEqual(store.exercises.count, 1324)

        measure {
            let s = ExerciseStore()
            let e = expectation(description: "m")
            Task {
                await s.load()
                e.fulfill()
            }
            wait(for: [e], timeout: 10)
        }
    }

    func testSearchPerformance() throws {
        let store = ExerciseStore()
        let exp = expectation(description: "load")
        Task {
            await store.load()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        measure {
            _ = store.search(query: "胸")
            _ = store.search(query: "bench")
            _ = store.search(query: "dumbbell")
        }
    }

    func testFilterPerformance() throws {
        let store = ExerciseStore()
        let exp = expectation(description: "load")
        Task {
            await store.load()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        measure {
            _ = store.filtered(bodyParts: ["chest"], equipments: ["dumbbell"], targets: [])
            _ = store.filtered(bodyParts: [], equipments: [], targets: ["biceps"])
        }
    }

    func testGIFURLResolutionPerformance() throws {
        let store = ExerciseStore()
        let exp = expectation(description: "load")
        Task {
            await store.load()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        measure {
            for ex in store.exercises.prefix(50) {
                _ = ExerciseStore.gifURL(for: ex)
                _ = ExerciseStore.imageURL(for: ex)
            }
        }
    }

    func testColdStartToInteractive() throws {
        measure {
            let s = ExerciseStore()
            let e = expectation(description: "m")
            Task {
                await s.load()
                // load完成后即首页可交互
                e.fulfill()
            }
            wait(for: [e], timeout: 10)
            XCTAssertFalse(s.exercises.isEmpty)
        }
    }

    func testGIFFirstFrameLoadTime() throws {
        let store = ExerciseStore()
        let exp = expectation(description: "load")
        Task {
            await store.load()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        // 量首帧 GIF 解码时间
        measure {
            guard let ex = store.exercises.first,
                  let url = ExerciseStore.gifURL(for: ex),
                  let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return }
            _ = CGImageSourceCreateImageAtIndex(src, 0, nil)
        }
    }

    func testThumbnailLoadBatchTime() throws {
        let store = ExerciseStore()
        let exp = expectation(description: "load")
        Task {
            await store.load()
            exp.fulfill()
        }
        wait(for: [exp], timeout: 10)

        // 量首屏卡片缩略图批量解码时间（10 张卡片首屏数量）
        measure {
            for ex in store.exercises.prefix(10) {
                if let url = ExerciseStore.imageURL(for: ex) {
                    _ = UIImage(contentsOfFile: url.path)
                }
            }
        }
    }
}