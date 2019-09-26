//
//  RACExtensions.swift
//  TestProject
//
//  Created by robert john alkuino on 25/09/2019.
//  Copyright © 2019 robert john alkuino. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result

private let userInteractiveQueue = DispatchQueue.global(qos: .userInteractive)
private let userInitiatedQueue = DispatchQueue.global(qos: .userInitiated)
private let backgroundQueue = DispatchQueue.global(qos: .background)

private let userInteractiveScheduler = QueueScheduler(qos: .userInteractive, name: "Interactive", targeting: userInteractiveQueue)
private let userInitiatedScheduler = QueueScheduler(qos: .userInitiated, name: "UserInitiated", targeting: userInitiatedQueue)
private let backgroundScheduler = QueueScheduler(qos: .background, name: "Background", targeting: backgroundQueue)


extension SignalProtocol {
    public func ignoreError() -> Signal<Value, NoError> {
        return Signal{ observer,sink in
            signal.observe { event in
                switch event {
                case .failed(_): break
                case let .value(val): observer.send(value: val)
                case .completed: observer.sendCompleted()
                case .interrupted: observer.sendInterrupted()
                }
            }
        }
    }
    
    public func transformToBool() -> Signal<Bool, NoError> {
        return Signal { observer,sink in
            signal.observe { event in
                switch event {
                case .failed(_): observer.send(value: false)
                case .value(_): break
                case .completed: observer.send(value: true)
                case .interrupted: observer.sendInterrupted()
                }
            }
        }
    }
    
    public func failedAsNext(fn: @escaping () -> Value) -> Signal<Value, NoError> {
        return Signal { observer,sink in
            signal.observe { event in
                switch event {
                case .failed(_): observer.send(value: fn())
                case let .value(val): observer.send(value: val)
                case .completed: observer.sendCompleted()
                case .interrupted: observer.sendInterrupted()
                }
            }
        }
    }
    
    public func completedAsNext() -> Signal<Void, Error> {
        return Signal { observer,sink in
            signal.observe { event in
                switch event {
                case let .failed(err): observer.send(error: err)
                case .value(_): break
                case .completed: observer.sendCompleted()
                case .interrupted: observer.sendInterrupted()
                }
            }
        }
    }
    
    public func nextAsCompleted() -> Signal<Void, Error> {
        return Signal { observer,sink in
            signal.observe { event in
                switch event {
                case let .failed(err): observer.send(error: err)
                case .value(_): observer.sendCompleted()
                case .completed: observer.sendCompleted()
                case .interrupted: observer.sendInterrupted()
                }
            }
        }
    }
    
    public func observeOnUserInteractive() -> Signal<Value, Error> {
        
        return signal.observe(on: userInteractiveScheduler)
    }
    
    public func observeOnUserInitiated() -> Signal<Value, Error> {
        return signal.observe(on: userInitiatedScheduler)
    }
    
    public func observeOnMain() -> Signal<Value, Error> {
        return signal.observe(on: UIScheduler())
    }
    
    public func observeOnBackground() -> Signal<Value, Error> {
        return signal.observe(on: backgroundScheduler)
    }
    
    public func retryUntil(interval: DispatchTimeInterval, onScheduler scheduler: DateScheduler, fn: @escaping () -> Bool) -> Signal<Value, Error> {
        
        return Signal { observer,sink in
            return signal.observe { event in
                switch event {
                case .failed, .interrupted:
                    scheduler.schedule {
                        observer.send(event)
                    }
                    
                default:
                    var schedulerDisposable: Disposable?
                    var retryAttempts = 100
                    schedulerDisposable = scheduler.schedule(after: scheduler.currentDate, interval: interval, leeway: interval, action: {
                        retryAttempts = retryAttempts - 1
                        if fn() || retryAttempts <= 0 {
                            observer.send(event)
                            schedulerDisposable?.dispose()
                        }
                    })
                }
            }
        }
    }
    
    public func delayLatestUntil<E>(triggerSignal: Signal<Bool, E>) -> Signal<Value, Error> {
        let (newSignal, newObserver) = Signal<Value, Error>.pipe()
        
        var passOn = false
        var latestValue: Value?
        
        signal.observe { event in
            if passOn {
                newObserver.send(event)
            } else if case .value(let val) = event {
                latestValue = val
            }
        }
        
        triggerSignal.observe { trigger in
            passOn = trigger.value!
            
            if trigger.value! {
                if let latestValue = latestValue {
                    newObserver.send(value: latestValue)
                }
                latestValue = nil
            }
        }
        
        return newSignal
    }
    
    public func delayAllUntil<E>(triggerSignal: Signal<Bool, E>) -> Signal<Value, Error> {
        let (newSignal, newObserver) = Signal<Value, Error>.pipe()
        
        var passOn = false
        var latestValues: [Value] = []
        
        signal.observe { event in
            if passOn {
                newObserver.send(event)
            } else if case let .value(val) = event {
                latestValues.append(val)
            }
        }
        
        triggerSignal.observeResult { trigger in
            passOn = trigger.value!
            
            if trigger.value! {
                for val in latestValues {
                    newObserver.send(value: val)
                }
                latestValues.removeAll()
            }
        }
        
        return newSignal
    }
    
}

