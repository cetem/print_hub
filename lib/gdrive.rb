module GDrive
  class << self
    def upload_spreadsheat(title, array)
      s = gdrive_session.create_spreadsheet(title)
      ws = s.worksheets[0]
      ws.update_cells(1, 1, array)
      ws.save

      change_permissions(s.key)
    end

    private

    def gdrive
      @gdrive ||= SECRETS[:gdrive]
    end

    def client
      unless @client
        key = Google::APIClient::KeyUtils.load_from_pkcs12(
          gdrive[:cert], gdrive[:secret]
        )
        scopes = %w(
          https://www.googleapis.com/auth/drive https://docs.google.com/feeds/
          https://docs.googleusercontent.com/ https://spreadsheets.google.com/feeds/
        ).join(' ')
        token_url             = 'https://accounts.google.com/o/oauth2/token'
        # Path (?)
        Google::APIClient.logger ||= Rails.logger
        ####

        @client               = Google::APIClient.new
        @client.authorization = Signet::OAuth2::Client.new(
          token_credential_uri: token_url,
          audience:             token_url,
          scope:                scopes,
          issuer:               gdrive[:issuer],
          signing_key:        key
        )

        @client.authorization.fetch_access_token!
      end

      @client
    end

    def gdrive_session
      GoogleDrive.login_with_oauth(client.authorization.access_token)
    end

    def change_permissions(file_id)
      drive = client.discovered_api('drive', 'v2')

      # roles = { owner: [email], writer: [email2, email3] }
      gdrive[:roles].each do |role, users|
        [users].flatten.each do |user|
          obj = drive.permissions.insert.request_schema.new(value: user,
                                                            type: 'user',
                                                            role: role)

          client.execute(
            api_method: drive.permissions.insert,
            body_object: obj,
            parameters: { 'fileId' => file_id }
          )
        end
      end
    end
  end
end
