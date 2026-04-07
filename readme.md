# Build::Dependency

Build::Dependency provides dependency resolution algorithms.

[![Development Status](https://github.com/ioquatix/build-dependency/workflows/Test/badge.svg)](https://github.com/ioquatix/build-dependency/actions?workflow=Test)

## Motivation

Build::Dependency helps you resolve complex dependency graphs in your build systems and applications. It supports:

  - **Full dependency resolution** with automatic ordering
  - **Partial chains** for incremental builds
  - **Private dependencies** that don't leak to dependents
  - **Wildcard matching** for batch dependencies
  - **Mermaid visualization** for diagram generation

## Usage

Please see the [project documentation](https://ioquatix.github.io/build-dependency/) for more details.

  - [Getting Started](https://ioquatix.github.io/build-dependency/guides/getting-started/index) - This guide explains how to use `build-dependency` for dependency resolution in your projects.

## Releases

Please see the [project releases](https://ioquatix.github.io/build-dependency/releases/index) for all releases.

### v1.6.0

  - Change visualization to use Mermaid flowcharts for better readability and diagram generation.

## See Also

  - [build](https://github.com/ioquatix/build) — General build system using dependency resolution.
  - [teapot](https://github.com/ioquatix/teapot) — Package management using dependency resolution.

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

### Running Tests

To run the test suite:

``` shell
bundle exec sus
```

### Making Releases

Please see the [project releases](https://ioquatix.github.io/build-dependency/releases/index) for all releases.

### Developer Certificate of Origin

In order to protect users of this project, we require all contributors to comply with the [Developer Certificate of Origin](https://developercertificate.org/). This ensures that all contributions are properly licensed and attributed.

### Community Guidelines

This project is best served by a collaborative and respectful environment. Treat each other professionally, respect differing viewpoints, and engage constructively. Harassment, discrimination, or harmful behavior is not tolerated. Communicate clearly, listen actively, and support one another. If any issues arise, please inform the project maintainers.
