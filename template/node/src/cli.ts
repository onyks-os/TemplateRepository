#!/usr/bin/env node
/**
 * Command line entry point for {{PROJECT_SHORT}}.
 *
 * This layer parses arguments and formats output; business logic lives in the
 * core modules so it stays testable without a terminal.
 */

import { VERSION } from "./index.js";

export const EXIT_OK = 0;
export const EXIT_ERROR = 1;
export const EXIT_USAGE = 2;

export function run(argv: readonly string[]): number {
  if (argv.includes("--version") || argv.includes("-V")) {
    process.stdout.write(`{{PROJECT_PKG}} ${VERSION}\n`);
    return EXIT_OK;
  }

  // TODO(template): dispatch to the core here.
  process.stdout.write(`{{PROJECT_SHORT}} v${VERSION}\n`);
  return EXIT_OK;
}

// Only run when invoked directly, so the module stays importable from tests.
if (process.argv[1] && import.meta.url.endsWith(process.argv[1].replace(/^.*[\\/]/, ""))) {
  process.exitCode = run(process.argv.slice(2));
}
