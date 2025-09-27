//
//  TodaysMemoryView.swift
//  iSeeFit
//
//  Created by VirginiaZheng on 2025-09-20.
//

import SwiftUI

struct TodaysMemoryView: View {
    @State private var scrollOffset: CGFloat = 0
    // Weight feature sheets (debug-logs enabled)
    @State private var showWeightInput: Bool = false
    //@State private var showWeightChart: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TodaysMemoryBkCard(externalScrollOffset: scrollOffset)
                
                ScrollView {
                   // contentView()
                    TodayView()
                        .background(GeometryReader { geo in
                            Color.clear.onAppear {
                                scrollOffset = geo.frame(in: .global).minY
                            }
                            .onChange(of: geo.frame(in: .global).minY) {
                                scrollOffset = geo.frame(in: .global).minY
                            }
                        })
                }
                // Floating action buttons inside scroll area (top-right)
                .overlay(alignment: .topTrailing) {
                    HStack(spacing: 12) {
                        Button(action: {
                            print("DEBUG: TodaysMemoryView - weight input button tapped")
                            showWeightInput = true
                        }) {
                            Image(systemName: "scalemass.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.blue.opacity(0.9))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 12)
                }
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showWeightInput) {
            WeightInputView()
        }
    }
}



struct TodaysMemoryView_Previews: PreviewProvider {
    static var previews: some View {
        TodaysMemoryView()
    }
}
