# STD Libs
require 'base64'
require 'openssl'
require 'json'

module OnePass
  # Handle all the 1Password OpVault operations
  class OpVault
    FIELD_TYPES = {
      password: 'P',
      text: 'T',
      email: 'E',
      number: 'N',
      radio: 'R',
      telephone: 'TEL',
      checkbox: 'C',
      url: 'U'
    }

    DESIGNATION_TYPES = {
      username: 'username',
      password: 'password',
      none: ''
    }

    def initialize(vault_path)
      check_and_set_vault vault_path
      check_and_set_profile File.join(@vault_path, 'default', 'profile.js')
      @items = {}
      @item_index = {}
    end

    def check_and_set_vault(vault_path)
      @vault_path = File.expand_path(vault_path)
      unless File.exist? @vault_path
        raise ArgumentError.new, 'Vault file does not exist'
      end
    end

    def check_and_set_profile(profile_path)
      unless File.exist? profile_path
        raise ArgumentError.new, 'Vault profile does not exist'
      end

      profile = File.read profile_path
      unless profile.start_with?('var profile=') && profile.end_with?(';')
        raise 'Vault profile format incorrect'
      end

      @profile = JSON.parse profile[12..-2]
    rescue
      raise 'Unable to parse vault profile'
    end

    def unlock(master_password = nil)
      master_password = yield if block_given?

      salt = Base64.decode64(@profile['salt'])
      iterations = @profile['iterations']
      key, mac_key = derive_keys master_password, salt, iterations
      @master_key, @master_mac_key = master_keys key, mac_key
      @overview_key, @overview_mac_key = overview_keys key, mac_key
    rescue
      raise 'Incorrect password'
    end

    def lock
      @master_key = @master_mac_key = nil
    end

    def check_hmac(data, hmac_key, desired_hmac)
      digest = OpenSSL::Digest::SHA256.new
      computed_hmac = OpenSSL::HMAC.digest digest, hmac_key, data
      raise ArgumentError.new, 'Invalid HMAC' if computed_hmac != desired_hmac
    end

    def load_items
      file_glob = File.join(@vault_path, 'default', 'band_*.js')
      Dir.glob(file_glob) do |file|
        band = JSON.parse File.read(file)[3..-3]
        @items.merge! band
      end

      @items.each_pair do |uuid, item|
        overview = item_overview item
        @item_index[overview['title']] = uuid
      end
    end

    def find(search)
      @items.values_at *@item_index.values_at(*@item_index.keys.grep(search))
    end

    def decrypt_data(key, iv, data)
      cipher = OpenSSL::Cipher::AES256.new(:CBC).decrypt
      cipher.key = key
      cipher.iv = iv
      cipher.padding = 0
      cipher.update(data) + cipher.final
    end

    def decrypt_opdata(cipher_text, cipher_key, cipher_mac_key)
      key_data = cipher_text[0..-33]
      mac_data = cipher_text[-32..-1]

      check_hmac key_data, cipher_mac_key, mac_data
      plaintext = decrypt_data cipher_key, key_data[16..31], key_data[32..-1]

      plaintext_size = key_data[8..15].unpack('Q')[0]
      plaintext[-plaintext_size..-1]
    end

    def derive_keys(master_password, salt, iterations)
      digest = OpenSSL::Digest::SHA512.new
      derived_key = OpenSSL::PKCS5.pbkdf2_hmac(
        master_password, salt, iterations, digest.digest_length, digest
      )

      # => key, hmac
      [derived_key[0..31], derived_key[32..63]]
    end

    def master_keys(derived_key, derived_mac_key)
      encrypted = Base64.decode64(@profile['masterKey'])
      decrypt_keys encrypted, derived_key, derived_mac_key
    end

    def overview_keys(derived_key, derived_mac_key)
      encrypted = Base64.decode64(@profile['overviewKey'])
      decrypt_keys encrypted, derived_key, derived_mac_key
    end

    def decrypt_keys(encrypted_key, derived_key, derived_mac_key)
      key_base = decrypt_opdata encrypted_key, derived_key, derived_mac_key
      keys = OpenSSL::Digest::SHA512.new.digest key_base

      # => key, hmac
      [keys[0..31], keys[32..63]]
    end

    def item_keys(item)
      item_key = Base64.decode64 item['k']
      key_data = item_key[0..-33]
      key_hmac = item_key[-32..-1]

      check_hmac key_data, @master_mac_key, key_hmac
      plaintext = decrypt_data @master_key, key_data[0..15], key_data[16..-1]

      # => key, hmac
      [plaintext[0..31], plaintext[32..63]]
    end

    def item_overview(item)
      data = Base64.decode64(item['o'])
      overview = decrypt_opdata data, @overview_key, @overview_mac_key
      { 'uuid' => item['uuid'] }.merge JSON.parse overview
    end

    def item_detail(item)
      data = Base64.decode64(item['d'])
      item_key, item_mac_key = item_keys item
      detail = decrypt_opdata data, item_key, item_mac_key
      { 'uuid' => item['uuid'] }.merge JSON.parse detail
    end
  end
end
