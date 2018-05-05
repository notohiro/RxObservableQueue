//
//  RxObservableQueueTests.swift
//  RxObservableQueueTests
//
//  Created by Hiroshi Noto on 2017/05/09.
//  Copyright © 2017 Hiroshi Noto. All rights reserved.
//

import XCTest

import RxSwift

@testable import RxObservableQueue

class RxObservableQueueTests: XCTestCase {
	static func createObservable(quantity: Int,
	                             interval: UInt32 = 0,
	                             withError error: Error? = nil) -> Observable<Int> {
		return Observable<Int>.create { observer in
			var disposed = false

			OperationQueue().addOperation {
				if quantity > 0 {
					for index in 1...quantity {
						if disposed { return }

						observer.onNext(index)
						sleep(interval)
					}
				}

				if let error = error {
					observer.onError(error)
				} else {
					observer.onCompleted()
				}
			}

			return Disposables.create {
				disposed = true
			}
		}
	}

	static func createTask(source: Int, quantity: Int) -> Observable<String> {
		return RxObservableQueueTests.createObservable(quantity: quantity)
			.map { number -> String in
				return String("source: \(source) task: \(number)")
		}
	}

	func testSubscribe() {
		let bag = DisposeBag()

		var emittedCount = 0
		let emitQuantity = 9
		var completed = false

		RxObservableQueue
			.create(observable: RxObservableQueueTests.createObservable(quantity: emitQuantity), maxConcurrentCount: 3)
			.subscribe(onNext: { task, counter in
				emittedCount += 1

				// do some time-consuming task
				OperationQueue().addOperation {
					print("\(task) started")
					sleep(1)
					print("\(task) finished")

					// send signal() to pop next task from queue
					counter.signal()
				}
			}, onCompleted: {
				completed = true
			})
			.disposed(by: bag)

		RunLoop.current.run(until: Date(timeIntervalSinceNow: 5))

		XCTAssertEqual(emittedCount, emitQuantity)
		XCTAssertTrue(completed)
	}

	func testError() {
		let bag = DisposeBag()

		var emittedCount = 0
		let emitQuantity = 3
		var completed = false

		let tasks = RxObservableQueueTests.createObservable(quantity: emitQuantity, withError: NSError())

		RxObservableQueue
			.create(observable: tasks, maxConcurrentCount: 3)
			.subscribe(onNext: { task, counter in
				emittedCount += 1

				// do some time-consuming task
				OperationQueue().addOperation {
					print("\(task) started")
					sleep(1)
					print("\(task) finished")

					// send signal() to pop next task from queue
					counter.signal()
				}
			}, onError: { _ in
				completed = true
			})
			.disposed(by: bag)

		RunLoop.current.run(until: Date(timeIntervalSinceNow: 5))

		XCTAssertTrue(completed)
	}

	func testDispose() {
		var emittedCount = 0
		let emitQuantity = 9
		var completed = false

		let disposable = RxObservableQueue
			.create(observable: RxObservableQueueTests.createObservable(quantity: emitQuantity, interval: 1), maxConcurrentCount: 3)
			.subscribe(onNext: { task, counter in
				emittedCount += 1

				// do some time-consuming task
				OperationQueue().addOperation {
					print("\(task) started")
					sleep(1)
					print("\(task) finished")

					// send signal() to pop next task from queue
					counter.signal()
				}
			}, onCompleted: {
				completed = true
			})

		// wait until second item emitted
		RunLoop.current.run(until: Date(timeIntervalSinceNow: 1.5))

		disposable.dispose()

		// wait until second task finished
		RunLoop.current.run(until: Date(timeIntervalSinceNow: 1))

		XCTAssertEqual(emittedCount, 2)
		XCTAssertFalse(completed)
	}

	func testFlatMap() {
		let bag = DisposeBag()

		var emittedCount = 0
		let sourceQuantity = 3
		var completed = false

		let source = RxObservableQueueTests.createObservable(quantity: sourceQuantity, interval: 2)

		source
			.debug()
			.flatMapLatest { number -> Observable<(String, Counter)> in
				// creating tasks from sourceObservable
				let tasks = RxObservableQueueTests.createTask(source: number, quantity: 5)

				return RxObservableQueue.create(observable: tasks, maxConcurrentCount: 5)
			}
			.debug()
			.subscribe(onNext: { task, counter in
				emittedCount += 1

				// do some time-consuming task
				OperationQueue().addOperation {
					print("\(task) started")
					sleep(1)
					print("\(task) finished")

					// send signal() to pop next task from queue
					counter.signal()
				}
			}, onCompleted: {
				completed = true
			})
			.disposed(by: bag)

		RunLoop.current.run(until: Date(timeIntervalSinceNow: 13))

		XCTAssertEqual(emittedCount, 15)
		XCTAssertTrue(completed)
	}
}
