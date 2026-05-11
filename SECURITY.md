# Security notes

## Validator keys
- Never commit priv_validator_key.json to git
- Restrict file mode to 0600
- Back up encrypted, never plain text
- Consider remote signing (TMKMS) for high-stakes setups

## Operator wallet
- Use a dedicated wallet for unjail/withdraw TXs
- Rotate the operator key if exposed
- Set --keyring-backend file or os, never test

## Host hardening
- ufw default deny incoming, allow only SSH + p2p
- Disable password SSH, key-based only
- Auto-update security patches
- fail2ban on the SSH port

## Process isolation
- Run republicd as a non-root user where possible
- Use systemd ProtectSystem and ProtectHome directives

## Disclosure
For security issues that could affect validator funds or keys,
contact privately before opening a public issue.
