//
//  RxQueue.swift
//  RxQueue
//
//  Created by Hiroshi Noto on 2017/05/09.
//  Copyright © 2017 Hiroshi Noto. All rights reserved.
//

import Foundation

import RxSwift

class RxQueue<E> {
	static func create(observable: Observable<E>, semaphore: DispatchSemaphore) -> Observable<E> {
		return Observable.create { observer in
			var queue = [E]()
			var completed = false
			let accessSemaphore = DispatchSemaphore(value: 1)

			let disposable = observable
				.subscribe(onNext: { element in
					accessSemaphore.wait()
					queue.append(element)
					accessSemaphore.signal()
				}, onError: { _ in
					accessSemaphore.wait()
					completed = true
					accessSemaphore.signal()
				}, onCompleted: {
					accessSemaphore.wait()
					completed = true
					accessSemaphore.signal()
				}, onDisposed: nil
				)

			let opQueue = OperationQueue()
			opQueue.qualityOfService = .background
			opQueue.addOperation {
				while !(queue.count == 0 && completed) {
					semaphore.wait()

					accessSemaphore.wait()

					if queue.count != 0 {
						let element = queue.removeFirst()
						observer.onNext(element)
					} else {
						semaphore.signal()
					}

					accessSemaphore.signal()
				}

				disposable.dispose()
				observer.onCompleted()
			}

			return Disposables.create {
				accessSemaphore.wait()

				completed = true
				queue.removeAll()

				accessSemaphore.signal()
			}
		}
	}
}
