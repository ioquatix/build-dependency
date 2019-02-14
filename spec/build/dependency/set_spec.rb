# Copyright, 2012, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'build/dependency/set'

RSpec.describe Build::Dependency::Set do
	NamedObject = Struct.new(:name, :age)
	
	let(:object_class) {Struct.new(:name, :age)}

	describe "empty set" do
		it "is empty" do
			expect(subject).to be_empty
		end
	end
	
	describe "non-empty set" do
		let(:bob) {object_class.new('Bob', 10)}
		subject {described_class.new([bob])}
		
		it "should contain named objects" do
			expect(subject).to be_include bob
		end
		
		it "can enumerate all contained objects" do
			expect(subject.each.to_a).to be == [bob]
		end
		
		it "contains one item" do
			expect(subject).to_not be_empty
			expect(subject.size).to be == 1
		end
		
		it "can be cleared" do
			expect(subject).to_not be_empty
			subject.clear
			expect(subject).to be_empty
		end
		
		it "can delete items" do
			expect(subject).to_not be_empty
			subject.delete(bob)
			expect(subject).to be_empty
		end
		
		it "can be frozen" do
			subject.freeze
			
			expect(subject).to be_frozen
		end
		
		it "can look up named items" do
			expect(subject[bob.name]).to be == bob
		end
		
		it "should have string representation" do
			expect(subject.to_s).to be =~ /Bob/
		end
	end
	
	it "could contain many items" do
		names = ["Apple", "Orange", "Banana", "Kiwifruit"]
		
		names.each_with_index do |name, index|
			subject << NamedObject.new(name, index)
		end
		
		expect(subject.size).to be == names.size
	end
end
