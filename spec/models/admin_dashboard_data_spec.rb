require 'spec_helper'

describe AdminDashboardData do

  describe "rails_env_check" do
    subject { AdminDashboardData.new.rails_env_check }

    it 'returns nil when running in production mode' do
      Rails.stubs(:env).returns('production')
      subject.should be_nil
    end

    it 'returns a string when running in development mode' do
      Rails.stubs(:env).returns('development')
      subject.should_not be_nil
    end

    it 'returns a string when running in test mode' do
      Rails.stubs(:env).returns('test')
      subject.should_not be_nil
    end
  end

  describe 'host_names_check' do
    subject { AdminDashboardData.new.host_names_check }

    it 'returns nil when host_names is set' do
      Discourse.stubs(:current_hostname).returns('something.com')
      subject.should be_nil
    end

    it 'returns a string when host_name is localhost' do
      Discourse.stubs(:current_hostname).returns('localhost')
      subject.should_not be_nil
    end

    it 'returns a string when host_name is production.localhost' do
      Discourse.stubs(:current_hostname).returns('production.localhost')
      subject.should_not be_nil
    end
  end

  describe 'gc_checks' do
    subject { AdminDashboardData.new.gc_checks }

    it 'returns nil when gc params are set' do
      ENV.stubs(:[]).with('RUBY_GC_MALLOC_LIMIT').returns(90000000)
      subject.should be_nil
    end

    it 'returns a string when gc params are not set' do
      ENV.stubs(:[]).with('RUBY_GC_MALLOC_LIMIT').returns(nil)
      subject.should_not be_nil
    end
  end

  describe 'clockwork_check' do
    subject { AdminDashboardData.new.clockwork_check }

    it 'returns nil when clockwork is running' do
      Jobs::ClockworkHeartbeat.stubs(:is_clockwork_running?).returns(true)
      subject.should be_nil
    end

    it 'returns a string when clockwork is not running' do
      Jobs::ClockworkHeartbeat.stubs(:is_clockwork_running?).returns(false)
      subject.should_not be_nil
    end
  end

  describe 'sidekiq_check' do
    subject { AdminDashboardData.new.sidekiq_check }

    it 'returns nil when sidekiq processed a job recently' do
      Jobs.stubs(:last_job_performed_at).returns(1.minute.ago)
      Jobs.stubs(:queued).returns(0)
      subject.should be_nil
    end

    it 'returns nil when last job processed was a long time ago, but no jobs are queued' do
      Jobs.stubs(:last_job_performed_at).returns(7.days.ago)
      Jobs.stubs(:queued).returns(0)
      subject.should be_nil
    end

    it 'returns nil when no jobs have ever been processed, but no jobs are queued' do
      Jobs.stubs(:last_job_performed_at).returns(nil)
      Jobs.stubs(:queued).returns(0)
      subject.should be_nil
    end

    it 'returns a string when no jobs were processed recently and some jobs are queued' do
      Jobs.stubs(:last_job_performed_at).returns(20.minutes.ago)
      Jobs.stubs(:queued).returns(1)
      subject.should_not be_nil
    end

    it 'returns a string when no jobs have ever been processed, and some jobs are queued' do
      Jobs.stubs(:last_job_performed_at).returns(nil)
      Jobs.stubs(:queued).returns(1)
      subject.should_not be_nil
    end
  end

  describe 'ram_check' do
    subject { AdminDashboardData.new.ram_check }

    it 'returns nil when total ram is 1 GB' do
      MemInfo.any_instance.stubs(:mem_total).returns(1025272)
      subject.should be_nil
    end

    it 'returns nil when total ram cannot be determined' do
      MemInfo.any_instance.stubs(:mem_total).returns(nil)
      subject.should be_nil
    end

    it 'returns a string when total ram is less than 1 GB' do
      MemInfo.any_instance.stubs(:mem_total).returns(512636)
      subject.should_not be_nil
    end
  end

  describe 'send_email_with_gmail_check' do
    subject { AdminDashboardData.new.send_email_with_gmail_check }

    it 'returns nil if gmail.com is not in the smtp_settings address' do
      ActionMailer::Base.stubs(:smtp_settings).returns({address: 'mandrillapp.com'})
      expect(subject).to be_nil
    end

    context 'gmail.com is in the smtp_settings address' do
      before { ActionMailer::Base.stubs(:smtp_settings).returns({address: 'smtp.gmail.com'}) }

      it 'returns nil in development env' do
        Rails.stubs(:env).returns('development')
        expect(subject).to be_nil
      end

      it 'returns a string when in production env' do
        Rails.stubs(:env).returns('production')
        expect(subject).to_not be_nil
      end
    end
  end

  describe 'default_logo_check' do
    subject { AdminDashboardData.new.default_logo_check }

    describe 'favicon_url check' do
      before do
        SiteSetting.stubs(:logo_url).returns('/assets/my-logo.jpg')
        SiteSetting.stubs(:logo_small_url).returns('/assets/my-small-logo.jpg')
      end

      it 'returns a string when favicon_url is default' do
        expect(subject).to_not be_nil
      end

      it 'returns a string when favicon_url contains default filename' do
        SiteSetting.stubs(:favicon_url).returns("/prefix#{SiteSetting.defaults[:favicon_url]}")
        expect(subject).to_not be_nil
      end

      it 'returns nil when favicon_url does not match default-favicon.png' do
        SiteSetting.stubs(:favicon_url).returns('/assets/my-favicon.png')
        expect(subject).to be_nil
      end
    end

    describe 'logo_url check' do
      before do
        SiteSetting.stubs(:favicon_url).returns('/assets/my-favicon.png')
        SiteSetting.stubs(:logo_small_url).returns('/assets/my-small-logo.jpg')
      end

      it 'returns a string when logo_url is default' do
        expect(subject).to_not be_nil
      end

      it 'returns a string when logo_url contains default filename' do
        SiteSetting.stubs(:logo_url).returns("/prefix#{SiteSetting.defaults[:logo_url]}")
        expect(subject).to_not be_nil
      end

      it 'returns nil when logo_url does not match d-logo-sketch.png' do
        SiteSetting.stubs(:logo_url).returns('/assets/my-logo.png')
        expect(subject).to be_nil
      end
    end

    # etc.
  end

  describe 'auth_config_checks' do

    shared_examples 'problem detection for login providers' do
      context 'when disabled' do
        it 'returns nil' do
          SiteSetting.stubs(enable_setting).returns(false)
          subject.should be_nil
        end
      end

      context 'when enabled' do
        before do
          SiteSetting.stubs(enable_setting).returns(true)
        end

        it 'returns nil key and secret are set' do
          SiteSetting.stubs(key).returns('12313213')
          SiteSetting.stubs(secret).returns('12312313123')
          subject.should be_nil
        end

        it 'returns a string when key is not set' do
          SiteSetting.stubs(key).returns('')
          SiteSetting.stubs(secret).returns('12312313123')
          subject.should_not be_nil
        end

        it 'returns a string when secret is not set' do
          SiteSetting.stubs(key).returns('123123')
          SiteSetting.stubs(secret).returns('')
          subject.should_not be_nil
        end

        it 'returns a string when key and secret are not set' do
          SiteSetting.stubs(key).returns('')
          SiteSetting.stubs(secret).returns('')
          subject.should_not be_nil
        end
      end
    end

    describe 'facebook' do
      subject { AdminDashboardData.new.facebook_config_check }
      let(:enable_setting) { :enable_facebook_logins }
      let(:key) { :facebook_app_id }
      let(:secret) { :facebook_app_secret }
      include_examples 'problem detection for login providers'
    end

    describe 'twitter' do
      subject { AdminDashboardData.new.twitter_config_check }
      let(:enable_setting) { :enable_twitter_logins }
      let(:key) { :twitter_consumer_key }
      let(:secret) { :twitter_consumer_secret }
      include_examples 'problem detection for login providers'
    end

    describe 'github' do
      subject { AdminDashboardData.new.github_config_check }
      let(:enable_setting) { :enable_github_logins }
      let(:key) { :github_client_id }
      let(:secret) { :github_client_secret }
      include_examples 'problem detection for login providers'
    end
  end

end
