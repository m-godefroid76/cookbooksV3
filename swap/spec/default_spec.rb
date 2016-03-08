require 'chefspec'

describe 'swap::default' do
  before do
    @chef_run = ChefSpec::ChefRunner.new.converge 'swap::default'
  end

  describe 'create the swap space' do
    it 'creates swap file' do
      @chef_run.should execute_command <<-EOF.gsub(/^\s{8}/, '')
        dd if=/dev/zero of=/var/swapfile bs=1M count=8192
        chmod 600 /mnt/swap/swapfile
        mkswap /mnt/swap/swapfile
      EOF
    end

    it "doesn't create swap when exists" do
      pending 'TODO: Once ChefSpec supports guards'
    end
  end

  describe 'mount' do
    before do
      @mount = @chef_run.mount('none')
    end

    it 'has correct mount point' do
      @mount.name.should eql 'none'
    end

    it 'has correct device' do
      @mount.device.should eql '/var/swapfile'
    end

    it 'has correct fstype' do
      @mount.fstype.should eql 'swap'
    end
  end

  describe 'activate the swap file' do
    it 'runs swapon -a' do
      @chef_run.should execute_command 'swapon -a'
    end

    it "doesn't activate the swap when activated" do
      pending 'TODO: Once ChefSpec supports guards'
    end
  end
end
