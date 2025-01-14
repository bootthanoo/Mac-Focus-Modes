class Macfocusmodes < Formula
  desc "macOS Focus Modes manager that configures dock and wallpaper based on focus state"
  homepage "https://github.com/bootthanoo/Mac-Focus-Modes"
  url "https://github.com/bootthanoo/Mac-Focus-Modes/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "afcb76a4c13ac72ca77d4e0c36f8b89142bc9245f02ed6078c479f90d371bd31"
  license "MIT"

  depends_on "dockutil"
  depends_on "yq"
  depends_on "jq"

  def install
    bin.install "macfocusmodes.sh" => "macfocusmodes"
  end

  service do
    run [opt_bin/"macfocusmodes"]
    keep_alive true
    log_path var/"log/macfocusmodes.log"
    error_log_path var/"log/macfocusmodes.log"
    working_dir HOMEBREW_PREFIX
    environment_variables PATH: std_service_path_env
    run_type :immediate
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