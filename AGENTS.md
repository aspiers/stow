# AGENTS.md

This file provides guidance to AI coding assistants when working with
code in this repository.

## Overview

GNU Stow is a symlink farm manager written in Perl. It manages the
installation of software packages by creating symlinks from a target
directory (e.g., `/usr/local`) to package directories within a stow
directory (e.g., `/usr/local/stow/package`). This allows multiple
packages to coexist without file conflicts.

The codebase consists of:

- **Frontend**: Perl CLI scripts (`bin/stow`, `bin/chkstow`)
- **Backend**: Perl module `lib/Stow.pm` (core logic) and
  `lib/Stow/Util.pm` (utilities)
- **Test suite**: Test files in `t/` using Test::More and Test::Output

## Critical Build System Detail

**All program source files end in `.in` and are preprocessed by
`Makefile` before execution.**

Before testing any code changes:
1. Modify the `.in` files (NOT the generated files)
2. Run `make` to regenerate the preprocessed versions
3. Then test your changes

The preprocessing step uses `sed` to inject paths and version info
(see Makefile.am:115-149).

To avoid forgetting this step, use:

```bash
make watch
```

This runs `make` in a loop every second, auto-regenerating files on changes.

## Development Commands

### Building

```bash
./configure    # Configure for your system
make           # Build all targets (required after editing .in files)
make watch     # Auto-rebuild on changes (recommended during development)
```

### Testing

```bash
# Run full test suite
make check
# or
make test

# Run individual test (must set PERL5LIB first)
export PERL5LIB=t:bin:lib
perl t/stow.t

# Run with debug verbosity
TEST_VERBOSE=4 perl t/stow.t

# Run with prove
prove t/stow.t
prove          # Run all tests

# Test coverage
make coverage  # Requires Devel::Cover
# Opens HTML report at cover_db/coverage.html
```

### Installation

```bash
# Via Autotools (installs docs in multiple formats)
./configure --prefix=/usr/local
make install

# Via Module::Build (CPAN-style)
./configure && make
perl Build.PL
./Build install
```

## Architecture

### Core Classes

**Stow** (`lib/Stow.pm`):
- Main class implementing the stow/unstow logic
- Key methods: `plan_stow()`, `plan_unstow()`, `process_tasks()`,
  `get_conflicts()`
- Manages state: directory mappings, tasks queue, conflicts
- Handles tree folding/unfolding for efficient symlink management

**Stow::Util** (`lib/Stow/Util.pm`):
- Utility functions: path manipulation, debugging, error reporting
- Functions: `join_paths()`, `parent()`, `canon_path()`,
  `adjust_dotfile()`, etc.

### Design Principles

1. **Stateless**: Stow stores no state between runs. It determines
   current state by examining the filesystem.
2. **Safe**: Never deletes files, directories, or links in stow
   directories. Target tree can always be rebuilt.
3. **Tree folding**: When entire directory trees are stowed, creates a
   single symlink to the directory rather than symlinking each file
   individually.
4. **Conflict detection**: Plans all operations first, detects conflicts,
   only executes if conflict-free.

### Test Structure

Tests in `t/` use a common pattern:

1. Import `testutil.pm` for helper functions
2. Call `init_test_dirs()` to set up clean test environment in
   `tmp-testing-trees/`
3. Use helpers: `make_path()`, `make_file()`, `make_link()`,
   `new_Stow()`, etc.
4. Tests use subtests with `subtest('description', sub { ... })`
5. Test files are split into subtests for better organization and
   debugging

**Important test utilities** (`t/testutil.pm`):
- `init_test_dirs()`: Creates fresh test directory structure
- `new_Stow()`: Creates Stow instance for testing
- `make_path()`, `make_file()`, `make_link()`: Set up test fixtures
- `is_link()`, `is_dir_not_symlink()`, `is_nonexistent_path()`:
  Assertion helpers

## Common Patterns

### Running a single test from a specific subtest

```bash
export PERL5LIB=t:bin:lib
TEST_VERBOSE=4 perl t/stow.t
```

Tests are organized into subtests - read the test file to see available
subtests.

### Debugging

Enable verbose output in tests using `TEST_VERBOSE` (levels 0-5) or in
the stow command with `-v` / `--verbose`.

### Working with .in files

When editing source:

1. Edit `bin/stow.in`, `lib/Stow.pm.in`, etc. (NOT the generated
   versions)
2. Run `make` or `make watch`
3. Test the generated files in `bin/` and `lib/`

### Experimental files

Use `playground/` subdirectory for test files - it's gitignored and
excluded from the build.
