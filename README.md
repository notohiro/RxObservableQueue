# RxObservableQueue

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/RxObservableQueue.svg)](https://img.shields.io/cocoapods/v/RxObservableQueue.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/RxObservableQueue.svg?style=flat)](http://cocoapods.org/pods/RxObservableQueue)

With RxObservableQueue, you can mange Observables as Queue.
RxObservableQueue is thin wrapper for containing _emitted_ objects and _emitting_ objects when desired.

## Features

<img src="https://raw.githubusercontent.com/notohiro/RxObservableQueue/master/picture.png" width="603">

## Requirements

- iOS 8.0+
- Xcode 8.0+
- RxSwift

## Installation

RxObservableQueue is available through [CocoaPods](http://cocoapods.org) and [Carthage](https://github.com/Carthage/Carthage).

### CocoaPods

To install, simply add the following line to your `Podfile`:

> CocoaPods 0.39.0+ is required to build NowCastMapView.

```ruby
platform :ios, '8.0'
use_frameworks!

pod 'RxObservableQueue'
```

### Carthage

To integrate RxObservableQueue into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "notohiro/RxObservableQueue"
```

Run `carthage update` to build the framework and drag the built `RxObservableQueue.framework` into your Xcode project.

## Usage

### Initialize with Observable and the number of concurrency.

```Swift
queue = RxObservableQueue
  .create(observable: someObservable, maxConcurrentCount: 3)
```

### Subscribe and send signal() when you need next object.

```Swift
queue.subscribe(onNext: { item, counter in
  // do some time-consuming task
  doSomeOperation(item) {
    // send signal() to pop next task from queue
    counter.signal()
  }
  })
  .addDisposableTo(bag)
```

## Author

[![Twitter](https://img.shields.io/badge/twitter-@notohiro-blue.svg?style=flat)](http://twitter.com/notohiro)

## License

RxObservableQueue is available under the MIT license. See the LICENSE file for more info.
