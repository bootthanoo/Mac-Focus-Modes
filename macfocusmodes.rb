class Macfocusmodes < Formula
  desc "macOS Focus Modes manager that configures dock and wallpaper based on focus state"
  homepage "https://github.com/bootthanoo/Mac-Focus-Modes"
  url "https://github.com/bootthanoo/Mac-Focus-Modes/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "ff155773aee8cab27ae015f4359449f33639cb7258e518ebc9bc5b33e2cdf27e"
  license "MIT"

  depends_on "dockutil"
  depends_on "yq"
  depends_on "jq"

  def install
    bin.install "macfocusmodes.sh" => "macfocusmodes"
    (var/"log").mkpath
    touch "#{var}/log/macfocusmodes.log"
    chmod 0644, "#{var}/log/macfocusmodes.log"
    (prefix/"homebrew.mxcl.macfocusmodes.plist").write service_plist
  end

  def service_plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>#{plist_name}</string>
        <key>ProgramArguments</key>
        <array>
          <string>#{opt_bin}/macfocusmodes</string>
        </array>
        <key>KeepAlive</key>
        <true/>
        <key>RunAtLoad</key>
        <true/>
        <key>StandardErrorPath</key>
        <string>#{var}/log/macfocusmodes.log</string>
        <key>StandardOutPath</key>
        <string>#{var}/log/macfocusmodes.log</string>
        <key>ProcessType</key>
        <string>Background</string>
      </dict>
      </plist>
    EOS
  end

  def caveats
    <<~EOS
      To start macfocusmodes now and restart at login:
        brew services start macfocusmodes

      To stop the service:
        brew services stop macfocusmodes

      Configuration files will be stored in:
        ~/.config/macfocusmodes/
    EOS
  end
end 