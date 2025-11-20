import SwiftUI

// MARK: - Control Grid
struct MenuControlGrid: View {
    @ObservedObject var manager: TunnelManager
    
    var body: some View {
        HStack(spacing: 0) {
            MenuGridButton(icon: "rectangle.grid.2x2.fill", title: "Panel", color: .blue) {
                NSApp.sendAction(#selector(AppDelegate.openDashboardWindowAction), to: nil, from: nil)
            }
            
            Divider().padding(.vertical, 8)
            
            MenuGridButton(icon: "play.fill", title: "Tümü Başlat", color: .green) {
                NSApp.sendAction(#selector(AppDelegate.startAllManagedTunnelsAction), to: nil, from: nil)
            }
            
            Divider().padding(.vertical, 8)
            
            MenuGridButton(icon: "stop.fill", title: "Tümü Durdur", color: .red) {
                NSApp.sendAction(#selector(AppDelegate.stopAllTunnelsAction), to: nil, from: nil)
            }
            
            Divider().padding(.vertical, 8)
            
            MenuGridButton(icon: "arrow.clockwise", title: "Yenile", color: .secondary) {
                NSApp.sendAction(#selector(AppDelegate.refreshManagedTunnelListAction), to: nil, from: nil)
            }
        }
        .frame(width: 240, height: 60)
    }
}

// MARK: - Creation Grid
struct MenuCreationGrid: View {
    var body: some View {
        HStack(spacing: 0) {
            MenuGridButton(icon: "bolt.fill", title: "Hızlı Tünel", color: .purple) {
                NSApp.sendAction(#selector(AppDelegate.openQuickTunnelWindowAction), to: nil, from: nil)
            }
            
            Divider().padding(.vertical, 8)
            
            MenuGridButton(icon: "plus.circle.fill", title: "Yeni Tünel", color: .blue) {
                NSApp.sendAction(#selector(AppDelegate.openCreateManagedTunnelWindowAction), to: nil, from: nil)
            }
            
            Divider().padding(.vertical, 8)
            
            MenuGridButton(icon: "server.rack", title: "MAMP", color: .orange) {
                NSApp.sendAction(#selector(AppDelegate.openCreateFromMampWindow), to: nil, from: nil)
            }
        }
        .frame(width: 240, height: 60)
    }
}

// MARK: - Footer Grid
struct MenuFooterGrid: View {
    var body: some View {
        HStack(spacing: 0) {
            MenuGridButton(icon: "gear", title: "Ayarlar", color: .secondary) {
                NSApp.sendAction(#selector(AppDelegate.openSettingsWindowAction), to: nil, from: nil)
            }
            
            Divider().padding(.vertical, 8)
            
            MenuGridButton(icon: "book.fill", title: "Kılavuz", color: .secondary) {
                NSApp.sendAction(#selector(AppDelegate.openSetupPdfAction), to: nil, from: nil)
            }
            
            Divider().padding(.vertical, 8)
            
            MenuGridButton(icon: "power", title: "Çıkış", color: .red) {
                NSApp.terminate(nil)
            }
        }
        .frame(width: 240, height: 50)
    }
}

// MARK: - Shared Button Component
struct MenuGridButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            // Close menu before action to prevent stuck menu
            NSApp.sendAction(#selector(NSMenu.cancelTracking), to: nil, from: nil)
            action()
        }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                    .scaleEffect(isHovering ? 1.1 : 1.0)
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isHovering ? Color.primary.opacity(0.05) : Color.clear)
            .animation(.spring(response: 0.3), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hover in
            isHovering = hover
        }
    }
}
