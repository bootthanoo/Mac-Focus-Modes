class Macfocusmodes < Formula
  desc "macOS Focus Modes manager that configures dock/wallpaper based on focus state"
  homepage "https://github.com/bootthanoo/Mac-Focus-Modes"
  url "https://github.com/bootthanoo/Mac-Focus-Modes/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "bd97f7ec46ef0b3963cfe2bc11ba5fd6b93bdeaed117aaf931cd2e0308c3ad34"
  license "MIT"

  depends_on "dockutil"
  depends_on "yq"
  depends_on "jq"

  def install
    bin.install "macfocusmodes.sh" => "macfocusmodes"
    chmod 0755, bin/"macfocusmodes"
    (var/"log/macfocusmodes").mkpath
  end

  service do
    run ["/bin/zsh", opt_bin/"macfocusmodes"]
    environment_variables PATH: std_service_path_env,
                         HOME: ENV["HOME"],
                         SHELL: "/bin/zsh"
    require_root false
    keep_alive true
    process_type :background
    working_dir HOMEBREW_PREFIX
    log_path var/"log/macfocusmodes/macfocusmodes.log"
    error_log_path var/"log/macfocusmodes/macfocusmodes.log"
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