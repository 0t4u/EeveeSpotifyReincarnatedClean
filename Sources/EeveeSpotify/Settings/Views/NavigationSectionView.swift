import SwiftUI
import UIKit

enum EeveeSettingsIcon {
    static func image(named name: String, fallback: String = "circle.fill") -> UIImage? {
        UIImage(systemName: name) ?? UIImage(systemName: fallback)
    }
}

struct EeveeSettingsIconView: View {
    let name: String
    let color: Color

    var body: some View {
        if let image = EeveeSettingsIcon.image(named: name) {
            Image(uiImage: image)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(color)
        }
    }
}

struct NavigationSectionView: View {
    var color: Color
    var title: String
    var imageSystemName: String
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .foregroundColor(color)
                
                EeveeSettingsIconView(name: imageSystemName, color: .white)
            }
            .frame(width: 30, height: 30)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            ChevronRightView()
        }
    }
}
