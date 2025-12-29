# Homebrew Cask formula for RedButtonQuit
#
# To install locally for testing:
#   brew install --cask ./redbuttonquit.rb
#
# To submit to homebrew-cask:
#   1. Fork https://github.com/Homebrew/homebrew-cask
#   2. Add this file to Casks/r/redbuttonquit.rb
#   3. Submit a pull request

cask "redbuttonquit" do
  version "1.0.0"
  sha256 "PLACEHOLDER_SHA256_HASH"

  url "https://github.com/yourusername/redbuttonquit/releases/download/v#{version}/RedButtonQuit-#{version}.dmg"
  name "RedButtonQuit"
  desc "Quit apps when closing their last window"
  homepage "https://github.com/yourusername/redbuttonquit"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "RedButtonQuit.app"

  postflight do
    # Remind user about accessibility permission
    ohai "RedButtonQuit requires Accessibility permission to function."
    ohai "Grant permission in System Settings > Privacy & Security > Accessibility"
  end

  zap trash: [
    "~/Library/Preferences/com.redbuttonquit.app.plist",
    "~/Library/Application Support/RedButtonQuit",
    "~/Library/Caches/com.redbuttonquit.app",
  ]
end
