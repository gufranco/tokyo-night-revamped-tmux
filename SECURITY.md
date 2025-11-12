# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Which versions are eligible for receiving such patches depends on the CVSS v3.0 Rating:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

Please report (suspected) security vulnerabilities to the repository maintainers via GitHub Security Advisories. You will receive a response from us within 48 hours. If the issue is confirmed, we will release a patch as soon as possible depending on complexity but historically within a few days.

## Security Best Practices

When using this tmux theme:

1. **Keep Dependencies Updated**: Regularly update bash, tmux, and all required dependencies
2. **Review Scripts**: All widget scripts run with your user permissions - review them before use
3. **API Tokens**: If using GitHub/GitLab widgets, ensure your tokens have minimal required permissions
4. **Network Widgets**: The netspeed widget accesses network interfaces - ensure you trust the implementation

## Known Security Considerations

- Widget scripts execute with user-level permissions
- Some widgets may make external API calls (GitHub, GitLab, weather services)
- Network-related widgets access system network configuration

If you discover a security issue, please report it responsibly.
