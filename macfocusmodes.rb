class Macfocusmodes < Formula
  desc "macOS Focus Modes manager that configures dock/wallpaper based on focus state"
  homepage "https://github.com/bootthanoo/Mac-Focus-Modes"
  url "https://github.com/bootthanoo/Mac-Focus-Modes/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "a23ccf7817588f61f468440497527f64e730b093cef5dc423808b723a9608a32"
  license "MIT"

  depends_on "dockutil"
  depends_on "yq"
  depends_on "jq"

  def install
    bin.install "macfocusmodes.sh" => "macfocusmodes"
    chmod 0755, bin/"macfocusmodes"
  end

  service do
    run [opt_bin/"macfocusmodes"]
    environment_variables PATH: std_service_path_env
    require_root false
    keep_alive true
    process_type :background
    working_dir HOMEBREW_PREFIX
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