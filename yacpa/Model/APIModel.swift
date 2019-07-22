//
//  CurrentPrices.swift
//  yacpa
//
//  Created by Michael Gray on 7/19/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import Foundation


typealias ModelProperty<T> = CurrentValueSubject<T, Never>

protocol ModelType {
    associatedtype Failure: Error

    var currency: AnyPublisher<String, Never> { get }
    var currentPriceRefreshable: RefreshableValue<CurrentPrice, Failure> { get }
    var historicalPricesRefreshable: RefreshableValue<HistoricalClose, Failure> { get }
    var refreshRate: TimeInterval { get }

    func setRefreshRate(timeInterval: TimeInterval)
    func refresh()
}

extension ModelType {

    var currentPrice: AnyPublisher<CurrentPrice, Never> {
        return currentPriceRefreshable.values
    }
    var currentPriceError: AnyPublisher<Failure?, Never> {
        return currentPriceRefreshable.errors
    }

    var historicalPrices: AnyPublisher<HistoricalClose, Never> {
        return historicalPricesRefreshable.values
    }

    var historicalPricesErrors: AnyPublisher<Failure?, Never> {
        return historicalPricesRefreshable.errors
    }

    var isRefreshing: AnyPublisher<Bool, Never> {
        return Publishers
            .CombineLatest(currentPriceRefreshable.isRefreshing, historicalPricesRefreshable.isRefreshing)
            .map { $0 || $1 }
            .eraseToAnyPublisher()
    }


}

// why no protocol?  Why no
// So ... it's really nice to have @Published in a Model/ViewModel
// But you can't use propertyWrappers in a protocol definition.
// Need to figure out the balance between the desire to have 
final class APIModel<API: CoinDeskAPIType>: ModelType {

    let currency: AnyPublisher<String, Never>
    let currentPriceRefreshable: RefreshableValue<CurrentPrice, API.Failure>
    let historicalPricesRefreshable: RefreshableValue<HistoricalClose, API.Failure>

    private var currencySubject = CurrentValueSubject<String, Never>("EUR")
    private var cancelables = [AnyCancellable]()
    private var timerCancelable: AnyCancellable?

    var refreshRate: TimeInterval = 0.0 {
        didSet {
            self.timerCancelable?.cancel()
            if refreshRate > 0.0 {
                let sink = Timer
                    .publish(every: refreshRate, on: .main, in: .default)
                    .autoconnect()
                    .sink { [weak self] _ in
                        self?.currentPriceRefreshable.refresh()
                    }
                self.timerCancelable = AnyCancellable(sink)
            } else {
                self.timerCancelable = nil
            }
        }
    }

    init(api: API.Type) {

        currentPriceRefreshable = RefreshableValue {
            api.shared.currentPrice()
        }

        let innerCurrency = currencySubject.print("Model.currencySubject")
        currency = currencySubject.print("Model.currency").eraseToAnyPublisher()
        historicalPricesRefreshable = RefreshableValue {
            innerCurrency.flatMap {
                api.shared.historicalClose(currency: $0).mapToResults()
            }
            .print("innerHistory:")
        }
        self.refresh()
    }

    func setRefreshRate(timeInterval: TimeInterval) {
        self.refreshRate = timeInterval
    }

    func refresh() {
        currentPriceRefreshable.refresh()
        historicalPricesRefreshable.refresh()
    }
}