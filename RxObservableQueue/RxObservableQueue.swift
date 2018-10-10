//
//  RxObservableQueue.swift
//  RxObservableQueue
//
//  Created by Hiroshi Noto on 2017/05/09.
//  Copyright © 2017 Hiroshi Noto. All rights reserved.
//

import Foundation

import RxSwift

open class Counter {
	var count = 0
	var maxCount: Int
	let semaphore = DispatchSemaphore(value: 1)

	init(maxCouncurrentCount: Int) {
		maxCount = maxCouncurrentCount
	}

	func up() -> Bool {
		var ret = false

		semaphore.wait()
		if count < maxCount {
			count += 1
			ret = true
		}
		semaphore.signal()

		return ret
	}

	open func signal() {
		semaphore.wait()
		if count > 0 {
			count -= 1
		}
		semaphore.signal()
	}
}

open class RxObservableQueue<E> {
	enum State {
		case subscribing
		case disposed
	}

	enum Result {
		case error(error: Error)
		case completed
	}

	// swiftlint:disable:next function_body_length
    public static func create(observable: Observable<E>, maxConcurrentCount: Int) -> Observable<(E, Counter)> {
		return Observable.create { observer in
			var queue = [E]()
			var state = State.subscribing
			var observableResult: Result?
			let counter = Counter(maxCouncurrentCount: maxConcurrentCount)
			let semaphore = DispatchSemaphore(value: 1)

			var disposable: Disposable? = observable
				.subscribe(onNext: { element in
					semaphore.wait()
					if observableResult == nil { queue.append(element) }
					semaphore.signal()
				}, onError: { error in
					semaphore.wait()
					observableResult = .error(error: error)
					semaphore.signal()
				}, onCompleted: {
					semaphore.wait()
					observableResult = .completed
					semaphore.signal()
				}, onDisposed: nil)

			let opQueue = OperationQueue()
			opQueue.qualityOfService = .background
			opQueue.addOperation {
				// (queue.count == 0 && observableResult != nil) means queue will never be added any more.
				while !(queue.count == 0 && observableResult != nil) {
					semaphore.wait()

					if case .disposed = state {
						semaphore.signal()
						break
					}

					if queue.count != 0 && counter.up() {
						let element = queue.removeFirst()
						OperationQueue().addOperation { observer.onNext((element, counter)) }
					}

					semaphore.signal()
				}

				semaphore.wait()
				switch state {
				case .subscribing:
					switch observableResult {
					case .some(.completed):
						OperationQueue().addOperation { observer.onCompleted() }
					case let .some(.error(error)):
						OperationQueue().addOperation { observer.onError(error) }
					default:
						OperationQueue().addOperation { observer.onError(NSError()) }
					}
				case .disposed:
					break
				}
				semaphore.signal()
			}

			return Disposables.create {
				semaphore.wait()

				if case .subscribing = state {
					disposable?.dispose()
					disposable = nil
					queue.removeAll()
					state = .disposed
				}

				semaphore.signal()
			}
		}
	}
}
