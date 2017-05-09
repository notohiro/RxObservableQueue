//
//  RxQueueTests.swift
//  RxQueueTests
//
//  Created by Hiroshi Noto on 2017/05/09.
//  Copyright © 2017 Hiroshi Noto. All rights reserved.
//

import XCTest

import RxSwift

@testable import RxQueue

class RxQueueTests: XCTestCase {
	static func queueWithError() -> Observable<Int> {
		return Observable<Int>.create { observer in
			for i in 1...3 {
				sleep(1)
				observer.onNext(i)
			}

			observer.onError(NSError())

			return Disposables.create()
		}
	}

	static func queue() {

	}

    func testSubscribe() {
        let semaphore = DispatchSemaphore(value: 3)
		let bag = DisposeBag()

		var completed = false

		let queue = Observable.of(1, 2, 3, 4, 5, 6, 7, 8 ,9)

		RxQueue
			.create(observable: queue, semaphore: semaphore)
			.subscribe(onNext: { task in
				// do some time-consuming task
				OperationQueue().addOperation {
					print("\(task) started")
					sleep(1)
					print("\(task) finished")

					// send signal() to pop next task from queue
					semaphore.signal()
				}
			}, onCompleted: {
				completed = true
			})
			.addDisposableTo(bag)

		RunLoop.current.run(until: Date(timeIntervalSinceNow: 5))

		XCTAssertTrue(completed)
    }

	func testError() {
		let semaphore = DispatchSemaphore(value: 3)
		let bag = DisposeBag()

		var completed = false

		let queue = RxQueueTests.queueWithError()

		RxQueue
			.create(observable: queue, semaphore: semaphore)
			.subscribe(onNext: { task in
				print(task)
				OperationQueue().addOperation {
					sleep(1)
					semaphore.signal()
				}
			}, onCompleted: {
				completed = true
			})
			.addDisposableTo(bag)

		RunLoop.current.run(until: Date(timeIntervalSinceNow: 5))

		XCTAssertTrue(completed)
	}

	func testFlatMap() {
		let semaphore = DispatchSemaphore(value: 2)
		let bag = DisposeBag()

		var completed = false

		let sourceObservable = Observable<Int>.create { observer in
			for i in 1...3 {
				print("source: \(i)")
				observer.onNext(i)
				RunLoop.current.run(until: Date(timeIntervalSinceNow: 2))
			}

			observer.onCompleted()
			return Disposables.create()
		}

		sourceObservable
			.flatMapLatest { source -> Observable<String> in
				// creating tasks from sourceObservable
				let queue = Observable<String>.create { observer in
					for i in 1...5 {
						let task = source * i
						observer.onNext(String("source: \(source) task: \(task)"))
					}
					observer.onCompleted()

					return Disposables.create()
				}

				return RxQueue.create(observable: queue, semaphore: semaphore)
			}
			.subscribe(onNext: { task in
				// do some time-consuming task
				print(task)
				OperationQueue().addOperation {
					print("\(task) started")
					sleep(1)
					print("\(task) finished")

					// send signal() to pop next task from queue
					semaphore.signal()
				}
			}, onCompleted: {
				completed = true
			})
			.addDisposableTo(bag)

		RunLoop.current.run(until: Date(timeIntervalSinceNow: 10))

		XCTAssertTrue(completed)
	}
}
