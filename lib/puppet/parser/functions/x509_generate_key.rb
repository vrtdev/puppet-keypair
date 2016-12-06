module Puppet::Parser::Functions
  newfunction(:x509_generate_key, type: :rvalue, doc: <<-EODOC
        The x509_generate_key function generates a new X.509 (SSL) RSA keypair.
        Optional parameters:
         * key_length
         * CN
      EODOC
             ) do |args|
    params = args.shift || {}

    output = {
      'params' =>     params,
      'CN' =>         params['CN'] || 'autogenerated.puppet',
      'key_length' => params['key_length'] || 2048
    }

    Dir.mktmpdir do |dir|
      unless system('openssl', 'genrsa', '-out', "#{dir}/key", output['key_length'].to_s)
        raise Puppet::ParseError, 'Could not generate key'
      end

      unless system('openssl', 'req', '-new', '-subj', "/CN=#{output['CN']}", '-key', "#{dir}/key", '-out', "#{dir}/csr")
        raise Puppet::ParseError, 'Could not generate CSR'
      end

      unless system('openssl', 'x509', '-req', '-days', '3650', '-in', "#{dir}/csr", '-signkey', "#{dir}/key", '-out', "#{dir}/crt")
        raise Puppet::ParseError, 'Could not generate self-signed CRT'
      end

      output['secret_key'] = File.read("#{dir}/key")
      output['cert'] = File.read("#{dir}/crt")
    end

    output
  end
end