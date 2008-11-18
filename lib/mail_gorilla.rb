require 'xmlrpc/client'
class MailGorilla
  
  # => You can find documentation on the MailChimp api at http://www.mailchimp.com/api/1.1/
  
  attr_reader :config
  attr_reader :api_key
  attr_reader :chimpApi
  attr_reader :lists
  attr_reader :campaigns
  attr_reader :templates

  def initialize(autologin = true)
    load_config
    login if autologin
    return self
  end

  def load_config
    @config = YAML.load(File.open("#{RAILS_ROOT}/config/mail_gorilla.yml"))[RAILS_ENV].symbolize_keys
  end
  
  def login
    begin
      @chimpApi ||= XMLRPC::Client.new2("http://api.mailchimp.com/1.1/")
      @api_key = @chimpApi.call("login", @config[:username].to_s, @config[:password].to_s)
    rescue
      
      puts "****************** Mail Chimp Error"
      puts "Connection: #{@chimpApi}"
      puts "Login #{@config[:username].to_s}, #{@config[:password].to_s}"
    end
  end
  
  def get_lists
    @lists = @chimpApi.call("lists", @api_key)
  end
  
  def get_campaigns
    @campaigns = @chimpApi.call("campaigns", @api_key)
  end
  
  def get_templates
    @templates = @chimpApi.call("campaignTemplates", @api_key)
  end
  
  def get_merge_vars(list_id)
    @merge_vars = @chimpApi.call("listMergeVars", @api_key, list_id)
  end
  
  def add_merge_var(list_id, tag, name, req = false)
    @merge_var = @chimpApi.call("listMergeVarAdd", @api_key, list_id, tag, name, req)
  end

  def batch_subscribe(list_id, info_array)
    # => info_array is an array of hashes that must contain {:EMAIL=>"",:EMAIL_TYPE=>""} 
    
        # listBatchSubscribe
        # public static listBatchSubscribe(string apikey, string id, array batch, boolean double_optin, boolean update_existing, boolean replace_interests)
        # 
        # Subscribe a batch of email addresses to a list at once
        # 
        # 
        # Section:
        #     List Related
        # Parameters:
        #     apikey  a valid API Key for your user account. Get by calling login()
        #     id  the list id to connect to
        #     batch   an array of structs for each address to import with two special keys: "EMAIL" for the email address, and "EMAIL_TYPE" for the email type option (html or text)
        #     double_optin  flag to control whether to send an opt-in confirmation email - defaults to true
        #     update_existing   flag to control whether to update members that are already subscribed to the list or to return an error, defaults to false (return error)
        #     replace_interests   flag to determine whether we replace the interest groups with the updated groups provided, or we add the provided groups to the member's interest groups (optional, defaults to true)
    
    @chimpApi.call("listBatchSubscribe", @api_key, list_id, info_array, false, true)
  end

  ########################################### campaign functions ####################################################
  
  def campaign_content(campaign_id)
    @chimpApi.call("campaignContent",@api_key,campaign_id)
  end
  
  def update_campaign(campaign_id)
    
  end
  
  
  ###################################################################################################################



  ########################################### user functions ########################################################

  def user_find(list_id, email)
    begin
      info = @chimpApi.call("listMemberInfo", @api_key, list_id, email)
    rescue
      return nil
    end
  end
  
  def user_subscribed?(list_id, email)
    # => return true or false based on if user is actually in the list and if their status is == subscribed
    info = user_find(list_id, email)
    info ? (info["status"] == "subscribed") : false
  end
  
  def subscribe_user(list_id, current_email, user_info = {}, email_type = "html")
    # => return true or false on success
    begin
      @chimpApi.call("listSubscribe", @api_key, list_id, current_email, user_info, email_type, false)
    rescue
      false
    end
  end
  
  def unscubscribe_user(list_id, current_email)
    # => return true or false on success
    begin
      @chimpApi.call("listUnsubscribe", @api_key, list_id, current_email, true, false, false)
    rescue
      false
    end
  end

  def update_user_info(list_id, current_email, user_info = {}, email_type = "") 
    # => user_info is a hash of values for the user on the list
    # => example:
    # =>    {:EMAIL=>"new_email@address.com"}
    # => email_type can be "html" or "text" or "" for no change
    # => return true or false on success
    
    @chimpApi.call("listUpdateMember", @api_key, list_id, current_email, user_info, email_type)
    
  end
  
  #####################################################################################################################
  
end