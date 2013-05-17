require_relative '../model'

describe Document do

  it { should be_a Hash }

  describe 'with an implcit :name field' do

    it { should_not respond_to :name }
    it { should_not respond_to :name? }
    it { should_not respond_to :name= }

    context 'when unnamed' do
      it { should_not respond_to :name }
      it '#name raises error' do 
        expect{subject.name}.to raise_error(NameError)
      end
    end

    context 'when named' do
      before(:each) { subject[:name] = "Rumpelstiltskin" }
      it { should respond_to :name }
      it '#name returns name' do 
        subject.name.should eq "Rumpelstiltskin" 
      end
    end
      
  end

  describe 'with an explicit :name field' do
    
    subject { Document.with(:name).new } 
    
    it { should respond_to :name }
    it { should respond_to :name? }
    it { should respond_to :name= }
    
    context 'when unnamed' do
      it 'has no name' do 
        subject.name?.should be_false 
      end
      it '#name is nil' do 
        subject.name.should be_nil 
      end
    end  
    
    context 'when named' do
      before(:each) { subject.name = "Rumpelstiltskin" }
      it 'has a name' do 
        subject.name?.should be_true 
      end
      it '#name is name' do 
        subject.name.should eq "Rumpelstiltskin" 
      end 
    end

    context 'with an empty name' do
      before(:each) { subject.name = '' }
      it 'has no name' do 
        subject.name?.should be_false 
      end
      it '#name is empty string' do 
        subject.name.should eq '' 
      end 
    end
      
  end
  
  describe 'with an embedded document' do
    
    subject { Class.new(Document) do attr :embedded, Document end.new }
    
    it { should respond_to :embedded }
    it { should respond_to :embedded? }
    it { should_not respond_to :embedded= }
  
    context 'when embedded document is unset' do
      it 'has no embedded document' do
        subject.embedded?.should be_false
      end
      it '#embedded is a kind of Document' do
        subject.embedded.should be_a Document
      end
      it '#embedded is empty document' do
        subject.embedded.should be_empty
      end 
    end
    
    context 'when embedded document contains values' do
      before(:each) { subject.embedded[:value] = :any }
      it 'has embedded document' do
        subject.embedded?.should be_true
      end
      it '#embedded is a kind of Document' do
        subject.embedded.should be_a Document
      end
      it '#embedded contains values' do
        subject.embedded.should have_at_least(1).values
      end 
    end
      
  end  
  
  describe 'with an Array field' do
    
    subject { Class.new(Document) do attr :array, Array end.new }
      
    it { should respond_to :array }
    it { should respond_to :array? }
    it { should_not respond_to :array= }

    context 'when array is unset' do
      it 'has no array field' do
        subject.array?.should be_false
      end
      it '#array is instance of Array' do
        subject.array.should be_instance_of Array
      end
      it '#array is empty' do
        subject.array.should be_empty
      end 
    end
  
    context 'when array contains values' do
      before(:each) { subject.array << :value }
      it 'has array field' do
        subject.array?.should be_true
      end
      it '#array is instance of Array' do
        subject.array.should be_instance_of Array
      end
      it '#array contains values' do
        subject.array.should have_at_least(1).values
      end 
    end
    
  end  

end