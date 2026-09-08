//! Command line entry point for {{PROJECT_SHORT}}.
//!
//! This binary parses arguments and formats output; the logic lives in the
//! library crate so it stays testable without a terminal.

use std::process::ExitCode;

use {{CRATE_NAME}}::VERSION;

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();

    if args.iter().any(|a| a == "--version" || a == "-V") {
        println!("{{PROJECT_DIST}} {VERSION}");
        return ExitCode::SUCCESS;
    }

    // TODO(template): dispatch to the library here.
    println!("{{PROJECT_SHORT}} v{VERSION}");
    ExitCode::SUCCESS
}
