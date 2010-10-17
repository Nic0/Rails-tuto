require 'spec_helper'

describe User do
  before(:each) do
  # basic attribut for an user 
    @attr = { 
        :name                   => "Exemple User", 
        :email                  => "user@email.com",
        :password               => "foobar",
        :password_confirmation  => "foobar"
    }

  end

  it "should create a new instance given valid attributes" do
    User.create!(@attr)
  end

  it "should require a name" do
    no_name_user = User.new(@attr.merge(:name => ""))
    no_name_user.should_not be_valid
  end

  it "should require an email" do
    no_email_user = User.new(@attr.merge(:email => ""))
    no_email_user.should_not be_valid
  end

  it "should reject names too long" do
    long_name = "a" * 51
    long_name_user = User.new(@attr.merge(:name => long_name))
    long_name_user.should_not be_valid
  end

  it "should reject names too short" do
    short_name = "a" * 2
    short_name_user = User.new(@attr.merge(:name => short_name))
    short_name_user.should_not be_valid
  end

  it "should accept valid email addresses" do
    addresses = %w[user@foo.com THE_USER@foo.bar.org first.last@foo.jp]
    addresses.each do |address|
      valid_email_user = User.new(@attr.merge(:email => address))
      valid_email_user.should be_valid
    end
  end

  it "should reject invalid email addresses" do
    addresses = %w[user@foo,com user_at_foo.org example.user@foo.]
    addresses.each do |address|
      invalid_email_user = User.new(@attr.merge(:email => address))
      invalid_email_user.should_not be_valid
    end
  end

  it "should reject duplicate email addresses" do
    User.create!(@attr)
    user_duplicate_email = User.new(@attr)
    user_duplicate_email.should_not be_valid
  end

  it "should reject emails adresses identical up to case" do
    upcase_email = @attr[:email].upcase
    User.create!(@attr.merge(:email => upcase_email))
    user_with_duplicate = User.new(@attr)
    user_with_duplicate.should_not be_valid
  end

  describe "password validation" do
    
    it "should require a password" do
      User.new(@attr.merge(:password => "", :password_confirmation => "")).
        should_not be_valid
    end

    it "should require a matching password" do
      User.new(@attr.merge(:password_confirmation => "invalid")).
        should_not be_valid
    end

    it "should reject short password" do
      short_passwd = "a" * 5
      User.new(@attr.merge(:password => short_passwd)).
        should_not be_valid
    end

    it "should reject long password" do
      long_passwd = "a" * 41
      User.new(@attr.merge(:password => long_passwd)).
        should_not be_valid
    end
  end
  
  describe "password encryption "do
    before(:each) do
      @user = User.create!(@attr)
    end

    it "should have an encrypted password attribute" do
      @user.should respond_to(:encrypted_password)
    end

    it "should save the encrypted passwd" do
      @user.encrypted_password.should_not be_blank
    end

    describe "has_password? method" do
    
      it "should be true if the pass match" do
        @user.has_password?(@attr[:password]).should be_true
      end

      it "should be false if pass dosn't match" do
        @user.has_password?("invalid").should be_false
      end
    end

    describe "authentificate methode" do
      
      it "should return nil on email/passowd missatch" do
        wrong_password_user = User.authenticate(@attr[:email], "wrongpass").
        should be_nil
      end

      it "should return nil for an email adress with no user" do
        nonexist_user = User.authenticate("bar@foo.com", @attr[:password]).
        should be_nil
      end

      it "should return the user on email/pass match" do
        matching_user = User.authenticate(@attr[:email], @attr[:password]).
        should == @user
      end
    end
  end
  
  describe "admin attribute" do
    
    before(:each) do 
      @user = User.create!(@attr)
    end

    it "should response to admin" do
      @user.should respond_to(:admin)
    end

    it "should not be an admin by default" do
      @user.should_not be_admin
    end

    it "should be convertible to an admin" do
      @user.toggle!(:admin)
      @user.should be_admin
    end
  end

  describe "micropost associations" do
    
    before(:each) do
      @user = User.create(@attr)
      @mp1 = Factory(:micropost, :user => @user, :created_at => 1.day.ago)
      @mp2 = Factory(:micropost, :user => @user, :created_at => 1.hour.ago)
    end

    it "sohuld have a microposts attribute" do
      @user.should respond_to(:microposts)
    end

    it "should have the risht microposts in right order" do
      @user.microposts.should == [@mp2, @mp1]
    end

    it "should destroy associated mircoposts" do
      @user.destroy
      [@mp1, @mp2].each do |micropost|
        Micropost.find_by_id(micropost.id).should be_nil
      end
    end

    describe "status feed" do

      it "should have a feed" do
        @user.should respond_to(:feed)
      end

      it "should include the user's microposts" do
        @user.feed.include?(@mp1).should be_true
        @user.feed.include?(@mp2).should be_true
      end

      it "should not include a different user's microposts" do
        mp3 = Factory(:micropost,
                      :user => Factory(:user, :email => Factory.next(:email)))
        @user.feed.include?(mp3).should be_false
      end
      it "should include the microposts of followed users" do
        followed = Factory(:user, :email => Factory.next(:email))
        mp3 = Factory(:micropost, :user => followed)
        @user.follow!(followed)
        @user.feed.should include(mp3)
      end
    end
  end

  describe "relationships" do
    
    before(:each) do
      @user = User.create!(@attr)
      @followed = Factory(:user)
    end

    it "should have a relationships method" do
      @user.should respond_to(:relationships)
    end
    
    it "should have a following method" do
      @user.should respond_to(:following)
    end

    it "should have a following? method" do
      @user.should respond_to(:following?)
    end

    it "should have a follow! method" do
      @user.should respond_to(:follow!)
    end

    it "should include the followed user in the following array" do
      @user.follow!(@followed)
      @user.following.should include(@followed)
    end

    it "should have an unfollow! method" do
      @followed.should respond_to(:unfollow!)
    end

    it "should unfollow an user" do
      @user.follow!(@followed)
      @user.unfollow!(@followed)
      @user.should_not be_following(@followed)
    end
  
    it "should have a reverse_relationships method" do
      @user.should respond_to(:reverse_relationships)
    end

  end
end
