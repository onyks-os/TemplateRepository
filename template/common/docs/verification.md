# Release Verification

Every {{PROJECT_SHORT}} release is published with checksums, a Sigstore signature, and a CycloneDX
SBOM. This guide shows how to verify an artifact before installing it.

## 1. Verify the Checksums

Download the artifact and `SHA256SUMS` from the
[Releases page](https://github.com/{{GITHUB_OWNER}}/{{PROJECT_SLUG}}/releases), then:

```bash
sha256sum --check --ignore-missing SHA256SUMS
```

Expected output: `<artifact>: OK`.

## 2. Verify the Sigstore Signature

Release artifacts are signed keylessly through GitHub Actions OIDC — there is no long-lived private
key to steal. Install [`sigstore`](https://pypi.org/project/sigstore/) and verify:

```bash
python -m pip install sigstore

sigstore verify identity \
  --cert-identity "https://github.com/{{GITHUB_OWNER}}/{{PROJECT_SLUG}}/.github/workflows/release.yml@refs/tags/v{{VERSION}}" \
  --cert-oidc-issuer "https://token.actions.githubusercontent.com" \
  <artifact>
```

## 3. Verifying Signer Identity

The `--cert-identity` value must exactly match the release workflow path and the tag being verified.
A signature that verifies against a *different* identity is not a valid {{PROJECT_SHORT}} release,
even if the cryptography checks out.

## 4. Inspect the SBOM

```bash
jq '.components[] | {name, version, licenses}' sbom.json
```

Compare the component list against [`DEPENDENCIES.md`](../DEPENDENCIES.md). Any component present in
the SBOM but absent from that file should be reported as an issue.

## 5. Reproducing the Build

```bash
git clone --branch v{{VERSION}} https://github.com/{{GITHUB_OWNER}}/{{PROJECT_SLUG}}.git
cd {{PROJECT_SLUG}}
make build
sha256sum dist/*
```

<!-- TODO(template): state whether the build is bit-for-bit reproducible, and if not, which parts
     vary (timestamps, paths) and how to normalize them. -->
