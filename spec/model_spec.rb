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
    
    subject { Class.new(Document) do attr :embedded, Document end.new }
    
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
    
    subject { Class.new(Document) do attr :array, Array end.new }
      
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

end