require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class NFSVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::NFS
    @app, @env = mock_action_data

    @vm = mock("vm")
    @env.env.stubs(:host).returns(Vagrant::Hosts::Base.new(@env))
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)
  end

  context "with an instance" do
    setup do
      # Kind of dirty but not sure of a way around this
      @klass.send(:alias_method, :verify_host_real, :verify_host)
      @klass.any_instance.stubs(:verify_host)
      @instance = @klass.new(@app, @env)
    end

    context "calling" do
      should "call the proper sequence and succeed" do
        seq = sequence('seq')
        @instance.expects(:extract_folders).in_sequence(seq)
        @instance.expects(:export_folders).in_sequence(seq)
        @app.expects(:call).with(@env).in_sequence(seq)
        @instance.call(@env)
      end
    end

    context "extracting folders" do
      setup do
        @env.env.config.vm.share_folder("v-foo", "/foo", ".", :nfs => true)
        @env.env.config.vm.share_folder("v-bar", "/bar", ".", :nfs => true)
      end

      should "extract the NFS enabled folders" do
        @instance.extract_folders
        assert_equal 2, @instance.folders.length
      end

      should "remove the folders from the original config" do
        @instance.extract_folders
        assert_equal 1, @env["config"].vm.shared_folders.length
        assert @env["config"].vm.shared_folders.has_key?("v-root")
      end
    end

    context "verifying host" do
      should "error environment if host is nil" do
        @env.env.stubs(:host).returns(nil)
        @instance.verify_host_real
        assert @env.error?
        assert_equal :nfs_host_required, @env.error.first
      end

      should "error environment if host does not support NFS" do
        @env.env.host.stubs(:nfs?).returns(false)
        @instance.verify_host_real
        assert @env.error?
        assert_equal :nfs_not_supported, @env.error.first
      end

      should "be fine if everything passes" do
        @env.env.host.stubs(:nfs?).returns(true)
        @instance.verify_host_real
        assert !@env.error?
      end
    end
  end
end