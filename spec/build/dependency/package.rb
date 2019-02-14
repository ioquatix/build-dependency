# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'build/dependency'

class Package
	include Build::Dependency
	
	def initialize(name = nil)
		@name = name
	end
	
	attr :name
	
	def inspect
		"<Package:#{@name}>"
	end
end

RSpec.shared_context "app packages" do
	let(:app) do
		Package.new('app').tap do |package|
			package.provides 'app'
			package.depends 'lib', private: true
			package.depends :platform, private: true
			package.depends 'Language/C++14', private: true
		end
	end
	
	let(:tests) do
		Package.new('tests').tap do |package|
			package.provides 'tests'
			package.depends 'lib', private: true
			package.depends :platform, private: true
			package.depends 'Language/C++17', private: true
		end
	end
	
	let(:lib) do
		Package.new('lib').tap do |package|
			package.provides 'lib'
			package.depends :platform, private: true
			package.depends 'Language/C++17', private: true
		end
	end
	
	let(:platform) do
		Package.new('Platform/linux').tap do |package|
			package.provides platform: 'Platform/linux'
			package.provides 'Platform/linux'
			package.depends :variant
		end
	end
	
	let(:variant) do
		Package.new('Variant/debug').tap do |package|
			package.provides variant: 'Variant/debug'
			package.provides 'Variant/debug'
		end
	end
	
	let(:compiler) do
		Package.new('Compiler/clang').tap do |package|
			package.provides 'Language/C++14'
			package.provides 'Language/C++17'
		end
	end
	
	let(:packages) {[app, tests, lib, platform, variant, compiler]}
	
	let(:visualization) {Build::Dependency::Visualization.new}
end
