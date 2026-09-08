/**
 * Smoke tests — the minimum guarantee that the package is wired up correctly.
 * Replace these with real tests, but never let the suite reach zero.
 */

import { describe, expect, it } from "vitest";

import { EXIT_OK, run } from "../src/cli.js";
import { VERSION } from "../src/index.js";

describe("{{PROJECT_SHORT}}", () => {
  it("exposes a version", () => {
    expect(VERSION).toBeTruthy();
  });

  it("exits successfully with no arguments", () => {
    expect(run([])).toBe(EXIT_OK);
  });

  it("handles --version", () => {
    expect(run(["--version"])).toBe(EXIT_OK);
  });
});
