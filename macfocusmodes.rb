class Macfocusmodes < Formula
  desc "Automatically configure your Mac's environment based on Focus modes"
  homepage "https://github.com/bootthanoo/Mac-Focus-Modes"
  url "https://github.com/bootthanoo/Mac-Focus-Modes/archive/refs/tags/v1.0.1.tar.gz"
  sha256 "406ebf5cc9f7f0f30a22e22a307506fcac04f41d15cf2fb123fb07b30387a5a9"
  license "MIT"

  depends_on "dockutil"
  depends_on "jq"
  depends_on "yq"

  def install
    bin.install "macfocusmodes.sh" => "macfocusmodes"
  end

  service do
    require_root false
    process_type :background
    run [opt_bin/"macfocusmodes"]
    keep_alive true
    log_path var/"log/macfocusmodes.log"
    error_log_path var/"log/macfocusmodes.log"
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