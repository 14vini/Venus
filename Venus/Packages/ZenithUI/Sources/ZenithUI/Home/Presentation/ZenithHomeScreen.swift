import SwiftUI

struct ZenithHomeScreen: View {
    let userName: String

    @StateObject private var viewModel = ZenithHomeViewModel()

    var body: some View {
        ZenithHomeView(
            userName: userName,
            viewModel: viewModel
        )
    }
}

#Preview {
    NavigationStack {
        ZenithHomeScreen(userName: "Kaua")
    }
}

