//
//  PriceListRow.swift
//  yacpa
//
//  Created by Michael Gray on 7/22/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import Foundation
import SwiftUI


final class PriceListRowViewModel<Model: ModelType>: BindableObject, Hashable, Identifiable {

    let willChange = PassthroughSubject<Void, Never>()
    var price: String {
        willSet {
            willChange.send()
        }
    }
    var date: Date {
        willSet {
            willChange.send()
        }
    }
    var showMinutes: Bool {
        willSet {
            willChange.send()
        }
    }

    var dateString: String {
        if showMinutes {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .medium
            formatter.doesRelativeDateFormatting = true
            return formatter.string(from: self.date)

        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.doesRelativeDateFormatting = true
            return formatter.string(from: self.date)
        }
    }

    init(price: String, date: Date, showMinutes: Bool = false) {
        // NOTE is is better or not to call 'willChange.send()' here?
        // I like that it only triggers once, but it's confusing that it's sent BEFORE the data is changed.
        // I'm also worried of removing the 'didSet' operations cause what if you forget to trugger it here?
        self.price = price
        self.date = date
        self.showMinutes = showMinutes
    }

    // viewModels begatting viewModels.
    var historicalDetailViewModel: HistoricalDetailViewModel<Model> {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: self.date)
        return HistoricalDetailViewModel(dateString: dateString)
    }


    func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(price)
    }
    static func == (lhs: PriceListRowViewModel, rhs: PriceListRowViewModel) -> Bool {
        lhs.date == rhs.date && lhs.price == rhs.price
    }
}

struct PriceListRow<Model: ModelType>: View {
    @ObjectBinding var viewModel: PriceListRowViewModel<Model>

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("\(viewModel.price)")
            Spacer()
            Text("\(viewModel.dateString)")
        }
    }
}
