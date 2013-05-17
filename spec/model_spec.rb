require_relative '../model'

describe Document do

  it { should be_a Hash }

  describe 'with an implcit :name field' do

    it { should_not respond_to :name }
    it { should_not respond_to :name? }
    it { should_not respond_to :name= }

    context 'when unnamed' do
      it { should_not respond_to :name }
      it '#name raises no method error' do 
        expect{subject.name}.to raise_error(NoMethodError)
      end
    end

    context 'when named' do
      before { subject[:name] = "value" }
      it { should respond_to :name }
      its(:name) { should eq "value" }
    end
      
  end

  describe 'with an explicit :name field' do
    
    subject { Document.with(:name).new } 
    
    it { should respond_to :name }
    it { should respond_to :name? }
    it { should respond_to :name= }
    
    context 'when unnamed' do
      its(:name?) { should be_false }
      its(:name) { should be_nil }
    end  
    
    context 'when named' do
      before { subject.name = "value" }
      its(:name?) { should be_true }
      its(:name) { should eq "value" }
    end

    context 'with an empty name' do
      before { subject.name = '' }
      its(:name?) { should be_false }
      its(:name) { should eq "" }
    end
      
  end
  
  describe 'with an embedded document' do
    
    subject { Document.with(:embedded => Document).new }
    
    it { should respond_to :embedded }
    it { should respond_to :embedded? }
    it { should_not respond_to :embedded= }
  
    context 'when embedded document is unset' do
      its(:embedded?) { should be_false }
      its(:embedded) { should be_a Document }
      its(:embedded) { should be_empty }
    end
    
    context 'when embedded document contains values' do
      before { subject.embedded[:value] = "value" }
      its(:embedded?) { should be_true }
      its(:embedded) { should be_a Document }
      its(:embedded) { should have_at_least(1).values }
    end
      
  end  
  
  describe 'with an Array field' do
    
    subject { Document.with(:array => Array).new }
      
    it { should respond_to :array }
    it { should respond_to :array? }
    it { should_not respond_to :array= }

    context 'when array is unset' do
      its(:array?) { should be_false }
      its(:array) { should be_a Array }
      its(:array) { should be_empty }
    end
  
    context 'when array contains values' do
      before { subject.array << "value" }
      its(:array?) { should be_true }
      its(:array) { should be_a Array }
      its(:array) { should have_at_least(1).value }
    end
    
  end  
  
  describe "anonymous declaration" do
    
    it "should accept field names" do
      type = Document.with(:a,:b,:c)
      type.should be_a Class
      type.schema.should include :a
      type.schema.should include :b
      type.schema.should include :c
    end

    it "should accept field names with type" do
      type = Document.with(:a,b:Array,c:Document)
      type.should be_a Class
      type.schema.should include :a
      type.schema.should include :b => Array
      type.schema.should include :c => Document
    end
    
  end

  describe "class declaration" do

    it "should accept field names" do
      class A < Document
        attr :field
      end
      A.should be_a Class
      A.schema.should include :field
    end

    it "should accept field names with type" do
      class B < Document
        attr :field, Document
      end
      B.should be_a Class
      B.schema.should include :field => Document
    end
    
  end


end