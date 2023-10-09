//
//  ContentView.swift
//  iOS Demo
//
//  Created by Ian Wagner on 2023-10-09.
//

import SwiftUI
import CoreLocation
import FerrostarCore
import FerrostarMapLibreUI

let style = URL(string: "https://tiles.stadiamaps.com/styles/outdoors.json?api_key=\(stadiaMapsAPIKey)")!

struct LocationIdentifier : Identifiable, Equatable, Hashable {
    static func == (lhs: LocationIdentifier, rhs: LocationIdentifier) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    let id = UUID()
    let name: String
    let location: CLLocationCoordinate2D
}

let locations = [
    LocationIdentifier(name: "Cupertino HS", location: CLLocationCoordinate2D(latitude: 37.31910, longitude: -122.01018)),
]


struct LocationSelectionView: View {
    @StateObject private var locationManager = LiveLocationProvider(activityType: .otherNavigation)
    @State private var ferrostarCore: FerrostarCore!
    @State private var isFetchingRoutes = false
    @State private var routes: [Route]?
    @State private var errorMessage: String?

    var body: some View {
        let locationServicesEnabled = locationManager.authorizationStatus == .authorizedAlways || locationManager.authorizationStatus == .authorizedWhenInUse

        NavigationStack {
            VStack(spacing: 15) {
                Image(systemName: locationServicesEnabled ? "location.fill" : "location.slash.fill")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                Text("Location services \(locationServicesEnabled ? "available" : "unavailable")")
                Text("\(locationManager.lastLocation?.description ?? "Location unknown")")
                    .fontDesign(.monospaced)

                if locationServicesEnabled && locationManager.lastLocation != nil && !isFetchingRoutes {
                    ForEach(locations) { loc in
                        Button(loc.name) {
                            let userLocation = locationManager.lastLocation!
                            if ferrostarCore == nil {
                                ferrostarCore = FerrostarCore(valhallaEndpointUrl: URL(string: "https://api.stadiamaps.com/route/v1?api_key=\(stadiaMapsAPIKey)")!, profile: "pedestrian", locationManager: locationManager)
                            }

                            Task {
                                do {
                                    routes = try await ferrostarCore.getRoutes(initialLocation: userLocation, waypoints: [loc.location])

                                    // TODO: Show a preview with selectable routes
                                    try ferrostarCore.startNavigation(route: routes!.first!, stepAdvance: .relativeLineStringDistance(minimumHorizontalAccuracy: 32, automaticAdvanceDistance: 10))

                                    errorMessage = nil
                                } catch {
                                    errorMessage = "Error: \(error)"
                                }
                            }
                        }
                    }
                }

                if ferrostarCore?.observableState != nil {
                    NavigationLink("Navigate") {
                        NavigationMapView(lightStyleURL: style, darkStyleURL: style, navigationState: ferrostarCore.observableState!)
                            .overlay(alignment: .bottomLeading) {
                                if let location = locationManager.lastLocation {
                                    VStack {
                                        Text("±\(Int(location.horizontalAccuracy))m accuracy")
                                            .foregroundColor(.white)
                                    }
                                    .padding(.all, 8)
                                    .background(Color.black.opacity(0.7).clipShape(.buttonBorder, style: FillStyle()))
                                }
                            }
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .fontDesign(.monospaced)
                }
            }
            .padding()
        }
    }
}

#Preview {
    LocationSelectionView()
}
