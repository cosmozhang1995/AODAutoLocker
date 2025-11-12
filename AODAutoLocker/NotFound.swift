import SwiftUI

struct NotFoundView: View {
    var body: some View {
        VStack {
            Image(systemName: "questionmark.circle.fill")
                .foregroundStyle(.white, .blue)
                .font(.system(size: 120))
            Spacer().frame(height: 20)
            Text("Opps, this page is lost")
        }
        .navigationTitle("Page not found")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        NotFoundView()
    }
}
