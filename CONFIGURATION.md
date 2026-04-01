# Local Configuration

This project currently does not require any secret runtime configuration.

If future integrations need private values such as API keys, service plist files, or environment-specific endpoints:

- store them in local, ignored files such as `.env`, `Secrets.plist`, `Config.plist`, or `GoogleService-Info.plist`
- do not hardcode secrets directly in Swift source files
- commit only redacted examples or setup documentation, never real credentials
- keep production and development values separated

Recommended approach for future scaling:

- add a small configuration loader layer that reads from ignored local files
- provide a sample file such as `Config.example.plist` with placeholder values only
- use GitHub repository secrets for CI or deployment workflows instead of committed values
