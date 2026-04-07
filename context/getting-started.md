# Getting Started

This guide explains how to use `build-dependency` for dependency resolution in your projects.

## Installation

Add this line to your application's Gemfile:

``` ruby
gem "build-dependency"
```

And then execute:

``` bash
$ bundle
```

Or install it yourself as:

``` bash
$ gem install build-dependency
```

## Concepts

### Dependency Graphs

A dependency graph is a DAG (directed acyclic graph), such that if `A` depends on `B`, `A` has an edge pointing to `B`.

A **dependency list** is an ordered list of dependencies, such that if `A` depends on `B`, `B` will be listed earlier than `A`.

A **dependency chain** is the result of traversing the dependency graph from a given set of dependencies. It contains an ordered list of providers and a list of specific provisions.

### Full Dependency Chain

Here's an example of a full dependency chain showing how dependencies are resolved:

``` mermaid
flowchart LR
    variant[variant] --- Variant_debug[Variant/debug]
    Platform_linux[Platform/linux] --> variant[variant]
    platform[platform] --- Platform_linux[Platform/linux]
    Language_C__14[Language/C++14] --- Compiler_clang[Compiler/clang]
    Language_C__17[Language/C++17] --- Compiler_clang[Compiler/clang]
    lib[lib] -.-> platform[platform]
    lib[lib] -.-> Language_C__17[Language/C++17]
    app[app] -.-> lib[lib]
    app[app] -.-> platform[platform]
    app[app] -.-> Language_C__14[Language/C++14]

    %% Styles
    style Variant_debug fill:#add8e6
    style Platform_linux fill:#add8e6
    style Compiler_clang fill:#add8e6
    style Variant_debug stroke-width:3px
    style Platform_linux stroke-width:3px
    style Language_C__17 stroke-width:3px
    style lib stroke-width:3px
    style Language_C__14 stroke-width:3px
    style app stroke-width:3px
```

In this diagram:
- **Solid arrows** (-->) represent public dependencies
- **Dotted arrows** (-.->) represent private dependencies
- **Undirected edges** (---) represent provisions
- **Light blue boxes** are providers (they provide named provisions)
- **Bold borders** indicate provisions included in the chain

### Partial Dependency Chain

A **private dependency** is not traversed when creating a partial chain. When building a partial chain for `app`, we don't follow `lib`'s private dependency on `Language/C++17`:

``` mermaid
flowchart LR
    variant[variant] --- Variant_debug[Variant/debug]
    Platform_linux[Platform/linux] --> variant[variant]
    platform[platform] --- Platform_linux[Platform/linux]
    lib[lib] -.-> platform[platform]
    lib[lib] -.-> Language_C__17[Language/C++17]
    Language_C__14[Language/C++14] --- Compiler_clang[Compiler/clang]
    Language_C__17[Language/C++17] --- Compiler_clang[Compiler/clang]

    %% Styles
    style Variant_debug fill:#add8e6
    style Platform_linux fill:#add8e6
    style Compiler_clang fill:#add8e6
    style Variant_debug stroke-width:3px
    style Platform_linux stroke-width:3px
    style lib stroke-width:3px
    style Language_C__14 stroke-width:3px
```

Notice that in the partial chain, private dependencies of dependencies are not included.

## Usage

### Creating a Model

To create your own dependency graph, you need to expose a model object which represents something that has dependencies and can be depended on.

Here is an example of a package model for Arch Linux `PKGBUILD` files:

``` ruby
# A specific package.
class Package
	include Build::Dependency
	
	def initialize(path, metadata)
		@path = path
		@metadata = metadata
		
		metadata.each do |key, value|
			case key
			when "pkgname"
				@name = value
			when "depends"
				self.depends(value)
			when "provides"
				self.provides(value)
			when "pkgver"
				@pkgver = value
			when "pkgrel"
				@pkgrel = value
			when "arch"
				@arch = value
			end
		end
		
		@name ||= File.basename(path)
		self.provides(@name)
	end
	
	attr :path
	attr :name
	attr :metadata
	
	def package_path
		File.join(@path, package_file)
	end
	
	def package_file
		"#{@name}-#{@pkgver}-#{@pkgrel}-#{@arch}.pkg.tar.xz"
	end
end
```

