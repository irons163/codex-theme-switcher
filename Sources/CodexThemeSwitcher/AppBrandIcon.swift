import SwiftUI

struct AppBrandIcon: View {
    let height: CGFloat

    var body: some View {
        Image("MenuBarIcon", bundle: .module)
            .resizable()
            .renderingMode(.original)
            .interpolation(.high)
            .scaledToFit()
            .frame(height: height)
    }
}
