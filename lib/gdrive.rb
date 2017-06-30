module GDrive
  class << self
    def upload_spreadsheet(title, array, kwargs={})
      return if array.blank?

      s = gdrive_session.spreadsheet_by_title(title)
      not_assign_permissions = !!s
      s ||= gdrive_session.create_spreadsheet(title)

      month = kwargs[:month]
      label = kwargs[:label]
      if (month || label).present?
        page_title = label || I18n.t('date.month_names')[month]

        ws = s.worksheet_by_title(page_title)
        unless ws
          ws = s.add_worksheet(page_title, array.size + 5, array[0].size)
        end
      else
        ws = s.worksheets[0]
      end
      ws.update_cells(1, 1, array)
      ws.save

      change_permissions(s.key) unless not_assign_permissions

      puts "https://docs.google.com/spreadsheets/d/#{s.key}/edit#gid=#{ws.gid}"
    end

    private

    def gdrive
      @_gdrive ||= SECRETS[:gdrive]
    end

    def client
      unless @_gclient
        key = Google::APIClient::KeyUtils.load_from_pkcs12(
          gdrive[:cert], gdrive[:secret]
        )
        scopes = %w(
          https://www.googleapis.com/auth/drive
          https://spreadsheets.google.com/feeds/
        ).join(' ')
        token_url = 'https://accounts.google.com/o/oauth2/token'
        # Path (?)
        Google::APIClient.logger ||= Rails.logger
        ####

        @_gclient               = Google::APIClient.new
        @_gclient.authorization = Signet::OAuth2::Client.new(
          token_credential_uri: token_url,
          audience:             token_url,
          scope:                scopes,
          issuer:               gdrive[:issuer],
          signing_key:          key
        )

        @_gclient.authorization.fetch_access_token!
      end

      @_gclient
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
