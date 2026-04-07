# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.

require "build/dependency/set"

NamedObject = Struct.new(:name, :age)

describe Build::Dependency::Set do
	let(:object_class) {Struct.new(:name, :age)}
	
	with "empty set" do
		let(:subject) {Build::Dependency::Set.new}
		
		it "is empty" do
			expect(subject).to be(:empty?)
		end
	end
	
	with "non-empty set" do
		let(:bob) {object_class.new("Bob", 10)}
		let(:subject) {Build::Dependency::Set.new([bob])}
		
		it "should contain named objects" do
			expect(subject).to be(:include?, bob)
		end
		
		it "can enumerate all contained objects" do
			expect(subject.each.to_a).to be == [bob]
		end
		
		it "contains one item" do
			expect(subject).not.to be(:empty?)
			expect(subject.size).to be == 1
		end
		
		it "can be cleared" do
			expect(subject).not.to be(:empty?)
			subject.clear
			expect(subject).to be(:empty?)
		end
		
		it "can delete items" do
			expect(subject).not.to be(:empty?)
			subject.delete(bob)
			expect(subject).to be(:empty?)
		end
		
		it "can be frozen" do
			subject.freeze
			
			expect(subject).to be(:frozen?)
		end
		
		it "can look up named items" do
			expect(subject[bob.name]).to be == bob
		end
		
		it "should have string representation" do
			expect(subject.to_s).to be =~ /Bob/
		end
	end
	
	it "could contain many items" do
		set = Build::Dependency::Set.new
		names = ["Apple", "Orange", "Banana", "Kiwifruit"]
		
		names.each_with_index do |name, index|
			set << NamedObject.new(name, index)
		end
		
		expect(set.size).to be == names.size
	end
	
	it "should raise KeyError when adding duplicate items" do
		set = Build::Dependency::Set.new
		bob = NamedObject.new("Bob", 10)
		
		set << bob
		
		expect do
			set.add(bob)
		end.to raise_exception(KeyError)
	end
	
	it "can slice named items" do
		set = Build::Dependency::Set.new
		alice = NamedObject.new("Alice", 20)
		bob = NamedObject.new("Bob", 30)
		charlie = NamedObject.new("Charlie", 40)
		
		set << alice
		set << bob
		set << charlie
		
		expect(set.slice(["Alice", "Charlie"])).to be == [alice, charlie]
	end
	
	it "can be duplicated" do
		original = Build::Dependency::Set.new
		alice = NamedObject.new("Alice", 20)
		bob = NamedObject.new("Bob", 30)
		
		original << alice
		original << bob
		
		duplicate = original.dup
		
		expect(duplicate.size).to be == 2
		expect(duplicate).to be(:include?, alice)
		expect(duplicate).to be(:include?, bob)
		
		# Check that modifying the duplicate doesn't affect the original
		charlie = NamedObject.new("Charlie", 40)
		duplicate << charlie
		
		expect(duplicate.size).to be == 3
		expect(original.size).to be == 2
		expect(original).not.to be(:include?, charlie)
	end
end