public extension SignalProtocol where Value == Bool {
    
    func mapToTuple<T>(right: T, _ wrong: T) -> Signal<T, Error> {
        return signal.map { $0 ? right : wrong }
    }
    
}

public extension SignalProtocol where Value: Equatable {
    func equalsTo(value: Value) -> Signal<Bool, Error> {
        return signal.map({ next in next == value })
    }
    
    func filter(values: [Value]) -> Signal<Value, Error> {
        return signal.filter({ value in values.firstIndex { $0 == value } != nil })
    }
}

extension SignalProducerProtocol {
    public func ignoreError() -> SignalProducer<Value, NoError> {
        
        return producer.lift { $0.ignoreError() }
    }
    
    public func transformToBool() -> SignalProducer<Bool, NoError> {
        return producer.lift { $0.transformToBool() }
    }
    
    public func failedAsNext(fn: @escaping () -> Value) -> SignalProducer<Value, NoError> {
        return producer.lift { $0.failedAsNext(fn: fn) }
    }
    
    public func completedAsNext() -> SignalProducer<Void, Error> {
        return producer.lift { $0.completedAsNext() }
    }
    
    public func nextAsCompleted() -> SignalProducer<Void, Error> {
        return producer.lift { $0.nextAsCompleted() }
    }
    
    public func startOnUserInteractive() -> SignalProducer<Value, Error> {
        return producer.start(on: userInteractiveScheduler)
    }
    
    public func observeOnUserInteractive() -> SignalProducer<Value, Error> {
        return producer.lift { $0.observeOnUserInteractive() }
    }
    
    public func startOnUserInitiated() -> SignalProducer<Value, Error> {
        return producer.start(on: userInitiatedScheduler)
    }
    
    public func observeOnUserInitiated() -> SignalProducer<Value, Error> {
        return producer.lift { $0.observeOnUserInitiated() }
    }
    
    public func startOnMain() -> SignalProducer<Value, Error> {
        return producer.start(on: UIScheduler())
    }
    
    public func observeOnMain() -> SignalProducer<Value, Error> {
        return producer.lift { $0.observeOnMain() }
    }
    
    public func retryUntil(interval: DispatchTimeInterval, onScheduler scheduler: DateScheduler, fn: @escaping () -> Bool) -> SignalProducer<Value, Error> {
        return producer.lift { $0.retryUntil(interval: interval, onScheduler: scheduler, fn: fn) }
    }
    
    public func delayLatestUntil<E>(triggerProducer: SignalProducer<Bool, E>) -> SignalProducer<Value, Error> {
        return liftRight(transform: Signal.delayLatestUntil)(triggerProducer)
    }
    
    public func delayAllUntil<E>(triggerProducer: SignalProducer<Bool, E>) -> SignalProducer<Value, Error> {
        return liftRight(transform: Signal.delayAllUntil)(triggerProducer)
    }
    
    public static func fromValues(values: [Value]) -> SignalProducer<Value, Error> {
        return SignalProducer { sink, _ in
            for value in values {
                sink.send(value: value)
            }
            sink.sendCompleted()
        }
    }
    
    /// Right-associative lifting of a binary signal operator over producers. That
    /// is, the argument producer will be started before the receiver. When both
    /// producers are synchronous this order can be important depending on the operator
    /// to generate correct results.
    
    private func liftRight<U, F, V, G>(transform: @escaping (Signal<Value, Error>) -> (Signal<U, F>) -> Signal<V, G>) -> (SignalProducer<U, F>) -> SignalProducer<V, G> {
        return { otherProducer in
            return SignalProducer { observer, outerDisposable in
                self.producer.startWithSignal { signal, disposable in
                    outerDisposable.observeEnded {
                        disposable.dispose()
                    }
                    
                    otherProducer.startWithSignal { otherSignal, otherDisposable in
                        outerDisposable.observeEnded {
                            disposable.dispose()
                        }
                        
                        transform(signal)(otherSignal).observe(observer)
                    }
                }
            }
        }
    }
}

public extension SignalProducerProtocol where Value: Equatable {
    func equalsTo(value: Value) -> SignalProducer<Bool, Error> {
        return producer.lift { $0.equalsTo(value: value) }
    }
    
    func filter(values: [Value]) -> SignalProducer<Value, Error> {
        return producer.lift { $0.filter(values: values) }
    }
}

public extension SignalProducerProtocol where Value == Bool {
    
    func mapToTuple<T>(right: T, _ wrong: T) -> SignalProducer<T, Error> {
        return producer.lift { $0.mapToTuple(right: right, wrong) }
    }
    
}

