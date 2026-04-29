import MapKit
import SwiftUI

struct WhiskedMapView: View {
    @Environment(LocationStore.self) private var locations

    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 53.5342, longitude: -113.5161),
            span:   MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
        )
    )

    var body: some View {
        @Bindable var locations = locations

        Map(position: $position, selection: $locations.selectedLocation) {
            ForEach(locations.locations) { location in
                Annotation(
                    location.name,
                    coordinate: location.coordinate,
                    anchor: .bottom
                ) {
                    WhiskedPin(location: location, isSelected: locations.selectedLocation?.id == location.id)
                }
                .tag(location)
            }
            UserAnnotation()
        }
        .mapStyle(.standard(pointsOfInterestFilter: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
                .mapControlVisibility(.hidden)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Pin

private struct WhiskedPin: View {
    let location:   WhiskedLocation
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.whisked.amber : .white)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                Image(systemName: "bell.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Color.whisked.amber)
            }

            // Callout label on selection
            if isSelected {
                Text(location.type.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.whisked.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.whisked.cream, in: Capsule())
                    .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                    .padding(.top, 4)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
