# Security Policy

## Supported Versions

The following versions of **SoSquad - RAKSHAK-NET** are currently supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0.0 | :x:                |

## Reporting a Vulnerability

We take the security and integrity of **SoSquad - RAKSHAK-NET** seriously. If you discover a vulnerability or security flaw, we appreciate your help in responsibly disclosing it.

### How to Report

- **Do NOT create public GitHub issues or discussions for sensitive security vulnerabilities.**
- Please email our security point of contact or maintainers with details regarding the issue.
- Please include:
  - Description of the vulnerability and its potential impact.
  - Clear steps to reproduce the issue (proof-of-concept steps or scenarios).
  - Component(s) affected (e.g., Firestore rules, BLE mesh transport, client state notifier).
  - Any proposed mitigations or remediations.

### Response Timeline

- **Acknowledgment:** Within 48 hours.
- **Assessment & Triage:** Within 5 business days.
- **Fix & Disclosure:** Coordinated release and disclosure schedule following verification and patch deployment.

## Security Best Practices for Deployments

1. **Firebase Security Rules:**
   - Always enforce strict schema, type, and state validation in `firestore.rules`.
   - In production environments with user accounts or authenticated responders, restrict read and update permissions to authorized roles (`request.auth != null`).

2. **API Key Restrictions:**
   - Restrict Firebase Client API Keys in the **Google Cloud Console**:
     - **Application Restrictions:** Restrict to specific Android package names and SHA-1 release fingerprints.
     - **API Restrictions:** Scope keys strictly to Firebase and necessary APIs.

3. **Secrets and Credentials:**
   - Never commit `.env` files, private keys, service account JSON files, or signing keystores (`*.jks`, `*.keystore`) to version control.
   - Use environment variables or CI/CD secret management (e.g., GitHub Actions Secrets) for automated build pipelines.