### Creating a Context

A context represents a directory full of packages:

``` ruby
class Context
	def initialize(path)
		@path = path
		@packages = {}
		
		load_packages!
	end
	
	def packages_path
		@path
	end
	
	attr :packages
	
	def load_packages!
		Dir.foreach(packages_path) do |package_name|
			next if package_name.start_with?(".")
			
			package_path = File.join(packages_path, package_name)
			next unless File.directory?(package_path)
			
			LOGGER.info "Loading #{package_path}..."
			output, status = Open3.capture2("makepkg", "--printsrcinfo", chdir: package_path)
			
			metadata = output.lines.collect(&:strip).delete_if(&:empty?).collect{|line| line.split(/\s*=\s*/, 2)}
			
			package = Package.new(package_path, metadata)
			@packages[package.name] = package
			
			if package.name != package_name
				LOGGER.warn "Package in directory #{package_name} has pkgname of #{package.name}!"
			end
		end
	end
	
	# Compute the dependency chain for the selection of packages.
	def provision_chain(selection)
		Build::Dependency::Chain.new(selection, @packages.values, selection)
	end
end
```

### Building Dependency Chains

A chain represents a list of resolved packages. You generate a chain from:
- A list of dependencies
- A list of all available packages
- A selection of packages which help to resolve ambiguities (e.g. if two packages provide the same target, selection and then priority is used to resolve the ambiguity)

Here is an example rake task which can build a directory of packages including both local PKGBUILDs and upstream packages:

``` ruby
desc "Build a deployment of packages, specify the root package using TARGET="
task :collect do
	target = ENV["TARGET"] or fail("Please supply TARGET=")
	
	LOGGER.info "Resolving packages for #{target}"
	
	context = Servers::Context.new(__dir__)
	
	chain = context.provision_chain([target])
	
	deploy_root = File.join(__dir__, "../deploy", target)
	
	FileUtils::Verbose.rm_rf deploy_root
	FileUtils::Verbose.mkdir_p deploy_root
	
	system_packages = Set.new
	
	# Dependencies that could not be resolved by our local packages must be resolved by the system:
	chain.unresolved.each do |(depends, source)|
		output, status = Open3.capture2("pactree", "-lsu", depends.name)
		
		abort "Failed to resolve dependency tree for package #{depends.name}" unless status.success?
		
		system_packages += output.split(/\s+/)
	end
	
	# Copy system packages from pacman repositories:
	Dir.chdir(deploy_root) do
		Open3.pipeline(
			["pacman", "-Sp", *system_packages.to_a],
			["wget", "-nv", "-i", "-"],
		)
	end
	
	# Copy local packages:
	chain.ordered.each do |resolution|
		package = resolution.provider
		FileUtils::Verbose.cp package.package_path, File.join(deploy_root, package.package_file)
	end
end
```

### Using Wildcards

It's possible to include wildcards in the dependency name. This is useful if you use scoped names, e.g. `Test/*` would depend on all test targets. The wildcard matching is done by `File.fnmatch?`.

Example:

``` ruby
package.depends "Test/*"  # Matches all test targets
package.depends "Language/C++*"  # Matches C++14, C++17, etc.
```

### Visualization

You can generate Mermaid diagrams to visualize your dependency chains:

``` ruby
visualization = Build::Dependency::Visualization.new
chain = Build::Dependency::Chain.expand(["app"], packages)
mermaid_diagram = visualization.generate(chain)
puts mermaid_diagram
```

This will output a Mermaid flowchart diagram that you can render in documentation or save to a file.
