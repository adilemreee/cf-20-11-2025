# 🌥️ Cloudflared Manager

<div align="center">

![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)
![Version](https://img.shields.io/badge/Version-1.0.0-red.svg)

**macOS için Modern Cloudflare Tunnel Yönetim Uygulaması**

*Web projelerinizi, SSH bağlantılarınızı ve veritabanlarınızı güvenle internete açın*

[Özellikler](#-özellikler) • [Kurulum](#-kurulum) • [Kullanım](#-kullanım) • [SSH Tünelleme](#-ssh-tünelleme)

</div>

---

## 🎯 **Ne İşe Yarar?**

Cloudflared Manager, yerel bilgisayarınızdaki servisleri **güvenli bir şekilde** internete açmanızı sağlar:

- 🌐 **Web Siteleri**: localhost:3000 → https://myapp.com
- 🔐 **SSH Bağlantısı**: Mac'inize dünyanın her yerinden bağlanın
- 💾 **Veritabanları**: MySQL, PostgreSQL, MongoDB erişimi
- 🐳 **Docker Container'lar**: Projelerinizi anında paylaşın
- 📁 **Dosya Paylaşımı**: Klasörleri web üzerinden paylaşın

**Firewall ayarı, port forwarding veya public IP gerektirmez!**

---

## 📸 **Ekran Görüntüleri**

<div align="center">

### Ana Gösterge Paneli

<img src="assets/Screenshot 2025-11-20 at 19.39.34.png" alt="Dashboard" width="800"/>

*Modern, kullanıcı dostu arayüz ile tüm tünellerinizi tek yerden yönetin*

---

### Yolları Seçme ve Görünüm

<table>
  <tr>
    <td width="50%">
      <img src="assets/Screenshot 2025-11-20 at 19.39.40.png" alt="Tunnel Management"/>
      <p align="center"><b>Yollar</b></p>
    </td>
    <td width="50%">
      <img src="assets/Screenshot 2025-11-20 at 19.39.44.png" alt="Create Tunnel"/>
      <p align="center"><b>Görünüm</b></p>
    </td>
  </tr>
</table>

---

### Bildirim ve Geçmiş

<table>
  <tr>
    <td width="50%">
      <img src="assets/Screenshot 2025-11-20 at 19.39.46.png" alt="Quick Tunnel"/>
      <p align="center"><b>Bildirim</b></p>
      <p align="center"><i>Tek Tıkla Bildirim Ayarları</i></p>
    </td>
    <td width="50%">
      <img src="assets/Screenshot 2025-11-20 at 19.39.53.png" alt="MAMP Integration"/>
      <p align="center"><b>Geçmiş</b></p>
      <p align="center"><i>Log ve Bildirim Kayıtları</i></p>
    </td>
  </tr>
</table>

---

### Yedekleme

<img src="assets/Screenshot 2025-11-20 at 19.39.56.png" alt="File Sharing" width="700"/>

*Tünellerinizi ve Config Ayarlarınızı Yedekleyin*

---

### Ayarlar ve Özelleştirme

<table>
  <tr>
    <td width="50%">
      <img src="assets/Screenshot 2025-11-20 at 19.39.58.png" alt="Settings"/>
      <p align="center"><b>Gelişmiş Ayarlar</b></p>
    </td>
    <td width="50%">
      <img src="assets/Screenshot 2025-11-20 at 19.40.02.png" alt="Theme Settings"/>
      <p align="center"><b>Hakkında</b></p>
    </td>
  </tr>
</table>

---

### Menü Çubuğu Entegrasyonu

<img src="assets/Screenshot 2025-11-20 at 19.40.09.png" alt="Menu Bar" width="500"/>

*macOS menü çubuğundan hızlı erişim - tüm kontroller elinizin altında*

</div>

---

## ✨ **Özellikler**

### 🌐 **3 Tür Tünel Desteği**

#### **HTTP/HTTPS Tünelleri** 
- Web uygulamalarınızı paylaşın
- React, Vue, Next.js development server'ları
- MAMP/Docker projeleri

#### **TCP Tünelleri (SSH, Database)**
- 🔐 SSH: Mac'inize uzaktan bağlanın
- 💾 MySQL, PostgreSQL, MongoDB
- 🖥️ RDP (Windows Remote Desktop)
- 🎮 Oyun sunucuları

#### **Hızlı Tüneller (Geçici)**
- Tek tıkla geçici URL oluşturun
- Kimlik doğrulama gerektirmez
- Demo ve test için ideal

### 🎨 **Modern Arayüz**
- Menu bar entegrasyonu
- Dark/Light mode desteği
- 11 farklı renk teması
- Gerçek zamanlı durum göstergeleri

### 🔧 **Otomatik Yapılandırma**
- MAMP projeleri için otomatik setup
- Apache vHost güncellemesi
- DNS kayıtları yönetimi
- Yedekleme ve geri yükleme

---

## 💻 **Sistem Gereksinimleri**

- **macOS**: 13.0 (Ventura) veya üzeri
- **İşlemci**: Intel veya Apple Silicon
- **RAM**: 4 GB minimum
- **Cloudflare Hesabı**: Ücretsiz plan yeterli
- **İnternet Bağlantısı**: Sürekli aktif olmalı

---

## 🚀 **Kurulum (3 Adımda)**

### **1. Uygulamayı İndirin**
```bash
# GitHub Releases sayfasından DMG dosyasını indirin
# Applications klasörüne sürükleyin
```

### **2. Cloudflared Kurun**
```bash
# Homebrew ile (önerilen):
brew install cloudflare/cloudflare/cloudflared

# Veya Manuel:
# https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/
```

### **3. Cloudflare'e Giriş Yapın**
```bash
# Terminal'de:
cloudflared login

# Browser açılacak → Domain seçin → Yetkilendirin
```

**Hazır!** Artık uygulamayı kullanabilirsiniz.

---

## 📚 **Hızlı Kullanım**

### **🌐 Web Sitesi Paylaşmak**

```
1. Menu Bar → Hızlı Tünel
2. URL: http://localhost:3000
3. Başlat
→ https://random.trycloudflare.com linki alırsınız
```

**Kullanım Alanları:**
- React/Vue/Angular development server
- MAMP projeleri
- Docker container'lar
- Node.js/Python uygulamaları

---

### **🔐 SSH Tünelleme (Uzak Erişim)**

Mac'inize dünyanın her yerinden SSH ile bağlanın:

#### **Sunucu Tarafı (Mac'inizde):**

1. **SSH'ı Aktif Edin:**
   ```
   System Settings → General → Sharing → Remote Login: ON
   ```

2. **SSH Tüneli Oluşturun:**
   ```
   Menu Bar → Yönetilen Tünel Oluştur
   
   Tünel Adı: mac-ssh
   Hostname: ssh.yourdomain.com
   Port: 22
   Protocol: TCP ← ÖNEMLİ!
   ```

3. **DNS Yönlendirmesi:**
   ```
   Tünel oluştuktan sonra:
   → Tünele sağ tık → DNS Kaydı Yönlendir
   ```

4. **Tüneli Başlatın:**
   ```
   Menu Bar → Tünelin yanındaki ▶️ butonuna tıklayın
   ```

#### **İstemci Tarafı (Bağlanacak Bilgisayar):**

```bash
# 1. cloudflared kurun (tek sefer):
brew install cloudflare/cloudflare/cloudflared

# 2. SSH config oluşturun (tek sefer):
mkdir -p ~/.ssh && touch ~/.ssh/config && chmod 600 ~/.ssh/config
cloudflared access ssh-config --hostname ssh.yourdomain.com >> ~/.ssh/config

# 3. Bağlanın:
ssh kullanici@ssh.yourdomain.com
```

#### **Mobil Cihazlardan SSH:**

**Android:** Termux uygulamasında cloudflared kurabilirsiniz
```bash
pkg install wget
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64
chmod +x cloudflared-linux-arm64
mv cloudflared-linux-arm64 $PREFIX/bin/cloudflared
ssh kullanici@ssh.yourdomain.com
```

**iOS:** Mac'inizde proxy başlatın, Termius ile localhost:2222'ye bağlanın
```bash
# Mac'te:
cloudflared access tcp --hostname ssh.yourdomain.com --url 0.0.0.0:2222

# iPhone'da Termius:
Host: [Mac'in yerel IP'si]
Port: 2222
```

---

### **💾 Veritabanı Tünelleme**

MySQL, PostgreSQL veya MongoDB'yi internete açın:

```
Menu Bar → Yönetilen Tünel Oluştur

Tünel Adı: mysql-tunnel
Hostname: db.yourdomain.com
Port: 3306 (MySQL) / 5432 (PostgreSQL) / 27017 (MongoDB)
Protocol: TCP
```

**Bağlantı:**
```bash
# İstemci tarafında:
cloudflared access tcp --hostname db.yourdomain.com --url localhost:3306

# Başka terminal'de:
mysql -h 127.0.0.1 -P 3306 -u root -p
```

---

## ⚙️ **Ayarlar ve Özelleştirme**

### **Genel Ayarlar**
```
Menu Bar → Settings → Genel

- Cloudflared yolu
- Otomatik başlatma
- Menu bar ikonu
- Bildirimler
```

### **Tema Sistemi**
```
Settings → Görünüm

- 🌓 Sistem / Açık / Koyu tema
- 🎨 11 farklı vurgu rengi
- Dark mode desteği
```

### **MAMP Entegrasyonu**
```
Settings → Yollar

- MAMP dizini: /Applications/MAMP
- Apache config otomatik güncelleme
- vHost yönetimi
```

### **Yedekleme**
```
Settings → Yedekleme

- Tünel yapılandırmalarını yedekle
- Otomatik yedekleme
- Geri yükleme
```

---

## 🔧 **Sorun Giderme**

### **cloudflared bulunamadı**
```bash
# Kurulumu kontrol edin:
which cloudflared

# Yoksa kurun:
brew install cloudflare/cloudflare/cloudflared
```

### **Tünel oluşturulamıyor**
```bash
# Cloudflare'e giriş yapın:
cloudflared login

# Credentials kontrol:
ls -la ~/.cloudflared/
```

### **SSH bağlantısı çalışmıyor**
```bash
# İstemci tarafında:
# 1. cloudflared kurulu mu kontrol:
which cloudflared

# 2. SSH config kontrol:
cat ~/.ssh/config

# 3. Tünelin çalıştığını kontrol:
# Sunucu Mac'te tünel yeşil ✓ olmalı
```

### **Port zaten kullanımda**
```bash
# Hangi uygulama kullanıyor:
lsof -i :PORT_NUMBER

# Kapatmak için:
kill -9 PID
```

### **MAMP entegrasyonu hatası**
```bash
# MAMP yolunu kontrol:
ls /Applications/MAMP

# Apache yeniden başlat:
/Applications/MAMP/bin/stop.sh
/Applications/MAMP/bin/start.sh
```

---

## ❓ **Sık Sorulan Sorular**

### **Farklı ağdan bağlanabilir miyim?**
✅ Evet! Cloudflare Tunnel, firewall veya router ayarı gerektirmez. Dünyanın her yerinden bağlanabilirsiniz.

### **Telefondan SSH yapabilir miyim?**
✅ **Android:** Termux uygulamasında cloudflared kurarak doğrudan bağlanabilirsiniz.  
⚠️ **iOS:** Proxy setup gerekir (yukarıdaki SSH bölümüne bakın).

### **MAMP gerekli mi?**
❌ Hayır. MAMP opsiyoneldir. Her tür web server veya uygulama desteklenir.

### **Güvenli mi?**
✅ Evet! 
- End-to-end şifreleme
- Firewall port açmaya gerek yok
- Cloudflare DDoS koruması
- Zero Trust güvenlik modeli

### **Ücretsiz mi?**
✅ Cloudflare Free plan yeterli. Sınırsız tünel oluşturabilirsiniz.

### **Hangi protokoller destekleniyor?**
- ✅ HTTP/HTTPS (web siteleri)
- ✅ TCP (SSH, database, RDP)
- ❌ UDP (şu an desteklenmiyor)

### **Hız sınırı var mı?**
Cloudflare Free plan'da bandwidth limiti yok. Ağ hızınız kadar hızlı çalışır.

---

## 🔬 **Teknik Detaylar**

### **Mimari**
- **SwiftUI + MVVM**: Modern, reactive UI
- **Combine Framework**: Asynchronous işlemler
- **AppKit Integration**: macOS menu bar desteği
- **Process Management**: Cloudflared process yönetimi

### **Kullanılan Teknolojiler**
- Swift 5.9
- SwiftUI 4.0
- macOS 13.0+ SDK
- Cloudflared CLI

### **Güvenlik**
- Sandbox compliance
- Secure credential storage
- Input validation
- Cloudflare end-to-end encryption

---

## 📄 **Lisans**

MIT License - Copyright (c) 2025 Adil Emre Karayürek

---

## 🙏 **Teşekkürler**

- **Cloudflare Team** - Tunnel teknolojisi
- **Apple** - SwiftUI framework
- **Open Source Community** - İlham veren projeler

---

## 📞 **Destek**

- 🐛 **Bug Report**: [GitHub Issues](https://github.com/yourusername/cloudflared-manager/issues)
- 📚 **Dokümantasyon**: [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)

---

<div align="center">

**Made with ❤️ by Adil Emre**

⭐ **Projeyi beğendiyseniz GitHub'da star vermeyi unutmayın!**

</div>
