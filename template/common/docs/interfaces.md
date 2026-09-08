<!--
Copyright (c) {{COPYRIGHT_YEAR}} {{GITHUB_OWNER}}
SPDX-License-Identifier: {{LICENSE_ID}}
-->

# {{PROJECT_SHORT}} — External Interfaces Reference

This document is the contract between {{PROJECT_SHORT}} and everything outside it. Any change to what
is described here is a change to the public interface and must follow
[Semantic Versioning](https://semver.org/).

## Table of Contents

1. [Command Line Interface](#1-command-line-interface)
2. [Configuration](#2-configuration)
3. [Exit Codes](#3-exit-codes)
4. [Programmatic API](#4-programmatic-api)
5. [Files & System Integration](#5-files--system-integration)
6. [External Network Endpoints](#6-external-network-endpoints)

---

## 1. Command Line Interface

| Command | Description | Requires privileges |
| :------ | :---------- | :------------------ |
| <!-- TODO(template): one row per command. --> | | |

### Global Options

| Option | Type | Default | Description |
| :----- | :--- | :------ | :---------- |
| `--help` | flag | — | Show usage and exit. |
| `--version` | flag | — | Print the version and exit. |

---

## 2. Configuration

| Key | Type | Default | Description |
| :-- | :--- | :------ | :---------- |
| <!-- TODO(template): every configuration key and environment variable read by the program. --> | | | |

Precedence: command-line flags override environment variables, which override the configuration file,
which overrides built-in defaults.

---

## 3. Exit Codes

| Code | Meaning |
| :--- | :------ |
| `0`  | Success. |
| `1`  | Generic error. |
| `2`  | Invalid usage or arguments. |
| <!-- TODO(template): project-specific codes. --> | |

---

## 4. Programmatic API

<!-- TODO(template): the public, supported entry points. Anything not listed here is internal and may
     change without a major version bump. -->

---

## 5. Files & System Integration

| Path | Purpose | Lifetime |
| :--- | :------ | :------- |
| <!-- TODO(template): every path the program reads, writes, or creates. --> | | |

---

## 6. External Network Endpoints

| Endpoint | Purpose | When contacted | Opt-out |
| :------- | :------ | :------------- | :------ |
| <!-- TODO(template): every host the program contacts. If none, state "none" explicitly — users
     checking for telemetry look here first. --> | | | |
